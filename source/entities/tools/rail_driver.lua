-- Rail Driver Tool
-- Basic kinetic launcher that fires straight projectiles

class('RailDriver').extends(Tool)

-- Rail Driver data
RailDriver.DATA = {
    id = "rail_driver",
    name = "Rail Driver",
    description = "Kinetic launcher for breaking asteroids",
    imagePath = "images/tools/tool_rail_driver",
    projectileImage = "images/tools/tool_rail_driver_projectile",

    -- Base stats
    baseDamage = 3,
    fireRate = 1.5,        -- 1.5 shots per second
    projectileSpeed = 8,   -- Fast projectiles
    pattern = "straight",
    damageType = "physical",

    -- Upgrade info
    pairsWithBonus = "alloy_gears",
    upgradedName = "Rail Cannon",
    upgradedImagePath = "images/tools/tool_rail_cannon",
    upgradedDamage = 8,
    upgradedSpeed = 12,
    piercing = true,       -- Upgraded version pierces through first target
}

function RailDriver:init()
    RailDriver.super.init(self, RailDriver.DATA)

    -- Rail Driver specific properties
    self.piercing = false
end

function RailDriver:fire()
    -- Get firing angle from station
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Get firing position
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Create projectile
    self:createProjectile(fireX, fireY, firingAngle)

    -- Play sound
    -- TODO: AudioManager:playSFX("tool_rail_driver")
end

function RailDriver:createProjectile(x, y, angle)
    if GameplayScene and GameplayScene.createProjectile then
        local projectile = GameplayScene:createProjectile(
            x, y, angle,
            self.projectileSpeed,
            self.damage,
            self.data.projectileImage,
            self.piercing
        )
        return projectile
    end
end

function RailDriver:upgrade(bonusItem)
    local success = RailDriver.super.upgrade(self, bonusItem)
    if success then
        -- Enable piercing on upgrade
        self.piercing = true
    end
    return success
end
