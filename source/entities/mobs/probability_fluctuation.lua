-- Probability Fluctuation MOB (Episode 3)
-- Unstable entity that shouldn't exist but does anyway

class('ProbabilityFluctuation').extends(MOB)

ProbabilityFluctuation.DATA = {
    id = "probability_fluctuation",
    name = "Probability Fluctuation",
    description = "Exists despite the odds",
    imagePath = "images/episodes/ep3/ep3_probability_fluctuation",

    -- Stats - flickery and unpredictable
    baseHealth = 7,
    baseSpeed = 1.1,
    baseDamage = 5,
    rpValue = 12,

    -- Collision
    width = 14,
    height = 14,
    range = 1,
    emits = false,
}

function ProbabilityFluctuation:init(x, y, waveMultipliers)
    ProbabilityFluctuation.super.init(self, x, y, ProbabilityFluctuation.DATA, waveMultipliers)
end

function ProbabilityFluctuation:update(dt)
    ProbabilityFluctuation.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function ProbabilityFluctuation:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
