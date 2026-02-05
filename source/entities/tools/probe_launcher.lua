-- Probe Launcher Tool
-- Fires homing probes that deal damage over time

class('ProbeLauncher').extends(Tool)

ProbeLauncher.DATA = {
    id = "probe_launcher",
    name = "Probe Launcher",
    description = "Homing probes. Dmg: 1/tick",
    imagePath = "images/tools/tool_probe_launcher",
    iconPath = "images/tools/tool_probe_launcher",
    projectileImage = "images/tools/tool_probe",

    baseDamage = 5,
    fireRate = 0.8,
    projectileSpeed = 6,
    pattern = "homing",
    damageType = "analysis",

    pairsWithBonus = "probe_swarm",
    upgradedName = "Drone Carrier",
    upgradedImagePath = "images/tools/tool_drone_carrier",
    upgradedDamage = 12,
}

function ProbeLauncher:init()
    ProbeLauncher.super.init(self, ProbeLauncher.DATA)
    self.probesPerShot = 1
    self.extraProbes = 0
end

function ProbeLauncher:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Fire multiple probes
    local totalProbes = self.probesPerShot + self.extraProbes
    local spreadAngle = 10

    for i = 1, totalProbes do
        local angle = firingAngle + (i - 1 - (totalProbes - 1) / 2) * spreadAngle
        self:createProjectile(fireX, fireY, angle)
    end
end

function ProbeLauncher:upgrade(bonusItem)
    local success = ProbeLauncher.super.upgrade(self, bonusItem)
    if success then
        self.probesPerShot = 2
    end
    return success
end
