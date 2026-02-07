-- Micro-Missile Pod Tool
-- Fires bursts of small missiles with slight spread

-- Localized for performance in shared update function
local math_atan <const> = math.atan
local math_min <const> = math.min
local math_max <const> = math.max
local math_sin <const> = math.sin
local math_cos <const> = math.cos
local RAD_TO_DEG <const> = 180 / math.pi
local DEG_TO_RAD <const> = math.pi / 180

-- Shared update function for missile projectiles (avoids closure creation per missile)
-- Not in sprite system: pool handles updates, GameplayScene draws manually
-- Uses spatial grid for homing instead of full mob list scan
local function missileProjectileUpdate(self)
    if not self.active then return end

    self.framesAlive = self.framesAlive + 1

    self.lifetime = self.lifetime + 1
    if self.lifetime > self.maxLifetime then
        self:deactivate("lifetime")
        return
    end

    -- Slight homing toward nearest enemy (optimized: check every 3 frames)
    -- Uses spatial grid instead of scanning all mobs (O(k) vs O(n))
    if self.lifetime % 3 == 0 then
        local nearestDistSq = 10000  -- 100^2
        local nearestMob = nil

        if GameplayScene and GameplayScene.getMobsNearPosition then
            local nearbyMobs = GameplayScene:getMobsNearPosition(self.x, self.y)
            local nearbyCount = #nearbyMobs
            for i = 1, nearbyCount do
                local mob = nearbyMobs[i]
                if mob and mob.active then
                    local dx = mob.x - self.x
                    local dy = mob.y - self.y
                    local distSq = dx * dx + dy * dy
                    if distSq < nearestDistSq then
                        nearestDistSq = distSq
                        nearestMob = mob
                    end
                end
            end
        end

        self.homingTarget = nearestMob
    end

    local nearestMob = self.homingTarget
    if nearestMob and nearestMob.active then
        -- Inline vectorToAngle (avoids Utils table lookup + function call)
        local targetAngle = math_atan(nearestMob.x - self.x, -(nearestMob.y - self.y)) * RAD_TO_DEG
        local angleDiff = targetAngle - self.angle
        -- Normalize angle diff
        if angleDiff > 180 then angleDiff = angleDiff - 360
        elseif angleDiff < -180 then angleDiff = angleDiff + 360 end

        -- Tripled homing strength to compensate for less frequent updates
        local effectiveHoming = self.homingStrength * 3

        if angleDiff > 0 then
            self.angle = self.angle + math_min(angleDiff, effectiveHoming)
        else
            self.angle = self.angle + math_max(angleDiff, -effectiveHoming)
        end

        -- Inline angleToVector (avoids Utils table lookup + function call)
        local rad = self.angle * DEG_TO_RAD
        self.dx = math_sin(rad)
        self.dy = -math_cos(rad)
        -- Update draw rotation and pre-rotated image for manual rendering
        self.drawRotation = self.angle - 90
        if self._rotCache then
            local step = Utils.getRotationStep(self.drawRotation)
            if step ~= self._lastRotStep then
                self._lastRotStep = step
                self.drawImage = self._rotCache.images[step]
                local off = self._rotCache.offsets[step]
                self._drawHalfW = off[1]
                self._drawHalfH = off[2]
            end
        end
    end

    -- Move
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed

    -- Inline isOnScreen check
    if self.x < -30 or self.x > 430 or self.y < -30 or self.y > 270 then
        self:deactivate("offscreen")
    end
end

class('MicroMissilePod').extends(Tool)

MicroMissilePod.DATA = {
    id = "micro_missile_pod",
    name = "Micro Rocket Pack",
    description = "3-rocket burst. Dmg: 4x3",
    imagePath = "images/tools/tool_micro_missile_pod",
    iconPath = "images/tools/tool_micro_missile_pod",
    projectileImage = "images/tools/tool_micro_missile",

    baseDamage = 4,
    fireRate = 0.6,
    projectileSpeed = 7,
    pattern = "burst",
    damageType = "explosive",

    pairsWithBonus = "guidance_module",
    upgradedName = "Swarm Deployer",
    upgradedImagePath = "images/tools/tool_micro_missile_pod",
    upgradedProjectileImage = "images/tools/tool_swarm_missile",
    upgradedDamage = 8,
}

function MicroMissilePod:init()
    MicroMissilePod.super.init(self, MicroMissilePod.DATA)
    self.missilesPerBurst = 3
    self.extraMissiles = 0
    self.burstSpread = 15  -- Degrees between missiles
end

function MicroMissilePod:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    local totalMissiles = self.missilesPerBurst + self.extraMissiles
    local halfSpread = (totalMissiles - 1) * self.burstSpread / 2

    for i = 0, totalMissiles - 1 do
        local angle = firingAngle - halfSpread + (i * self.burstSpread)
        -- Add slight random wobble
        angle = angle + (math.random() - 0.5) * 3

        local proj = self:createMissileProjectile(fireX, fireY, angle)
    end
end

function MicroMissilePod:createMissileProjectile(x, y, angle)
    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        self.data.projectileImage,
        false
    )

    if proj then
        -- Slight homing toward nearest enemy
        proj.homingStrength = 1.5
        proj.lifetime = 0
        proj.maxLifetime = 120  -- 4 seconds
        proj.spawnX = x
        proj.spawnY = y
        proj.homingTarget = nil
        -- Use shared update function (avoids closure creation per missile)
        proj.update = missileProjectileUpdate
    end

    return proj
end

function MicroMissilePod:upgrade(bonusItem)
    local success = MicroMissilePod.super.upgrade(self, bonusItem)
    if success then
        self.missilesPerBurst = 5
        self.burstSpread = 12
    end
    return success
end
