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

    -- Tool stats from data (with research spec bonuses)
    local baseFireRate = toolData.fireRate or 1.0
    local baseDamage = toolData.baseDamage or 1

    -- Apply research spec bonuses
    local fireRateBonus = 0
    local damageBonus = 0
    if ResearchSpecSystem then
        fireRateBonus = ResearchSpecSystem:getFireRateBonus()
        damageBonus = ResearchSpecSystem:getDamageBonus()
    end

    self.damage = baseDamage * (1 + damageBonus)
    self.fireRate = baseFireRate * (1 + fireRateBonus)
    self.projectileSpeed = toolData.projectileSpeed or 10
    self.pattern = toolData.pattern or "straight"

    -- DEBUG: Log tool creation
    print("TOOL INIT: " .. toolData.id .. " | baseDmg=" .. baseDamage .. " specBonus=" .. damageBonus .. " -> damage=" .. self.damage)

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

    -- Calculate rotated offset
    local angle = Utils.degToRad(stationRotation)
    local cos = math.cos(angle)
    local sin = math.sin(angle)

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
        self.fireCooldown = self.fireInterval
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

    print("Tool evolved: " .. self.data.name .. " -> " .. (toolData.upgradedName or "Evolved"))
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

        -- Apply all bonuses: level + item bonus + spec bonus + global bonus
        self.damage = baseDamage * (1 + self.damageBonus + specDamageBonus + self.globalDamageBonus)

        -- DEBUG: Log damage calculation
        print("TOOL STATS: " .. self.data.id .. " Lv" .. self.level .. " | baseDmg=" .. baseDamage ..
              " itemBonus=" .. self.damageBonus .. " specBonus=" .. specDamageBonus ..
              " globalBonus=" .. self.globalDamageBonus .. " -> damage=" .. self.damage)

        -- Fire rate with bonuses
        self.fireRate = baseRate * (1 + self.fireRateBonus + specFireRateBonus)
        self.fireInterval = 1 / self.fireRate

        -- Range bonus (used by some tools)
        self.range = levelStats.range + (self.rangeBonus * levelStats.range)
    else
        -- Fallback to base calculation
        local baseDamage = self.isEvolved and (self.data.upgradedDamage or self.data.baseDamage) or self.data.baseDamage
        self.damage = baseDamage * (1 + self.damageBonus + specDamageBonus + self.globalDamageBonus)

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
