-- Citation Platform MOB (Episode 5)
-- Fires focused data streams. They're sharing their research. Aggressively.

local gfx <const> = playdate.graphics
local math_atan <const> = math.atan
local RAD_TO_DEG <const> = 180 / math.pi

class('CitationPlatform').extends(MOB)

CitationPlatform.DATA = {
    id = "citation_platform",
    name = "Citation Platform",
    description = "Sharing research aggressively",
    imagePath = "images/episodes/ep5/ep5_citation_platform",
    projectileImage = "images/episodes/ep5/ep5_citation_beam",

    -- Stats - hovers at range
    baseHealth = 16,
    baseSpeed = 0.5,
    baseDamage = 7,
    rpValue = 22,

    -- Collision
    width = 20,
    height = 20,
    range = 90,     -- Stays at range
    emits = true,   -- Shooting MOB

    -- Attack properties
    fireRate = 0.5,     -- Shots per second
    projectileSpeed = 3.5,
}

function CitationPlatform:init(x, y, waveMultipliers)
    CitationPlatform.super.init(self, x, y, CitationPlatform.DATA, waveMultipliers)

    -- Firing state
    self.fireCooldown = 0
    self.fireInterval = 1 / CitationPlatform.DATA.fireRate
end

function CitationPlatform:update(dt)
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = (dt or (1/30)) * 2
    CitationPlatform.super.update(self, dt)

    -- Update firing
    self.fireCooldown = self.fireCooldown - dt
    if self.fireCooldown <= 0 then
        -- Only fire if in range (use squared distance to avoid sqrt)
        local ddx = self.targetX - self.x
        local ddy = self.targetY - self.y
        local distSq = ddx * ddx + ddy * ddy
        local rangePlusPad = self.range + 20
        if distSq <= rangePlusPad * rangePlusPad then
            self:fire()
            self.fireCooldown = self.fireInterval
        end
    end
end

function CitationPlatform:fire()
    -- Calculate angle to station
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local angle = math_atan(dx, -dy) * RAD_TO_DEG

    -- Create projectile aimed at station
    if GameplayScene and GameplayScene.createEnemyProjectile then
        GameplayScene:createEnemyProjectile(
            self.x, self.y,
            angle,
            CitationPlatform.DATA.projectileSpeed,
            self.damage,
            CitationPlatform.DATA.projectileImage,
            nil  -- No special effect
        )
    else
        -- Fallback: direct damage
        if GameplayScene and GameplayScene.station then
            if math.random() < 0.3 then
                GameplayScene.station:takeDamage(self.damage)
            end
        end
    end
end
