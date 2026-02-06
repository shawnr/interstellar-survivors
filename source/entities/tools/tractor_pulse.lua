-- Tractor Pulse Tool
-- Pulls collectibles toward station (no damage)

class('TractorPulse').extends(Tool)

TractorPulse.DATA = {
    id = "tractor_pulse",
    name = "Tractor Pulse",
    description = "Pulls collectibles. No dmg",
    imagePath = "images/tools/tool_tractor_pulse",
    iconPath = "images/tools/tool_tractor_pulse",
    projectileImage = "images/tools/tool_tractor_effect",

    baseDamage = 0,
    fireRate = 0.8,
    projectileSpeed = 8,
    pattern = "cone",
    damageType = "none",

    pairsWithBonus = "magnetic_coils",
    upgradedName = "Gravity Well",
    upgradedImagePath = "images/tools/tool_gravity_well",
}

function TractorPulse:init()
    TractorPulse.super.init(self, TractorPulse.DATA)
    self.rangeBonus = 0
    self.pullRange = 120  -- Increased for better collection coverage
end

function TractorPulse:fire()
    -- Tractor pulse affects collectibles in a cone
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Pull collectibles
    local pulled = self:pullCollectibles(firingAngle)

    -- Create visual effect: ring expanding outward to show pull range
    local range = self.pullRange * (1 + self.rangeBonus)
    if GameplayScene and GameplayScene.createPulseEffect then
        GameplayScene:createPulseEffect(
            Constants.STATION_CENTER_X,
            Constants.STATION_CENTER_Y,
            range,
            0.3,  -- Duration in seconds
            "tractor"  -- Effect type
        )
    end

    -- Play sound (always play to show it fired)
    if AudioManager then
        AudioManager:playSFX("tool_tractor_pulse", 0.4)
    end
end

function TractorPulse:pullCollectibles(firingAngle)
    if not GameplayScene or not GameplayScene.collectibles then return false end

    local range = self.pullRange * (1 + self.rangeBonus)
    local rangeSq = range * range
    local minDistSq = 15 * 15  -- Minimum distance squared
    local pullStrength = self.upgraded and 12 or 8  -- Faster pull for quicker collection
    local pulledAny = false

    -- Pull ALL collectibles within range (no cone restriction)
    for _, collectible in ipairs(GameplayScene.collectibles) do
        if collectible.active then
            local dx = collectible.x - Constants.STATION_CENTER_X
            local dy = collectible.y - Constants.STATION_CENTER_Y
            local distSq = dx * dx + dy * dy

            -- Pull if within range (use squared distance for performance)
            if distSq < rangeSq and distSq > minDistSq then
                collectible:pullToward(Constants.STATION_CENTER_X, Constants.STATION_CENTER_Y, pullStrength)
                pulledAny = true
            end
        end
    end

    return pulledAny
end

function TractorPulse:upgrade(bonusItem)
    local success = TractorPulse.super.upgrade(self, bonusItem)
    if success then
        self.pullRange = 180  -- Covers most of screen when upgraded
    end
    return success
end
