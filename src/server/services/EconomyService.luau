--!strict
--[[
	EconomyService
	--------------
	The incremental loop and the only place currency changes.

	The server is the sole authority. The client never computes a balance, a
	cost or a multiplier -- it renders what it is told and asks for purchases.
	Everything arriving from a client is assumed to be forged until checked.

	One Heartbeat connection drives every player. Per-player loops would mean
	one thread per session and drift between them; a single accumulator keeps
	the tick rate identical for everyone regardless of server load.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.config.GameConfig)
local UpgradeConfig = require(Shared.config.UpgradeConfig)
local Remotes = require(Shared.remotes.Remotes)

local DataService = require(script.Parent.DataService)

export type PurchaseResult = {
	ok: boolean,
	reason: string?,
}

local EconomyService = {}

local accumulator = 0

--[[
	Total multiplier for one rate kind, derived from owned upgrade levels.

	Effects add before they multiply: three levels of a +0.25 upgrade give
	1 + 0.75 = 1.75x, not 1.25^3. Additive stacking is what keeps a ten-upgrade
	curve tunable -- multiplicative stacking explodes past readable numbers
	within an hour of play.
]]
local function multiplierFor(profile: DataService.Profile, kind: UpgradeConfig.UpgradeKind): number
	local total = 1

	for id, level in profile.upgrades do
		local upgrade = UpgradeConfig.get(id)
		if upgrade and upgrade.kind == kind and level > 0 then
			total += upgrade.effectPerLevel * level
		end
	end

	return total
end

--[[
	Highest area the player has earned access to. Areas are ordered by
	requirement in config, so the last one that qualifies is the answer.
]]
local function currentAreaId(stat: number): string
	local unlocked = GameConfig.areas[1].id

	for _, area in GameConfig.areas do
		if stat >= area.requiredStat then
			unlocked = area.id
		end
	end

	return unlocked
end

--[[
	The snapshot the client is allowed to see. Built explicitly rather than
	sending the profile, so adding a private field to the save shape can never
	leak it to every client by accident.
]]
local function snapshotFor(player: Player)
	local session = DataService.get(player)
	if not session then
		return nil
	end

	local profile = session.profile

	return {
		stat = profile.stat,
		currency = profile.currency,
		upgrades = profile.upgrades,
		statPerTick = GameConfig.loop.baseStatPerTick * multiplierFor(profile, "StatRate"),
		currencyPerTick = profile.stat
			* GameConfig.loop.baseCurrencyPerStat
			* multiplierFor(profile, "CurrencyRate"),
		areaId = currentAreaId(profile.stat),
		saveEnabled = session.saveEnabled,
	}
end

function EconomyService.pushState(player: Player)
	local snapshot = snapshotFor(player)
	if not snapshot then
		return
	end

	Remotes.get().StateChanged:FireClient(player, snapshot)
end

--[[
	Advances one player by a single tick.
]]
local function tickPlayer(player: Player)
	local session = DataService.get(player)
	if not session or session.released then
		return
	end

	local profile = session.profile

	local statGain = GameConfig.loop.baseStatPerTick * multiplierFor(profile, "StatRate")
	profile.stat += statGain

	local currencyGain = profile.stat
		* GameConfig.loop.baseCurrencyPerStat
		* multiplierFor(profile, "CurrencyRate")
	profile.currency += currencyGain
end

--[[
	Handles a purchase request. Every branch here exists because a client can
	send anything: a made-up id, a maxed upgrade, or a purchase it cannot
	afford. Rejecting is always cheaper than repairing an inflated economy.
]]
function EconomyService.purchaseUpgrade(player: Player, upgradeId: unknown): PurchaseResult
	if type(upgradeId) ~= "string" then
		return { ok = false, reason = "InvalidRequest" }
	end

	local upgrade = UpgradeConfig.get(upgradeId)
	if not upgrade then
		return { ok = false, reason = "UnknownUpgrade" }
	end

	local session = DataService.get(player)
	if not session then
		return { ok = false, reason = "NoSession" }
	end

	local profile = session.profile
	local level = profile.upgrades[upgrade.id] or 0

	if level >= upgrade.maxLevel then
		return { ok = false, reason = "MaxLevel" }
	end

	local cost = UpgradeConfig.costAtLevel(upgrade, level)
	if profile.currency < cost then
		return { ok = false, reason = "InsufficientFunds" }
	end

	profile.currency -= cost
	profile.upgrades[upgrade.id] = level + 1

	EconomyService.pushState(player)
	return { ok = true }
end

function EconomyService.start()
	local remotes = Remotes.get()

	remotes.PurchaseUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		EconomyService.purchaseUpgrade(player, upgradeId)
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator += deltaTime
		if accumulator < GameConfig.loop.tickInterval then
			return
		end

		-- Subtract rather than reset so a lagging server catches up instead of
		-- quietly paying out less than it owes.
		accumulator -= GameConfig.loop.tickInterval

		for _, player in Players:GetPlayers() do
			tickPlayer(player)
			EconomyService.pushState(player)
		end
	end)
end

return EconomyService
