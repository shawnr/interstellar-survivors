-- MOB Base Class
-- Enemies that attack the station

local gfx <const> = playdate.graphics

class('MOB').extends(Entity)

function MOB:init(x, y, mobData, waveMultipliers)
    -- Debug: Log what MOB is being created
    print("Creating MOB: " .. (mobData.id or "unknown"))
    print("  Image path: " .. (mobData.imagePath or "nil"))

    MOB.super.init(self, x, y, mobData.imagePath)

    -- Debug: Verify the image was set correctly
    local img = self:getImage()
    if img then
        local imgW, imgH = img:getSize()
        print("  Verified sprite image: " .. imgW .. "x" .. imgH .. ", ID: " .. tostring(img))
    else
        print("  WARNING: Sprite has no image after init!")
    end

    -- Store data
    self.data = mobData
    self.mobType = mobData.id or "unknown"

    -- Apply wave multipliers
    waveMultipliers = waveMultipliers or { health = 1, damage = 1, speed = 1 }

    -- Stats
    self.health = mobData.baseHealth * waveMultipliers.health
    self.maxHealth = self.health
    self.damage = mobData.baseDamage * waveMultipliers.damage
    self.speed = mobData.baseSpeed * waveMultipliers.speed
    self.rpValue = mobData.rpValue or 5
    self.range = mobData.range or 1
    self.emits = mobData.emits or false

    -- Movement
    self.targetX = Constants.STATION_CENTER_X
    self.targetY = Constants.STATION_CENTER_Y

    -- Health bar display
    self.showHealthBar = false
    self.healthBarTimer = 0

    -- Set center point FIRST
    self:setCenter(0.5, 0.5)

    -- Set collision rect
    local w = mobData.width or 16
    local h = mobData.height or 16
    self:setCollideRect(0, 0, w, h)

    -- Z-index (mobs behind projectiles)
    self:setZIndex(50)

    -- Now position properly
    self:moveTo(x, y)

    -- Add to sprite system
    self:add()
end

function MOB:update(dt)
    if not self.active then return end

    -- Don't update if game is paused/leveling up
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    dt = dt or (1/30)

    -- Update health bar timer
    if self.showHealthBar then
        self.healthBarTimer = self.healthBarTimer - dt
        if self.healthBarTimer <= 0 then
            self.showHealthBar = false
        end
    end

    -- Movement
    if self.emits then
        self:updateShooterMovement(dt)
    else
        self:updateRammerMovement(dt)
    end
end

-- Movement for ramming MOBs (straight line)
function MOB:updateRammerMovement(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 1 then
        -- Normalize and apply speed
        local moveX = (dx / dist) * self.speed
        local moveY = (dy / dist) * self.speed

        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)

        -- Rotate to face movement direction
        local angle = Utils.vectorToAngle(dx, dy)
        self:setRotation(angle)
    end
end

-- Movement for shooting MOBs (orbit at range)
function MOB:updateShooterMovement(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > self.range then
        -- Move closer
        local moveX = (dx / dist) * self.speed
        local moveY = (dy / dist) * self.speed

        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)
    else
        -- Orbit behavior
        local angle = math.atan(dy, dx)
        angle = angle + (self.speed * 0.02 * dt)

        self.x = self.targetX - math.cos(angle) * self.range
        self.y = self.targetY - math.sin(angle) * self.range
        self:moveTo(self.x, self.y)
    end

    -- Always face the station
    local angle = Utils.vectorToAngle(dx, dy)
    self:setRotation(angle)
end

-- Take damage
function MOB:takeDamage(amount, damageType)
    self.health = self.health - amount

    -- Show health bar
    self.showHealthBar = true
    self.healthBarTimer = Constants.HEALTH_BAR_SHOW_DURATION

    -- Check for death
    if self.health <= 0 then
        self:onDestroyed()
        return true
    end

    return false
end

-- Called when MOB is destroyed
function MOB:onDestroyed()
    self.active = false

    -- Play destroyed sound
    if AudioManager then
        AudioManager:playSFX("mob_destroyed", 0.5)
    end

    -- Spawn collectibles
    self:spawnCollectibles()

    -- Remove sprite
    self:remove()
end

-- Spawn collectibles at death location
function MOB:spawnCollectibles()
    if not GameplayScene then return end

    -- Spawn RP orbs based on rpValue
    -- Split into multiple smaller orbs for better feel
    local orbCount = math.max(1, math.floor(self.rpValue / 5))
    local valuePerOrb = self.rpValue / orbCount

    for i = 1, orbCount do
        -- Slight random offset for each orb
        local offsetX = (math.random() - 0.5) * 16
        local offsetY = (math.random() - 0.5) * 16

        local collectible = Collectible(
            self.x + offsetX,
            self.y + offsetY,
            Collectible.TYPES.RP,
            valuePerOrb
        )

        table.insert(GameplayScene.collectibles, collectible)
    end

    -- Small chance to drop health
    if math.random(100) <= 5 then  -- 5% chance
        local healthOrb = Collectible(
            self.x,
            self.y,
            Collectible.TYPES.HEALTH,
            5  -- Heal 5 HP
        )
        table.insert(GameplayScene.collectibles, healthOrb)
    end
end

-- Draw health bar (called from gameplay scene)
function MOB:drawHealthBar()
    if not self.showHealthBar or not self.active then return end

    local barWidth = 20
    local barHeight = 3
    local barX = self.x - barWidth / 2
    local barY = self.y - self:getRadius() - 6

    -- Background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(barX, barY, barWidth, barHeight)

    -- Fill
    local fillWidth = (self.health / self.maxHealth) * (barWidth - 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX + 1, barY + 1, fillWidth, barHeight - 2)
end

-- DEBUG: Draw MOB type label (for debugging sprite issues)
-- Set DEBUG_MOB_LABELS = true to enable
DEBUG_MOB_LABELS = false

function MOB:drawDebugLabel()
    if not DEBUG_MOB_LABELS or not self.active then return end

    -- Draw MOB type label below the sprite
    local label = self.mobType or "?"
    local labelY = self.y + self:getRadius() + 2

    -- Background for readability
    local textWidth = gfx.getTextSize(label)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.x - textWidth/2 - 2, labelY - 1, textWidth + 4, 10)

    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(label, self.x, labelY, kTextAlignment.center)
end

-- Get radius for collision
function MOB:getRadius()
    local w, h = self:getSize()
    return math.max(w, h) / 2
end

-- Check if MOB has reached the station
function MOB:hasReachedStation()
    local dist = Utils.distance(self.x, self.y, self.targetX, self.targetY)
    return dist < (Constants.STATION_RADIUS + self:getRadius())
end
