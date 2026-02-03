-- Tool Base Class
-- Weapons/tools that attach to the station and fire automatically

local gfx <const> = playdate.graphics

class('Tool').extends(Entity)

function Tool:init(toolData)
    -- Store tool data
    self.data = toolData

    -- Initialize without position (will be set when attached)
    Tool.super.init(self, 0, 0, toolData.imagePath)

    -- Station reference (set when attached)
    self.station = nil
    self.slotIndex = nil
    self.slotData = nil

    -- Level system (1-4)
    self.level = 1

    -- Tool stats from data (with research spec bonuses and grant funding)
    local baseFireRate = toolData.fireRate or 1.0
    local baseDamage = toolData.baseDamage or 1

    -- Apply research spec bonuses
    local fireRateBonus = 0
    local damageBonus = 0
    if ResearchSpecSystem then
        fireRateBonus = ResearchSpecSystem:getFireRateBonus()
        damageBonus = ResearchSpecSystem:getDamageBonus()
    end

    -- Apply grant funding damage bonus
    local grantDamageBonus = 0
    if SaveManager and GrantFundingData then
        local damageLevel = SaveManager:getGrantFundingLevel("damage")
        if damageLevel > 0 then
            grantDamageBonus = GrantFundingData.getTotalBonus("damage", damageLevel)
        end
    end

    self.damage = baseDamage * (1 + damageBonus + grantDamageBonus)
    self.fireRate = baseFireRate * (1 + fireRateBonus)
    self.projectileSpeed = toolData.projectileSpeed or 10
    self.pattern = toolData.pattern or "straight"

    -- Firing state
    self.fireCooldown = 0
    self.fireInterval = 1 / self.fireRate  -- Convert rate to interval

    -- Evolution state (different from level upgrades)
    self.isEvolved = false
    self.bonusItem = nil

    -- Legacy upgrade flag (for backward compatibility)
    self.upgraded = false
    self.isUpgraded = false

    -- Bonus modifiers (applied by upgrade system)
    self.damageBonus = 0
    self.fireRateBonus = 0
    self.accuracyBonus = 0
    self.globalDamageBonus = 0
    self.projectileSpeedBonus = 0
    self.rangeBonus = 0

    -- Set center point for proper rotation
    self:setCenter(0.5, 0.5)

    -- Set Z-index (tools above station)
    self:setZIndex(150)
end

-- Update tool position based on station rotation
function Tool:updatePosition(stationRotation)
    if not self.station or not self.slotData then return end

    -- Use station's cached trig values (calculated once per frame, shared by all tools)
    local cos = self.station.cachedCos or math.cos(Utils.degToRad(stationRotation))
    local sin = self.station.cachedSin or math.sin(Utils.degToRad(stationRotation))

    local baseX = self.slotData.x
    local baseY = self.slotData.y

    local rotatedX = baseX * cos - baseY * sin
    local rotatedY = baseX * sin + baseY * cos

    -- Set position
    self.x = self.station.x + rotatedX
    self.y = self.station.y + rotatedY
    self:moveTo(self.x, self.y)

    -- Rotate tool sprite to face outward
    -- Tool sprites are drawn facing RIGHT (0°), but game uses 0°=UP coordinate system
    -- Offset by -90° to align sprite to face outward from station
    local toolAngle = stationRotation + self.slotData.angle - 90
    self:setRotation(toolAngle)
end

-- Update method called each frame
function Tool:update(dt)
    if not self.station then return end

    dt = dt or (1/30)

    -- Update fire cooldown
    self.fireCooldown = math.max(0, self.fireCooldown - dt)

    -- Fire if ready
    if self.fireCooldown <= 0 then
        self:fire()
        -- Apply fire rate slow from station (1.0 = normal, 0.5 = 50% slower so interval is 2x)
        local fireRateMult = self.station.fireRateSlow or 1.0
        -- Safety check: fireRateMult must be positive, default to 1.0 if invalid
        if fireRateMult <= 0 then
            fireRateMult = 1.0
            self.station.fireRateSlow = 1.0
        end
        self.fireCooldown = self.fireInterval / fireRateMult
    end
end

-- Fire the tool (override in specific tools)
function Tool:fire()
    -- Get firing angle
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Get firing position (slightly in front of tool)
    local offsetDist = 10
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Create projectile (override in subclass for different patterns)
    self:createProjectile(fireX, fireY, firingAngle)
end

-- Create a projectile (override for different patterns)
function Tool:createProjectile(x, y, angle)
    -- Default: single straight projectile
    if GameplayScene and GameplayScene.projectilePool then
        local projectile = GameplayScene.projectilePool:get(
            x, y, angle,
            self.projectileSpeed * (1 + self.projectileSpeedBonus),
            self.damage,
            self.data.projectileImage or "images/tools/tool_rail_driver_projectile"
        )
        return projectile
    end
end

-- Evolve the tool (called when both tool and matching bonus are at max level)
function Tool:evolve(toolData)
    if self.isEvolved then return false end

    self.isEvolved = true
    self.upgraded = true
    self.isUpgraded = true

    -- Apply evolved stats
    if toolData.upgradedDamage then
        self.damage = toolData.upgradedDamage
    end
    if toolData.upgradedFireRate then
        self.fireRate = toolData.upgradedFireRate
        self.fireInterval = 1 / self.fireRate
    end
    if toolData.upgradedSpeed then
        self.projectileSpeed = toolData.upgradedSpeed
    end

    -- Change to evolved image
    if toolData.upgradedImagePath then
        local img = gfx.image.new(toolData.upgradedImagePath)
        if img then self:setImage(img) end
    end

    -- Recalculate with new base stats
    self:recalculateStats()

    return true
end

-- Legacy upgrade method (for backward compatibility)
function Tool:upgrade(bonusItem)
    self.bonusItem = bonusItem
    return self:evolve(self.data)
end

-- Check if tool can be upgraded (level-wise)
function Tool:canLevelUp()
    return self.level < 4
end

-- Check if tool can evolve (max level + matching bonus)
function Tool:canEvolve()
    return not self.isEvolved and self.level >= 4 and self.data.pairsWithBonus ~= nil
end

-- Recalculate stats based on level and bonuses
function Tool:recalculateStats()
    -- Get research spec bonuses
    local specFireRateBonus = 0
    local specDamageBonus = 0
    if ResearchSpecSystem then
        specFireRateBonus = ResearchSpecSystem:getFireRateBonus()
        specDamageBonus = ResearchSpecSystem:getDamageBonus()
    end

    -- Get grant funding damage bonus
    local grantDamageBonus = 0
    if SaveManager and GrantFundingData then
        local damageLevel = SaveManager:getGrantFundingLevel("damage")
        if damageLevel > 0 then
            grantDamageBonus = GrantFundingData.getTotalBonus("damage", damageLevel)
        end
    end

    -- Get level-scaled stats from data
    local levelStats = ToolsData.getStatsAtLevel(self.data.id, self.level)
    if levelStats then
        -- Use evolved stats as base if evolved
        local baseDamage, baseRate
        if self.isEvolved and self.data.upgradedDamage then
            baseDamage = self.data.upgradedDamage
            baseRate = self.data.upgradedFireRate or self.data.fireRate
        else
            baseDamage = levelStats.damage
            baseRate = levelStats.fireRate
        end

        -- Apply all bonuses: level + item bonus + spec bonus + global bonus + grant funding
        self.damage = baseDamage * (1 + self.damageBonus + specDamageBonus + self.globalDamageBonus + grantDamageBonus)

        -- Fire rate with bonuses
        self.fireRate = baseRate * (1 + self.fireRateBonus + specFireRateBonus)
        self.fireInterval = 1 / self.fireRate

        -- Range bonus (used by some tools)
        self.range = levelStats.range + (self.rangeBonus * levelStats.range)
    else
        -- Fallback to base calculation
        local baseDamage = self.isEvolved and (self.data.upgradedDamage or self.data.baseDamage) or self.data.baseDamage
        self.damage = baseDamage * (1 + self.damageBonus + specDamageBonus + self.globalDamageBonus + grantDamageBonus)

        local baseRate = self.isEvolved and (self.data.upgradedFireRate or self.data.fireRate) or self.data.fireRate
        self.fireRate = baseRate * (1 + self.fireRateBonus + specFireRateBonus)
        self.fireInterval = 1 / self.fireRate
    end
end

-- Get tool info for UI
function Tool:getInfo()
    return {
        name = self.isEvolved and self.data.upgradedName or self.data.name,
        level = self.level,
        damage = self.damage,
        fireRate = self.fireRate,
        pattern = self.pattern,
        evolved = self.isEvolved
    }
end
