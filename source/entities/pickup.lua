-- Pickup Entity
-- Random sci-fi themed collectibles that float through the playfield
-- Larger than RP orbs (16x16), awards HP and/or RP on collection
-- NOT in sprite system: drawn manually by GameplayScene for performance

local gfx <const> = playdate.graphics
local math_floor <const> = math.floor
local math_sqrt <const> = math.sqrt
local math_min <const> = math.min
local math_sin <const> = math.sin
local math_random <const> = math.random

class('Pickup').extends(gfx.sprite)

-- Visual draw functions for each variant (16x16 procedural retro-vector graphics)
local VISUAL_DRAW = {}

function VISUAL_DRAW.box(img, size)
    -- Rect outline + cross
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(1, 1, size - 2, size - 2)
    gfx.drawLine(1, 1, size - 2, size - 2)
    gfx.drawLine(size - 2, 1, 1, size - 2)
end

function VISUAL_DRAW.circle(img, size)
    -- Circle outline + center dot
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(half, half, half - 2)
    gfx.fillCircleAtPoint(half, half, 2)
end

function VISUAL_DRAW.diamond(img, size)
    -- Rotated square + inner dot
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(half, 1, size - 2, half)
    gfx.drawLine(size - 2, half, half, size - 2)
    gfx.drawLine(half, size - 2, 1, half)
    gfx.drawLine(1, half, half, 1)
    gfx.fillCircleAtPoint(half, half, 2)
end

function VISUAL_DRAW.crystal(img, size)
    -- Triangle + vertical line
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(half, 1, size - 2, size - 3)
    gfx.drawLine(size - 2, size - 3, 1, size - 3)
    gfx.drawLine(1, size - 3, half, 1)
    gfx.drawLine(half, 3, half, size - 5)
end

function VISUAL_DRAW.canister(img, size)
    -- Rect + horizontal lines
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(3, 1, size - 6, size - 2)
    gfx.drawLine(3, math_floor(size * 0.33), size - 4, math_floor(size * 0.33))
    gfx.drawLine(3, math_floor(size * 0.66), size - 4, math_floor(size * 0.66))
end

function VISUAL_DRAW.pod(img, size)
    -- Oval + circle
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.drawEllipseInRect(1, 3, size - 2, size - 6)
    gfx.fillCircleAtPoint(half, half, 3)
end

function Pickup:init(x, y, pickupData)
    Pickup.super.init(self)

    -- Properties
    self.data = pickupData
    self.active = true

    -- Position
    self.x = x
    self.y = y

    -- Movement: drift toward station (like collectibles but slower)
    self.speed = 0.3
    self.maxSpeed = 3
    self.passiveDrift = 0.05
    self.collectRadius = 55
    self.pickupRadius = 45
    self.collectRadiusSq = self.collectRadius * self.collectRadius
    self.pickupRadiusSq = self.pickupRadius * self.pickupRadius

    -- Animation
    self.bobOffset = math_random() * 6.283
    self.bobSpeed = 4
    self.bobAmount = 2
    self.age = 0
    self.lifetime = 45  -- 45 seconds (longer than RP orbs' 15s)

    -- Manual drawing data
    self.drawImage = nil
    self.drawVisible = true
    self.drawX = x
    self.drawY = y

    -- Create visual
    self:createVisual()
end

function Pickup:createVisual()
    local size = 16
    local img = gfx.image.new(size, size)

    gfx.pushContext(img)

    local drawFn = VISUAL_DRAW[self.data.visual]
    if drawFn then
        drawFn(img, size)
    else
        -- Fallback: simple circle
        VISUAL_DRAW.circle(img, size)
    end

    gfx.popContext()
    self.drawImage = img
end

function Pickup:update(dt)
    if not self.active then return end

    -- Don't update if game is paused/leveling up
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    dt = dt or (1/30)

    -- Age and lifetime
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self.active = false
        self.drawVisible = false
        return
    end

    -- Calculate distance to station
    local dx = Constants.STATION_CENTER_X - self.x
    local dy = Constants.STATION_CENTER_Y - self.y
    local distSq = dx * dx + dy * dy

    -- Check for pickup (auto-collect)
    if distSq < self.pickupRadiusSq then
        self:collect()
        return
    end

    -- Within collect radius: accelerate toward station
    if distSq < self.collectRadiusSq then
        if distSq > 1 then
            local dist = math_sqrt(distSq)
            local speedMult = 1 + (1 - dist / self.collectRadius) * 3
            local currentSpeed = math_min(self.speed * speedMult, self.maxSpeed)
            local invDist = 1 / dist
            self.x = self.x + dx * invDist * currentSpeed
            self.y = self.y + dy * invDist * currentSpeed
        end
    else
        -- Passive drift toward station (slow)
        if distSq > 1 then
            self.x = self.x + dx * 0.0005
            self.y = self.y + dy * 0.0005
        end
    end

    -- Bobbing animation
    local bob = math_sin(self.age * self.bobSpeed + self.bobOffset) * self.bobAmount
    self.drawX = self.x
    self.drawY = self.y + bob

    -- Fade out near end of lifetime (blink in last 3 seconds)
    if self.age > self.lifetime - 3 then
        self.drawVisible = math_floor(self.age * 8) % 2 == 0
    end
end

function Pickup:collect()
    if not self.active then return end

    self.active = false
    self.drawVisible = false

    -- Roll HP and RP amounts
    local hp = 0
    local rp = 0
    if self.data.hpMax > 0 then
        hp = math_random(self.data.hpMin, self.data.hpMax)
    end
    if self.data.rpMax > 0 then
        rp = math_random(self.data.rpMin, self.data.rpMax)
    end

    -- Apply effects
    if hp > 0 and GameplayScene and GameplayScene.station then
        GameplayScene.station:heal(hp)
    end
    if rp > 0 and GameManager then
        GameManager:awardRP(rp)
    end

    -- Build message: "Babel Fish Tank: +15 HP, +20 RP"
    local parts = { self.data.name .. ":" }
    if hp > 0 then parts[#parts + 1] = "+" .. hp .. " HP" end
    if rp > 0 then parts[#parts + 1] = "+" .. rp .. " RP" end
    if GameplayScene then
        GameplayScene:showMessage(table.concat(parts, " "), 2.5)
    end

    -- Play collect sound
    if AudioManager then
        AudioManager:playSFX("collectible_rare", 0.8)
    end
end

-- Pull toward a point (for tractor pulse)
function Pickup:pullToward(targetX, targetY, strength)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local distSq = dx * dx + dy * dy

    if distSq > 1 then
        local factor = strength / (distSq ^ 0.5)
        self.x = self.x + dx * factor
        self.y = self.y + dy * factor
    end
end

return Pickup
