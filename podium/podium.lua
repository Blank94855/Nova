--- A module to create a uikit node that nicely winners at the end of a game.
--- Avatars of the 3 players on the podium are displayed at the top of the frame.
--- A scroll list with all players is displayed below. Clicking on a cell allows to display player profiles.
---@code
--- local podium = require("github.com/aduermael/modzh/podium")
--- -- players should be provides ordered by score DESC
--- -- title can optionally be provided (default value: "Winners")
--- local node = podium:show({ players = {
---         { username = "foo", userID = "4567", score = 777 }
---         { username = "bar", userID = "1234", score = 555 }
---     },
---     title = "Winners",
--- })
--- -- podium is displayed and the center of the screen with default adaptive size.
--- -- like any other uikit node, Width and Height can be changed
--- -- as well as functions like paprentDidResize for positionning.
--- node.Width = 200 -- for example
--- -- to remove the podium:
--- node:remove()
--- -- NOTE: only one podium can be displayed at a time
--- -- to refresh content, call remove then display with updated data.

local mod = {}

local AVATAR_SIZE = 50
local MIN_WIDTH = 200
local MAX_WIDTH = 600
local MIN_HEIGHT = 200
local MAX_HEIGHT = 600
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 600
local CELL_PADDING = 2

local theme = require("uitheme").current

local defaultConfig = {
	title = "Winners",
	players = {
		{ username = Player.Username, userID = Player.UserID, score = 0 },
		{ username = Player.Username, userID = Player.UserID, score = 0 },
		-- { username = "caillef", userID = "caillef", score = 90 },
		-- { username = "aduermael", userID = "aduermael", score = 100 },
		-- { username = "claire", userID = "aduermael", score = 50 },
	}, -- players should be provided in display order (top to bottom)
}

local frame
local removeBackup
local pointerIsHiddenBackup

mod.show = function(self, config)
	if self ~= mod then
		error("ui_podium:show() - should be called with `:`", 2)
	end

	if frame ~= nil then -- display one podium at a type
		error("ui_podium:show(config) - podium is already shown", 2)
	end

	local ok, err = pcall(function()
		config = require("config"):merge(defaultConfig, config)
	end)
	if not ok then
		error(err, 2)
	end

	pointerIsHiddenBackup = Pointer.IsHidden
	Pointer:Show()

	local ui = require("uikit")
	local uiAvatar = require("ui_avatar")

	frame = ui:frameGenericContainer()

	local defaultSize = true
	frame.Width = DEFAULT_WIDTH
	frame.Height = DEFAULT_HEIGHT

	removeBackup = frame.remove
	frame.remove = function(self)
		frame = nil
		removeBackup(self)
	end

	local title = ui:createText(config.title, Color.White, "big")
	title:setParent(frame)

	local players = {}

	for i, p in ipairs(config.players) do
		if i <= 3 then
			local a = uiAvatar:get({ usernameOrId = p.userID or p.username, size = 100 })
			a:setParent(frame)
			table.insert(players, a)
		else
			break
		end
	end

	local cells = {} -- each line: head | name | score(optional)

	local scroll

	local cellParentDidResize = function(self)
		local parent = self.parent or scroll
		if parent == nil then
			self.Height = AVATAR_SIZE + theme.paddingTiny * 2
			return
		end
		self.Width = parent.Width
		if parent == scroll then
			self.Width = self.Width - CELL_PADDING * 2
		end

		local availableWidth = self.Width - theme.padding * 3 - AVATAR_SIZE
		-- use half available width for username and score
		availableWidth = availableWidth * 0.5 - theme.padding

		self.username.object.Scale = 1
		local scale = math.min(1, availableWidth / self.username.Width)
		self.username.object.Scale = scale

		self.score.object.Scale = 1
		scale = math.min(1, availableWidth / self.score.Width)
		self.score.object.Scale = scale

		self.Height = math.max(self.avatar.Height, self.username.Height, self.score.Height) + theme.paddingTiny * 2

		self.avatar.pos = {
			theme.padding,
			self.Height * 0.5 - AVATAR_SIZE * 0.5,
		}

		self.username.pos = {
			theme.padding * 2 + AVATAR_SIZE,
			self.Height * 0.5 - self.username.Height * 0.5,
		}
		self.score.pos = {
			self.Width - self.score.Width - theme.padding,
			self.Height * 0.5 - self.score.Height * 0.5,
		}
	end

	local function formatNumber(num)
		local formatted = tostring(num)
		local k
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
			if k == 0 then
				break
			end
		end
		return formatted
	end

	local loadCell = function(index)
		local p = config.players[index]
		if p == nil then
			return nil
		end

		local cell = cells[index]
		if cell == nil then
			cell = ui:frameScrollCell()

			cell.avatar = uiAvatar:get({
				-- usernameOrId = score.userID,
			})
			cell.avatar:setParent(cell)
			cell.avatar.Width = AVATAR_SIZE
			cell.avatar.Height = AVATAR_SIZE

			cell.username = ui:createText("", { color = Color.White })
			cell.username:setParent(cell)

			cell.score = ui:createText("", { color = Color(200, 200, 200) })
			cell.score:setParent(cell)

			cell.parentDidResize = cellParentDidResize
			cell.onPress = function(_)
				Client:HapticFeedback()
			end

			cell.onRelease = function(self)
				if self.userID ~= nil and self.username.Text ~= nil then
					Menu:ShowProfile({
						id = self.userID,
						username = self.username.Text,
					})
				end
			end

			cells[index] = cell
		end

		cell.userID = p.userID
		cell.username.Text = p.username or ""
		local score = p.score
		if score then
			cell.score.Text = formatNumber(score)
		else
			cell.score.Text = ""
		end
		cell.avatar:load({ usernameOrId = p.userID or p.username })

		cell:parentDidResize()

		return cell
	end

	local unloadCell = function(_, cell)
		cell:setParent(nil)
	end

	scroll = ui:scroll({
		backgroundColor = theme.buttonTextColor,
		direction = "down",
		padding = CELL_PADDING,
		cellPadding = CELL_PADDING,
		loadCell = loadCell,
		unloadCell = unloadCell,
	})
	scroll:setParent(frame)

	local functions = {}

	local _nativeSetWidth
	local _nativeSetHeight

	functions.restoreNativeSizeSetters = function(frame)
		if _nativeSetWidth ~= nil then
			frame._setWidth = _nativeSetWidth
		end
		if _nativeSetHeight ~= nil then
			frame._setHeight = _nativeSetHeight
		end
	end

	functions.installCustomSizeSetters = function(frame)
		if _nativeSetWidth == nil then
			_nativeSetWidth = frame._setWidth
			frame._setWidth = function(self, w)
				defaultSize = false
				_nativeSetWidth(self, w)
				functions.layout(self)
			end
		end
		if _nativeSetHeight == nil then
			_nativeSetHeight = frame._setHeight
			frame._setHeight = function(self, h)
				defaultSize = false
				_nativeSetHeight(self, h)
				functions.layout(self)
			end
		end
	end

	functions.layout = function(frame)
		-- cap size
		functions.restoreNativeSizeSetters(frame)
		if defaultSize then
			frame.Width = DEFAULT_WIDTH
			frame.Height = DEFAULT_HEIGHT
		end
		frame.Width = math.min(
			math.max(MIN_WIDTH, frame.Width),
			Screen.Width - Screen.SafeArea.Left - Screen.SafeArea.Right - theme.padding * 2,
			MAX_WIDTH
		)
		frame.Height = math.min(
			math.max(MIN_HEIGHT, frame.Height),
			Screen.Height - Screen.SafeArea.Top - Screen.SafeArea.Bottom - theme.padding * 2,
			MAX_HEIGHT
		)
		functions.installCustomSizeSetters(frame)

		local playerSize = (frame.Width - theme.padding * 2) / 2.3

		local yCursor = frame.Height - theme.padding

		title.pos.X = frame.Width * 0.5 - title.Width * 0.5
		yCursor = yCursor - title.Height
		title.pos.Y = yCursor

		for i, p in ipairs(players) do
			p.Width = playerSize
			p.pos.Y = yCursor - p.Height
			if i == 1 then
				p.pos.X = frame.Width * 0.5 - p.Width * 0.5
			elseif i == 2 then
				p.pos.X = players[1].pos.X - p.Width * 0.7
				p.pos.Y = p.pos.Y - p.Height * 0.1
			elseif i == 3 then
				p.pos.X = players[1].pos.X + players[1].Width * 0.7
				p.pos.Y = p.pos.Y - p.Height * 0.2
			end
		end

		scroll.pos.Y = theme.padding
		scroll.pos.X = theme.padding
		scroll.Width = frame.Width - theme.padding * 2
		scroll.Height = frame.Height - title.Height - playerSize - theme.padding * 4
	end

	frame.parentDidResizeSystem = function(self)
		functions.layout(self)
	end

	frame.parentDidResize = function(self)
		self.pos = {
			Screen.SafeArea.Left
				+ (Screen.Width - Screen.SafeArea.Left - Screen.SafeArea.Right) * 0.5
				- self.Width * 0.5,
			Screen.SafeArea.Bottom
				+ (Screen.Height - Screen.SafeArea.Top - Screen.SafeArea.Bottom) * 0.5
				- self.Height * 0.5,
		}
	end

	functions.layout(frame)
	frame:parentDidResize()

	return frame
end

mod.remove = function(self)
	if self ~= mod then
		error("ui_podium:remove() - should be called with `:`", 2)
	end

	if frame == nil then
		return
	end

	if pointerIsHiddenBackup ~= nil then
		if pointerIsHiddenBackup == true then
			Pointer:Hide()
		else
			Pointer:Show()
		end
	end

	frame:remove()
end

return mod
