-- Micro-Missile Pod Tool
-- Fires bursts of small missiles with slight spread

class('MicroMissilePod').extends(Tool)

MicroMissilePod.DATA = {
    id = "micro_missile_pod",
    name = "Micro-Missile Pod",
    description = "3-missile burst. Dmg: 4x3",
    imagePath = "images/tools/tool_micro_missile_pod",
    iconPath = "images/tools/tool_micro_missile_pod",
    projectileImage = "images/tools/tool_micro_missile",

    baseDamage = 4,
    fireRate = 0.6,
    projectileSpeed = 7,
    pattern = "burst",
    damageType = "explosive",

    pairsWithBonus = "guidance_module",
    upgradedName = "Swarm Launcher",
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
        -- Ensure spawn position is set for collision protection
        proj.spawnX = x
        proj.spawnY = y

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

            self.lifetime = self.lifetime + 1
            if self.lifetime > self.maxLifetime then
                self:deactivate("lifetime")
                return
            end

            -- Slight homing toward nearest enemy
            local nearestDist = 100
            local nearestMob = nil

            if GameplayScene and GameplayScene.mobs then
                for _, mob in ipairs(GameplayScene.mobs) do
                    if mob.active then
                        local dist = Utils.distance(self.x, self.y, mob.x, mob.y)
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestMob = mob
                        end
                    end
                end
            end

            if nearestMob then
                local targetAngle = Utils.vectorToAngle(nearestMob.x - self.x, nearestMob.y - self.y)
                local angleDiff = targetAngle - self.angle
                while angleDiff > 180 do angleDiff = angleDiff - 360 end
                while angleDiff < -180 do angleDiff = angleDiff + 360 end

                if math.abs(angleDiff) < self.homingStrength then
                    self.angle = targetAngle
                elseif angleDiff > 0 then
                    self.angle = self.angle + self.homingStrength
                else
                    self.angle = self.angle - self.homingStrength
                end

                self.dx, self.dy = Utils.angleToVector(self.angle)
                self:setRotation(self.angle - 90)
            end

            -- Move
            self.x = self.x + self.dx * self.speed
            self.y = self.y + self.dy * self.speed
            self:moveTo(self.x, self.y)

            if not self:isOnScreen(30) then
                self:deactivate("offscreen")
            end
        end
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
