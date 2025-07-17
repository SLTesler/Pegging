# Cinco Popper Implementation Summary

## What I've Added

### 1. New Cinco Popper Definition
Added to `shop_system.lua` in the POPPERS table:
```lua
{id = "cincoPopper", name = "Cinco", desc = "Gain +250 points for every 5th time the ball bounces.", price = 45, rarity = 0.4}
```

### 2. Purchase Handler
Added purchase handler in `shop_system.lua`:
```lua
elseif item.id == "cincoPopper" then
    gameState.poppers.cincoPopper = (gameState.poppers.cincoPopper or 0) + 1
    gameState.coins = gameState.coins - item.price
    return true
```

### 3. Scoring Configuration
Added to `config.lua` in the SCORING section:
```lua
CINCO_POPPER_POINTS = 250,
```

### 4. Effect Implementation
Added to `collision_system.lua` in the `applyPopperEffects` function:
```lua
elseif effectType == "cinco" and gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 then
    points = config.SCORING.CINCO_POPPER_POINTS
    effectText = "+" .. points .. " CINCO!"
    effectColor = {1, 0.8, 0.2}
```

### 5. Trigger Logic
Added to both peg collisions and wall collisions in `collision_system.lua`:

**For Peg Collisions:**
```lua
-- Cinco Popper: bonus for every 5th bounce
if gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 and ball.bounceCount % 5 == 0 then
    applyPopperEffects(gameState, ball, peg, "cinco")
end
```

**For Wall Collisions:**
```lua
-- Cinco Popper: bonus for every 5th bounce (wall hits count too)
if gameState.poppers and (gameState.poppers.cincoPopper or 0) > 0 and ball.bounceCount % 5 == 0 then
    applyPopperEffects(gameState, ball, nil, "cinco")
end
```

## How Cinco Works

- **Trigger**: Every 5th time a ball bounces (both peg hits and wall hits count)
- **Effect**: +250 points
- **Visual**: Shows "+250 CINCO!" text effect in golden color
- **Logic**: Uses `ball.bounceCount % 5 == 0` to check if it's the 5th bounce
- **Price**: 45 coins (expensive but powerful)
- **Rarity**: 0.4 (rare, appears less frequently in shop)

## Candy System Status

The candy system remains unchanged with only the original "Candy of Life" available:
- **Candy of Life**: +1 life for 15 coins (can only be bought once)

## Testing

To test the Cinco popper:
1. Start the game and play through to the shop
2. Purchase the "Cinco" popper (if it appears)
3. During gameplay, watch for "+250 CINCO!" text effects every 5th bounce
4. The effect works for both peg hits and wall hits

The Cinco popper is now fully implemented and should work correctly in the game! 