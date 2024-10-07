--- This module allows you to create Quads providing texture URLs.
--- The Quad is returned upon creation and the texture appears when loaded.
---@code
--- webquad = require("github.com/aduermael/modzh/webquad")
--- local q = webquad:create({ url = "https://raw.githubusercontent.com/aduermael/modzh/refs/heads/main/assets/tex-asphalt.png" })
--- -- q is a regular Object, so you can parent it and position it:
--- q:SetParent(World)
--- q.Position = Player.Position

mod = {}

local defaultConfig = {
	url = "",
	color = Color.Black, -- Quad color, seen while texture is being loaded
}

-- returns Quad and HTTP request
mod.create = function(_, config)
	config = require("config"):merge(defaultConfig, config, {
		acceptTypes = {
			color = { "Color", "table" },
		},
	})

	local q = Quad()

	local req = HTTP:Get(config.url, function(res)
		if res.StatusCode ~= 200 then
			error("webquad: couldn't load image (" .. res.StatusCode .. ")")
		end
		q.Image = res.Body
	end)

	q.Color = config.color
	return q, req
end

return mod
