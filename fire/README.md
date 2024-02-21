# Fire 🔥

This module allows you to create fire Objects.

![fire.gif](https://raw.githubusercontent.com/aduermael/modzh/main/fire/img/fire.gif)

### Usage: 

```lua
Modules = {
	fire = "github.com/aduermael/modzh/fire"
}

Client.OnStart = function()
	Player:SetParent(World)
	Camera:SetModeThirdPerson()
	
	f = fire:create()
	f:SetParent(Player)
	-- now Player is on fire
end
```