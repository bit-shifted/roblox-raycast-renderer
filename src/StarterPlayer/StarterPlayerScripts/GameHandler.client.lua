local Renderer, Scene, Player, Canvas = require(script.Parent.Renderer)()

local function OnStart()
    print('Game started.')
end

local function OnUpdate(delta)
    --game loop
end

Renderer:Start(OnStart, OnUpdate)