-- shop_system.lua
-- Shop system management

local config = require('config')
local visualEffects = require('visual_effects')

local shopSystem = {}

-- Define the Green, Red, and Blue Poppers
shopSystem.POPPERS = {
    {id = "greenPopper", name = "Green Popper", desc = "Gain +30 points for every green peg hit this round.", price = 12, rarity = 1},
    {id = "redPopper", name = "Red Popper", desc = "Gain +50 points for every red peg hit this round.", price = 18, rarity = 1},
    {id = "bluePopper", name = "Blue Popper", desc = "Gain +100 points for every blue peg hit this round.", price = 40, rarity = 0.5},
    {id = "bouncePopper", name = "Bounce Popper", desc = "Gain +10 points every time the ball bounces.", price = 22, rarity = 0.8},
    {id = "wallPopper", name = "Wall Popper", desc = "Gain +15 points every time the ball bounces off a wall.", price = 16, rarity = 1},
    {id = "comboPopper", name = "Combo Popper", desc = "Gain +20 points for every combo hit (3+ pegs in a single bounce).", price = 20, rarity = 0.8},
    {id = "explosivePopper", name = "Explosive Popper", desc = "Every 5th peg hit in a round explodes, clearing nearby pegs and granting +50 points (red explosion).", price = 30, rarity = 0.6},
    {id = "multiplierPopper", name = "Multiplier Popper", desc = "All points earned this round are multiplied by 1.2x.", price = 35, rarity = 0.5}
}

-- Define the Candies
shopSystem.CANDIES = {
    {id = "candyLife", name = "Candy of Life", desc = "Gain +1 life. Can only be bought once.", price = 15, once = true}
}

-- Check if item/perk is available for purchase
function shopSystem.isAvailable(gameState, id)
    if id == "extraBall1" then return gameState.round >= 5 and not gameState.upgrades.extraBall1 end
    if id == "extraBall2" then return gameState.round >= 10 and gameState.upgrades.extraBall1 and not gameState.upgrades.extraBall2 end
    if id == "extraBall3" then return gameState.round >= 15 and gameState.upgrades.extraBall2 and not gameState.upgrades.extraBall3 end
    if id == "extraBall4" then return gameState.round >= 20 and gameState.upgrades.extraBall3 and not gameState.upgrades.extraBall4 end
    if id == "multiplierBoost" then return gameState.multiplierBoostLevel < 5 end
    if id == "wallPoints" then return not gameState.upgrades.wallPoints end
    if id == "wallToWall" then return gameState.wallToWallLevel < 5 end
    if id == "paprika" then return gameState.paprikaLevel < 5 end
    if id == "extraLife" then return not gameState.upgrades.extraLife end
    if id == "speedBoost" then return true end -- Always available
    if id == "giantBall" then return true end -- Always available
    if id == "magnetBall" then return true end -- Always available
    if id == "rainbowTrail" then return true end -- Always available
    if id == "explosionRadius" then return true end -- Always available
    if id == "comboMaster" then return not gameState.upgrades.comboMaster end
    if id == "luckyStrike" then return not gameState.upgrades.luckyStrike end
    if id == "comboKing" then return not gameState.upgrades.comboKing end
    if id == "explosionExpert" then return not gameState.upgrades.explosionExpert end
    if id == "luckyCharm" then return not gameState.upgrades.luckyCharm end
    return not gameState.upgrades[id]
end

-- Reroll shop items (just reshuffle the three Poppers)
function shopSystem.rerollShopItems(gameState)
    gameState.shopItems = {}
    local poppers = {}
    -- Only include poppers not yet bought
    for _, popper in ipairs(shopSystem.POPPERS) do
        if not gameState.poppers or (gameState.poppers[popper.id] or 0) == 0 then
            table.insert(poppers, popper)
        end
    end
    local selected = {}
    local maxItems = math.min(3, #poppers)
    for i = 1, maxItems do
        -- Weighted random selection based on rarity
        local totalWeight = 0
        for _, popper in ipairs(poppers) do
            totalWeight = totalWeight + (popper.rarity or 1)
        end
        local pick = math.random() * totalWeight
        local accum = 0
        local chosenIndex = 1
        for idx, popper in ipairs(poppers) do
            accum = accum + (popper.rarity or 1)
            if pick <= accum then
                chosenIndex = idx
                break
            end
        end
        table.insert(gameState.shopItems, poppers[chosenIndex])
        table.remove(poppers, chosenIndex)
    end
end

-- Reroll shop perks
function shopSystem.rerollShopPerks(gameState)
    gameState.shopPerks = {}
    local available = {}
    for _, perk in ipairs(gameState.allPerks) do
        if shopSystem.isAvailable(gameState, perk.id) then
            table.insert(available, perk)
        end
    end
    for i = 1, math.min(6, #available) do
        local idx = math.random(#available)
        table.insert(gameState.shopPerks, available[idx])
        table.remove(available, idx)
    end
end

-- Purchase item
function shopSystem.purchaseItem(gameState, item)
    -- Only allow buying if not already owned
    if (gameState.poppers and (gameState.poppers[item.id] or 0) > 0) then
        return false
    end
    if gameState.coins >= item.price then
        if item.id == "greenPopper" then
            gameState.poppers.greenPopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "redPopper" then
            gameState.poppers.redPopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "bluePopper" then
            gameState.poppers.bluePopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "bouncePopper" then
            gameState.poppers.bouncePopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "wallPopper" then
            gameState.poppers.wallPopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "comboPopper" then
            gameState.poppers.comboPopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "explosivePopper" then
            gameState.poppers.explosivePopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "multiplierPopper" then
            gameState.poppers.multiplierPopper = 1
            gameState.coins = gameState.coins - item.price
            return true
        elseif item.id == "speedBoost" then
            require('power_ups').activatePowerUp(gameState, "speedBoost")
            gameState.coins = gameState.coins - item.price
        elseif item.id == "giantBall" then
            require('power_ups').activatePowerUp(gameState, "giantBall")
            gameState.coins = gameState.coins - item.price
        elseif item.id == "magnetBall" then
            require('power_ups').activatePowerUp(gameState, "magnetBall")
            gameState.coins = gameState.coins - item.price
        elseif item.id == "rainbowTrail" then
            require('power_ups').activatePowerUp(gameState, "rainbowTrail")
            gameState.coins = gameState.coins - item.price
        elseif item.id == "explosionRadius" then
            require('power_ups').activatePowerUp(gameState, "explosionRadius")
            gameState.coins = gameState.coins - item.price
        elseif item.id == "comboMaster" then
            gameState.combo.maxTime = gameState.combo.maxTime * 1.5
            gameState.coins = gameState.coins - item.price
        elseif item.id == "luckyStrike" then
            gameState.upgrades.luckyStrike = true
            gameState.coins = gameState.coins - item.price
        elseif item.id == "wallPoints" then
            gameState.upgrades.wallPoints = true
            gameState.coins = gameState.coins - item.price
        elseif item.id == "wallToWall" then
            if gameState.wallToWallLevel < 5 then
                gameState.wallToWallLevel = gameState.wallToWallLevel + 1
                -- Find existing wall to wall perk or add new one
                local found = false
                for j = 1, 5 do
                    if gameState.perks[j] == 1 then
                        gameState.perkCounts[j] = gameState.perkCounts[j] + 1
                        found = true
                        break
                    end
                end
                if not found then
                    for j = 1, 5 do
                        if gameState.perks[j] == 0 then
                            gameState.perks[j] = 1
                            gameState.perkCounts[j] = 1
                            break
                        end
                    end
                end
                gameState.coins = gameState.coins - item.price
            end
        elseif item.id == "paprika" then
            if gameState.paprikaLevel < 5 then
                gameState.paprikaLevel = gameState.paprikaLevel + 1
                -- Find existing paprika perk or add new one
                local found = false
                for j = 1, 5 do
                    if gameState.perks[j] == 2 then
                        gameState.perkCounts[j] = gameState.perkCounts[j] + 1
                        found = true
                        break
                    end
                end
                if not found then
                    for j = 1, 5 do
                        if gameState.perks[j] == 0 then
                            gameState.perks[j] = 2
                            gameState.perkCounts[j] = 1
                            break
                        end
                    end
                end
                gameState.coins = gameState.coins - item.price
            end
        elseif item.id == "comboKing" then
            gameState.upgrades.comboKing = true
            gameState.coins = gameState.coins - item.price
        elseif item.id == "explosionExpert" then
            gameState.upgrades.explosionExpert = true
            gameState.coins = gameState.coins - item.price
        elseif item.id == "luckyCharm" then
            gameState.upgrades.luckyCharm = true
            gameState.coins = gameState.coins - item.price
        elseif item.id == "extraBall1" then
            gameState.upgrades.extraBall1 = true
            gameState.maxBalls = 2
            gameState.coins = gameState.coins - item.price
        elseif item.id == "extraBall2" then
            gameState.upgrades.extraBall2 = true
            gameState.maxBalls = 3
            gameState.coins = gameState.coins - item.price
        elseif item.id == "extraBall3" then
            gameState.upgrades.extraBall3 = true
            gameState.maxBalls = 4
            gameState.coins = gameState.coins - item.price
        elseif item.id == "extraBall4" then
            gameState.upgrades.extraBall4 = true
            gameState.maxBalls = 5
            gameState.coins = gameState.coins - item.price
        elseif item.id == "extraLife" then
            gameState.upgrades.extraLife = true
            gameState.lives = gameState.lives + 1
            gameState.coins = gameState.coins - item.price
        elseif item.id == "multiplierBoost" then
            gameState.multiplierBoostLevel = gameState.multiplierBoostLevel + 1
            gameState.coins = gameState.coins - item.price
        else
            -- Handle basic upgrades
            gameState.upgrades[item.id] = true
            gameState.coins = gameState.coins - item.price
        end
        return true
    else
        -- Show "Not enough coins" feedback
        visualEffects.addEffect(gameState, config.WIDTH/2, config.HEIGHT/2, "Not enough coins!", {1, 0.4, 0.4})
        return false
    end
end

-- Purchase candy
function shopSystem.purchaseCandy(gameState, candy)
    if candy.id == "candyLife" then
        if (gameState.candyBought and gameState.candyBought[candy.id]) then
            return false -- Already bought
        end
        if gameState.coins >= candy.price then
            gameState.lives = gameState.lives + 1
            gameState.coins = gameState.coins - candy.price
            gameState.candyBought = gameState.candyBought or {}
            gameState.candyBought[candy.id] = true
            return true
        end
    end
    return false
end

return shopSystem 