-- Pickup Thief MOB
-- Organic creature that spawns when a pickup appears and races to eat it.
-- Immune to electrical damage (EMP Burst, Tesla Coil).
-- Rotates through a pool of named variants with different visual shapes.

local gfx <const> = playdate.graphics
local math_floor <const> = math.floor
local math_sqrt <const> = math.sqrt
local math_random <const> = math.random
local math_abs <const> = math.abs
local math_cos <const> = math.cos
local math_sin <const> = math.sin

class('PickupThief').extends(MOB)

-- Pool of thief variants: name + visual shape
-- Visuals are distinct creature silhouettes (tentacles, legs, spines) —
-- clearly different from pickup items (geometric outlines)
PickupThief.VARIANTS = {
    { name = "Space Herpes", visual = "spore" },
    { name = "Protomolecule Glob", visual = "tentacle" },
    { name = "Langolier", visual = "claw" },
    { name = "Blob Fragment", visual = "spore" },
    { name = "Mynock", visual = "leech" },
    { name = "Nibbler Spawn", visual = "spider" },
    { name = "Tribble Mutant", visual = "spore" },
    { name = "Mogwai", visual = "spider" },
    { name = "Cargo Gremlin", visual = "claw" },
    { name = "Loot Leech", visual = "leech" },
    { name = "Plunder Bug", visual = "spider" },
    { name = "Space Scavenger", visual = "claw" },
    { name = "Metroid Larva", visual = "tentacle" },
    { name = "Headcrab", visual = "spider" },
    { name = "Flood Spore", visual = "spore" },
    { name = "Ohmu Larva", visual = "leech" },
    { name = "Ceti Eel", visual = "leech" },
    { name = "Dianoga", visual = "tentacle" },
    { name = "Graboid Spawn", visual = "claw" },
    { name = "Brainslug", visual = "tentacle" },
}

-- Visual draw functions (20x20 procedural creatures, 5 variants)
-- Designed to be clearly distinct from pickup items (geometric outlines):
-- Thieves are filled organic creatures with extending appendages.
local VISUAL_DRAW = {}

function VISUAL_DRAW.tentacle(img, size)
    -- Octopus-like: round body with 4 curving tentacles
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Body (filled dome)
    gfx.fillCircleAtPoint(half, half - 1, 5)
    -- Tentacles extending outward (wavy lines)
    gfx.setLineWidth(2)
    gfx.drawLine(half - 4, half + 2, 1, size - 2)       -- Bottom-left
    gfx.drawLine(half + 4, half + 2, size - 2, size - 2) -- Bottom-right
    gfx.drawLine(half - 3, half - 3, 1, 1)               -- Top-left
    gfx.drawLine(half + 3, half - 3, size - 2, 1)        -- Top-right
    gfx.setLineWidth(1)
    -- Tentacle curls (dots at tips)
    gfx.fillCircleAtPoint(1, size - 2, 1)
    gfx.fillCircleAtPoint(size - 2, size - 2, 1)
    gfx.fillCircleAtPoint(1, 1, 1)
    gfx.fillCircleAtPoint(size - 2, 1, 1)
    -- Eyes (two dots)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half - 2, half - 2, 1)
    gfx.fillCircleAtPoint(half + 2, half - 2, 1)
end

function VISUAL_DRAW.spider(img, size)
    -- Spider: small body with 8 radiating legs
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Compact body
    gfx.fillCircleAtPoint(half, half, 3)
    -- 8 legs radiating outward (long, extending past body)
    gfx.setLineWidth(1)
    gfx.drawLine(half, half - 3, half - 2, 1)       -- N-left
    gfx.drawLine(half, half - 3, half + 2, 1)       -- N-right
    gfx.drawLine(half + 3, half, size - 1, half - 3) -- E-up
    gfx.drawLine(half + 3, half, size - 1, half + 3) -- E-down
    gfx.drawLine(half, half + 3, half - 2, size - 1) -- S-left
    gfx.drawLine(half, half + 3, half + 2, size - 1) -- S-right
    gfx.drawLine(half - 3, half, 1, half - 3)        -- W-up
    gfx.drawLine(half - 3, half, 1, half + 3)        -- W-down
    -- Leg tips (dots)
    gfx.fillCircleAtPoint(half - 2, 1, 1)
    gfx.fillCircleAtPoint(half + 2, 1, 1)
    gfx.fillCircleAtPoint(size - 1, half - 3, 1)
    gfx.fillCircleAtPoint(size - 1, half + 3, 1)
    gfx.fillCircleAtPoint(half - 2, size - 1, 1)
    gfx.fillCircleAtPoint(half + 2, size - 1, 1)
    gfx.fillCircleAtPoint(1, half - 3, 1)
    gfx.fillCircleAtPoint(1, half + 3, 1)
    -- Fangs
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half, half, 1)
end

function VISUAL_DRAW.leech(img, size)
    -- Leech/eel: elongated segmented body with sucker mouth
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Elongated body (overlapping ovals)
    gfx.fillEllipseInRect(1, half - 4, 7, 8)
    gfx.fillEllipseInRect(5, half - 3, 6, 6)
    gfx.fillEllipseInRect(9, half - 3, 6, 6)
    -- Sucker mouth (open circle at front)
    gfx.drawCircleAtPoint(size - 4, half, 3)
    gfx.fillCircleAtPoint(size - 4, half, 1)
    -- Segment lines
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(5, half - 3, 5, half + 3)
    gfx.drawLine(9, half - 3, 9, half + 3)
    -- Tail spike
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(1, half, -1, half - 2)
    gfx.drawLine(1, half, -1, half + 2)
end

function VISUAL_DRAW.claw(img, size)
    -- Crab: wide body with two prominent pincers
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Body (wide oval)
    gfx.fillEllipseInRect(4, half - 3, 12, 8)
    -- Left pincer (V-shape)
    gfx.setLineWidth(2)
    gfx.drawLine(5, half - 2, 1, 1)
    gfx.drawLine(1, 1, 4, half - 4)
    -- Right pincer (V-shape)
    gfx.drawLine(5, half + 2, 1, size - 2)
    gfx.drawLine(1, size - 2, 4, half + 4)
    gfx.setLineWidth(1)
    -- Legs (4 stubby)
    gfx.drawLine(size - 5, half - 3, size - 1, half - 5)
    gfx.drawLine(size - 4, half - 2, size - 1, half - 2)
    gfx.drawLine(size - 4, half + 2, size - 1, half + 2)
    gfx.drawLine(size - 5, half + 3, size - 1, half + 5)
    -- Eyes (stalks)
    gfx.fillCircleAtPoint(7, half - 4, 1)
    gfx.fillCircleAtPoint(7, half + 4, 1)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(7, half - 4, 0)
    gfx.fillCircleAtPoint(7, half + 4, 0)
end

function VISUAL_DRAW.spore(img, size)
    -- Spore: round core with radiating spines/barbs
    local half = size / 2
    gfx.setColor(gfx.kColorWhite)
    -- Core
    gfx.fillCircleAtPoint(half, half, 4)
    -- Radiating spines (6 directions)
    gfx.setLineWidth(1)
    gfx.drawLine(half, half - 4, half, 1)             -- N
    gfx.drawLine(half + 3, half - 2, size - 2, 2)     -- NE
    gfx.drawLine(half + 3, half + 2, size - 2, size - 3) -- SE
    gfx.drawLine(half, half + 4, half, size - 2)       -- S
    gfx.drawLine(half - 3, half + 2, 2, size - 3)     -- SW
    gfx.drawLine(half - 3, half - 2, 2, 2)            -- NW
    -- Spine tips (barb dots)
    gfx.fillCircleAtPoint(half, 1, 1)
    gfx.fillCircleAtPoint(size - 2, 2, 1)
    gfx.fillCircleAtPoint(size - 2, size - 3, 1)
    gfx.fillCircleAtPoint(half, size - 2, 1)
    gfx.fillCircleAtPoint(2, size - 3, 1)
    gfx.fillCircleAtPoint(2, 2, 1)
    -- Dark center
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(half, half, 2)
end

-- Pre-cache variant images (shared across all instances)
local VARIANT_IMAGE_CACHE = {}

local function getVariantImage(visual)
    if VARIANT_IMAGE_CACHE[visual] then
        return VARIANT_IMAGE_CACHE[visual]
    end
    local size = 20
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
    local drawFn = VISUAL_DRAW[visual]
    if drawFn then
        drawFn(img, size)
    else
        VISUAL_DRAW.blob(img, size)
    end
    gfx.popContext()
    VARIANT_IMAGE_CACHE[visual] = img
    return img
end

PickupThief.DATA = {
    id = "pickup_thief",
    name = "Pickup Thief",
    imagePath = nil,  -- Procedural graphic (no image file)
    baseHealth = 60,
    baseSpeed = 0.6,  -- 1.5x pickup drift speed (0.4)
    baseDamage = 0,
    rpValue = 15,
    width = 20,
    height = 20,
    range = 1,
    emits = true,  -- Prevents station collision destruction (thief targets pickups, not station)
    skipRotation = true,
    electricImmune = true,
}

function PickupThief:init(x, y, waveMultipliers, targetPickup)
    PickupThief.super.init(self, x, y, PickupThief.DATA, waveMultipliers)

    -- Pick a random variant
    local variant = PickupThief.VARIANTS[math_random(#PickupThief.VARIANTS)]
    self.variantName = variant.name
    self.variantVisual = variant.visual

    -- Set procedural image
    local img = getVariantImage(variant.visual)
    self.drawImage = img
    local iw, ih = img:getSize()
    self._drawHalfW = math_floor(iw / 2)
    self._drawHalfH = math_floor(ih / 2)

    -- Thief state
    self.targetPickup = targetPickup
    self.state = "chasing"  -- chasing, eating, fleeing
    self.eatingTimer = 0
    self.stolenPickupData = nil
    self.fleeAngle = 0
    self.baseSpeed = self.speed
end

function PickupThief:update(dt)
    if not self.active then return end

    -- Pause check
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    -- Frame guard
    local frame = Projectile.frameCounter
    if self._lastFrame == frame then return end
    self._lastFrame = frame
    dt = dt or (1/30)

    -- Health bar timer
    if self.showHealthBar then
        self.healthBarTimer = self.healthBarTimer - dt
        if self.healthBarTimer <= 0 then
            self.showHealthBar = false
        end
    end

    local speedScale = dt * 30

    if self.state == "chasing" then
        self:updateChasing(speedScale)
    elseif self.state == "eating" then
        self:updateEating(dt)
    elseif self.state == "fleeing" then
        self:updateFleeing(speedScale)
    end
end

function PickupThief:updateChasing(speedScale)
    local pickup = self.targetPickup

    -- If pickup was collected or despawned, flee
    if not pickup or not pickup.active then
        self.state = "fleeing"
        self:calculateFleeAngle()
        return
    end

    -- Move toward pickup
    local dx = pickup.x - self.x
    local dy = pickup.y - self.y
    local distSq = dx * dx + dy * dy

    -- Reached pickup? Start eating
    if distSq < 15 * 15 then
        self.state = "eating"
        self.eatingTimer = 1.5
        return
    end

    -- Acceleration: speed up as we get closer (1x at 300px, 2x at 50px)
    local dist = math_sqrt(distSq)
    local accelMult = 1.0 + math.max(0, (300 - dist) / 300)
    local moveSpeed = self.baseSpeed * accelMult * speedScale

    -- Direction to pickup (normalized)
    local invDist = 1 / dist
    local dirX = dx * invDist
    local dirY = dy * invDist

    -- Check if direct path to pickup crosses through station zone
    local stationX = Constants.STATION_CENTER_X
    local stationY = Constants.STATION_CENTER_Y
    local avoidRadius = Constants.STATION_RADIUS + 30  -- ~62px clearance

    local sdx = self.x - stationX
    local sdy = self.y - stationY
    local stationDistSq = sdx * sdx + sdy * sdy

    -- Project station center onto thief→pickup line to detect crossing
    local toStationX = stationX - self.x
    local toStationY = stationY - self.y
    local projection = toStationX * dirX + toStationY * dirY
    local needsAvoidance = false

    if projection > 0 and projection < dist then
        -- Perpendicular distance from station center to the line
        local perpX = toStationX - projection * dirX
        local perpY = toStationY - projection * dirY
        local perpDistSq = perpX * perpX + perpY * perpY
        if perpDistSq < avoidRadius * avoidRadius then
            needsAvoidance = true
        end
    end

    -- Also avoid if already inside the zone
    if stationDistSq < avoidRadius * avoidRadius then
        needsAvoidance = true
    end

    local moveX, moveY
    if needsAvoidance then
        -- Steer tangentially around the station
        local stationDist = math_sqrt(stationDistSq)
        if stationDist < 1 then stationDist = 1 end

        -- Normalized vector from station to thief
        local awayX = sdx / stationDist
        local awayY = sdy / stationDist

        -- Two tangent directions (CW and CCW around station)
        local tangentCW_X = awayY
        local tangentCW_Y = -awayX
        local tangentCCW_X = -awayY
        local tangentCCW_Y = awayX

        -- Pick whichever tangent direction best leads toward the pickup
        local dotCW = tangentCW_X * dirX + tangentCW_Y * dirY
        local dotCCW = tangentCCW_X * dirX + tangentCCW_Y * dirY

        local tangentX, tangentY
        if dotCW > dotCCW then
            tangentX, tangentY = tangentCW_X, tangentCW_Y
        else
            tangentX, tangentY = tangentCCW_X, tangentCCW_Y
        end

        -- Blend tangential with push-away (push harder when closer to station)
        local pushStrength = 0
        if stationDistSq < avoidRadius * avoidRadius then
            pushStrength = (avoidRadius - stationDist) / avoidRadius
        end

        moveX = (tangentX * (1 - pushStrength * 0.5) + awayX * pushStrength * 0.5) * moveSpeed
        moveY = (tangentY * (1 - pushStrength * 0.5) + awayY * pushStrength * 0.5) * moveSpeed
    else
        -- Clear path - go directly toward pickup
        moveX = dirX * moveSpeed
        moveY = dirY * moveSpeed
    end

    -- Proactive projectile dodge
    moveX, moveY = self:applyProjectileDodge(moveX, moveY, speedScale)

    self.x = self.x + moveX
    self.y = self.y + moveY
end

function PickupThief:updateEating(dt)
    self.eatingTimer = self.eatingTimer - dt

    -- Blink the pickup while eating
    if self.targetPickup and self.targetPickup.active then
        self.targetPickup.drawVisible = math_floor(self.eatingTimer * 6) % 2 == 0
    end

    if self.eatingTimer <= 0 then
        -- Consume the pickup
        if self.targetPickup and self.targetPickup.active then
            self.stolenPickupData = self.targetPickup.data
            self.targetPickup.active = false
            self.targetPickup.drawVisible = false
        end

        -- Taunt message
        local pickupName = self.stolenPickupData and self.stolenPickupData.name or "pickup"
        if GameplayScene then
            GameplayScene:showMessage(self.variantName .. " stole your " .. pickupName .. "!", 2.5)
        end

        -- Food coma: 50% speed
        self.speed = self.baseSpeed * 0.5
        self.state = "fleeing"
        self:calculateFleeAngle()
    end
end

function PickupThief:updateFleeing(speedScale)
    -- Move toward nearest screen edge
    local moveSpeed = self.speed * speedScale
    local moveX = math_cos(self.fleeAngle) * moveSpeed
    local moveY = math_sin(self.fleeAngle) * moveSpeed

    -- Station avoidance: push away if too close during flee
    local stationX = Constants.STATION_CENTER_X
    local stationY = Constants.STATION_CENTER_Y
    local avoidRadius = Constants.STATION_RADIUS + 30
    local sdx = self.x - stationX
    local sdy = self.y - stationY
    local stationDistSq = sdx * sdx + sdy * sdy
    if stationDistSq < avoidRadius * avoidRadius and stationDistSq > 1 then
        local stationDist = math_sqrt(stationDistSq)
        local push = (avoidRadius - stationDist) / avoidRadius
        moveX = moveX + (sdx / stationDist) * push * moveSpeed * 2
        moveY = moveY + (sdy / stationDist) * push * moveSpeed * 2
    end

    -- Proactive projectile dodge
    moveX, moveY = self:applyProjectileDodge(moveX, moveY, speedScale)

    self.x = self.x + moveX
    self.y = self.y + moveY

    -- Off-screen? Deactivate
    if self.x < -30 or self.x > Constants.SCREEN_WIDTH + 30 or
       self.y < -30 or self.y > Constants.SCREEN_HEIGHT + 30 then
        self.active = false
    end
end

-- Scan for approaching projectiles and dodge perpendicular (throttled every 4 frames)
function PickupThief:applyProjectileDodge(moveX, moveY, speedScale)
    self._dodgeScanCounter = (self._dodgeScanCounter or 0) + 1
    if self._dodgeScanCounter < 4 then
        -- Apply cached dodge direction between scans
        if self._cachedDodgeX then
            return moveX + self._cachedDodgeX, moveY + self._cachedDodgeY
        end
        return moveX, moveY
    end
    self._dodgeScanCounter = 0
    self._cachedDodgeX = nil
    self._cachedDodgeY = nil

    if not GameplayScene or not GameplayScene.projectilePool then
        return moveX, moveY
    end

    local projActive = GameplayScene.projectilePool.active
    local projCount = #projActive
    local threatDistSq = 55 * 55
    local bestDistSq = threatDistSq
    local bestDx, bestDy

    for i = 1, projCount do
        local proj = projActive[i]
        if proj.active then
            local pdx = proj.x - self.x
            local pdy = proj.y - self.y
            local pDistSq = pdx * pdx + pdy * pdy

            if pDistSq < bestDistSq then
                -- Dot product: is projectile heading toward us?
                local dot = proj.dx * (-pdx) + proj.dy * (-pdy)
                if dot > 0 then
                    bestDistSq = pDistSq
                    bestDx = pdx
                    bestDy = pdy
                end
            end
        end
    end

    if bestDx then
        -- Dodge perpendicular to projectile-to-thief vector
        local perpX = bestDy
        local perpY = -bestDx
        local perpLen = math_sqrt(perpX * perpX + perpY * perpY)
        if perpLen > 0 then
            local dodgeStrength = self.baseSpeed * 2.5 * speedScale
            local dodgeX = (perpX / perpLen) * dodgeStrength
            local dodgeY = (perpY / perpLen) * dodgeStrength
            self._cachedDodgeX = dodgeX
            self._cachedDodgeY = dodgeY
            return moveX + dodgeX, moveY + dodgeY
        end
    end

    return moveX, moveY
end

function PickupThief:calculateFleeAngle()
    -- Flee toward the nearest screen edge
    local distLeft = self.x
    local distRight = Constants.SCREEN_WIDTH - self.x
    local distTop = self.y
    local distBottom = Constants.SCREEN_HEIGHT - self.y
    local minDist = math.min(distLeft, distRight, distTop, distBottom)

    if minDist == distLeft then
        self.fleeAngle = math.pi  -- Left
    elseif minDist == distRight then
        self.fleeAngle = 0  -- Right
    elseif minDist == distTop then
        self.fleeAngle = -math.pi / 2  -- Up
    else
        self.fleeAngle = math.pi / 2  -- Down
    end
end

function PickupThief:onDestroyed()
    if self.state == "eating" or (self.state == "fleeing" and self.stolenPickupData) then
        -- Killed after eating: drop partial RP (50% of pickup's average RP)
        if self.stolenPickupData then
            local avgRp = math_floor((self.stolenPickupData.rpMin + self.stolenPickupData.rpMax) / 4)
            if avgRp > 0 and GameplayScene and GameplayScene.collectiblePool then
                GameplayScene.collectiblePool:get(self.x, self.y, Collectible.TYPES.RP, avgRp)
            end
        end

        -- If still eating, restore the pickup
        if self.state == "eating" and self.targetPickup then
            self.targetPickup.active = true
            self.targetPickup.drawVisible = true
        end
    end

    -- Standard MOB death (RP drop, sound, etc.)
    PickupThief.super.onDestroyed(self)
end
