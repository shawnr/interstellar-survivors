-- Greeting Drone MOB (Episode 1)
-- Small, fast ramming enemy that wants to "hug" your station

class('GreetingDrone').extends(MOB)

GreetingDrone.DATA = {
    id = "greeting_drone",
    name = "Greeting Drone",
    description = "Small, fast, eager to hug your station",
    imagePath = "images/episodes/ep1/ep1_greeting_drone",

    -- Stats - faster than asteroids but less damage
    baseHealth = 5,
    baseSpeed = 1.2,    -- Fast!
    baseDamage = 3,
    rpValue = 8,

    -- Collision
    width = 12,
    height = 12,
    range = 1,      -- Must touch to damage
    emits = false,  -- Ramming MOB
}

function GreetingDrone:init(x, y, waveMultipliers)
    GreetingDrone.super.init(self, x, y, GreetingDrone.DATA, waveMultipliers)
end

function GreetingDrone:update(dt)
    GreetingDrone.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function GreetingDrone:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
