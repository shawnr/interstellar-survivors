-- Phase Disruptor Tool
-- High damage piercing beam that passes through all enemies

class('PhaseDisruptor').extends(Tool)

PhaseDisruptor.DATA = {
    id = "phase_disruptor",
    name = "Phase Disruptor",
    description = "Piercing beam. Dmg: 15",
    imagePath = "images/tools/tool_phase_disruptor",
    iconPath = "images/tools/tool_phase_disruptor",
    projectileImage = "images/tools/tool_phase_beam",

    baseDamage = 15,
    fireRate = 0.4,
    projectileSpeed = 15,
    pattern = "piercing",
    damageType = "phase",

    pairsWithBonus = "phase_modulators",
    upgradedName = "Dimensional Rift",
    upgradedImagePath = "images/tools/tool_phase_disruptor",
    upgradedDamage = 30,
}

function PhaseDisruptor:init()
    PhaseDisruptor.super.init(self, PhaseDisruptor.DATA)
    self.maxPierceTargets = 99  -- Essentially unlimited
end

function PhaseDisruptor:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 14
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    self:createPiercingBeam(fireX, fireY, firingAngle)
end

function PhaseDisruptor:createPiercingBeam(x, y, angle)
    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        self.data.projectileImage,
        true  -- Piercing
    )

    if proj then
        proj.maxHits = self.maxPierceTargets
        proj.hitCount = 0
        proj.hitTargets = {}  -- Track targets to prevent double-hitting same enemy

        -- Override onHit to track hits properly
        proj.onHit = function(self, target)
            -- Only count if we haven't hit this target before
            if not self.hitTargets[target] then
                self.hitTargets[target] = true
                self.hitCount = self.hitCount + 1

                -- Deactivate only if we hit max targets
                if self.hitCount >= self.maxHits then
                    self:deactivate()
                end
            end
        end
    end

    return proj
end

function PhaseDisruptor:upgrade(bonusItem)
    local success = PhaseDisruptor.super.upgrade(self, bonusItem)
    if success then
        -- Upgraded beam is wider and longer-lasting
        self.projectileSpeed = 18
    end
    return success
end
