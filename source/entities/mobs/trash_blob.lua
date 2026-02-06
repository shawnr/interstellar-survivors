-- Trash Blob MOB (Episode 4)
-- Larger, consolidated debris entity for better performance
-- Equivalent to ~3 debris chunks combined

local gfx <const> = playdate.graphics

class('TrashBlob').extends(MOB)

TrashBlob.DATA = {
    id = "trash_blob",
    name = "Trash Blob",
    description = "Compressed mass of ancient wreckage",
    imagePath = nil,  -- Generated programmatically

    -- Consolidated stats (~3 debris chunks worth)
    baseHealth = 24,
    baseSpeed = 0.5,  -- Slower than debris chunks
    baseDamage = 12,
    rpValue = 24,

    -- Collision - larger than debris chunk
    width = 32,
    height = 32,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

-- Pre-generate blob images for each variant (performance: avoid regenerating)
TrashBlob.cachedImages = nil

function TrashBlob:init(x, y, waveMultipliers, variant)
    -- Generate cached images if not already done
    if not TrashBlob.cachedImages then
        TrashBlob:generateCachedImages()
    end

    -- Choose a random variant
    variant = variant or math.random(1, 3)

    local data = {}
    for k, v in pairs(TrashBlob.DATA) do
        data[k] = v
    end

    -- Use parent init but we'll set the image manually
    TrashBlob.super.init(self, x, y, data, waveMultipliers)

    self.variant = variant
    self:setImage(TrashBlob.cachedImages[variant])

    -- No animation - static sprite for performance
end

-- Generate cached blob images (called once)
function TrashBlob:generateCachedImages()
    TrashBlob.cachedImages = {}

    for variant = 1, 3 do
        local img = gfx.image.new(32, 32)
        gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)

        -- Draw an irregular blob shape based on variant
        if variant == 1 then
            -- Chunky blob with angular edges
            gfx.fillCircleAtPoint(16, 16, 12)
            gfx.fillRect(8, 10, 16, 12)
            gfx.fillCircleAtPoint(10, 10, 6)
            gfx.fillCircleAtPoint(22, 20, 7)
            gfx.fillPolygon(4, 16, 12, 8, 20, 12, 16, 20)
        elseif variant == 2 then
            -- Spiky blob
            gfx.fillCircleAtPoint(16, 16, 10)
            gfx.fillPolygon(16, 2, 20, 12, 12, 12)  -- Top spike
            gfx.fillPolygon(30, 16, 20, 20, 20, 12) -- Right spike
            gfx.fillPolygon(16, 30, 12, 20, 20, 20) -- Bottom spike
            gfx.fillPolygon(2, 16, 12, 12, 12, 20)  -- Left spike
            gfx.fillCircleAtPoint(16, 16, 8)
        else
            -- Lumpy blob
            gfx.fillCircleAtPoint(14, 14, 10)
            gfx.fillCircleAtPoint(20, 18, 9)
            gfx.fillCircleAtPoint(12, 20, 7)
            gfx.fillCircleAtPoint(18, 12, 6)
            gfx.fillRect(10, 12, 14, 10)
        end

        -- Add some black detail/texture
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(16, 16, 11)  -- Outline
        -- Random internal details
        gfx.fillCircleAtPoint(12 + variant * 2, 14, 2)
        gfx.fillCircleAtPoint(18, 18 - variant, 2)
        gfx.fillCircleAtPoint(14, 20, 1)

        gfx.popContext()
        TrashBlob.cachedImages[variant] = img
    end
end

function TrashBlob:update(dt)
    TrashBlob.super.update(self, dt)

    -- Check for station collision (no rotation for performance)
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function TrashBlob:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end

return TrashBlob
