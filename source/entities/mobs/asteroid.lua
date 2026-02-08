-- Asteroid MOB
-- Basic ramming enemy that moves toward the station

class('Asteroid').extends(MOB)

-- Asteroid data (from design document)
Asteroid.DATA = {
    id = "asteroid",
    name = "Asteroid",
    description = "Common space debris that threatens the station by ramming",
    imagePath = "images/shared/asteroid",

    -- Base stats
    baseHealth = 8,
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

-- Pre-computed level data (avoids table.deepcopy on every spawn)
Asteroid.LEVEL_DATA = {
    [1] = Asteroid.DATA,
}

function Asteroid:init(x, y, waveMultipliers, level)
    level = level or 1
    self.level = level

    -- Use pre-computed level data or base DATA (no deep copy needed)
    local data = Asteroid.LEVEL_DATA[level]
    if not data then
        -- Build level-specific override table once, cache it
        local base = Asteroid.DATA
        if level == 2 then
            data = setmetatable({
                baseHealth = base.baseHealth * 1.5,
                baseDamage = base.baseDamage * 1.3,
                rpValue = base.rpValue * 1.5,
                width = 20, height = 20,
            }, { __index = base })
        elseif level == 3 then
            data = setmetatable({
                baseHealth = base.baseHealth * 2.5,
                baseDamage = base.baseDamage * 1.8,
                rpValue = base.rpValue * 2.5,
                width = 24, height = 24,
            }, { __index = base })
        else
            data = base
        end
        Asteroid.LEVEL_DATA[level] = data
    end

    -- Call parent init
    Asteroid.super.init(self, x, y, data, waveMultipliers)
end

-- Override update for asteroid-specific behavior
function Asteroid:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)
    Asteroid.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end


-- Override destroyed to potentially spawn smaller asteroids
function Asteroid:onDestroyed()
    -- Large asteroids could spawn smaller ones (optional feature)
    -- For now, just call parent
    Asteroid.super.onDestroyed(self)
end
