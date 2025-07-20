-- collision_system.lua
-- Collision detection and response system

local config = require('config')
local visualEffects = require('visual_effects')

local collisionSystem = {}

-- Unified popper effect system
local function applyPopperEffects(gameState, ball, peg, effectType)
    local points = 0
    local effectText = ""
    local effectColor = {1, 1, 1}
    
    if effectType == "bounce" and gameState.poppers and (gameState.poppers.bouncePopper or 0) > 0 then
        points = config.SCORING.BOUNCE_POPPER_POINTS
        effectText = "+" .. points
        effectColor = {0.2, 1, 0.2}
    elseif effectType == "green" and gameState.poppers and (gameState.poppers.greenPopper or 0) > 0 then
        points = config.SCORING.GREEN_POPPER_POINTS
        effectText = "+" .. points
        effectColor = {0.2, 1, 0.2}
    elseif effectType == "red" and gameState.poppers and (gameState.poppers.redPopper or 0) > 0 then
        points = config.SCORING.RED_POPPER_POINTS
        effectText = "+" .. points
        effectColor = {1, 0.2, 0.2}
    elseif effectType == "blue" and gameState.poppers and (gameState.poppers.bluePopper or 0) > 0 then
        points = config.SCORING.BLUE_POPPER_POINTS
        effectText = "+" .. points
        effectColor = {0, 0.6, 1}
    elseif effectType == "wall" and gameState.poppers and (gameState.poppers.wallPopper or 0) > 0 then
        points = config.SCORING.WALL_POPPER_POINTS
        effectText = "+" .. points .. " WALL"
        effectColor = {0.8, 0.8, 0.2}
    elseif effectType == "combo" and gameState.poppers and (gameState.poppers.comboPopper or 0) > 0 then
        points = config.SCORING.COMBO_POPPER_POINTS
        effectText = "+" .. points .. " COMBO"
        effectColor = {1, 0.5, 0.2}
    elseif effectType == "cinco" and gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 then
        points = config.SCORING.CINCO_POPPER_POINTS
        effectText = "+" .. points .. " CINCO!"
        effectColor = {1, 0.8, 0.2}
    elseif effectType == "yellow" and gameState.poppers and (gameState.poppers.bananaPopper or 0) > 0 then
        points = config.SCORING.BANANA_POPPER_POINTS
        effectText = "+" .. points .. " BANANA!"
        effectColor = {1, 1, 0}
    elseif effectType == "wallMaster" and gameState.poppers and (gameState.poppers.wallMasterPopper or 0) > 0 then
        points = 1000
        effectText = "+1000 WALL MASTER!"
        effectColor = {0.3, 0.7, 1}
    end
    
    if points > 0 then
        gameState:ensureRoundState()
        gameState.currentRound.score = gameState.currentRound.score + points
        
        -- Track popper activation for UI display
        table.insert(gameState.popperActivations, {
            type = effectType,
            points = points,
            timer = 2.0, -- Show for 2 seconds
            color = effectColor
        })
        
        -- Show effect text for bounce effects (now only one)
        if effectType == "bounce" then
            visualEffects.addEffect(gameState, ball.x, ball.y - 20, effectText, effectColor)
        else
            visualEffects.addEffect(gameState, ball.x, ball.y - 20, effectText, effectColor)
        end
    end
end

-- Check if peg matches color for popper effects
local function getPegColorType(peg)
    if not peg.outlineColor then return nil end
    local r, g, b = peg.outlineColor[1], peg.outlineColor[2], peg.outlineColor[3]
    
    if r == 0.2 and g == 1 and b == 0.2 then return "green" end
    if r == 1 and g == 0.2 and b == 0.2 then return "red" end
    if r == 0 and g == 0.6 and b == 1 then return "blue" end
    if r == 1 and g == 1 and b == 0 then return "yellow" end
    
    return nil
end

-- Update multiplier meter and handle score doubling
local function updateMultiplierMeter(gameState, ball)
    gameState.multiplierMeter = gameState.multiplierMeter + 1
    if gameState.multiplierMeter >= config.SCORING.MULTIPLIER_METER_MAX then
        gameState.multiplierMeter = 0
        -- Double current score immediately
        gameState:ensureRoundState()
        gameState.currentRound.score = gameState.currentRound.score * config.SCORING.SCORE_DOUBLE_MULTIPLIER
        gameState.rainbowShockwave = config.RAINBOW_SHOCKWAVE_DURATION
        
        -- Create visual effects
        local meterX = config.PLAY_X - 60 - 30  -- Match the new left-side meter position
        local meterY = config.PLAY_Y + config.PLAY_HEIGHT/2
        visualEffects.createRainbowShockwave(gameState, meterX, meterY)
        visualEffects.addEffect(gameState, ball.x, ball.y - 30, "SCORE DOUBLED!", config.COLORS.multiplier)
    end
end

-- Add coin effect near coins UI
local function addCoinEffect(gameState)
    local infoX = config.PLAY_X + 10
    local infoY = config.PLAY_Y - 60
    local roundTextWidth = 0
    if love and love.graphics and love.graphics.getFont then
        roundTextWidth = love.graphics.getFont():getWidth("Round: " .. tostring(gameState.round))
    end
    local gap = 40
    local coinsX = infoX + roundTextWidth + gap
    local coinsString = "Coins: " .. tostring(gameState.coins)
    local coinsWidth = 0
    if gameState.fonts and gameState.fonts.normal then
        coinsWidth = gameState.fonts.normal:getWidth(coinsString)
    elseif love and love.graphics and love.graphics.getFont then
        coinsWidth = love.graphics.getFont():getWidth(coinsString)
    end
    local coinEffectX = coinsX + coinsWidth - 16
    visualEffects.addEffect(gameState, coinEffectX, infoY, "+1 COIN", config.COLORS.coin)
end

-- Check collisions between ball and pegs
function collisionSystem.checkBallPegCollision(gameState, ball, dt)
    gameState:ensureRoundState()
    
    for i = #gameState.pegs, 1, -1 do
        local peg = gameState.pegs[i]
        if not peg then
            goto continue
        end
        local dx = ball.x - peg.x
        local dy = ball.y - peg.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        -- Apply magnet ball attraction
        if gameState.powerUps.magnetBall.active then
            local attractionRadius = gameState.powerUps.magnetBall.attractionRadius
            if dist < attractionRadius and dist > ball.radius + peg.radius then
                local attractionForce = 500
                local nx = dx / dist
                local ny = dy / dist
                ball.vx = ball.vx + nx * attractionForce * dt
                ball.vy = ball.vy + ny * attractionForce * dt
            end
        end
        
        if dist < ball.radius + peg.radius then
            -- Realistic collision response
            local nx = dx / dist
            local ny = dy / dist
            
            -- Relative velocity in collision normal direction
            local relativeVelocity = ball.vx * nx + ball.vy * ny
            
            -- Always separate overlapping objects first
            local overlap = (ball.radius + peg.radius) - dist
            ball.x = ball.x + nx * overlap
            ball.y = ball.y + ny * overlap
            
            -- Only bounce if moving toward peg
            if relativeVelocity < 0 then
                -- Use config constant for bounce impulse
                local impulse = -config.PEG_BOUNCE_IMPULSE * relativeVelocity
                ball.vx = ball.vx + impulse * nx
                ball.vy = ball.vy + impulse * ny
                
                -- Apply bounce popper effect
                applyPopperEffects(gameState, ball, peg, "bounce")
            end
            
            -- Gold pegs are permanent - just track hits for potential future features
            if peg.isGold then
                peg.goldHitCount = peg.goldHitCount + 1
            end
            
            -- Score points from peg points system
            local basePoints = 0
            if peg.isGold then
                basePoints = config.SCORING.GOLD_PEG_BASE + gameState.round
                gameState.coins = gameState.coins + 1
                gameState.stats.totalCoinsCollected = gameState.stats.totalCoinsCollected + 1
                addCoinEffect(gameState)
            elseif not peg.isRed and peg.points > 0 then
                basePoints = math.max(1, math.floor(peg.points * 0.25))
                peg.points = peg.points - basePoints
                

                visualEffects.addEffect(gameState, peg.x + math.random(-20, 20), peg.y + math.random(-20, 20), "+" .. basePoints, config.COLORS.green)
            end
            
            -- Apply color-based popper effects
            if not peg.isGold and not peg.isBonus then
                local colorType = getPegColorType(peg)
                if colorType then
                    applyPopperEffects(gameState, ball, peg, colorType)
                end
            end
            
            -- Remove peg if its points reach zero or below
            if peg.points and peg.points <= 0 then
                table.remove(gameState.pegs, i)
                table.remove(gameState.pegShapes, i)
                break -- Exit loop to avoid using nil peg
            end
            
            -- Calculate final score
            local totalPoints = basePoints
            local points = math.floor(totalPoints * gameState.multiplier * gameState.combo.multiplier)
            
            -- Apply multiplier popper effect
            if gameState.poppers and (gameState.poppers.multiplierPopper or 0) > 0 then
                local multiplierBonus = math.floor(points * 0.2) -- 20% bonus
                points = points + multiplierBonus
                if multiplierBonus > 0 then
                    visualEffects.addEffect(gameState, ball.x, ball.y - 40, "+" .. multiplierBonus .. " MULT", {1, 0.8, 0.2})
                end
            end
            
            local prevScore = gameState.currentRound.score
            gameState.currentRound.score = prevScore + points
            
            -- If the round goal is reached for the first time, record this ball
            if not gameState.goalBall and prevScore < gameState.goal and gameState.currentRound.score >= gameState.goal then
                gameState.goalBall = ball
            end
            
            gameState.stats.totalPegsHit = gameState.stats.totalPegsHit + 1
            
            -- Add to combo
            collisionSystem.addToCombo(gameState)
            
            -- Update multiplier meter
            updateMultiplierMeter(gameState, ball)

            -- Add effect
            if points > 0 then
                visualEffects.addEffect(gameState, ball.x, ball.y, "+" .. points, config.COLORS.points)
            end

            -- Coin per hit upgrade - every 5th collision (peg hits only)
            if gameState.upgrades.coinPerHit then
                gameState.collisionCount = gameState.collisionCount + 1
                if gameState.collisionCount % 5 == 0 then
                    gameState.coins = gameState.coins + 1
                    gameState.stats.totalCoinsCollected = gameState.stats.totalCoinsCollected + 1
                    addCoinEffect(gameState)
                end
            end
            
            -- Increment bounce count
            ball.bounceCount = ball.bounceCount + 1
            
            -- Increment combo hit count for combo popper
            ball.comboHitCount = (ball.comboHitCount or 0) + 1
            
            -- Cinco Popper: bonus for every 5th bounce
            if gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 and ball.bounceCount % 5 == 0 then
                applyPopperEffects(gameState, ball, peg, "cinco")
            end
            
            -- Apply double hit bonus with round scaling
            if gameState.upgrades.doubleHit and ball.bounceCount >= 2 and ball.bounceCount % 2 == 0 then
                local bonusPoints = math.floor((config.SCORING.DOUBLE_HIT_BASE + gameState.round) * gameState.multiplier * gameState.combo.multiplier)
                gameState.currentRound.score = gameState.currentRound.score + bonusPoints
                visualEffects.addEffect(gameState, ball.x, ball.y, "+" .. bonusPoints, config.COLORS.bonus)
            end
            
            -- Apply collision bonus on 10th collision
            if gameState.upgrades.collisionBonus and ball.bounceCount % 10 == 0 then
                local bonusPoints = math.floor(config.SCORING.COLLISION_BONUS_BASE * gameState.multiplier * gameState.combo.multiplier)
                gameState.currentRound.score = gameState.currentRound.score + bonusPoints
                visualEffects.addEffect(gameState, ball.x, ball.y - 20, "10th HIT BONUS +" .. bonusPoints, config.COLORS.yellow)
            end
            
            -- Ball hit effect
            ball.hitTimer = config.HIT_TIMER
            peg.hit = true
            peg.hitTimer = config.PEG_HIT_TIMER
            
            -- Add collision particles with enhanced effects
            local particleCount = gameState.powerUps.explosionRadius.active and 15 or 8
            visualEffects.addParticles(gameState, ball.x, ball.y, particleCount)
            
            -- Add screen shake for peg hits
            visualEffects.addScreenShake(gameState, config.SCREEN_SHAKE.pegHit.intensity, config.SCREEN_SHAKE.pegHit.duration)
            
            -- Check for random explosion chance
            if gameState.upgrades.luckyStrike and math.random() < 0.25 then
                collisionSystem.triggerRandomPegExplosion(gameState)
            end

            -- Track pegs hit for Explosive Popper
            gameState.pegsHitThisRound = (gameState.pegsHitThisRound or 0) + 1
            -- Explosive Popper: every 10th peg hit in a round
            if gameState.poppers and (gameState.poppers.explosivePopper or 0) > 0 and gameState.pegsHitThisRound % 10 == 0 then
                -- Red explosion effect: clear nearby pegs and add points
                local explosionRadius = 220
                local explosionScore = 0
                for j = #gameState.pegs, 1, -1 do
                    local peg2 = gameState.pegs[j]
                    if peg2 and peg2 ~= peg then
                        local dx2 = peg.x - peg2.x
                        local dy2 = peg.y - peg2.y
                        if math.sqrt(dx2*dx2 + dy2*dy2) < explosionRadius then
                            -- Add the destroyed peg's points to explosion score
                            explosionScore = explosionScore + (peg2.points or 5)
                            table.remove(gameState.pegs, j)
                            table.remove(gameState.pegShapes, j)
                        end
                    end
                end
                -- Add both explosion bonus and destroyed peg scores
                local totalExplosionPoints = config.SCORING.EXPLOSIVE_POPPER_POINTS + explosionScore
                gameState.currentRound.score = gameState.currentRound.score + totalExplosionPoints
                -- Red explosion animation
                if visualEffects and visualEffects.createExplosion then
                    visualEffects.createExplosion(gameState, peg.x, peg.y, {1,0,0})
                end
                visualEffects.addEffect(gameState, peg.x, peg.y, "EXPLOSION!", {1,0,0})
                if explosionScore > 0 then
                    visualEffects.addEffect(gameState, peg.x, peg.y - 40, "+" .. totalExplosionPoints, {1, 0.8, 0.2})
                end
            end
            -- Combo Popper: bonus for 3+ pegs in a single bounce
            if gameState.poppers and (gameState.poppers.comboPopper or 0) > 0 and (ball.comboHitCount or 0) >= 3 then
                applyPopperEffects(gameState, ball, peg, "combo")
            end
        end
        ::continue::
    end
end

-- Check collisions between ball and walls
function collisionSystem.checkBallWallCollision(gameState, ball, dt)
    gameState:ensureRoundState()
    local wallHit = false
    
    -- Left wall
    if ball.x - ball.radius < config.PLAY_X + config.WALL_THICKNESS then
        ball.x = config.PLAY_X + config.WALL_THICKNESS + ball.radius
        ball.vx = -ball.vx * config.WALL_BOUNCE
        wallHit = true
    end
    
    -- Right wall
    if ball.x + ball.radius > config.PLAY_X + config.PLAY_WIDTH - config.WALL_THICKNESS then
        ball.x = config.PLAY_X + config.PLAY_WIDTH - config.WALL_THICKNESS - ball.radius
        ball.vx = -ball.vx * config.WALL_BOUNCE
        wallHit = true
    end
    
    -- Top wall
    if ball.y - ball.radius < config.PLAY_Y + config.WALL_THICKNESS then
        ball.y = config.PLAY_Y + config.WALL_THICKNESS + ball.radius
        ball.vy = -ball.vy * config.WALL_BOUNCE
        wallHit = true
    end
    
    -- Bottom wall
    if ball.y + ball.radius > config.PLAY_Y + config.PLAY_HEIGHT - config.WALL_THICKNESS then
        ball.y = config.PLAY_Y + config.PLAY_HEIGHT - config.WALL_THICKNESS - ball.radius
        ball.vy = -ball.vy * config.WALL_BOUNCE
        ball.bottomWallBounces = ball.bottomWallBounces + 1
        wallHit = true
    end
    
    if wallHit then
        -- Score points with standardized values
        local totalPoints = (gameState.upgrades.wallPoints and config.SCORING.WALL_BASE_POINTS or 0) + config.SCORING.WALL_BASE_POINTS
        local points = math.floor(totalPoints * gameState.multiplier)
        
        -- Apply multiplier popper effect to wall hits
        if gameState.poppers and (gameState.poppers.multiplierPopper or 0) > 0 then
            local multiplierBonus = math.floor(points * 0.2) -- 20% bonus
            points = points + multiplierBonus
            if multiplierBonus > 0 then
                visualEffects.addEffect(gameState, ball.x, ball.y - 40, "+" .. multiplierBonus .. " MULT", {1, 0.8, 0.2})
            end
        end
        
        gameState.currentRound.score = gameState.currentRound.score + points
        
        -- Update multiplier meter
        updateMultiplierMeter(gameState, ball)
        
        -- Add effect
        visualEffects.addEffect(gameState, ball.x, ball.y, "+" .. points, config.COLORS.wallPoints)
        
        -- Ball hit effect
        ball.hitTimer = config.HIT_TIMER
        
        -- Wall hit effect
        gameState.wallHitTimer = config.WALL_HIT_TIMER
        
        -- Add wall explosion particles
        visualEffects.addParticles(gameState, ball.x, ball.y, 8)
        
        -- Increment bounce count
        ball.bounceCount = ball.bounceCount + 1
        
        -- Cinco Popper: bonus for every 5th bounce (wall hits count too)
        if gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 and ball.bounceCount % 5 == 0 then
            applyPopperEffects(gameState, ball, nil, "cinco")
        end

        -- Wall Master Popper: 1000 points every 5th wall hit
        if gameState.poppers and (gameState.poppers.wallMasterPopper or 0) > 0 then
            ball.wallMasterCount = (ball.wallMasterCount or 0) + 1
            if ball.wallMasterCount % 5 == 0 then
                applyPopperEffects(gameState, ball, nil, "wallMaster")
            end
        end
        
        -- Reset combo hit count when ball hits wall (combo is pegs hit in single bounce)
        ball.comboHitCount = 0
        
        -- Apply popper effects
        applyPopperEffects(gameState, ball, nil, "bounce")
        applyPopperEffects(gameState, ball, nil, "wall")
    end
end

-- Check collisions between balls
function collisionSystem.checkBallBallCollision(gameState, ball, dt)
    gameState:ensureRoundState()
    
    for _, other in ipairs(gameState.balls) do
        if ball ~= other then
            local dx = ball.x - other.x
            local dy = ball.y - other.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local minDist = ball.radius + other.radius
            
            if dist < minDist and dist > 0 then
                -- Realistic ball-to-ball collision
                local nx = dx / dist
                local ny = dy / dist
                
                -- Relative velocity
                local dvx = ball.vx - other.vx
                local dvy = ball.vy - other.vy
                local dot = dvx * nx + dvy * ny
                
                -- Only resolve if balls are approaching
                if dot > 0 then
                    -- Use config constant for ball collision impulse
                    local impulse = dot * config.BALL_COLLISION_IMPULSE
                    
                    -- Apply gentle impulse
                    ball.vx = ball.vx - impulse * nx
                    ball.vy = ball.vy - impulse * ny
                    other.vx = other.vx + impulse * nx
                    other.vy = other.vy + impulse * ny
                    
                    -- Separate overlapping balls
                    local overlap = minDist - dist
                    ball.x = ball.x + nx * overlap * 0.5
                    ball.y = ball.y + ny * overlap * 0.5
                    other.x = other.x - nx * overlap * 0.5
                    other.y = other.y - ny * overlap * 0.5
                    
                    -- Score points with standardized values
                    local basePoints = gameState.upgrades.ballCollision and config.SCORING.BALL_COLLISION_UPGRADED or config.SCORING.BALL_COLLISION_BASE
                    local points = math.floor(basePoints * gameState.multiplier)
                    gameState.currentRound.score = gameState.currentRound.score + points
                    
                    -- Update multiplier meter
                    updateMultiplierMeter(gameState, ball)

                    -- Add effect
                    visualEffects.addEffect(gameState, (ball.x + other.x)/2, (ball.y + other.y)/2, "+" .. points, config.COLORS.ballCollision)

                    -- Flash meter and show collision info
                    gameState.meterFlashTimer = config.METER_FLASH_DURATION
                    gameState.lastBallCollisionPoints = points
                    if love and love.timer then
                        gameState.lastBallCollisionTime = love.timer.getTime()
                    end
                    
                    -- Ball hit effect
                    ball.hitTimer = config.HIT_TIMER
                    other.hitTimer = config.HIT_TIMER
                    
                    -- Increment bounce counts
                    ball.bounceCount = ball.bounceCount + 1
                    other.bounceCount = other.bounceCount + 1
                end
            end
        end
    end
end

-- Add to combo
function collisionSystem.addToCombo(gameState)
    gameState.combo.count = gameState.combo.count + 1
    gameState.combo.timer = gameState.combo.maxTime
    gameState.combo.multiplier = math.min(gameState.combo.multiplier + config.COMBO.multiplierIncrement, gameState.combo.maxMultiplier)
    
    if gameState.combo.count > gameState.stats.maxCombo then
        gameState.stats.maxCombo = gameState.combo.count
    end
end

-- Trigger random peg explosion
function collisionSystem.triggerRandomPegExplosion(gameState)
    gameState:ensureRoundState()
    
    if #gameState.pegs > 0 then
        local randomPeg = gameState.pegs[math.random(#gameState.pegs)]
        local explosionRadius = gameState.powerUps.explosionRadius.active and 200 or 100
        
        -- Create explosion effect
        visualEffects.createExplosion(gameState, randomPeg.x, randomPeg.y, explosionRadius)
        
        -- Remove pegs in explosion radius
        for i = #gameState.pegs, 1, -1 do
            local peg = gameState.pegs[i]
            local dx = peg.x - randomPeg.x
            local dy = peg.y - randomPeg.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < explosionRadius then
                -- Add points for destroyed pegs using standardized scoring
                local points = math.floor((config.SCORING.RANDOM_EXPLOSION_BASE + gameState.round) * gameState.multiplier * gameState.combo.multiplier)
                gameState.currentRound.score = gameState.currentRound.score + points
                gameState.stats.totalPegsHit = gameState.stats.totalPegsHit + 1
                
                visualEffects.addEffect(gameState, peg.x, peg.y, "+" .. points, config.COLORS.orange)
                table.remove(gameState.pegs, i)
                table.remove(gameState.pegShapes, i)
            end
        end
        
        gameState.stats.explosionsTriggered = gameState.stats.explosionsTriggered + 1
        visualEffects.addScreenShake(gameState, config.SCREEN_SHAKE.explosion.intensity, config.SCREEN_SHAKE.explosion.duration)
    end
end

return collisionSystem 