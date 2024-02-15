local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CanvasGui = PlayerGui:WaitForChild("CanvasGui")

local Canvas = {
	Gui = CanvasGui,
	Frame = CanvasGui.BackgroundFrame.Canvas,
	Resolution = 128,
	Pixels = {},
	AbsoluteSize = Vector2.new(),
}

function Canvas:CreatePixel(Parent, Order)
	local Pixel = Instance.new("Frame", Parent)
	Pixel.BorderSizePixel = 0
	Pixel.BackgroundColor3 = Color3.new()
	Pixel.LayoutOrder = Order or 0
	
	return Pixel
end

-- Only clear non blank pixels
function Canvas:Clear()
	for Y = 1, self.AbsoluteSize.Y do
		for X = 1, self.AbsoluteSize.X do
			local Pixel = self.Pixels[Y][X]
			if Pixel.BackgroundTransparency ~= 1 then
				Pixel.BackgroundColor3 = Color3.new()
			end
		end
	end
end

function Canvas:Initialize()
	local CanvasFrame =  Canvas.Gui.BackgroundFrame.Canvas
	self.AbsoluteSize = Vector2.new(self.Resolution, self.Resolution)
	CanvasFrame.PixelGrid.CellSize = UDim2.fromScale(1/self.AbsoluteSize.X, 1/self.AbsoluteSize.Y)
	
	-- Create blank pixel grid order doesnt matter
	for Y = 1, self.AbsoluteSize.Y do
		--task.wait()
		self.Pixels[Y] = {}
		for X = 1, self.AbsoluteSize.X do
			local Pixel = self:CreatePixel(CanvasFrame, self.Resolution * Y + X)-- X + Y * CanvasResolution)

			self.Pixels[Y][X] = Pixel
		end
	end
end

return Canvas