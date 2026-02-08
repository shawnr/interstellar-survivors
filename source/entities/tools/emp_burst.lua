-- EMP Burst Tool
-- Donut-shaped AoE: damages and scrambles mechanical mobs only (no effect on organic)

local math_floor <const> = math.floor
local math_max <const> = math.max

class('EMPBurst').extends(Tool)

EMPBurst.DATA = {
    id = "emp_burst",
    name = "EMP Burst",
    description = "EMP donut. Scrambles mechs",
    imagePath = "images/tools/tool_emp_burst",
    iconPath = "images/tools/tool_emp_burst",
    projectileImage = "images/tools/tool_emp_effect",

    baseDamage = 4,
    fireRate = 0.5,
    projectileSpeed = 0,  -- Instant radial
    pattern = "radial",
    damageType = "electric",

    pairsWithBonus = "capacitor_bank",
    upgradedName = "Ion Storm",
    upgradedImagePath = "images/tools/tool_ion_storm",
    upgradedDamage = 10,
}

function EMPBurst:init()
    EMPBurst.super.init(self, EMPBurst.DATA)
    self.innerRadius = 45         -- Safe zone (station + tools + shield)
    self.donutThickness = 50      -- Base donut width
    self.thicknessPerLevel = 15   -- +15px per level
end

function EMPBurst:fire()
    local thickness = self.donutThickness + (self.level - 1) * self.thicknessPerLevel
    local outerR = self.innerRadius + thickness

    -- Apply donut AoE damage
    self:burstDamage(self.innerRadius, outerR)

    -- Create donut particle visual effect centered on station
    if GameplayScene and GameplayScene.createEMPEffect then
        local cx = self.station and self.station.x or self.x
        local cy = self.station and self.station.y or self.y
        GameplayScene:createEMPEffect(cx, cy, self.innerRadius, outerR, 0.5)
    end
end

function EMPBurst:burstDamage(innerR, outerR)
    if not GameplayScene or not GameplayScene.mobs then return end

    local mobs = GameplayScene.mobs
    local mobCount = #mobs
    local innerRSq = innerR * innerR
    local outerRSq = outerR * outerR
    local cx = self.station and self.station.x or self.x
    local cy = self.station and self.station.y or self.y
    local damage = self.damage

    for i = 1, mobCount do
        local mob = mobs[i]
        if mob.active then
            local dx = mob.x - cx
            local dy = mob.y - cy
            local distSq = dx * dx + dy * dy
            -- Only damage mobs inside the donut (between inner and outer radius)
            if distSq >= innerRSq and distSq <= outerRSq and not mob.electricImmune then
                if mob.isMechanical then
                    -- Mechanical: 2x damage + scramble
                    mob:takeDamage(damage * 2)
                    if mob.applyScramble then
                        mob:applyScramble(1.0)
                    end
                end
                -- Non-mechanical mobs: no effect (EMP only affects electronics)
            end
        end
    end
end

function EMPBurst:upgrade(bonusItem)
    local success = EMPBurst.super.upgrade(self, bonusItem)
    if success then
        -- Evolved: covers whole game field
        self.donutThickness = 210  -- outer = 45 + 210 = 255
    end
    return success
end
