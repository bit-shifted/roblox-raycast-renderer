local Textures = require(script.Parent.Textures)

local Sprite = {}
Sprite.__index = Sprite

function Sprite.new(TextureNum, Size, Position)
	return setmetatable({
		Size = Size or Vector2.new(1,1),
		Texture = Textures[TextureNum],
		Position = Position or Vector2.new(4,4)
	}, Sprite)
end

return Sprite