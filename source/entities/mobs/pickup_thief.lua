-- Pickup Thief MOB
-- Organic creature that spawns when a pickup appears and races to eat it.
-- Immune to electrical damage (EMP Burst, Tesla Coil).
-- Rotates through a pool of named variants with different visual shapes.

local gfx <const> = playdate.graphics
local math_floor <const> = math.floor
local math_sqrt <const> = math.sqrt
local math_random <const> = math.random
local math_abs <const> = math.abs

class('PickupThief').extends(MOB)

-- Pool of thief variants: name + visual shape
PickupThief.VARIANTS = {
    { name = "Space Herpes", visual = "blob" },
    { name = "Protomolecule Glob", visual = "blob" },
    { name = "Langolier", visual = "maw" },
    { name = "Blob Fragment", visual = "blob" },
    { name = "Mynock", visual = "wing" },
    { name = "Nibbler Spawn", visual = "bug" },
    { name = "Tribble Mutant", visual = "blob" },
    { name = "Mogwai", visual = "bug" },
    { name = "Cargo Gremlin", visual = "bug" },
    { name = "Loot Leech", visual = "worm" },
    { name = "Plunder Bug", visual = "bug" },
    { name = "Space Scavenger", visual = "maw" },
    { name = "Metroid Larva", visual = "blob" },
    { name = "Headcrab", visual = "bug" },
    { name = "Flood Spore", visual = "blob" },
    { name = "Ohmu Larva", visual = "worm" },
    { name = "Ceti Eel", visual = "worm" },
    { name = "Dianoga", visual = "maw" },
    { name = "Graboid Spawn", visual = "worm" },
    { name = "Brainslug", visual = "worm" },
}

-- Visual draw functions (18x18 procedural retro-vector, 5 variants)
local VISUAL_DRAW = {}

function VISUAL_DRAW.blob(img, size)
    -- Blobby amoeba shape
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(half, half, 7)
    gfx.fillCircleAtPoint(half + 3, half - 2, 4)
    gfx.fillCircleAtPoint(half - 2, half + 3, 4)
    -- Eye
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half - 2, half - 2, 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(half - 3, half - 3, 1)
end

function VISUAL_DRAW.bug(img, size)
    -- Insectoid with legs
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Body
    gfx.fillEllipseInRect(4, 5, 10, 8)
    -- Head
    gfx.fillCircleAtPoint(half + 4, half, 3)
    -- Legs (3 pairs)
    gfx.drawLine(5, 7, 2, 3)
    gfx.drawLine(8, 7, 6, 2)
    gfx.drawLine(5, 12, 2, 15)
    gfx.drawLine(8, 12, 6, 16)
    gfx.drawLine(11, 9, 14, 6)
    gfx.drawLine(11, 10, 14, 13)
    -- Eye
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half + 4, half, 1)
end

function VISUAL_DRAW.worm(img, size)
    -- Segmented worm/leech
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Body segments (3 overlapping circles)
    gfx.fillCircleAtPoint(5, half, 4)
    gfx.fillCircleAtPoint(9, half, 4)
    gfx.fillCircleAtPoint(13, half, 3)
    -- Mouth
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(15, half, 2)
    -- Segment lines
    gfx.drawLine(7, half - 4, 7, half + 4)
    gfx.drawLine(11, half - 3, 11, half + 3)
end

function VISUAL_DRAW.maw(img, size)
    -- All mouth creature
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Outer jaw
    gfx.fillCircleAtPoint(half, half, 7)
    -- Inner mouth (black)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half + 1, half, 5)
    -- Teeth (white dots around mouth)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(half + 4, half - 3, 1)
    gfx.fillCircleAtPoint(half + 5, half, 1)
    gfx.fillCircleAtPoint(half + 4, half + 3, 1)
    gfx.fillCircleAtPoint(half + 1, half - 5, 1)
    gfx.fillCircleAtPoint(half + 1, half + 5, 1)
end

function VISUAL_DRAW.wing(img, size)
    -- Bat-like/mynock creature
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Body
    gfx.fillCircleAtPoint(half, half, 4)
    -- Wings
    gfx.drawLine(half - 4, half, 1, half - 5)
    gfx.drawLine(1, half - 5, 1, half + 2)
    gfx.drawLine(1, half + 2, half - 4, half)
    gfx.drawLine(half + 4, half, size - 2, half - 5)
    gfx.drawLine(size - 2, half - 5, size - 2, half + 2)
    gfx.drawLine(size - 2, half + 2, half + 4, half)
    -- Eye
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half, half - 1, 1)
end

-- Pre-cache variant images (shared across all instances)
local VARIANT_IMAGE_CACHE = {}

local function getVariantImage(visual)
    if VARIANT_IMAGE_CACHE[visual] then
        return VARIANT_IMAGE_CACHE[visual]
    end
    local size = 18
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
    local drawFn = VISUAL_DRAW[visual]
    if drawFn then
        drawFn(img, size)
    else
        VISUAL_DRAW.blob(img, size)
    end
    gfx.popContext()
    VARIANT_IMAGE_CACHE[visual] = img
    return img
end

PickupThief.DATA = {
    id = "pickup_thief",
    name = "Pickup Thief",
    imagePath = nil,  -- Procedural graphic (no image file)
    baseHealth = 60,
    baseSpeed = 0.7,
    baseDamage = 0,
    rpValue = 15,
    width = 18,
    height = 18,
    range = 1,
    emits = true,  -- Prevents station collision destruction (thief targets pickups, not station)
    skipRotation = true,
    electricImmune = true,
}

function PickupThief:init(x, y, waveMultipliers, targetPickup)
    PickupThief.super.init(self, x, y, PickupThief.DATA, waveMultipliers)

    -- Pick a random variant
    local variant = PickupThief.VARIANTS[math_random(#PickupThief.VARIANTS)]
    self.variantName = variant.name
    self.variantVisual = variant.visual

    -- Set procedural image
    local img = getVariantImage(variant.visual)
    self.drawImage = img
    local iw, ih = img:getSize()
    self._drawHalfW = math_floor(iw / 2)
    self._drawHalfH = math_floor(ih / 2)

    -- Thief state
    self.targetPickup = targetPickup
    self.state = "chasing"  -- chasing, eating, fleeing
    self.eatingTimer = 0
    self.stolenPickupData = nil
    self.fleeAngle = 0
    self.baseSpeed = self.speed
end

function PickupThief:update(dt)
    if not self.active then return end

    -- Pause check
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Frame guard
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)

    -- Health bar timer
    if self.showHealthBar then
        self.healthBarTimer = self.healthBarTimer - dt
        if self.healthBarTimer <= 0 then
            self.showHealthBar = false
        end
    end

    local speedScale = dt * 30

    if self.state == "chasing" then
        self:updateChasing(speedScale)
    elseif self.state == "eating" then
        self:updateEating(dt)
    elseif self.state == "fleeing" then
        self:updateFleeing(speedScale)
    end
end

function PickupThief:updateChasing(speedScale)
    local pickup = self.targetPickup

    -- If pickup was collected or despawned, flee
    if not pickup or not pickup.active then
        self.state = "fleeing"
        self:calculateFleeAngle()
        return
    end

    -- Move toward pickup
    local dx = pickup.x - self.x
    local dy = pickup.y - self.y
    local distSq = dx * dx + dy * dy

    -- Reached pickup? Start eating
    if distSq < 15 * 15 then
        self.state = "eating"
        self.eatingTimer = 1.5
        return
    end

    -- Acceleration: speed up as we get closer (1x at 300px, 2x at 50px)
    local dist = math_sqrt(distSq)
    local accelMult = 1.0 + math.max(0, (300 - dist) / 300)
    local moveSpeed = self.baseSpeed * accelMult * speedScale

    -- Normalize and move
    local invDist = 1 / dist
    self.x = self.x + dx * invDist * moveSpeed
    self.y = self.y + dy * invDist * moveSpeed
end

function PickupThief:updateEating(dt)
    self.eatingTimer = self.eatingTimer - dt

    -- Blink the pickup while eating
    if self.targetPickup and self.targetPickup.active then
        self.targetPickup.drawVisible = math_floor(self.eatingTimer * 6) % 2 == 0
    end

    if self.eatingTimer <= 0 then
        -- Consume the pickup
        if self.targetPickup and self.targetPickup.active then
            self.stolenPickupData = self.targetPickup.data
            self.targetPickup.active = false
            self.targetPickup.drawVisible = false
        end

        -- Taunt message
        local pickupName = self.stolenPickupData and self.stolenPickupData.name or "pickup"
        if GameplayScene then
            GameplayScene:showMessage(self.variantName .. " stole your " .. pickupName .. "!", 2.5)
        end

        -- Food coma: 50% speed
        self.speed = self.baseSpeed * 0.5
        self.state = "fleeing"
        self:calculateFleeAngle()
    end
end

function PickupThief:updateFleeing(speedScale)
    -- Move toward nearest screen edge
    local moveSpeed = self.speed * speedScale
    local cos = math.cos(self.fleeAngle)
    local sin = math.sin(self.fleeAngle)
    self.x = self.x + cos * moveSpeed
    self.y = self.y + sin * moveSpeed

    -- Off-screen? Deactivate
    if self.x < -30 or self.x > Constants.SCREEN_WIDTH + 30 or
       self.y < -30 or self.y > Constants.SCREEN_HEIGHT + 30 then
        self.active = false
    end
end

function PickupThief:calculateFleeAngle()
    -- Flee toward the nearest screen edge
    local distLeft = self.x
    local distRight = Constants.SCREEN_WIDTH - self.x
    local distTop = self.y
    local distBottom = Constants.SCREEN_HEIGHT - self.y
    local minDist = math.min(distLeft, distRight, distTop, distBottom)

    if minDist == distLeft then
        self.fleeAngle = math.pi  -- Left
    elseif minDist == distRight then
        self.fleeAngle = 0  -- Right
    elseif minDist == distTop then
        self.fleeAngle = -math.pi / 2  -- Up
    else
        self.fleeAngle = math.pi / 2  -- Down
    end
end

function PickupThief:onDestroyed()
    if self.state == "eating" or (self.state == "fleeing" and self.stolenPickupData) then
        -- Killed after eating: drop partial RP (50% of pickup's average RP)
        if self.stolenPickupData then
            local avgRp = math_floor((self.stolenPickupData.rpMin + self.stolenPickupData.rpMax) / 4)
            if avgRp > 0 and GameplayScene and GameplayScene.collectiblePool then
                GameplayScene.collectiblePool:get(self.x, self.y, Collectible.TYPES.RP, avgRp)
            end
        end

        -- If still eating, restore the pickup
        if self.state == "eating" and self.targetPickup then
            self.targetPickup.active = true
            self.targetPickup.drawVisible = true
        end
    end

    -- Standard MOB death (RP drop, sound, etc.)
    PickupThief.super.onDestroyed(self)
end
