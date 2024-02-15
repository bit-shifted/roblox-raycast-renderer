local Canvas = require(script.Canvas)
local Scene = require(script.Scene)
local Ray2d = require(script.Ray2d)
local Player = require(script.Player2d)
local Textures = require(script.Textures)

local RunService = game:GetService("RunService")

local ProjectionDistance = Canvas.Resolution/2 / math.tan(math.rad(Player.Fov/2)) -- How far the camera 'plane' is in front of the player
local DegreesPerColumn = Player.Fov/Canvas.Resolution 
local TextureWidth, TextureHeight = 64, 64
local SkyTextureStep = Vector2.new(128/Canvas.Resolution, 128/Canvas.Resolution)

local function IntToRgb(Int)
	if not Int then return end
	return Color3.fromRGB(math.floor(Int / 65536) % 256, math.floor(Int / 256) % 256, Int % 256)
end

local function WorldToScreenPos(WorldPos)
	local PlayerToWorld = WorldPos - Player.Position
	local AngleFromSprite = math.deg(math.atan2(PlayerToWorld.Y , -PlayerToWorld.X))

	if AngleFromSprite < 0 then AngleFromSprite += 360 end

	local AdjustedPlayerRot = Player.Rotation+90
	if AdjustedPlayerRot  < 0 then
		AdjustedPlayerRot += 360
	elseif AdjustedPlayerRot >= 360 then
		AdjustedPlayerRot -= 360
	end
	local LeftFovDifference = AngleFromSprite - AdjustedPlayerRot + (Player.Fov/2)


	if AdjustedPlayerRot < 90 and AngleFromSprite > 270 then
		LeftFovDifference -= 360
	end

	if AdjustedPlayerRot > 270 and AngleFromSprite < 90 then
		LeftFovDifference  += 360
	end

	return Vector2int16.new(LeftFovDifference * (Canvas.Resolution/Player.Fov), Canvas.Resolution/2), AngleFromSprite
end

local function RenderWallColumn(HitData, Column, ColumnHeight, ColumnRay)
	local Dist = HitData.PerpendicularDist
	local AxisHit = HitData.AxisHit
	local Normal = HitData.Normal
	local TextureNum = HitData.TextureNum
	local LightFac = (Normal:Dot(Vector2.new(0,1))+2)/2 -- 0.5-1.5

	-- Y Draw
	local DrawStart = math.floor(-ColumnHeight / 2 + Canvas.Resolution / 2)
	local DrawEnd = math.floor(ColumnHeight / 2 + Canvas.Resolution / 2)

	DrawStart = math.clamp(DrawStart, 1, Canvas.Resolution)
	DrawEnd = math.clamp(DrawEnd, 1, Canvas.Resolution)

	--Invisible walls (99) are anything but rendered
	if TextureNum ~= 99 then
		-- Get texture column
		local wallX;
		if (AxisHit == 0) then
			wallX = Player.Position.Y + Dist * ColumnRay.Direction.Unit.Y
		else
			wallX = Player.Position.X + Dist * ColumnRay.Direction.Unit.X
		end
		wallX -= math.floor(wallX)

		local TextureX = math.ceil(wallX * TextureWidth)

		if AxisHit == 0 and ColumnRay.Direction.X > 0 then
			TextureX = TextureWidth - TextureX + 1
		elseif AxisHit == 1 and ColumnRay.Direction.Y < 0 then
			TextureX = TextureWidth - TextureX + 1
		end

		-- Apply scaled texture
		local TextureStep = TextureHeight/ColumnHeight
		local TexturePos = (DrawStart - Canvas.Resolution / 2 + ColumnHeight / 2)*TextureStep

		for Y = DrawStart, DrawEnd do
			if Y > Canvas.Resolution then break end

			local Pixel = Canvas.Pixels[Y][Column]
			local TextureY = bit32.band(math.round(TexturePos), TextureHeight - 1)+1
			--local TexturePixel = TextureX + TextureY * TextureHeight - TextureHeight
			TexturePos += TextureStep
			--print(TextureX, TextureY)
			local ColorInt = Textures[TextureNum][TextureX][TextureY]
			local RgbColor = IntToRgb(ColorInt or 8355711)
			local ShadedColor = Color3.new(RgbColor.R*LightFac, RgbColor.G*LightFac, RgbColor.B*LightFac)

			Pixel.BackgroundColor3 = ShadedColor
		end
	end

	return DrawEnd -- Where to start floor/ceil
end

local function GetSkyPixelColor(Column, PixelY)
	local WrappedColumn = Player.Rotation + Column % Canvas.Resolution
	local TexX = math.round(WrappedColumn * SkyTextureStep.X)
	local TexY = math.round(PixelY * SkyTextureStep.Y)
	--print(TexX + TexY * TextureHeight - TextureHeight)
	return IntToRgb(Textures[6][TexX + TexY * TextureHeight - TextureHeight])
end

local function RenderSkyColumn(Column)
	for Y = 1, math.round(Canvas.Resolution/1.5) do
		local WrappedColumn = (Player.Rotation*2 + Column) % Canvas.Resolution
		local TexX = math.floor(WrappedColumn * SkyTextureStep.X)+1
		local TexY = math.floor(Y * SkyTextureStep.Y)
		--print(TexX + TexY * TextureHeight - TextureHeight)
		--print(TexX, TexY)
		local Color = IntToRgb(Textures[6][TexX][TexY])
		Canvas.Pixels[Y][Column].BackgroundColor3 = Color or Color3.new()
	end
end

-- Floor and ceiling
local function RenderFloorColumn(Column, ColumnRay, FloorStart)
	-- Any pixels left over will become the floor/ceiling; iterate the rest of vertical strip


	for Y = FloorStart, Canvas.Resolution do
		local CenterDelta =  math.round(Y - Canvas.Resolution/2)
		local RelativeRayAngle = ColumnRay.Angle - math.rad(Player.Rotation)
		local StraightDistToFloor = Player.Height * ProjectionDistance/CenterDelta
		local TrueFloorDist = StraightDistToFloor/ math.cos(RelativeRayAngle) 

		local FloorPos = Vector2.new(
			math.sin(ColumnRay.Angle) * TrueFloorDist + Player.Position.X,
			math.cos(ColumnRay.Angle) * TrueFloorDist + Player.Position.Y
		)

		local TexturePixel = Vector2.new(
			math.round(FloorPos.X*TextureWidth)%TextureWidth+1,
			math.round(FloorPos.Y*TextureHeight)%TextureHeight+1
		)
		local FloorCeilIndex = Scene.MapSize.X * math.floor(FloorPos.Y) + math.floor(FloorPos.X) - Scene.MapSize.X --math.floor(FloorPos.X) +  math.floor(FloorPos.Y) * Scene.MapSize.Y - Scene.MapSize.Y; print(FloorPos, FloorCeilIndex)
		local FloorCell = Scene.Floor[FloorCeilIndex]
		local CeilCell = Scene.Ceiling[FloorCeilIndex]
		FloorCell = FloorCell == 0 and 5 or FloorCell -- Tile default

		local FloorTexture = Textures[FloorCell or 5]
		local CeilTexture = Textures[CeilCell or 0]
		local FloorColor = IntToRgb(FloorTexture[TexturePixel.X][TexturePixel.Y]) --FloorTexture[TexturePixel.X + TexturePixel.Y * TextureHeight - TextureHeight])


		-- Ceiling identical to floors, just get pixel above wall column (delta - screenheight/2)
		local CeilingY = math.floor(math.max(Canvas.Resolution/2 - CenterDelta, 1))
		local FloorPixel = Canvas.Pixels[Y][Column]
		local CeilingPixel = Canvas.Pixels[CeilingY][Column]

		-- Sky shows through invisible ceiling
		if CeilTexture and CeilTexture ~= 0 then
			local CeilingColor = IntToRgb(CeilTexture[TexturePixel.X][TexturePixel.Y])--[TexturePixel.X + TexturePixel.Y * TextureHeight - TextureHeight])
			CeilingPixel.BackgroundColor3 = CeilingColor
		end
		FloorPixel.BackgroundColor3 = FloorColor
	end
end

local function RenderSpritesColumn(Column, WallDepth)
	for _,Sprite in pairs(Scene.Sprites) do

		local ScreenPos = Sprite.CachedScreenPos
		local SpriteHalfDist = Sprite.CachedDist
		local AdjustedSize = Sprite.Size/SpriteHalfDist
		local ScreenSize = Vector2.new(
			TextureWidth/SpriteHalfDist,
			TextureHeight/SpriteHalfDist
		)
		local TextureStep = Vector2.new(
			TextureWidth/ScreenSize.X,
			TextureHeight/ScreenSize.Y
		)

		local PixelOffset = Vector2int16.new(
			math.round(ScreenPos.X - ScreenSize.X/2)*TextureStep.X,
			math.round(ScreenPos.Y - ScreenSize.Y/2)*TextureStep.Y
		)
		local StartY = math.round(math.max(ScreenPos.Y - ScreenSize.Y/2, 1))
		local EndY =  math.round(math.min(ScreenPos.Y + ScreenSize.Y/2, Canvas.Resolution))

		if Column >= ScreenPos.X - ScreenSize.X/2 and Column <= ScreenPos.X + ScreenSize.X/2 then
			if SpriteHalfDist*2 > WallDepth then break end --Sprite column is behind a wall

			local SizeYDiff = math.max(math.round(ScreenSize.Y - TextureHeight), 0)
			local TexX = math.round((Column - math.round(ScreenPos.X - ScreenSize.X/2))*TextureStep.X)

			for Y = StartY, EndY do
				local Row = Y
				local Pixel = Canvas.Pixels[Y][Column]
				local TexY = math.round((Row - math.round(ScreenPos.Y - ScreenSize.Y/2))*TextureStep.Y)

				TexX = math.clamp(TexX, 1, TextureWidth)
				TexY = math.clamp(TexY, 1, TextureHeight)

				if not Sprite.Texture[TexX] or not Sprite.Texture[TexX][TexY] then
					print(TexX, TexY, Y, TextureStep.Y)
				end

				local Color = Sprite.Texture[TexX][TexY]--[TexX + TexY * TextureHeight - TextureHeight]

				if Pixel and Color and Color ~= 0 then
					Pixel.BackgroundColor3 = IntToRgb(Color)
				end
			end
		end
	end
end
--[[


local function RenderSpritesColumn(Column, WallDepth)
	for _,Sprite in pairs(Scene.Sprites) do

		local ScreenPos = Sprite.CachedScreenPos
		local SpriteHalfDist = Sprite.CachedDist
		local AdjustedSize = Sprite.Size/SpriteHalfDist
		local ScreenSize = Vector2.new(
			TextureWidth/SpriteHalfDist,
			TextureHeight/SpriteHalfDist
		)
		local TextureStep = Vector2.new(
			TextureWidth/ScreenSize.X,
			TextureHeight/ScreenSize.Y
		)

		local PixelOffset = Vector2int16.new(
			math.round(ScreenPos.X - ScreenSize.X/2)*TextureStep.X,
			math.round(ScreenPos.Y - ScreenSize.Y/2)*TextureStep.Y
		)
		local YBounds = {
			math.round(math.max(ScreenPos.Y - ScreenSize.Y/2, 1)),
			math.round(math.min(ScreenPos.Y + ScreenSize.Y/2, Canvas.Resolution))
		}
		local XBounds = {
			math.round(math.max(ScreenPos.X - ScreenSize.X/2, 1)),
			math.round(math.min(ScreenPos.X + ScreenSize.X/2, Canvas.Resolution))
		}
		
		
		if Column >= XBounds[1] and Column <= XBounds[2] then
			if SpriteHalfDist*2 > WallDepth then break end --Sprite column is behind a wall
			local SizeYDiff = math.max(math.round(ScreenSize.Y - TextureHeight), 0)
			local TexX = math.round((Column - math.round(ScreenPos.X - ScreenSize.X/2))*TextureStep.X)

			for Y = YBounds[1], YBounds[2] do
				local Pixel = Canvas.Pixels[Y][Column]
				local TexY = math.round((Y - math.round(ScreenPos.Y - ScreenSize.Y/2))*TextureStep.Y)
				if not Sprite.Texture[TexX] or not Sprite.Texture[TexX][TexY] then
					print(TexX, TexY, Y, YBounds[1], TextureStep.Y)
				end
				local Color = Sprite.Texture[TexX][TexY]

				if Pixel and Color and Color ~= 0 then
					Pixel.BackgroundColor3 = IntToRgb(Color)
				end
			end
		end
	end
end

]]

-- Casts a cone of rays in front of the player
local function RenderCast()
	local ViewDistance = Player.ViewDistance
	local PlayerPos = Player.Position
	local PlayerDir = Player:LookVector()
	local PlayerHeight = Player.Height
	local RenderStartTick = tick()

	-- Sprite render data for this frame
	for _,Sprite in pairs(Scene.Sprites) do
		local d = (Sprite.Position - Player.Position)
		Sprite.CachedScreenPos, Sprite.PlayerAngleFromSprite = WorldToScreenPos(Sprite.Position)
		Sprite.CachedDist = d.Magnitude/2
	end

	-- Render walls on top of floor/ceiling pixels
	for Column = 1,Canvas.Resolution do
		local Angle = math.rad(Player.Fov/Canvas.Resolution*Column - Player.Fov/2 + Player.Rotation)
		local ColumnRay = Ray2d.new(PlayerPos, Angle, ViewDistance)
		local HitData = ColumnRay:GridCast(Scene.Map)

		RenderSkyColumn(Column)

		if HitData then
			local Normal = HitData.Normal
			local Dist = HitData.PerpendicularDist
			local Hit = HitData.Hit

			local WallDepth = Dist * math.cos(Angle - math.rad(Player.Rotation))
			local ColumnHeight = math.round(Canvas.Resolution/WallDepth)

			-- Wall, floors, ceiling and sky
			local FloorStart = RenderWallColumn(HitData, Column, ColumnHeight, ColumnRay)
			RenderFloorColumn(Column, ColumnRay, FloorStart)
			RenderSpritesColumn(Column, WallDepth)
		end
	end
end

--# Interface
local Renderer = {
	Running = false
}

function Renderer:Start(StartFunc, UpdateFunc)
	task.spawn(StartFunc)
	Canvas:Clear()
	Canvas.Frame.Visible = true
	self.UpdateFunc = UpdateFunc
	self.Running = true
end

function Renderer:Stop()
	Canvas:Clear()
	Canvas.Frame.Visible = false
	self.Running = false
end

Canvas:Initialize()

RunService.RenderStepped:Connect(function(DeltaTime)
	if Renderer.Running then
		local LastPos = Player.Position

		Player:ApplyRotation(DeltaTime)
		Player:ApplyVelocity(DeltaTime)
		Renderer.UpdateFunc(DeltaTime)
		RenderCast()
	end
end)

return function() return unpack({Renderer, Scene, Player, Canvas}) end