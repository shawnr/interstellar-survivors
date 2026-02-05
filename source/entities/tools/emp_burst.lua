-- EMP Burst Tool
-- Radial electric damage that disables mechs

class('EMPBurst').extends(Tool)

EMPBurst.DATA = {
    id = "emp_burst",
    name = "EMP Burst",
    description = "Disables mechs. Dmg: 2",
    imagePath = "images/tools/tool_emp_burst",
    iconPath = "images/tools/tool_emp_burst",
    projectileImage = "images/tools/tool_emp_effect",

    baseDamage = 6,
    fireRate = 0.5,
    projectileSpeed = 0,  -- Instant radial
    pattern = "radial",
    damageType = "electric",

    pairsWithBonus = "capacitor_bank",
    upgradedName = "Ion Storm",
    upgradedImagePath = "images/tools/tool_ion_storm",
    upgradedDamage = 15,
}

function EMPBurst:init()
    EMPBurst.super.init(self, EMPBurst.DATA)
    self.burstRadius = 60
    self.burstProjectiles = 8
end

function EMPBurst:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)

    -- Fire projectiles in all directions from the tool
    local angleStep = 360 / self.burstProjectiles

    for i = 1, self.burstProjectiles do
        local angle = firingAngle + (i - 1) * angleStep
        local offsetDist = 12
        local dx, dy = Utils.angleToVector(angle)
        local fireX = self.x + dx * offsetDist
        local fireY = self.y + dy * offsetDist

        if GameplayScene and GameplayScene.createProjectile then
            GameplayScene:createProjectile(
                fireX, fireY, angle,
                8,  -- Medium speed for radial
                self.damage,
                self.data.projectileImage,
                false
            )
        end
    end
end

function EMPBurst:upgrade(bonusItem)
    local success = EMPBurst.super.upgrade(self, bonusItem)
    if success then
        self.burstRadius = 90
        self.burstProjectiles = 12
    end
    return success
end
