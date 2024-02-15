local Map = {
	"Bricks",
	"WalkStone",
	"SmoothStone",
	"Mud",
	"Gravel",
	"Sky",
	"Pillar",
	"Stone",
	"Planks",
}

local Textures = {}
for Index,TextureName in pairs(Map) do
	Textures[Index] = require(script:FindFirstChild(TextureName))
end

return Textures
