-- Silk Weaver MOB (Episode 1)
-- Hovers at range and fires sticky webbing that slows rotation

local gfx <const> = playdate.graphics

class('SilkWeaver').extends(MOB)

SilkWeaver.DATA = {
    id = "silk_weaver",
    name = "Silk Weaver",
    description = "Fires sticky webbing that slows rotation",
    imagePath = "images/episodes/ep1/ep1_silk_weaver",
    projectileImage = "images/episodes/ep1/ep1_silk_projectile",

    -- Stats - hovers at range
    baseHealth = 12,
    baseSpeed = 0.6,
    baseDamage = 2,
    rpValue = 15,

    -- Collision
    width = 20,
    height = 20,
    range = 80,     -- Stays at range
    emits = true,   -- Shooting MOB

    -- Attack properties
    fireRate = 0.5,     -- Shots per second
    projectileSpeed = 3,
}

function SilkWeaver:init(x, y, waveMultipliers)
    SilkWeaver.super.init(self, x, y, SilkWeaver.DATA, waveMultipliers)

    -- Firing state
    self.fireCooldown = 0
    self.fireInterval = 1 / SilkWeaver.DATA.fireRate
end

function SilkWeaver:update(dt)
    SilkWeaver.super.update(self, dt)

    dt = dt or (1/30)

    -- Update firing
    self.fireCooldown = self.fireCooldown - dt
    if self.fireCooldown <= 0 then
        -- Only fire if in range
        local dist = Utils.distance(self.x, self.y, self.targetX, self.targetY)
        if dist <= self.range + 20 then
            self:fire()
            self.fireCooldown = self.fireInterval
        end
    end
end

function SilkWeaver:fire()
    -- Calculate angle to station
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local angle = Utils.vectorToAngle(dx, dy)

    -- Create projectile aimed at station
    if GameplayScene and GameplayScene.createEnemyProjectile then
        GameplayScene:createEnemyProjectile(
            self.x, self.y,
            angle,
            SilkWeaver.DATA.projectileSpeed,
            self.damage,
            SilkWeaver.DATA.projectileImage,
            "slow"  -- Special effect: slows station rotation
        )
    else
        -- Fallback: direct damage if projectile system not available
        -- Just deal damage at range for now
        if GameplayScene and GameplayScene.station then
            -- Small chance to hit
            if math.random() < 0.3 then
                GameplayScene.station:takeDamage(self.damage)
                -- Apply slow effect
                self:applySlowEffect()
            end
        end
    end
end

function SilkWeaver:applySlowEffect()
    -- Slow station rotation for a short time
    if GameplayScene and GameplayScene.station then
        -- Apply a rotation slow debuff
        GameplayScene.station.rotationSlow = 0.5  -- 50% slower
        GameplayScene.station.rotationSlowTimer = 2.0  -- 2 seconds

        -- Slow effect applied
    end
end
