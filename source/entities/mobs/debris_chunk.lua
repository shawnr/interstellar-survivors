-- Debris Chunk MOB (Episode 4)
-- Ancient wreckage tumbling toward the station

class('DebrisChunk').extends(MOB)

DebrisChunk.DATA = {
    id = "debris_chunk",
    name = "Debris Chunk",
    description = "Twisted metal fragment from an ancient war",
    imagePath = "images/episodes/ep4/ep4_debris_chunk",

    -- Stats - varies by variant
    baseHealth = 8,
    baseSpeed = 0.7,
    baseDamage = 5,
    rpValue = 8,

    -- Collision
    width = 14,
    height = 14,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

-- Image variants for visual variety
DebrisChunk.VARIANTS = {
    "images/episodes/ep4/ep4_debris_chunk",
    "images/episodes/ep4/ep4_debris_chunk_v2",
    "images/episodes/ep4/ep4_debris_chunk_v3",
}

function DebrisChunk:init(x, y, waveMultipliers, variant)
    -- Choose a random variant if not specified
    variant = variant or math.random(1, 3)
    local data = table.deepcopy(DebrisChunk.DATA)
    data.imagePath = DebrisChunk.VARIANTS[variant]

    DebrisChunk.super.init(self, x, y, data, waveMultipliers)
    self.variant = variant
    -- No rotation animation for performance
end

function DebrisChunk:update(dt)
    DebrisChunk.super.update(self, dt)

    -- Check for station collision (no rotation for performance)
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function DebrisChunk:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
