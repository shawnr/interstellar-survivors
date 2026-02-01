-- Singularity Core Tool
-- Deploys gravity orbs that orbit the station, damaging enemies they touch

class('SingularityCore').extends(Tool)

SingularityCore.DATA = {
    id = "singularity_core",
    name = "Singularity Core",
    description = "Orbital gravity orb. Dmg: 6/tick",
    imagePath = "images/tools/tool_singularity_core",
    iconPath = "images/tools/tool_singularity_core",
    projectileImage = "images/tools/tool_singularity_orb",

    baseDamage = 6,
    fireRate = 0.3,
    projectileSpeed = 0,
    pattern = "orbital",
    damageType = "gravity",

    pairsWithBonus = "graviton_lens",
    upgradedName = "Black Hole Generator",
    upgradedImagePath = "images/tools/tool_singularity_core",
    upgradedDamage = 12,
}

function SingularityCore:init()
    SingularityCore.super.init(self, SingularityCore.DATA)
    self.orbitalRangeBonus = 0
    self.activeOrbs = {}
    self.maxOrbs = 2
    self.orbitalRadius = 60
    self.orbitalSpeed = 2  -- Degrees per frame
end

function SingularityCore:fire()
    -- Clean up inactive orbs
    for i = #self.activeOrbs, 1, -1 do
        if not self.activeOrbs[i].active then
            table.remove(self.activeOrbs, i)
        end
    end

    -- Only spawn if under max orbs
    if #self.activeOrbs >= self.maxOrbs then
        return
    end

    -- Create orbital projectile
    local orb = self:createOrbitalProjectile()
    if orb then
        table.insert(self.activeOrbs, orb)
    end
end

function SingularityCore:createOrbitalProjectile()
    -- Calculate starting position
    local startAngle = math.random() * 360
    local radius = self.orbitalRadius * (1 + self.orbitalRangeBonus)
    local rad = math.rad(startAngle)
    local x = Constants.STATION_CENTER_X + math.cos(rad) * radius
    local y = Constants.STATION_CENTER_Y + math.sin(rad) * radius

    -- Create projectile
    local proj = GameplayScene:createProjectile(
        x, y, startAngle,
        0,  -- No forward speed
        self.damage,
        self.data.projectileImage,
        true  -- Piercing (damages multiple enemies)
    )

    if proj then
        -- Set up orbital behavior
        proj.isOrbital = true
        proj.orbitalAngle = startAngle
        proj.orbitalRadius = radius
        proj.orbitalSpeed = self.orbitalSpeed
        proj.orbitalLifetime = 0
        proj.maxOrbitalLifetime = 300  -- 10 seconds at 30fps
        proj.damageTickTimer = 0
        proj.damageTickInterval = 10  -- Damage every 10 frames (3x per second)
        proj.maxHits = 999  -- Unlimited hits

        -- Override update for orbital behavior
        proj.update = function(self)
            if not self.active then return end

            if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
                return
            end

            -- Update lifetime
            self.orbitalLifetime = self.orbitalLifetime + 1
            if self.orbitalLifetime > self.maxOrbitalLifetime then
                self:deactivate()
                return
            end

            -- Update orbital position
            self.orbitalAngle = self.orbitalAngle + self.orbitalSpeed
            local rad = math.rad(self.orbitalAngle)
            self.x = Constants.STATION_CENTER_X + math.cos(rad) * self.orbitalRadius
            self.y = Constants.STATION_CENTER_Y + math.sin(rad) * self.orbitalRadius
            self:moveTo(self.x, self.y)

            -- Update rotation for visual effect
            self:setRotation(self.orbitalAngle)

            -- Damage tick timer (prevents instant multi-hit)
            if self.damageTickTimer > 0 then
                self.damageTickTimer = self.damageTickTimer - 1
            end
        end

        -- Override onHit to reset damage tick
        local originalOnHit = proj.onHit
        proj.onHit = function(self, target)
            if self.damageTickTimer <= 0 then
                self.damageTickTimer = self.damageTickInterval
                -- Don't deactivate - orbital continues
            end
        end
    end

    return proj
end

function SingularityCore:upgrade(bonusItem)
    local success = SingularityCore.super.upgrade(self, bonusItem)
    if success then
        self.maxOrbs = 3
        self.orbitalSpeed = 3
    end
    return success
end
