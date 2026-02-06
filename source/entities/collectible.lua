-- Collectible Entity
-- Items dropped by MOBs that can be collected

local gfx <const> = playdate.graphics

class('Collectible').extends(gfx.sprite)

-- Collectible types
Collectible.TYPES = {
    RP = "rp",              -- Research Points (XP)
    HEALTH = "health",      -- Heals station
    MAGNET = "magnet",      -- Pulls all collectibles
}

function Collectible:init(x, y, collectibleType, value)
    Collectible.super.init(self)

    -- Properties
    self.collectibleType = collectibleType or Collectible.TYPES.RP
    self.value = value or 1
    self.active = true

    -- Position
    self.x = x
    self.y = y

    -- Movement
    self.speed = 0.5           -- Initial drift speed
    self.maxSpeed = 4          -- Max collection speed
    self.passiveDrift = 0.08   -- Very slow drift toward station (for RP)

    -- Apply collect range bonus from research specs
    local baseCollectRadius = 50
    local rangeBonus = 0
    if ResearchSpecSystem then
        rangeBonus = ResearchSpecSystem:getCollectRangeBonus()
    end
    self.collectRadius = baseCollectRadius * (1 + rangeBonus)
    self.pickupRadius = 45     -- Station auto-collects at this distance (near station edge)

    -- Animation
    self.bobOffset = math.random() * math.pi * 2  -- Random start phase
    self.bobSpeed = 5
    self.bobAmount = 2

    -- Lifetime (despawn after a while if not collected)
    self.lifetime = 15  -- seconds
    self.age = 0

    -- Create visual based on type
    self:createVisual()

    -- Set center and position
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(75)  -- Above mobs, below projectiles

    -- Add to sprite system
    self:add()
end

function Collectible:createVisual()
    -- Create a simple circle for now
    local size = 8
    local img = gfx.image.new(size, size)

    gfx.pushContext(img)
    gfx.setColor(gfx.kColorWhite)

    if self.collectibleType == Collectible.TYPES.RP then
        -- RP orb: filled circle with dot
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 1)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(size/2, size/2, 2)
    elseif self.collectibleType == Collectible.TYPES.HEALTH then
        -- Health: cross/plus shape
        gfx.fillRect(2, size/2 - 1, size - 4, 2)
        gfx.fillRect(size/2 - 1, 2, 2, size - 4)
    else
        -- Default: simple circle
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 1)
    end

    gfx.popContext()
    self:setImage(img)
end

function Collectible:update(dt)
    if not self.active then return end

    -- Don't update if game is paused/leveling up
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    dt = dt or (1/30)

    -- Age and check lifetime
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self:collect(false)  -- Despawn without effect
        return
    end

    -- Calculate distance to station (use squared for comparisons)
    local dx = Constants.STATION_CENTER_X - self.x
    local dy = Constants.STATION_CENTER_Y - self.y
    local distSq = dx * dx + dy * dy
    local collectRadiusSq = self.collectRadius * self.collectRadius
    local pickupRadiusSq = self.pickupRadius * self.pickupRadius

    -- Move toward station
    if distSq > 1 then
        if distSq < collectRadiusSq then
            -- Within collect radius: accelerate toward station
            local dist = math.sqrt(distSq)  -- Only sqrt when needed
            local speedMult = 1 + (1 - dist / self.collectRadius) * 3
            local currentSpeed = math.min(self.speed * speedMult, self.maxSpeed)
            local invDist = 1 / dist
            self.x = self.x + dx * invDist * currentSpeed
            self.y = self.y + dy * invDist * currentSpeed
        elseif self.collectibleType == Collectible.TYPES.RP then
            -- RP collectibles: very slow passive drift toward station
            local invDist = 1 / math.sqrt(distSq)  -- Only sqrt when needed
            self.x = self.x + dx * invDist * self.passiveDrift
            self.y = self.y + dy * invDist * self.passiveDrift
        end
    end

    -- Bobbing animation
    local bob = math.sin(self.age * self.bobSpeed + self.bobOffset) * self.bobAmount
    self:moveTo(self.x, self.y + bob)

    -- Check for pickup
    if distSq < pickupRadiusSq then
        self:collect(true)
    end

    -- Fade out near end of lifetime
    if self.age > self.lifetime - 2 then
        -- Blink effect
        local blinkRate = 10
        if math.floor(self.age * blinkRate) % 2 == 0 then
            self:setVisible(true)
        else
            self:setVisible(false)
        end
    end
end

function Collectible:collect(applyEffect)
    if not self.active then return end

    self.active = false

    if applyEffect then
        -- Play collect sound
        if AudioManager then
            if self.collectibleType == Collectible.TYPES.HEALTH then
                AudioManager:playSFX("collectible_rare", 0.6)
            else
                AudioManager:playSFX("collectible_get", 0.3)
            end
        end

        if self.collectibleType == Collectible.TYPES.RP then
            -- Award RP
            if GameManager then
                GameManager:awardRP(self.value)
            end
        elseif self.collectibleType == Collectible.TYPES.HEALTH then
            -- Heal station
            if GameplayScene and GameplayScene.station then
                GameplayScene.station:heal(self.value)
            end
        end
    end

    -- Ensure visibility is off and remove sprite
    self:setVisible(false)
    self:remove()
end

-- Pull toward a point (for magnet effect)
function Collectible:pullToward(targetX, targetY, strength)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 1 then
        self.x = self.x + (dx / dist) * strength
        self.y = self.y + (dy / dist) * strength
    end
end

-- Reset collectible for reuse (object pooling)
-- rangeBonus: optional cached bonus from pool (avoids per-collectible lookup)
function Collectible:reset(x, y, collectibleType, value, rangeBonus)
    -- Properties
    self.collectibleType = collectibleType or Collectible.TYPES.RP
    self.value = value or 1
    self.active = true

    -- Position
    self.x = x
    self.y = y

    -- Movement
    self.speed = 0.5
    self.maxSpeed = 4
    self.passiveDrift = 0.08

    -- Apply collect range bonus (use cached bonus if provided)
    local baseCollectRadius = 50
    rangeBonus = rangeBonus or 0
    self.collectRadius = baseCollectRadius * (1 + rangeBonus)
    self.pickupRadius = 30  -- Increased for station auto-collect

    -- Animation
    self.bobOffset = math.random() * math.pi * 2
    self.bobSpeed = 5
    self.bobAmount = 2

    -- Lifetime
    self.lifetime = 15
    self.age = 0

    -- Update visual
    self:createVisual()

    -- Position and show
    self:moveTo(x, y)
    self:setVisible(true)
    self:add()
end

-- Deactivate for pooling
function Collectible:deactivate()
    self.active = false
    self:setVisible(false)
    self:remove()
end


-- ============================================
-- Collectible Pool (Object Pooling)
-- ============================================

class('CollectiblePool').extends()

function CollectiblePool:init(initialSize)
    self.pool = {}      -- Inactive collectibles
    self.active = {}    -- Active collectibles

    -- Cached range bonus (updated once per frame for performance)
    self.cachedRangeBonus = 0
    self.rangeBonusCacheTime = 0

    -- Pre-allocate collectibles
    initialSize = initialSize or 100
    for i = 1, initialSize do
        local c = Collectible(0, 0, Collectible.TYPES.RP, 1)
        c.active = false
        c:setVisible(false)  -- Ensure hidden
        c:remove()  -- Remove from sprite system initially
        table.insert(self.pool, c)
    end

    Utils.debugPrint("CollectiblePool initialized with " .. initialSize .. " collectibles")
end

-- Get a collectible from the pool
function CollectiblePool:get(x, y, collectibleType, value)
    local c

    if #self.pool > 0 then
        -- Reuse from pool
        c = table.remove(self.pool)
    else
        -- Create new if pool empty
        c = Collectible(0, 0, Collectible.TYPES.RP, 1)
        c.active = false
        c:setVisible(false)
        c:remove()
        Utils.debugPrint("CollectiblePool: Created new collectible (pool exhausted)")
    end

    -- Reset and configure (pass cached range bonus)
    c:reset(x, y, collectibleType, value, self.cachedRangeBonus)

    -- Add to active list
    table.insert(self.active, c)

    return c
end

-- Update cached range bonus (call once per frame)
function CollectiblePool:updateRangeBonusCache()
    if ResearchSpecSystem then
        self.cachedRangeBonus = ResearchSpecSystem:getCollectRangeBonus()
    else
        self.cachedRangeBonus = 0
    end
end

-- Get the cached range bonus
function CollectiblePool:getRangeBonus()
    return self.cachedRangeBonus
end

-- Merge nearby RP orbs to reduce collectible count
-- Only checks a limited number of orbs per frame for performance
function CollectiblePool:mergeNearbyOrbs()
    local active = self.active
    local n = #active
    if n < 2 then return end

    local mergeDistSq = 20 * 20  -- Orbs within 20px merge
    local maxChecks = math.min(10, n)  -- Check up to 10 orbs per frame
    local startIdx = (self.mergeCheckOffset or 0) + 1

    for checkNum = 1, maxChecks do
        local i = ((startIdx + checkNum - 2) % n) + 1
        local orb1 = active[i]

        -- Only process active RP orbs
        if orb1 and orb1.active and orb1.collectibleType == Collectible.TYPES.RP then
            -- Check nearby orbs (only look at a few neighbors)
            for j = i + 1, math.min(i + 5, n) do
                local orb2 = active[j]
                if orb2 and orb2.active and orb2.collectibleType == Collectible.TYPES.RP then
                    local dx = orb2.x - orb1.x
                    local dy = orb2.y - orb1.y
                    local distSq = dx * dx + dy * dy

                    if distSq < mergeDistSq then
                        -- Merge: add orb2's value to orb1, deactivate orb2
                        orb1.value = orb1.value + orb2.value
                        orb2.active = false
                        orb2:setVisible(false)
                        orb2:remove()
                    end
                end
            end
        end
    end

    -- Rotate starting point for next frame
    self.mergeCheckOffset = (startIdx + maxChecks - 1) % n
end

-- Update all active collectibles (swap-and-pop for O(1) removal)
function CollectiblePool:update(dt)
    -- Update range bonus cache once per frame
    self:updateRangeBonusCache()

    -- Merge nearby RP orbs (reduces collectible count over time)
    self:mergeNearbyOrbs()

    local active = self.active
    local pool = self.pool
    local n = #active
    local i = 1

    while i <= n do
        local c = active[i]
        if c.active then
            c:update(dt)
            i = i + 1
        else
            -- Swap-and-pop: O(1) removal instead of O(n) table.remove
            active[i] = active[n]
            active[n] = nil
            n = n - 1
            pool[#pool + 1] = c
        end
    end
end

-- Get all active collectibles
function CollectiblePool:getActive()
    return self.active
end

-- Get count of active collectibles
function CollectiblePool:getActiveCount()
    return #self.active
end

-- Release all collectibles
function CollectiblePool:releaseAll()
    for i = #self.active, 1, -1 do
        local c = self.active[i]
        c:deactivate()
        table.insert(self.pool, c)
    end
    self.active = {}
end

return Collectible
