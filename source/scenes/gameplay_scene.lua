-- Gameplay Scene
-- Main game loop where combat happens

local gfx <const> = playdate.graphics

-- Global reference for entities to access
GameplayScene = {}

function GameplayScene:init()
    -- Game state
    self.isPaused = false
    self.isLevelingUp = false
    self.elapsedTime = 0

    -- Entity references
    self.station = nil
    self.mobs = {}
    self.collectibles = {}

    -- Object pools
    self.projectilePool = nil
    self.enemyProjectilePool = nil

    -- Wave management (7 waves over 1 minute for testing)
    self.currentWave = 1
    self.spawnTimer = 0
    self.spawnInterval = 1.5  -- Start with 1.5 seconds between spawns
    self.waveStartTimes = { 0, 8, 16, 24, 32, 40, 48 }  -- Wave start times in seconds (~8s each)

    -- Boss tracking
    self.boss = nil
    self.bossSpawned = false

    -- Salvage drone (spawned by bonus item)
    self.salvageDrone = nil

    -- Background
    self.backgroundSprite = nil

    -- On-screen message system
    self.messages = {}
    self.messageY = 40  -- Y position for messages
end

-- Show a temporary message on screen
function GameplayScene:showMessage(text, duration)
    duration = duration or 2.0
    table.insert(self.messages, {
        text = text,
        timer = duration,
        maxTimer = duration,
    })
end

-- Update messages (fade out over time)
function GameplayScene:updateMessages(dt)
    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        msg.timer = msg.timer - dt
        if msg.timer <= 0 then
            table.remove(self.messages, i)
        end
    end
end

-- Draw messages with white text and black stroke (floating, no box)
function GameplayScene:drawMessages()
    local y = self.messageY
    for i, msg in ipairs(self.messages) do
        -- Fade out in last 0.5 seconds
        local alpha = 1.0
        if msg.timer < 0.5 then
            alpha = msg.timer / 0.5
        end

        -- Only draw if visible
        if alpha > 0.1 then
            local centerX = Constants.SCREEN_WIDTH / 2

            -- Draw black stroke (outline) by drawing text offset in all directions
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            local offsets = { {-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1} }
            for _, offset in ipairs(offsets) do
                gfx.drawTextAligned(msg.text, centerX + offset[1], y + offset[2], kTextAlignment.center)
            end

            -- Draw white text on top
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned(msg.text, centerX, y, kTextAlignment.center)

            -- Reset draw mode
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        y = y + 18  -- Tighter spacing
    end
end

function GameplayScene:enter(params)
    print("Entering gameplay scene for Episode " .. (GameManager.currentEpisodeId or "nil"))

    -- Clear any existing sprites
    gfx.sprite.removeAll()

    -- Reset state
    self.isPaused = false
    self.isLevelingUp = false
    self.elapsedTime = 0
    self.currentWave = 1
    self.spawnTimer = 0
    self.mobs = {}
    self.collectibles = {}
    self.messages = {}
    self.boss = nil
    self.bossSpawned = false
    self.salvageDrone = nil

    -- Initialize upgrade system for this episode
    UpgradeSystem:reset()
    UpgradeSystem:setEpisode(GameManager.currentEpisodeId or 1)

    -- Create projectile pools
    self.projectilePool = ProjectilePool(50)
    self.enemyProjectilePool = EnemyProjectilePool(30)

    -- Create station
    self.station = Station()

    -- Give station a starting tool (Rail Driver)
    local railDriver = RailDriver()
    self.station:attachTool(railDriver)

    -- Load background based on current episode
    local episodeId = GameManager.currentEpisodeId or 1
    local episodeData = EpisodesData.get(episodeId)
    local bgPath = episodeData and episodeData.backgroundPath or "images/episodes/ep1/bg_ep1"

    local bgImage = gfx.image.new(bgPath)
    if bgImage then
        local w, h = bgImage:getSize()
        print("Background loaded for Episode " .. episodeId .. ": " .. w .. "x" .. h)

        -- Create background sprite at lowest Z-index
        self.backgroundSprite = gfx.sprite.new(bgImage)
        self.backgroundSprite:setCenter(0, 0)  -- Top-left corner
        self.backgroundSprite:moveTo(0, 0)
        self.backgroundSprite:setZIndex(-1000)  -- Behind everything
        self.backgroundSprite:add()
    else
        print("WARNING: Background failed to load for Episode " .. episodeId .. "!")
    end

    print("Gameplay scene initialized")
end

function GameplayScene:update()
    -- Update upgrade selection UI if visible (before early return)
    if self.isLevelingUp and UpgradeSelection.isVisible then
        UpgradeSelection:update()
        return
    end

    if self.isPaused or self.isLevelingUp then
        return
    end

    local dt = 1/30

    -- Update elapsed time
    self.elapsedTime = self.elapsedTime + dt

    -- Update station
    self.station:update()

    -- Update tools
    for _, tool in ipairs(self.station.tools) do
        tool:update(dt)
    end

    -- Update projectiles
    self.projectilePool:update()
    self.enemyProjectilePool:update()

    -- Update MOBs
    self:updateMOBs(dt)

    -- Update collectibles
    self:updateCollectibles(dt)

    -- Spawn new MOBs
    self:updateSpawning(dt)

    -- Check collisions
    self:checkCollisions()

    -- Check win/lose conditions
    self:checkGameConditions()

    -- Update on-screen messages
    self:updateMessages(dt)
end

function GameplayScene:updateMOBs(dt)
    for i = #self.mobs, 1, -1 do
        local mob = self.mobs[i]
        if mob.active then
            mob:update(dt)
        else
            table.remove(self.mobs, i)
        end
    end
end

function GameplayScene:updateCollectibles(dt)
    for i = #self.collectibles, 1, -1 do
        local collectible = self.collectibles[i]
        if collectible.active then
            collectible:update(dt)
        else
            table.remove(self.collectibles, i)
        end
    end

    -- Update salvage drone (if present)
    if self.salvageDrone and self.salvageDrone.active then
        self.salvageDrone:update()
    end
end

function GameplayScene:updateSpawning(dt)
    -- Update current wave based on elapsed time
    self:updateWave()

    self.spawnTimer = self.spawnTimer - dt

    if self.spawnTimer <= 0 then
        self:spawnMOB()
        self.spawnTimer = self.spawnInterval
    end
end

function GameplayScene:updateWave()
    -- Check if we should advance to next wave
    for i = #self.waveStartTimes, 1, -1 do
        if self.elapsedTime >= self.waveStartTimes[i] and self.currentWave < i then
            self.currentWave = i
            self:onWaveStart(i)
            break
        end
    end
end

function GameplayScene:onWaveStart(waveNum)
    print("Wave " .. waveNum .. " started!")

    -- Play wave start sound
    AudioManager:playSFX("wave_start")

    -- Adjust spawn rate based on wave
    -- Earlier waves: slower spawns, later waves: faster spawns
    local spawnRates = { 2.0, 1.8, 1.5, 1.3, 1.1, 0.9, 0.7 }
    self.spawnInterval = spawnRates[waveNum] or 0.7

    -- Show wave message with MOB types
    local mobTypes = self:getWaveMOBTypes(waveNum)
    self:showMessage("Wave " .. waveNum .. ": " .. mobTypes, 3.0)
end

-- Get MOB types for wave announcement
function GameplayScene:getWaveMOBTypes(waveNum)
    local episodeId = GameManager.currentEpisodeId or 1

    if episodeId == 1 then
        if waveNum <= 2 then
            return "Greeting Drones"
        elseif waveNum <= 4 then
            return "Greeting Drones, Silk Weavers"
        else
            return "Greeting Drones, Silk Weavers!"
        end
    elseif episodeId == 2 then
        if waveNum <= 2 then
            return "Survey Drones"
        elseif waveNum <= 4 then
            return "Survey Drones, Efficiency Monitors"
        else
            return "Efficiency Monitors incoming!"
        end
    elseif episodeId == 3 then
        if waveNum <= 2 then
            return "Probability Fluctuations"
        elseif waveNum <= 4 then
            return "Fluctuations, Paradox Nodes"
        else
            return "Reality is unstable!"
        end
    elseif episodeId == 4 then
        if waveNum <= 2 then
            return "Debris Chunks"
        elseif waveNum <= 4 then
            return "Debris, Defense Turrets"
        else
            return "Ancient war zone!"
        end
    elseif episodeId == 5 then
        if waveNum <= 2 then
            return "Debate Drones"
        elseif waveNum <= 4 then
            return "Drones, Citation Platforms"
        else
            return "Peer review intensifies!"
        end
    else
        return "Unknown threats"
    end
end

function GameplayScene:spawnMOB()
    -- Limit active MOBs
    if #self.mobs >= Constants.MAX_ACTIVE_MOBS then
        return
    end

    -- Random spawn position on screen edge
    local x, y = Utils.randomEdgePoint(30)

    -- Wave multipliers (scaling difficulty)
    local multipliers = {
        health = 1.0 + (self.currentWave - 1) * 0.15,
        damage = 1.0 + (self.currentWave - 1) * 0.1,
        speed = 1.0
    }

    -- Choose MOB type based on wave and randomness
    local mob = self:chooseMOBType(x, y, multipliers)
    if mob then
        table.insert(self.mobs, mob)
    end
end

function GameplayScene:chooseMOBType(x, y, multipliers)
    local roll = math.random(100)
    local episodeId = GameManager.currentEpisodeId or 1

    -- Debug: Log episode ID occasionally
    if math.random(100) <= 5 then
        print("Spawning MOB for Episode " .. episodeId)
    end

    -- Episode-specific MOB spawning
    if episodeId == 1 then
        return self:chooseEpisode1MOB(x, y, multipliers, roll)
    elseif episodeId == 2 then
        return self:chooseEpisode2MOB(x, y, multipliers, roll)
    elseif episodeId == 3 then
        return self:chooseEpisode3MOB(x, y, multipliers, roll)
    elseif episodeId == 4 then
        return self:chooseEpisode4MOB(x, y, multipliers, roll)
    elseif episodeId == 5 then
        return self:chooseEpisode5MOB(x, y, multipliers, roll)
    else
        -- Default to Episode 1 spawning for unimplemented episodes
        return self:chooseEpisode1MOB(x, y, multipliers, roll)
    end
end

-- Episode 1: Spider planet - Greeting Drones, Silk Weavers, Asteroids
function GameplayScene:chooseEpisode1MOB(x, y, multipliers, roll)
    if self.currentWave <= 2 then
        if roll <= 70 then
            return GreetingDrone(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        if roll <= 50 then
            return GreetingDrone(x, y, multipliers)
        elseif roll <= 75 then
            return Asteroid(x, y, multipliers, math.random(1, 2))
        else
            return SilkWeaver(x, y, multipliers)
        end
    elseif self.currentWave <= 6 then
        if roll <= 40 then
            return GreetingDrone(x, y, multipliers)
        elseif roll <= 60 then
            return Asteroid(x, y, multipliers, math.random(1, 3))
        else
            return SilkWeaver(x, y, multipliers)
        end
    else
        if roll <= 30 then
            return GreetingDrone(x, y, multipliers)
        elseif roll <= 50 then
            return Asteroid(x, y, multipliers, math.random(2, 3))
        else
            return SilkWeaver(x, y, multipliers)
        end
    end
end

-- Episode 2: Corporate bureaucracy - Survey Drones and Efficiency Monitors
function GameplayScene:chooseEpisode2MOB(x, y, multipliers, roll)
    -- Slightly tougher multipliers for Episode 2
    multipliers.health = multipliers.health * 1.2
    multipliers.damage = multipliers.damage * 1.1

    if self.currentWave <= 2 then
        -- Early waves: Mostly Survey Drones
        if roll <= 70 then
            return SurveyDrone(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        -- Mid waves: Mix of Survey Drones and Efficiency Monitors
        if roll <= 50 then
            return SurveyDrone(x, y, multipliers)
        elseif roll <= 80 then
            return EfficiencyMonitor(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(1, 2))
        end
    else
        -- Late waves: Heavy Efficiency Monitor presence
        if roll <= 35 then
            return SurveyDrone(x, y, multipliers)
        elseif roll <= 75 then
            return EfficiencyMonitor(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(2, 3))
        end
    end
end

-- Episode 3: Probability anomaly zone - Probability Fluctuations and Paradox Nodes
function GameplayScene:chooseEpisode3MOB(x, y, multipliers, roll)
    -- Episode 3 has weird reality-bending stuff
    multipliers.health = multipliers.health * 1.3
    multipliers.damage = multipliers.damage * 1.15

    if self.currentWave <= 2 then
        -- Early waves: Mostly Probability Fluctuations
        if roll <= 70 then
            return ProbabilityFluctuation(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        -- Mid waves: Mix of Fluctuations and Paradox Nodes
        if roll <= 50 then
            return ProbabilityFluctuation(x, y, multipliers)
        elseif roll <= 80 then
            return ParadoxNode(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(1, 2))
        end
    else
        -- Late waves: Heavy Paradox Node presence
        if roll <= 35 then
            return ProbabilityFluctuation(x, y, multipliers)
        elseif roll <= 75 then
            return ParadoxNode(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(2, 3))
        end
    end
end

-- Episode 4: Debris field - Debris Chunks and Defense Turrets
function GameplayScene:chooseEpisode4MOB(x, y, multipliers, roll)
    -- Episode 4 is salvage themed
    multipliers.health = multipliers.health * 1.35
    multipliers.damage = multipliers.damage * 1.2

    if self.currentWave <= 2 then
        -- Early waves: Mostly Debris Chunks
        if roll <= 80 then
            return DebrisChunk(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        -- Mid waves: Mix of Debris and Defense Turrets
        if roll <= 50 then
            return DebrisChunk(x, y, multipliers)
        elseif roll <= 85 then
            return DefenseTurret(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(1, 2))
        end
    else
        -- Late waves: Heavy Turret presence
        if roll <= 35 then
            return DebrisChunk(x, y, multipliers)
        elseif roll <= 80 then
            return DefenseTurret(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(2, 3))
        end
    end
end

-- Episode 5: Academic conference - Debate Drones and Citation Platforms
function GameplayScene:chooseEpisode5MOB(x, y, multipliers, roll)
    -- Episode 5 is the final challenge
    multipliers.health = multipliers.health * 1.4
    multipliers.damage = multipliers.damage * 1.25

    if self.currentWave <= 2 then
        -- Early waves: Mostly Debate Drones
        if roll <= 75 then
            return DebateDrone(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        -- Mid waves: Mix of Drones and Citation Platforms
        if roll <= 50 then
            return DebateDrone(x, y, multipliers)
        elseif roll <= 85 then
            return CitationPlatform(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(1, 2))
        end
    else
        -- Late waves: Heavy Citation Platform presence
        if roll <= 30 then
            return DebateDrone(x, y, multipliers)
        elseif roll <= 80 then
            return CitationPlatform(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(2, 3))
        end
    end
end

function GameplayScene:checkCollisions()
    -- Projectiles vs MOBs
    local projectiles = self.projectilePool:getActive()

    for _, proj in ipairs(projectiles) do
        if proj.active then
            for _, mob in ipairs(self.mobs) do
                if mob.active then
                    -- Simple distance check
                    local dist = Utils.distance(proj.x, proj.y, mob.x, mob.y)
                    local collisionDist = 12  -- Combined radius estimate

                    if dist < collisionDist then
                        -- Hit!
                        local killed = mob:takeDamage(proj:getDamage())
                        proj:onHit(mob)

                        if not proj.active then
                            break  -- Projectile used up
                        end
                    end
                end
            end
        end
    end

    -- MOBs vs Station (circular collision)
    for _, mob in ipairs(self.mobs) do
        if mob.active and not mob.emits then
            local dist = Utils.distance(mob.x, mob.y, self.station.x, self.station.y)
            local collisionDist = Constants.STATION_RADIUS + mob:getRadius()

            if dist < collisionDist then
                -- Calculate attack angle (direction MOB approached from)
                local attackAngle = Utils.vectorToAngle(mob.x - self.station.x, mob.y - self.station.y)
                -- MOB hit station (pass attack angle for shield check)
                self.station:takeDamage(mob.damage, attackAngle)
                mob:onDestroyed()
            end
        end
    end

    -- Enemy Projectiles vs Station
    local enemyProjectiles = self.enemyProjectilePool:getActive()
    for _, proj in ipairs(enemyProjectiles) do
        if proj.active then
            local dist = Utils.distance(proj.x, proj.y, self.station.x, self.station.y)
            if dist < Constants.STATION_RADIUS + 4 then
                -- Calculate attack angle for shield check
                local attackAngle = Utils.vectorToAngle(proj.x - self.station.x, proj.y - self.station.y)
                -- Hit station!
                self.station:takeDamage(proj:getDamage(), attackAngle)

                -- Apply special effects
                local effect = proj:getEffect()
                if effect == "slow" then
                    self.station.rotationSlow = 0.5
                    self.station.rotationSlowTimer = 2.0
                end

                proj:deactivate()
            end
        end
    end
end

function GameplayScene:checkGameConditions()
    -- Check for game over
    if self.station.health <= 0 then
        GameManager:endEpisode(false)
    end

    -- Check for boss spawn
    -- Debug mode: 1 minute, Normal mode: 7 minutes
    local debugMode = SaveManager and SaveManager:getSetting("debugMode", false)
    local bossSpawnTime = debugMode and 60 or 420

    if self.elapsedTime >= bossSpawnTime and not self.bossSpawned then
        self:spawnBoss()
    end

    -- Update boss if active
    if self.boss and self.boss.active then
        self.boss:update(1/30)
    end
end

function GameplayScene:spawnBoss()
    self.bossSpawned = true

    -- Play boss warning sound
    AudioManager:playSFX("boss_warning")

    -- Spawn boss at edge of screen
    local x, y = Utils.randomEdgePoint(50)

    -- Create boss based on episode
    local episodeId = GameManager.currentEpisodeId or 1

    if episodeId == 1 then
        print("BOSS TIME! Spawning Cultural Attache!")
        self:showMessage("BOSS: Cultural Attache!", 3.0)
        self.boss = CulturalAttache(x, y)
    elseif episodeId == 2 then
        print("BOSS TIME! Spawning Productivity Liaison!")
        self:showMessage("BOSS: Productivity Liaison!", 3.0)
        self.boss = ProductivityLiaison(x, y)
    elseif episodeId == 3 then
        print("BOSS TIME! Spawning Improbability Engine!")
        self:showMessage("BOSS: Improbability Engine!", 3.0)
        self.boss = ImprobabilityEngine(x, y)
    elseif episodeId == 4 then
        print("BOSS TIME! Spawning Chomper!")
        self:showMessage("BOSS: Chomper!", 3.0)
        self.boss = Chomper(x, y)
    elseif episodeId == 5 then
        print("BOSS TIME! Spawning Distinguished Professor!")
        self:showMessage("BOSS: Distinguished Professor!", 3.0)
        self.boss = DistinguishedProfessor(x, y)
    else
        -- Default to Episode 1 boss
        self.boss = CulturalAttache(x, y)
    end

    table.insert(self.mobs, self.boss)

    -- Stop regular mob spawning (or slow it down significantly)
    self.spawnInterval = 5.0
end

-- Called from Tool when it fires
function GameplayScene:createProjectile(x, y, angle, speed, damage, imagePath, piercing)
    return self.projectilePool:get(x, y, angle, speed, damage, imagePath, piercing)
end

-- Called from MOBs when they fire at the station
function GameplayScene:createEnemyProjectile(x, y, angle, speed, damage, imagePath, effect)
    return self.enemyProjectilePool:get(x, y, angle, speed, damage, imagePath, effect)
end

-- Draw background (called before sprite.update)
function GameplayScene:drawBackground()
    -- Background is now a sprite, so nothing to do here
    -- The sprite system will draw it automatically
end

-- Draw overlay (HUD elements - called after sprite.update)
function GameplayScene:drawOverlay()
    -- Draw MOB health bars and debug labels
    for _, mob in ipairs(self.mobs) do
        mob:drawHealthBar()
        -- DEBUG: Draw MOB type labels to diagnose sprite issues
        if mob.drawDebugLabel then
            mob:drawDebugLabel()
        end
    end

    -- Draw shield effect (before HUD so it's behind UI elements)
    self.station:drawShield()

    -- Draw HUD
    self:drawHUD()

    -- Draw on-screen messages
    self:drawMessages()

    -- Draw upgrade selection UI if visible (drawn on top of everything)
    if self.isLevelingUp and UpgradeSelection.isVisible then
        UpgradeSelection:draw()
    end
end

function GameplayScene:drawHUD()
    -- RP Bar (top of screen) - thin line
    local rpPercent = GameManager.currentRP / GameManager.rpToNextLevel
    rpPercent = Utils.clamp(rpPercent, 0, 1)

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 6)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(1, 1, (Constants.SCREEN_WIDTH - 2) * rpPercent, 4)

    -- Top info bar background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 6, Constants.SCREEN_WIDTH, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 24, Constants.SCREEN_WIDTH, 24)

    -- Timer (top left) - larger and bold
    local timeStr = Utils.formatTime(self.elapsedTime)
    gfx.drawText("*" .. timeStr .. "*", 8, 8)

    -- Wave (top center)
    gfx.drawTextAligned("Wave " .. self.currentWave, Constants.SCREEN_WIDTH / 2, 8, kTextAlignment.center)

    -- Level (top right)
    gfx.drawTextAligned("*Lv." .. GameManager.playerLevel .. "*", Constants.SCREEN_WIDTH - 8, 8, kTextAlignment.right)

    -- Bottom HUD bar background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)

    -- Health Bar (bottom right)
    local healthBarWidth = 100
    local healthBarHeight = 12
    local healthBarX = Constants.SCREEN_WIDTH - healthBarWidth - 8
    local healthBarY = Constants.SCREEN_HEIGHT - 18

    -- Health percentage
    local healthPercent = self.station.health / self.station.maxHealth
    healthPercent = Utils.clamp(healthPercent, 0, 1)

    -- Draw health bar border
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(healthBarX - 1, healthBarY - 1, healthBarWidth + 2, healthBarHeight + 2)

    -- Draw health bar background (empty = black)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(healthBarX, healthBarY, healthBarWidth, healthBarHeight)

    -- Draw health bar fill (white = health remaining)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight)

    -- Draw health text next to bar
    local healthStr = math.floor(self.station.health) .. "/" .. self.station.maxHealth
    gfx.drawTextAligned(healthStr, healthBarX - 6, healthBarY, kTextAlignment.right)

    -- Draw boss health bar AFTER the HUD (so it's not covered by the white background)
    if self.boss and self.boss.active then
        self.boss:drawHealthBar()
    end
end

function GameplayScene:onLevelUp()
    -- Get upgrade options from the upgrade system
    local toolOptions, bonusOptions = UpgradeSystem:getUpgradeOptions(self.station)

    -- If no options available, skip the level up UI
    if #toolOptions == 0 and #bonusOptions == 0 then
        print("Level up! No upgrades available - skipping UI")
        return
    end

    print("Level up! Showing upgrade selection...")
    self.isLevelingUp = true

    -- Play level up sound
    AudioManager:playSFX("level_up")

    -- Show the upgrade selection UI
    UpgradeSelection:show(toolOptions, bonusOptions, function(selectionType, selectionData)
        -- Callback when player makes a selection
        self:onUpgradeSelected(selectionType, selectionData)
    end)
end

-- Called when player selects an upgrade
function GameplayScene:onUpgradeSelected(selectionType, selectionData)
    print("Selected " .. selectionType .. ": " .. (selectionData.name or "unknown"))

    if selectionType == "tool" then
        UpgradeSystem:applyToolSelection(selectionData, self.station)
    else
        UpgradeSystem:applyBonusSelection(selectionData, self.station)
    end

    -- Resume gameplay
    self.isLevelingUp = false
end

function GameplayScene:exit()
    print("Exiting gameplay scene")

    -- Clean up
    self.projectilePool:releaseAll()
    self.enemyProjectilePool:releaseAll()
    gfx.sprite.removeAll()
end

return GameplayScene
