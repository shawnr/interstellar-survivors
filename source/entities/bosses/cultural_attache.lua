-- Cultural Attaché Boss (Episode 1)
-- Large ceremonial vessel that launches drones and demands you accept their poetry

local gfx <const> = playdate.graphics

class('CulturalAttache').extends(MOB)

CulturalAttache.DATA = {
    id = "cultural_attache",
    name = "Cultural Attaché",
    description = "Demands you accept their poetry",
    imagePath = "images/episodes/ep1/ep1_boss_cultural_attache",

    -- Boss stats (balanced for difficulty)
    baseHealth = 120,
    baseSpeed = 0.25,
    baseDamage = 8,
    rpValue = 100,

    -- Collision
    width = 48,
    height = 48,
    range = 100,    -- Stays at range
    emits = true,   -- Shooting boss
}

-- Boss phases
CulturalAttache.PHASES = {
    APPROACH = 1,   -- Moving into position
    DRONE_WAVE = 2, -- Launching greeting drones
    POETRY = 3,     -- Poetry attack (slows rotation)
    ENRAGED = 4,    -- Below 30% health - more aggressive
}

function CulturalAttache:init(x, y)
    -- Bosses don't use wave multipliers
    CulturalAttache.super.init(self, x, y, CulturalAttache.DATA, { health = 1, damage = 1, speed = 1 })

    -- Boss-specific state
    self.phase = CulturalAttache.PHASES.APPROACH
    self.phaseTimer = 0
    self.attackTimer = 0
    self.dronesSpawned = 0
    self.maxDronesPerWave = 3

    -- Poetry scroll reference
    self.poetryScroll = nil
    self.showingPoetry = false

    -- Set Z-index (bosses above normal mobs)
    self:setZIndex(75)

    print("Cultural Attaché boss spawned!")
end

function CulturalAttache:update(dt)
    if not self.active then return end

    -- Don't update if game is paused/leveling up
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

    -- Update phase timer
    self.phaseTimer = self.phaseTimer + dt
    self.attackTimer = self.attackTimer + dt

    -- Check for enraged phase
    if self.health / self.maxHealth <= 0.3 and self.phase ~= CulturalAttache.PHASES.ENRAGED then
        self:enterPhase(CulturalAttache.PHASES.ENRAGED)
    end

    -- Execute current phase
    if self.phase == CulturalAttache.PHASES.APPROACH then
        self:updateApproach(dt)
    elseif self.phase == CulturalAttache.PHASES.DRONE_WAVE then
        self:updateDroneWave(dt)
    elseif self.phase == CulturalAttache.PHASES.POETRY then
        self:updatePoetry(dt)
    elseif self.phase == CulturalAttache.PHASES.ENRAGED then
        self:updateEnraged(dt)
    end
end

function CulturalAttache:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTimer = 0
    self.attackTimer = 0

    if newPhase == CulturalAttache.PHASES.DRONE_WAVE then
        self.dronesSpawned = 0
        GameplayScene:showMessage("Deploying greeting drones!")
    elseif newPhase == CulturalAttache.PHASES.POETRY then
        GameplayScene:showMessage("Reciting epic poetry!")
    elseif newPhase == CulturalAttache.PHASES.ENRAGED then
        GameplayScene:showMessage("INSULTED! NOW ENRAGED!")
        self.speed = self.speed * 1.5
    end
end

function CulturalAttache:updateApproach(dt)
    -- Move toward station until in range
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
        -- In position, start attack cycle
        self:enterPhase(CulturalAttache.PHASES.DRONE_WAVE)
    end

    -- Face the station
    local angle = Utils.vectorToAngle(dx, dy)
    self:setRotation(angle)
end

function CulturalAttache:updateDroneWave(dt)
    -- Orbit the station
    self:orbitStation(dt)

    -- Spawn drones periodically
    if self.attackTimer >= 1.5 and self.dronesSpawned < self.maxDronesPerWave then
        self:spawnDrone()
        self.attackTimer = 0
        self.dronesSpawned = self.dronesSpawned + 1
    end

    -- After spawning all drones, switch to poetry phase
    if self.dronesSpawned >= self.maxDronesPerWave and self.phaseTimer >= 5 then
        self:enterPhase(CulturalAttache.PHASES.POETRY)
    end
end

function CulturalAttache:updatePoetry(dt)
    -- Orbit the station
    self:orbitStation(dt)

    -- Show poetry scroll and apply slow
    if not self.showingPoetry and self.phaseTimer >= 0.5 then
        self:startPoetryAttack()
    end

    -- End poetry phase after duration
    if self.phaseTimer >= 4 then
        self:endPoetryAttack()
        self:enterPhase(CulturalAttache.PHASES.DRONE_WAVE)
    end
end

function CulturalAttache:updateEnraged(dt)
    -- More aggressive orbit
    self:orbitStation(dt, 1.5)

    -- Rapidly spawn drones and use poetry
    if self.attackTimer >= 0.8 then
        if math.random() < 0.6 then
            self:spawnDrone()
        else
            self:applySlowEffect()
        end
        self.attackTimer = 0
    end
end

function CulturalAttache:orbitStation(dt, speedMult)
    speedMult = speedMult or 1.0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Orbit behavior
    local angle = math.atan(dy, dx)
    angle = angle + (self.speed * speedMult * 0.03 * dt * 30)

    self.x = self.targetX - math.cos(angle) * self.range
    self.y = self.targetY - math.sin(angle) * self.range
    self:moveTo(self.x, self.y)

    -- Face the station
    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

function CulturalAttache:spawnDrone()
    if not GameplayScene then return end

    -- Spawn a greeting drone near the boss
    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 30
    local spawnY = self.y + math.sin(offsetAngle) * 30

    local drone = GreetingDrone(spawnX, spawnY, { health = 1, damage = 1, speed = 1 })
    table.insert(GameplayScene.mobs, drone)

    print("Boss spawned drone!")
end

function CulturalAttache:startPoetryAttack()
    self.showingPoetry = true

    -- Apply slow to station
    self:applySlowEffect()

    print("Boss: Reciting poetry!")
end

function CulturalAttache:endPoetryAttack()
    self.showingPoetry = false
end

function CulturalAttache:applySlowEffect()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station.rotationSlow = 0.4  -- 60% slower
        GameplayScene.station.rotationSlowTimer = 2.5

        GameplayScene:showMessage("Poetry slows rotation!", 2.0)
    end
end

function CulturalAttache:onDestroyed()
    self.active = false

    -- Award RP
    if GameManager then
        GameManager:awardRP(self.rpValue)
    end

    -- Remove sprite
    self:remove()

    -- Show victory message
    GameplayScene:showMessage("Poetry accepted! Victory!", 3.0)

    -- Trigger victory!
    if GameManager then
        GameManager:endEpisode(true)
    end
end

-- Override health bar for boss (at bottom of screen, above HUD)
function CulturalAttache:drawHealthBar()
    if not self.active then return end

    -- Boss health bar at bottom of screen (above bottom HUD)
    local barWidth = 280
    local barHeight = 10
    local barX = (Constants.SCREEN_WIDTH - barWidth) / 2
    local barY = Constants.SCREEN_HEIGHT - 38

    -- Background box
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX - 4, barY - 14, barWidth + 8, barHeight + 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(barX - 4, barY - 14, barWidth + 8, barHeight + 18)

    -- Boss name
    gfx.drawTextAligned("*CULTURAL ATTACHÉ*", Constants.SCREEN_WIDTH / 2, barY - 12, kTextAlignment.center)

    -- Health bar border
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(barX, barY, barWidth, barHeight)

    -- Health bar fill
    local fillWidth = (self.health / self.maxHealth) * (barWidth - 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX + 1, barY + 1, fillWidth, barHeight - 2)
end

return CulturalAttache
