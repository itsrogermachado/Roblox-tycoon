--!strict
--[[
	Remotes
	-------
	Single source of truth for every client/server channel.

	A RemoteEvent is the only way a LocalScript can talk to the server, and it
	is fully visible to exploiters -- anyone can fire any remote with any
	argument. That is why every name lives here and every handler validates:
	the client asks, the server decides.

	The server creates the instances; the client waits for them. Declaring the
	names in one place stops the classic bug where a typo on one side creates
	a second, silent remote that nobody is listening to.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

-- Client -> server requests. Treat every payload as hostile.
local EVENT_NAMES = {
	"PurchaseUpgrade",
}

-- Server -> client pushes. These carry authoritative state for display only.
local EVENT_NAMES_DOWNSTREAM = {
	"StateChanged",
}

export type RemoteMap = { [string]: RemoteEvent }

local Remotes = {}

local cached: RemoteMap? = nil

local function buildOnServer(): RemoteMap
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	assert(folder, "Remotes folder must exist by now")

	local map: RemoteMap = {}
	for _, name in EVENT_NAMES do
		map[name] = Remotes._ensureEvent(folder :: Folder, name)
	end
	for _, name in EVENT_NAMES_DOWNSTREAM do
		map[name] = Remotes._ensureEvent(folder :: Folder, name)
	end
	return map
end

function Remotes._ensureEvent(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

local function buildOnClient(): RemoteMap
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
	assert(folder, "Remotes folder never replicated -- is the server bootstrap running?")

	local map: RemoteMap = {}
	for _, name in EVENT_NAMES do
		map[name] = folder:WaitForChild(name) :: RemoteEvent
	end
	for _, name in EVENT_NAMES_DOWNSTREAM do
		map[name] = folder:WaitForChild(name) :: RemoteEvent
	end
	return map
end

--[[
	Returns the remote map, creating it on the server and waiting for it on the
	client. Safe to call from anywhere; the result is cached per environment.
]]
function Remotes.get(): RemoteMap
	if cached then
		return cached
	end

	local map = if RunService:IsServer() then buildOnServer() else buildOnClient()
	cached = map
	return map
end

return Remotes
