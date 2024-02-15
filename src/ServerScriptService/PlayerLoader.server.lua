local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local CanvasGui = StarterGui:WaitForChild("CanvasGui")

local function OnPlayerAdded(Player)
	local PlayerGui = Player:WaitForChild("PlayerGui")
	for _,v in pairs(StarterGui:GetChildren()) do
		local Clone = v:Clone()
		
		Clone.Parent = PlayerGui
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

for _,Player in pairs(Players:GetPlayers()) do
	OnPlayerAdded(Player)
end