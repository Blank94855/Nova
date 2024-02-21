--- This module allows you to create fire Objects. 🔥
---@code
--- fireModule = require("github.com/aduermael/modzh/fire")
--- fire = fireModule:create()
--- -- fire is a regular Object, so you can parent it and position it:
--- fire:SetParent(World)
--- fire.Position = Player.Position

mod = {}

local model
local pool = {}
local particles = {}

local sources = {}

local START_COLOR = Color(255, 224, 0)
local END_COLOR = Color(234, 104, 0)
local SCALE = 5
local LIFE = 1.2

local defaultConfig = {
	radius = 4,
	delay = 0.02,
}

local tickListener
local toRemove = {}

local pow = 2
local up = 0.05
local upInv = 1.0 / up
local down = 1.0 - up
local downInv = 1.0 / down

function scale(p)
	if p <= up then
		return (p * upInv) ^ pow
	end
	return 1.0 - ((p - up) * downInv) ^ pow
end

function startTickIfNeeded()
	if tickListener ~= nil then
		return
	end

	if model == nil then
		local ms = MutableShape()
		ms:AddBlock(Color(255, 0, 0), 0, 0, 0)
		ms.Pivot = { 0.5, 0.5, 0.5 }
		ms.IsUnlit = true
		model = Shape(ms)
	end

	tickListener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
		for _, source in ipairs(sources) do
			source.t = source.t + dt
			if source.t >= source.config.delay then
				source.t = source.t % source.config.delay
				local p = table.remove(pool)
				if p == nil then
					p = Shape(model)
				end
				p:SetParent(World)

				local d = Number3(0, 0, math.random() * source.config.radius)
				d:Rotate(0, math.random() * math.pi * 2, 0)
				p.Position = source.Position + d

				p.Acceleration = -Config.ConstantAcceleration
				p.Scale = 0
				p.v = Number3(0, 15, 0)
				p.rAxis = Number3(math.random(), math.random(), math.random())
				-- p.Physics = PhysicsMode.Dynamic
				p.Physics = PhysicsMode.Disabled
				p.life = LIFE
				particles[p] = true
			end
		end

		local l
		for p, _ in pairs(particles) do
			p.life = p.life - dt
			l = 1.0 - (p.life / LIFE)
			p.Scale = scale(l) * SCALE
			p.Position = p.Position + p.v * dt
			p:RotateWorld(p.rAxis, dt)
			p.Palette[1].Color:Lerp(START_COLOR, END_COLOR, l)
			if p.life <= 0 then
				table.insert(toRemove, p)
			end
		end

		for _, p in ipairs(toRemove) do
			table.insert(pool, p)
			particles[p] = nil
		end
		toRemove = {}
	end)
end

mod.create = function(_, config)
	config = require("config"):merge(defaultConfig, config)

	local source = Object()
	source:SetParent(World)
	source.t = 0.0
	source.config = config

	table.insert(sources, source)

	startTickIfNeeded()

	return source
end

return mod
