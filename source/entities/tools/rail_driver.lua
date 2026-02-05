-- Rail Driver Tool
-- Basic kinetic launcher that fires straight projectiles

class('RailDriver').extends(Tool)

-- Rail Driver data
RailDriver.DATA = {
    id = "rail_driver",
    name = "Rail Driver",
    description = "Kinetic launcher for breaking asteroids",
    imagePath = "images/tools/tool_rail_driver",
    iconPath = "images/tools/tool_rail_driver",
    projectileImage = "images/tools/tool_rail_driver_projectile",

    -- Base stats (synced with tools_data.lua)
    baseDamage = 8,
    fireRate = 2.0,
    projectileSpeed = 10,
    pattern = "straight",
    damageType = "physical",

    -- Upgrade info
    pairsWithBonus = "alloy_gears",
    upgradedName = "Rail Cannon",
    upgradedImagePath = "images/tools/tool_rail_cannon",
    upgradedProjectileImage = "images/tools/tool_rail_cannon_projectile",
    upgradedDamage = 20,
    upgradedSpeed = 12,
    piercing = true,       -- Upgraded version pierces through first target
}

function RailDriver:init()
    RailDriver.super.init(self, RailDriver.DATA)

    -- Rail Driver specific properties
    self.piercing = false
end

-- RailDriver uses the base Tool:fire() method
-- Override createProjectile to pass the piercing parameter
function RailDriver:createProjectile(x, y, angle)
    if GameplayScene and GameplayScene.projectilePool then
        local projectile = GameplayScene.projectilePool:get(
            x, y, angle,
            self.projectileSpeed * (1 + (self.projectileSpeedBonus or 0)),
            self.damage,
            self.data.projectileImage or "images/tools/tool_rail_driver_projectile",
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
