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
    fireRate = 0.5,
    projectileSpeed = 6,
    pattern = "cone",
    damageType = "none",

    pairsWithBonus = "magnetic_coils",
    upgradedName = "Gravity Well",
    upgradedImagePath = "images/tools/tool_gravity_well",
}

function TractorPulse:init()
    TractorPulse.super.init(self, TractorPulse.DATA)
    self.rangeBonus = 0
    self.pullRange = 80
end

function TractorPulse:fire()
    -- Tractor pulse affects collectibles in a cone
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Pull collectibles
    local pulled = self:pullCollectibles(firingAngle)

    -- Play sound if we pulled something
    if pulled and AudioManager then
        AudioManager:playSFX("tool_tractor_pulse", 0.4)
    end
end

function TractorPulse:pullCollectibles(firingAngle)
    if not GameplayScene or not GameplayScene.collectibles then return false end

    local range = self.pullRange * (1 + self.rangeBonus)
    local pullStrength = self.upgraded and 8 or 5
    local pulledAny = false

    -- Pull ALL collectibles within range (no cone restriction)
    for _, collectible in ipairs(GameplayScene.collectibles) do
        if collectible.active then
            local dx = collectible.x - Constants.STATION_CENTER_X
            local dy = collectible.y - Constants.STATION_CENTER_Y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Pull if within range
            if dist < range and dist > 15 then
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
        self.pullRange = 120
    end
    return success
end
