-- Plasma Sprayer Tool
-- Fires multiple short-range plasma droplets in a cone pattern

class('PlasmaSprayer').extends(Tool)

PlasmaSprayer.DATA = {
    id = "plasma_sprayer",
    name = "Plasma Sprayer",
    description = "Cone spray. Dmg: 3x5",
    imagePath = "images/tools/tool_plasma_sprayer",
    iconPath = "images/tools/tool_plasma_sprayer",
    projectileImage = "images/tools/tool_plasma_droplet",

    baseDamage = 3,
    fireRate = 1.5,
    projectileSpeed = 8,
    pattern = "cone",
    damageType = "plasma",

    pairsWithBonus = "fuel_injector",
    upgradedName = "Inferno Cannon",
    upgradedImagePath = "images/tools/tool_plasma_sprayer",
    upgradedProjectileImage = "images/tools/tool_inferno_droplet",
    upgradedDamage = 6,
}

function PlasmaSprayer:init()
    PlasmaSprayer.super.init(self, PlasmaSprayer.DATA)
    self.projectilesPerShot = 5
    self.spreadAngle = 45  -- Total cone angle
    self.maxRange = 80  -- Short range
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
            -- Short range - deactivate after traveling maxRange
            proj.maxTravelDist = self.maxRange
            proj.travelDist = 0
            -- Use spawnX/spawnY for consistency with collision protection
            -- (createProjectile already sets these, but we ensure they're correct)
            proj.spawnX = fireX
            proj.spawnY = fireY

            proj.update = function(self)
                if not self.active then return end

                -- Prevent double updates in the same frame
                if self.lastUpdateFrame == Projectile.frameCounter then
                    return
                end
                self.lastUpdateFrame = Projectile.frameCounter

                if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
                    return
                end

                -- Track frames alive for collision grace period
                self.framesAlive = self.framesAlive + 1

                -- Move
                self.x = self.x + self.dx * self.speed
                self.y = self.y + self.dy * self.speed
                self:moveTo(self.x, self.y)

                -- Check distance traveled (use spawnX/spawnY for consistency)
                self.travelDist = Utils.distance(self.spawnX, self.spawnY, self.x, self.y)
                if self.travelDist > self.maxTravelDist then
                    self:deactivate("max_range")
                    return
                end

                -- Off screen check
                if not self:isOnScreen(20) then
                    self:deactivate("offscreen")
                end
            end
        end
    end
end

function PlasmaSprayer:upgrade(bonusItem)
    local success = PlasmaSprayer.super.upgrade(self, bonusItem)
    if success then
        self.projectilesPerShot = 7
        self.spreadAngle = 60
        self.maxRange = 100
    end
    return success
end
