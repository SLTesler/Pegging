-- game_objects.lua
-- Game objects (pegs, balls) creation and management

local config = require('config')
local visualEffects = require('visual_effects')

local gameObjects = {}

-- Create pegs in a consistent 10x10 grid
function gameObjects.createPegs(gameState)
    gameState.pegs = {}
    gameState.pegShapes = {}
    gameObjects.createPegGrid(gameState)
end

-- Create 10 columns with random heights (1-5 pegs each)
function gameObjects.createPegGrid(gameState)
    local pegIndex = 0
    local totalPegs = 0
    
    -- Generate random column heights
    local columnHeights = {}
    local missingColumn = (gameState.round % 5 == 0) and math.random(1, 7) or nil
    for col = 1, 7 do
        if col == missingColumn then
            columnHeights[col] = 0
        else
            columnHeights[col] = math.random(1, 5)
            totalPegs = totalPegs + columnHeights[col]
        end
    end
    
    local startX = config.PLAY_X + config.WALL_THICKNESS + config.PEG_RADIUS + 20
    local startY = config.PLAY_Y + config.WALL_THICKNESS + config.PEG_RADIUS + 100
    local spacingX = (config.PLAY_WIDTH - 2 * (config.WALL_THICKNESS + config.PEG_RADIUS + 20)) / 6.2
    local maxHeight = 5
    local spacingY = (config.PLAY_HEIGHT - 2 * (config.WALL_THICKNESS + config.PEG_RADIUS + 100)) / (maxHeight - 1)
    
    for col = 1, 7 do
        local colHeight = columnHeights[col]
        for row = 1, colHeight do
            pegIndex = pegIndex + 1
            local x = startX + (col-1) * spacingX
            local y = startY + spacingY * (maxHeight - 1) - (row-1) * spacingY
            gameObjects.createPeg(gameState, x, y, pegIndex)
        end
    end
end

-- Helper function to create a peg
function gameObjects.createPeg(gameState, x, y, pegIndex)
    -- Clamp peg position to stay within play area walls
    x = math.max(config.PLAY_X + config.WALL_THICKNESS + config.PEG_RADIUS, math.min(config.PLAY_X + config.PLAY_WIDTH - config.WALL_THICKNESS - config.PEG_RADIUS, x))
    y = math.max(config.PLAY_Y + config.WALL_THICKNESS + config.PEG_RADIUS, math.min(config.PLAY_Y + config.PLAY_HEIGHT - config.WALL_THICKNESS - config.PEG_RADIUS, y))
    
    -- Generate gold peg positions once per round
    if not gameState.goldPegPositions then
        gameState.goldPegPositions = {}
        for i = 1, config.GOLD_PEG_COUNT do
            local pos
            repeat
                pos = math.random(1, 30)
            until not gameState.goldPegPositions[pos]
            gameState.goldPegPositions[pos] = true
        end
    end
    local isGold = gameState.goldPegPositions[pegIndex] or false
    
    -- Generate bonus peg positions once per round
    if not gameState.bonusPegPositions then
        gameState.bonusPegPositions = {}
        for i = 1, 5 do
            local pos
            repeat
                pos = math.random(1, 30)
            until not gameState.bonusPegPositions[pos] and not gameState.goldPegPositions[pos]
            gameState.bonusPegPositions[pos] = true
        end
    end
    local isBonus = gameState.bonusPegPositions[pegIndex] or false
    
    -- Peg points scale using config constants
    local basePoints = math.floor(config.SCORING.PEG_BASE_POINTS * math.pow(config.SCORING.PEG_POINTS_SCALING, gameState.round - 1))
    local pegPoints = (isBonus and math.floor(basePoints * config.SCORING.BONUS_PEG_MULTIPLIER * math.pow(1.1, gameState.round - 1)) or basePoints)
    
    -- Assign a random outline color for regular pegs
    local outlineColors = {
        {1, 1, 0},   -- yellow
        {0, 0.6, 1}, -- blue
        {1, 0.2, 0.2}, -- red
        {0.2, 1, 0.2}  -- green
    }
    local outlineColor = outlineColors[math.random(#outlineColors)]
    
    table.insert(gameState.pegs, {
        x = x,
        y = y,
        radius = config.PEG_RADIUS,
        color = isGold and config.COLORS.gold or {0.15, 0.15, 0.15}, -- Match outside background for regular pegs
        outlineColor = isGold and config.COLORS.gold or outlineColor, -- Use gold for gold pegs, random for regular
        hit = false,
        hitTimer = 0,
        isGold = isGold,
        isBonus = isBonus,
        goldHitCount = 0,
        points = pegPoints
    })
    table.insert(gameState.pegShapes, 1)
end

-- Create balls with aimed direction
function gameObjects.createBalls(gameState)
    -- Ensure round state is valid
    gameState:ensureRoundState()
    
    local count = gameState.maxBalls
    -- Calculate angle from aim position to mouse
    local dx = gameState.mouseX - gameState.aimX
    local dy = gameState.mouseY - gameState.aimY
    local angle = math.atan2(dy, dx)
    local speed = config.BALL_SPEED
    
    -- Apply speed boost power-up
    if gameState.powerUps.speedBoost.active then
        speed = speed * gameState.powerUps.speedBoost.multiplier
    end
    
    for i = 1, count do
        local spreadAngle = angle + (math.random() - 0.5) * config.SPREAD_ANGLE
        local ballRadius = config.BALL_RADIUS
        
        -- Apply giant ball power-up
        if gameState.powerUps.giantBall.active then
            ballRadius = config.BALL_RADIUS * gameState.powerUps.giantBall.sizeMultiplier
        end
        
        table.insert(gameState.balls, {
            x = gameState.aimX,
            y = gameState.aimY,
            radius = ballRadius,
            vx = math.cos(spreadAngle) * speed,
            vy = math.sin(spreadAngle) * speed,
            color = config.COLORS.ballNormal,
            hitTimer = 0,
            bounceCount = 0,
            bottomWallBounces = 0,
            comboHitCount = 0,
            trail = {},
            mass = config.BALL_MASS,
            restitution = config.BALL_RESTITUTION,
            rainbowTrail = gameState.powerUps.rainbowTrail.active
        })
        
        -- Update round state safely
        gameState.currentRound.balls_remaining = math.max(0, gameState.currentRound.balls_remaining - 1)
        gameState.currentRound.active_balls = gameState.currentRound.active_balls + 1
    end
    
    gameState.lives = gameState.lives - 1
    gameState.canDropBalls = false
    gameState.isAiming = false
    gameState.multiplier = 1.0
    gameState.multiplierMeter = 0
end

-- Create explosion effect
function gameObjects.createExplosion(gameState, x, y)
    for i = 1, 10 do
        local angle = math.random() * math.pi * 2
        local speed = 200 + math.random() * 100
        
        table.insert(gameState.balls, {
            x = x,
            y = y,
            radius = config.BALL_RADIUS,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = config.COLORS.ballExplosion,
            hitTimer = 0.5,
            bounceCount = 0,
            trail = {}
        })
    end
end

-- Check if mouse is over a peg
function gameObjects.checkMouseOverPeg(gameState, mx, my)
    gameState.hoverPeg = false
    
    for _, peg in ipairs(gameState.pegs) do
        local dx = mx - peg.x
        local dy = my - peg.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist < peg.radius then
            gameState.hoverPeg = true
            return
        end
    end
end

-- Update pegs
function gameObjects.updatePegs(gameState, dt)
    for _, peg in ipairs(gameState.pegs) do
        if peg.hit then
            peg.hitTimer = peg.hitTimer - dt
            if peg.hitTimer <= 0 then
                peg.hit = false
            end
        end
    end
end

-- Update balls
function gameObjects.updateBalls(gameState, dt)
    -- Ensure round state is valid
    gameState:ensureRoundState()
    
    for i = #gameState.balls, 1, -1 do
        local ball = gameState.balls[i]
        
        -- Update position with improved integration
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
        
        -- Apply gravity
        ball.vy = ball.vy + config.GRAVITY * dt
        
        -- Add to trail with rainbow effect
        local trailEntry = {x = ball.x, y = ball.y}
        if ball.rainbowTrail then
            local hue = (gameState.time * 200 + ball.x * 0.01) % 360 / 360
            trailEntry.r, trailEntry.g, trailEntry.b = config.COLORS.rainbow(hue)
        end
        table.insert(ball.trail, trailEntry)
        if #ball.trail > config.TRAIL_LENGTH then
            table.remove(ball.trail, 1)
        end
        
        -- Update hit timer
        if ball.hitTimer > 0 then
            ball.hitTimer = ball.hitTimer - dt
        end
        
        -- Remove balls that go out of bounds or hit bottom wall twice
        if ball.y > config.PLAY_Y + config.PLAY_HEIGHT + 100 or ball.bottomWallBounces >= 2 then
            table.remove(gameState.balls, i)
            -- Decrement active_balls for round state
            gameState.currentRound.active_balls = math.max(0, gameState.currentRound.active_balls - 1)
        end
    end
end

-- Draw balls with trails
function gameObjects.drawBalls(gameState)
    for _, ball in ipairs(gameState.balls) do
        -- Draw rainbow flame trail
        for i, pos in ipairs(ball.trail) do
            local alpha = (i / #ball.trail) * 0.8
            if pos.r then
                -- Rainbow trail
                love.graphics.setColor(pos.r, pos.g, pos.b, alpha)
            else
                -- Normal trail
                local hue = ((i * 30 + gameState.time * 200) % 360) / 360
                local r, g, b = config.COLORS.rainbow(hue)
                love.graphics.setColor(r, g, b, alpha)
            end
            local size = ball.radius * (0.3 + 0.4 * (i / #ball.trail))
            love.graphics.circle("fill", pos.x, pos.y, size)
        end
        
        -- Draw ball
        if ball.hitTimer > 0 then
            love.graphics.setColor(unpack(config.COLORS.ballHit))
        else
            love.graphics.setColor(unpack(ball.color))
        end
        
        love.graphics.circle("fill", ball.x, ball.y, ball.radius)
        
        -- Rainbow holographic outline
        local ballHue = ((ball.x + ball.y + gameState.time * 100) % 360) / 360
        local r, g, b = config.COLORS.rainbow(ballHue)
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", ball.x, ball.y, ball.radius + 2)
        love.graphics.setLineWidth(1)
        
        -- Draw ball highlight
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", ball.x - ball.radius * 0.3, ball.y - ball.radius * 0.3, ball.radius * 0.4)
    end
end

-- Draw pegs with visual effects
function gameObjects.drawPegs(gameState)
    for i, peg in ipairs(gameState.pegs) do
        if peg.isGold then
            -- Gold peg with sparkles
            love.graphics.setColor(unpack(config.COLORS.pegGold))
            love.graphics.circle("fill", peg.x, peg.y, peg.radius)
            -- Sparkle effect every 2.5 seconds
            if math.floor(gameState.time / 2.5) % 2 == 0 and (gameState.time % 2.5) < 0.3 then
                for k = 1, 6 do
                    local angle = k * math.pi / 3 + gameState.time * 3
                    local dist = peg.radius * 0.7
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.circle("fill", peg.x + math.cos(angle) * dist, peg.y + math.sin(angle) * dist, 3)
                end
            end
            -- Glossy highlight (only for gold pegs)
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.circle("fill", peg.x - peg.radius * 0.3, peg.y - peg.radius * 0.3, peg.radius * 0.3)
        elseif peg.isBonus then
            -- Bonus peg with pearlescent effect
            if peg.hit then
                love.graphics.setColor(unpack(config.COLORS.pegBonusHit))
            else
                love.graphics.setColor(unpack(config.COLORS.pegBonus))
            end
            love.graphics.circle("fill", peg.x, peg.y, peg.radius)
            -- Pearlescent overlay
            local pearl = 0.3 + 0.2 * math.sin(gameState.time * 2 + peg.x * 0.01)
            love.graphics.setColor(1, 1, 1, pearl * 0.3)
            love.graphics.circle("fill", peg.x, peg.y, peg.radius)
            -- Purple-blue glowing outline
            local glow = 0.5 + 0.5 * math.sin(gameState.time * 3)
            love.graphics.setColor(0.5, 0, 1, glow)
            love.graphics.setLineWidth(6)
            love.graphics.circle("line", peg.x, peg.y, peg.radius + 2)
            love.graphics.setColor(0, 0.5, 1, glow * 0.7)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", peg.x, peg.y, peg.radius + 4)
            love.graphics.setLineWidth(1)
            -- No glossy highlight for bonus pegs
        else
            -- Regular peg
            if peg.hit then
                love.graphics.setColor(unpack(config.COLORS.pegHit))
            else
                love.graphics.setColor(unpack(peg.color))
            end
            love.graphics.circle("fill", peg.x, peg.y, peg.radius)
            -- Solid outline (no glow)
            love.graphics.setColor(unpack(peg.outlineColor))
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", peg.x, peg.y, peg.radius)
            love.graphics.setLineWidth(1)
            -- No glossy highlight for regular pegs
        end
        -- Draw points (all pegs) with error checking
        if peg.points and gameState.fonts and gameState.fonts.tiny then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(gameState.fonts.tiny)
            love.graphics.printf(tostring(math.max(0, peg.points)), peg.x - 12, peg.y - 6, 24, "center")
        end
    end
end

return gameObjects 