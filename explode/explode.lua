--- A module to create explosions of Shapes and sub-Shapes.
--- Each explosion creates copies of target shapes, it's often necessary to hide the target when the explosion occurs.
---@code
--- explode = require("github.com/aduermael/modzh/explode")
--- explode(someShape, { includeRoot = true })

local mod = {}

local conf = require("config")
local hierarchyActions = require("hierarchyactions")
local defaultConfig = {
	debrisTTL = 5, -- in seconds, debris removed after that delay
	bounciness = 0.1,
	collidesWithGoups = Map.CollisionGroups,
	minVelocity = 50,
	maxVelocity = 150,
	acceleration = nil, -- acceleration for debris
	setup = function(debris, config) -- setup for each debris
		local v = Number3(0, 0, 1) * (config.minVelocity + math.random() * (config.maxVelocity - config.minVelocity))
		v:Rotate(Number3(math.random() * -math.pi, math.random() * math.pi * 2, 0)) -- random spherical dome directions
		debris.Velocity = v
	end,
	remove = function(debris)
		debris:RemoveFromParent()
	end,
}

setmetatable(mod, {
	__index = {},
	__newindex = function()
		error("explode module is read-only", 2)
	end,
	__metatable = false,
	__call = function(_, target, config)
		config = conf:merge(defaultConfig, config, {
			acceptTypes = {
				collidesWithGroups = { "CollisionGroups", "table" },
				acceleration = { "table", "Number3" },
			},
		})

		hierarchyActions:applyToDescendants(target, { includeRoot = true }, function(o)
			if type(o) == "Shape" or type(o) == "MutableShape" then
				local debris = Shape(o)
				World:AddChild(debris)

				debris.Scale:Set(o.LossyScale)
				debris.Position:Set(o.Position)
				debris.Rotation:Set(o.Rotation)

				debris.Physics = PhysicsMode.Dynamic
				debris.CollisionGroups = nil
				debris.CollidesWithGroups = config.collidesWithGoups
				debris.Bounciness = config.bounciness

				config.setup(debris, config)

				Timer(config.debrisTTL, function()
					config.remove(debris)
				end)
			end
		end)
	end,
})

return mod
