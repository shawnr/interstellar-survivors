-- Productivity Liaison Boss (Episode 2)
-- Corporate enforcer that demands quarterly reports and sends performance reviews

local gfx <const> = playdate.graphics

class('ProductivityLiaison').extends(MOB)

ProductivityLiaison.DATA = {
    id = "productivity_liaison",
    name = "Productivity Liaison",
    description = "Your performance is under review",
    imagePath = "images/episodes/ep2/ep2_boss_productivity_liaison",

    -- Boss stats (Episode 2)
    baseHealth = 600,
    baseSpeed = 0.28,
    baseDamage = 10,
    rpValue = 120,

    -- Collision
    width = 48,
    height = 48,
    range = 90,
    emits = true,
    isBoss = true,
}

-- Boss phases
ProductivityLiaison.PHASES = {
    APPROACH = 1,       -- Moving into position
    SURVEY_SWARM = 2,   -- Launching survey drones
    FEEDBACK = 3,       -- Feedback pulse attack
    ENRAGED = 4,        -- Below 30% health - performance improvement plan
}

function ProductivityLiaison:init(x, y)
    ProductivityLiaison.super.init(self, x, y, ProductivityLiaison.DATA, { health = 1, damage = 1, speed = 1 })

    -- Boss-specific state
    self.phase = ProductivityLiaison.PHASES.APPROACH
    self.phaseTimer = 0
    self.attackTimer = 0
    self.dronesSpawned = 0
    self.maxDronesPerWave = 6

    -- Feedback attack state
    self.feedbackActive = false

    -- Set Z-index (bosses above normal mobs)
    self:setZIndex(75)

    -- Unlock in database when encountered
    if SaveManager then
        SaveManager:unlockDatabaseEntry("bosses", "productivity_liaison")
    end
end

function ProductivityLiaison:update(dt)
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

    -- Handle scramble (erratic movement from EMP)
    self._speedScale = dt * 30
    if self:handleScramble(dt) then return end

    -- Update phase timer
    self.phaseTimer = self.phaseTimer + dt
    self.attackTimer = self.attackTimer + dt

    -- Check for enraged phase
    if self.health / self.maxHealth <= 0.3 and self.phase ~= ProductivityLiaison.PHASES.ENRAGED then
        self:enterPhase(ProductivityLiaison.PHASES.ENRAGED)
    end

    -- Execute current phase
    if self.phase == ProductivityLiaison.PHASES.APPROACH then
        self:updateApproach(dt)
    elseif self.phase == ProductivityLiaison.PHASES.SURVEY_SWARM then
        self:updateSurveySwarm(dt)
    elseif self.phase == ProductivityLiaison.PHASES.FEEDBACK then
        self:updateFeedback(dt)
    elseif self.phase == ProductivityLiaison.PHASES.ENRAGED then
        self:updateEnraged(dt)
    end
end

function ProductivityLiaison:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTimer = 0
    self.attackTimer = 0

    if newPhase == ProductivityLiaison.PHASES.SURVEY_SWARM then
        self.dronesSpawned = 0
        GameplayScene:showMessage("Deploying survey drones!")
    elseif newPhase == ProductivityLiaison.PHASES.FEEDBACK then
        GameplayScene:showMessage("Performance review incoming!")
    elseif newPhase == ProductivityLiaison.PHASES.ENRAGED then
        GameplayScene:showMessage("PERFORMANCE IMPROVEMENT PLAN!")
        self.speed = self.speed * 1.5
        self.maxDronesPerWave = 8
    end
end

function ProductivityLiaison:updateApproach(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > self.range and dist > 0 then
        local moveX = (dx / dist) * self.speed * 5  -- Fast approach
        local moveY = (dy / dist) * self.speed * 5
        self.x = self.x + moveX
        self.y = self.y + moveY
        self:moveTo(self.x, self.y)
    else
        self:enterPhase(ProductivityLiaison.PHASES.SURVEY_SWARM)
    end

    if dist > 0 then
        local angle = Utils.vectorToAngle(dx, dy)
        self:setRotation(angle)
    end
end

function ProductivityLiaison:updateSurveySwarm(dt)
    self:orbitStation(dt)

    -- Spawn survey drones periodically
    if self.attackTimer >= 0.8 and self.dronesSpawned < self.maxDronesPerWave then
        self:spawnSurveyDrone()
        self.attackTimer = 0
        self.dronesSpawned = self.dronesSpawned + 1
    end

    -- After spawning all drones, switch to feedback phase
    if self.dronesSpawned >= self.maxDronesPerWave and self.phaseTimer >= 5 then
        self:enterPhase(ProductivityLiaison.PHASES.FEEDBACK)
    end
end

function ProductivityLiaison:updateFeedback(dt)
    self:orbitStation(dt)

    -- Apply feedback debuff
    if not self.feedbackActive and self.phaseTimer >= 0.5 then
        self:startFeedbackAttack()
    end

    -- End feedback phase after duration
    if self.phaseTimer >= 4 then
        self:endFeedbackAttack()
        self:enterPhase(ProductivityLiaison.PHASES.SURVEY_SWARM)
    end
end

function ProductivityLiaison:updateEnraged(dt)
    self:orbitStation(dt, 1.5)

    -- Rapidly attack
    if self.attackTimer >= 0.4 then
        if math.random() < 0.5 then
            self:spawnSurveyDrone()
        else
            self:applyFeedbackDebuff()
        end
        self.attackTimer = 0
    end
end

function ProductivityLiaison:orbitStation(dt, speedMult)
    speedMult = speedMult or 1.0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y

    local angle = math.atan(dy, dx)
    angle = angle + (self.speed * speedMult * 0.03 * dt * 30)

    self.x = self.targetX - math.cos(angle) * self.range
    self.y = self.targetY - math.sin(angle) * self.range
    self:moveTo(self.x, self.y)

    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

function ProductivityLiaison:spawnSurveyDrone()
    if not GameplayScene then return end

    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 30
    local spawnY = self.y + math.sin(offsetAngle) * 30

    -- Spawn Episode 2 survey drones, not Episode 1 greeting drones
    local drone = SurveyDrone(spawnX, spawnY, { health = 1.2, damage = 1.1, speed = 1.2 })
    GameplayScene:queueMob(drone)
end

function ProductivityLiaison:startFeedbackAttack()
    self.feedbackActive = true
    self:applyFeedbackDebuff()
    GameplayScene:showMessage("Negative feedback received!")
end

function ProductivityLiaison:endFeedbackAttack()
    self.feedbackActive = false
end

function ProductivityLiaison:applyFeedbackDebuff()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:applyDebuff("fireRateSlow", 0.5, 2.0)
        GameplayScene:showMessage("Productivity declining!", 1.5)
    end
end

function ProductivityLiaison:onDestroyed()
    self.active = false

    if GameManager then
        GameManager:awardRP(self.rpValue)
    end

    -- Save boss image for celebration before removing
    local bossImage = self:getImage()

    self:remove()

    -- Trigger boss defeat celebration
    if GameplayScene and GameplayScene.onBossDefeated then
        GameplayScene:onBossDefeated("Productivity Liaison", bossImage)
    elseif GameManager then
        GameManager:endEpisode(true)
    end
end

function ProductivityLiaison:drawHealthBar()
    self:drawBossHealthBar("LIAISON")
end

return ProductivityLiaison
