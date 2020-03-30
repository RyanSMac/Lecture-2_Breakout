--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {params.ball}
    self.level = params.level

    self.recoverPoints = params.recoverPoints

    self.paddlePoints = params.paddlePoints

    self.powerUp = {}

    self.powerSpawnCount = 0
    self.powerSpawnNum = math.random(10, 15)

    -- give ball random starting velocity
    for b, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    for i, power in pairs(self.powerUp) do
        power:update(dt)
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for b, ball in pairs(self.balls) do
        ball:update(dt)
    
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - ball.width
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
                -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger brick hit function
                brick:hit()

                -- spawn power after number of hits
                self.powerSpawnCount = self.powerSpawnCount + 1
                if self.powerSpawnCount >= self.powerSpawnNum then
                    table.insert(self.powerUp, PowerUp(math.random(1, 3) , brick.x + ((brick.width / 2) - 8), brick.y + ((brick.height / 2) - 8)))
                    self.powerSpawnCount = 0
                    self.powerSpawnNum = math.random(10,15)
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints * 2

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints,
                        paddlePoints = self.paddlePoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            ball.remove = true
        end
    end

    for b, ball in pairs(self.balls) do
        if ball.remove then
            table.remove(self.balls, b)
        end
    end

    if self.score >= self.paddlePoints then
        if self.paddle.size < 4 then 
            self.paddle.size = self.paddle.size + 1
            self.paddle.width = self.paddle.width + 32
        end
        self.paddlePoints = self.paddlePoints * 2
    end

    if tableEmpty(self.balls) then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.width - 32
        end

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                paddlePoints = self.paddlePoints

            })
        end
    end

    -- if the powerUp collied with the paddle 
    for i, power in pairs(self.powerUp) do
        if power:collides(self.paddle) then
            -- activate power up
            ActivatePowerUp(power, self.balls)
            -- remove power up from list
            power.remove = true
        end

        if power.remove then
            table.remove(self.powerUp, i)
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end
    
    self.paddle:render()
    for b, ball in pairs(self.balls) do
        ball:render()
    end

    for i, power in pairs(self.powerUp) do
        power:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

function ActivatePowerUp(powerUp, balls)
    if powerUp.type == 3 then
        table.insert(balls, MultiBall(math.random(7),
            powerUp.x + 8,
            powerUp.y + 8,
            math.random(-50, -60),
            math.random(-200, 200)))
    elseif powerUp.type == 2 then
        for b, ball in pairs(balls) do
            if ball.size < 3 then
                ball.width = ball.width + 4
                ball.height = ball.height  + 4
                ball.sx = ball.sx + 0.5
                ball.sy = ball.sy + 0.5
                ball.size = ball.size + 1
            end
        end
    elseif powerUp.type == 1 then
        for b, ball in pairs(balls) do
            if ball.size > 1 then
                ball.width = ball.width - 4
                ball.height = ball.height - 4
                ball.sx = ball.sx - 0.5
                ball.sy = ball.sy - 0.5
                ball.size = ball.size - 1
            end
        end
    end
end

function tableEmpty(table)
    local next = next

    if next(table) == nil then
        return true
    else
        return false
    end
end