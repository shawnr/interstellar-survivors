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

    -- Mission intro overlay state
    self.showingMissionIntro = false
    self.missionIntroTimer = 0
    self.missionIntroFadeTimer = 0
    self.missionText = ""

    -- Crank indicator state
    self.showCrankIndicator = false

    -- Boss defeat celebration state
    self.showingBossDefeated = false
    self.bossDefeatedTimer = 0
    self.defeatedBossName = ""
    self.bossDefeatedImage = nil
    self.bossZoomScale = 1.0

    -- Episode statistics tracking
    self.stats = {
        mobKills = {},      -- { mobType = count }
        toolsObtained = {}, -- { toolId = true }
        itemsObtained = {}, -- { itemId = true }
        totalRP = 0,
    }

    -- Equipment slot icon cache
    self.toolSlotIcons = {}
    self.itemSlotIcons = {}
end

-- Track a mob kill
function GameplayScene:trackMobKill(mobType)
    self.stats.mobKills[mobType] = (self.stats.mobKills[mobType] or 0) + 1
end

-- Track tool obtained
function GameplayScene:trackToolObtained(toolId)
    self.stats.toolsObtained[toolId] = true
end

-- Track bonus item obtained
function GameplayScene:trackItemObtained(itemId)
    self.stats.itemsObtained[itemId] = true
end

-- Track RP gained
function GameplayScene:trackRP(amount)
    self.stats.totalRP = self.stats.totalRP + amount
end

-- Get current episode stats
function GameplayScene:getStats()
    return {
        mobKills = self.stats.mobKills,
        toolsObtained = self.stats.toolsObtained,
        itemsObtained = self.stats.itemsObtained,
        totalRP = self.stats.totalRP,
        elapsedTime = self.elapsedTime,
        playerLevel = GameManager.playerLevel,
    }
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

-- Update mission intro overlay (2 sec visible, 1 sec fade)
function GameplayScene:updateMissionIntro(dt)
    if self.missionIntroTimer > 0 then
        -- Still in visible phase
        self.missionIntroTimer = self.missionIntroTimer - dt
    elseif self.missionIntroFadeTimer < 1.0 then
        -- In fade phase
        self.missionIntroFadeTimer = self.missionIntroFadeTimer + dt
        if self.missionIntroFadeTimer >= 1.0 then
            -- Intro complete, start gameplay
            self.showingMissionIntro = false
            self.isPaused = false
            print("Mission intro complete - starting gameplay")

            -- Check if crank is docked and show indicator if so
            if playdate.isCrankDocked() and playdate.ui and playdate.ui.crankIndicator then
                self.showCrankIndicator = true
                playdate.ui.crankIndicator:start()
            end
        end
    end
end

-- Draw mission intro overlay
function GameplayScene:drawMissionIntro()
    if not self.showingMissionIntro then return end

    -- Calculate alpha (1.0 during visible, fade to 0 during fade)
    local alpha = 1.0
    if self.missionIntroTimer <= 0 then
        alpha = 1.0 - self.missionIntroFadeTimer
    end

    -- Only draw if visible enough
    if alpha < 0.1 then return end

    local centerX = Constants.SCREEN_WIDTH / 2
    local centerY = Constants.SCREEN_HEIGHT / 2

    -- Draw semi-transparent overlay during visible phase (dithered)
    if alpha > 0.5 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.3)
        gfx.fillRect(0, centerY - 40, Constants.SCREEN_WIDTH, 80)
        gfx.setDitherPattern(0)
    end

    -- Draw mission text with larger emphasis
    local text = "*" .. self.missionText .. "*"  -- Bold

    -- Use dithering for fade effect on text (draw in layers)
    if alpha > 0.7 then
        -- Full visibility
        -- Black stroke
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        local offsets = { {-2, -2}, {0, -2}, {2, -2}, {-2, 0}, {2, 0}, {-2, 2}, {0, 2}, {2, 2} }
        for _, offset in ipairs(offsets) do
            gfx.drawTextAligned(text, centerX + offset[1], centerY - 8 + offset[2], kTextAlignment.center)
        end
        -- White text
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(text, centerX, centerY - 8, kTextAlignment.center)
    elseif alpha > 0.3 then
        -- Partial fade - use dithering
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.setDitherPattern(1.0 - alpha)
        gfx.drawTextAligned(text, centerX, centerY - 8, kTextAlignment.center)
        gfx.setDitherPattern(0)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Called when a boss is defeated (instead of calling GameManager:endEpisode directly)
function GameplayScene:onBossDefeated(bossName, bossImage)
    print("Boss defeated! Starting celebration for: " .. bossName)

    -- Play boss defeated sound
    if AudioManager then
        AudioManager:playSFX("boss_defeated")
    end

    -- Store celebration state
    self.showingBossDefeated = true
    self.bossDefeatedTimer = 0
    self.defeatedBossName = bossName
    self.bossDefeatedImage = bossImage
    self.bossZoomScale = 1.0

    -- Pause gameplay
    self.isPaused = true
end

-- Update boss defeat celebration
function GameplayScene:updateBossDefeated(dt)
    self.bossDefeatedTimer = self.bossDefeatedTimer + dt

    -- Zoom effect: scale up over time (pixelation effect)
    if self.bossDefeatedTimer < 1.5 then
        -- Zoom in over 1.5 seconds (1.0 -> 8.0)
        self.bossZoomScale = 1.0 + (self.bossDefeatedTimer / 1.5) * 7.0
    else
        self.bossZoomScale = 8.0
    end

    -- Check for button press to skip (after minimum 1 second)
    if self.bossDefeatedTimer > 1.0 then
        if playdate.buttonJustPressed(playdate.kButtonA) or
           playdate.buttonJustPressed(playdate.kButtonB) then
            self:endBossCelebration()
            return
        end
    end

    -- Auto-advance after 3 seconds
    if self.bossDefeatedTimer >= 3.0 then
        self:endBossCelebration()
    end
end

-- End boss celebration and proceed to ending panels
function GameplayScene:endBossCelebration()
    print("Boss celebration complete - proceeding to ending")
    self.showingBossDefeated = false
    self.isPaused = false
    GameManager:endEpisode(true)
end

-- Draw boss defeat celebration
function GameplayScene:drawBossDefeated()
    if not self.showingBossDefeated then return end

    local centerX = Constants.SCREEN_WIDTH / 2
    local centerY = Constants.SCREEN_HEIGHT / 2

    -- Draw darkened background overlay
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Draw zoomed/pixelated boss image
    if self.bossDefeatedImage then
        local scale = math.floor(self.bossZoomScale)
        if scale < 1 then scale = 1 end

        local imgW, imgH = self.bossDefeatedImage:getSize()

        -- For pixelation effect: scale down then up using nearest neighbor
        -- Create a scaled version
        local scaledW = imgW * scale
        local scaledH = imgH * scale

        -- Draw centered
        local drawX = centerX - scaledW / 2
        local drawY = centerY - scaledH / 2 - 20  -- Shift up to make room for text

        -- Draw the image scaled (Playdate will use nearest neighbor for pixelated look)
        self.bossDefeatedImage:drawScaled(drawX, drawY, scale)
    end

    -- Draw "[BOSS_NAME] defeated!" text
    local text = "*" .. self.defeatedBossName .. " defeated!*"

    -- Text position below the image
    local textY = centerY + 50

    -- Draw black stroke
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    local offsets = { {-2, -2}, {0, -2}, {2, -2}, {-2, 0}, {2, 0}, {-2, 2}, {0, 2}, {2, 2} }
    for _, offset in ipairs(offsets) do
        gfx.drawTextAligned(text, centerX + offset[1], textY + offset[2], kTextAlignment.center)
    end

    -- Draw white text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(text, centerX, textY, kTextAlignment.center)

    -- Draw "Press any button" hint after 1 second
    if self.bossDefeatedTimer > 1.0 then
        local hintText = "Press A or B to continue"
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(hintText, centerX, textY + 25, kTextAlignment.center)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function GameplayScene:enter(params)
    -- Stop title/menu music when starting gameplay
    if AudioManager then
        AudioManager:stopMusic()
    end

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

    -- Set wave timing based on debug mode
    local isDebugMode = SaveManager and SaveManager:getSetting("debugMode", false)
    if isDebugMode then
        -- Debug mode: Fast waves for testing (~8 seconds each, boss at ~1 minute)
        self.waveStartTimes = { 0, 8, 16, 24, 32, 40, 48 }
    else
        -- Normal mode: 1 minute per wave (boss at 7 minutes)
        self.waveStartTimes = { 0, 60, 120, 180, 240, 300, 360 }
    end

    -- Set initial spawn interval based on episode difficulty
    -- Episode 1: 1.8s, Episodes 2+: much faster (0.9s, 0.8s, 0.7s, 0.6s)
    local episodeSpawnIntervals = { 1.8, 0.9, 0.8, 0.7, 0.6 }
    local episodeId = GameManager.currentEpisodeId or 1
    self.spawnInterval = episodeSpawnIntervals[episodeId] or 1.5

    -- Reset boss defeat state
    self.showingBossDefeated = false
    self.bossDefeatedTimer = 0
    self.defeatedBossName = ""
    self.bossDefeatedImage = nil
    self.bossZoomScale = 1.0

    -- Reset crank indicator state (will be activated after mission intro if needed)
    self.showCrankIndicator = false

    -- Reset episode statistics
    self.stats = {
        mobKills = {},
        toolsObtained = {},
        itemsObtained = {},
        totalRP = 0,
    }

    -- Clear equipment slot icon caches
    self.toolSlotIcons = {}
    self.itemSlotIcons = {}

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
        -- Create background sprite at lowest Z-index
        self.backgroundSprite = gfx.sprite.new(bgImage)
        self.backgroundSprite:setCenter(0, 0)  -- Top-left corner
        self.backgroundSprite:moveTo(0, 0)
        self.backgroundSprite:setZIndex(-1000)  -- Behind everything
        self.backgroundSprite:add()
    end

    -- Set up mission intro overlay
    self.missionText = episodeData and episodeData.startingMessage or "MISSION START"
    self.showingMissionIntro = true
    self.missionIntroTimer = 2.0  -- Show for 2 seconds
    self.missionIntroFadeTimer = 0
    self.isPaused = true  -- Pause game during intro
end

function GameplayScene:update()
    local dt = 1/30

    -- Update mission intro overlay
    if self.showingMissionIntro then
        self:updateMissionIntro(dt)
        return
    end

    -- Update boss defeat celebration
    if self.showingBossDefeated then
        self:updateBossDefeated(dt)
        return
    end

    -- Update upgrade selection UI if visible (before early return)
    if self.isLevelingUp and UpgradeSelection.isVisible then
        UpgradeSelection:update()
        return
    end

    if self.isPaused or self.isLevelingUp then
        return
    end

    -- Update elapsed time
    self.elapsedTime = self.elapsedTime + dt

    -- Update station
    self.station:update()

    -- Update tools
    for i, tool in ipairs(self.station.tools) do
        local success, err = pcall(function()
            tool:update(dt)
        end)
        if not success then
            print("ERROR updating tool " .. i .. " (" .. (tool.data.id or "unknown") .. "): " .. tostring(err))
        end
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

    -- Base spawn rates per wave (slightly faster than before for more action)
    -- Earlier waves: slower spawns, later waves: faster spawns
    local spawnRates = { 1.8, 1.5, 1.2, 1.0, 0.8, 0.6, 0.5 }
    local baseInterval = spawnRates[waveNum] or 0.5

    -- Episode difficulty multiplier (lower = faster spawns = harder)
    -- Episode 1: baseline, Episodes 2+: progressively harder
    local episodeId = GameManager.currentEpisodeId or 1
    local episodeMultipliers = { 1.0, 0.5, 0.45, 0.4, 0.35 }  -- Ep2+ spawn 2x+ faster
    local episodeMult = episodeMultipliers[episodeId] or 0.35

    -- Player level scaling (higher level = more mobs)
    -- Every 3 levels, spawn rate decreases by 10%
    local playerLevel = GameManager.playerLevel or 1
    local levelMult = 1.0 - (math.floor((playerLevel - 1) / 3) * 0.1)
    levelMult = math.max(levelMult, 0.5)  -- Cap at 50% reduction (2x spawn rate)

    -- Calculate final spawn interval
    self.spawnInterval = baseInterval * episodeMult * levelMult
    print("Spawn interval: " .. string.format("%.2f", self.spawnInterval) ..
          " (ep" .. episodeId .. " mult=" .. episodeMult ..
          ", level " .. playerLevel .. " mult=" .. string.format("%.2f", levelMult) .. ")")

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

    -- Determine how many mobs to spawn this cycle
    -- Higher episodes and player levels spawn multiple mobs more often
    local episodeId = GameManager.currentEpisodeId or 1
    local playerLevel = GameManager.playerLevel or 1

    -- Base chance to spawn extra mob: 0% ep1, 30% ep2, 45% ep3, 55% ep4, 65% ep5
    local extraMobChance = (episodeId - 1) * 15
    -- Add 5% per 2 player levels
    extraMobChance = extraMobChance + math.floor(playerLevel / 2) * 5
    extraMobChance = math.min(extraMobChance, 80)  -- Cap at 80%

    -- Determine spawn count (1-3 mobs)
    local spawnCount = 1
    if math.random(100) <= extraMobChance then
        spawnCount = 2
        -- Small chance of spawning 3 at once in later episodes
        if episodeId >= 3 and math.random(100) <= 20 then
            spawnCount = 3
        end
    end

    -- Spawn the mobs
    for i = 1, spawnCount do
        if #self.mobs >= Constants.MAX_ACTIVE_MOBS then
            break
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
                        -- For tick-based projectiles (like orbital), check if damage can be applied
                        if proj.usesTickDamage then
                            local canDamage = proj:onHit(mob)
                            if canDamage then
                                mob:takeDamage(proj:getDamage())
                            end
                        else
                            -- Normal projectile: apply damage then call onHit
                            mob:takeDamage(proj:getDamage())
                            proj:onHit(mob)
                        end

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
            local mobRadius = mob:getRadius()
            local collisionDist = Constants.STATION_RADIUS + mobRadius

            if dist < collisionDist then
                -- Calculate attack angle (direction MOB approached from)
                local attackAngle = Utils.vectorToAngle(mob.x - self.station.x, mob.y - self.station.y)
                -- MOB hit station (ram damage - shield is less effective)
                self.station:takeDamage(mob.damage, attackAngle, "ram")
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
                -- Hit station! (projectile damage - shield is more effective)
                self.station:takeDamage(proj:getDamage(), attackAngle, "projectile")

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
        self:showMessage("BOSS: Cultural Attache!", 3.0)
        self.boss = CulturalAttache(x, y)
    elseif episodeId == 2 then
        self:showMessage("BOSS: Productivity Liaison!", 3.0)
        self.boss = ProductivityLiaison(x, y)
    elseif episodeId == 3 then
        self:showMessage("BOSS: Improbability Engine!", 3.0)
        self.boss = ImprobabilityEngine(x, y)
    elseif episodeId == 4 then
        self:showMessage("BOSS: Chomper!", 3.0)
        self.boss = Chomper(x, y)
    elseif episodeId == 5 then
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
-- options: { inverted = bool, rotationOffset = number }
function GameplayScene:createProjectile(x, y, angle, speed, damage, imagePath, piercing, options)
    return self.projectilePool:get(x, y, angle, speed, damage, imagePath, piercing, options)
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

    -- Draw mission intro overlay (on top of everything)
    if self.showingMissionIntro then
        self:drawMissionIntro()
    end

    -- Draw boss defeat celebration (on top of everything)
    if self.showingBossDefeated then
        self:drawBossDefeated()
    end

    -- Draw crank indicator if crank is docked (on top of everything)
    if self.showCrankIndicator and playdate.ui and playdate.ui.crankIndicator then
        if playdate.isCrankDocked() then
            playdate.ui.crankIndicator:update()
        else
            -- Crank was undocked, stop showing indicator
            self.showCrankIndicator = false
        end
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

    -- Draw equipment slots on sides
    self:drawEquipmentSlots()
end

-- Draw tool and item slots on the sides of the screen
function GameplayScene:drawEquipmentSlots()
    local slotSize = 15
    local maxSlots = 8
    local topY = 24  -- Below top bar
    local bottomY = Constants.SCREEN_HEIGHT - 22  -- Above bottom bar
    local availableHeight = bottomY - topY  -- 194px
    local slotSpacing = availableHeight / maxSlots  -- ~24px per slot position

    -- Left side: Tool slots (X = 0)
    local leftX = 0

    -- Right side: Item slots (X = screen width - slot size)
    local rightX = Constants.SCREEN_WIDTH - slotSize

    -- Get equipped tools
    local equippedTools = self.station and self.station.tools or {}

    -- Get owned bonus items (as a list)
    local ownedItems = {}
    if UpgradeSystem and UpgradeSystem.ownedBonusItems then
        for itemId, level in pairs(UpgradeSystem.ownedBonusItems) do
            if level > 0 then
                table.insert(ownedItems, itemId)
            end
        end
    end

    -- Get font for letters
    local font = gfx.getSystemFont(gfx.font.kVariantBold)

    -- Draw tool slots (left side)
    for i = 1, maxSlots do
        local slotY = topY + (i - 1) * slotSpacing + (slotSpacing - slotSize) / 2
        local tool = equippedTools[i]

        if tool then
            -- Filled slot: black background with first letter
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(leftX, slotY, slotSize, slotSize)

            -- Get first letter of tool name
            local toolName = tool.data and tool.data.name or "?"
            local letter = string.upper(string.sub(toolName, 1, 1))

            -- Draw letter centered in slot (white on black)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.setFont(font)
            local letterW = font:getTextWidth(letter)
            local letterH = font:getHeight()
            local letterX = leftX + (slotSize - letterW) / 2
            local letterY = slotY + (slotSize - letterH) / 2
            gfx.drawText(letter, letterX, letterY)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)

            -- Border
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(leftX, slotY, slotSize, slotSize)
        else
            -- Empty slot: white background with black border
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(leftX, slotY, slotSize, slotSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(leftX, slotY, slotSize, slotSize)
        end
    end

    -- Draw item slots (right side)
    for i = 1, maxSlots do
        local slotY = topY + (i - 1) * slotSpacing + (slotSpacing - slotSize) / 2
        local itemId = ownedItems[i]

        if itemId then
            -- Filled slot: black background with first letter
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(rightX, slotY, slotSize, slotSize)

            -- Get first letter of item name
            local itemData = BonusItemsData and BonusItemsData[itemId]
            local itemName = itemData and itemData.name or "?"
            local letter = string.upper(string.sub(itemName, 1, 1))

            -- Draw letter centered in slot (white on black)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.setFont(font)
            local letterW = font:getTextWidth(letter)
            local letterH = font:getHeight()
            local letterX = rightX + (slotSize - letterW) / 2
            local letterY = slotY + (slotSize - letterH) / 2
            gfx.drawText(letter, letterX, letterY)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)

            -- Border
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(rightX, slotY, slotSize, slotSize)
        else
            -- Empty slot: white background with black border
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(rightX, slotY, slotSize, slotSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(rightX, slotY, slotSize, slotSize)
        end
    end
end

function GameplayScene:onLevelUp()
    -- Always play level up sound
    AudioManager:playSFX("level_up")

    -- Get upgrade options from the upgrade system
    local toolOptions, bonusOptions = UpgradeSystem:getUpgradeOptions(self.station)

    -- If no options available, skip the level up UI (sound already played)
    if #toolOptions == 0 and #bonusOptions == 0 then
        print("Level up! No upgrades available - skipping UI (8/8 tools and items maxed)")
        return
    end

    print("Level up! Showing upgrade selection...")
    self.isLevelingUp = true

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
        -- Track tool for episode stats
        if selectionData.id then
            self:trackToolObtained(selectionData.id)
        end
    else
        UpgradeSystem:applyBonusSelection(selectionData, self.station)
        -- Track bonus item for episode stats
        if selectionData.id then
            self:trackItemObtained(selectionData.id)
        end
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
