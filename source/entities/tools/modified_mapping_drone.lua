-- Modified Mapping Drone Tool
-- Heat-seeking missile that targets the highest HP enemy
-- Reference: Murderbot Diaries - ART/Perihelion's modified mapping drones

class('ModifiedMappingDrone').extends(Tool)

ModifiedMappingDrone.DATA = {
    id = "modified_mapping_drone",
    name = "Mapping Drone",
    description = "Seeks highest HP. Dmg: 18",
    imagePath = "images/tools/tool_mapping_drone",
    iconPath = "images/tools/tool_mapping_drone",
    projectileImage = "images/tools/tool_mapping_drone_missile",

    baseDamage = 18,
    fireRate = 0.5,
    projectileSpeed = 4,
    pattern = "homing_priority",
    damageType = "explosive",

    pairsWithBonus = "targeting_matrix",
    upgradedName = "Perihelion Strike",
    upgradedImagePath = "images/tools/tool_mapping_drone",
    upgradedDamage = 35,
}

function ModifiedMappingDrone:init()
    ModifiedMappingDrone.super.init(self, ModifiedMappingDrone.DATA)
    self.homingAccuracyBonus = 0
end

function ModifiedMappingDrone:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Find the highest HP target
    local target = self:findHighestHPTarget()

    -- If we have a target, adjust angle toward it
    if target then
        local targetAngle = Utils.vectorToAngle(target.x - fireX, target.y - fireY)
        firingAngle = targetAngle
    end

    -- Create a special homing projectile
    self:createHomingProjectile(fireX, fireY, firingAngle, target)
end

-- Find the MOB with the highest current HP
function ModifiedMappingDrone:findHighestHPTarget()
    if not GameplayScene or not GameplayScene.mobs then
        return nil
    end

    local highestHP = 0
    local target = nil

    local mobs = GameplayScene.mobs
    local mobCount = #mobs
    for i = 1, mobCount do
        local mob = mobs[i]
        if mob.active and mob.health and mob.health > highestHP then
            highestHP = mob.health
            target = mob
        end
    end

    return target
end

-- Create a homing projectile that tracks toward target
function ModifiedMappingDrone:createHomingProjectile(x, y, angle, target)
    -- Use the standard projectile pool but we'll override behavior
    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        self.data.projectileImage,
        false  -- Not piercing - explodes on contact
    )

    if proj then
        -- Store target reference and homing data on projectile
        proj.homingTarget = target
        proj.homingStrength = 3.0 + self.homingAccuracyBonus  -- Turn rate in degrees per frame
        proj.isHoming = true
        proj.maxLifetime = 180  -- 6 seconds at 30fps
        proj.lifetime = 0
        -- Ensure spawn position is set for collision protection
        proj.spawnX = x
        proj.spawnY = y

        -- Override the update function for homing behavior
        -- Not in sprite system: pool handles updates, GameplayScene draws manually
        proj.update = function(self)
            if not self.active then return end

            -- Track frames alive for collision grace period
            self.framesAlive = self.framesAlive + 1

            -- Track lifetime
            self.lifetime = (self.lifetime or 0) + 1
            if self.lifetime > (self.maxLifetime or 180) then
                self:deactivate("lifetime")
                return
            end

            -- Homing behavior
            if self.isHoming and self.homingTarget and self.homingTarget.active then
                local targetAngle = Utils.vectorToAngle(
                    self.homingTarget.x - self.x,
                    self.homingTarget.y - self.y
                )

                -- Smoothly turn toward target
                local angleDiff = targetAngle - self.angle
                -- Normalize angle difference to -180 to 180
                while angleDiff > 180 do angleDiff = angleDiff - 360 end
                while angleDiff < -180 do angleDiff = angleDiff + 360 end

                -- Apply turn rate
                local turnRate = self.homingStrength or 3.0
                if math.abs(angleDiff) < turnRate then
                    self.angle = targetAngle
                elseif angleDiff > 0 then
                    self.angle = self.angle + turnRate
                else
                    self.angle = self.angle - turnRate
                end

                -- Update direction vector
                self.dx, self.dy = Utils.angleToVector(self.angle)

                -- Update draw rotation for manual rendering
                self.drawRotation = self.angle - 90
            elseif self.isHoming then
                -- Target lost - find new highest HP target
                self.homingTarget = nil
                if GameplayScene and GameplayScene.mobs then
                    local highestHP = 0
                    local mobs = GameplayScene.mobs
                    local mobCount = #mobs
                    for i = 1, mobCount do
                        local mob = mobs[i]
                        if mob.active and mob.health and mob.health > highestHP then
                            highestHP = mob.health
                            self.homingTarget = mob
                        end
                    end
                end
            end

            -- Move in current direction
            self.x = self.x + self.dx * self.speed
            self.y = self.y + self.dy * self.speed

            -- Inline isOnScreen check (with larger margin for homing)
            if self.x < -50 or self.x > 450 or self.y < -50 or self.y > 290 then
                self:deactivate("offscreen")
            end
        end
    end

    return proj
end

function ModifiedMappingDrone:upgrade(bonusItem)
    local success = ModifiedMappingDrone.super.upgrade(self, bonusItem)
    if success then
        -- Improved homing when upgraded
        self.homingAccuracyBonus = 2.0
    end
    return success
end
