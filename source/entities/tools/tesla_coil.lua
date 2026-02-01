-- Tesla Coil Tool
-- Lightning that chains to multiple enemies

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
    projectileSpeed = 20,
    pattern = "chain",
    damageType = "electric",

    pairsWithBonus = "arc_capacitors",
    upgradedName = "Storm Generator",
    upgradedImagePath = "images/tools/tool_tesla_coil",
    upgradedDamage = 16,
}

function TeslaCoil:init()
    TeslaCoil.super.init(self, TeslaCoil.DATA)
    self.chainTargets = 2
    self.extraChainTargets = 0
    self.chainRange = 60  -- Max distance to chain
end

function TeslaCoil:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Find nearest enemy in firing direction
    local target = self:findNearestEnemy(fireX, fireY, firingAngle)

    if target then
        -- Fire at the target
        local targetAngle = Utils.vectorToAngle(target.x - fireX, target.y - fireY)
        local proj = self:createChainProjectile(fireX, fireY, targetAngle, target)
    else
        -- Fire in default direction
        self:createProjectile(fireX, fireY, firingAngle)
    end
end

function TeslaCoil:findNearestEnemy(fromX, fromY, preferredAngle)
    if not GameplayScene or not GameplayScene.mobs then
        return nil
    end

    local nearest = nil
    local nearestDist = 200  -- Max targeting range

    for _, mob in ipairs(GameplayScene.mobs) do
        if mob.active then
            local dist = Utils.distance(fromX, fromY, mob.x, mob.y)
            if dist < nearestDist then
                nearestDist = dist
                nearest = mob
            end
        end
    end

    return nearest
end

function TeslaCoil:createChainProjectile(x, y, angle, target)
    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        self.data.projectileImage,
        false
    )

    if proj then
        proj.chainTarget = target
        proj.chainsRemaining = self.chainTargets + self.extraChainTargets
        proj.chainRange = self.chainRange
        proj.chainDamage = self.damage
        proj.hitTargets = {}  -- Track hit targets to avoid re-hitting

        -- Override onHit for chain behavior
        proj.onHit = function(self, hitTarget)
            -- Mark target as hit
            self.hitTargets[hitTarget] = true

            -- Chain to next target if chains remaining
            if self.chainsRemaining > 0 then
                self.chainsRemaining = self.chainsRemaining - 1

                -- Find next nearest enemy (not already hit)
                local nextTarget = nil
                local nearestDist = self.chainRange

                if GameplayScene and GameplayScene.mobs then
                    for _, mob in ipairs(GameplayScene.mobs) do
                        if mob.active and not self.hitTargets[mob] then
                            local dist = Utils.distance(hitTarget.x, hitTarget.y, mob.x, mob.y)
                            if dist < nearestDist then
                                nearestDist = dist
                                nextTarget = mob
                            end
                        end
                    end
                end

                if nextTarget then
                    -- Create chain projectile to next target
                    local chainAngle = Utils.vectorToAngle(nextTarget.x - hitTarget.x, nextTarget.y - hitTarget.y)
                    local chainProj = GameplayScene:createProjectile(
                        hitTarget.x, hitTarget.y, chainAngle,
                        20,  -- Fast chain
                        self.chainDamage * 0.8,  -- Slightly reduced damage per chain
                        "images/tools/tool_lightning_bolt",
                        false
                    )

                    if chainProj then
                        chainProj.chainTarget = nextTarget
                        chainProj.chainsRemaining = self.chainsRemaining
                        chainProj.chainRange = self.chainRange
                        chainProj.chainDamage = self.chainDamage * 0.8
                        chainProj.hitTargets = self.hitTargets
                        chainProj.onHit = self.onHit  -- Copy chain behavior
                    end
                end
            end

            -- Deactivate this projectile
            self:deactivate()
        end
    end

    return proj
end

function TeslaCoil:upgrade(bonusItem)
    local success = TeslaCoil.super.upgrade(self, bonusItem)
    if success then
        self.chainTargets = 4
        self.chainRange = 80
    end
    return success
end
