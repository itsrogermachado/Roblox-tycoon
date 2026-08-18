--!strict
--[[
	Client bootstrap.

	Kept deliberately thin: it starts controllers and nothing else. Anything
	with logic of its own belongs in a controller module, so this file never
	becomes the place where unrelated features quietly pile up.
]]

local controllers = script:WaitForChild("controllers")
local StateController = require(controllers.StateController)

StateController.start()

print("[Client] Ready -- waiting for server state.")
