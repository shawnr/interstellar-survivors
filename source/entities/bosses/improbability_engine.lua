-- Improbability Engine Boss (Episode 3)
-- Reality-bending anomaly that warps probability and breaks physics

local gfx <const> = playdate.graphics

class('ImprobabilityEngine').extends(MOB)

ImprobabilityEngine.DATA = {
    id = "improbability_engine",
    name = "Improbability Engine",
    description = "Reality is just a suggestion",
    imagePath = "images/episodes/ep3/ep3_boss_improbability",

    -- Boss stats (Episode 3)
    baseHealth = 400,
    baseSpeed = 0.2,
    baseDamage = 7,
    rpValue = 150,

    -- Collision
    width = 48,
    height = 48,
    range = 100,
    emits = true,
}

-- Boss phases
ImprobabilityEngine.PHASES = {
    APPROACH = 1,           -- Moving into position
    PROBABILITY_STORM = 2,  -- Spawning probability fluctuations
    REALITY_WARP = 3,       -- Warping reality (inverts/randomizes effects)
    PARADOX = 4,            -- Paradox node summoning
    ENRAGED = 5,            -- Below 30% - full chaos mode
}

function ImprobabilityEngine:init(x, y)
    ImprobabilityEngine.super.init(self, x, y, ImprobabilityEngine.DATA, { health = 1, damage = 1, speed = 1 })

    -- Boss-specific state
    self.phase = ImprobabilityEngine.PHASES.APPROACH
    self.phaseTimer = 0
    self.attackTimer = 0
    self.spawnsThisPhase = 0
    self.maxSpawnsPerPhase = 4

    -- Reality warp state
    self.warpActive = false
    self.originalX = x
    self.originalY = y

    -- Teleport cooldown
    self.teleportTimer = 0
    self.canTeleport = false

    -- Set Z-index (bosses above normal mobs)
    self:setZIndex(75)

    -- Unlock in database when encountered
    if SaveManager then
        SaveManager:unlockDatabaseEntry("bosses", "improbability_engine")
    end
end

function ImprobabilityEngine:update(dt)
    if not self.active then return end

    -- Don't update if game is paused
    if GameplayScene and (GameplayScene.isPaused or GameplayScene.isLevelingUp) then
        return
    end

    dt = dt or (1/30)

    -- Update health bar
    if self.showHealthBar then
        self.healthBarTimer = self.healthBarTimer - dt
        if self.healthBarTimer <= 0 then
            self.showHealthBar = false
        end
    end

    -- Update timers
    self.phaseTimer = self.phaseTimer + dt
    self.attackTimer = self.attackTimer + dt
    self.teleportTimer = self.teleportTimer + dt

    -- Enable teleporting after a delay
    if self.teleportTimer >= 8 and not self.canTeleport then
        self.canTeleport = true
    end

    -- Check for enraged phase
    if self.health / self.maxHealth <= 0.3 and self.phase ~= ImprobabilityEngine.PHASES.ENRAGED then
        self:enterPhase(ImprobabilityEngine.PHASES.ENRAGED)
    end

    -- Execute current phase
    if self.phase == ImprobabilityEngine.PHASES.APPROACH then
        self:updateApproach(dt)
    elseif self.phase == ImprobabilityEngine.PHASES.PROBABILITY_STORM then
        self:updateProbabilityStorm(dt)
    elseif self.phase == ImprobabilityEngine.PHASES.REALITY_WARP then
        self:updateRealityWarp(dt)
    elseif self.phase == ImprobabilityEngine.PHASES.PARADOX then
        self:updateParadox(dt)
    elseif self.phase == ImprobabilityEngine.PHASES.ENRAGED then
        self:updateEnraged(dt)
    end
end

function ImprobabilityEngine:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTimer = 0
    self.attackTimer = 0
    self.spawnsThisPhase = 0

    if newPhase == ImprobabilityEngine.PHASES.PROBABILITY_STORM then
        GameplayScene:showMessage("Probability destabilizing!")
    elseif newPhase == ImprobabilityEngine.PHASES.REALITY_WARP then
        GameplayScene:showMessage("REALITY INVERSION!")
    elseif newPhase == ImprobabilityEngine.PHASES.PARADOX then
        GameplayScene:showMessage("Paradox field expanding!")
    elseif newPhase == ImprobabilityEngine.PHASES.ENRAGED then
        GameplayScene:showMessage("CAUSALITY COLLAPSE!")
        self.speed = self.speed * 1.8
        self.maxSpawnsPerPhase = 6
        self.canTeleport = true
    end
end

function ImprobabilityEngine:updateApproach(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > self.range then
        local moveX = (dx / dist) * self.speed
        local moveY = (dy / dist) * self.speed
        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)
    else
        self:enterPhase(ImprobabilityEngine.PHASES.PROBABILITY_STORM)
    end

    local angle = Utils.vectorToAngle(dx, dy)
    self:setRotation(angle)
end

function ImprobabilityEngine:updateProbabilityStorm(dt)
    self:erraticOrbit(dt)

    -- Spawn probability fluctuations periodically
    if self.attackTimer >= 1.4 and self.spawnsThisPhase < self.maxSpawnsPerPhase then
        self:spawnFluctuation()
        self.attackTimer = 0
        self.spawnsThisPhase = self.spawnsThisPhase + 1
    end

    -- After spawning, switch to reality warp
    if self.spawnsThisPhase >= self.maxSpawnsPerPhase and self.phaseTimer >= 5 then
        self:enterPhase(ImprobabilityEngine.PHASES.REALITY_WARP)
    end
end

function ImprobabilityEngine:updateRealityWarp(dt)
    self:erraticOrbit(dt, 0.5)

    -- Apply reality warp effect
    if not self.warpActive and self.phaseTimer >= 0.5 then
        self:startRealityWarp()
    end

    -- End warp phase after duration
    if self.phaseTimer >= 4 then
        self:endRealityWarp()
        self:enterPhase(ImprobabilityEngine.PHASES.PARADOX)
    end
end

function ImprobabilityEngine:updateParadox(dt)
    self:erraticOrbit(dt)

    -- Spawn paradox nodes
    if self.attackTimer >= 1.8 and self.spawnsThisPhase < 3 then
        self:spawnParadoxNode()
        self.attackTimer = 0
        self.spawnsThisPhase = self.spawnsThisPhase + 1
    end

    -- After spawning, back to probability storm
    if self.spawnsThisPhase >= 3 and self.phaseTimer >= 5 then
        self:enterPhase(ImprobabilityEngine.PHASES.PROBABILITY_STORM)
    end
end

function ImprobabilityEngine:updateEnraged(dt)
    self:erraticOrbit(dt, 1.5)

    -- Random teleports in enraged mode
    if self.canTeleport and math.random(100) <= 2 then
        self:teleportRandom()
    end

    -- Rapid chaotic attacks
    if self.attackTimer >= 0.5 then
        local roll = math.random(100)
        if roll <= 40 then
            self:spawnFluctuation()
        elseif roll <= 60 then
            self:spawnParadoxNode()
        else
            self:applyRealityGlitch()
        end
        self.attackTimer = 0
    end
end

-- Erratic orbit that occasionally reverses direction
function ImprobabilityEngine:erraticOrbit(dt, speedMult)
    speedMult = speedMult or 1.0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y

    local angle = math.atan(dy, dx)

    -- Occasionally reverse direction (probability is weird)
    local direction = 1
    if math.random(100) <= 5 then
        direction = -1
    end

    angle = angle + (self.speed * speedMult * 0.03 * dt * 30 * direction)

    -- Vary the orbit distance slightly
    local orbitRange = self.range + math.sin(self.phaseTimer * 2) * 20

    self.x = self.targetX - math.cos(angle) * orbitRange
    self.y = self.targetY - math.sin(angle) * orbitRange
    self:moveTo(self.x, self.y)

    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

function ImprobabilityEngine:teleportRandom()
    -- Teleport to a random position around the station
    local angle = math.random() * math.pi * 2
    local newX = self.targetX + math.cos(angle) * self.range
    local newY = self.targetY + math.sin(angle) * self.range

    -- Clamp to screen bounds
    newX = Utils.clamp(newX, 50, Constants.SCREEN_WIDTH - 50)
    newY = Utils.clamp(newY, 50, Constants.SCREEN_HEIGHT - 50)

    self.x = newX
    self.y = newY
    self:moveTo(self.x, self.y)

    GameplayScene:showMessage("*BLINK*", 0.5)
    self.teleportTimer = 0
    self.canTeleport = false
end

function ImprobabilityEngine:spawnFluctuation()
    if not GameplayScene then return end

    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 35
    local spawnY = self.y + math.sin(offsetAngle) * 35

    local fluctuation = ProbabilityFluctuation(spawnX, spawnY, { health = 1.3, damage = 1.2, speed = 1.1 })
    table.insert(GameplayScene.mobs, fluctuation)
end

function ImprobabilityEngine:spawnParadoxNode()
    if not GameplayScene then return end

    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 40
    local spawnY = self.y + math.sin(offsetAngle) * 40

    local node = ParadoxNode(spawnX, spawnY, { health = 1.4, damage = 1.3, speed = 0.9 })
    table.insert(GameplayScene.mobs, node)
end

function ImprobabilityEngine:startRealityWarp()
    self.warpActive = true
    self:applyRealityGlitch()
    GameplayScene:showMessage("Controls inverted!", 2.0)
end

function ImprobabilityEngine:endRealityWarp()
    self.warpActive = false
    -- Remove any lingering effects
    if GameplayScene and GameplayScene.station then
        GameplayScene.station.controlsInverted = false
    end
end

function ImprobabilityEngine:applyRealityGlitch()
    if GameplayScene and GameplayScene.station then
        -- Invert crank controls temporarily
        GameplayScene.station.controlsInverted = true
        GameplayScene.station.controlsInvertedTimer = 2.5

        -- Also apply a random debuff
        local roll = math.random(3)
        if roll == 1 then
            -- Slow rotation
            GameplayScene.station.rotationSlow = 0.5
            GameplayScene.station.rotationSlowTimer = 2.0
        elseif roll == 2 then
            -- Slow fire rate
            GameplayScene.station.fireRateSlow = 0.6
            GameplayScene.station.fireRateSlowTimer = 2.0
        end
        -- roll == 3: just inverted controls
    end
end

function ImprobabilityEngine:onDestroyed()
    self.active = false

    -- End any lingering effects
    if GameplayScene and GameplayScene.station then
        GameplayScene.station.controlsInverted = false
    end

    if GameManager then
        GameManager:awardRP(self.rpValue)
    end

    -- Save boss image for celebration before removing
    local bossImage = self:getImage()

    self:remove()

    -- Trigger boss defeat celebration
    if GameplayScene and GameplayScene.onBossDefeated then
        GameplayScene:onBossDefeated("Improbability Engine", bossImage)
    elseif GameManager then
        GameManager:endEpisode(true)
    end
end

-- Override health bar for boss (compact bar in bottom border area)
function ImprobabilityEngine:drawHealthBar()
    if not self.active then return end

    -- Compact boss health bar in bottom left area
    local barWidth = 170
    local barHeight = 14
    local barX = 6
    local barY = Constants.SCREEN_HEIGHT - 20

    local healthPercent = self.health / self.maxHealth
    local fillWidth = math.floor(healthPercent * (barWidth - 2))

    -- Health bar background (black = empty)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(barX, barY, barWidth, barHeight)

    -- Health bar fill (white = health remaining)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX + 1, barY + 1, fillWidth, barHeight - 2)

    -- Draw boss name inside the bar using smaller font
    local bossName = "IMPROBABLE"
    local textX = barX + barWidth / 2
    local textY = barY + 2

    -- Use tighter tracking for compact text
    gfx.setFontTracking(-1)

    -- Use clip rect to draw text in two colors
    -- First draw white text (for the empty/black portion)
    gfx.setClipRect(barX + 1 + fillWidth, barY + 1, barWidth - fillWidth - 2, barHeight - 2)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(bossName, textX, textY, kTextAlignment.center)

    -- Then draw black text (for the filled/white portion)
    gfx.setClipRect(barX + 1, barY + 1, fillWidth, barHeight - 2)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned(bossName, textX, textY, kTextAlignment.center)

    -- Clear clip rect and restore draw mode
    gfx.clearClipRect()
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setFontTracking(0)
end

return ImprobabilityEngine
