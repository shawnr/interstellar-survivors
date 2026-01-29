-- Paradox Node MOB (Episode 3)
-- A logical impossibility made manifest. Slow but tough.

class('ParadoxNode').extends(MOB)

ParadoxNode.DATA = {
    id = "paradox_node",
    name = "Paradox Node",
    description = "This statement is false",
    imagePath = "images/episodes/ep3/ep3_paradox_node",

    -- Stats - slow but tanky
    baseHealth = 18,
    baseSpeed = 0.5,
    baseDamage = 10,
    rpValue = 25,

    -- Collision
    width = 20,
    height = 20,
    range = 1,
    emits = false,
}

function ParadoxNode:init(x, y, waveMultipliers)
    ParadoxNode.super.init(self, x, y, ParadoxNode.DATA, waveMultipliers)
end

function ParadoxNode:update(dt)
    ParadoxNode.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function ParadoxNode:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
