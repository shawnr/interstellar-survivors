-- Game Constants
-- All values from the Interstellar Survivors design document

Constants = {
    -- Version info (keep in sync with pdxinfo)
    VERSION = "0.1.187",
    BUILD = 188,

    -- Screen dimensions
    SCREEN_WIDTH = 400,
    SCREEN_HEIGHT = 240,

    -- Station
    STATION_CENTER_X = 200,
    STATION_CENTER_Y = 120,
    STATION_BASE_HEALTH = 500,   -- Increased for better survivability
    STATION_RADIUS = 32,
    STATION_SLOTS = 8,

    -- Crank rotation
    ROTATION_RATIO = 1.0,           -- 360 crank = 360 station (1:1)
    ROTATION_SMOOTHING = 0.3,       -- Lerp factor for smooth rotation
    CRANK_DEAD_ZONE = 2,            -- Degrees of dead zone

    -- Gameplay
    -- Boss spawn time is controlled by debug mode setting:
    -- Debug ON: 120 seconds (2 min), Debug OFF: 420 seconds (7 min)
    MAX_EQUIPMENT = 8,  -- Combined limit for tools + bonus items

    -- XP/Leveling (lower values = faster early leveling)
    BASE_XP = 50,
    BASE_LEVEL_EXPONENT = 1.15,

    -- Collectibles
    COLLECTIBLE_DRIFT_SPEED = 0.5,  -- px/frame
    TRACTOR_PULL_SPEED = 3,         -- px/frame
    TRACTOR_UPGRADED_SPEED = 5,     -- px/frame
    STANDARD_COLLECTIBLE_RP = 10,
    RARE_COLLECTIBLE_RP = 25,
    RARE_COLLECTIBLE_CHANCE = 20,   -- percent

    -- MOB damage multiplier (global)
    MOB_DAMAGE_MULTIPLIER = 1,

    -- Wave spawn limits (for performance)
    MAX_ACTIVE_PROJECTILES = 50,
    MAX_ACTIVE_MOBS = 24,  -- Reduced from 30 for performance (mobs are tougher to compensate)

    -- UI positions
    RP_BAR_Y = 0,
    RP_BAR_HEIGHT = 2,
    BOSS_HEALTH_BAR_Y = 0,
    BOSS_HEALTH_BAR_WIDTH = 200,
    BOSS_HEALTH_BAR_HEIGHT = 6,

    -- Timing
    HEALTH_BAR_SHOW_DURATION = 0.5, -- seconds (reduced from 1.0 for performance)
    WAVE_INDICATOR_DURATION = 0.5,  -- seconds
    STARTING_MESSAGE_DURATION = 1.5,-- seconds
    BOSS_WARNING_TIME = 405,        -- 6:45 in seconds

    -- Tool slot positions (angle in degrees, offset from center)
    TOOL_SLOTS = {
        [0] = { angle = 0,   x = 0,   y = -32 },  -- Top
        [1] = { angle = 45,  x = 23,  y = -23 },  -- Top-right
        [2] = { angle = 90,  x = 32,  y = 0 },    -- Right
        [3] = { angle = 135, x = 23,  y = 23 },   -- Bottom-right
        [4] = { angle = 180, x = 0,   y = 32 },   -- Bottom
        [5] = { angle = 225, x = -23, y = 23 },   -- Bottom-left
        [6] = { angle = 270, x = -32, y = 0 },    -- Left
        [7] = { angle = 315, x = -23, y = -23 },  -- Top-left
    },

    -- Episode count
    TOTAL_EPISODES = 5,
    TOTAL_RESEARCH_SPECS = 8,

    -- UI Theme (terminal aesthetic)
    UI = {
        PANEL_MARGIN = 10,
        HEADER_HEIGHT = 30,
        FOOTER_HEIGHT = 24,
        ITEM_HEIGHT = 32,
        CARD_CORNER_RADIUS = 4,
        RULE_THICKNESS = 1,
    },
}

return Constants
