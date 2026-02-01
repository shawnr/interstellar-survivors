-- Projectile Entity
-- Fired by tools, damages MOBs

local gfx <const> = playdate.graphics

class('Projectile').extends(Entity)

function Projectile:init()
    Projectile.super.init(self, 0, 0, nil)

    -- Projectile properties
    self.speed = 10
    self.damage = 1
    self.angle = 0
    self.piercing = false
    self.hitCount = 0
    self.maxHits = 1

    -- Movement direction
    self.dx = 0
    self.dy = 0

    -- Set center point FIRST
    self:setCenter(0.5, 0.5)

    -- Set Z-index (projectiles above most things)
    self:setZIndex(200)

    -- Collision rect (small)
    self:setCollideRect(0, 0, 8, 8)
end

-- Reset projectile for reuse (object pooling)
-- options: { inverted = bool, rotationOffset = number }
function Projectile:reset(x, y, angle, speed, damage, imagePath, piercing, options)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed or 10
    self.damage = damage or 1
    self.piercing = piercing or false
    self.hitCount = 0
    self.maxHits = self.piercing and 2 or 1
    self.active = true

    -- Parse options
    options = options or {}
    local inverted = options.inverted or false
    local rotationOffset = options.rotationOffset or -90  -- Default: sprites face RIGHT

    -- Calculate direction
    self.dx, self.dy = Utils.angleToVector(angle)

    -- Load image
    if imagePath then
        local img = gfx.image.new(imagePath)
        if img then
            -- Invert image colors if requested (for visibility on dark backgrounds)
            if inverted then
                img = img:invertedImage()
            end
            self:setImage(img)
        end
    end

    -- Position and rotate
    self:moveTo(x, y)
    -- Projectile sprites are drawn facing RIGHT, but game uses 0°=UP coordinate system
    -- Use rotationOffset to align sprite with movement direction (default -90°)
    self:setRotation(angle + rotationOffset)

    -- Add to sprite system
    self:add()
end

function Projectile:update()
    if not self.active then return end

    -- Don't update if game is paused/leveling up
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Move in direction
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed
    self:moveTo(self.x, self.y)

    -- Check if off screen
    if not self:isOnScreen(20) then
        self:deactivate()
    end
end

-- Called when projectile hits something
function Projectile:onHit(target)
    self.hitCount = self.hitCount + 1

    -- Deactivate if max hits reached
    if self.hitCount >= self.maxHits then
        self:deactivate()
    end
end

-- Deactivate for pooling
function Projectile:deactivate()
    self.active = false
    self:remove()
end

-- Get damage value
function Projectile:getDamage()
    return self.damage
end


-- ============================================
-- Projectile Pool (Object Pooling)
-- ============================================

class('ProjectilePool').extends()

function ProjectilePool:init(initialSize)
    self.pool = {}      -- Inactive projectiles
    self.active = {}    -- Active projectiles

    -- Pre-allocate projectiles
    initialSize = initialSize or Constants.MAX_ACTIVE_PROJECTILES
    for i = 1, initialSize do
        local proj = Projectile()
        proj.active = false
        table.insert(self.pool, proj)
    end

    print("ProjectilePool initialized with " .. initialSize .. " projectiles")
end

-- Get a projectile from the pool
-- options: { inverted = bool, rotationOffset = number }
function ProjectilePool:get(x, y, angle, speed, damage, imagePath, piercing, options)
    local proj

    if #self.pool > 0 then
        -- Reuse from pool
        proj = table.remove(self.pool)
    else
        -- Create new if pool empty
        proj = Projectile()
        print("ProjectilePool: Created new projectile (pool exhausted)")
    end

    -- Reset and configure
    proj:reset(x, y, angle, speed, damage, imagePath, piercing, options)

    -- Add to active list
    table.insert(self.active, proj)

    return proj
end

-- Return a projectile to the pool
function ProjectilePool:release(proj)
    proj:deactivate()

    -- Remove from active list
    for i = #self.active, 1, -1 do
        if self.active[i] == proj then
            table.remove(self.active, i)
            break
        end
    end

    -- Return to pool
    table.insert(self.pool, proj)
end

-- Update all active projectiles
function ProjectilePool:update()
    for i = #self.active, 1, -1 do
        local proj = self.active[i]
        if proj.active then
            local success, err = pcall(function()
                proj:update()
            end)
            if not success then
                print("ERROR updating projectile " .. i .. ": " .. tostring(err))
                proj:deactivate()
            end
        else
            -- Return inactive projectiles to pool
            table.remove(self.active, i)
            table.insert(self.pool, proj)
        end
    end
end

-- Get all active projectiles
function ProjectilePool:getActive()
    return self.active
end

-- Get count of active projectiles
function ProjectilePool:getActiveCount()
    return #self.active
end

-- Release all projectiles
function ProjectilePool:releaseAll()
    for i = #self.active, 1, -1 do
        local proj = self.active[i]
        proj:deactivate()
        table.insert(self.pool, proj)
    end
    self.active = {}
end


-- ============================================
-- Enemy Projectile (fired by MOBs at station)
-- ============================================

class('EnemyProjectile').extends(Entity)

function EnemyProjectile:init()
    EnemyProjectile.super.init(self, 0, 0, nil)

    -- Projectile properties
    self.speed = 3
    self.damage = 1
    self.angle = 0
    self.effect = nil  -- Special effect like "slow"

    -- Movement direction
    self.dx = 0
    self.dy = 0

    -- Set center point
    self:setCenter(0.5, 0.5)

    -- Set Z-index (enemy projectiles below player projectiles)
    self:setZIndex(150)

    -- Collision rect
    self:setCollideRect(0, 0, 8, 8)
end

function EnemyProjectile:reset(x, y, angle, speed, damage, imagePath, effect)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed or 3
    self.damage = damage or 1
    self.effect = effect
    self.active = true

    -- Calculate direction
    self.dx, self.dy = Utils.angleToVector(angle)

    -- Load image
    if imagePath then
        local img = gfx.image.new(imagePath)
        if img then
            self:setImage(img)
        end
    end

    -- Position and rotate
    self:moveTo(x, y)
    self:setRotation(angle - 90)

    -- Add to sprite system
    self:add()
end

function EnemyProjectile:update()
    if not self.active then return end

    -- Don't update if game is paused
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Move in direction
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed
    self:moveTo(self.x, self.y)

    -- Check if off screen
    if not self:isOnScreen(20) then
        self:deactivate()
    end
end

function EnemyProjectile:deactivate()
    self.active = false
    self:remove()
end

function EnemyProjectile:getDamage()
    return self.damage
end

function EnemyProjectile:getEffect()
    return self.effect
end


-- ============================================
-- Enemy Projectile Pool
-- ============================================

class('EnemyProjectilePool').extends()

function EnemyProjectilePool:init(initialSize)
    self.pool = {}
    self.active = {}

    initialSize = initialSize or 30
    for i = 1, initialSize do
        local proj = EnemyProjectile()
        proj.active = false
        table.insert(self.pool, proj)
    end

    print("EnemyProjectilePool initialized with " .. initialSize .. " projectiles")
end

function EnemyProjectilePool:get(x, y, angle, speed, damage, imagePath, effect)
    local proj

    if #self.pool > 0 then
        proj = table.remove(self.pool)
    else
        proj = EnemyProjectile()
    end

    proj:reset(x, y, angle, speed, damage, imagePath, effect)
    table.insert(self.active, proj)

    return proj
end

function EnemyProjectilePool:update()
    for i = #self.active, 1, -1 do
        local proj = self.active[i]
        if proj.active then
            proj:update()
        else
            table.remove(self.active, i)
            table.insert(self.pool, proj)
        end
    end
end

function EnemyProjectilePool:getActive()
    return self.active
end

function EnemyProjectilePool:releaseAll()
    for i = #self.active, 1, -1 do
        local proj = self.active[i]
        proj:deactivate()
        table.insert(self.pool, proj)
    end
    self.active = {}
end
