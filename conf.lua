local gridSize = 35
local sqrSize = 30

function love.conf(t)
    t.window.width = sqrSize*gridSize
    t.window.height = sqrSize*gridSize
    t.window.borderless = true
end