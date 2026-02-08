-- Repulsor Field Tool
-- Pushes enemies away from station (no donut hole - affects all mobs to outer edge)

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
    self.pushRadius = 70   -- Wider than shield (~40px)
    self.pushForceBonus = 0
end

function RepulsorField:recalculateStats()
    RepulsorField.super.recalculateStats(self)
    if not self.isEvolved then
        -- L1=70, L2=80, L3=90, L4=100
        self.pushRadius = 70 + (self.level - 1) * 10
    end
end

function RepulsorField:fire()
    -- Push all nearby enemies away (no donut hole)
    self:pushEnemies()

    -- Create expanding circle flash centered on station
    if GameplayScene and GameplayScene.createPulseEffect then
        local cx = self.station and self.station.x or self.x
        local cy = self.station and self.station.y or self.y
        GameplayScene:createPulseEffect(cx, cy, self.pushRadius, 0.3, "repulsor")
    end
end

function RepulsorField:pushEnemies()
    if not GameplayScene or not GameplayScene.mobs then return end

    local force = self.pushForce * (1 + self.pushForceBonus)

    local mobs = GameplayScene.mobs
    local mobCount = #mobs
    local pushRadiusSq = self.pushRadius * self.pushRadius
    local pushRadius = self.pushRadius
    for i = 1, mobCount do
        local mob = mobs[i]
        if mob.active then
            local dx = mob.x - self.x
            local dy = mob.y - self.y
            local distSq = dx * dx + dy * dy
            if distSq < pushRadiusSq and distSq > 1 then
                -- Calculate push direction (away from tool)
                local dist = distSq ^ 0.5
                local invDist = 1 / dist

                -- Apply push (stronger when closer)
                local pushStrength = force * (1 - dist / pushRadius) * 10
                mob.x = mob.x + dx * invDist * pushStrength
                mob.y = mob.y + dy * invDist * pushStrength
                mob:moveTo(mob.x, mob.y)
            end
        end
    end
end

function RepulsorField:upgrade(bonusItem)
    local success = RepulsorField.super.upgrade(self, bonusItem)
    if success then
        self.pushForce = 5
        self.pushRadius = 130  -- Evolved: large coverage
    end
    return success
end
