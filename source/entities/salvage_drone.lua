-- Salvage Drone Entity
-- A small drone that flies around collecting RP collectibles for the player
-- NOT in sprite system: drawn manually by GameplayScene in drawOverlay()

local gfx <const> = playdate.graphics
local math_floor <const> = math.floor
local math_sqrt <const> = math.sqrt
local math_cos <const> = math.cos
local math_sin <const> = math.sin
local math_rad <const> = math.rad
local math_deg <const> = math.deg
local math_atan <const> = math.atan
local math_ceil <const> = math.ceil

class('SalvageDrone').extends()

function SalvageDrone:init()
    -- Create a visible drone image (20x20)
    local img = gfx.image.new(20, 20)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorWhite)
    -- Draw a small drone shape: body circle with "wings"
    gfx.fillCircleAtPoint(10, 10, 6)
    -- Draw wing lines
    gfx.setLineWidth(2)
    gfx.drawLine(2, 10, 6, 10)   -- Left wing
    gfx.drawLine(14, 10, 18, 10) -- Right wing
    gfx.drawLine(10, 2, 10, 6)   -- Top antenna
    -- Outline for visibility
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawCircleAtPoint(10, 10, 6)
    gfx.popContext()

    -- Manual drawing data (matches game entity pattern)
    self.drawImage = img
    self._drawHalfW = 10
    self._drawHalfH = 10

    -- Position near station initially
    self.x = Constants.STATION_CENTER_X + 40
    self.y = Constants.STATION_CENTER_Y

    -- Movement properties
    self.speed = 6.0          -- Faster movement speed for quicker collection
    self.targetCollectible = nil
    self.orbitAngle = 0       -- For orbiting when no target
    self.orbitRadius = 60     -- Orbit slightly further out for visibility
    self.orbitSpeed = 3       -- Degrees per frame (faster for visibility)

    -- Collection properties
    self.collectRadius = 16   -- Larger collection radius
    self.searchRadius = 400   -- Search the entire screen

    self.active = true
end

function SalvageDrone:update()
    if not self.active then return end

    -- Don't update if game is paused
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Clear stale target immediately if it's no longer active
    if self.targetCollectible and not self.targetCollectible.active then
        self.targetCollectible = nil
    end

    -- Find a target if we don't have one (throttled search - every 5 frames)
    if not self.targetCollectible then
        self.searchCooldown = (self.searchCooldown or 0) - 1
        if self.searchCooldown <= 0 then
            self.targetCollectible = self:findClosestCollectible()
            self.searchCooldown = 5  -- Only search every 5 frames
        end
    end

    if self.targetCollectible and self.targetCollectible.active then
        -- Move toward target
        local dx = self.targetCollectible.x - self.x
        local dy = self.targetCollectible.y - self.y
        local distSq = dx * dx + dy * dy
        local collectRadiusSq = self.collectRadius * self.collectRadius

        if distSq < collectRadiusSq then
            -- Collect it!
            self:collectTarget()
        elseif distSq > 0 then
            -- Move toward target (only calculate sqrt when needed)
            local invDist = 1 / math_sqrt(distSq)
            local moveX = dx * invDist * self.speed
            local moveY = dy * invDist * self.speed
            self.x = self.x + moveX
            self.y = self.y + moveY
        end
    else
        -- No target - orbit around station
        self:orbitStation()
    end
end

function SalvageDrone:findClosestCollectible()
    if not GameplayScene then return nil end

    local searchRadiusSq = self.searchRadius * self.searchRadius

    -- Priority 1: Pickup items (only when close to station - let player see them first)
    if GameplayScene.pickups then
        local pickups = GameplayScene.pickups
        local count = #pickups
        local closestDistSq = searchRadiusSq
        local closest = nil
        -- Only grab pickups within 95px of station center (~50px outside collection zone)
        local stationX = Constants.STATION_CENTER_X
        local stationY = Constants.STATION_CENTER_Y
        local pickupGrabRadiusSq = 95 * 95

        for i = 1, count do
            local pickup = pickups[i]
            if pickup.active then
                -- Check if pickup is close enough to station
                local psx = pickup.x - stationX
                local psy = pickup.y - stationY
                local stationDistSq = psx * psx + psy * psy
                if stationDistSq < pickupGrabRadiusSq then
                    local dx = self.x - pickup.x
                    local dy = self.y - pickup.y
                    local distSq = dx * dx + dy * dy
                    if distSq < closestDistSq then
                        closestDistSq = distSq
                        closest = pickup
                    end
                end
            end
        end

        if closest then return closest end
    end

    -- Priority 2: RP collectibles
    if not GameplayScene.collectibles then return nil end

    local closest = nil
    local closestDistSq = searchRadiusSq

    local collectibles = GameplayScene.collectibles
    local count = #collectibles
    for i = 1, count do
        local collectible = collectibles[i]
        if collectible.active then
            local cdx = self.x - collectible.x
            local cdy = self.y - collectible.y
            local distSq = cdx * cdx + cdy * cdy
            if distSq < closestDistSq then
                closestDistSq = distSq
                closest = collectible
            end
        end
    end

    return closest
end

function SalvageDrone:collectTarget()
    if not self.targetCollectible then return end

    local collectible = self.targetCollectible
    self.targetCollectible = nil

    -- Guard: ensure collectible is still active (may have been collected elsewhere)
    if not collectible.active then return end

    -- Handle Pickup items (distinguished by pickupRadius field)
    if collectible.pickupRadius then
        collectible:collect()
        return
    end

    -- Only do special handling for RP collectibles
    if collectible.collectibleType == Collectible.TYPES.RP then
        -- Play collect sound
        if AudioManager then
            AudioManager:playSFX("collectible_get", 0.3)
        end

        local rpValue = collectible.value or 1

        -- Check if station needs health
        local station = GameplayScene and GameplayScene.station
        if station and station.health < station.maxHealth then
            -- Convert 25% of RP to health
            local healthAmount = math_ceil(rpValue * 0.25)
            local rpAmount = math_floor(rpValue * 0.75)

            -- Heal station (cap at max health)
            station:heal(healthAmount)

            -- Award reduced RP
            if GameManager and rpAmount > 0 then
                GameManager:awardRP(rpAmount)
            end
        else
            -- Station at full health - award full RP
            if GameManager then
                GameManager:awardRP(rpValue)
            end
        end

        -- Mark collectible as inactive (consistent with Collectible:collect())
        collectible.active = false
        collectible.drawVisible = false
    else
        -- For non-RP collectibles (health, etc.), use normal collection
        collectible:collect(true)
    end
end

function SalvageDrone:orbitStation()
    -- Orbit around the station when there's nothing to collect
    self.orbitAngle = self.orbitAngle + self.orbitSpeed
    if self.orbitAngle >= 360 then
        self.orbitAngle = self.orbitAngle - 360
    end

    local rad = math_rad(self.orbitAngle)
    local targetX = Constants.STATION_CENTER_X + math_cos(rad) * self.orbitRadius
    local targetY = Constants.STATION_CENTER_Y + math_sin(rad) * self.orbitRadius

    -- Smoothly move toward orbit position
    self.x = self.x + (targetX - self.x) * 0.1
    self.y = self.y + (targetY - self.y) * 0.1
end

function SalvageDrone:deactivate()
    self.active = false
end

return SalvageDrone
