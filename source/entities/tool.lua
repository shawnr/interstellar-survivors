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

    -- Firing state
    self.fireCooldown = 0
    self.fireInterval = 1 / self.fireRate  -- Convert rate to interval

    -- Upgrade state
    self.upgraded = false
    self.isUpgraded = false  -- Alias for upgrade system
    self.bonusItem = nil

    -- Bonus modifiers (applied by upgrade system)
    self.damageBonus = 0
    self.fireRateBonus = 0
    self.accuracyBonus = 0

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
            self.projectileSpeed,
            self.damage,
            self.data.projectileImage or "images/tools/tool_rail_driver_projectile"
        )
        return projectile
    end
end

-- Upgrade the tool with a bonus item
function Tool:upgrade(bonusItem)
    if self.upgraded then return false end

    self.upgraded = true
    self.isUpgraded = true
    self.bonusItem = bonusItem

    -- Apply upgraded stats
    if self.data.upgradedDamage then
        self.damage = self.data.upgradedDamage
    end
    if self.data.upgradedFireRate then
        self.fireRate = self.data.upgradedFireRate
        self.fireInterval = 1 / self.fireRate
    end
    if self.data.upgradedSpeed then
        self.projectileSpeed = self.data.upgradedSpeed
    end

    -- Change to upgraded image
    if self.data.upgradedImagePath then
        local img = gfx.image.new(self.data.upgradedImagePath)
        if img then self:setImage(img) end
    end

    print("Tool upgraded: " .. self.data.name .. " -> " .. (self.data.upgradedName or "Upgraded"))
    return true
end

-- Check if tool can be upgraded
function Tool:canUpgrade()
    return not self.upgraded and self.data.pairsWithBonus ~= nil
end

-- Recalculate stats based on bonuses
function Tool:recalculateStats()
    -- Get research spec bonuses
    local specFireRateBonus = 0
    local specDamageBonus = 0
    if ResearchSpecSystem then
        specFireRateBonus = ResearchSpecSystem:getFireRateBonus()
        specDamageBonus = ResearchSpecSystem:getDamageBonus()
    end

    -- Base damage with bonuses (item bonus + spec bonus)
    local baseDamage = self.upgraded and (self.data.upgradedDamage or self.data.baseDamage) or self.data.baseDamage
    self.damage = baseDamage * (1 + self.damageBonus + specDamageBonus)

    -- Fire rate with bonuses (item bonus + spec bonus)
    local baseRate = self.upgraded and (self.data.upgradedFireRate or self.data.fireRate) or self.data.fireRate
    self.fireRate = baseRate * (1 + self.fireRateBonus + specFireRateBonus)
    self.fireInterval = 1 / self.fireRate
end

-- Get tool info for UI
function Tool:getInfo()
    return {
        name = self.upgraded and self.data.upgradedName or self.data.name,
        damage = self.damage,
        fireRate = self.fireRate,
        pattern = self.pattern,
        upgraded = self.upgraded
    }
end
