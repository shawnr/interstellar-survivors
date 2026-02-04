-- Station Entity
-- The player's space station that rotates with the crank

local gfx <const> = playdate.graphics

-- Pre-computed unit circle points for shield arc (performance optimization)
-- 25 points for 24 segments, representing normalized positions from 0 to 1
local SHIELD_UNIT_CIRCLE = {}
local SHIELD_SEGMENTS = 24
for i = 0, SHIELD_SEGMENTS do
    local t = i / SHIELD_SEGMENTS  -- 0 to 1
    SHIELD_UNIT_CIRCLE[i] = {
        cos = math.cos(t * math.pi),  -- Coverage is typically pi radians (half circle)
        sin = math.sin(t * math.pi)
    }
end

class('Station').extends(Entity)

function Station:init()
    -- Initialize base entity (without position yet)
    Station.super.init(self, 0, 0, "images/shared/station_base")

    -- Calculate max health with research spec bonuses and grant funding
    local baseHealth = Constants.STATION_BASE_HEALTH
    local healthBonus = 0
    local startingHealthBonus = 0
    local grantHealthBonus = 0

    if ResearchSpecSystem then
        healthBonus = ResearchSpecSystem:getStationHealthBonus()
        startingHealthBonus = ResearchSpecSystem:getStartingHealth()
    end

    -- Apply grant funding health bonus
    if SaveManager and GrantFundingData then
        local healthLevel = SaveManager:getGrantFundingLevel("health")
        if healthLevel > 0 then
            grantHealthBonus = GrantFundingData.getTotalBonus("health", healthLevel)
        end
    end

    -- Apply percentage bonuses and flat bonus
    self.maxHealth = math.floor(baseHealth * (1 + healthBonus + grantHealthBonus)) + startingHealthBonus
    self.health = self.maxHealth

    -- Rotation (controlled by crank)
    self.currentRotation = 0

    -- Tools attached to station
    self.tools = {}
    self.usedSlots = {}

    -- Damage state tracking
    self.damageState = 0  -- 0 = healthy, 1 = damaged, 2 = critical

    -- Debuff tracking
    self.rotationSlow = 1.0        -- Rotation speed multiplier (1.0 = normal)
    self.rotationSlowTimer = 0     -- Time remaining on slow effect
    self.fireRateSlow = 1.0        -- Fire rate multiplier (1.0 = normal)
    self.fireRateSlowTimer = 0     -- Time remaining on fire rate slow
    self.controlsInverted = false  -- Whether crank controls are inverted
    self.controlsInvertedTimer = 0 -- Time remaining on inverted controls

    -- Shield system (damage-based absorption)
    self.shieldLevel = 1                  -- Shield upgrade level (1-4)
    self.shieldDamageCapacity = 10        -- Max damage shield can absorb before depleting
    self.shieldCurrentCapacity = 10       -- Current remaining damage capacity
    self.shieldCooldown = 0               -- Current cooldown timer
    self.shieldBaseCooldown = 2.0         -- Base cooldown: 2s
    self.shieldCoverage = 0.25            -- Coverage (0.25 = quarter circle, 90 degrees)
    self.shieldProjectileBlock = 1.0      -- 100% of projectile damage blocked
    self.shieldRamBlock = 0.5             -- 50% of ram damage blocked at level 1
    self.shieldAngleOffset = 180          -- Shield is opposite the rail driver (slot 0)
    self.shieldOpacity = 1.0              -- Visual opacity (fades during cooldown)
    self:updateShieldStats()

    -- Shield flash effect (visual when shield absorbs hit)
    self.shieldFlashTimer = 0      -- Timer for shield activation flash
    self.shieldFlashAngle = 0      -- Angle where the shield was hit
    self.shieldFlashIntensity = 0  -- Intensity of flash (based on level)

    -- Health regeneration system
    self.healthRegen = 0           -- HP to regen per tick (set by bonus items)
    self.baseHealthRegen = 2.0     -- Base regen rate: 2 HP per tick
    self.healthRegenInterval = 4.0 -- Seconds between regen ticks
    self.healthRegenTimer = 0      -- Timer for next regen

    -- Set center point FIRST (0.5, 0.5 = center of sprite)
    self:setCenter(0.5, 0.5)

    -- Set up collision (circular)
    self:setCollideRect(0, 0, 64, 64)

    -- NOW position at screen center
    self.x = Constants.STATION_CENTER_X
    self.y = Constants.STATION_CENTER_Y
    self:moveTo(self.x, self.y)

    -- Set Z-index (station should be behind tools)
    self:setZIndex(100)

    -- Add to sprite system
    self:add()

    print("Station initialized at " .. self.x .. ", " .. self.y)
end

function Station:updateShieldStats()
    -- Shield stats by level:
    -- Level 1: 10 dmg capacity, 25% coverage, 2.0s cooldown, 100% projectile, 50% ram
    -- Level 2: 15 dmg capacity, 33% coverage, 1.6s cooldown, 100% projectile, 60% ram
    -- Level 3: 20 dmg capacity, 42% coverage, 1.2s cooldown, 100% projectile, 70% ram
    -- Level 4: 25 dmg capacity, 50% coverage, 0.8s cooldown, 100% projectile, 80% ram
    local level = self.shieldLevel

    local baseCapacity = 10 + (level - 1) * 5     -- 10, 15, 20, 25
    local baseCooldown = 2.0 - (level - 1) * 0.4  -- 2.0, 1.6, 1.2, 0.8

    -- Apply grant funding shield bonuses
    local capacityBonus = 0
    local cooldownReduction = 0
    if SaveManager and GrantFundingData then
        local shieldLevel = SaveManager:getGrantFundingLevel("shields")
        if shieldLevel > 0 then
            capacityBonus = GrantFundingData.getShieldCapacityBonus(shieldLevel)
            cooldownReduction = GrantFundingData.getShieldCooldownReduction(shieldLevel)
        end
    end

    self.shieldDamageCapacity = math.floor(baseCapacity * (1 + capacityBonus))
    self.shieldCurrentCapacity = self.shieldDamageCapacity
    self.shieldCoverage = 0.25 + (level - 1) * 0.083     -- 0.25, 0.33, 0.42, 0.50
    self.shieldBaseCooldown = baseCooldown * (1 - cooldownReduction)
    self.shieldProjectileBlock = 1.0                      -- Always 100% for projectiles
    self.shieldRamBlock = 0.5 + (level - 1) * 0.1        -- 0.5, 0.6, 0.7, 0.8
end

function Station:upgradeShield()
    if self.shieldLevel < 4 then
        self.shieldLevel = self.shieldLevel + 1
        self:updateShieldStats()
        print("Shield upgraded to level " .. self.shieldLevel)
        return true
    end
    return false
end

function Station:update()
    local dt = 1/30

    -- Update rotation slow timer
    if self.rotationSlowTimer > 0 then
        self.rotationSlowTimer = self.rotationSlowTimer - dt
        if self.rotationSlowTimer <= 0 then
            self.rotationSlow = 1.0  -- Reset to normal speed
        end
    end

    -- Update fire rate slow timer
    if self.fireRateSlowTimer > 0 then
        self.fireRateSlowTimer = self.fireRateSlowTimer - dt
        if self.fireRateSlowTimer <= 0 then
            self.fireRateSlow = 1.0  -- Reset to normal fire rate
        end
    end

    -- Update controls inverted timer
    if self.controlsInvertedTimer > 0 then
        self.controlsInvertedTimer = self.controlsInvertedTimer - dt
        if self.controlsInvertedTimer <= 0 then
            self.controlsInverted = false  -- Reset to normal controls
        end
    end

    -- Update shield cooldown and opacity
    if self.shieldCooldown > 0 then
        self.shieldCooldown = self.shieldCooldown - dt
        -- Fade opacity back in as cooldown progresses (0 at start, 1 when ready)
        self.shieldOpacity = 1.0 - (self.shieldCooldown / self.shieldBaseCooldown)
        if self.shieldCooldown <= 0 then
            self.shieldCooldown = 0
            self.shieldCurrentCapacity = self.shieldDamageCapacity  -- Regenerate shield
            self.shieldOpacity = 1.0
        end
    else
        self.shieldOpacity = 1.0
    end

    -- Update shield flash timer
    if self.shieldFlashTimer > 0 then
        self.shieldFlashTimer = self.shieldFlashTimer - dt
    end

    -- Health regeneration (base + bonus from items)
    local totalRegen = self.baseHealthRegen + (self.healthRegen or 0)
    if totalRegen > 0 and self.health < self.maxHealth then
        self.healthRegenTimer = self.healthRegenTimer + dt
        if self.healthRegenTimer >= self.healthRegenInterval then
            self.healthRegenTimer = 0
            self:heal(totalRegen)
        end
    end

    -- Get base rotation from input manager
    local baseRotation = InputManager:getRotation()

    -- Apply controls inverted effect (boss ability)
    if self.controlsInverted then
        -- Save pivot on first inverted frame so reflection is stable
        if not self.invertPivot then
            self.invertPivot = baseRotation
        end
        -- Reflect input around the fixed pivot point
        baseRotation = 2 * self.invertPivot - baseRotation
    else
        self.invertPivot = nil
    end

    -- Apply slow effect by interpolating slower toward target
    if self.rotationSlow < 1.0 then
        -- When slowed, don't follow input as quickly
        local slowedTarget = self.currentRotation + (baseRotation - self.currentRotation) * self.rotationSlow
        self.currentRotation = slowedTarget
    else
        self.currentRotation = baseRotation
    end

    -- Apply rotation to sprite
    self:setRotation(self.currentRotation)

    -- Cache trig values for tool position updates (optimization - calculate once, use for all 8 tools)
    local angle = Utils.degToRad(self.currentRotation)
    self.cachedCos = math.cos(angle)
    self.cachedSin = math.sin(angle)

    -- Update all attached tools
    for _, tool in ipairs(self.tools) do
        tool:updatePosition(self.currentRotation)
    end
end

-- Check if an attack angle is covered by the shield
function Station:isShieldCovering(attackAngle)
    if self.shieldCurrentCapacity <= 0 or self.shieldCooldown > 0 then
        return false
    end

    -- Shield center is opposite the rail driver (slot 0 faces the current rotation)
    local shieldCenter = (self.currentRotation + self.shieldAngleOffset) % 360

    -- Calculate the half-angle of coverage
    local halfCoverage = (self.shieldCoverage * 360) / 2

    -- Normalize attack angle
    attackAngle = attackAngle % 360

    -- Check if attack angle is within shield coverage
    local diff = math.abs(attackAngle - shieldCenter)
    if diff > 180 then
        diff = 360 - diff
    end

    return diff <= halfCoverage
end

-- Attach a tool to the station
function Station:attachTool(tool, slotIndex)
    -- Find next available slot if not specified
    if slotIndex == nil then
        slotIndex = self:getNextAvailableSlot()
    end

    if slotIndex == nil then
        print("No available slots for tool!")
        return false
    end

    if #self.tools >= Constants.MAX_EQUIPMENT then
        print("Maximum tools reached!")
        return false
    end

    -- Mark slot as used
    self.usedSlots[slotIndex] = true

    -- Configure tool with slot info
    tool.station = self
    tool.slotIndex = slotIndex
    tool.slotData = Constants.TOOL_SLOTS[slotIndex]

    -- Add tool to list
    table.insert(self.tools, tool)

    -- Position tool initially
    tool:updatePosition(self.currentRotation)

    -- Add tool to sprite system
    tool:add()

    print("Tool attached to slot " .. slotIndex)
    return true
end

-- Get next available slot
function Station:getNextAvailableSlot()
    for i = 0, Constants.STATION_SLOTS - 1 do
        if not self.usedSlots[i] then
            return i
        end
    end
    return nil
end

-- Take damage (with shield support)
-- damageType: "projectile" or "ram" (defaults to "ram" for backwards compatibility)
function Station:takeDamage(amount, attackAngle, damageType)
    damageType = damageType or "ram"

    -- Debug mode: station is invincible (check specific setting)
    if SaveManager and SaveManager:isDebugFeatureEnabled("stationInvincible") then
        return false
    end

    -- Check for dodge (research spec bonus)
    if ResearchSpecSystem then
        local dodgeChance = ResearchSpecSystem:getDodgeChance()
        if dodgeChance > 0 and math.random() < dodgeChance then
            return false
        end
    end

    -- Check shield coverage
    local shieldCenter = (self.currentRotation + self.shieldAngleOffset) % 360

    if attackAngle and self:isShieldCovering(attackAngle) then
        -- Calculate how much damage the shield blocks based on damage type
        local blockEffectiveness = damageType == "projectile" and self.shieldProjectileBlock or self.shieldRamBlock
        local damageToBlock = math.floor(amount * blockEffectiveness)
        local damageBlocked = math.min(damageToBlock, self.shieldCurrentCapacity)
        local damagePassthrough = amount - damageBlocked

        -- Reduce shield capacity
        self.shieldCurrentCapacity = self.shieldCurrentCapacity - damageBlocked

        -- Play shield hit sound
        if AudioManager then
            AudioManager:playSFX("shield_hit", 0.8)
        end

        -- Trigger shield flash effect (more likely and intense at higher levels)
        local flashChance = 0.3 + (self.shieldLevel - 1) * 0.1
        if math.random() < flashChance then
            self.shieldFlashTimer = 0.15 + (self.shieldLevel * 0.05)
            self.shieldFlashAngle = attackAngle
            self.shieldFlashIntensity = self.shieldLevel
        end

        -- Start cooldown if shield depleted
        if self.shieldCurrentCapacity <= 0 then
            self.shieldCooldown = self.shieldBaseCooldown
        end

        -- If no passthrough damage, shield fully absorbed the hit
        if damagePassthrough <= 0 then
            return false
        end

        -- Continue with passthrough damage
        amount = damagePassthrough
    end

    -- Apply damage reduction (from bonus items like Quantum Stabilizer)
    local damageReduction = self.damageReduction or 0
    local finalDamage = math.max(1, math.floor(amount * (1 - damageReduction)))

    self.health = math.max(0, self.health - finalDamage)

    -- Play hit sound
    if AudioManager then
        AudioManager:playSFX("station_hit", 0.7)
    end

    -- Update damage visual state
    local healthPercent = self.health / self.maxHealth

    if healthPercent <= 0.50 and self.damageState ~= 2 then
        self.damageState = 2
        local img = Utils.getCachedImage("images/shared/station_damaged_2")
        if img then self:setImage(img) end
    elseif healthPercent <= 0.75 and healthPercent > 0.50 and self.damageState ~= 1 then
        self.damageState = 1
        local img = Utils.getCachedImage("images/shared/station_damaged_1")
        if img then self:setImage(img) end
    end

    -- Check for destruction
    if self.health <= 0 then
        self:onDestroyed()
        return true
    end

    return false
end

-- Called when station is destroyed
function Station:onDestroyed()
    print("Station destroyed!")

    -- Play destruction sound
    if AudioManager then
        AudioManager:playSFX("station_destroyed", 1.0)
    end

    -- Trigger destruction sequence in gameplay scene (don't remove yet - animation handles that)
    if GameplayScene and GameplayScene.startStationDestroyedSequence then
        GameplayScene:startStationDestroyedSequence()
    else
        -- Fallback: immediate game over if scene method not available
        self:remove()
        if GameManager then
            GameManager:endEpisode(false)
        end
    end
end

-- Heal the station
function Station:heal(amount)
    self.health = math.min(self.maxHealth, self.health + amount)

    -- Update visual state if healed enough
    local healthPercent = self.health / self.maxHealth
    if healthPercent > 0.75 and self.damageState ~= 0 then
        self.damageState = 0
        local img = Utils.getCachedImage("images/shared/station_base")
        if img then self:setImage(img) end
    elseif healthPercent > 0.50 and self.damageState == 2 then
        self.damageState = 1
        local img = Utils.getCachedImage("images/shared/station_damaged_1")
        if img then self:setImage(img) end
    end
end

-- Get health percentage (0-1)
function Station:getHealthPercent()
    return self.health / self.maxHealth
end

-- Get shield percentage (0-1)
function Station:getShieldPercent()
    if self.shieldCooldown > 0 then
        return 0  -- Shield is recharging
    end
    return self.shieldCurrentCapacity / self.shieldDamageCapacity
end

-- Check if shield is active
function Station:isShieldActive()
    return self.shieldCurrentCapacity > 0 and self.shieldCooldown <= 0
end

-- Get shield cooldown percentage (0-1, 0 = ready)
function Station:getShieldCooldownPercent()
    if self.shieldBaseCooldown <= 0 then return 0 end
    return self.shieldCooldown / self.shieldBaseCooldown
end

-- Get current rotation
function Station:getRotation()
    return self.currentRotation
end

-- Get position of a specific slot (world coordinates)
function Station:getSlotPosition(slotIndex)
    local slotData = Constants.TOOL_SLOTS[slotIndex]
    if not slotData then return self.x, self.y end

    -- Calculate rotated position
    local angle = Utils.degToRad(self.currentRotation)
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    local rotatedX = slotData.x * cos - slotData.y * sin
    local rotatedY = slotData.x * sin + slotData.y * cos

    return self.x + rotatedX, self.y + rotatedY
end

-- Get firing angle for a specific slot (in game coordinate system where 0=up)
function Station:getSlotFiringAngle(slotIndex)
    local slotData = Constants.TOOL_SLOTS[slotIndex]
    if not slotData then return self.currentRotation end

    return self.currentRotation + slotData.angle
end

-- Draw shield effect (called from gameplay scene)
function Station:drawShield()
    -- Draw shield even during cooldown (with fade effect)
    -- Only skip if shield has no capacity (shouldn't happen normally)
    if self.shieldDamageCapacity <= 0 then return end

    local shieldCenter = (self.currentRotation + self.shieldAngleOffset) % 360
    local halfAngle = (self.shieldCoverage * 360) / 2
    local startAngle = shieldCenter - halfAngle - 90  -- -90 for Playdate coordinate system
    local endAngle = shieldCenter + halfAngle - 90
    local radius = Constants.STATION_RADIUS + 8

    -- Reset graphics state to ensure clean drawing
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw shield arc (white so visible on dark background)
    gfx.setColor(gfx.kColorWhite)

    -- Convert to radians
    local startRad = math.rad(startAngle)
    local endRad = math.rad(endAngle)

    -- Draw arc as line segments with opacity-based dithering
    -- More segments for smoother fade (24 segments)
    local segments = 24
    local angleStep = (endRad - startRad) / segments

    -- Line width: thicker when fully charged, thinner when fading in
    local lineWidth = 1 + math.floor(self.shieldOpacity * 2)  -- 1 to 3
    gfx.setLineWidth(lineWidth)

    -- Pre-calculate all arc points (25 points for 24 segments)
    -- This reduces conditional trig calculations and allows point reuse
    local points = {}
    local stationX, stationY = self.x, self.y
    for i = 0, segments do
        local angle = startRad + i * angleStep
        points[i] = {
            x = stationX + math.cos(angle) * radius,
            y = stationY + math.sin(angle) * radius
        }
    end

    -- Draw segments with dithering
    for i = 0, segments - 1 do
        -- Dithering: use a pseudo-random pattern based on segment index
        local dither = ((i * 7) % 8) / 8
        if self.shieldOpacity > dither then
            local p1, p2 = points[i], points[i + 1]
            gfx.drawLine(p1.x, p1.y, p2.x, p2.y)
        end
    end

    -- When in cooldown (opacity < 1), draw a small charging indicator at shield center
    if self.shieldOpacity < 1.0 and self.shieldOpacity > 0.1 then
        local centerRad = math.rad(shieldCenter - 90)
        local indicatorX = self.x + math.cos(centerRad) * (radius - 4)
        local indicatorY = self.y + math.sin(centerRad) * (radius - 4)
        -- Pulsing dot to show charging
        local pulseSize = 2 + math.floor(self.shieldOpacity * 2)
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(indicatorX, indicatorY, pulseSize)
    end

    gfx.setLineWidth(1)

    -- Draw shield flash effect if active
    if self.shieldFlashTimer > 0 then
        self:drawShieldFlash()
    end
end

-- Draw shield activation flash (burst effect when shield absorbs hit)
function Station:drawShieldFlash()
    local intensity = self.shieldFlashIntensity
    local flashAngle = self.shieldFlashAngle - 90  -- Adjust for Playdate coordinate system

    -- Convert to radians
    local centerRad = math.rad(flashAngle)

    -- Draw radiating lines from impact point
    -- More lines and longer at higher intensity
    local numLines = 3 + intensity * 2  -- 5, 7, 9, 11 lines
    local baseLength = 15 + intensity * 5  -- 20, 25, 30, 35 length
    local spread = 15 + intensity * 5  -- Degrees of spread

    local radius = Constants.STATION_RADIUS + 6
    local hitX = self.x + math.cos(centerRad) * radius
    local hitY = self.y + math.sin(centerRad) * radius

    gfx.setColor(gfx.kColorWhite)  -- White so visible on dark background
    gfx.setLineWidth(2)

    -- Draw radiating burst lines
    for i = 1, numLines do
        local angleOffset = (i - (numLines + 1) / 2) * (spread / numLines)
        local lineAngle = centerRad + math.rad(angleOffset)

        -- Vary length slightly for organic look
        local length = baseLength * (0.7 + math.random() * 0.6)

        local endX = hitX + math.cos(lineAngle) * length
        local endY = hitY + math.sin(lineAngle) * length

        gfx.drawLine(hitX, hitY, endX, endY)
    end

    -- At higher levels, add an arc flash
    if intensity >= 2 then
        local arcRadius = radius + 4
        local arcSpread = 20 + intensity * 10  -- Degrees
        local arcSegments = 4 + intensity

        gfx.setLineWidth(intensity)

        for i = 0, arcSegments - 1 do
            local a1 = centerRad - math.rad(arcSpread / 2) + (i / arcSegments) * math.rad(arcSpread)
            local a2 = centerRad - math.rad(arcSpread / 2) + ((i + 1) / arcSegments) * math.rad(arcSpread)
            local x1 = self.x + math.cos(a1) * arcRadius
            local y1 = self.y + math.sin(a1) * arcRadius
            local x2 = self.x + math.cos(a2) * arcRadius
            local y2 = self.y + math.sin(a2) * arcRadius
            gfx.drawLine(x1, y1, x2, y2)
        end
    end

    -- At max level, add a small circle at impact point
    if intensity >= 4 then
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(hitX, hitY, 4)
    end

    gfx.setLineWidth(1)
end
