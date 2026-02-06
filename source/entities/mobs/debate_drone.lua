-- Debate Drone MOB (Episode 5)
-- Small alien vessels who consider physical collision an acceptable form of peer review

class('DebateDrone').extends(MOB)

DebateDrone.DATA = {
    id = "debate_drone",
    name = "Debate Drone",
    description = "Physical collision is peer review",
    imagePath = "images/episodes/ep5/ep5_debate_drone",

    -- Stats - fast and annoying
    baseHealth = 5,
    baseSpeed = 1.2,
    baseDamage = 3,
    rpValue = 8,

    -- Collision
    width = 14,
    height = 14,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

-- Image variants for visual variety (different alien species)
DebateDrone.VARIANTS = {
    "images/episodes/ep5/ep5_debate_drone",
    "images/episodes/ep5/ep5_debate_drone_v2",
    "images/episodes/ep5/ep5_debate_drone_v3",
}

function DebateDrone:init(x, y, waveMultipliers, variant)
    -- Choose a random variant if not specified
    variant = variant or math.random(1, 3)
    local data = table.deepcopy(DebateDrone.DATA)
    data.imagePath = DebateDrone.VARIANTS[variant]

    DebateDrone.super.init(self, x, y, data, waveMultipliers)
    self.variant = variant
end

function DebateDrone:update(dt)
    DebateDrone.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function DebateDrone:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
