PowerUp = Class{}

function PowerUp:init(type, x, y)
    -- used for type of power up
    self.type = type

    self.x = x
    self.y = y
    self.width = 16
    self.height = 16

    self.dy = 25

    self.remove = false
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function PowerUp:update(dt)
    if self.y < VIRTUAL_HEIGHT then
        self.y = self.y + self.dy * dt
    else
        self.remove = true
    end
end

function PowerUp:render()
    love.graphics.draw(gTextures['main'], gFrames['power-ups'][self.type],
        self.x, self.y)
end