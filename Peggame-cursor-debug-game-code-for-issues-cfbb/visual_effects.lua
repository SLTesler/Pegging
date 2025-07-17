-- visual_effects.lua
-- Visual effects and particle system

local config = require('config')

local visualEffects = {}

-- Particle limit enforcement
local function enforceParticleLimit(gameState)
    if #gameState.particles > config.PARTICLE_LIMIT then
        -- Remove oldest particles first
        local excess = #gameState.particles - config.PARTICLE_LIMIT
        for i = 1, excess do
            table.remove(gameState.particles, 1)
        end
    end
end

-- Add a visual effect
function visualEffects.addEffect(gameState, x, y, text, color, opts)
    opts = opts or {}
    table.insert(gameState.effects, {
        x = x,
        y = y,
        text = text,
        color = color,
        timer = config.EFFECT_DURATION,
        alpha = 1.0,
        bouncePopper = opts.bouncePopper or false
    })
end

-- Add collision particles with rainbow effects
function visualEffects.addParticles(gameState, x, y, count)
    count = count or 5
    
    -- Check if we would exceed the limit and adjust count accordingly
    local availableSlots = config.PARTICLE_LIMIT - #gameState.particles
    if availableSlots <= 0 then
        return -- No room for new particles
    end
    count = math.min(count, availableSlots)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 50 + math.random() * 100
        local hue = (i * 24) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        
        table.insert(gameState.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            timer = config.PARTICLE_DURATION,
            size = 4 + math.random() * 5,
            color = {r, g, b}
        })
    end
    
    -- Enforce limit after adding
    enforceParticleLimit(gameState)
end

-- Add screen shake
function visualEffects.addScreenShake(gameState, intensity, duration)
    gameState.screenShake.intensity = intensity
    gameState.screenShake.duration = duration
end

-- Create rainbow explosion effect
function visualEffects.createRainbowExplosion(gameState, x, y, count)
    count = count or 20
    
    -- Respect particle limits
    local availableSlots = config.PARTICLE_LIMIT - #gameState.particles
    if availableSlots <= 0 then
        return
    end
    count = math.min(count, availableSlots)
    
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = 150 + math.random() * 100
        local hue = (i * 18) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        
        table.insert(gameState.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            timer = 2.0,
            size = 6 + math.random() * 8,
            color = {r, g, b}
        })
    end
    
    enforceParticleLimit(gameState)
end

-- Create explosion effect (flash instead of particles)
function visualEffects.createExplosion(gameState, x, y, colorOrRadius)
    local color = {1, 0, 0} -- Default red
    local radius = 100 -- Default radius
    
    -- Handle different parameter types
    if type(colorOrRadius) == "table" then
        color = colorOrRadius
    elseif type(colorOrRadius) == "number" then
        radius = colorOrRadius
    end
    -- Add a flash effect (expanding, fading circle)
    table.insert(gameState.effects, {
        x = x,
        y = y,
        text = nil, -- No text, just a flash
        color = color,
        timer = 0.5, -- Flash duration
        alpha = 1.0,
        flash = true,
        flashRadius = radius,
        flashMaxRadius = radius * 2
    })
    -- Add a big burst text effect
    visualEffects.addEffect(gameState, x, y, "BOOM!", color)
end

-- Create rainbow storm effect
function visualEffects.createRainbowStorm(gameState)
    local count = 30
    local availableSlots = config.PARTICLE_LIMIT - #gameState.particles
    if availableSlots <= 0 then
        return
    end
    count = math.min(count, availableSlots)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 100 + math.random() * 200
        local hue = (i * 12) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        
        table.insert(gameState.particles, {
            x = math.random(config.WIDTH),
            y = math.random(config.HEIGHT),
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            timer = 3.0,
            size = 8 + math.random() * 12,
            color = {r, g, b}
        })
    end
    
    enforceParticleLimit(gameState)
end

-- Create rainbow sparkles
function visualEffects.createRainbowSparkles(gameState, x, y, count)
    count = count or 12
    
    local availableSlots = config.PARTICLE_LIMIT - #gameState.particles
    if availableSlots <= 0 then
        return
    end
    count = math.min(count, availableSlots)
    
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local radius = 60 + math.random() * 40
        local sparkleX = x + math.cos(angle) * radius
        local sparkleY = y + math.sin(angle) * radius
        local hue = (i * 30) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        
        table.insert(gameState.particles, {
            x = sparkleX,
            y = sparkleY,
            vx = 0,
            vy = 0,
            timer = 1.5,
            size = 3 + math.random() * 4,
            color = {r, g, b}
        })
    end
    
    enforceParticleLimit(gameState)
end

-- Create rainbow shockwave effect
function visualEffects.createRainbowShockwave(gameState, x, y)
    local count = 15
    local availableSlots = config.PARTICLE_LIMIT - #gameState.particles
    if availableSlots <= 0 then
        return
    end
    count = math.min(count, availableSlots)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 120 + math.random() * 150
        local hue = (i * 24) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        
        table.insert(gameState.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            timer = 1.0,
            size = 5 + math.random() * 6,
            color = {r, g, b}
        })
    end
    
    enforceParticleLimit(gameState)
end

-- Update all visual effects
function visualEffects.updateEffects(gameState, dt)
    for i = #gameState.effects, 1, -1 do
        local effect = gameState.effects[i]
        effect.timer = effect.timer - dt
        effect.alpha = effect.timer / config.EFFECT_DURATION
        if effect.flash then
            -- Expand the flash radius and fade out
            local progress = 1 - (effect.timer / 0.5)
            effect.flashRadius = (effect.flashMaxRadius or 200) * progress
            effect.alpha = 1 - progress
        end
        if effect.timer <= 0 then
            table.remove(gameState.effects, i)
        end
    end
    -- Update particles as before
    for i = #gameState.particles, 1, -1 do
        local particle = gameState.particles[i]
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        particle.timer = particle.timer - dt
        if particle.timer <= 0 then
            table.remove(gameState.particles, i)
        end
    end
end

-- Update screen shake
function visualEffects.updateScreenShake(gameState, dt)
    if gameState.screenShake.duration > 0 then
        gameState.screenShake.duration = gameState.screenShake.duration - dt
        gameState.screenShake.offsetX = (math.random() - 0.5) * gameState.screenShake.intensity
        gameState.screenShake.offsetY = (math.random() - 0.5) * gameState.screenShake.intensity
        
        if gameState.screenShake.duration <= 0 then
            gameState.screenShake.offsetX = 0
            gameState.screenShake.offsetY = 0
            gameState.screenShake.intensity = 0
        end
    end
end

-- Draw rainbow background
function visualEffects.drawRainbowBackground(gameState)
    for y = 0, config.PLAY_HEIGHT, 20 do
        for x = 0, config.PLAY_WIDTH, 20 do
            local hue = ((x + y + gameState.time * 50) % 360) / 360
            local r, g, b = config.COLORS.rainbow(hue)
            love.graphics.setColor(r, g, b, 0.25)
            love.graphics.rectangle("fill", config.PLAY_X + x, config.PLAY_Y + y, 20, 20)
        end
    end
end

-- Draw rainbow wall shadow
function visualEffects.drawRainbowWallShadow(gameState)
    if gameState.wallHitTimer and gameState.wallHitTimer > 0 then
        local alpha = gameState.wallHitTimer / config.WALL_HIT_TIMER
        for i = 1, 8 do
            local hue = ((i * 45 + gameState.time * 200) % 360) / 360
            local r, g, b = config.COLORS.rainbow(hue)
            love.graphics.setColor(r, g, b, alpha * 0.3)
            love.graphics.setLineWidth(6 - i * 0.5)
            love.graphics.rectangle("line", config.PLAY_X - i, config.PLAY_Y - i, config.PLAY_WIDTH + 2*i, config.PLAY_HEIGHT + 2*i)
        end
        love.graphics.setLineWidth(1)
    end
end

-- Draw particles
function visualEffects.drawParticles(gameState)
    for _, particle in ipairs(gameState.particles) do
        local alpha = particle.timer / config.PARTICLE_DURATION
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

-- Draw effects
function visualEffects.drawEffects(gameState)
    for _, effect in ipairs(gameState.effects) do
        if effect.flash then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], 0.5 * (effect.alpha or 1))
            love.graphics.circle("fill", effect.x, effect.y, effect.flashRadius or 100)
        elseif effect.text then
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.alpha)
            if gameState.fonts and gameState.fonts.small then
                love.graphics.setFont(gameState.fonts.small)
            end
            love.graphics.printf(effect.text, effect.x - 50, effect.y, 100, "center")
        end
    end
end

return visualEffects 