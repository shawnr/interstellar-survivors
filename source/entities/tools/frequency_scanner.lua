-- Frequency Scanner Tool
-- Disperses gas clouds with frequency damage

class('FrequencyScanner').extends(Tool)

FrequencyScanner.DATA = {
    id = "frequency_scanner",
    name = "Frequency Scanner",
    description = "Disperses gas clouds. Dmg: 4",
    imagePath = "images/tools/tool_frequency_scanner",
    iconPath = "images/tools/tool_frequency_scanner",
    projectileImage = "images/tools/tool_frequency_scanner_beam",

    baseDamage = 4,
    fireRate = 0.8,
    projectileSpeed = 12,
    pattern = "straight",
    damageType = "frequency",

    pairsWithBonus = "expanded_dish",
    upgradedName = "Harmonic Disruptor",
    upgradedImagePath = "images/tools/tool_harmonic_disruptor",
    upgradedDamage = 10,
}

function FrequencyScanner:init()
    FrequencyScanner.super.init(self, FrequencyScanner.DATA)
end

function FrequencyScanner:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    self:createProjectile(fireX, fireY, firingAngle)
end
