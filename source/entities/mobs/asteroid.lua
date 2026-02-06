-- Asteroid MOB
-- Basic ramming enemy that moves toward the station

class('Asteroid').extends(MOB)

-- Asteroid data (from design document)
Asteroid.DATA = {
    id = "asteroid",
    name = "Asteroid",
    description = "Common space debris that threatens the station by ramming",
    imagePath = "images/shared/asteroid",

    -- Base stats (easiest enemy - one hit kill)
    baseHealth = 3,
    baseSpeed = 0.5,   -- Slow approach
    baseDamage = 5,
    rpValue = 5,

    -- Collision
    width = 16,
    height = 16,
    range = 1,      -- Must touch to damage
    emits = false,  -- Ramming, not shooting
    skipRotation = true,  -- Performance: no rotation updates

    -- Levels (asteroids have 3 size levels)
    levels = 3,
}

function Asteroid:init(x, y, waveMultipliers, level)
    -- Adjust stats based on level
    level = level or 1
    local data = table.deepcopy(Asteroid.DATA)

    -- Scale stats by level
    if level == 2 then
        data.baseHealth = data.baseHealth * 1.5
        data.baseDamage = data.baseDamage * 1.3
        data.rpValue = data.rpValue * 1.5
        data.width = 20
        data.height = 20
    elseif level == 3 then
        data.baseHealth = data.baseHealth * 2.5
        data.baseDamage = data.baseDamage * 1.8
        data.rpValue = data.rpValue * 2.5
        data.width = 24
        data.height = 24
    end

    self.level = level

    -- Call parent init
    Asteroid.super.init(self, x, y, data, waveMultipliers)
end

-- Override update for asteroid-specific behavior
function Asteroid:update(dt)
    Asteroid.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

-- Called when asteroid hits the station
function Asteroid:onHitStation()
    -- Deal damage to station
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
        -- TODO: AudioManager:playSFX("station_hit")
    end

    -- Destroy self
    self:onDestroyed()
end

-- Override destroyed to potentially spawn smaller asteroids
function Asteroid:onDestroyed()
    -- Large asteroids could spawn smaller ones (optional feature)
    -- For now, just call parent
    Asteroid.super.onDestroyed(self)
end
