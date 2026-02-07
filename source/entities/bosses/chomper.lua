-- Chomper Boss (Episode 4)
-- Very large, very hungry, thinks your station might be food

local gfx <const> = playdate.graphics

class('Chomper').extends(MOB)

Chomper.DATA = {
    id = "chomper",
    name = "Chomper",
    description = "Very large. Very hungry.",
    imagePath = "images/episodes/ep4/ep4_boss_chomper",
    animPath = "images/episodes/ep4/ep4_boss_chomper",  -- Animation table (2 frames - chomping)
    frameDuration = 0.2,  -- 200ms per frame - chomping animation

    -- Boss stats (Episode 4)
    baseHealth = 1000,
    baseSpeed = 0.30,
    baseDamage = 14,
    rpValue = 180,

    -- Collision - larger boss
    width = 56,
    height = 56,
    range = 120,
    emits = false,  -- Ramming boss
}

-- Boss phases
Chomper.PHASES = {
    APPROACH = 1,       -- Moving into position
    CIRCLING = 2,       -- Circling the station
    CHARGING = 3,       -- Charging at the station
    RECOVERING = 4,     -- Recovering after a charge
    ENRAGED = 5,        -- Below 30% health - faster charges
}

function Chomper:init(x, y)
    Chomper.super.init(self, x, y, Chomper.DATA, { health = 1, damage = 1, speed = 1 })

    -- Boss-specific state
    self.phase = Chomper.PHASES.APPROACH
    self.phaseTimer = 0
    self.attackTimer = 0
    self.chargeTarget = { x = 0, y = 0 }
    self.chargeDirection = { x = 0, y = 0 }
    self.chargeTimer = 0

    -- Charge cooldown
    self.chargeCooldown = 6  -- Seconds between charges
    self.chargeSpeed = 5     -- Speed during charge

    -- Set Z-index (bosses above normal mobs)
    self:setZIndex(75)

    -- Unlock in database when encountered
    if SaveManager then
        SaveManager:unlockDatabaseEntry("bosses", "chomper")
    end
end

function Chomper:update(dt)
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

    -- Update animation (chomping effect)
    if self.animImageTable and self.frameCount > 1 then
        self:updateAnimation(dt)
    end

    -- Update timers
    self.phaseTimer = self.phaseTimer + dt
    self.attackTimer = self.attackTimer + dt

    -- Check for enraged phase
    if self.health / self.maxHealth <= 0.3 and self.phase ~= Chomper.PHASES.ENRAGED then
        self:enterPhase(Chomper.PHASES.ENRAGED)
    end

    -- Execute current phase
    if self.phase == Chomper.PHASES.APPROACH then
        self:updateApproach(dt)
    elseif self.phase == Chomper.PHASES.CIRCLING then
        self:updateCircling(dt)
    elseif self.phase == Chomper.PHASES.CHARGING then
        self:updateCharging(dt)
    elseif self.phase == Chomper.PHASES.RECOVERING then
        self:updateRecovering(dt)
    elseif self.phase == Chomper.PHASES.ENRAGED then
        self:updateEnraged(dt)
    end
end

function Chomper:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTimer = 0
    self.attackTimer = 0

    if newPhase == Chomper.PHASES.CIRCLING then
        GameplayScene:showMessage("It's circling...")
    elseif newPhase == Chomper.PHASES.CHARGING then
        GameplayScene:showMessage("INCOMING!")
    elseif newPhase == Chomper.PHASES.ENRAGED then
        GameplayScene:showMessage("IT'S ANGRY NOW!")
        self.chargeCooldown = 3  -- Faster charges when enraged
        self.chargeSpeed = 7
    end
end

function Chomper:updateApproach(dt)
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
        self:enterPhase(Chomper.PHASES.CIRCLING)
    end

    if dist > 0 then
        local angle = Utils.vectorToAngle(dx, dy)
        self:setRotation(angle)
    end
end

function Chomper:updateCircling(dt)
    self:orbitStation(dt)

    -- Check if it's time to charge
    if self.attackTimer >= self.chargeCooldown then
        self:startCharge()
    end
end

function Chomper:startCharge()
    -- Lock onto current station position
    self.chargeTarget.x = self.targetX
    self.chargeTarget.y = self.targetY

    -- Calculate charge direction
    local dx = self.chargeTarget.x - self.x
    local dy = self.chargeTarget.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.chargeDirection.x = dx / dist
        self.chargeDirection.y = dy / dist
    else
        self.chargeDirection.x = 0
        self.chargeDirection.y = -1
    end

    self.chargeTimer = 0
    self:enterPhase(Chomper.PHASES.CHARGING)
end

function Chomper:updateCharging(dt)
    self.chargeTimer = self.chargeTimer + dt

    -- Move in charge direction
    self.x = self.x + self.chargeDirection.x * self.chargeSpeed
    self.y = self.y + self.chargeDirection.y * self.chargeSpeed
    self:moveTo(self.x, self.y)

    -- Face charge direction
    local angle = Utils.vectorToAngle(self.chargeDirection.x, self.chargeDirection.y)
    self:setRotation(angle)

    -- Check for station collision during charge
    local dist = Utils.distance(self.x, self.y, self.targetX, self.targetY)
    if dist < Constants.STATION_RADIUS + 28 then
        self:onHitStation()
        self:enterPhase(Chomper.PHASES.RECOVERING)
        return
    end

    -- End charge after 2 seconds or if off screen
    if self.chargeTimer >= 2 or not self:isOnScreen(50) then
        self:enterPhase(Chomper.PHASES.RECOVERING)
    end
end

function Chomper:updateRecovering(dt)
    -- Move back toward orbit range
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        if dist > self.range then
            local moveX = (dx / dist) * self.speed * 0.5
            local moveY = (dy / dist) * self.speed * 0.5
            self.x = self.x + moveX
            self.y = self.y + moveY
            self:moveTo(self.x, self.y)
        elseif dist < self.range - 20 then
            -- Too close, back up
            local moveX = -(dx / dist) * self.speed * 0.5
            local moveY = -(dy / dist) * self.speed * 0.5
            self.x = self.x + moveX
            self.y = self.y + moveY
            self:moveTo(self.x, self.y)
        end

        local angle = Utils.vectorToAngle(dx, dy)
        self:setRotation(angle)
    end

    -- Return to circling after recovery time
    if self.phaseTimer >= 2 then
        self:enterPhase(Chomper.PHASES.CIRCLING)
    end
end

function Chomper:updateEnraged(dt)
    -- Faster orbit
    self:orbitStation(dt, 1.5)

    -- More frequent charges
    if self.attackTimer >= self.chargeCooldown then
        self:startCharge()
    end

    -- Spawn debris chunks when hit (done in takeDamage)
end

function Chomper:orbitStation(dt, speedMult)
    speedMult = speedMult or 1.0

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y

    local angle = math.atan(dy, dx)
    angle = angle + (self.speed * speedMult * 0.02 * dt * 30)

    self.x = self.targetX - math.cos(angle) * self.range
    self.y = self.targetY - math.sin(angle) * self.range
    self:moveTo(self.x, self.y)

    local faceAngle = Utils.vectorToAngle(self.targetX - self.x, self.targetY - self.y)
    self:setRotation(faceAngle)
end

function Chomper:onHitStation()
    if GameplayScene and GameplayScene.station then
        -- Calculate attack angle for shield check
        local dx = self.x - self.targetX
        local dy = self.y - self.targetY
        local attackAngle = math.atan(dx, -dy) * (180 / math.pi)
        GameplayScene.station:takeDamage(self.damage, attackAngle, "ram")
        -- Apply rotation slow on charge impact
        GameplayScene.station:applyDebuff("rotationSlow", 0.3, 3.0)
        GameplayScene:showMessage("CHOMP! Rotation jammed!", 1.5)
    end
end

-- Override takeDamage to spawn debris in enraged phase
function Chomper:takeDamage(amount)
    local killed = Chomper.super.takeDamage(self, amount)

    -- Spawn debris when hit in enraged phase
    if self.phase == Chomper.PHASES.ENRAGED and math.random() < 0.3 then
        self:spawnDebris()
    end

    return killed
end

function Chomper:spawnDebris()
    if not GameplayScene then return end

    local offsetAngle = math.random() * math.pi * 2
    local spawnX = self.x + math.cos(offsetAngle) * 40
    local spawnY = self.y + math.sin(offsetAngle) * 40

    local debris = DebrisChunk(spawnX, spawnY, { health = 0.8, damage = 0.8, speed = 1.2 })
    GameplayScene:queueMob(debris)
end

function Chomper:onDestroyed()
    self.active = false

    if GameManager then
        GameManager:awardRP(self.rpValue)
    end

    -- Save boss image for celebration before removing
    local bossImage = self:getImage()

    self:remove()

    -- Trigger boss defeat celebration
    if GameplayScene and GameplayScene.onBossDefeated then
        GameplayScene:onBossDefeated("Chomper", bossImage)
    elseif GameManager then
        GameManager:endEpisode(true)
    end
end

function Chomper:drawHealthBar()
    self:drawBossHealthBar("CHOMPER")
end

return Chomper
