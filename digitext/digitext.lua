--- A module to create UI texts custom bitmap fonts, for digits only (cool to display scores, timers, etc.)
---@code
--- digitext = require("github.com/aduermael/modzh/digitext")
--- local t = digitext({ text = "1234", font = "purple-outlined", size = 30 })
--- t:setParent(someUINode)
--- -- config.text accepts numbers/integers too:
--- local t = digitext({ text = 1234, font = "purple-outlined", size = 30 })

local mod = {}

local conf = require("config")
local ui = require("uikit")

local privateFields = setmetatable({}, { __mode = "k" })

local fonts = {}
fonts["purple-outlined"] = {
	texture = "https://github.com/aduermael/modzh/blob/main/digitext/fonts/purple-outlined.png?raw=true",
	charSize = Number2(36, 56),
	-- computed / downloaded:
	quadData = nil,
}

local defaultConfig = {
	text = "",
	size = 20,
	font = "purple-outlined",
	color = Color.White,
}

local charFrame
local q
local charRatio
local charWidth
local contentDidResizeBackup
local function refresh(t)
	local fields = privateFields[t]
	if fields == nil then
		return
	end
	local font = fields.font
	if font == nil then
		return
	end
	local config = fields.config
	if config == nil then
		return
	end

	charRatio = font.charSize.Width / font.charSize.Height
	charWidth = fields.config.size * charRatio
	t.Width = #fields.digits * charWidth

	if font.quadData == nil then
		-- quad data not yet loaded, just return!
		return
	end

	contentDidResizeBackup = t.contentDidResize
	t.contentDidResize = nil

	local nbCharFrames = #fields.charFrames
	local nbDigits = #fields.digits

	while nbCharFrames < nbDigits do
		charFrame = ui:frame({ color = fields.config.color })
		q = charFrame:getQuad()
		q.Image = {
			data = font.quadData,
			cutout = true,
		}
		q.Tiling = { 0.1, 1 }
		charFrame:setParent(t)
		table.insert(fields.charFrames, charFrame)
		nbCharFrames = nbCharFrames + 1
	end

	for i = 1, nbCharFrames do
		charFrame = fields.charFrames[i]
		if i > nbDigits then
			charFrame:hide()
		else
			charFrame:show()
			charFrame:getQuad().Offset:Set(fields.digits[i] * 0.1, 0)
			charFrame.Height = config.size
			charFrame.Width = charWidth
			charFrame.pos.X = (i - 1) * charWidth
		end
	end

	t.contentDidResize = contentDidResizeBackup
	if t.contentDidResize then
		t:contentDidResize()
	end
end

local function setText(t, text)
	local fields = privateFields[t]
	if fields == nil then
		return
	end
	local font = fields.font
	if font == nil then
		return
	end

	if type(text) == "number" or type(text) == "integer" then
		text = tostring(math.floor(text))
	end

	fields.digits = {}

	for i = 1, #text do
		local char = text:sub(i, i)
		local charCode = string.byte(char)

		if charCode >= 48 and charCode <= 57 then
			local digit = charCode - 48
			table.insert(fields.digits, digit)
		end
	end

	refresh(t)
end

setmetatable(mod, {
	__index = {},
	__newindex = function()
		error("digitext module is read-only", 2)
	end,
	__metatable = false,
	__call = function(_, config)
		config = conf:merge(defaultConfig, config, {
			acceptTypes = {
				text = { "string", "number", "integer" },
			},
		})

		local font = fonts[config.font]

		if font == nil then
			error("digitext(config) - unknown config.font", 2)
		end

		local t = ui:frame()
		privateFields[t] = {
			config = config,
			font = font,
			charFrames = {},
			digits = {},
		}

		t.Height = config.size
		setText(t, config.text)

		t._setText = setText

		local req = HTTP:Get(font.texture, function(res)
			if res.StatusCode ~= 200 then
				error("webquad: couldn't load image (" .. res.StatusCode .. ")")
			end
			font.quadData = res.Body
			refresh(t)
		end)

		t.onRemove = function()
			req:Cancel()
		end

		return t
	end,
})

return mod
