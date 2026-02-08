-- Paradox Node MOB (Episode 3)
-- A logical impossibility made manifest. Slow but tough.

class('ParadoxNode').extends(MOB)

ParadoxNode.DATA = {
    id = "paradox_node",
    name = "Paradox Node",
    description = "This statement is false",
    imagePath = "images/episodes/ep3/ep3_paradox_node",

    -- Stats - slow but tanky
    baseHealth = 40,
    baseSpeed = 0.5,
    baseDamage = 10,
    rpValue = 25,

    -- Collision
    width = 20,
    height = 20,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

function ParadoxNode:init(x, y, waveMultipliers)
    ParadoxNode.super.init(self, x, y, ParadoxNode.DATA, waveMultipliers)
end

function ParadoxNode:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)
    ParadoxNode.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

-- Override onHitStation to sometimes apply a random debuff (like Improbability Engine boss)
function ParadoxNode:onHitStation()
    if GameplayScene and GameplayScene.station and math.random(100) <= 15 then
        local roll = math.random(3)
        if roll == 1 then
            GameplayScene.station:applyDebuff("controlsInverted", true, 2.5)
        elseif roll == 2 then
            GameplayScene.station:applyDebuff("rotationSlow", 0.2, 2.0)
        else
            GameplayScene.station:applyDebuff("fireRateSlow", 0.2, 2.0)
        end
    end
    ParadoxNode.super.onHitStation(self)
end

