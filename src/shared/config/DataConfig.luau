--!strict
--[[
	DataConfig
	----------
	Persistence tuning.

	`storeName` is versioned on purpose. DataStore entries cannot be migrated
	in place without risk, so a breaking change to the save shape means
	bumping this string and starting clean rather than corrupting live saves.
]]

local DataConfig = {}

DataConfig.storeName = "PlayerData_v1"
DataConfig.keyPrefix = "Player_"

-- Retries for a single DataStore call. Roblox throttles aggressively and a
-- transient failure is normal, so a lone failed request must never be read as
-- "this player has no data".
DataConfig.maxRetries = 5
DataConfig.retryBaseDelay = 1
DataConfig.retryBackoff = 2

-- Periodic autosave, in seconds. Roblox allows roughly one write per minute
-- per key, so anything below 60 is throttled and wasted.
DataConfig.autosaveInterval = 120

-- Seconds to allow for flushing every session during a server shutdown.
-- BindToClose gives us 30 before the process is killed regardless.
DataConfig.shutdownFlushBudget = 25

return DataConfig
