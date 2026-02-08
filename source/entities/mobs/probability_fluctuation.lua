-- Probability Fluctuation MOB (Episode 3)
-- Unstable entity that shouldn't exist but does anyway

class('ProbabilityFluctuation').extends(MOB)

ProbabilityFluctuation.DATA = {
    id = "probability_fluctuation",
    name = "Probability Fluctuation",
    description = "Exists despite the odds",
    imagePath = "images/episodes/ep3/ep3_probability_fluctuation",
    animPath = "images/episodes/ep3/ep3_probability_fluctuation",  -- Animation table (3 frames)
    frameDuration = 0.1,  -- 100ms per frame - flickery effect

    -- Stats - flickery and unpredictable
    baseHealth = 18,
    baseSpeed = 1.1,
    baseDamage = 5,
    rpValue = 12,

    -- Collision
    width = 14,
    height = 14,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

function ProbabilityFluctuation:init(x, y, waveMultipliers)
    ProbabilityFluctuation.super.init(self, x, y, ProbabilityFluctuation.DATA, waveMultipliers)
end

function ProbabilityFluctuation:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)
    ProbabilityFluctuation.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

