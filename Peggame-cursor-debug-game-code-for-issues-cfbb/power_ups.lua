-- power_ups.lua
-- Power-up system management

local config = require('config')
local visualEffects = require('visual_effects')

local powerUps = {}

-- Activate power-up
function powerUps.activatePowerUp(gameState, powerUpType)
    local powerUp = gameState.powerUps[powerUpType]
    if powerUp then
        powerUp.active = true
        powerUp.timer = powerUp.duration
        gameState.stats.powerUpsUsed = gameState.stats.powerUpsUsed + 1
        
        -- Add screen shake for power-up activation
        visualEffects.addScreenShake(gameState, config.SCREEN_SHAKE.powerUp.intensity, config.SCREEN_SHAKE.powerUp.duration)
        
        -- Add rainbow explosion effect
        local centerX = config.PLAY_X + config.PLAY_WIDTH/2
        local centerY = config.PLAY_Y + config.PLAY_HEIGHT/2
        visualEffects.createRainbowExplosion(gameState, centerX, centerY, 20)
        
        visualEffects.addEffect(gameState, centerX, centerY - 50, powerUpType:upper() .. " ACTIVATED!", config.COLORS.magenta)
    end
end

-- Update power-ups
function powerUps.updatePowerUps(gameState, dt)
    for powerUpType, powerUp in pairs(gameState.powerUps) do
        if powerUp.active then
            powerUp.timer = powerUp.timer - dt
            if powerUp.timer <= 0 then
                powerUp.active = false
                visualEffects.addEffect(gameState, config.WIDTH/2, config.HEIGHT/2, powerUpType:upper() .. " EXPIRED!", config.COLORS.orange)
            end
        end
    end
end

-- Update combo system
function powerUps.updateCombo(gameState, dt)
    gameState.combo.timer = gameState.combo.timer - dt
    if gameState.combo.timer <= 0 then
        gameState.combo.count = 0
        gameState.combo.multiplier = 1.0
    end
end

-- Update random events
function powerUps.updateRandomEvents(gameState, dt)
    for eventType, event in pairs(gameState.randomEvents) do
        event.timer = event.timer + dt
        if event.timer - event.lastEvent > event.interval then
            if eventType == "rainbowStorm" then
                -- Create rainbow storm effect
                visualEffects.createRainbowStorm(gameState)
                visualEffects.addEffect(gameState, config.WIDTH/2, config.HEIGHT/2, "RAINBOW STORM!", config.COLORS.rainbowStorm)
                event.lastEvent = event.timer
            elseif eventType == "gravityShift" then
                -- Temporarily reverse gravity
                for _, ball in ipairs(gameState.balls) do
                    ball.vy = -ball.vy * 0.5
                end
                -- Show 'GRAVITY SHIFT!' near the first ball if it exists, else center
                local gx, gy
                if #gameState.balls > 0 then
                    gx = gameState.balls[1].x
                    gy = gameState.balls[1].y - 40
                else
                    gx = config.WIDTH/2
                    gy = config.HEIGHT/2
                end
                visualEffects.addEffect(gameState, gx, gy, "GRAVITY SHIFT!", config.COLORS.gravityShift)
                event.lastEvent = event.timer
            end
        end
    end
end

-- Draw power-up indicators
function powerUps.drawPowerUpIndicators(gameState)
    local powerUpY = 150
    for powerUpType, powerUp in pairs(gameState.powerUps) do
        if powerUp.active then
            local alpha = 0.5 + 0.5 * math.sin(gameState.time * 5)
            love.graphics.setColor(1, 0, 1, alpha)
            love.graphics.setFont(gameState.fonts.small)
            love.graphics.print(powerUpType:upper() .. ": " .. string.format("%.1f", powerUp.timer), 10, powerUpY)
            powerUpY = powerUpY + 20
        end
    end
end

-- Draw combo indicator
function powerUps.drawComboIndicator(gameState)
    if gameState.combo.count > 0 then
        local comboAlpha = 0.7 + 0.3 * math.sin(gameState.time * 10)
        love.graphics.setColor(1, 0.5, 0, comboAlpha)
        -- Position combo meter to the left of play area
        local meterWidth = 60
        local meterHeight = 400
        local meterX = config.PLAY_X - meterWidth - 30  -- Moved to left side
        local meterY = config.PLAY_Y + config.PLAY_HEIGHT/2 - meterHeight/2
        -- Place text close to the left of the meter
        local textX = meterX - 120
        local textY = meterY + meterHeight/2 - 10
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("COMBO x" .. string.format("%.1f", gameState.combo.multiplier), textX, textY, 110, "center")
        -- Place hit count text close above the multiplier text
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf(gameState.combo.count .. " hits!", textX, textY - 30, 110, "center")
    end
end

return powerUps 