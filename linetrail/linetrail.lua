--- This module allows you to create trails for bullets and other projectiles that travel in straigh lines.
---@code
--- trail = require("github.com/aduermael/modzh/linetrail")
---
--- -- This will create a trail going from startPos to endPos at a speed of 1000
--- -- The trail is removed (and recycled) when done, no need to worry about that.
--- trail:create({
--- 	startPos = Player.Position,
--- 	endPos = Player.Position + Player.Forward * 500,
--- 	color = Color( 255, 255, 255, 200),
--- 	speed = 1000,
---	})
---
--- -- Default config:
--- {
---		startPos = Number3.Zero,
---		endPos = Number3.Zero,
---		color = Color(255, 255, 255, 220),
---		speed = 1000,
---		size = 0.5,
---		type = "quad", -- can be "quad" or "cube"
---		light = false,
---		lightRadius = 40,
---		lightIntensity = 1.8,
---		lightHardness = 0.5,
--- }

mod = {}

quadPool = {}
cubePool = {}
lightPool = {}

cubeShape = nil

ease = require("ease")
conf = require("config") -- used to merge configs

defaultConfig = {
	startPos = Number3.Zero,
	endPos = Number3.Zero,
	color = Color(255, 255, 255, 220),
	speed = 1000,
	size = 0.5,
	type = "quad", -- can be "quad" or "cube"
	light = false,
	lightRadius = 40,
	lightIntensity = 1.8,
	lightHardness = 0.5,
}

mod.setDefaultSpeed = function(self, speed)
	if self ~= mod then
		error("linetrail:setDefaultSpeed(speed) should be called with `:`", 2)
	end

	if type(speed) ~= "number" and type(speed) ~= "integer" then
		error("linetrail:setDefaultSpeed(speed) - speed should be number", 2)
	end
	defaultConfig.speed = speed
end

mod.create = function(self, config)
	if self ~= mod then
		error("linetrail:create(config) should be called with `:`", 2)
	end

	local ok, err = pcall(function()
		config = conf:merge(defaultConfig, config)
	end)

	if not ok then
		error(err, 2)
	end

	if config.type ~= "quad" and config.type ~= "cube" then
		error('linetrail:create(config) - config.type should be "quad" or "cube"', 2)
	end

	local target = config.endPos:Copy()
	local isQuad = config.type == "quad"

	local t
	if isQuad then
		t = table.remove(quadPool)
		if t == nil then
			t = Quad()
			t.IsUnlit = true
			t.Anchor = { 1, 0.5 }
		end

		t.Color = config.color
		t.Width = 0
		t.Height = config.size
	else
		t = table.remove(cubePool)
		if t == nil then
			if cubeShape == nil then
				cubeShape = MutableShape()
				cubeShape:AddBlock(Color(255, 255, 255), 0, 0, 0)
				cubeShape = Shape(cubeShape)
			end
			t = cubeShape:Copy()
			t.IsUnlit = true
			t.Pivot = { 1, 0.5, 0.5 }
		end

		t.Palette[1].Color = config.color
		t.Scale = { 0, config.size, config.size }
	end

	if config.light == true then
		local l = table.remove(lightPool)
		if l == nil then
			l = Light()
		end
		l.Color = config.color
		l.Radius = config.lightRadius
		l.Intensity = config.lightIntensity
		l.Hardness = config.lightHardness
		t.light = l
		l:SetParent(t)
	end

	t.Position:Set(config.startPos)
	t.Right:Set(config.endPos - config.startPos)
	World:AddChild(t)

	local halfWay = config.startPos + (config.endPos - config.startPos) * 0.5
	local halfDistance = (halfWay - config.startPos).Length
	local halfTime = halfDistance / config.speed

	if isQuad then
		local e = ease:inQuad(t, halfTime, {
			onDone = function()
				local e = ease:outQuad(t, halfTime, {
					onDone = function()
						if t.light then
							t.light:RemoveFromParent()
							table.insert(lightPool, t.light)
							t.light = nil
						end
						t:RemoveFromParent()
						table.insert(quadPool, t)
					end,
				})
				e.Position = target
				e.Width = 0
			end,
		})
		e.Position = halfWay
		e.Width = halfDistance * 0.9
	else
		local e = ease:inSine(t, halfTime, {
			onDone = function()
				local e = ease:outSine(t, halfTime, {
					onDone = function()
						if t.light then
							t.light:RemoveFromParent()
							table.insert(lightPool, t.light)
							t.light = nil
						end
						t:RemoveFromParent()
						table.insert(cubePool, t)
					end,
				})
				e.Position = target
				e.Scale = Number3(0, config.size, config.size)
			end,
		})
		e.Position = halfWay
		e.Scale = Number3(halfDistance * 0.9, config.size, config.size)
	end
end

return mod
