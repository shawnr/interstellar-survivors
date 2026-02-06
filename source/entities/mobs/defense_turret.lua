-- Defense Turret MOB (Episode 4)
-- Automated systems from an old war, still functional, still shooting

local gfx <const> = playdate.graphics
local math_atan <const> = math.atan
local RAD_TO_DEG <const> = 180 / math.pi

class('DefenseTurret').extends(MOB)

DefenseTurret.DATA = {
    id = "defense_turret",
    name = "Defense Turret",
    description = "Ancient automated gun platform",
    imagePath = "images/episodes/ep4/ep4_defense_turret",
    projectileImage = "images/episodes/ep4/ep4_turret_projectile",

    -- Stats - stationary turret
    baseHealth = 20,
    baseSpeed = 0.3,
    baseDamage = 6,
    rpValue = 20,

    -- Collision
    width = 28,
    height = 28,
    range = 100,    -- Stays at range
    emits = true,   -- Shooting MOB

    -- Attack properties
    fireRate = 0.6,     -- Shots per second
    projectileSpeed = 4,
}

function DefenseTurret:init(x, y, waveMultipliers)
    DefenseTurret.super.init(self, x, y, DefenseTurret.DATA, waveMultipliers)

    -- Firing state
    self.fireCooldown = 0
    self.fireInterval = 1 / DefenseTurret.DATA.fireRate
end

function DefenseTurret:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)
    DefenseTurret.super.update(self, dt)

    -- Update firing
    self.fireCooldown = self.fireCooldown - dt
    if self.fireCooldown <= 0 then
        -- Only fire if in range (use squared distance for performance)
        -- Inline distanceSquared (avoid function call overhead)
        local ddx = self.targetX - self.x
        local ddy = self.targetY - self.y
        local distSq = ddx * ddx + ddy * ddy
        local rangeSq = (self.range + 20) * (self.range + 20)
        if distSq <= rangeSq then
            self:fire()
            self.fireCooldown = self.fireInterval
        end
    end
end

function DefenseTurret:fire()
    -- Calculate angle to station (inline vectorToAngle)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local angle = math_atan(dx, -dy) * RAD_TO_DEG

    -- Create projectile aimed at station
    if GameplayScene and GameplayScene.createEnemyProjectile then
        GameplayScene:createEnemyProjectile(
            self.x, self.y,
            angle,
            DefenseTurret.DATA.projectileSpeed,
            self.damage,
            DefenseTurret.DATA.projectileImage,
            nil  -- No special effect
        )
    else
        -- Fallback: direct damage
        if GameplayScene and GameplayScene.station then
            if math.random() < 0.25 then
                GameplayScene.station:takeDamage(self.damage)
            end
        end
    end
end
