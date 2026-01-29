-- Station Entity
-- The player's space station that rotates with the crank

local gfx <const> = playdate.graphics

class('Station').extends(Entity)

function Station:init()
    -- Initialize base entity (without position yet)
    Station.super.init(self, 0, 0, "images/shared/station_base")

    -- Calculate max health with research spec bonuses
    local baseHealth = Constants.STATION_BASE_HEALTH
    local healthBonus = 0
    local startingHealthBonus = 0

    if ResearchSpecSystem then
        healthBonus = ResearchSpecSystem:getStationHealthBonus()
        startingHealthBonus = ResearchSpecSystem:getStartingHealth()
    end

    -- Apply percentage bonus and flat bonus
    self.maxHealth = math.floor(baseHealth * (1 + healthBonus)) + startingHealthBonus
    self.health = self.maxHealth

    -- Rotation (controlled by crank)
    self.currentRotation = 0

    -- Tools attached to station
    self.tools = {}
    self.usedSlots = {}

    -- Damage state tracking
    self.damageState = 0  -- 0 = healthy, 1 = damaged, 2 = critical

    -- Debuff tracking
    self.rotationSlow = 1.0        -- Rotation speed multiplier (1.0 = normal)
    self.rotationSlowTimer = 0     -- Time remaining on slow effect

    -- Set center point FIRST (0.5, 0.5 = center of sprite)
    self:setCenter(0.5, 0.5)

    -- Set up collision (circular)
    self:setCollideRect(0, 0, 64, 64)

    -- NOW position at screen center
    self.x = Constants.STATION_CENTER_X
    self.y = Constants.STATION_CENTER_Y
    self:moveTo(self.x, self.y)

    -- Set Z-index (station should be behind tools)
    self:setZIndex(100)

    -- Add to sprite system
    self:add()

    print("Station initialized at " .. self.x .. ", " .. self.y)
end

function Station:update()
    local dt = 1/30

    -- Update slow timer
    if self.rotationSlowTimer > 0 then
        self.rotationSlowTimer = self.rotationSlowTimer - dt
        if self.rotationSlowTimer <= 0 then
            self.rotationSlow = 1.0  -- Reset to normal speed
        end
    end

    -- Get base rotation from input manager
    local baseRotation = InputManager:getRotation()

    -- Apply slow effect by interpolating slower toward target
    if self.rotationSlow < 1.0 then
        -- When slowed, don't follow input as quickly
        local slowedTarget = self.currentRotation + (baseRotation - self.currentRotation) * self.rotationSlow
        self.currentRotation = Utils.lerp(self.currentRotation, slowedTarget, 0.5)
    else
        self.currentRotation = baseRotation
    end

    -- Apply rotation to sprite
    self:setRotation(self.currentRotation)

    -- Update all attached tools
    for _, tool in ipairs(self.tools) do
        tool:updatePosition(self.currentRotation)
    end
end

-- Attach a tool to the station
function Station:attachTool(tool, slotIndex)
    -- Find next available slot if not specified
    if slotIndex == nil then
        slotIndex = self:getNextAvailableSlot()
    end

    if slotIndex == nil then
        print("No available slots for tool!")
        return false
    end

    if #self.tools >= Constants.MAX_TOOLS_PER_EPISODE then
        print("Maximum tools reached!")
        return false
    end

    -- Mark slot as used
    self.usedSlots[slotIndex] = true

    -- Configure tool with slot info
    tool.station = self
    tool.slotIndex = slotIndex
    tool.slotData = Constants.TOOL_SLOTS[slotIndex]

    -- Add tool to list
    table.insert(self.tools, tool)

    -- Position tool initially
    tool:updatePosition(self.currentRotation)

    -- Add tool to sprite system
    tool:add()

    print("Tool attached to slot " .. slotIndex)
    return true
end

-- Get next available slot
function Station:getNextAvailableSlot()
    for i = 0, Constants.STATION_SLOTS - 1 do
        if not self.usedSlots[i] then
            return i
        end
    end
    return nil
end

-- Take damage
function Station:takeDamage(amount)
    -- Check for dodge (research spec bonus)
    if ResearchSpecSystem then
        local dodgeChance = ResearchSpecSystem:getDodgeChance()
        if dodgeChance > 0 and math.random() < dodgeChance then
            -- Dodged! Play a different sound or show effect
            print("Dodged!")
            return false
        end
    end

    self.health = math.max(0, self.health - amount)

    -- Play hit sound
    if AudioManager then
        AudioManager:playSFX("station_hit", 0.7)
    end

    -- Update damage visual state
    local healthPercent = self.health / self.maxHealth

    if healthPercent <= 0.33 and self.damageState ~= 2 then
        self.damageState = 2
        local img = gfx.image.new("images/shared/station_damaged_2")
        if img then self:setImage(img) end
    elseif healthPercent <= 0.66 and healthPercent > 0.33 and self.damageState ~= 1 then
        self.damageState = 1
        local img = gfx.image.new("images/shared/station_damaged_1")
        if img then self:setImage(img) end
    end

    -- Check for destruction
    if self.health <= 0 then
        self:onDestroyed()
        return true
    end

    return false
end

-- Called when station is destroyed
function Station:onDestroyed()
    print("Station destroyed!")

    -- Play destruction sound
    if AudioManager then
        AudioManager:playSFX("station_destroyed", 1.0)
    end

    -- Remove station from sprite system
    self:remove()

    -- Trigger game over
    if GameManager then
        GameManager:endEpisode(false)
    end
end

-- Heal the station
function Station:heal(amount)
    self.health = math.min(self.maxHealth, self.health + amount)

    -- Update visual state if healed enough
    local healthPercent = self.health / self.maxHealth
    if healthPercent > 0.66 and self.damageState ~= 0 then
        self.damageState = 0
        local img = gfx.image.new("images/shared/station_base")
        if img then self:setImage(img) end
    elseif healthPercent > 0.33 and self.damageState == 2 then
        self.damageState = 1
        local img = gfx.image.new("images/shared/station_damaged_1")
        if img then self:setImage(img) end
    end
end

-- Get health percentage (0-1)
function Station:getHealthPercent()
    return self.health / self.maxHealth
end

-- Get current rotation
function Station:getRotation()
    return self.currentRotation
end

-- Get position of a specific slot (world coordinates)
function Station:getSlotPosition(slotIndex)
    local slotData = Constants.TOOL_SLOTS[slotIndex]
    if not slotData then return self.x, self.y end

    -- Calculate rotated position
    local angle = Utils.degToRad(self.currentRotation)
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    local rotatedX = slotData.x * cos - slotData.y * sin
    local rotatedY = slotData.x * sin + slotData.y * cos

    return self.x + rotatedX, self.y + rotatedY
end

-- Get firing angle for a specific slot (in game coordinate system where 0=up)
function Station:getSlotFiringAngle(slotIndex)
    local slotData = Constants.TOOL_SLOTS[slotIndex]
    if not slotData then return self.currentRotation end

    return self.currentRotation + slotData.angle
end
