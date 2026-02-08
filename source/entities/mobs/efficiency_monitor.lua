-- Efficiency Monitor MOB (Episode 2)
-- Larger corporate enforcer, slower but tougher

class('EfficiencyMonitor').extends(MOB)

EfficiencyMonitor.DATA = {
    id = "efficiency_monitor",
    name = "Efficiency Monitor",
    description = "Your metrics are unacceptable",
    imagePath = "images/episodes/ep2/ep2_efficiency_monitor",

    -- Stats - slower but more health and damage
    baseHealth = 35,
    baseSpeed = 0.6,
    baseDamage = 8,
    rpValue = 20,

    -- Collision
    width = 18,
    height = 18,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
    isMechanical = true,
}

function EfficiencyMonitor:init(x, y, waveMultipliers)
    EfficiencyMonitor.super.init(self, x, y, EfficiencyMonitor.DATA, waveMultipliers)
end

function EfficiencyMonitor:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)
    EfficiencyMonitor.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

-- Override onHitStation to sometimes apply fireRateSlow (like Productivity Liaison boss)
function EfficiencyMonitor:onHitStation()
    if GameplayScene and GameplayScene.station and math.random(100) <= 15 then
        GameplayScene.station:applyDebuff("fireRateSlow", 0.2, 2.0)
    end
    EfficiencyMonitor.super.onHitStation(self)
end

