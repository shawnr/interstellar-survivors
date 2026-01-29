-- Distinguished Professor Boss (Episode 5)
-- A senior academic who believes your research is "derivative"

local gfx <const> = playdate.graphics

class('DistinguishedProfessor').extends(MOB)

DistinguishedProfessor.DATA = {
    id = "distinguished_professor",
    name = "Distinguished Professor",
    description = "Your research is... derivative.",
    imagePath = "images/episodes/ep5/ep5_boss_professor",
    projectileImage = "images/episodes/ep5/ep5_citation_beam",

    -- Boss stats (balanced for difficulty)
    baseHealth = 220,
    baseSpeed = 0.25,
    baseDamage = 10,
    rpValue = 200,

    -- Collision
    width = 44,
    height = 44,
    range = 130,    -- Stays at max range
    emits = true,   -- Shooting boss

    -- Attack properties
    fireRate = 0.8,
    projectileSpeed = 4,
}

-- Boss phases
DistinguishedProfessor.PHASES = {
    APPROACH = 1,           -- Moving into position
    LECTURING = 2,          -- Firing citation beams
    SUMMONING = 3,          -- Summoning debate drones
    ENRAGED = 4,            -- Below 30% - rapid fire, chaining beams
}

function DistinguishedProfessor:init(x, y)
    DistinguishedProfessor.super.init(self, x, y, DistinguishedProfessor.DATA, { health = 1, damage = 1, speed = 1 })

    -- Boss-specific state
    self.phase = DistinguishedProfessor.PHASES.APPROACH
    self.phaseTimer = 0
    self.attackTimer = 0
    self.fireCooldown = 0
    self.fireInterval = 1 / DistinguishedProfessor.DATA.fireRate
    self.dronesSpawned = 0
    self.maxDronesPerWave = 5

    -- Set Z-index
    self:setZIndex(75)

    print("Distinguished Professor boss spawned!")
end

function DistinguishedProfessor:update(dt)
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
    self.fireCooldown = self.fireCooldown - dt

    -- Check for enraged phase
    if self.health / self.maxHealth <= 0.3 and self.phase ~= DistinguishedProfessor.PHASES.ENRAGED then
        self:enterPhase(DistinguishedProfessor.PHASES.ENRAGED)
    end

    -- Execute current phase
    if self.phase == DistinguishedProfessor.PHASES.APPROACH then
        self:updateApproach(dt)
    elseif self.phase == DistinguishedProfessor.PHASES.LECTURING then
        self:updateLecturing(dt)
    elseif self.phase == DistinguishedProfessor.PHASES.SUMMONING then
        self:updateSummoning(dt)
    elseif self.phase == DistinguishedProfessor.PHASES.ENRAGED then
        self:updateEnraged(dt)
    end
end

function DistinguishedProfessor:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTimer = 0
    self.attackTimer = 0

    if newPhase == DistinguishedProfessor.PHASES.LECTURING then
        GameplayScene:showMessage("Preparing citations...")
    elseif newPhase == DistinguishedProfessor.PHASES.SUMMONING then
        self.dronesSpawned = 0
        GameplayScene:showMessage("Calling for peer review!")
    elseif newPhase == DistinguishedProfessor.PHASES.ENRAGED then
        GameplayScene:showMessage("YOUR METHODOLOGY IS FLAWED!")
        self.fireInterval = 0.6  -- Faster firing
        self.maxDronesPerWave = 7
    end
end

function DistinguishedProfessor:updateApproach(dt)
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
        self:enterPhase(DistinguishedProfessor.PHASES.LECTURING)
    end

    local angle = Utils.vectorToAngle(dx, dy)
    self:setRotation(angle)
end

function DistinguishedProfessor:updateLecturing(dt)
    self:orbitStation(dt)

    -- Fire citation beams
    if self.fireCooldown <= 0 then
        self:fireCitationBeam()
        self.fireCooldown = self.fireInterval
    end

    -- Switch to summoning after a while
    if self.phaseTimer >= 6 then
        self:enterPhase(DistinguishedProfessor.PHASES.SUMMONING)
    end
end

function DistinguishedProfessor:updateSummoning(dt)
    self:orbitStation(dt, 0.5)  -- Slower orbit while summoning

    -- Spawn debate drones
    if self.attackTimer >= 1.5 and self.dronesSpawned < self.maxDronesPerWave then
        self:spawnDebateDrone()
        self.attackTimer = 0
        self.dronesSpawned = self.dronesSpawned + 1
    end

    -- Return to lecturing after spawning all drones
    if self.dronesSpawned >= self.maxDronesPerWave and self.phaseTimer >= 5 then
        self:enterPhase(DistinguishedProfessor.PHASES.LECTURING)
    end
end

function DistinguishedProfessor:updateEnraged(dt)
    self:orbitStation(dt, 1.2)

    -- Rapid fire
    if self.fireCooldown <= 0 then
        self:fireCitationBeam()
        -- Fire additional beams occasionally
        if math.random() < 0.3 then
            self:fireCitationBeam(15)  -- Offset angle
            self:fireCitationBeam(-15)
        end
        self.fireCooldown = self.fireInterval
    end

    -- Occasionally summon drones
    if self.attackTimer >= 10 then
        self:spawnDroneSquad()
        self.attackTimer = 0
    end
end

function DistinguishedProfessor:orbitStation(dt, speedMult)
    speedMult = speedMult or 1.0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y

    local angle = math.atan(dy, dx)
    angle = angle + (self.speed * speedMult * 0.025 * dt * 30)

    self.x = self.targetX - math.cos(angle) * self.range
    self.y = self.targetY - math.sin(angle) * self.range
    self:moveTo(self.x, self.y)

    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

function DistinguishedProfessor:fireCitationBeam(angleOffset)
    angleOffset = angleOffset or 0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local angle = Utils.vectorToAngle(dx, dy) + angleOffset

    if GameplayScene and GameplayScene.createEnemyProjectile then
        GameplayScene:createEnemyProjectile(
            self.x, self.y,
            angle,
            DistinguishedProfessor.DATA.projectileSpeed,
            self.damage,
            DistinguishedProfessor.DATA.projectileImage,
            nil
        )
    else
        -- Fallback
        if GameplayScene and GameplayScene.station then
            if math.random() < 0.25 then
                GameplayScene.station:takeDamage(self.damage)
            end
        end
    end
end

function DistinguishedProfessor:spawnDebateDrone()
    if not GameplayScene then return end

    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 35
    local spawnY = self.y + math.sin(offsetAngle) * 35

    local drone = DebateDrone(spawnX, spawnY, { health = 1.2, damage = 1.1, speed = 1.2 })
    table.insert(GameplayScene.mobs, drone)
end

function DistinguishedProfessor:spawnDroneSquad()
    for i = 1, 5 do
        self:spawnDebateDrone()
    end
    GameplayScene:showMessage("Peer review squad!")
end

function DistinguishedProfessor:onDestroyed()
    self.active = false

    if GameManager then
        GameManager:awardRP(self.rpValue)
    end

    self:remove()

    GameplayScene:showMessage("Research... acceptable.")

    if GameManager then
        GameManager:endEpisode(true)
    end
end

-- Override health bar for boss
function DistinguishedProfessor:drawHealthBar()
    if not self.active then return end

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
    gfx.drawTextAligned("*DISTINGUISHED PROFESSOR*", Constants.SCREEN_WIDTH / 2, barY - 12, kTextAlignment.center)

    -- Health bar border
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(barX, barY, barWidth, barHeight)

    -- Health bar fill
    local fillWidth = (self.health / self.maxHealth) * (barWidth - 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX + 1, barY + 1, fillWidth, barHeight - 2)
end

return DistinguishedProfessor
