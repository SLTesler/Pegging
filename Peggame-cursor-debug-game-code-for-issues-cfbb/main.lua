-- main.lua
-- Modular peg bounce game

local config = require('config')
local gameState = require('game_state')
local visualEffects = require('visual_effects')
local gameObjects = require('game_objects')
local collisionSystem = require('collision_system')
local powerUps = require('power_ups')
local uiSystem = require('ui_system')
local shopSystem = require('shop_system')

-- Round summary state
local roundSummary = {
    active = false,
    rows = {},
    total = 0,
    timer = 0
}

-- Initialize game
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setFullscreen(true)
    config.WIDTH, config.HEIGHT = love.graphics.getDimensions()
    config.PLAY_X, config.PLAY_Y = config.WIDTH * 0.2, config.HEIGHT * 0.15
    config.PLAY_WIDTH, config.PLAY_HEIGHT = config.WIDTH * 0.6, config.HEIGHT * 0.7
    gameState.aimX = config.PLAY_X + config.PLAY_WIDTH/2
    gameState.aimY = config.PLAY_Y + 50
    love.window.setTitle("Peg Bounce")
    
    -- Initialize game state
    gameState:initializeRandomSeed()
    gameState:ensureRoundState()
    gameState.candyBought = gameState.candyBought or {}
    gameState.poppers = gameState.poppers or {}
    
    uiSystem.initFonts(gameState)
    gameObjects.createPegs(gameState)
    shopSystem.rerollShopItems(gameState)
    shopSystem.rerollShopPerks(gameState)
    
    -- Initialize wall hit timer
    gameState.wallHitTimer = nil
    
    -- Set initial mouse position
    gameState.mouseX = gameState.aimX
    gameState.mouseY = gameState.aimY
end

function showRoundSummaryPopup(rows, total)
    roundSummary.active = true
    roundSummary.rows = rows
    roundSummary.total = total
    roundSummary.timer = 3.0 -- Auto-advance after 3 seconds
end

function calculateRoundScoreAndBonuses()
    gameState:ensureRoundState()
    local round = gameState.currentRound
    local rows = {}
    local total = 0
    
    -- Main reward: round score
    table.insert(rows, {label = "Round Score", value = round.score})
    total = total + round.score
    
    -- Bonus: unused balls
    if round.balls_remaining > 0 then
        local bonus = round.balls_remaining * 10
        table.insert(rows, {label = "Unused Balls", value = bonus})
        total = total + bonus
    end
    
    -- Bonus: perfect round
    if round.perfect then
        local bonus = math.floor(round.score * 0.5)
        table.insert(rows, {label = "Perfect Round Bonus", value = bonus})
        total = total + bonus
    end
    
    -- Lives bonus (1 coin per life)
    if gameState.lives > 0 then
        table.insert(rows, {label = "Lives Bonus (Coins)", value = gameState.lives})
        gameState.coins = gameState.coins + gameState.lives
    end
    
    return rows, total
end

-- Check if round should complete
local function checkRoundCompletion()
    gameState:ensureRoundState()
    
    -- Round completes when goal is reached OR all balls are used and none active
    local goalReached = gameState.currentRound.score >= gameState.goal
    local ballsFinished = gameState.currentRound.balls_remaining == 0 and gameState.currentRound.active_balls == 0
    
    if (goalReached or ballsFinished) and not roundSummary.active then
        local rows, total = calculateRoundScoreAndBonuses()
        showRoundSummaryPopup(rows, total)
        return true
    end
    
    return false
end

-- Handle round completion
local function completeRound()
    -- Reset round state
    gameState.balls = {}
    gameState.effects = {}
    gameState.particles = {}
    gameState.canDropBalls = true
    gameState.goalBall = nil
    
    if gameState.round >= gameState.totalRounds then
        gameState.state = config.GAME_STATE.GAME_OVER
    else
        gameState.state = config.GAME_STATE.SHOP
        gameState.candyBought = gameState.candyBought or {}
        gameState.poppers = gameState.poppers or {}
        -- Scale coin reward with round
        local roundBonus = math.floor(gameState.currentRound.score / 400) + math.floor(gameState.lives / 2) + math.floor(gameState.round * 2)
        gameState.coins = gameState.coins + roundBonus
        shopSystem.rerollShopItems(gameState)
        shopSystem.rerollShopPerks(gameState)
    end
end

-- Update game
function love.update(dt)
    gameState.time = gameState.time + dt
    gameState:ensureRoundState()
    
    -- Handle round summary
    if roundSummary.active then
        roundSummary.timer = roundSummary.timer - dt
        if roundSummary.timer <= 0 then
            roundSummary.active = false
            completeRound()
        end
        return -- Don't update anything else during summary
    end
    
    -- Update screen shake
    visualEffects.updateScreenShake(gameState, dt)
    
    -- Update power-ups
    powerUps.updatePowerUps(gameState, dt)
    
    -- Update combo system
    powerUps.updateCombo(gameState, dt)
    
    -- Update random events
    powerUps.updateRandomEvents(gameState, dt)
    
    -- Update wall hit timer
    if gameState.wallHitTimer then
        gameState.wallHitTimer = gameState.wallHitTimer - dt
        if gameState.wallHitTimer <= 0 then
            gameState.wallHitTimer = nil
        end
    end
    
    -- Update effects
    visualEffects.updateEffects(gameState, dt)
    
    -- Update pegs
    gameObjects.updatePegs(gameState, dt)
    
    -- Update balls
    gameObjects.updateBalls(gameState, dt)
        
    -- Check collisions
    for _, ball in ipairs(gameState.balls) do
        collisionSystem.checkBallWallCollision(gameState, ball, dt)
        collisionSystem.checkBallPegCollision(gameState, ball, dt)
        collisionSystem.checkBallBallCollision(gameState, ball, dt)
    end
    
    -- Check if all balls are gone
    if #gameState.balls == 0 and not gameState.canDropBalls then
        gameState.canDropBalls = true
        
        -- Check if round is complete
        if gameState.currentRound.score >= gameState.goal then
            if not gameState.roundCompleteTimer then
                gameState.roundCompleteTimer = 3 -- 3 seconds delay
                -- Bonus coins for double points
                if gameState.currentRound.score >= gameState.goal * 2 then
                    gameState.coins = gameState.coins + 10
                end
            end
        elseif gameState.lives <= 0 then
            gameState.state = config.GAME_STATE.GAME_OVER
        end
    end

    -- Handle round complete timer
    if gameState.roundCompleteTimer then
        gameState.roundCompleteTimer = gameState.roundCompleteTimer - dt
        if gameState.roundCompleteTimer <= 0 then
            gameState.roundCompleteTimer = nil
            checkRoundCompletion()
        end
    end

    -- Update meter flash timer
    if gameState.meterFlashTimer > 0 then
        gameState.meterFlashTimer = gameState.meterFlashTimer - dt
        if gameState.meterFlashTimer < 0 then
            gameState.meterFlashTimer = 0
        end
    end
    
    -- Update rainbow shockwave timer
    if gameState.rainbowShockwave > 0 then
        gameState.rainbowShockwave = gameState.rainbowShockwave - dt
        if gameState.rainbowShockwave < 0 then
            gameState.rainbowShockwave = 0
        end
    end
    
    -- Update score glow timer and detect score changes
    if gameState.scoreGlowTimer > 0 then
        gameState.scoreGlowTimer = gameState.scoreGlowTimer - dt
        if gameState.scoreGlowTimer < 0 then
            gameState.scoreGlowTimer = 0
        end
    end
    
    -- Check for score increase and trigger effects
    if gameState.currentRound.score > (gameState.lastRoundScore or 0) then
        gameState.scoreGlowTimer = config.SCORE_GLOW_DURATION
        -- Add rainbow sparkles around score text
        local scoreX = config.PLAY_X + config.PLAY_WIDTH/2
        local scoreY = config.PLAY_Y + config.PLAY_HEIGHT + 100
        visualEffects.createRainbowSparkles(gameState, scoreX, scoreY, 12)
        gameState.lastRoundScore = gameState.currentRound.score
    end
    
    -- Check if round is complete during gameplay
    if gameState.state == config.GAME_STATE.PLAYING and gameState.currentRound.score >= gameState.goal then
        gameState.canAdvanceRound = true
    end

    -- Add a timer for game over/win state
    if gameState.state == config.GAME_STATE.GAME_OVER and not gameState.gameOverTimer then
        gameState.gameOverTimer = 3
    end
    if gameState.state == config.GAME_STATE.GAME_OVER and gameState.gameOverTimer then
        gameState.gameOverTimer = gameState.gameOverTimer - dt
        if gameState.gameOverTimer <= 0 then
            gameState.state = config.GAME_STATE.MENU
            gameState.gameOverTimer = nil
        end
    end

    -- Check for round completion during gameplay
    if gameState.state == config.GAME_STATE.PLAYING then
        checkRoundCompletion()
    end
end

-- Draw game
function love.draw()
    -- Apply screen shake
    love.graphics.push()
    love.graphics.translate(gameState.screenShake.offsetX, gameState.screenShake.offsetY)
    
    -- Draw solid grey background
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, config.WIDTH, config.HEIGHT)
    
    -- Draw rainbow background
    love.graphics.setScissor(config.PLAY_X, config.PLAY_Y, config.PLAY_WIDTH, config.PLAY_HEIGHT)
    visualEffects.drawRainbowBackground(gameState)
    love.graphics.setScissor()
    
    -- Draw rainbow drop shadow when walls are hit
    visualEffects.drawRainbowWallShadow(gameState)
    
    -- Draw solid black walls
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", config.PLAY_X, config.PLAY_Y, config.PLAY_WIDTH, config.WALL_THICKNESS)
    love.graphics.rectangle("fill", config.PLAY_X, config.PLAY_Y + config.PLAY_HEIGHT - config.WALL_THICKNESS, config.PLAY_WIDTH, config.WALL_THICKNESS)
    love.graphics.rectangle("fill", config.PLAY_X, config.PLAY_Y, config.WALL_THICKNESS, config.PLAY_HEIGHT)
    love.graphics.rectangle("fill", config.PLAY_X + config.PLAY_WIDTH - config.WALL_THICKNESS, config.PLAY_Y, config.WALL_THICKNESS, config.PLAY_HEIGHT)
    
    -- Draw pegs
    gameObjects.drawPegs(gameState)
    
    -- Draw balls
    gameObjects.drawBalls(gameState)
    
    -- Draw particles
    visualEffects.drawParticles(gameState)
    
    -- Draw effects
    visualEffects.drawEffects(gameState)
    
    -- Draw power-up indicators
    powerUps.drawPowerUpIndicators(gameState)
    
    -- Draw combo indicator
    powerUps.drawComboIndicator(gameState)
    
    love.graphics.pop() -- End screen shake transform
    
    -- Draw UI
    uiSystem.drawUI(gameState)

    -- State-specific UI
    if gameState.state == config.GAME_STATE.MENU then
        uiSystem.drawMenu(gameState)
    elseif gameState.state == config.GAME_STATE.SHOP then
        uiSystem.drawShop(gameState)
        uiSystem.drawPoppers(gameState)
    elseif gameState.state == config.GAME_STATE.GAME_OVER then
        uiSystem.drawGameOver(gameState)
    elseif gameState.state == config.GAME_STATE.PAUSED then
        uiSystem.drawPauseMenu(gameState)
    end
    
    -- Hover peg warning
    uiSystem.drawHoverPegWarning(gameState)
    
    -- Draw vertical multiplier meter on right side during gameplay
    if gameState.state == config.GAME_STATE.PLAYING then
        uiSystem.drawMultiplierMeter(gameState)
    end
    
    -- Draw aiming system during gameplay
    if gameState.state == config.GAME_STATE.PLAYING then
        uiSystem.drawAimingSystem(gameState)
    end
    
    -- Draw perk slots above play area (right side)
    if gameState.state == config.GAME_STATE.PLAYING then
        uiSystem.drawCandyRow(gameState)
    end
    
    -- Draw "Next Round" button during gameplay if score requirement met
    if gameState.state == config.GAME_STATE.PLAYING then
        uiSystem.drawNextRoundButton(gameState)
    end
    
    -- Draw poppers at top during gameplay
    if gameState.state == config.GAME_STATE.PLAYING then
        uiSystem.drawPoppers(gameState)
        uiSystem.drawCandies(gameState)
    end

    -- Draw round summary popup
    if roundSummary.active then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", config.WIDTH/2 - 250, config.HEIGHT/2 - 200, 500, 400, 18, 18)
        love.graphics.setColor(1, 1, 1)
        
        if gameState.fonts and gameState.fonts.large then
            love.graphics.setFont(gameState.fonts.large)
        end
        love.graphics.printf("Round Summary", config.WIDTH/2 - 250, config.HEIGHT/2 - 180, 500, "center")
        
        if gameState.fonts and gameState.fonts.normal then
            love.graphics.setFont(gameState.fonts.normal)
        end
        local y = config.HEIGHT/2 - 110
        for _, row in ipairs(roundSummary.rows) do
            love.graphics.printf(row.label, config.WIDTH/2 - 200, y, 300, "left")
            love.graphics.printf("+" .. tostring(row.value), config.WIDTH/2 + 100, y, 100, "right")
            y = y + 40
        end
        
        if gameState.fonts and gameState.fonts.title then
            love.graphics.setFont(gameState.fonts.title)
        end
        love.graphics.printf("Total: " .. tostring(roundSummary.total), config.WIDTH/2 - 200, config.HEIGHT/2 + 120, 400, "center")
        
        -- Draw Continue button
        local btnW, btnH = 220, 60
        local btnX = config.WIDTH/2 - btnW/2
        local btnY = config.HEIGHT/2 + 170
        love.graphics.setColor(0.2, 0.7, 0.2, 0.95)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 16, 16)
        love.graphics.setColor(1, 1, 1)
        if gameState.fonts and gameState.fonts.normal then
            love.graphics.setFont(gameState.fonts.normal)
        end
        love.graphics.printf("Continue", btnX, btnY + 18, btnW, "center")
        
        -- Show auto-advance timer
        local timerText = string.format("Auto-advance in %.1fs", math.max(0, roundSummary.timer))
        love.graphics.printf(timerText, btnX, btnY + 70, btnW, "center")
    end

    -- Draw round number in the lower right
    local roundText = "Round " .. tostring(gameState.round)
    if gameState.fonts and gameState.fonts.title then
        love.graphics.setFont(gameState.fonts.title)
    end
    local rx = config.PLAY_X + config.PLAY_WIDTH - 40
    local ry = config.PLAY_Y + config.PLAY_HEIGHT + 80
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local ox = math.cos(angle) * 6
        local oy = math.sin(angle) * 6
        local hue = ((gameState.time * 100 + i * 45) % 360) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.printf(roundText, rx + ox, ry + oy, 400, "right")
    end
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf(roundText, rx, ry, 400, "right")
end

-- Handle mouse presses
function love.mousepressed(x, y, button)
    if button == 2 and gameState.state == config.GAME_STATE.PLAYING then
        -- Right click to remove perks
        for i = 1, 5 do
            local px = config.PLAY_X + config.PLAY_WIDTH - 60 - (i-1)*50
            local py = 10
            if x >= px and x <= px + 40 and y >= py and y <= py + 40 and gameState.perks[i] ~= 0 then
                if gameState.perkCounts[i] > 1 then
                    gameState.perkCounts[i] = gameState.perkCounts[i] - 1
                else
                    gameState.perks[i] = 0
                    gameState.perkCounts[i] = 0
                end
                return
            end
        end
    elseif button == 1 then
        -- Handle round summary clicks
        if roundSummary.active then
            local btnW, btnH = 220, 60
            local btnX = config.WIDTH/2 - btnW/2
            local btnY = config.HEIGHT/2 + 170
            if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
                roundSummary.active = false
                completeRound()
            end
            return
        end
        
        if gameState.state == config.GAME_STATE.MENU then
            if x > config.WIDTH/2 - 120 and x < config.WIDTH/2 + 120 then
                if y > config.HEIGHT/2 - 10 and y < config.HEIGHT/2 + 40 then
                    -- Start game
                    gameState:reset()
                    startNewRound()
                elseif y > config.HEIGHT/2 + 60 and y < config.HEIGHT/2 + 110 then
                    love.event.quit()
                end
            end
        elseif gameState.state == config.GAME_STATE.PLAYING then
            -- Check for Next Round button click
            if gameState.canAdvanceRound and x > config.WIDTH/2 - 100 and x < config.WIDTH/2 + 100 and y > config.HEIGHT/2 - 40 and y < config.HEIGHT/2 then
                gameState.state = config.GAME_STATE.SHOP
                gameState.candyBought = gameState.candyBought or {}
                gameState.coins = gameState.coins + math.floor(gameState.currentRound.score / 500) + math.floor(gameState.lives / 2)
                gameState.round = gameState.round + 1
                shopSystem.rerollShopItems(gameState)
                shopSystem.rerollShopPerks(gameState)
                return
            end
            
            -- Launch ball with aiming
            if gameState.canDropBalls then
                gameObjects.createBalls(gameState)
            end
        elseif gameState.state == config.GAME_STATE.PAUSED then
            if x > config.WIDTH/2 - 100 and x < config.WIDTH/2 + 100 then
                if y > config.HEIGHT/2 - 30 and y < config.HEIGHT/2 then
                    -- Resume
                    gameState.state = config.GAME_STATE.PLAYING
                elseif y > config.HEIGHT/2 + 10 and y < config.HEIGHT/2 + 40 then
                    -- Restart round
                    gameState:resetRound()
                    gameObjects.createPegs(gameState)
                    gameState.state = config.GAME_STATE.PLAYING
                elseif y > config.HEIGHT/2 + 50 and y < config.HEIGHT/2 + 80 then
                    -- Quit to menu
                    gameState.state = config.GAME_STATE.MENU
                end
            end
        elseif gameState.state == config.GAME_STATE.SHOP then
            -- Reroll button
            local rerollBtnY = 170
            if x >= config.WIDTH/2 - 80 and x <= config.WIDTH/2 + 80 and y >= rerollBtnY and y <= rerollBtnY + 40 then
                if gameState.coins >= 5 then
                    gameState.coins = gameState.coins - 5
                    shopSystem.rerollShopItems(gameState)
                end
                return
            end
            -- Buy buttons for each Popper
            local yOffset = 100
            local startY = 240 + yOffset
            local iconSize = 80
            local spacing = 90
            for i, item in ipairs(gameState.shopItems) do
                local itemY = startY + (i-1)*spacing
                local buyX, buyY, buyW, buyH = config.WIDTH/2 + iconSize/2 + 16, itemY + 20, 80, 40
                local bought = gameState.poppers and (gameState.poppers[item.id] or 0) > 0
                if not bought and x >= buyX and x <= buyX + buyW and y >= buyY and y <= buyY + buyH then
                    if gameState.coins >= item.price then
                        shopSystem.purchaseItem(gameState, item)
                    end
                    return
                end
            end
            -- Buy buttons for Candies
            local popperCount = #gameState.shopItems
            local candies = shopSystem.CANDIES
            for i, candy in ipairs(candies) do
                local candyY = startY + popperCount * spacing + 60 + (i-1)*spacing
                local buyX, buyY, buyW, buyH = config.WIDTH/2 + iconSize/2 + 16, candyY + 20, 80, 40
                local bought = gameState.candyBought and gameState.candyBought[candy.id]
                if not bought and x >= buyX and x <= buyX + buyW and y >= buyY and y <= buyY + buyH then
                    if gameState.coins >= candy.price then
                        shopSystem.purchaseCandy(gameState, candy)
                    end
                    return
                end
            end
            -- Continue button (match yOffset and spacing from drawShop)
            local exitBtnY = startY + popperCount * spacing + 60 + #candies * spacing + 40
            if x >= config.WIDTH/2 - 100 and x <= config.WIDTH/2 + 100 and y >= exitBtnY and y <= exitBtnY + 50 then
                startNewRound()
                return
            end
        elseif gameState.state == config.GAME_STATE.GAME_OVER then
            if x > config.WIDTH/2 - 100 and x < config.WIDTH/2 + 100 then
                if y > config.HEIGHT/2 + 20 and y < config.HEIGHT/2 + 60 then
                    -- Restart game
                    gameState:reset()
                    startNewRound()
                elseif y > config.HEIGHT/2 + 70 and y < config.HEIGHT/2 + 110 then
                    -- Back to menu
                    gameState.state = config.GAME_STATE.MENU
                end
            end
        end
    end
end

-- Handle mouse movement
function love.mousemoved(x, y)
    gameState.mouseX = x
    gameState.mouseY = y
    
    if gameState.state == config.GAME_STATE.PLAYING then
        gameObjects.checkMouseOverPeg(gameState, x, y)
    end
end

-- Handle key presses
function love.keypressed(key)
    if key == "escape" then
        if gameState.state == config.GAME_STATE.PLAYING then
            gameState.state = config.GAME_STATE.PAUSED
        elseif gameState.state == config.GAME_STATE.PAUSED then
            gameState.state = config.GAME_STATE.PLAYING
        end
    end
end

-- Start a new round
function startNewRound()
    gameState.round = gameState.round + 1
    gameState.state = config.GAME_STATE.PLAYING
    gameState.goldPegPositions = nil -- Reset gold peg positions
    gameState.bonusPegPositions = nil -- Reset bonus peg positions
    gameState:resetRound()
    gameObjects.createPegs(gameState)
    -- Round number goal scaling (scale faster)
    gameState.goal = math.floor(config.START_GOAL * math.pow(1.5, gameState.round - 1) / 50) * 50  -- Rounded to nearest 50
    gameState.canAdvanceRound = false
    
    -- Ensure round state is properly initialized
    gameState:initializeRound()
    gameState.balls = {}
    gameState.effects = {}
    gameState.particles = {}
    gameState.canDropBalls = true
    gameState.goalBall = nil
    
    -- Reset round summary
    roundSummary.active = false
    roundSummary.rows = {}
    roundSummary.total = 0
    
    -- Ensure candyBought and poppers are always tables
    gameState.candyBought = gameState.candyBought or {}
    gameState.poppers = gameState.poppers or {}
end