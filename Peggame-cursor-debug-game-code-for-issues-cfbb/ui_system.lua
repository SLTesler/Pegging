-- ui_system.lua
-- User interface system

local config = require('config')
local visualEffects = require('visual_effects')

local uiSystem = {}

local buttonStates = {}

-- Place drawPopperIcon at the very top so it is always in scope
local function drawPopperIcon(popperId, x, y, time, scale)
    scale = scale or 1
    -- Floating animation (original amplitude)
    local float = math.sin(time * 2 + x) * 6
    y = y + float
    if popperId == "greenPopper" then
        -- Draw a green UFO
        love.graphics.setColor(0.2, 0.8, 0.2) -- Green main body
        love.graphics.ellipse("fill", x + 40*scale, y + 45*scale, 30*scale, 15*scale) -- Main saucer
        love.graphics.setColor(0.4, 1, 0.4) -- Lighter green dome
        love.graphics.ellipse("fill", x + 40*scale, y + 35*scale, 20*scale, 12*scale) -- Dome
        -- UFO lights (animated)
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + time * 3
            local lightX = x + 40*scale + math.cos(angle) * 22*scale
            local lightY = y + 45*scale + math.sin(angle) * 8*scale
            local brightness = 0.5 + 0.5 * math.sin(time * 8 + i)
            love.graphics.setColor(1, 1, 1, brightness)
            love.graphics.circle("fill", lightX, lightY, 2*scale)
        end
    elseif popperId == "redPopper" then
        -- Draw a red UFO
        love.graphics.setColor(0.8, 0.2, 0.2) -- Red main body
        love.graphics.ellipse("fill", x + 40*scale, y + 45*scale, 30*scale, 15*scale) -- Main saucer
        love.graphics.setColor(1, 0.4, 0.4) -- Lighter red dome
        love.graphics.ellipse("fill", x + 40*scale, y + 35*scale, 20*scale, 12*scale) -- Dome
        -- UFO lights (animated)
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + time * 3
            local lightX = x + 40*scale + math.cos(angle) * 22*scale
            local lightY = y + 45*scale + math.sin(angle) * 8*scale
            local brightness = 0.5 + 0.5 * math.sin(time * 8 + i)
            love.graphics.setColor(1, 1, 1, brightness)
            love.graphics.circle("fill", lightX, lightY, 2*scale)
        end
    elseif popperId == "bluePopper" then
        -- Draw a blue UFO
        love.graphics.setColor(0.2, 0.4, 1) -- Blue main body
        love.graphics.ellipse("fill", x + 40*scale, y + 45*scale, 30*scale, 15*scale) -- Main saucer
        love.graphics.setColor(0.4, 0.6, 1) -- Lighter blue dome
        love.graphics.ellipse("fill", x + 40*scale, y + 35*scale, 20*scale, 12*scale) -- Dome
        -- UFO lights (animated)
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + time * 3
            local lightX = x + 40*scale + math.cos(angle) * 22*scale
            local lightY = y + 45*scale + math.sin(angle) * 8*scale
            local brightness = 0.5 + 0.5 * math.sin(time * 8 + i)
            love.graphics.setColor(1, 1, 1, brightness)
            love.graphics.circle("fill", lightX, lightY, 2*scale)
        end
    elseif popperId == "wallPopper" then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", x + 20*scale, y + 32*scale, 40*scale, 28*scale, 8*scale, 8*scale)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", x + 20*scale, y + 54*scale, 40*scale, 8*scale, 4*scale, 4*scale)
    elseif popperId == "bouncePopper" then
        love.graphics.setColor(0.8, 0.8, 0.8)
        for i = 0, 5 do
            love.graphics.arc("line", x + 40*scale, y + 54*scale - i*10*scale, 20*scale, math.pi, 2*math.pi)
        end
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", x + 24*scale, y + 68*scale, 32*scale, 8*scale, 4*scale, 4*scale)
    elseif popperId == "comboPopper" then
        local t = time * 2
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + t
            local r, g, b = config.COLORS.rainbow(i / 6 + t * 0.1)
            love.graphics.setColor(r, g, b, 0.7)
            love.graphics.polygon("fill",
                x + 40*scale + math.cos(angle) * 32*scale,
                y + 40*scale + math.sin(angle) * 32*scale,
                x + 40*scale + math.cos(angle + 0.4) * 16*scale,
                y + 40*scale + math.sin(angle + 0.4) * 16*scale,
                x + 40*scale + math.cos(angle - 0.4) * 16*scale,
                y + 40*scale + math.sin(angle - 0.4) * 16*scale
            )
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", x + 40*scale, y + 40*scale, 14*scale)
    elseif popperId == "explosivePopper" then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", x + 40*scale, y + 48*scale, 28*scale)
        love.graphics.setColor(1, 0.7, 0.2)
        love.graphics.rectangle("fill", x + 32*scale, y + 20*scale, 16*scale, 16*scale, 4*scale, 4*scale)
        love.graphics.setColor(1, 0.3, 0)
        love.graphics.circle("fill", x + 40*scale, y + 12*scale, 6*scale)
    elseif popperId == "multiplierPopper" then
        for i = 1, 6 do
            local angle = (i / 6) * math.pi + time
            local r, g, b = config.COLORS.rainbow(i / 6 + time * 0.2)
            love.graphics.setColor(r, g, b, 0.7)
            love.graphics.push()
            love.graphics.translate(x + 40*scale, y + 40*scale)
            love.graphics.rotate(angle)
            love.graphics.rectangle("fill", -4*scale, -32*scale, 8*scale, 64*scale, 4*scale, 4*scale)
            love.graphics.pop()
        end
    elseif popperId == "cincoPopper" then
        -- Draw a hand with 5 fingers
        love.graphics.setColor(1, 0.8, 0.6) -- Skin tone
        -- Palm
        love.graphics.ellipse("fill", x + 40*scale, y + 50*scale, 20*scale, 25*scale)
        -- Thumb
        love.graphics.ellipse("fill", x + 22*scale, y + 45*scale, 8*scale, 15*scale)
        -- Fingers
        local fingerOffsets = {-12, -4, 4, 12}
        for i, offset in ipairs(fingerOffsets) do
            love.graphics.rectangle("fill", x + 38*scale + offset*scale, y + 25*scale, 4*scale, 20*scale, 2*scale, 2*scale)
        end
        -- Number "5" in the palm
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.setFont(love.graphics.newFont(14*scale))
        love.graphics.printf("5", x + 32*scale, y + 44*scale, 16*scale, "center")
        love.graphics.setFont(love.graphics.getFont()) -- Reset font
    elseif popperId == "bananaPopper" then
        -- Draw a banana
        love.graphics.setColor(1, 1, 0) -- Yellow banana
        -- Banana body (curved)
        love.graphics.push()
        love.graphics.translate(x + 40*scale, y + 40*scale)
        love.graphics.rotate(math.pi / 6) -- Slight curve
        love.graphics.ellipse("fill", 0, 0, 25*scale, 12*scale)
        love.graphics.pop()
        -- Banana stem (brown)
        love.graphics.setColor(0.4, 0.3, 0.1)
        love.graphics.circle("fill", x + 28*scale, y + 25*scale, 4*scale)
        -- Banana highlights
        love.graphics.setColor(1, 1, 0.7)
        love.graphics.push()
        love.graphics.translate(x + 40*scale, y + 40*scale)
        love.graphics.rotate(math.pi / 6)
        love.graphics.ellipse("fill", -5*scale, -2*scale, 8*scale, 3*scale)
        love.graphics.pop()
    end
end

function uiSystem.setButtonPressed(id)
    buttonStates[id] = {pressed = true, timer = 0.12}
end

function uiSystem.updateButtonStates(dt)
    for id, state in pairs(buttonStates) do
        if state.pressed then
            state.timer = state.timer - dt
            if state.timer <= 0 then
                state.pressed = false
                state.timer = 0
            end
        end
    end
end

function uiSystem.isButtonPressed(id)
    return buttonStates[id] and buttonStates[id].pressed
end

-- Initialize fonts
function uiSystem.initFonts(gameState)
    -- Only create fonts if they don't already exist
    if not gameState.fonts.title then
        gameState.fonts.title = love.graphics.newFont(42)
    end
    if not gameState.fonts.large then
        gameState.fonts.large = love.graphics.newFont(32)
    end
    if not gameState.fonts.normal then
        gameState.fonts.normal = love.graphics.newFont(20)
    end
    if not gameState.fonts.small then
        gameState.fonts.small = love.graphics.newFont(16)
    end
    if not gameState.fonts.score then
        gameState.fonts.score = love.graphics.newFont(18)
    end
    if not gameState.fonts.tiny then
        gameState.fonts.tiny = love.graphics.newFont(12)
    end
end

-- Draw menu screen
function uiSystem.drawMenu(gameState)
    love.graphics.setColor(unpack(config.COLORS.uiBackground))
    love.graphics.rectangle("fill", config.WIDTH/2 - 150, config.HEIGHT/2 - 100, 300, 200)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.title)
    love.graphics.printf("PEG BOUNCE", config.WIDTH/2 - 150, config.HEIGHT/2 - 80, 300, "center")
    
    -- Start button with rainbow glow
    local startHue = (gameState.time * 150) % 360 / 360
    local sr, sg, sb = config.COLORS.rainbow(startHue)
    love.graphics.setColor(sr, sg, sb, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 120, config.HEIGHT/2 - 10, 240, 50)
    love.graphics.setColor(sr * 1.5, sg * 1.5, sb * 1.5, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", config.WIDTH/2 - 120, config.HEIGHT/2 - 10, 240, 50)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Start Bouncing", config.WIDTH/2 - 120, config.HEIGHT/2 + 5, 240, "center")
    
    -- Quit button with rainbow glow
    local quitHue = ((gameState.time * 150) + 180) % 360 / 360
    local qr, qg, qb = config.COLORS.rainbow(quitHue)
    love.graphics.setColor(qr, qg, qb, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 120, config.HEIGHT/2 + 60, 240, 50)
    love.graphics.setColor(qr * 1.5, qg * 1.5, qb * 1.5, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", config.WIDTH/2 - 120, config.HEIGHT/2 + 60, 240, 50)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Quit Game", config.WIDTH/2 - 120, config.HEIGHT/2 + 75, 240, "center")

    -- In drawMenu, add scale animation for Start and Quit buttons
    local startBtnId = "menuStart"
    local quitBtnId = "menuQuit"
    local startScale = uiSystem.isButtonPressed(startBtnId) and 0.95 or 1.0
    local quitScale = uiSystem.isButtonPressed(quitBtnId) and 0.95 or 1.0
    love.graphics.push()
    love.graphics.translate(config.WIDTH/2, config.HEIGHT/2 + 15)
    love.graphics.scale(startScale, startScale)
    love.graphics.translate(-config.WIDTH/2, -(config.HEIGHT/2 + 15))
    love.graphics.setColor(sr, sg, sb, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 120, config.HEIGHT/2 - 10, 240, 50)
    love.graphics.setColor(sr * 1.5, sg * 1.5, sb * 1.5, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", config.WIDTH/2 - 120, config.HEIGHT/2 - 10, 240, 50)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Start Bouncing", config.WIDTH/2 - 120, config.HEIGHT/2 + 5, 240, "center")
    love.graphics.pop()
    love.graphics.push()
    love.graphics.translate(config.WIDTH/2, config.HEIGHT/2 + 85)
    love.graphics.scale(quitScale, quitScale)
    love.graphics.translate(-config.WIDTH/2, -(config.HEIGHT/2 + 85))
    love.graphics.setColor(qr, qg, qb, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 120, config.HEIGHT/2 + 60, 240, 50)
    love.graphics.setColor(qr * 1.5, qg * 1.5, qb * 1.5, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", config.WIDTH/2 - 120, config.HEIGHT/2 + 60, 240, 50)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Quit Game", config.WIDTH/2 - 120, config.HEIGHT/2 + 75, 240, "center")
    love.graphics.pop()
end

-- Draw shop screen
function uiSystem.drawShop(gameState)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 50, 50, config.WIDTH - 100, config.HEIGHT - 100)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.title)
    love.graphics.printf("SHOP - Round " .. gameState.round .. " Complete", 50, 70, config.WIDTH - 100, "center")
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Coins: " .. gameState.coins, 50, 130, config.WIDTH - 100, "center")

    -- Draw reroll button
    local rerollBtnY = 170
    love.graphics.setColor(0.2, 0.6, 1, 0.9)
    love.graphics.rectangle("fill", config.WIDTH/2 - 80, rerollBtnY, 160, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Reroll (5 coins)", config.WIDTH/2 - 80, rerollBtnY + 8, 160, "center")

    -- Vertical offset for centering lower
    local yOffset = 100

    -- Centered poppers section
    love.graphics.setFont(gameState.fonts.large)
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.printf("Poppers", config.WIDTH/2 - 200, 200 + yOffset, 400, "center")
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.setColor(1, 1, 1, 1)
    local startY = 240 + yOffset
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredPopper = nil
    local popperCount = #gameState.shopItems
    local iconSize = 80
    local spacing = 90
    for i, item in ipairs(gameState.shopItems) do
        local y = startY + (i-1)*spacing
        local canAfford = gameState.coins >= item.price
        local bought = gameState.poppers and (gameState.poppers[item.id] or 0) > 0
        local alpha = bought and 0.3 or 1
        local iconX = config.WIDTH/2 - iconSize/2
        love.graphics.setColor(1, 1, 1, alpha)
        drawPopperIcon(item.id, iconX, y, gameState.time, 1)
        -- Draw buy button to the right of icon (centered)
        local buyX, buyY, buyW, buyH = config.WIDTH/2 + iconSize/2 + 16, y + 20, 80, 40
        love.graphics.setColor(canAfford and not bought and {0.9, 0.8, 0.2, 1} or {0.5, 0.5, 0.2, 0.7})
        if bought then love.graphics.setColor(0.5, 0.5, 0.5, 0.7) end
        love.graphics.rectangle("fill", buyX, buyY, buyW, buyH, 8, 8)
        -- Draw red rectangle if mouse is over buy button (debug)
        if mouseX >= buyX and mouseX <= buyX + buyW and mouseY >= buyY and mouseY <= buyY + buyH then
            love.graphics.setColor(1, 0, 0, 0.3)
            love.graphics.rectangle("fill", buyX, buyY, buyW, buyH, 8, 8)
        end
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf(bought and "Bought" or "Buy", buyX, buyY + 8, buyW, "center")
        -- Show price to the right of buy button
        love.graphics.setColor(1, 1, 0.2, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("$" .. tostring(item.price), buyX + buyW + 12, buyY + 8, 60, "left")
        -- Hover detection for popper icon
        if mouseX >= iconX and mouseX <= iconX + iconSize and mouseY >= y and mouseY <= y + iconSize then
            hoveredPopper = item
        end
    end
    -- Centered candies section
    love.graphics.setFont(gameState.fonts.large)
    love.graphics.setColor(1, 0.7, 1, 1)
    love.graphics.printf("Candies", config.WIDTH/2 - 200, startY + popperCount * spacing + 20, 400, "center")
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.setColor(1, 1, 1, 1)
    local hoveredCandy = nil
    local candies = require('shop_system').CANDIES
    for i, candy in ipairs(candies) do
        local y = startY + popperCount * spacing + 60 + (i-1)*spacing
        local canAfford = gameState.coins >= candy.price and not (gameState.candyBought and gameState.candyBought[candy.id])
        local bought = gameState.candyBought and gameState.candyBought[candy.id]
        local iconX = config.WIDTH/2 - iconSize/2
        -- Draw heart icon for Candy of Life with floating animation
        local float = math.sin(gameState.time * 2 + iconX) * 6
        local heartY = y + float
        love.graphics.setColor(1, 0.3, 0.5, bought and 0.3 or 1)
        love.graphics.polygon("fill",
            iconX + 40, heartY + 40,
            iconX + 20, heartY + 30,
            iconX + 10, heartY + 50,
            iconX + 40, heartY + 80,
            iconX + 70, heartY + 50,
            iconX + 60, heartY + 30
        )
        love.graphics.setColor(1, 0.6, 0.8, bought and 0.3 or 1)
        love.graphics.circle("fill", iconX + 25, heartY + 38, 16)
        love.graphics.circle("fill", iconX + 55, heartY + 38, 16)
        -- Draw buy button to the right of icon (centered)
        local buyX, buyY, buyW, buyH = config.WIDTH/2 + iconSize/2 + 16, y + 20, 80, 40
        love.graphics.setColor(canAfford and not bought and {0.9, 0.8, 0.2, 1} or {0.5, 0.5, 0.2, 0.7})
        if bought then love.graphics.setColor(0.5, 0.5, 0.5, 0.7) end
        love.graphics.rectangle("fill", buyX, buyY, buyW, buyH, 8, 8)
        -- Draw red rectangle if mouse is over buy button (debug)
        if mouseX >= buyX and mouseX <= buyX + buyW and mouseY >= buyY and mouseY <= buyY + buyH then
            love.graphics.setColor(1, 0, 0, 0.3)
            love.graphics.rectangle("fill", buyX, buyY, buyW, buyH, 8, 8)
        end
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf(bought and "Bought" or "Buy", buyX, buyY + 8, buyW, "center")
        -- Show price to the right of buy button
        love.graphics.setColor(1, 1, 0.2, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("$" .. tostring(candy.price), buyX + buyW + 12, buyY + 8, 60, "left")
        -- Hover detection for candy icon
        if mouseX >= iconX and mouseX <= iconX + iconSize and mouseY >= y and mouseY <= y + iconSize then
            hoveredCandy = candy
        end
    end
    -- Draw tooltip for hovered popper
    if hoveredPopper then
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.setColor(0, 0, 0, 0.85)
        local tw = gameState.fonts.normal:getWidth(hoveredPopper.desc)
        love.graphics.rectangle("fill", mouseX + 16, mouseY + 8, tw + 24, 40, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(hoveredPopper.desc, mouseX + 28, mouseY + 18)
    end
    -- Draw tooltip for hovered candy
    if hoveredCandy then
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.setColor(0, 0, 0, 0.85)
        local tw = gameState.fonts.normal:getWidth(hoveredCandy.desc)
        love.graphics.rectangle("fill", mouseX + 16, mouseY + 8, tw + 24, 40, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(hoveredCandy.desc, mouseX + 28, mouseY + 18)
    end
    -- Draw exit/advance button
    local exitBtnY = startY + popperCount * spacing + 60 + #require('shop_system').CANDIES * spacing + 40
    local btnX, btnY, btnW, btnH = config.WIDTH/2 - 100, exitBtnY, 200, 50
    -- Draw glowing rainbow outline
    for i = 3, 1, -1 do
        local hue = ((gameState.time * 100 + i * 60) % 360) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        local alpha = 0.25 + 0.15 * i
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.setLineWidth(i)
        love.graphics.rectangle("line", btnX - i, btnY - i, btnW + 2*i, btnH + 2*i, 14, 14)
    end
    love.graphics.setLineWidth(1)
    -- Draw black button
    love.graphics.setColor(0, 0, 0, 0.95)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 14, 14)
    -- Draw white text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Continue", btnX, btnY + 15, btnW, "center")
end

-- Draw game over screen
function uiSystem.drawGameOver(gameState)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 200, config.HEIGHT/2 - 150, 400, 300)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.title)
    love.graphics.printf("GAME OVER", config.WIDTH/2 - 200, config.HEIGHT/2 - 130, 400, "center")
    
    love.graphics.setFont(gameState.fonts.normal)
    local finalScore = (gameState.currentRound and gameState.currentRound.score) or 0
    love.graphics.printf("Final Score: " .. finalScore, config.WIDTH/2 - 200, config.HEIGHT/2 - 70, 400, "center")
    love.graphics.printf("Rounds Completed: " .. (gameState.round - 1) .. "/" .. gameState.totalRounds, config.WIDTH/2 - 200, config.HEIGHT/2 - 40, 400, "center")
    
    -- Restart button
    love.graphics.setColor(unpack(config.COLORS.buttonGreen))
    love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 + 20, 200, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PLAY AGAIN", config.WIDTH/2 - 100, config.HEIGHT/2 + 30, 200, "center")
    
    -- Menu button
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 + 70, 200, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("MAIN MENU", config.WIDTH/2 - 100, config.HEIGHT/2 + 80, 200, "center")
end

-- Draw pause menu
function uiSystem.drawPauseMenu(gameState)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", config.WIDTH/2 - 150, config.HEIGHT/2 - 100, 300, 200)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.title)
    love.graphics.printf("PAUSED", config.WIDTH/2 - 150, config.HEIGHT/2 - 80, 300, "center")
    
    -- Resume button
    love.graphics.setColor(unpack(config.COLORS.buttonGreen))
    love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 - 30, 200, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("RESUME", config.WIDTH/2 - 100, config.HEIGHT/2 - 25, 200, "center")
    
    -- Restart button
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 + 10, 200, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("RESTART ROUND", config.WIDTH/2 - 100, config.HEIGHT/2 + 15, 200, "center")
    
    -- Quit button
    love.graphics.setColor(unpack(config.COLORS.buttonRed))
    love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 + 50, 200, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("QUIT TO MENU", config.WIDTH/2 - 100, config.HEIGHT/2 + 55, 200, "center")
end

-- Draw UI elements
function uiSystem.drawUI(gameState)
    -- Add round number and coins next to each other above play area on the left
    local infoX = config.PLAY_X + 10
    local infoY = config.PLAY_Y - 60
    love.graphics.setFont(gameState.fonts.normal)
    -- Round number (light grey)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Round: " .. tostring(gameState.round), infoX, infoY)
    -- Coins (gold color, label and amount)
    local roundTextWidth = love.graphics.getFont():getWidth("Round: " .. tostring(gameState.round))
    local gap = 40
    local coinsX = infoX + roundTextWidth + gap
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print("Coins: " .. tostring(gameState.coins), coinsX, infoY)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    
    -- Lives (above play area)
    local livesStartX = config.PLAY_X + config.PLAY_WIDTH/2 - (config.START_LIVES * 25)/2
    for i = 1, config.START_LIVES do
        if i <= gameState.lives then
            love.graphics.setColor(0.2, 0.8, 0.2)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        end
        love.graphics.circle("fill", livesStartX + (i-1)*25, 80, 10)
    end
    
    -- Progress bar (bottom of play area) - bigger with flaming rainbow effect
    local progressWidth = 500
    local progressHeight = 40
    local roundScore = (gameState.currentRound and gameState.currentRound.score or 0)
    local progress = math.min(roundScore / gameState.goal, 1.0)
    local progressX = config.PLAY_X + config.PLAY_WIDTH/2 - progressWidth/2
    local progressY = config.PLAY_Y + config.PLAY_HEIGHT + 20

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", progressX, progressY, progressWidth, progressHeight)
    
    -- Flaming rainbow fill
    local fillWidth = progressWidth * progress
    for i = 1, math.floor(fillWidth) do
        local hue = ((i * 3 + gameState.time * 200) % 360) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        local flame = 0.7 + 0.3 * math.sin((i * 0.1 + gameState.time * 5) * math.pi)
        love.graphics.setColor(r * flame, g * flame, b * flame, 0.9)
        love.graphics.rectangle("fill", progressX + i, progressY, 1, progressHeight)
    end
    
    -- Glowing border
    local hue = (gameState.time * 100) % 360 / 360
    local r, g, b = config.COLORS.rainbow(hue)
    love.graphics.setColor(r, g, b, 0.8)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", progressX - 2, progressY - 2, progressWidth + 4, progressHeight + 4)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf(math.floor(progress * 100) .. "%", progressX, progressY + 10, progressWidth, "center")
    
    -- Score text underneath with rainbow glow
    local scoreText = roundScore .. "/" .. gameState.goal .. " points"
    local scoreY = progressY + progressHeight + 10
    
    if gameState.scoreGlowTimer > 0 then
        -- Rainbow glow effect
        local glowHue = (gameState.time * 300) % 360 / 360
        local gr, gg, gb = config.COLORS.rainbow(glowHue)
        love.graphics.setColor(gr, gg, gb, gameState.scoreGlowTimer)
    else
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Calculate scale based on scoreScaleTimer
    local scale = 1.0
    if gameState.scoreScaleTimer > 0 then
        -- Create a bouncy scale effect that starts big and shrinks back to normal
        local progress = 1 - (gameState.scoreScaleTimer / 0.5) -- Normalize to 0-1
        scale = 1.0 + 0.5 * math.sin(progress * math.pi) -- Smooth sine curve from 1.0 to 1.5 and back
    end
    
    love.graphics.push()
    love.graphics.translate(progressX + progressWidth/2, scoreY + 20) -- Center point for scaling
    love.graphics.scale(scale, scale)
    love.graphics.setFont(gameState.fonts.title)
    love.graphics.printf(scoreText, -progressWidth/2, -20, progressWidth, "center")
    love.graphics.pop()

    -- Show yellow text for ball collision points above meter for 1 second
    if gameState.lastBallCollisionPoints and love.timer.getTime() - gameState.lastBallCollisionTime < 1 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(gameState.fonts.score)
        love.graphics.printf("+" .. gameState.lastBallCollisionPoints .. " Ball Collision!", progressX, 25, progressWidth, "center")
        love.graphics.setFont(gameState.fonts.small)
    end
end

-- Draw aiming system
function uiSystem.drawAimingSystem(gameState)
    -- Draw launch position
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", gameState.aimX, gameState.aimY, 25)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", gameState.aimX, gameState.aimY, 25)
    
    -- Draw aiming arrow
    local dx = gameState.mouseX - gameState.aimX
    local dy = gameState.mouseY - gameState.aimY
    local length = math.min(math.sqrt(dx*dx + dy*dy), 150) -- Limit arrow length
    local angle = math.atan2(dy, dx)
    
    -- Arrow line
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(4)
    local endX = gameState.aimX + math.cos(angle) * length
    local endY = gameState.aimY + math.sin(angle) * length
    love.graphics.line(gameState.aimX, gameState.aimY, endX, endY)
    
    -- Arrow head
    local headSize = 15
    local headAngle1 = angle + math.pi * 0.8
    local headAngle2 = angle - math.pi * 0.8
    love.graphics.line(endX, endY, endX + math.cos(headAngle1) * headSize, endY + math.sin(headAngle1) * headSize)
    love.graphics.line(endX, endY, endX + math.cos(headAngle2) * headSize, endY + math.sin(headAngle2) * headSize)
    love.graphics.setLineWidth(1)
    
    -- Show instruction
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.normal)
    love.graphics.printf("Aim and click to launch!", 0, config.HEIGHT - 30, config.WIDTH, "center")
end

-- Draw multiplier meter
function uiSystem.drawMultiplierMeter(gameState)
    local meterWidth = 60
    local meterHeight = 400
    local meterX = config.PLAY_X - meterWidth - 30  -- Moved to left side to match combo indicator
    local meterY = config.PLAY_Y + config.PLAY_HEIGHT/2 - meterHeight/2
    
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", meterX, meterY, meterWidth, meterHeight)
    
    -- Liquid rainbow fill
    local fillHeight = (gameState.multiplierMeter / 10) * meterHeight
    for i = 1, math.floor(fillHeight) do
        local hue = ((i * 5 + gameState.time * 100) % 360) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.rectangle("fill", meterX + 5, meterY + meterHeight - i, meterWidth - 10, 1)
    end
    
    -- Rainbow border with shockwave effect
    local shockwaveSize = gameState.rainbowShockwave > 0 and (1 - gameState.rainbowShockwave) * 20 or 0
    for i = 1, 5 + math.floor(shockwaveSize) do
        local hue = ((i * 60 + gameState.time * 200) % 360) / 360
        local r, g, b = config.COLORS.rainbow(hue)
        local alpha = gameState.rainbowShockwave > 0 and (0.8 - i * 0.1) or (i == 1 and 1.0 or 0)
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", meterX - i, meterY - i, meterWidth + i*2, meterHeight + i*2)
    end
    love.graphics.setLineWidth(1)
    
    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(gameState.fonts.small)
    love.graphics.printf("x" .. string.format("%.0f", gameState.multiplier), meterX - 20, meterY - 30, meterWidth + 40, "center")
    love.graphics.printf(gameState.multiplierMeter .. "/10", meterX - 20, meterY + meterHeight + 10, meterWidth + 40, "center")
end

-- Draw popper activations
function uiSystem.drawPopperActivations(gameState)
    if not gameState.popperActivations or #gameState.popperActivations == 0 then
        return
    end
    
    local startX = config.PLAY_X + 10
    local startY = config.PLAY_Y + 10
    local spacing = 30
    
    for i, activation in ipairs(gameState.popperActivations) do
        local y = startY + (i - 1) * spacing
        local alpha = math.min(activation.timer / 2.0, 1.0)
        
        -- Draw popper icon
        love.graphics.push()
        love.graphics.translate(startX, y)
        drawPopperIcon(activation.type .. "Popper", 0, 0, gameState.time, 0.5)
        love.graphics.pop()
        
        -- Draw points text to the right of icon
        love.graphics.setColor(activation.color[1], activation.color[2], activation.color[3], alpha)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("+" .. activation.points, startX + 50, y + 15, 100, "left")
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

-- Draw candy row
function uiSystem.drawCandyRow(gameState)
    local shopSystem = require('shop_system')
    local candies = shopSystem.CANDIES
    local bought = gameState.candyBought or {}
    local numCandies = 0
    for _, candy in ipairs(candies) do
        if bought[candy.id] then
            numCandies = numCandies + 1
        end
    end
    if numCandies == 0 then return end
    local boxSize = 44
    local spacing = 12
    local totalWidth = numCandies * boxSize + (numCandies - 1) * spacing
    local x0 = config.PLAY_X + config.PLAY_WIDTH - totalWidth - 30
    local y0 = 10
    -- Draw pink outline for the row
    love.graphics.setColor(1, 0.3, 0.7, 0.7)
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", x0 - 8, y0 - 8, totalWidth + 16, boxSize + 16, 14, 14)
    love.graphics.setLineWidth(1)
    -- Draw each bought candy
    local i = 0
    for _, candy in ipairs(candies) do
        if bought[candy.id] then
            local x = x0 + i * (boxSize + spacing)
            -- Pink outline for each box
            love.graphics.setColor(1, 0.3, 0.7, 1)
            love.graphics.rectangle("line", x, y0, boxSize, boxSize, 10, 10)
            -- Box background
            love.graphics.setColor(0.9, 0.7, 0.9, 0.8)
            love.graphics.rectangle("fill", x, y0, boxSize, boxSize, 10, 10)
            -- Candy name (or icon if you want to add one)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(gameState.fonts.small)
            love.graphics.printf(candy.name, x, y0 + boxSize/2 - 8, boxSize, "center")
            i = i + 1
        end
    end
end

-- Remove all perk slot logic and visuals
uiSystem.drawPerkSlots = function() end

-- Draw "Next Round" button
function uiSystem.drawNextRoundButton(gameState)
    if gameState.canAdvanceRound then
        -- Rainbow "YOU WON" text
        local hue = (gameState.time * 100) % 360 / 360
        local r, g, b = config.COLORS.rainbow(hue)
        love.graphics.setColor(r, g, b, 1.0)
        love.graphics.setFont(gameState.fonts.title)
        love.graphics.printf("YOU WON!", 0, config.HEIGHT/2 - 100, config.WIDTH, "center")
        
        -- Next round button under the text
        love.graphics.setColor(unpack(config.COLORS.buttonBlue))
        love.graphics.rectangle("fill", config.WIDTH/2 - 100, config.HEIGHT/2 - 40, 200, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("NEXT ROUND", config.WIDTH/2 - 100, config.HEIGHT/2 - 30, 200, "center")
    end
end

-- Draw hover peg warning
function uiSystem.drawHoverPegWarning(gameState)
    if gameState.hoverPeg and gameState.state == config.GAME_STATE.PLAYING then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf("Can't drop balls on pegs!", config.PLAY_X, config.PLAY_Y + config.PLAY_HEIGHT + 60, config.PLAY_WIDTH, "center")
    end
end

function uiSystem.drawPoppers(gameState)
    local x = 100
    local y = 120
    local iconSize = 80
    local spacing = 90
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredPopper = nil
    local label = "Poppers"
    if gameState.fonts and gameState.fonts.large then
        love.graphics.setFont(gameState.fonts.large)
    end
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local ox = math.cos(angle) * 3
        local oy = math.sin(angle) * 3
        local glow = 0.5 + 0.3 * math.sin(gameState.time * 4)
        love.graphics.setColor(0.2, 1, 0.2, glow) -- Green glowing outline
        love.graphics.printf(label, x + ox - 10, y + oy - 60, 200, "left")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(label, x - 10, y - 60, 200, "left")
    if gameState.fonts and gameState.fonts.normal then
        love.graphics.setFont(gameState.fonts.normal)
    end
    for _, item in ipairs(require('shop_system').POPPERS) do
        local count = gameState.poppers[item.id] or 0
        if count > 0 then
            drawPopperIcon(item.id, x, y, gameState.time, 1)
            if mouseX >= x and mouseX <= x + iconSize and mouseY >= y and mouseY <= y + iconSize then
                hoveredPopper = item
            end
            y = y + spacing
        end
    end
    if hoveredPopper then
        local tipW, tipH = 340, 80
        local tipX = math.min(mouseX + 24, config.WIDTH - tipW - 24)
        local tipY = math.max(mouseY - tipH - 12, 20)
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tipX, tipY, tipW, tipH, 12, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf(hoveredPopper.name, tipX + 12, tipY + 8, tipW - 24, "left")
        love.graphics.setFont(gameState.fonts.tiny)
        love.graphics.printf(hoveredPopper.desc, tipX + 12, tipY + 36, tipW - 24, "left")
    end
end

-- Draw candies during gameplay (right side, like poppers)
function uiSystem.drawCandies(gameState)
    local shopSystem = require('shop_system')
    local candies = shopSystem.CANDIES
    local bought = gameState.candyBought or {}
    local x = config.PLAY_X + config.PLAY_WIDTH + 40
    local y = 120
    local iconSize = 80
    local spacing = 90
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredCandy = nil
    local label = "Candies"
    if gameState.fonts and gameState.fonts.large then
        love.graphics.setFont(gameState.fonts.large)
    end
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local ox = math.cos(angle) * 3
        local oy = math.sin(angle) * 3
        local glow = 0.5 + 0.3 * math.sin(gameState.time * 4)
        love.graphics.setColor(1, 0.4, 0.8, glow) -- Pink glowing outline
        love.graphics.printf(label, x + ox - 10, y + oy - 60, 200, "left")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(label, x - 10, y - 60, 200, "left")
    if gameState.fonts and gameState.fonts.normal then
        love.graphics.setFont(gameState.fonts.normal)
    end
    for _, candy in ipairs(candies) do
        if bought[candy.id] then
            -- Draw heart icon for Candy of Life
            love.graphics.setColor(1, 0.3, 0.5)
            love.graphics.polygon("fill",
                x + 40, y + 40,
                x + 20, y + 30,
                x + 10, y + 50,
                x + 40, y + 80,
                x + 70, y + 50,
                x + 60, y + 30
            )
            love.graphics.setColor(1, 0.6, 0.8)
            love.graphics.circle("fill", x + 25, y + 38, 16)
            love.graphics.circle("fill", x + 55, y + 38, 16)
            -- Hover detection
            if mouseX >= x and mouseX <= x + iconSize and mouseY >= y and mouseY <= y + iconSize then
                hoveredCandy = candy
            end
            y = y + spacing
        end
    end
    if hoveredCandy then
        local tipW, tipH = 340, 80
        local tipX = math.min(mouseX + 24, config.WIDTH - tipW - 24)
        local tipY = math.max(mouseY - tipH - 12, 20)
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tipX, tipY, tipW, tipH, 12, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameState.fonts.normal)
        love.graphics.printf(hoveredCandy.name, tipX + 12, tipY + 8, tipW - 24, "left")
        love.graphics.setFont(gameState.fonts.tiny)
        love.graphics.printf(hoveredCandy.desc, tipX + 12, tipY + 36, tipW - 24, "left")
    end
end

return uiSystem 