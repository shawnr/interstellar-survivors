-- Repulsor Field Tool
-- Pushes enemies away (no damage)

class('RepulsorField').extends(Tool)

RepulsorField.DATA = {
    id = "repulsor_field",
    name = "Repulsor Field",
    description = "Pushes enemies. No dmg",
    imagePath = "images/tools/tool_repulsor_field",
    iconPath = "images/tools/tool_repulsor_field",
    projectileImage = "images/tools/tool_repulsor_wave",

    baseDamage = 3,
    fireRate = 0.4,
    projectileSpeed = 0,  -- Instant radial
    pattern = "radial",
    damageType = "force",

    pairsWithBonus = "field_amplifier",
    upgradedName = "Shockwave Generator",
    upgradedImagePath = "images/tools/tool_shockwave_gen",
}

function RepulsorField:init()
    RepulsorField.super.init(self, RepulsorField.DATA)
    self.pushForce = 3
    self.pushRadius = 50
    self.pushForceBonus = 0
end

function RepulsorField:fire()
    -- Push all nearby enemies away
    self:pushEnemies()

    -- Create visual effect (radial wave)
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local numWaves = 8
    local angleStep = 360 / numWaves

    for i = 1, numWaves do
        local angle = firingAngle + (i - 1) * angleStep
        local offsetDist = 12
        local dx, dy = Utils.angleToVector(angle)
        local fireX = self.x + dx * offsetDist
        local fireY = self.y + dy * offsetDist

        if GameplayScene and GameplayScene.createProjectile then
            GameplayScene:createProjectile(
                fireX, fireY, angle,
                6,
                0,  -- No damage, just visual
                self.data.projectileImage,
                true  -- Pass through
            )
        end
    end
end

function RepulsorField:pushEnemies()
    if not GameplayScene or not GameplayScene.mobs then return end

    local force = self.pushForce * (1 + self.pushForceBonus)

    for _, mob in ipairs(GameplayScene.mobs) do
        if mob.active then
            local dist = Utils.distance(self.x, self.y, mob.x, mob.y)
            if dist < self.pushRadius and dist > 0 then
                -- Calculate push direction (away from tool)
                local dx = (mob.x - self.x) / dist
                local dy = (mob.y - self.y) / dist

                -- Apply push (stronger when closer)
                local pushStrength = force * (1 - dist / self.pushRadius)
                mob.x = mob.x + dx * pushStrength * 10
                mob.y = mob.y + dy * pushStrength * 10
                mob:moveTo(mob.x, mob.y)
            end
        end
    end
end

function RepulsorField:upgrade(bonusItem)
    local success = RepulsorField.super.upgrade(self, bonusItem)
    if success then
        self.pushForce = 5
        self.pushRadius = 80
    end
    return success
end
