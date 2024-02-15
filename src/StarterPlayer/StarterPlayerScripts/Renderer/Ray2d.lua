local Ray2d = {}
Ray2d.__index = Ray2d

-- Radian to 2d direction
local function RadToVector2(Rad)
	return Vector2.new(math.sin(Rad), math.cos(Rad)) 
end

local function GetLineNormal(Point, Line)
	local LineUnit = (Line[1] - Line[2]).Unit
	local RawNormal1 = Point-Line[1]
	local RawNormal2 = RawNormal1:Dot(LineUnit)*LineUnit
	
	return (RawNormal1 - RawNormal2).Unit
end

function Ray2d.new(Origin, Angle, Length)
	return setmetatable({
		Origin = Origin,
		Direction = RadToVector2(Angle)*Length,
		Angle = Angle
	}, Ray2d)
end

-- unit squares instead of lines
function Ray2d:GridCast(Map)
	local UnitDir = self.Direction.Unit
	local StepSizes = Vector2.new( -- Unit along grid cell axis
		math.sqrt(1 + (UnitDir.Y/UnitDir.X)*(UnitDir.Y/UnitDir.X)),
		math.sqrt(1 + (UnitDir.X/UnitDir.Y)*(UnitDir.X/UnitDir.Y)))
	
	local MapVec = {
		X = math.floor(self.Origin.X),
		Y = math.floor(self.Origin.Y),
	}
	local AccumlatedLength = {X = 0, Y = 0}
	
	local RayStep = {X = 0, Y = 0}
	
	if UnitDir.X < 0 then
		RayStep.X = -1
		AccumlatedLength.X = (self.Origin.X - MapVec.X) * StepSizes.X
	else
		RayStep.X = 1
		AccumlatedLength.X = (MapVec.X+1 - self.Origin.X) * StepSizes.X
	end
	
	if UnitDir.Y < 0 then
		RayStep.Y = -1
		AccumlatedLength.Y = (self.Origin.Y - MapVec.Y) * StepSizes.Y
	else
		RayStep.Y = 1
		AccumlatedLength.Y = ((MapVec.Y+1) - self.Origin.Y) * StepSizes.Y
	end
	
	-- Grid stepping until solid tile is hit
	local SolidHit = false
	local DistanceTraveled = 0
	local AxisHit = 0-- Which grid line axis the ray intersected with 0 = x, 1 = y
	local PerpWallDist = 0
	local Cell = nil
	
	-- Max walk dist determined by player view distance
	while not SolidHit and DistanceTraveled < self.Direction.Magnitude do 
		if AccumlatedLength.X < AccumlatedLength.Y then
			MapVec.X += RayStep.X
			DistanceTraveled = AccumlatedLength.X
			AccumlatedLength.X += StepSizes.X
			AxisHit = 0
		else
			MapVec.Y += RayStep.Y
			DistanceTraveled = AccumlatedLength.Y
			AccumlatedLength.Y += StepSizes.Y
			AxisHit = 1
		end
		
		local CellMapIndex = 16 * MapVec.Y+MapVec.X - 16
		Cell = Map[CellMapIndex]
		if not Cell then break end
		
		if Cell > 0 then
			SolidHit = true
		end
	end
	
	-- Gets the dist along the camera's view plane
	if AxisHit == 0 then
		PerpWallDist = (AccumlatedLength.X - StepSizes.X)
	else         
		PerpWallDist = (AccumlatedLength.Y - StepSizes.Y)
	end
	MapVec = Vector2.new(MapVec.X, MapVec.Y)
	
	if SolidHit then
		local EndIntersect = self.Origin + UnitDir * DistanceTraveled
		--local FlooredIntersect = Vector2.new(math.floor(EndIntersect.X), math.floor(EndIntersect.Y))
		local SurfaceVec = AxisHit == 0 and Vector2.new(0,1) or Vector2.new(1,0)
		local HitNormal = GetLineNormal(self.Origin, {MapVec - SurfaceVec, MapVec})
		
		return {
			Hit = EndIntersect,
			PerpendicularDist = PerpWallDist,
			Normal = HitNormal.Unit,
			TextureNum = Cell,
			AxisHit = AxisHit,
		}
	end
end

-- Line-line intersection
function Ray2d:Cast(Objects)
	local ClosestDist = math.huge
	local ClosestHit = nil
	
	for _,Object in ipairs(Objects) do
		-- Obstacle line
		local x1, y1 = Object[1].X, Object[1].Y
		local x2, y2 = Object[2].X, Object[2].Y
		-- Ray line
		local x3, y3 = self.Origin.X, self.Origin.Y
		local x4, y4 = self.Origin.X + self.Direction.X, self.Origin.Y + self.Direction.Y

		local Denominator = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
		if Denominator == 0 then break end
		
		local DT = (x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)
		local DU = (x1-x3)*(y1-y2) - (y1-y3)*(x1-x2)
		local T, U = DT/Denominator, DU/Denominator
		
		if T >= 0 and T <= 1 and U > 0 then
			-- Ray has hit
			local Hit = Vector2.new(x1 + T*(x2-x1), y1 + T*(y2-y1))
			local Dist = (Hit - self.Origin).Magnitude
			local Normal = GetLineNormal(self.Origin, Object)
			
			if Dist < ClosestDist then
				ClosestDist = Dist
				ClosestHit = {
					Hit = Hit, 
					Normal = Normal, 
					Object = Object,
				}
			end
		end
	end
	
	return ClosestHit
end

return Ray2d