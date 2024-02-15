local InputService = game:GetService("UserInputService")

local MOVEMENT_INPUTS = {
	W = Vector2.new(0,1),
	A = Vector2.new(-1,0),
	S = Vector2.new(0,-1),
	D = Vector2.new(1,0),
}

local Input = {}

-- Return unit vector based on current movement inputs
function Input:GetMovementVector()
	local UnitMovement = Vector2.new()
	
	for InputKey,Vector in pairs(MOVEMENT_INPUTS) do
		if InputService:IsKeyDown(Enum.KeyCode[InputKey]) then
			UnitMovement += Vector
		end
	end
	
	return UnitMovement
end

return Input