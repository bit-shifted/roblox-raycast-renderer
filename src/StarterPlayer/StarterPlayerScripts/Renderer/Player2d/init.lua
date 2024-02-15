local Scene = require(script.Parent.Scene)

local InputService = game:GetService("UserInputService")

local MOVEMENT_INPUTS = {
	W = Vector2.new(0,1),
	A = Vector2.new(-1,0),
	S = Vector2.new(0,-1),
	D = Vector2.new(1,0),
}

local Player = {
	Rotation = 90,
	Position = Vector2.new(5,5),
	Velocity = Vector2.new(),
	
	Acceleration = 20,
	MaxSpeed = 2,
	LookSpeed = 5,
	
	CollisionRadius = 0.25,
	Height = 0.5,
	ViewDistance = 32,
	Fov = 60,
	CameraPlane = Vector2.new(0,0.5)
}

local function RadToVector2(Rad)
	return Vector2.new(math.sin(Rad), math.cos(Rad)) 
end

local function ClampMagnitude(Vector, Max)
	local Clamped = Vector.Unit * math.clamp(Vector.Magnitude, 0, Max)
	return Clamped.Magnitude > 0 and Clamped or Vector2.new()
end

-- Line-circle collision detection
-- Credit: https://www.jeffreythompson.org/collision-detection/line-circle
function PointOnLine(Line, Point)
	-- get distance from the point to the two ends of the line
	local Dist1 = (Point - Line[1]).Magnitude
	local Dist2 = (Point - Line[2]).Magnitude

	-- get the length of the line
	local LineLen = (Line[1] - Line[2]).Magnitude

	-- since floats are so minutely accurate, add
	-- a little buffer zone that will give collision
	local Buffer = 0.1;   -- higher # = less accurate

	-- if the two distances are equal to the line's 
	-- length, the point is on the line!
	-- note we use the buffer here to give a range, 
	-- rather than one #
	if Dist1+Dist2 >= LineLen-Buffer and Dist1+Dist2 <= LineLen+Buffer then
		return true
	end
	
	return false
end


-- Check square in dir of movement
local function IsColliding(Pos)
	local CellPos = Vector2int16.new(Pos.X, Pos.Y)
	local Cell = Scene.Map[CellPos.X + CellPos.Y * Scene.MapSize.Y - Scene.MapSize.Y]
	if not Cell then return end
	
	return Cell ~= 0
end
--

function Player:LookVector()
	return RadToVector2(math.rad(self.Rotation))
end

function Player:RightVector()
	local Look = self:LookVector()
	return Vector2.new(Look.Y, -Look.X)
end

-- Return unit vector based on current movement inputs
function Player:GetMovementVector()
	local Movement = Vector2.new()

	for InputKey,Vector in pairs(MOVEMENT_INPUTS) do
		if InputService:IsKeyDown(Enum.KeyCode[InputKey]) then
			Movement += Vector
		end
	end

	return Movement.Unit
end

function Player:GetRelativeVelocity()
	local Angle = math.rad(self.Rotation)
	return -Vector2.new(
		-self.Velocity.X * math.cos(Angle) - self.Velocity.Y * math.sin(Angle),
		self.Velocity.X * math.sin(Angle) - self.Velocity.Y * math.cos(Angle))
end

function Player:ApplyVelocity(DeltaTime)
	self.Velocity = self:GetMovementVector()*self.Acceleration
	self.Velocity = ClampMagnitude(self.Velocity, self.MaxSpeed)
	
	local RelVelocity = self:GetRelativeVelocity()
	local CellToCheck = self.Position + RelVelocity.Unit * self.CollisionRadius
	
	if not IsColliding(CellToCheck) then
		self.Position += RelVelocity*DeltaTime
	end
end

function Player:ApplyRotation(DeltaTime)
	local Factor = InputService:GetMouseDelta().X
	self.Rotation += DeltaTime*self.LookSpeed * Factor
	if self.Rotation  < 0 then
		self.Rotation += 360
	elseif self.Rotation >= 360 then
		self.Rotation -= 360
	end
end

function Player:ApplyCollision()
	
end

InputService.MouseBehavior = Enum.MouseBehavior.LockCenter

return Player