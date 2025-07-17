-- game_state.lua
-- Game state management

local config = require('config')

local gameState = {
    -- Core game state
    state = config.GAME_STATE.MENU,
    round = 1,
    lives = config.START_LIVES,
    goal = config.START_GOAL,
    coins = 0,
    balls = {},
    pegs = {},
    pegShapes = {},

    -- Upgrades system
    upgrades = {
        wallPoints = false,
        doubleHit = false,
        ballCollision = false,
        coinPerHit = false,
        extraLife = false,
        collisionBonus = false,
        extraBall1 = false,
        extraBall2 = false,
        extraBall3 = false,
        extraBall4 = false
    },

    -- Shop system
    maxBalls = 1,
    multiplierBoostLevel = 0,
    shopType = 1,
    shopItems = {},

    -- Power-up system
    powerUps = {
        speedBoost = {active = false, timer = 0, duration = config.POWER_UPS.speedBoost.duration, multiplier = config.POWER_UPS.speedBoost.multiplier},
        giantBall = {active = false, timer = 0, duration = config.POWER_UPS.giantBall.duration, sizeMultiplier = config.POWER_UPS.giantBall.sizeMultiplier},
        magnetBall = {active = false, timer = 0, duration = config.POWER_UPS.magnetBall.duration, attractionRadius = config.POWER_UPS.magnetBall.attractionRadius},
        rainbowTrail = {active = false, timer = 0, duration = config.POWER_UPS.rainbowTrail.duration},
        explosionRadius = {active = false, timer = 0, duration = config.POWER_UPS.explosionRadius.duration, radius = config.POWER_UPS.explosionRadius.radius}
    },

    -- Combo system
    combo = {
        count = 0,
        timer = 0,
        maxTime = config.COMBO.maxTime,
        multiplier = 1.0,
        maxMultiplier = config.COMBO.maxMultiplier
    },

    -- Random events
    randomEvents = {
        pegExplosion = {timer = 0, interval = config.RANDOM_EVENTS.pegExplosion.interval, lastEvent = 0},
        rainbowStorm = {timer = 0, interval = config.RANDOM_EVENTS.rainbowStorm.interval, lastEvent = 0},
        gravityShift = {timer = 0, interval = config.RANDOM_EVENTS.gravityShift.interval, lastEvent = 0}
    },

    -- Screen shake
    screenShake = {
        intensity = 0,
        duration = 0,
        offsetX = 0,
        offsetY = 0
    },

    -- Stats tracking
    stats = {
        totalPegsHit = 0,
        totalCoinsCollected = 0,
        powerUpsUsed = 0,
        explosionsTriggered = 0,
        maxCombo = 0,
        maxMultiplier = 1.0,
        perfectRounds = 0
    },

    -- Shop items
    allItems = {
        {name="Speed Boost", desc="Balls move 50% faster for 5 seconds", price=15, id="speedBoost"},
        {name="Giant Ball", desc="Balls become 2x larger for 8 seconds", price=20, id="giantBall"},
        {name="Magnet Ball", desc="Balls attract to pegs for 6 seconds", price=25, id="magnetBall"},
        {name="Rainbow Trail", desc="Balls leave rainbow trails for 10 seconds", price=30, id="rainbowTrail"},
        {name="Explosion Radius", desc="Hits create explosions for 12 seconds", price=35, id="explosionRadius"},
        {name="Combo Master", desc="Combo timer lasts 50% longer", price=18, id="comboMaster"},
        {name="Lucky Strike", desc="25% chance for random peg explosions", price=22, id="luckyStrike"},
        {name="Life Support", desc="+1 Life permanently", price=20, id="extraLife"},
        {name="Baller 1", desc="Drop 2 balls total", price=15, id="extraBall1"},
        {name="Baller 2", desc="Drop 3 balls total", price=20, id="extraBall2"},
        {name="Baller 3", desc="Drop 4 balls total", price=25, id="extraBall3"},
        {name="Baller 4", desc="Drop 5 balls total", price=30, id="extraBall4"},
        {name="Multiplier Boost", desc="+5% multiplier gain per level", price=18, id="multiplierBoost"}
    },



    -- Visual effects
    effects = {},
    particles = {},
    fonts = {},

    -- Gameplay state
    canDropBalls = true,
    hoverPeg = false,
    totalRounds = config.ROUNDS,
    roundCompleteTimer = nil,
    meterFlashTimer = 0,
    lastBallCollisionPoints = nil,
    lastBallCollisionTime = 0,
    multiplierMeter = 0,
    multiplier = 1.0,
    rainbowShockwave = 0,
    aimX = config.PLAY_X + config.PLAY_WIDTH/2,
    aimY = config.PLAY_Y + 30,
    mouseX = 0,
    mouseY = 0,
    isAiming = false,
    time = 0,
    collisionCount = 0,
    scoreGlowTimer = 0,
    scoreScaleTimer = 0,
    popperActivations = {}, -- Track recent popper activations for UI display
    victoryTimer = 0, -- Timer for victory celebration before round summary
    wallHitTimer = nil,
    goldPegPositions = nil,
    bonusPegPositions = nil,
    canAdvanceRound = false,
    poppers = {}, -- Holds owned Poppers and their counts
    currentRound = nil, -- Will be initialized properly
    candyBought = {},
    pegsHitThisRound = 0,
    
    -- Random seed initialization flag
    randomSeedInitialized = false,
}

-- Initialize a new round state
function gameState:initializeRound()
    self.currentRound = {
        balls_remaining = config.START_BALLS,
        active_balls = 0,
        score = 0,
        multiplier = 1,
        perfect = true,
    }
    if self.candyBought == nil then self.candyBought = {} end
end

-- Ensure currentRound is always valid
function gameState:ensureRoundState()
    if not self.currentRound then
        self:initializeRound()
    end
end

-- Initialize random seed if not done
function gameState:initializeRandomSeed()
    if not self.randomSeedInitialized then
        math.randomseed(os.time())
        -- Warm up the random number generator
        for i = 1, 10 do
            math.random()
        end
        self.randomSeedInitialized = true
    end
end

-- Reset game state to initial values
function gameState:reset()
    self.state = config.GAME_STATE.MENU
    self.round = 1
    self.lives = config.START_LIVES
    self.goal = config.START_GOAL
    self.coins = 0
    self.balls = {}
    self.pegs = {}
    self.pegShapes = {}
    self.effects = {}
    self.particles = {}
    
    -- Initialize round state properly
    self:initializeRound()
    
    -- Initialize random seed
    self:initializeRandomSeed()
    
    -- Reset upgrades
    self.upgrades = {
        wallPoints = false,
        doubleHit = false,
        ballCollision = false,
        coinPerHit = false,
        extraLife = false,
        collisionBonus = false,
        extraBall1 = false,
        extraBall2 = false,
        extraBall3 = false,
        extraBall4 = false
    }
    
    -- Reset shop system
    self.maxBalls = 1
    self.multiplierBoostLevel = 0
    
    -- Reset power-ups
    for _, powerUp in pairs(self.powerUps) do
        powerUp.active = false
        powerUp.timer = 0
    end
    
    -- Reset combo
    self.combo.count = 0
    self.combo.timer = 0
    self.combo.multiplier = 1.0
    
    -- Reset stats
    self.stats = {
        totalPegsHit = 0,
        totalCoinsCollected = 0,
        powerUpsUsed = 0,
        explosionsTriggered = 0,
        maxCombo = 0,
        maxMultiplier = 1.0,
        perfectRounds = 0
    }
    
    -- Reset random events
    for _, event in pairs(self.randomEvents) do
        event.timer = 0
        event.lastEvent = 0
    end
    
    -- Reset visual effects
    self.screenShake.intensity = 0
    self.screenShake.duration = 0
    self.screenShake.offsetX = 0
    self.screenShake.offsetY = 0
    
    -- Reset gameplay state
    self.canDropBalls = true
    self.hoverPeg = false
    self.roundCompleteTimer = nil
    self.meterFlashTimer = 0
    self.lastBallCollisionPoints = nil
    self.lastBallCollisionTime = 0
    self.multiplierMeter = 0
    self.multiplier = 1.0
    self.rainbowShockwave = 0
    self.collisionCount = 0
    self.scoreGlowTimer = 0
    self.scoreScaleTimer = 0
    self.popperActivations = {}
    self.victoryTimer = 0
    self.wallHitTimer = nil
    self.goldPegPositions = nil
    self.bonusPegPositions = nil
    self.canAdvanceRound = false
    self.poppers = {}
    self.candyBought = {}
    self.pegsHitThisRound = 0
end

-- Reset round state
function gameState:resetRound()
    self.lives = config.START_LIVES
    self.balls = {}
    self.effects = {}
    self.particles = {}
    self.multiplierMeter = 0
    self.multiplier = 1.0
    self.canDropBalls = true
    self.collisionCount = 0
    self.pegsHitThisRound = 0
    
    -- Always ensure round state is initialized
    self:initializeRound()
    
    -- Reset power-ups
    for _, powerUp in pairs(self.powerUps) do
        powerUp.active = false
        powerUp.timer = 0
    end
    
    -- Reset combo
    self.combo.count = 0
    self.combo.timer = 0
    self.combo.multiplier = 1.0
    
    -- Reset screen shake
    self.screenShake.intensity = 0
    self.screenShake.duration = 0
    self.screenShake.offsetX = 0
    self.screenShake.offsetY = 0
    if self.candyBought == nil then self.candyBought = {} end
end

return gameState 