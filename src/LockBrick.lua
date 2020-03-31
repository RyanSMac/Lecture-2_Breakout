LockBrick = Class{__includes = Brick}

function LockBrick:init(x, y)
    -- used for coloring and score calculation
    self.tier = 0
    self.color = 1
    
    self.x = x
    self.y = y
    self.width = 32
    self.height = 16

    -- used to check if the block is locked or not
    self.unLocked = 0
    
    -- used to determine whether this brick should be rendered
    self.inPlay = true

    -- particle system belonging to the brick, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward 
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- spread of particles; normal looks more natural than uniform, which is clumpy; numbers
    -- are amount of standard deviation away in X and Y axis
    self.psystem:setEmissionArea('normal', 10, 10)
end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function LockBrick:hit()
    if self.unLocked == 1 then

        -- set the particle system to interpolate between two colors; in this case, we give
        -- it our self.color but with varying alpha; brighter for higher tiers, fading to 0
        -- over the particle's lifetime (the second color)
        self.psystem:setColors(
            paletteColors[self.color].r / 255,
            paletteColors[self.color].g / 255,
            paletteColors[self.color].b / 255,
            55 * (self.tier + 1) / 255,
            paletteColors[self.color].r / 255,
            paletteColors[self.color].g / 255,
            paletteColors[self.color].b / 255,
            0
        )
        self.psystem:emit(64)

        -- sound on hit
        gSounds['brick-hit-2']:stop()
        gSounds['brick-hit-2']:play()

        -- if we're at a higher tier than the base, we need to go down a tier
        -- if we're already at the lowest color, else just go down a color
        if self.tier > 0 then
            if self.color == 1 then
                self.tier = self.tier - 1
                self.color = 5
            else
                self.color = self.color - 1
            end
        else
            -- if we're in the first tier and the base color, remove brick from play
            if self.color == 1 then
                self.inPlay = false
            else
                self.color = self.color - 1
            end
        end

        -- play a second layer sound if the brick is destroyed
        if not self.inPlay then
            gSounds['brick-hit-1']:stop()
            gSounds['brick-hit-1']:play()
        end
    end
end

function LockBrick:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], 
            -- multiply color by 4 (-1) to get our color offset, then add tier to that
            -- to draw the correct tier and color brick onto the screen
            gFrames['bricks'][1 + ((self.color - 1) * 4) + self.tier],
            self.x, self.y)
    end

    if self.unLocked == 0 then
        love.graphics.draw(gTextures['main'],
            gFrames['lock'][1], self.x, self.y)
    end
end