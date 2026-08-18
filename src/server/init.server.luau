--!strict
--[[
	Server bootstrap.

	Start order matters. Remotes must exist before any client can wait on
	them, data must be loadable before the economy ticks a player, and player
	handling is connected last so nobody is processed by a service that has
	not started yet.

	Players who joined during startup are handled explicitly at the end:
	PlayerAdded does not fire retroactively, and in a live server the first
	player can beat this script.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.config.GameConfig)
local Remotes = require(Shared.remotes.Remotes)

local services = script:WaitForChild("services")
local DataService = require(services.DataService)
local EconomyService = require(services.EconomyService)
local LeaderstatsService = require(services.LeaderstatsService)

local function onPlayerAdded(player: Player)
	local session = DataService.load(player)
	LeaderstatsService.setup(player)
	EconomyService.pushState(player)

	if not session.saveEnabled then
		warn(
			string.format(
				"[Server] %s is playing on a locked session -- progress will not save.",
				player.Name
			)
		)
	end
end

-- Create the remote instances before anything can listen for them.
Remotes.get()

DataService.start()
EconomyService.start()
LeaderstatsService.start()

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

print(
	string.format(
		"[Server] %s online -- economy running at 1 tick / %ds.",
		GameConfig.theme.title,
		GameConfig.loop.tickInterval
	)
)
