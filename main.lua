function fpsLerp(a, b, t, dt)
    return a + (b - a) * math.min(1, dt / t)
end

function math.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function love.math.randomFloat(min, max)
    local min, max = min or 0, max or 1
    return min + (max - min) * love.math.random()
end

local particleColours = {
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1},
    {1, 1, 0},
    {1, 0, 1},
    {0, 1, 1}
}

-- light cyan
local trailColour = {0.5, 1, 1}

popupImg = {
    img = nil,
    x = love.graphics.getWidth() - 125,
    y = love.graphics.getHeight() + 125,
    rotation = 0,
    timer = 0,
    didTimer = false,
    curTime = 0
}
flash = 0

function love.load()
    Class = require("lib.class")
    ini = require("lib.ini")

    Particle = Class:extend()
    function Particle:new(x, y, color)
        self.x = x
        self.y = y
        self.color = color or particleColours[love.math.random(1, #particleColours)]
        self.alpha = 1

        self.speed = love.math.randomFloat(100, 200)
        self.angle = love.math.randomFloat(0, math.pi * 2)
        self.size = love.math.randomFloat(5, 10)
        self.lifetime = love.math.randomFloat(0.5, 1)
        self.timer = 0

        function self:update(dt)
            self.x = self.x + math.cos(self.angle) * self.speed * dt
            self.y = self.y + math.sin(self.angle) * self.speed * dt

            self.timer = self.timer + dt
            self.alpha = 1 - self.timer / self.lifetime
            if self.alpha < 0 then
                self.alpha = 0
            end
        end

        function self:draw()
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
            love.graphics.circle("fill", self.x, self.y, self.size)
        end

        table.insert(Particle.list, self)
    end
    Particle.list = {}

    mouse = {
        x = 0,
        y = 0,
        trail = {},
        hideTimer = 0,
        visible = true,
        alpha = 1,
        polyVerts = { -- recreate mouse cursor in a polygon
            0, 0,
            0, 15,
            6, 12.5,
            3, 5.25,
            10, 10,
            15, 7.5
        },
        isDown = false,
        rotation = 0 -- not radians
    }
    function mouse:onClick(x, y)
        -- make a bunch of particles
        for i = 1, love.math.random(15, 25) do
            Particle(x, y)
        end
    end

    testini = ini.parse("testini.ini")

    saveTable = {
        ["test"] = {
            ["testing"] = true
        },
        ["other"] = {
            ["blah"] = "blah"
        }

    }
    ini.save(saveTable, "testini.ini")
    
end

function love.update(dt)
    mouse.x = fpsLerp(mouse.x, love.mouse.getX(), 0.025, dt)
    mouse.y = fpsLerp(mouse.y, love.mouse.getY(), 0.025, dt)

    table.insert(mouse.trail, {x = mouse.x, y = mouse.y, alpha = 1, thickness=3, colour={trailColour[1], trailColour[2], trailColour[3]}})

    for i, v in ipairs(mouse.trail) do
        v.alpha = fpsLerp(v.alpha, 0, 0.125, dt)
        v.thickness = fpsLerp(v.thickness, 0, 0.25, dt)
        if v.alpha < 0 then
            table.remove(mouse.trail, i)
        end
        for i = 1, 3 do
            v.colour[i] = fpsLerp(v.colour[i], 0, 2.5, dt)
            if v.colour[i] < 0 then
                v.colour[i] = 0
            end
        end
    end

    for i, v in ipairs(Particle.list) do
        v:update(dt)
        if v.alpha <= 0 then
            table.remove(Particle.list, i)
        end
    end

    mouse.hideTimer = mouse.hideTimer + dt
    if mouse.hideTimer > 1 then
        mouse.alpha = fpsLerp(mouse.alpha, 0, 0.1, dt)
    else
        mouse.alpha = fpsLerp(mouse.alpha, 1, 0.1, dt)
    end

    love.mouse.setVisible(false)

    flash = math.max(0, flash - dt * 2)

    -- move popupImg.y to love.graphics.getHeight() - 200
    if not popupImg.didTimer then
        popupImg.y = fpsLerp(popupImg.y, love.graphics.getHeight() - 125, 0.25, dt)
    else
        popupImg.y = fpsLerp(popupImg.y, love.graphics.getHeight()+125, 0.25, dt)
    end

    -- use sinelaw to change popupImg.rotation with time
    --popupImg.rotation = math.sin(love.timer.getTime() * 2) * 0.1
    popupImg.rotation = math.sin((love.timer.getTime() - popupImg.curTime) * 2) * 0.1
    if popupImg.img then
        popupImg.timer = popupImg.timer + dt
        if popupImg.timer > 3 then
            popupImg.didTimer = true
            if popupImg.timer > 4 then
                popupImg.img:release()
                popupImg.img = nil
                popupImg.timer = 0
                popupImg.didTimer = false
            end
        end
    end
end

function love.keypressed(k)
    if k == "s" then
        if not love.filesystem.getInfo("screenshot") then
            love.filesystem.createDirectory("screenshot")
        end

        love.graphics.captureScreenshot(function(screenshot)
            -- save screenshot
            local screenshotName = "screenshot/" .. os.date("%Y-%m-%d %H-%M-%S") .. ".png"
            love.filesystem.write(screenshotName, screenshot)
            if popupImg.img then
                popupImg.img:release()
            end
            flash = 1
            popupImg = {
                img = love.graphics.newImage(screenshot),
                x = love.graphics.getWidth() - 125,
                y = love.graphics.getHeight() + 125,
                timer = 0,
                rotation = 0,
                didTimer = false,
                curTime = love.timer.getTime()
            }
        end)
    end
end

function love.draw()
    love.graphics.print("FPS: " .. love.timer.getFPS(), 0, 0)
    love.graphics.print("Mouse: " .. math.round(mouse.x, 2) .. ", " .. math.round(mouse.y, 2), 0, 20)
    love.graphics.print("Lua Memory Usage: " .. math.round(collectgarbage("count"), 2) .. " KB", 0, 40)
    love.graphics.print("Graphics Memory Usage: " .. math.round(love.graphics.getStats().texturememory / 1024 / 1024, 2) .. " MB", 0, 60)

    if mouse.visible then
        love.graphics.setColor(trailColour[1], trailColour[2], trailColour[3], mouse.alpha)
        love.graphics.circle("fill", mouse.x, mouse.y, 2)
    end

    -- points for trail (like a graph)
    for i, v in ipairs(mouse.trail) do
        local lastLineThickness = love.graphics.getLineWidth()
        love.graphics.setLineWidth(v.thickness)
        love.graphics.setColor(v.colour[1], v.colour[2], v.colour[3], v.alpha)
        nextPoint = mouse.trail[i + 1] or {x = mouse.x, y = mouse.y}
        love.graphics.line(v.x, v.y, nextPoint.x, nextPoint.y)
        love.graphics.setLineWidth(lastLineThickness)
    end

    for i, v in ipairs(Particle.list) do
        v:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setColor(1, 1, 1, flash)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)

    if popupImg.img then
        love.graphics.setColor(1, 1, 1, 1)
        -- rescale to 190x190
        love.graphics.draw(popupImg.img, popupImg.x, popupImg.y, popupImg.rotation, 190 / popupImg.img:getWidth(), 190 / popupImg.img:getHeight(), popupImg.img:getWidth() / 2, popupImg.img:getHeight() / 2)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        mouse:onClick(x, y)
    end
end

function love.mousemoved(x, y, dx, dy)
    mouse.hideTimer = 0
end

function love.quit()
    -- clear screenshot folder
    for i, v in ipairs(love.filesystem.getDirectoryItems("screenshot")) do
        love.filesystem.remove("screenshot/" .. v)
    end
end