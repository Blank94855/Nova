--- A module to play background music, with a set of existing tracks.
---@code
--- music = require("github.com/aduermael/modzh/music")
--- music:play({track = "arcade-synthwave", volume = 0.3})

local mod = {}

local conf = require("config")
local music = nil

mod.play = function(self, config)
	if self ~= mod then
		error("music:play() should be called with `:`", 2)
	end

	if config == nil and music ~= nil then
		music:Play()
		return
	end

	local defaultConfig = {
		volume = 0.3,
		track = "arcade-synthwave",
		loop = true,
	}
	config = conf:merge(defaultConfig, config)

	HTTP:Get("https://files.cu.bzh/soundtracks/" .. config.track .. ".mp3", function(res)
		if res.StatusCode ~= 200 then
			return
		end
		music = AudioSource()
		music.Sound = res.Body
		music.Volume = config.volume
		music.Loop = config.loop
		music.Spatialized = false
		World:AddChild(music)
		music:Play()
	end)
end

mod.stop = function(self)
	if music then
		music:Stop()
	end
end

return mod
