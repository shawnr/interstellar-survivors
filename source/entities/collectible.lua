-- Collectible Entity
-- Items dropped by MOBs that can be collected

local gfx <const> = playdate.graphics

class('Collectible').extends(gfx.sprite)

-- Collectible types
Collectible.TYPES = {
    RP = "rp",              -- Research Points (XP)
    HEALTH = "health",      -- Heals station
    MAGNET = "magnet",      -- Pulls all collectibles
}

function Collectible:init(x, y, collectibleType, value)
    Collectible.super.init(self)

    -- Properties
    self.collectibleType = collectibleType or Collectible.TYPES.RP
    self.value = value or 1
    self.active = true

    -- Position
    self.x = x
    self.y = y

    -- Movement
    self.speed = 0.5           -- Initial drift speed
    self.maxSpeed = 4          -- Max collection speed
    self.passiveDrift = 0.08   -- Very slow drift toward station (for RP)

    -- Apply collect range bonus from research specs
    local baseCollectRadius = 50
    local rangeBonus = 0
    if ResearchSpecSystem then
        rangeBonus = ResearchSpecSystem:getCollectRangeBonus()
    end
    self.collectRadius = baseCollectRadius * (1 + rangeBonus)
    self.pickupRadius = 20     -- Collected at this distance

    -- Animation
    self.bobOffset = math.random() * math.pi * 2  -- Random start phase
    self.bobSpeed = 5
    self.bobAmount = 2

    -- Lifetime (despawn after a while if not collected)
    self.lifetime = 15  -- seconds
    self.age = 0

    -- Create visual based on type
    self:createVisual()

    -- Set center and position
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(75)  -- Above mobs, below projectiles

    -- Add to sprite system
    self:add()
end

function Collectible:createVisual()
    -- Create a simple circle for now
    local size = 8
    local img = gfx.image.new(size, size)

    gfx.pushContext(img)
    gfx.setColor(gfx.kColorWhite)

    if self.collectibleType == Collectible.TYPES.RP then
        -- RP orb: filled circle with dot
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 1)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(size/2, size/2, 2)
    elseif self.collectibleType == Collectible.TYPES.HEALTH then
        -- Health: cross/plus shape
        gfx.fillRect(2, size/2 - 1, size - 4, 2)
        gfx.fillRect(size/2 - 1, 2, 2, size - 4)
    else
        -- Default: simple circle
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 1)
    end

    gfx.popContext()
    self:setImage(img)
end

function Collectible:update(dt)
    if not self.active then return end

    -- Don't update if game is paused/leveling up
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    dt = dt or (1/30)

    -- Age and check lifetime
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self:collect(false)  -- Despawn without effect
        return
    end

    -- Calculate distance to station
    local dx = Constants.STATION_CENTER_X - self.x
    local dy = Constants.STATION_CENTER_Y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Move toward station
    if dist > 1 then
        if dist < self.collectRadius then
            -- Within collect radius: accelerate toward station
            local speedMult = 1 + (1 - dist / self.collectRadius) * 3
            local currentSpeed = math.min(self.speed * speedMult, self.maxSpeed)
            self.x = self.x + (dx / dist) * currentSpeed
            self.y = self.y + (dy / dist) * currentSpeed
        elseif self.collectibleType == Collectible.TYPES.RP then
            -- RP collectibles: very slow passive drift toward station
            self.x = self.x + (dx / dist) * self.passiveDrift
            self.y = self.y + (dy / dist) * self.passiveDrift
        end
    end

    -- Bobbing animation
    local bob = math.sin(self.age * self.bobSpeed + self.bobOffset) * self.bobAmount
    self:moveTo(self.x, self.y + bob)

    -- Check for pickup
    if dist < self.pickupRadius then
        self:collect(true)
    end

    -- Fade out near end of lifetime
    if self.age > self.lifetime - 2 then
        -- Blink effect
        local blinkRate = 10
        if math.floor(self.age * blinkRate) % 2 == 0 then
            self:setVisible(true)
        else
            self:setVisible(false)
        end
    end
end

function Collectible:collect(applyEffect)
    if not self.active then return end

    self.active = false

    if applyEffect then
        -- Play collect sound
        if AudioManager then
            if self.collectibleType == Collectible.TYPES.HEALTH then
                AudioManager:playSFX("collectible_rare", 0.6)
            else
                AudioManager:playSFX("collectible_get", 0.3)
            end
        end

        if self.collectibleType == Collectible.TYPES.RP then
            -- Award RP
            if GameManager then
                GameManager:awardRP(self.value)
            end
        elseif self.collectibleType == Collectible.TYPES.HEALTH then
            -- Heal station
            if GameplayScene and GameplayScene.station then
                GameplayScene.station:heal(self.value)
            end
        end
    end

    -- Remove sprite
    self:remove()
end

-- Pull toward a point (for magnet effect)
function Collectible:pullToward(targetX, targetY, strength)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 1 then
        self.x = self.x + (dx / dist) * strength
        self.y = self.y + (dy / dist) * strength
    end
end

return Collectible
