-- Modified Mapping Drone Tool
-- Heat-seeking missile that targets the highest HP enemy
-- Reference: Murderbot Diaries - ART/Perihelion's modified mapping drones

local gfx <const> = playdate.graphics

-- Generate programmatic drone projectile image
-- Drawn facing RIGHT (sprite convention: -90° rotation applied by system)
-- Cylindrical drone with explosive payload, nose cone at right, fins at left
local function generateDroneProjectile(isUpgraded)
    local w = isUpgraded and 18 or 16
    local h = isUpgraded and 12 or 10
    local img = gfx.image.new(w, h)
    gfx.pushContext(img)

    local cy = math.floor(h / 2)  -- center y
    local bodyEnd = w - 4  -- where nose cone starts

    -- White fill for all parts
    gfx.setColor(gfx.kColorWhite)

    -- Stabilizer fins (left side, swept back)
    gfx.fillTriangle(3, cy - 2, 0, 0, 0, cy - 2)           -- top fin
    gfx.fillTriangle(3, cy + 1, 0, h - 1, 0, cy + 1)       -- bottom fin

    -- Tail/engine section
    gfx.fillRect(2, cy - 2, 2, 4)

    -- Explosive payload (bulging section, taller than body)
    local exH = isUpgraded and 10 or 8
    local exY = cy - math.floor(exH / 2)
    gfx.fillRect(4, exY, 3, exH)

    -- Drone body (narrow horizontal cylinder)
    gfx.fillRect(7, cy - 2, bodyEnd - 7, 4)

    -- Nose cone (pointing right)
    gfx.fillTriangle(w - 1, cy, bodyEnd, cy - 3, bodyEnd, cy + 3)

    -- Black outlines and details for contrast
    gfx.setColor(gfx.kColorBlack)

    -- Body outline
    gfx.drawRect(7, cy - 2, bodyEnd - 7, 4)

    -- Explosive section outline
    gfx.drawRect(4, exY, 3, exH)

    -- Explosive strap detail (vertical band)
    gfx.drawLine(5, exY, 5, exY + exH - 1)

    -- Drone viewport (small dark window on body)
    gfx.fillRect(bodyEnd - 2, cy - 1, 1, 2)

    -- Upgraded: extra explosive detail
    if isUpgraded then
        gfx.drawLine(6, exY + 1, 6, exY + exH - 2)
    end

    gfx.popContext()
    return img
end

-- Module-level cached projectile images
local droneProjImage = nil
local upgradedDroneProjImage = nil

-- Shared update function for homing projectiles (avoids per-projectile closure)
local function homingUpdate(self)
    if not self.active then return end

    self.framesAlive = self.framesAlive + 1

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

        local angleDiff = targetAngle - self.angle
        while angleDiff > 180 do angleDiff = angleDiff - 360 end
        while angleDiff < -180 do angleDiff = angleDiff + 360 end

        local turnRate = self.homingStrength or 3.0
        if math.abs(angleDiff) < turnRate then
            self.angle = targetAngle
        elseif angleDiff > 0 then
            self.angle = self.angle + turnRate
        else
            self.angle = self.angle - turnRate
        end

        self.dx, self.dy = Utils.angleToVector(self.angle)
        self.drawRotation = self.angle - 90

        -- Update pre-rotated draw image for new angle
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

    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed

    if self.x < -50 or self.x > 450 or self.y < -50 or self.y > 290 then
        self:deactivate("offscreen")
    end
end

class('ModifiedMappingDrone').extends(Tool)

ModifiedMappingDrone.DATA = {
    id = "modified_mapping_drone",
    name = "Mod. Mapping Drone",
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
    upgradedName = "Perihelion Express",
    upgradedImagePath = "images/tools/tool_mapping_drone",
    upgradedDamage = 35,
}

function ModifiedMappingDrone:init()
    ModifiedMappingDrone.super.init(self, ModifiedMappingDrone.DATA)
    self.homingAccuracyBonus = 0

    -- Generate programmatic projectile images (once, shared via module locals)
    if not droneProjImage then
        droneProjImage = generateDroneProjectile(false)
        Utils.imageCache["_drone_proj"] = droneProjImage
    end
    if not upgradedDroneProjImage then
        upgradedDroneProjImage = generateDroneProjectile(true)
        Utils.imageCache["_drone_proj_upgraded"] = upgradedDroneProjImage
    end
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
    -- Use programmatic drone image for better visibility
    local cacheKey = self.isEvolved and "_drone_proj_upgraded" or "_drone_proj"

    local proj = GameplayScene:createProjectile(
        x, y, angle,
        self.projectileSpeed * (1 + self.projectileSpeedBonus),
        self.damage,
        cacheKey,
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

        -- Use shared function (avoids per-projectile closure creation)
        proj.update = homingUpdate
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
