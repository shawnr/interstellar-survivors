-- Plasma Sprayer Tool
-- Fires multiple short-range plasma droplets in a cone pattern

-- Shared update function for plasma projectiles (avoids closure creation per projectile)
-- Not in sprite system: pool handles updates, GameplayScene draws manually
local function plasmaProjectileUpdate(self)
    if not self.active then return end

    self.framesAlive = self.framesAlive + 1

    -- Move
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed

    -- Check distance traveled (use squared distance for performance)
    local tdx = self.x - self.spawnX
    local tdy = self.y - self.spawnY
    local travelDistSq = tdx * tdx + tdy * tdy
    if travelDistSq > self.maxTravelDistSq then
        self:deactivate("max_range")
        return
    end

    -- Inline isOnScreen check
    if self.x < -20 or self.x > 420 or self.y < -20 or self.y > 260 then
        self:deactivate("offscreen")
    end
end

class('PlasmaSprayer').extends(Tool)

PlasmaSprayer.DATA = {
    id = "plasma_sprayer",
    name = "Plasma Sprayer",
    description = "Cone spray. Dmg: 4x4",
    imagePath = "images/tools/tool_plasma_sprayer",
    iconPath = "images/tools/tool_plasma_sprayer",
    projectileImage = "images/tools/tool_plasma_droplet",

    baseDamage = 4,  -- Increased from 3 to compensate for fewer projectiles
    fireRate = 1.5,
    projectileSpeed = 8,
    pattern = "cone",
    damageType = "plasma",

    pairsWithBonus = "fuel_injector",
    upgradedName = "Inferno Projector",
    upgradedImagePath = "images/tools/tool_plasma_sprayer",
    upgradedProjectileImage = "images/tools/tool_inferno_droplet",
    upgradedDamage = 6,
}

function PlasmaSprayer:init()
    PlasmaSprayer.super.init(self, PlasmaSprayer.DATA)
    self.projectilesPerShot = 4  -- Reduced from 5 for performance
    self.spreadAngle = 45  -- Total cone angle
    self.maxRange = 80  -- Short range
    self.maxRangeSq = 80 * 80  -- Pre-computed for performance
end

function PlasmaSprayer:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Fire multiple projectiles in a cone
    local halfSpread = self.spreadAngle / 2
    local angleStep = self.spreadAngle / (self.projectilesPerShot - 1)

    for i = 0, self.projectilesPerShot - 1 do
        local angle = firingAngle - halfSpread + (angleStep * i)
        -- Add slight randomness
        angle = angle + (math.random() - 0.5) * 5

        local proj = self:createProjectile(fireX, fireY, angle)
        if proj then
            -- Short range - deactivate after traveling maxRange (squared for performance)
            proj.maxTravelDistSq = self.maxRangeSq
            proj.spawnX = fireX
            proj.spawnY = fireY
            -- Use shared update function (avoids closure creation per projectile)
            proj.update = plasmaProjectileUpdate
        end
    end
end

function PlasmaSprayer:upgrade(bonusItem)
    local success = PlasmaSprayer.super.upgrade(self, bonusItem)
    if success then
        self.projectilesPerShot = 5  -- Reduced from 7 for performance
        self.spreadAngle = 60
        self.maxRange = 100
        self.maxRangeSq = 100 * 100  -- Pre-computed for performance
    end
    return success
end
