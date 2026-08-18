--!strict
--[[
	LeaderstatsService
	------------------
	Mirrors the profile onto the player list.

	"leaderstats" is a hard-coded Roblox convention, not an API: a Folder with
	that exact name parented to a Player makes its Value children appear in the
	player list automatically. The name is case-sensitive and nothing else
	works, which is why it is spelled out rather than pulled from config.

	These values are display copies. Nothing reads them back as truth -- the
	profile in DataService is the record.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.config.GameConfig)

local DataService = require(script.Parent.DataService)

local LeaderstatsService = {}

local UPDATE_INTERVAL = 1

local function build(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local stat = Instance.new("IntValue")
	stat.Name = GameConfig.theme.statName
	stat.Value = 0
	stat.Parent = folder

	local currency = Instance.new("IntValue")
	currency.Name = GameConfig.theme.currencyName
	currency.Value = 0
	currency.Parent = folder

	folder.Parent = player
end

--[[
	The player list only renders whole numbers, and the economy runs on
	fractional gains, so the display is floored. Flooring rather than rounding
	means the shown value never claims progress the profile does not have.
]]
local function refresh(player: Player)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		return
	end

	local session = DataService.get(player)
	if not session then
		return
	end

	local stat = folder:FindFirstChild(GameConfig.theme.statName)
	if stat and stat:IsA("IntValue") then
		stat.Value = math.floor(session.profile.stat)
	end

	local currency = folder:FindFirstChild(GameConfig.theme.currencyName)
	if currency and currency:IsA("IntValue") then
		currency.Value = math.floor(session.profile.currency)
	end
end

function LeaderstatsService.setup(player: Player)
	build(player)
	refresh(player)
end

function LeaderstatsService.start()
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			for _, player in Players:GetPlayers() do
				refresh(player)
			end
		end
	end)
end

return LeaderstatsService
