--!strict
--[[
	StateController
	---------------
	Receives authoritative state from the server and holds the latest copy.

	This is the client's whole relationship with the economy: it listens, it
	stores, it exposes. It never computes a balance or a cost, because a value
	the client derives is a value an exploiter controls.

	No UI yet -- for now the snapshot is logged so the loop can be verified in
	the Output window. The interface layer will read from here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.config.GameConfig)
local Remotes = require(Shared.remotes.Remotes)

export type Snapshot = {
	stat: number,
	currency: number,
	upgrades: { [string]: number },
	statPerTick: number,
	currencyPerTick: number,
	areaId: string,
	saveEnabled: boolean,
}

local StateController = {}

local latest: Snapshot? = nil

-- Logging every tick would flood the Output. One line every few seconds is
-- enough to confirm the loop is alive without drowning real warnings.
local LOG_EVERY = 5
local ticksSeenSinceLog = 0

function StateController.get(): Snapshot?
	return latest
end

function StateController.start()
	local remotes = Remotes.get()

	remotes.StateChanged.OnClientEvent:Connect(function(snapshot: Snapshot)
		latest = snapshot

		ticksSeenSinceLog += 1
		if ticksSeenSinceLog < LOG_EVERY then
			return
		end
		ticksSeenSinceLog = 0

		print(
			string.format(
				"[Client] %s: %d (+%.2f/s) | %s: %d (+%.2f/s) | area: %s",
				GameConfig.theme.statName,
				math.floor(snapshot.stat),
				snapshot.statPerTick,
				GameConfig.theme.currencyName,
				math.floor(snapshot.currency),
				snapshot.currencyPerTick,
				snapshot.areaId
			)
		)
	end)
end

return StateController
