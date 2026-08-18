--!strict
--[[
	DataService
	-----------
	Owns every read and write of persistent player data.

	A DataStore is Roblox's server-side database: the only place a value
	survives after the player leaves. It is a network call to another machine,
	so it fails routinely -- throttling, timeouts, outages -- and every call
	has to be treated as something that can go wrong.

	The rule that matters most here: if a load fails, this service refuses to
	save for the rest of that session. Saving after a failed load would write
	a fresh, empty profile over a real one and erase the player's progress
	permanently. A player who is told "we could not load your data" and keeps
	their save is annoyed; a player silently reset is gone for good.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local DataConfig = require(Shared.config.DataConfig)
local GameConfig = require(Shared.config.GameConfig)

export type Profile = {
	stat: number,
	currency: number,
	upgrades: { [string]: number },
	firstJoinUnix: number,
	lastSaveUnix: number,
}

export type Session = {
	profile: Profile,
	-- False when the initial load failed. A locked session is playable but
	-- never written back, so a broken read can never destroy a good save.
	saveEnabled: boolean,
	-- Set once the player leaves, so the autosave loop stops touching them.
	released: boolean,
}

local DataService = {}

local store: DataStore? = nil
local sessions: { [Player]: Session } = {}

--[[
	Studio has no reliable DataStore access unless API access is switched on
	for the place, so we degrade to memory-only rather than spamming errors.
	Progress will not persist between Studio runs -- that is expected.
]]
local function getStore(): DataStore?
	if store then
		return store
	end

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DataConfig.storeName)
	end)

	if ok then
		store = result
		return store
	end

	warn("[DataService] DataStore unavailable, running in memory-only mode:", result)
	return nil
end

local function keyFor(player: Player): string
	return DataConfig.keyPrefix .. tostring(player.UserId)
end

local function newProfile(): Profile
	return {
		stat = GameConfig.loop.startingStat,
		currency = GameConfig.loop.startingCurrency,
		upgrades = {},
		firstJoinUnix = os.time(),
		lastSaveUnix = 0,
	}
end

--[[
	Repairs a profile read from the DataStore.

	Saves written by an older build will be missing fields added since, and
	indexing a nil field is a runtime error that would take the whole loop
	down. Filling gaps against a fresh profile keeps old saves loadable.
]]
local function reconcile(raw: any): Profile
	local profile = newProfile()

	if type(raw) ~= "table" then
		return profile
	end

	if type(raw.stat) == "number" then
		profile.stat = raw.stat
	end
	if type(raw.currency) == "number" then
		profile.currency = raw.currency
	end
	if type(raw.firstJoinUnix) == "number" then
		profile.firstJoinUnix = raw.firstJoinUnix
	end
	if type(raw.lastSaveUnix) == "number" then
		profile.lastSaveUnix = raw.lastSaveUnix
	end
	if type(raw.upgrades) == "table" then
		for id, level in raw.upgrades do
			if type(id) == "string" and type(level) == "number" then
				profile.upgrades[id] = level
			end
		end
	end

	return profile
end

--[[
	Runs a DataStore call with exponential backoff.
	Returns the call's result, or nil plus the last error message.
]]
local function withRetry<T>(label: string, fn: () -> T): (T?, string?)
	local lastError: string? = nil

	for attempt = 1, DataConfig.maxRetries do
		local ok, result = pcall(fn)
		if ok then
			return result, nil
		end

		lastError = tostring(result)
		if attempt < DataConfig.maxRetries then
			task.wait(DataConfig.retryBaseDelay * (DataConfig.retryBackoff ^ (attempt - 1)))
		end
	end

	warn(
		string.format(
			"[DataService] %s failed after %d attempts: %s",
			label,
			DataConfig.maxRetries,
			lastError or "?"
		)
	)
	return nil, lastError
end

--[[
	Loads a player's profile. Always returns a usable session, even on
	failure -- the player gets to play, they just do not get written back.
]]
function DataService.load(player: Player): Session
	local existing = sessions[player]
	if existing then
		return existing
	end

	local activeStore = getStore()

	local session: Session = {
		profile = newProfile(),
		saveEnabled = true,
		released = false,
	}

	if activeStore then
		local raw, err = withRetry("load " .. player.Name, function()
			return (activeStore :: DataStore):GetAsync(keyFor(player))
		end)

		if err then
			session.saveEnabled = false
			warn(
				string.format(
					"[DataService] Save DISABLED for %s -- load failed, refusing to overwrite.",
					player.Name
				)
			)
		elseif raw ~= nil then
			session.profile = reconcile(raw)
		end
	else
		-- Memory-only mode. Nothing to overwrite, so saving stays harmless.
		session.saveEnabled = false
	end

	sessions[player] = session
	return session
end

function DataService.get(player: Player): Session?
	return sessions[player]
end

--[[
	Writes a session back. Returns true only when the data actually landed.
]]
function DataService.save(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end

	if not session.saveEnabled then
		return false
	end

	local activeStore = getStore()
	if not activeStore then
		return false
	end

	session.profile.lastSaveUnix = os.time()
	local profile = session.profile

	local _, err = withRetry("save " .. player.Name, function()
		return (activeStore :: DataStore):SetAsync(keyFor(player), profile)
	end)

	return err == nil
end

--[[
	Final save on the way out, then drop the session so the autosave loop and
	the economy loop stop seeing a player who is no longer here.
]]
function DataService.release(player: Player)
	local session = sessions[player]
	if not session then
		return
	end

	session.released = true
	DataService.save(player)
	sessions[player] = nil
end

function DataService.activeSessions(): { [Player]: Session }
	return sessions
end

local function startAutosave()
	task.spawn(function()
		while true do
			task.wait(DataConfig.autosaveInterval)
			for player, session in sessions do
				if not session.released and session.saveEnabled then
					task.spawn(DataService.save, player)
				end
			end
		end
	end)
end

--[[
	BindToClose runs when the server is shutting down. Roblox gives roughly 30
	seconds before killing the process, so every remaining session is flushed
	in parallel and the whole batch is bounded by a budget.
]]
local function bindShutdown()
	game:BindToClose(function()
		-- Studio closes instantly and has no real DataStore, so waiting here
		-- would just stall every test run.
		if RunService:IsStudio() then
			return
		end

		local pending = 0
		for player in sessions do
			pending += 1
			task.spawn(function()
				DataService.save(player)
				pending -= 1
			end)
		end

		local deadline = os.clock() + DataConfig.shutdownFlushBudget
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

function DataService.start()
	Players.PlayerRemoving:Connect(function(player)
		DataService.release(player)
	end)

	startAutosave()
	bindShutdown()
end

return DataService
