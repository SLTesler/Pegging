-- config.lua
-- Game configuration and constants

local config = {
    -- Game states
    GAME_STATE = {
        MENU = 1,
        PLAYING = 2,
        SHOP = 3,
        GAME_OVER = 4,
        ROUND_TRANSITION = 5,
        PAUSED = 6
    },

    -- Display settings
    WIDTH = 1600,
    HEIGHT = 1200,
    PLAY_X = 280,
    PLAY_Y = 150,
    PLAY_WIDTH = 1000,
    PLAY_HEIGHT = 850,
    WALL_THICKNESS = 10,

    -- Game settings
    PEG_COUNT = 30,
    GOLD_PEG_COUNT = 2,
    BALL_COUNT = 1,
    START_LIVES = 5,
    START_BALLS = 5,
    ROUNDS = 30,
    START_GOAL = 150,
    PEG_RADIUS = 35 * 1.1,
    BALL_RADIUS = 35 * 1.1 * 0.72,

    -- Visual effects
    PARTICLE_LIMIT = 200,
    TRAIL_LENGTH = 15,
    EFFECT_DURATION = 1.0,
    PARTICLE_DURATION = 0.5,
    HIT_TIMER = 0.1,
    PEG_HIT_TIMER = 0.2,
    WALL_HIT_TIMER = 0.2,
    METER_FLASH_DURATION = 0.5,
    RAINBOW_SHOCKWAVE_DURATION = 1.0,
    SCORE_GLOW_DURATION = 1.0,

    -- Physics constants (moved from magic numbers)
    GRAVITY = 375,
    AIR_RESISTANCE = 0.900,
    BALL_SPEED = 750,
    SPREAD_ANGLE = 0.4,
    BOUNCE_EFFICIENCY = 2.83,
    WALL_BOUNCE = 1.03,
    PEG_BOUNCE_IMPULSE = 1.930,
    BALL_COLLISION_IMPULSE = 0.3,
    BALL_MASS = 0.69,
    BALL_RESTITUTION = 2.83,

    -- Scoring constants (standardized)
    SCORING = {
        -- Base scoring
        PEG_BASE_POINTS = 5,
        PEG_POINTS_SCALING = 1.15,
        GOLD_PEG_BASE = 5,
        BONUS_PEG_MULTIPLIER = 1.15,
        
        -- Wall and collision scoring
        WALL_BASE_POINTS = 2,
        BALL_COLLISION_BASE = 3,
        BALL_COLLISION_UPGRADED = 8,
        
        -- Popper effects
        BOUNCE_POPPER_POINTS = 10,
        GREEN_POPPER_POINTS = 30,
        RED_POPPER_POINTS = 50,
        BLUE_POPPER_POINTS = 100,
        WALL_POPPER_POINTS = 15,
        COMBO_POPPER_POINTS = 20,
        EXPLOSIVE_POPPER_POINTS = 50,
        CINCO_POPPER_POINTS = 250,
        BANANA_POPPER_POINTS = 250,
        AIRTIME_POPPER_POINTS = 15,
        
        -- Bonus effects
        DOUBLE_HIT_BASE = 3,
        COLLISION_BONUS_BASE = 5,
        RANDOM_EXPLOSION_BASE = 10,
        
        -- Multiplier system
        MULTIPLIER_METER_MAX = 10,
        SCORE_DOUBLE_MULTIPLIER = 2.0
    },

    -- Power-up settings
    POWER_UPS = {
        speedBoost = {duration = 5.0, multiplier = 1.5},
        giantBall = {duration = 8.0, sizeMultiplier = 2.0},
        magnetBall = {duration = 6.0, attractionRadius = 100},
        rainbowTrail = {duration = 10.0},
        explosionRadius = {duration = 12.0, radius = 150}
    },

    -- Combo settings
    COMBO = {
        maxTime = 2.0,
        maxMultiplier = 5.0,
        multiplierIncrement = 0.1
    },

    -- Random events
    RANDOM_EVENTS = {
        pegExplosion = {interval = 15.0},
        rainbowStorm = {interval = 25.0},
        gravityShift = {interval = 20.0}
    },

    -- Screen shake
    SCREEN_SHAKE = {
        pegHit = {intensity = 2, duration = 0.1},
        powerUp = {intensity = 3, duration = 0.3},
        explosion = {intensity = 5, duration = 0.5}
    },

    -- Colors (preserving original rainbow scheme)
    COLORS = {
        -- Rainbow color generation functions
        rainbow = function(hue)
            local r = 0.5 + 0.5 * math.sin(hue * math.pi * 2)
            local g = 0.5 + 0.5 * math.sin((hue + 0.33) * math.pi * 2)
            local b = 0.5 + 0.5 * math.sin((hue + 0.66) * math.pi * 2)
            return r, g, b
        end,
        
        -- Specific colors
        white = {1, 1, 1},
        black = {0, 0, 0},
        red = {1, 0, 0},
        green = {0, 1, 0},
        blue = {0, 0, 1},
        yellow = {1, 1, 0},
        orange = {1, 0.5, 0},
        purple = {0.5, 0, 1},
        gold = {1, 0.8, 0},
        pink = {1, 0.4, 0.8},
        cyan = {0, 1, 1},
        magenta = {1, 0, 1},
        
        -- UI colors
        uiBackground = {0, 0, 0, 0.7},
        buttonGreen = {0.2, 0.6, 0.2},
        buttonBlue = {0.2, 0.5, 0.8},
        buttonRed = {0.6, 0.2, 0.2},
        buttonGray = {0.4, 0.4, 0.4},
        
        -- Peg colors
        pegNormal = {0.1, 0.1, 0.3},
        pegHit = {0.3, 0.3, 0.6},
        pegBonus = {0.2, 0.1, 0.3},
        pegBonusHit = {0.4, 0.3, 0.5},
        pegRed = {0.6, 0.6, 0.6},
        pegGold = {1, 0.8, 0},
        
        -- Ball colors
        ballNormal = {0.9, 0.9, 0.9},
        ballHit = {1, 0.2, 0.2},
        ballExplosion = {1, 0.5, 0.2},
        
        -- Effect colors
        points = {1, 0, 0},
        wallPoints = {1, 1, 0},
        ballCollision = {0, 1, 0},
        coin = {1, 0.8, 0},
        bonus = {1, 0.5, 0},
        multiplier = {1, 0, 1},
        explosion = {1, 0.5, 0},
        rainbowStorm = {1, 0, 1},
        gravityShift = {0, 1, 1}
    }
}

return config 