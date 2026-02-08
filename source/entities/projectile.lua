-- Projectile Entity
-- Fired by tools, damages MOBs
-- NOT in sprite system: drawn manually by GameplayScene for performance

local gfx <const> = playdate.graphics

-- Localize math functions for performance
local math_min <const> = math.min
local math_floor <const> = math.floor

-- Module-level cache for pre-rotated projectile images (shared across instances by imagePath+inverted)
local PROJ_ROTATION_CACHE = {}

local function getProjectileRotationCache(baseImg, cacheKey)
    if PROJ_ROTATION_CACHE[cacheKey] then
        return PROJ_ROTATION_CACHE[cacheKey]
    end

    local images = {}
    local offsets = {}
    local angleStep = 360 / Utils.ROTATION_STEPS
    for step = 0, Utils.ROTATION_STEPS - 1 do
        local angle = step * angleStep
        local rimg = baseImg:rotatedImage(angle)
        images[step] = rimg
        local rw, rh = rimg:getSize()
        offsets[step] = { math_floor(rw / 2), math_floor(rh / 2) }
    end

    local cache = { images = images, offsets = offsets }
    PROJ_ROTATION_CACHE[cacheKey] = cache
    return cache
end

class('Projectile').extends(Entity)

-- Monotonically increasing ID for stable collision frame cycling
Projectile._nextId = 0

-- Clear rotation caches (call between episodes to free memory)
function Projectile.clearRotationCache()
    for k in pairs(PROJ_ROTATION_CACHE) do
        PROJ_ROTATION_CACHE[k] = nil
    end
end

function Projectile:init()
    Projectile.super.init(self, 0, 0, nil)

    -- Projectile properties
    self.speed = 10
    self.damage = 1
    self.angle = 0
    self.piercing = false
    self.hitCount = 0
    self.maxHits = 1
    self.damageType = nil  -- "electric" for Tesla Coil projectiles

    -- Stable ID for collision frame cycling (assigned at reset)
    self._collisionId = 0

    -- Movement direction
    self.dx = 0
    self.dy = 0

    -- Track frames since spawn for collision grace period
    self.framesAlive = 0

    -- Manual drawing data (not in sprite system for performance)
    self.drawImage = nil
    self.drawRotation = 0
    self._drawHalfW = 4
    self._drawHalfH = 4
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

    -- Track spawn position for minimum travel distance check
    self.spawnX = x
    self.spawnY = y

    -- Reset frames alive counter (for collision grace period)
    self.framesAlive = 0

    -- Assign stable collision ID (survives swap-and-pop, unlike array index)
    Projectile._nextId = Projectile._nextId + 1
    self._collisionId = Projectile._nextId

    -- Parse options
    options = options or {}
    local inverted = options.inverted or false
    local rotationOffset = options.rotationOffset or -90  -- Default: sprites face RIGHT
    self.damageType = options.damageType or nil  -- e.g. "electric" for Tesla Coil

    -- Calculate direction
    self.dx, self.dy = Utils.angleToVector(angle)

    -- Load image and pre-cache rotated version (avoids runtime drawRotated)
    if imagePath then
        local cacheKey = imagePath .. (inverted and "_inv" or "")
        local img = Utils.imageCache[cacheKey]
        if not img then
            img = gfx.image.new(imagePath)
            if img and inverted then
                img = img:invertedImage()
            end
            Utils.imageCache[cacheKey] = img
        end

        -- Use pre-cached rotated image instead of runtime drawRotated()
        local displayAngle = angle + rotationOffset
        if img then
            local rotCache = getProjectileRotationCache(img, cacheKey)
            local step = Utils.getRotationStep(displayAngle)
            self.drawImage = rotCache.images[step]
            local off = rotCache.offsets[step]
            self._drawHalfW = off[1]
            self._drawHalfH = off[2]
            -- Store for homing projectiles that need to update drawImage mid-flight
            self._rotCache = rotCache
            self._lastRotStep = step
        else
            self.drawImage = nil
            self._rotCache = nil
        end
    end

    -- Store rotation (used by collision system, not drawing)
    self.drawRotation = angle + rotationOffset
end

-- Global frame counter (used by collectibles for throttling and tool-specific updates)
Projectile.frameCounter = 0

function Projectile.incrementFrameCounter()
    Projectile.frameCounter = Projectile.frameCounter + 1
end

function Projectile:update()
    if not self.active then return end

    -- Track frames alive for collision grace period
    self.framesAlive = self.framesAlive + 1

    -- Move in direction
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed

    -- Inline isOnScreen check (avoids method call + Utils table lookup)
    local px, py = self.x, self.y
    if px < -20 or px > 420 or py < -20 or py > 260 then
        self:deactivate("offscreen")
    end
end

-- Called when projectile hits something
function Projectile:onHit(target)
    self.hitCount = self.hitCount + 1

    -- Deactivate if max hits reached
    if self.hitCount >= self.maxHits then
        self:deactivate("hit_max")
    end
end

-- Deactivate for pooling (no sprite system removal needed)
function Projectile:deactivate(reason)
    self.active = false
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

    Utils.debugPrint("ProjectilePool initialized with " .. initialSize .. " projectiles")
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
        -- Only print warning occasionally to avoid log spam
        self.exhaustedCount = (self.exhaustedCount or 0) + 1
        if self.exhaustedCount <= 5 or self.exhaustedCount % 50 == 0 then
            Utils.debugPrint("ProjectilePool: Created new projectile (pool exhausted, count: " .. self.exhaustedCount .. ")")
        end
    end

    -- Reset and configure
    proj:reset(x, y, angle, speed, damage, imagePath, piercing, options)

    -- Add to active list with index tracking (O(1) release later)
    local idx = #self.active + 1
    self.active[idx] = proj
    proj._poolIndex = idx

    return proj
end

-- Return a projectile to the pool (O(1) swap-and-pop using tracked index)
function ProjectilePool:release(proj)
    proj:deactivate()

    local active = self.active
    local idx = proj._poolIndex
    local n = #active

    if idx and idx <= n and active[idx] == proj then
        -- Swap with last element and pop
        if idx < n then
            local swapped = active[n]
            active[idx] = swapped
            swapped._poolIndex = idx
        end
        active[n] = nil
    end

    -- Return to pool
    self.pool[#self.pool + 1] = proj
end

-- Update all active projectiles (swap-and-pop for O(1) removal)
function ProjectilePool:update()
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    local active = self.active
    local pool = self.pool
    local n = #active
    local i = 1

    while i <= n do
        local proj = active[i]
        if proj.active then
            proj:update()
            i = i + 1
        else
            -- Swap-and-pop: O(1) removal
            if i < n then
                local swapped = active[n]
                active[i] = swapped
                swapped._poolIndex = i
            end
            active[n] = nil
            n = n - 1
            pool[#pool + 1] = proj
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
-- NOT in sprite system: drawn manually by GameplayScene
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

    -- Manual drawing data (not in sprite system for performance)
    self.drawImage = nil
    self.drawRotation = 0
    self._drawHalfW = 4
    self._drawHalfH = 4
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

    -- Load image and pre-cache rotated version (avoids runtime drawRotated)
    if imagePath then
        local img = Utils.getCachedImage(imagePath)
        local displayAngle = angle - 90
        if img then
            local rotCache = getProjectileRotationCache(img, imagePath)
            local step = Utils.getRotationStep(displayAngle)
            self.drawImage = rotCache.images[step]
            local off = rotCache.offsets[step]
            self._drawHalfW = off[1]
            self._drawHalfH = off[2]
        else
            self.drawImage = nil
        end
    end

    -- Store rotation (used by collision system, not drawing)
    self.drawRotation = angle - 90
end

function EnemyProjectile:update()
    if not self.active then return end

    -- Move in direction
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed

    -- Inline isOnScreen check
    local px, py = self.x, self.y
    if px < -20 or px > 420 or py < -20 or py > 260 then
        self:deactivate()
    end
end

-- Deactivate for pooling (no sprite system removal needed)
function EnemyProjectile:deactivate()
    self.active = false
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

    Utils.debugPrint("EnemyProjectilePool initialized with " .. initialSize .. " projectiles")
end

function EnemyProjectilePool:get(x, y, angle, speed, damage, imagePath, effect)
    local proj

    if #self.pool > 0 then
        proj = table.remove(self.pool)
    else
        proj = EnemyProjectile()
    end

    proj:reset(x, y, angle, speed, damage, imagePath, effect)
    -- Direct assignment faster than table.insert
    self.active[#self.active + 1] = proj

    return proj
end

function EnemyProjectilePool:update()
    -- Move pause check outside loop (optimization: avoid checking for each projectile)
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    local active = self.active
    local pool = self.pool
    local n = #active
    local i = 1

    while i <= n do
        local proj = active[i]
        if proj.active then
            proj:update()
            i = i + 1
        else
            -- Swap-and-pop: O(1) removal
            active[i] = active[n]
            active[n] = nil
            n = n - 1
            pool[#pool + 1] = proj
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
