-- Entity Base Class
-- All game objects (station, tools, mobs, projectiles) extend this

local gfx <const> = playdate.graphics

class('Entity').extends(gfx.sprite)

function Entity:init(x, y, imagePath)
    Entity.super.init(self)

    -- Position
    self.x = x or 0
    self.y = y or 0

    -- Velocity
    self.vx = 0
    self.vy = 0

    -- State
    self.active = true
    self.rotation = 0

    -- Load image if provided
    if imagePath then
        local image = gfx.image.new(imagePath)
        if image then
            local w, h = image:getSize()
            -- Debug: Log image details including object identity
            print("  -> Loaded image: " .. imagePath)
            print("     Size: " .. w .. "x" .. h .. ", ID: " .. tostring(image))
            self:setImage(image)
        else
            print("ERROR: Could not load image: " .. imagePath)
        end
    end

    -- Position the sprite
    self:moveTo(self.x, self.y)
end

-- Update method (override in subclasses)
function Entity:update()
    -- Default: apply velocity
    if self.vx ~= 0 or self.vy ~= 0 then
        self.x = self.x + self.vx
        self.y = self.y + self.vy
        self:moveTo(self.x, self.y)
    end
end

-- Set position
function Entity:setPosition(x, y)
    self.x = x
    self.y = y
    self:moveTo(x, y)
end

-- Set velocity
function Entity:setVelocity(vx, vy)
    self.vx = vx
    self.vy = vy
end

-- Set rotation (degrees)
function Entity:setAngle(angle)
    self.rotation = angle
    self:setRotation(angle)
end

-- Called when collision occurs (override in subclasses)
function Entity:onCollision(other, collisionType)
    -- Override in subclasses
end

-- Destroy the entity
function Entity:destroy()
    self.active = false
    self:remove()
end

-- Check if entity is on screen
function Entity:isOnScreen(margin)
    margin = margin or 0
    return Utils.isOnScreen(self.x, self.y, margin)
end

-- Get bounding box for collision
function Entity:getBounds()
    local w, h = self:getSize()
    return self.x - w/2, self.y - h/2, w, h
end

-- Get center position
function Entity:getCenter()
    return self.x, self.y
end

-- Get radius (for circular collision)
function Entity:getRadius()
    local w, h = self:getSize()
    return math.max(w, h) / 2
end
