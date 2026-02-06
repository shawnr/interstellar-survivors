-- MOB Base Class
-- Enemies that attack the station

local gfx <const> = playdate.graphics

class('MOB').extends(Entity)

function MOB:init(x, y, mobData, waveMultipliers)
    MOB.super.init(self, x, y, mobData.imagePath)

    -- Store data
    self.data = mobData
    self.mobType = mobData.id or "unknown"

    -- Apply wave multipliers
    waveMultipliers = waveMultipliers or { health = 1, damage = 1, speed = 1 }

    -- Apply creative mode difficulty multiplier if enabled
    local difficultyMult = 1.0
    if SaveManager and SaveManager:getSetting("debugMode", false) then
        difficultyMult = SaveManager:getDebugSetting("difficultyMultiplier", 1.0)
    end

    -- Stats (apply both wave and difficulty multipliers to health/damage)
    self.health = mobData.baseHealth * waveMultipliers.health * difficultyMult
    self.maxHealth = self.health
    self.damage = mobData.baseDamage * waveMultipliers.damage * difficultyMult
    self.speed = mobData.baseSpeed * waveMultipliers.speed
    self.rpValue = mobData.rpValue or 5
    self.range = mobData.range or 1
    self.emits = mobData.emits or false
    self.skipRotation = mobData.skipRotation or false  -- Performance: skip setRotation calls

    -- Movement
    self.targetX = Constants.STATION_CENTER_X
    self.targetY = Constants.STATION_CENTER_Y

    -- Orbital movement for shooter MOBs
    self.orbitDirection = (math.random() > 0.5) and 1 or -1  -- Random CW or CCW
    self.orbitAngle = math.atan(y - Constants.STATION_CENTER_Y, x - Constants.STATION_CENTER_X)

    -- Evasion behavior
    self.evading = false
    self.evadeTimer = 0
    self.evadeDirection = 0

    -- Health bar display
    self.showHealthBar = false
    self.healthBarTimer = 0

    -- Animation support
    self.animImageTable = nil
    self.currentFrame = 1
    self.frameTime = 0
    self.frameDuration = mobData.frameDuration or 0.15  -- Default: 150ms per frame
    self.frameCount = 1

    -- Load animation if animPath is specified
    if mobData.animPath then
        self:loadAnimation(mobData.animPath)
    end

    -- Set center point FIRST
    self:setCenter(0.5, 0.5)

    -- Set collision rect
    local w = mobData.width or 16
    local h = mobData.height or 16
    self:setCollideRect(0, 0, w, h)

    -- Z-index (mobs behind projectiles)
    self:setZIndex(50)

    -- Cache radius for collision checks (use explicit mobData dimensions, not sprite size)
    -- This ensures collision works even if sprite fails to load
    local collisionW = mobData.width or 16
    local collisionH = mobData.height or 16
    self.cachedRadius = math.max(collisionW, collisionH) / 2

    -- Now position properly
    self:moveTo(x, y)

    -- Add to sprite system
    self:add()
end

-- Load animation from image table
function MOB:loadAnimation(animPath)
    local imageTable = gfx.imagetable.new(animPath)
    if imageTable then
        self.animImageTable = imageTable
        self.frameCount = imageTable:getLength()
        self.currentFrame = 1
        -- Set the first frame
        self:setImage(imageTable:getImage(1))
    end
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

    -- Update animation
    if self.animImageTable and self.frameCount > 1 then
        self:updateAnimation(dt)
    end

    -- Movement
    if self.emits then
        self:updateShooterMovement(dt)
    else
        self:updateRammerMovement(dt)
    end
end

-- Update animation frame
function MOB:updateAnimation(dt)
    self.frameTime = self.frameTime + dt

    if self.frameTime >= self.frameDuration then
        self.frameTime = self.frameTime - self.frameDuration
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > self.frameCount then
            self.currentFrame = 1
        end
        self:setImage(self.animImageTable:getImage(self.currentFrame))
    end
end

-- Movement for ramming MOBs (straight line)
function MOB:updateRammerMovement(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distSq = dx * dx + dy * dy

    if distSq > 1 then
        -- Normalize and apply speed (only sqrt when moving)
        local invDist = 1 / math.sqrt(distSq)
        local moveX = dx * invDist * self.speed
        local moveY = dy * invDist * self.speed

        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)

        -- Rotate to face movement direction (skip if flagged for performance)
        if not self.skipRotation then
            local angle = Utils.vectorToAngle(dx, dy)
            self:setRotation(angle)
        end
    end
end

-- Movement for shooting MOBs (orbit at range)
function MOB:updateShooterMovement(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distSq = dx * dx + dy * dy
    local rangeSq = self.range * self.range

    -- Handle evasion - temporarily move away from damage source
    if self.evading then
        self.evadeTimer = self.evadeTimer - dt
        if self.evadeTimer <= 0 then
            self.evading = false
            -- Update orbit angle to current position after evasion
            self.orbitAngle = math.atan(self.y - self.targetY, self.x - self.targetX)
        else
            -- Move away from damage source at double speed
            local evadeSpeed = self.speed * 2
            self.x = self.x + math.cos(self.evadeDirection) * evadeSpeed
            self.y = self.y + math.sin(self.evadeDirection) * evadeSpeed
            self:moveTo(self.x, self.y)
            -- Face the station while evading
            local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
            self:setRotation(faceAngle)
            return
        end
    end

    if distSq > rangeSq then
        -- Move closer (only sqrt when needed)
        local invDist = 1 / math.sqrt(distSq)
        local moveX = dx * invDist * self.speed
        local moveY = dy * invDist * self.speed

        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)
    else
        -- Active orbit behavior - circle around the station
        -- Speed based on MOB speed stat, faster than before
        local orbitSpeed = self.speed * 0.04 * self.orbitDirection
        self.orbitAngle = self.orbitAngle + orbitSpeed

        self.x = self.targetX + math.cos(self.orbitAngle) * self.range
        self.y = self.targetY + math.sin(self.orbitAngle) * self.range
        self:moveTo(self.x, self.y)
    end

    -- Always face the station
    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

-- Take damage
-- sourceX, sourceY: optional position of the damage source for evasion
function MOB:takeDamage(amount, damageType, sourceX, sourceY)
    self.health = self.health - amount

    -- Show health bar
    self.showHealthBar = true
    self.healthBarTimer = Constants.HEALTH_BAR_SHOW_DURATION

    -- Trigger evasion for shooter MOBs (if source position provided)
    if self.emits and sourceX and sourceY then
        self:startEvasion(sourceX, sourceY)
    end

    -- Check for death
    if self.health <= 0 then
        self:onDestroyed()
        return true
    end

    return false
end

-- Start evasion maneuver (move away from damage source)
function MOB:startEvasion(sourceX, sourceY)
    self.evading = true
    self.evadeTimer = 0.25  -- Evade for 0.25 seconds

    -- Calculate direction away from damage source
    local dx = self.x - sourceX
    local dy = self.y - sourceY

    if dx == 0 and dy == 0 then
        -- Random direction if directly on top
        self.evadeDirection = math.random() * math.pi * 2
    else
        self.evadeDirection = math.atan(dy, dx)
    end

    -- Sometimes reverse orbit direction when hit
    if math.random() > 0.6 then
        self.orbitDirection = -self.orbitDirection
    end
end

-- Called when MOB is destroyed
function MOB:onDestroyed()
    self.active = false

    -- Play destroyed sound
    if AudioManager then
        AudioManager:playSFX("mob_destroyed", 0.5)
    end

    -- Unlock in database
    if SaveManager and self.data and self.data.id then
        SaveManager:unlockDatabaseEntry("enemies", self.data.id)
    end

    -- Track kill for episode stats
    if GameplayScene and self.data and self.data.id then
        GameplayScene:trackMobKill(self.data.id)
    end

    -- Spawn collectibles
    self:spawnCollectibles()

    -- Remove sprite
    self:remove()
end

-- Spawn collectibles at death location
function MOB:spawnCollectibles()
    if not GameplayScene or not GameplayScene.collectiblePool then return end

    -- Spawn single RP orb with full value (optimized for performance)
    -- Station auto-collects orbs within pickup radius
    GameplayScene.collectiblePool:get(
        self.x,
        self.y,
        Collectible.TYPES.RP,
        self.rpValue
    )

    -- Small chance to drop health
    if math.random(100) <= 5 then  -- 5% chance
        GameplayScene.collectiblePool:get(
            self.x,
            self.y,
            Collectible.TYPES.HEALTH,
            5  -- Heal 5 HP
        )
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

-- Get radius for collision (cached for performance)
function MOB:getRadius()
    return self.cachedRadius or 8
end

-- Check if MOB has reached the station (uses squared distance for performance)
function MOB:hasReachedStation()
    local distSq = Utils.distanceSquared(self.x, self.y, self.targetX, self.targetY)
    local threshold = Constants.STATION_RADIUS + self:getRadius()
    return distSq < (threshold * threshold)
end
