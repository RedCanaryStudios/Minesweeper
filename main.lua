local gridSize = 35
local sqrSize = 30
local density = 0.125
local grid = {}
local revealed = {}
local flag = love.graphics.newImage("red-flag.png")
local predictions = {}
local predictions2 = {}
local dbh = {}
local isFirst = true

local function genGrid(itms, space)
    local sqrln = math.ceil(math.sqrt(itms))

    return function(idx)
        return (math.ceil(idx/sqrln) - sqrln/2)*space, (((idx-1) % sqrln) + 1 - sqrln/2)*space
    end
end

local function getNeighbors(n, t)
    local s = {}
    local r = (n % t)+1

    local function check(i)
        if i <= 0 then return end
        if i > t^2 then return end
        if math.abs(((n-1)%t)+1 - (((i-1)%t)+1)) > 1 then return end

        table.insert(s, i)
    end

    check(n-1)
    check(n+1)
    check(n+t)
    check(n-1+t)
    check(n+1+t)
    check(n-t)
    check(n-1-t)
    check(n+1-t)

    return s
end

local XRAY = false

local AI = {}
AI.mods = {}

AI.MouseProxy = {x = love.mouse.getX(), y = love.mouse.getY()}

AI.Enabled = false

AI.NextTarget = nil;
AI.Speed = 300;

AI.dist = function(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

AI.Step = function(dt)
    if AI.NextTarget and AI.Enabled then
        if AI.dist(AI.MouseProxy.x, AI.MouseProxy.y, AI.NextTarget[1], AI.NextTarget[2]) < 1 then
            love.mouse.setPosition(AI.NextTarget[1], AI.NextTarget[2])
            local click = AI.NextTarget[3]
            AI.NextTarget = nil
            if AI.Callback then
                AI.Callback(AI.MouseProxy.x, AI.MouseProxy.y, click)
            end
        else
            local d = AI.dist(AI.MouseProxy.x, AI.MouseProxy.y, AI.NextTarget[1], AI.NextTarget[2])
            local dirx, diry = (AI.NextTarget[1] - AI.MouseProxy.x), (AI.NextTarget[2] - AI.MouseProxy.y)
            AI.MouseProxy.x = AI.MouseProxy.x + (dirx/d)*dt*AI.Speed*(d/10)
            AI.MouseProxy.y = AI.MouseProxy.y + (diry/d)*dt*AI.Speed*(d/10)
            love.mouse.setX(AI.MouseProxy.x)
            love.mouse.setY(AI.MouseProxy.y)
        end
    end
end

AI.Callback = function(mx, my, click)
    love.mousepressed(mx, my, click)
end

AI.mods.next = function(x, y)
    local avail = {}
    local f = genGrid(gridSize^2, sqrSize)
    for i = 1, #predictions do
        if not (revealed[predictions[i]] == -10) then
            local px, py = f(predictions[i])
            px, py = px+love.graphics.getWidth()/2-sqrSize, py+love.graphics.getHeight()/2-sqrSize
            table.insert(avail, {AI.dist(x, y, px + sqrSize/2, py + sqrSize/2), px + sqrSize/2, py + sqrSize/2, predictions2[i], 2})
        end
    end
    for i = 1, #predictions2 do
        local px, py = f(predictions2[i])
        px, py = px+love.graphics.getWidth()/2-sqrSize, py+love.graphics.getHeight()/2-sqrSize
        table.insert(avail, {AI.dist(x, y, px + sqrSize/2, py + sqrSize/2), px + sqrSize/2, py + sqrSize/2, predictions2[i], 1})
    end
    table.sort(avail, function(a, b)
        return a[1] < b[1]
    end)

    if avail[1] then
        AI.NextTarget = {avail[1][2], avail[1][3], avail[1][5]}
        dbh = {avail[1][4]}
    end  
end

table.find = function(t, e)
    for i, v in ipairs(t) do
        if v == e then return i end
    end
    return nil
end

local nums = {}

for i = 1, 8 do
    nums[i] = love.graphics.newText(love.graphics.newFont("OPTIAntique-Bold.otf", sqrSize*0.5), tostring(i))
end

math.randomseed(os.time())

local function reset()
    for i = 1, gridSize^2 do
        if math.random(1, 1/density) == 1 then
            grid[i] = 20
        else
            grid[i] = 0
        end
    end
    
    for i = 1, #grid do
        revealed[i] = -1
    end
    
    for i = 1, #grid do
        for _, v in ipairs(getNeighbors(i, gridSize)) do
            if grid[v] > 19 then
                grid[i] = grid[i] + 1
            end
        end
    end
end

function love.load()
    reset()
end

function love.update(dt)
    AI.Step(dt)
end

function love.draw()
    local f = genGrid(gridSize^2, sqrSize)

    for i = 1, gridSize^2 do
        local x, y = f(i)
        
        if i % 2 == 0 then
            if revealed[i] == -1 or revealed[i] == -10 then
                love.graphics.setColor(191/255, 225/255, 125/255)
            else
                love.graphics.setColor(229/255, 194/255, 159/255)
            end
        else
            if revealed[i] == -1 or revealed[i] == -10 then
                love.graphics.setColor(142/255, 204/255, 57/255)
            else
                love.graphics.setColor(215/255, 184/255, 153/255)
            end
        end

        love.graphics.rectangle('fill', x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, sqrSize, sqrSize)
        if not (revealed[i] == -1) and not (revealed[i] == 0) and not (revealed[i] == -10) then
            if revealed[i] == 0 then
                love.graphics.setColor(1, 1, 1)
            elseif revealed[i] == 1 then
                love.graphics.setColor(0.3, 0.3, 0.8)
            elseif revealed[i] == 2 then
                love.graphics.setColor(0.3, 0.7, 0.3)
            elseif revealed[i] == 3 then
                love.graphics.setColor(0.8, 0.3, 0.3)
            elseif revealed[i] == 4 then
                love.graphics.setColor(0, 0.5, 0.5)
            elseif revealed[i] == 5 then
                love.graphics.setColor(0.2, 0, 0)
            elseif revealed[i] == 6 then
                love.graphics.setColor(1, 0, 1)
            elseif revealed[i] == 7 then
                love.graphics.setColor(0.9, 0.9, 0.9)
            elseif revealed[i] == 8 then
                love.graphics.setColor(0.1, 0, 0)
            elseif revealed[i] == -10 then
                love.graphics.setColor(1, 0, 0)
            elseif revealed[i] >= 20 then
                love.event.quit("restart")
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.draw(nums[revealed[i]], x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, 0, nil, nil, -sqrSize/4, -sqrSize/8)
        end
    end

    for i = 1, gridSize^2 do
        if revealed[i] == -10 then
            local x, y = f(i)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(flag, x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, 0, sqrSize/512, sqrSize/512, -sqrSize/4, -sqrSize/8)
        end
    end

    local x, y = math.floor(love.mouse.getX()/sqrSize), math.floor(love.mouse.getY()/sqrSize)+1
    local n = x*gridSize+y
    x, y = f(n)

    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle('fill', x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, sqrSize, sqrSize)

    if XRAY then
        for _, v in ipairs(dbh) do
            local x, y = f(v)
            
            love.graphics.setColor(1, 0, 1, 0.5)
    
            love.graphics.rectangle('fill', x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, sqrSize, sqrSize)
        end
    
        for _, v in ipairs(predictions) do
            local x, y = f(v)
            
            love.graphics.setColor(1, 0, 0, 0.5)
    
            love.graphics.rectangle('fill', x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, sqrSize, sqrSize)
        end
    
        for _, v in ipairs(predictions2) do
            local x, y = f(v)
            
            love.graphics.setColor(0, 0, 1, 0.5)
    
            love.graphics.rectangle('fill', x+love.graphics.getWidth()/2-sqrSize, y+love.graphics.getHeight()/2-sqrSize, sqrSize, sqrSize)
        end
    end

    if dbg then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(dbg))
    end
end

local revealCache = {}
local function reveal(n)
    if isFirst then
        if not (grid[n] == 0) then
            reset()
            return reveal(n)
        end
    end
    isFirst = false
    if revealed[n] == -10 then return end

    revealed[n] = grid[n]

    revealCache[n] = true

    if revealed[n] == 0 then
        for _, v in ipairs(getNeighbors(n, gridSize)) do
            if not revealCache[v] then
                reveal(v)
            end
        end
    end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        local x, y = math.floor(mx/sqrSize), math.floor(my/sqrSize)+1
        local n = x*gridSize+y
        reveal(n)

        predictions = {}
        predictions2 = {}
        for i = 1, 2 do
            for i = 1, gridSize^2 do
                if revealed[i] > 0 and revealed[i] < 9 then
                    local neighbors = {}
                    for _, v in ipairs(getNeighbors(i, gridSize)) do
                        if revealed[v] == -1 or revealed[v] == -10 then
                            table.insert(neighbors, v)
                        end
                    end

                    if #neighbors == revealed[i] then
                        for _, v in ipairs(neighbors) do
                            if not table.find(predictions, v) then
                                table.insert(predictions, v)
                            end
                        end
                    end

                    local flagged = 0
                    for _, v in ipairs(neighbors) do
                        if table.find(predictions, v) then
                            flagged = flagged + 1
                        end
                    end

                    if flagged == revealed[i] then
                        for _, v in ipairs(neighbors) do
                            if not table.find(predictions, v) and not table.find(predictions2, v) then
                                table.insert(predictions2, v)
                            end
                        end
                    end
                end
            end
        end
    elseif button == 2 then
        local x, y = math.floor(mx/sqrSize), math.floor(my/sqrSize)+1
        local n = x*gridSize+y
        if revealed[n] == -1 or revealed[n] == -10 then
            revealed[n] = (revealed[n] == -10) and -1 or -10
        end
    end
    AI.mods.next(love.mouse.getX(), love.mouse.getY())
end

function love.keypressed(k)
    if k == "q" then
        love.event.quit()
    elseif k == "x" then
        XRAY = not XRAY
    elseif k == "a" then
        AI.Enabled = not AI.Enabled
    end
end