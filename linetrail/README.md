# Linetrail ☄️

This module allows you to create trails for bullets and other projectiles that travel in straight lines.

![fire.gif](https://raw.githubusercontent.com/aduermael/modzh/main/linetrail/img/lintrails.gif)

### Import: 

```lua
Modules = {
	trail = "github.com/aduermael/modzh/linetrail"
}
```

### Usage

```lua
trail:create({
  startPos = startPosition,
  endPos = endPosition,
  color = Color( 255, 255, 255, 200),
  speed = 1000,
})
```

### Default config:

```lua
{
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
```