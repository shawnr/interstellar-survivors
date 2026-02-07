-- Rail Driver Tool
-- Basic kinetic launcher that fires straight projectiles

local gfx <const> = playdate.graphics

-- Generate larger programmatic projectile images for better visibility
-- Drawn facing RIGHT (sprite convention: -90° rotation applied by system)
-- Base rail driver: 10x3 horizontal bar
-- Upgraded rail cannon: 14x4 horizontal bar
local function generateProjectileImage(width, height)
    local img = gfx.image.new(width, height)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, width, height)
    -- Add black border for contrast on white backgrounds
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(0, 0, width, height)
    gfx.popContext()
    return img
end

-- Module-level programmatic images (shared across all instances)
local railDriverProjImage = nil
local railCannonProjImage = nil

class('RailDriver').extends(Tool)

-- Rail Driver data
RailDriver.DATA = {
    id = "rail_driver",
    name = "Rail Driver",
    description = "Kinetic launcher for breaking asteroids",
    imagePath = "images/tools/tool_rail_driver",
    iconPath = "images/tools/tool_rail_driver",
    projectileImage = "images/tools/tool_rail_driver_projectile",

    -- Base stats (synced with tools_data.lua)
    baseDamage = 8,
    fireRate = 2.0,
    projectileSpeed = 10,
    pattern = "straight",
    damageType = "physical",

    -- Upgrade info
    pairsWithBonus = "alloy_gears",
    upgradedName = "Rail Hyper Driver",
    upgradedImagePath = "images/tools/tool_rail_cannon",
    upgradedProjectileImage = "images/tools/tool_rail_cannon_projectile",
    upgradedDamage = 20,
    upgradedSpeed = 12,
    piercing = true,       -- Upgraded version pierces through first target
}

function RailDriver:init()
    RailDriver.super.init(self, RailDriver.DATA)

    -- Rail Driver specific properties
    self.piercing = false

    -- Generate programmatic projectile images (once, shared via module locals)
    if not railDriverProjImage then
        railDriverProjImage = generateProjectileImage(10, 3)
    end
    if not railCannonProjImage then
        railCannonProjImage = generateProjectileImage(14, 4)
    end
end

-- Override createProjectile to use larger programmatic images
function RailDriver:createProjectile(x, y, angle)
    if GameplayScene and GameplayScene.projectilePool then
        -- Use programmatic image for better visibility
        local img = self.piercing and railCannonProjImage or railDriverProjImage
        local cacheKey = self.piercing and "_rail_cannon_prog" or "_rail_driver_prog"

        -- Cache the programmatic image in Utils.imageCache so the rotation cache works
        if not Utils.imageCache[cacheKey] then
            Utils.imageCache[cacheKey] = img
        end

        local projectile = GameplayScene.projectilePool:get(
            x, y, angle,
            self.projectileSpeed * (1 + (self.projectileSpeedBonus or 0)),
            self.damage,
            cacheKey,
            self.piercing
        )
        return projectile
    end
end

function RailDriver:upgrade(bonusItem)
    local success = RailDriver.super.upgrade(self, bonusItem)
    if success then
        -- Enable piercing on upgrade
        self.piercing = true
    end
    return success
end
