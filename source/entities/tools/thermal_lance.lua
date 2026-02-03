-- Thermal Lance Tool
-- Heat beam that deals thermal damage

class('ThermalLance').extends(Tool)

-- Thermal Lance data
ThermalLance.DATA = {
    id = "thermal_lance",
    name = "Thermal Lance",
    description = "Heat beam. Dmg: 5",
    imagePath = "images/tools/tool_thermal_lance",
    iconPath = "images/tools/tool_thermal_lance",
    projectileImage = "images/tools/tool_thermal_beam",

    -- Base stats
    baseDamage = 5,
    fireRate = 0.4,         -- Slower fire rate
    projectileSpeed = 0,    -- Instant beam
    pattern = "beam",
    damageType = "thermal",

    -- Upgrade info
    pairsWithBonus = "cooling_vents",
    upgradedName = "Plasma Cutter",
    upgradedImagePath = "images/tools/tool_plasma_cutter",
    upgradedProjectileImage = "images/tools/tool_plasma_cutter_beam",
    upgradedDamage = 12,
}

function ThermalLance:init()
    ThermalLance.super.init(self, ThermalLance.DATA)

    -- Beam-specific properties
    self.beamLength = 150
    self.beamWidth = 4
end

function ThermalLance:fire()
    -- Get firing angle from station
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Get firing position
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Create beam projectile
    self:createBeam(fireX, fireY, firingAngle)

    -- Play sound
    -- TODO: AudioManager:playSFX("tool_thermal_lance")
end

function ThermalLance:createBeam(x, y, angle)
    if GameplayScene and GameplayScene.createProjectile then
        -- For beam, we create a fast projectile that represents the beam
        -- The beam travels instantly to hit enemies
        local projectile = GameplayScene:createProjectile(
            x, y, angle,
            20,  -- Very fast (effectively instant)
            self.damage,
            self.data.projectileImage,
            true  -- Piercing - beams go through enemies
        )
        return projectile
    end
end

function ThermalLance:upgrade(bonusItem)
    local success = ThermalLance.super.upgrade(self, bonusItem)
    if success then
        -- Increase beam length on upgrade
        self.beamLength = 200
        self.beamWidth = 6
    end
    return success
end
