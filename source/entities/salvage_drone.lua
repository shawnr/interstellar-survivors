-- Salvage Drone Entity
-- A small drone that flies around collecting RP collectibles for the player

local gfx <const> = playdate.graphics

class('SalvageDrone').extends(gfx.sprite)

function SalvageDrone:init()
    SalvageDrone.super.init(self)

    -- Create a visible drone sprite (larger, 20x20)
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
    self:setImage(img)

    self:setCenter(0.5, 0.5)
    self:setZIndex(250)  -- Above collectibles, below UI

    -- Position near station initially
    self.x = Constants.STATION_CENTER_X + 40
    self.y = Constants.STATION_CENTER_Y
    self:moveTo(self.x, self.y)

    -- Movement properties
    self.speed = 4.0          -- Movement speed
    self.targetCollectible = nil
    self.orbitAngle = 0       -- For orbiting when no target
    self.orbitRadius = 60     -- Orbit slightly further out for visibility
    self.orbitSpeed = 3       -- Degrees per frame (faster for visibility)

    -- Collection properties
    self.collectRadius = 12   -- Distance to collect (slightly larger)
    self.searchRadius = 300   -- How far to look for collectibles (larger default)

    self.active = true
end

function SalvageDrone:update()
    if not self.active then return end

    -- Don't update if game is paused
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Find a target if we don't have one (throttled search - every 5 frames)
    if not self.targetCollectible or not self.targetCollectible.active then
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
            local invDist = 1 / math.sqrt(distSq)
            local moveX = dx * invDist * self.speed
            local moveY = dy * invDist * self.speed
            self.x = self.x + moveX
            self.y = self.y + moveY
            self:moveTo(self.x, self.y)

            -- Face movement direction
            local angle = math.deg(math.atan(dy, dx))
            self:setRotation(angle)
        end
    else
        -- No target - orbit around station
        self:orbitStation()
    end
end

function SalvageDrone:findClosestCollectible()
    if not GameplayScene or not GameplayScene.collectibles then
        return nil
    end

    local closest = nil
    local closestDistSq = self.searchRadius * self.searchRadius  -- Use squared distance

    for _, collectible in ipairs(GameplayScene.collectibles) do
        if collectible.active then
            local distSq = Utils.distanceSquared(self.x, self.y, collectible.x, collectible.y)
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
            local healthAmount = math.ceil(rpValue * 0.25)
            local rpAmount = math.floor(rpValue * 0.75)

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

        -- Mark collectible as inactive and remove
        collectible.active = false
        collectible:remove()
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

    local rad = math.rad(self.orbitAngle)
    local targetX = Constants.STATION_CENTER_X + math.cos(rad) * self.orbitRadius
    local targetY = Constants.STATION_CENTER_Y + math.sin(rad) * self.orbitRadius

    -- Smoothly move toward orbit position
    self.x = self.x + (targetX - self.x) * 0.1
    self.y = self.y + (targetY - self.y) * 0.1
    self:moveTo(self.x, self.y)

    -- Face orbit direction
    self:setRotation(self.orbitAngle + 90)
end

function SalvageDrone:deactivate()
    self.active = false
    self:remove()
end

return SalvageDrone
