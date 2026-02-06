-- Utility functions for Interstellar Survivors

local gfx <const> = playdate.graphics

Utils = {}

-- Fast trig lookup tables (performance: avoid expensive math.sin/cos on Playdate CPU)
-- 64 entries = 5.625° resolution, sufficient for orbit calculations
local TRIG_ENTRIES <const> = 64
local TWO_PI <const> = math.pi * 2
local TRIG_SCALE <const> = TRIG_ENTRIES / TWO_PI

Utils.SIN_TABLE = {}
Utils.COS_TABLE = {}
for _i = 0, TRIG_ENTRIES - 1 do
    local angle = (_i / TRIG_ENTRIES) * TWO_PI
    Utils.SIN_TABLE[_i] = math.sin(angle)
    Utils.COS_TABLE[_i] = math.cos(angle)
end

-- Fast sin/cos using lookup table (radians input)
function Utils.fastSin(radians)
    local idx = math.floor((radians % TWO_PI) * TRIG_SCALE) % TRIG_ENTRIES
    return Utils.SIN_TABLE[idx]
end

function Utils.fastCos(radians)
    local idx = math.floor((radians % TWO_PI) * TRIG_SCALE) % TRIG_ENTRIES
    return Utils.COS_TABLE[idx]
end

-- Image cache for performance (avoid repeated disk I/O)
Utils.imageCache = {}

function Utils.getCachedImage(path)
    if not Utils.imageCache[path] then
        Utils.imageCache[path] = gfx.image.new(path)
    end
    return Utils.imageCache[path]
end

function Utils.clearImageCache()
    Utils.imageCache = {}
    Utils.rotatedImageCache = {}
end

-- Pre-rendered rotated image cache (for tools that rotate frequently)
-- Uses 24 angles (15° increments) for smooth rotation without excessive memory
Utils.rotatedImageCache = {}
Utils.ROTATION_STEPS = 24  -- 360 / 24 = 15° per step

-- Get pre-cached rotated images for a given image path
-- Returns a table of 24 pre-rotated images indexed by angle step (0-23)
function Utils.getRotatedImages(path)
    if Utils.rotatedImageCache[path] then
        return Utils.rotatedImageCache[path]
    end

    -- Load the base image
    local baseImage = Utils.getCachedImage(path)
    if not baseImage then
        return nil
    end

    -- Pre-render rotated versions
    local rotatedImages = {}
    local angleStep = 360 / Utils.ROTATION_STEPS

    for i = 0, Utils.ROTATION_STEPS - 1 do
        local angle = i * angleStep
        rotatedImages[i] = baseImage:rotatedImage(angle)
    end

    Utils.rotatedImageCache[path] = rotatedImages
    return rotatedImages
end

-- Get the appropriate angle step index for a given angle
function Utils.getRotationStep(angle)
    -- Normalize angle to 0-360
    angle = angle % 360
    if angle < 0 then angle = angle + 360 end

    -- Calculate step (0-23)
    local angleStep = 360 / Utils.ROTATION_STEPS
    local step = math.floor((angle + angleStep / 2) / angleStep) % Utils.ROTATION_STEPS
    return step
end

-- Debug print (only outputs when Creative Mode is enabled)
-- Use this for development/debug logging that shouldn't clutter normal gameplay
Utils._debugModeCache = nil
Utils._debugModeCacheTime = 0

function Utils.debugPrint(...)
    -- Cache the debug mode check for 1 second to avoid repeated save manager calls
    local currentTime = playdate.getCurrentTimeMilliseconds()
    if Utils._debugModeCache == nil or (currentTime - Utils._debugModeCacheTime) > 1000 then
        Utils._debugModeCache = SaveManager and SaveManager:getSetting("debugMode", false)
        Utils._debugModeCacheTime = currentTime
    end

    if Utils._debugModeCache then
        print(...)
    end
end

-- Linear interpolation
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Distance squared (faster, good for comparisons)
function Utils.distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

-- Normalize an angle to 0-360 range
function Utils.normalizeAngle(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

-- Convert degrees to radians
function Utils.degToRad(degrees)
    return degrees * (math.pi / 180)
end

-- Convert radians to degrees
function Utils.radToDeg(radians)
    return radians * (180 / math.pi)
end

-- Get direction vector from angle (in degrees)
function Utils.angleToVector(angleDegrees)
    local rad = Utils.degToRad(angleDegrees)
    return math.sin(rad), -math.cos(rad)
end

-- Get angle from direction vector (returns degrees)
function Utils.vectorToAngle(dx, dy)
    return Utils.radToDeg(math.atan(dx, -dy))
end

-- Check if a point is within screen bounds
function Utils.isOnScreen(x, y, margin)
    margin = margin or 0
    return x >= -margin and x <= Constants.SCREEN_WIDTH + margin
       and y >= -margin and y <= Constants.SCREEN_HEIGHT + margin
end

-- Calculate XP required for a level
-- Formula: BASE_XP × (LEVEL^EXPONENT - 1)
function Utils.xpForLevel(level)
    if level <= 1 then return 0 end
    return math.floor(Constants.BASE_XP * (math.pow(level, Constants.BASE_LEVEL_EXPONENT) - 1))
end

-- Calculate XP needed to go from current level to next
function Utils.xpToNextLevel(currentLevel)
    return Utils.xpForLevel(currentLevel + 1) - Utils.xpForLevel(currentLevel)
end

-- Random point on screen edge (for spawning)
function Utils.randomEdgePoint(margin)
    margin = margin or 20
    local edge = math.random(4)
    local x, y

    if edge == 1 then      -- Top
        x = math.random(0, Constants.SCREEN_WIDTH)
        y = -margin
    elseif edge == 2 then  -- Right
        x = Constants.SCREEN_WIDTH + margin
        y = math.random(0, Constants.SCREEN_HEIGHT)
    elseif edge == 3 then  -- Bottom
        x = math.random(0, Constants.SCREEN_WIDTH)
        y = Constants.SCREEN_HEIGHT + margin
    else                   -- Left
        x = -margin
        y = math.random(0, Constants.SCREEN_HEIGHT)
    end

    return x, y
end

-- Format time as M:SS
function Utils.formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- AABB collision check
function Utils.aabbOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

-- Circle collision check
function Utils.circleOverlap(x1, y1, r1, x2, y2, r2)
    local distSq = Utils.distanceSquared(x1, y1, x2, y2)
    local radiusSum = r1 + r2
    return distSq < radiusSum * radiusSum
end

-- Circle vs AABB collision
function Utils.circleRectOverlap(cx, cy, radius, rx, ry, rw, rh)
    -- Find closest point on rectangle to circle center
    local closestX = Utils.clamp(cx, rx, rx + rw)
    local closestY = Utils.clamp(cy, ry, ry + rh)

    -- Check if closest point is within circle
    local distSq = Utils.distanceSquared(cx, cy, closestX, closestY)
    return distSq < radius * radius
end

return Utils
