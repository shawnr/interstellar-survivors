-- Tesla Coil Tool
-- Lightning that chains to multiple enemies

local gfx <const> = playdate.graphics

-- Shared onHit function for chain lightning (avoids per-projectile closure)
local function chainOnHit(self, hitTarget)
    self.hitTargets[hitTarget] = true

    if GameplayScene and GameplayScene.createLightningArc then
        GameplayScene:createLightningArc(self.sourceX, self.sourceY, hitTarget.x, hitTarget.y)
    end

    if self.chainsRemaining > 0 then
        self.chainsRemaining = self.chainsRemaining - 1

        local nextTarget = nil
        local nearestDistSq = self.chainRange * self.chainRange

        if GameplayScene and GameplayScene.getMobsNearPosition then
            local nearbyMobs = GameplayScene:getMobsNearPosition(hitTarget.x, hitTarget.y)
            local nearbyCount = #nearbyMobs
            for i = 1, nearbyCount do
                local mob = nearbyMobs[i]
                if mob.active and not self.hitTargets[mob] and not mob.electricImmune then
                    local distSq = Utils.distanceSquared(hitTarget.x, hitTarget.y, mob.x, mob.y)
                    if distSq < nearestDistSq then
                        nearestDistSq = distSq
                        nextTarget = mob
                    end
                end
            end
        end

        if nextTarget then
            local chainAngle = Utils.vectorToAngle(nextTarget.x - hitTarget.x, nextTarget.y - hitTarget.y)
            local chainOptions = { inverted = true, rotationOffset = -90, damageType = "electric" }
            local chainProj = GameplayScene:createProjectile(
                hitTarget.x, hitTarget.y, chainAngle,
                22,
                self.chainDamage * 0.85,
                "images/tools/tool_lightning_bolt",
                false,
                chainOptions
            )

            if chainProj then
                chainProj.chainTarget = nextTarget
                chainProj.chainsRemaining = self.chainsRemaining
                chainProj.chainRange = self.chainRange
                chainProj.chainDamage = self.chainDamage * 0.85
                chainProj.hitTargets = self.hitTargets
                chainProj.sourceX = hitTarget.x
                chainProj.sourceY = hitTarget.y
                chainProj.onHit = chainOnHit
            end
        end
    end

    self:deactivate()
end

class('TeslaCoil').extends(Tool)

TeslaCoil.DATA = {
    id = "tesla_coil",
    name = "Tesla Coil",
    description = "Chain lightning. Dmg: 8",
    imagePath = "images/tools/tool_tesla_coil",
    iconPath = "images/tools/tool_tesla_coil",
    projectileImage = "images/tools/tool_lightning_bolt",

    baseDamage = 8,
    fireRate = 0.8,
    projectileSpeed = 18,
    pattern = "chain",
    damageType = "electric",

    pairsWithBonus = "arc_capacitors",
    upgradedName = "Storm Generator",
    upgradedImagePath = "images/tools/tool_tesla_coil",
    upgradedProjectileImage = "images/tools/tool_storm_bolt",
    upgradedDamage = 16,
}

function TeslaCoil:init()
    TeslaCoil.super.init(self, TeslaCoil.DATA)
    self.chainTargets = 2  -- Base chains (hits initial + 2 more)
    self.extraChainTargets = 0  -- From arc capacitors
    self.chainRange = 70  -- Max distance to chain
end

function TeslaCoil:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Find nearest enemy
    local target = self:findNearestEnemy(fireX, fireY, firingAngle)

    if target then
        -- Fire lightning directly at target
        local targetAngle = Utils.vectorToAngle(target.x - fireX, target.y - fireY)
        self:createChainProjectile(fireX, fireY, targetAngle, target)
    else
        -- No target - fire in default direction
        self:createProjectile(fireX, fireY, firingAngle)
    end
end

-- Override createProjectile to use lightning bolt with correct rotation
function TeslaCoil:createProjectile(x, y, angle)
    if GameplayScene and GameplayScene.projectilePool then
        -- Lightning bolt sprite faces RIGHT, use default -90 offset
        local lightningOptions = { inverted = true, rotationOffset = -90, damageType = "electric" }
        local projectile = GameplayScene.projectilePool:get(
            x, y, angle,
            self.projectileSpeed * (1 + self.projectileSpeedBonus),
            self.damage,
            self.data.projectileImage,
            false,
            lightningOptions
        )
        return projectile
    end
end

function TeslaCoil:findNearestEnemy(fromX, fromY, preferredAngle)
    if not GameplayScene or not GameplayScene.getMobsNearPosition then
        return nil
    end

    local nearest = nil
    local nearestDistSq = 180 * 180  -- Max targeting range squared

    -- Use spatial grid for efficient targeting (only checks nearby cells)
    local nearbyMobs = GameplayScene:getMobsNearPosition(fromX, fromY)
    local mobCount = #nearbyMobs
    for i = 1, mobCount do
        local mob = nearbyMobs[i]
        if mob.active and not mob.electricImmune then
            local distSq = Utils.distanceSquared(fromX, fromY, mob.x, mob.y)
            if distSq < nearestDistSq then
                nearestDistSq = distSq
                nearest = mob
            end
        end
    end

    return nearest
end

function TeslaCoil:createChainProjectile(x, y, angle, target)
    -- Lightning bolt sprite faces RIGHT, use default -90 offset
    local lightningOptions = { inverted = true, rotationOffset = -90, damageType = "electric" }
    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        self.data.projectileImage,
        false,
        lightningOptions
    )

    if proj then
        proj.chainTarget = target
        proj.chainsRemaining = self.chainTargets + self.extraChainTargets
        proj.chainRange = self.chainRange
        proj.chainDamage = self.damage
        proj.hitTargets = {}  -- Track hit targets to avoid re-hitting
        proj.sourceX = x
        proj.sourceY = y

        -- Use shared function (avoids per-projectile closure creation)
        proj.onHit = chainOnHit
    end

    return proj
end

function TeslaCoil:upgrade(bonusItem)
    local success = TeslaCoil.super.upgrade(self, bonusItem)
    if success then
        self.chainTargets = 4  -- More chains when upgraded
        self.chainRange = 90   -- Longer chain range
    end
    return success
end

