-- Salvage Drone Entity
-- A small drone that flies around collecting RP collectibles for the player

local gfx <const> = playdate.graphics

class('SalvageDrone').extends(gfx.sprite)

function SalvageDrone:init()
    SalvageDrone.super.init(self)

    print("SalvageDrone:init() - Creating drone")

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
    print("SalvageDrone:init() - Drone created at " .. self.x .. ", " .. self.y)
end

function SalvageDrone:update()
    if not self.active then return end

    -- Don't update if game is paused
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Find a target if we don't have one
    if not self.targetCollectible or not self.targetCollectible.active then
        self.targetCollectible = self:findClosestCollectible()
    end

    if self.targetCollectible and self.targetCollectible.active then
        -- Move toward target
        local dx = self.targetCollectible.x - self.x
        local dy = self.targetCollectible.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < self.collectRadius then
            -- Collect it!
            self:collectTarget()
        elseif dist > 0 then
            -- Move toward target
            local moveX = (dx / dist) * self.speed
            local moveY = (dy / dist) * self.speed
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
    local closestDist = self.searchRadius

    for _, collectible in ipairs(GameplayScene.collectibles) do
        if collectible.active then
            local dist = Utils.distance(self.x, self.y, collectible.x, collectible.y)
            if dist < closestDist then
                closestDist = dist
                closest = collectible
            end
        end
    end

    return closest
end

function SalvageDrone:collectTarget()
    if not self.targetCollectible then return end

    print("SalvageDrone: Collecting RP!")

    -- Get the RP value from the collectible
    local rpValue = self.targetCollectible.value or 1

    -- Add RP to player
    if GameManager then
        GameManager:addRP(rpValue)
    end

    -- Play collection sound
    if AudioManager then
        AudioManager:playSFX("collect_rp", 0.6)
    end

    -- Deactivate the collectible
    self.targetCollectible:deactivate()
    self.targetCollectible = nil
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
