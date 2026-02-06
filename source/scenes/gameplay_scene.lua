-- Gameplay Scene
-- Main game loop where combat happens

local gfx <const> = playdate.graphics

-- Localize math functions for performance (avoids table lookups in hot paths)
local math_floor <const> = math.floor
local math_ceil <const> = math.ceil
local math_max <const> = math.max
local math_min <const> = math.min
local math_abs <const> = math.abs
local math_random <const> = math.random
local math_sqrt <const> = math.sqrt
local math_atan <const> = math.atan

-- Pre-computed text outline offsets (performance: avoid table creation every frame)
local TEXT_OUTLINE_OFFSETS_1PX = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {1,0}, {-1,1}, {0,1}, {1,1} }
local TEXT_OUTLINE_OFFSETS_2PX = { {-2,-2}, {0,-2}, {2,-2}, {-2,0}, {2,0}, {-2,2}, {0,2}, {2,2} }

-- Cache for fallback letter images in equipment slots (performance: avoid image creation every frame)
local letterImageCache = {}

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

    -- DOD: Parallel arrays for mob hot data (faster collision detection)
    -- These are synced after mob updates for cache-efficient collision loops
    self.mobX = {}           -- mob positions
    self.mobY = {}
    self.mobActive = {}      -- is mob alive
    self.mobRadius = {}      -- collision radius
    self.mobEmits = {}       -- is shooter type (skip station collision)
    self.mobDamage = {}      -- damage on station collision
    self.mobCollisionBase = {} -- pre-cached (cachedRadius + 6) for collision
    self.mobCount = 0        -- number of mobs in arrays

    -- Frame counter for alternating collision checks (performance optimization)
    self.collisionFrame = 0

    -- Object pools
    self.projectilePool = nil
    self.enemyProjectilePool = nil
    self.collectiblePool = nil

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

    -- Station destroyed sequence state
    self.showingStationDestroyed = false
    self.stationDestroyedTimer = 0
    self.stationDestroyedAnim = nil
    self.stationDestroyedFrame = 1
    self.stationDestroyedFrameTimer = 0

    -- Cached equipment HUD strip (performance: only re-render when equipment changes)
    self.equipmentStripImage = nil
    self.equipmentStripDirty = true

    -- Pre-allocate health bar cache (avoids lazy alloc + nil checks during draw)
    self._healthBarCache = {}
    for i = 1, Constants.MAX_ACTIVE_MOBS do
        self._healthBarCache[i] = {}
    end

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

    -- Visual pulse effects (expanding rings for tools like Tractor Pulse)
    self.pulseEffects = {}

    -- Lightning arc effects (for Tesla Coil chain lightning)
    self.lightningArcs = {}

    -- Spatial partitioning grid for collision optimization
    -- Grid divides screen into cells to reduce collision checks
    self.gridCellSize = 50  -- 50x50 pixel cells
    self.gridCols = math.ceil(Constants.SCREEN_WIDTH / 50)   -- 8 columns
    self.gridRows = math.ceil(Constants.SCREEN_HEIGHT / 50)  -- 5 rows
    self.mobGrid = {}  -- Will be populated each frame: mobGrid[cellIndex] = {mob1, mob2, ...}
    self.dirtyCells = {}  -- Track which cells have mobs for lazy clearing (performance optimization)
    self.dirtyCellCount = 0
    self.nearbyMobsCache = {}  -- Reusable table for getMobsNearPosition (avoids allocation per call)
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
            for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_1PX) do
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
            Utils.debugPrint("Mission intro complete - starting gameplay")

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
        for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_2PX) do
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
    Utils.debugPrint("Boss defeated! Starting celebration for: " .. bossName)

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
    Utils.debugPrint("Boss celebration complete - proceeding to ending")
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
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_2PX) do
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

-- Start station destroyed sequence
function GameplayScene:startStationDestroyedSequence()
    Utils.debugPrint("Starting station destroyed sequence")

    -- Load the destroyed animation image table
    self.stationDestroyedAnim = gfx.imagetable.new("images/shared/station_destroyed_anim")
    if not self.stationDestroyedAnim then
        print("Warning: Could not load station destroyed animation")
        -- Fallback to immediate game over
        if self.station then self.station:remove() end
        GameManager:endEpisode(false)
        return
    end

    -- Store state
    self.showingStationDestroyed = true
    self.stationDestroyedTimer = 0
    self.stationDestroyedFrame = 1
    self.stationDestroyedFrameTimer = 0

    -- Pause gameplay
    self.isPaused = true

    -- Hide the station sprite (we'll draw the animation manually)
    if self.station then
        self.station:setVisible(false)
    end
end

-- Update station destroyed sequence
function GameplayScene:updateStationDestroyed(dt)
    self.stationDestroyedTimer = self.stationDestroyedTimer + dt

    -- Animate through frames (4 frames over ~1.5 seconds)
    local frameCount = self.stationDestroyedAnim:getLength()
    local frameDuration = 0.35  -- Time per frame

    self.stationDestroyedFrameTimer = self.stationDestroyedFrameTimer + dt
    if self.stationDestroyedFrameTimer >= frameDuration then
        self.stationDestroyedFrameTimer = 0
        if self.stationDestroyedFrame < frameCount then
            self.stationDestroyedFrame = self.stationDestroyedFrame + 1
        end
    end

    -- Check for button press to skip (after animation plays through once, ~1.4 seconds)
    if self.stationDestroyedTimer > 1.4 then
        if playdate.buttonJustPressed(playdate.kButtonA) or
           playdate.buttonJustPressed(playdate.kButtonB) then
            self:endStationDestroyedSequence()
            return
        end
    end

    -- Auto-advance after 5 seconds
    if self.stationDestroyedTimer >= 5.0 then
        self:endStationDestroyedSequence()
    end
end

-- End station destroyed sequence and go to game over
function GameplayScene:endStationDestroyedSequence()
    Utils.debugPrint("Station destroyed sequence complete - proceeding to game over")
    self.showingStationDestroyed = false
    self.isPaused = false

    -- Now remove the station
    if self.station then
        self.station:remove()
    end

    GameManager:endEpisode(false)
end

-- Draw station destroyed sequence
function GameplayScene:drawStationDestroyed()
    if not self.showingStationDestroyed then return end

    local centerX = Constants.SCREEN_WIDTH / 2
    local centerY = Constants.SCREEN_HEIGHT / 2

    -- Draw darkened background overlay
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Draw the animation frame at station position
    if self.stationDestroyedAnim then
        local frame = self.stationDestroyedAnim:getImage(self.stationDestroyedFrame)
        if frame then
            local imgW, imgH = frame:getSize()
            -- Draw at station center position
            frame:draw(Constants.STATION_CENTER_X - imgW / 2, Constants.STATION_CENTER_Y - imgH / 2)
        end
    end

    -- Draw "STATION DESTROYED" text
    local text = "*STATION DESTROYED*"
    local textY = centerY + 60

    -- Draw black stroke
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_2PX) do
        gfx.drawTextAligned(text, centerX + offset[1], textY + offset[2], kTextAlignment.center)
    end

    -- Draw white text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(text, centerX, textY, kTextAlignment.center)

    -- Draw "Press A to continue" hint after animation completes
    if self.stationDestroyedTimer > 1.4 then
        local hintText = "Press A to continue"
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

    -- Force full screen redraw every frame (all game entities drawn manually in drawOverlay;
    -- sprite system only handles background sprite)
    gfx.sprite.setAlwaysRedraw(true)

    -- Reset state
    self.isPaused = false
    self.isLevelingUp = false
    self.elapsedTime = 0
    self.currentWave = 1
    self.spawnTimer = 0
    self.mobs = {}
    self.collectibles = {}
    self.messages = {}
    self.pulseEffects = {}
    self.lightningArcs = {}
    self.boss = nil
    self.bossSpawned = false
    self.salvageDrone = nil

    -- Set wave timing based on debug mode and settings
    local isDebugMode = SaveManager and SaveManager:getSetting("debugMode", false)
    if isDebugMode then
        -- Debug mode: Use configurable wave length
        local waveLength = SaveManager:getDebugSetting("waveLength", 8)
        self.waveStartTimes = {}
        for i = 1, 7 do
            self.waveStartTimes[i] = (i - 1) * waveLength
        end
        -- Store episode length for boss spawn
        self.episodeLength = SaveManager:getDebugSetting("episodeLength", 60)
    else
        -- Normal mode: 20 seconds per wave, 2:30 episode (150s)
        local waveLength = 20
        self.waveStartTimes = {}
        for i = 1, 7 do
            self.waveStartTimes[i] = (i - 1) * waveLength
        end
        self.episodeLength = 150  -- 2 minutes 30 seconds for normal mode
    end

    -- Set initial spawn interval based on episode difficulty
    -- Episode 1: 1.8s, Episodes 2-3: faster, Episode 4: slower (TrashBlobs = fewer entities)
    local episodeSpawnIntervals = { 1.8, 0.9, 0.8, 1.0, 0.6 }
    local episodeId = GameManager.currentEpisodeId or 1
    self.spawnInterval = episodeSpawnIntervals[episodeId] or 1.5

    -- Reset boss defeat state
    self.showingBossDefeated = false
    self.bossDefeatedTimer = 0
    self.defeatedBossName = ""
    self.bossDefeatedImage = nil
    self.bossZoomScale = 1.0

    -- Reset station destroyed state
    self.showingStationDestroyed = false
    self.stationDestroyedTimer = 0
    self.stationDestroyedAnim = nil
    self.stationDestroyedFrame = 1
    self.stationDestroyedFrameTimer = 0

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

    -- Create object pools
    self.projectilePool = ProjectilePool(50)
    self.enemyProjectilePool = EnemyProjectilePool(30)
    self.collectiblePool = CollectiblePool(100)

    -- Point collectibles to pool's active list for backwards compatibility
    self.collectibles = self.collectiblePool:getActive()

    -- Create station
    self.station = Station()

    -- Give station a starting tool (use selected tool if available, otherwise Rail Driver)
    local startingToolId = GameManager.selectedStartingTool or "rail_driver"
    local startingTool = nil

    -- Get the tool class from UpgradeSystem
    if UpgradeSystem then
        local toolClass = UpgradeSystem:getToolClass(startingToolId)
        if toolClass then
            startingTool = toolClass()
        end
    end

    -- Fallback to Rail Driver if tool class not found
    if not startingTool then
        startingTool = RailDriver()
        startingToolId = "rail_driver"
    end

    self.station:attachTool(startingTool)

    -- Track starting tool in equipment order
    if UpgradeSystem then
        table.insert(UpgradeSystem.equipmentOrder, {type = "tool", id = startingToolId})
        UpgradeSystem.toolLevels[startingToolId] = 1
    end

    -- Clear the selected starting tool for next run
    GameManager.selectedStartingTool = nil

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

    -- Note: Projectile.incrementFrameCounter() is called in main.lua before scene update
    -- This prevents double-updates (projectiles are updated by both pool and sprite system)

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

    -- Update station destroyed sequence
    if self.showingStationDestroyed then
        self:updateStationDestroyed(dt)
        return
    end

    -- Update upgrade selection UI if visible (before early return)
    if self.isLevelingUp and UpgradeSelection.isVisible then
        UpgradeSelection:update()
        return
    end

    -- Update tool placement UI if visible (before early return)
    if self.isLevelingUp and ToolPlacementScreen.isVisible then
        ToolPlacementScreen:update()
        return
    end

    -- Update tool evolution screen if visible
    if self.isLevelingUp and ToolEvolutionScreen.isVisible then
        ToolEvolutionScreen:update()
        return
    end

    if self.isPaused or self.isLevelingUp then
        return
    end

    -- Update elapsed time and collision frame counter
    self.elapsedTime = self.elapsedTime + dt
    self.collisionFrame = self.collisionFrame + 1

    -- Update station
    self.station:update()

    -- Update tools (numeric for loop, 8x faster than ipairs)
    local tools = self.station.tools
    local toolCount = #tools
    for i = 1, toolCount do
        tools[i]:update(dt)
    end

    -- Update projectiles
    self.projectilePool:update()
    self.enemyProjectilePool:update()

    -- Update MOBs
    self:updateMOBs(dt)

    -- Update collectibles
    self:updateCollectibles(dt)

    -- Update visual pulse effects
    self:updatePulseEffects(dt)

    -- Update lightning arc effects
    self:updateLightningArcs(dt)

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
    -- Swap-and-pop removal for O(1) performance instead of O(n) table.remove
    local mobs = self.mobs
    local n = #mobs
    local i = 1
    while i <= n do
        local mob = mobs[i]
        if mob.active then
            mob:update(dt)
            i = i + 1
        else
            -- Swap with last element and remove
            mobs[i] = mobs[n]
            mobs[n] = nil
            n = n - 1
        end
    end

    -- Sync parallel arrays for fast collision detection
    self:syncMobArrays()
end

-- DOD: Sync mob data to parallel arrays for cache-efficient collision loops
-- This trades a small sync cost for much faster collision detection
function GameplayScene:syncMobArrays()
    local mobs = self.mobs
    local count = #mobs

    -- Local references for faster access
    local mobX = self.mobX
    local mobY = self.mobY
    local mobActive = self.mobActive
    local mobRadius = self.mobRadius
    local mobEmits = self.mobEmits
    local mobDamage = self.mobDamage

    -- Sync all mob data to arrays
    for i = 1, count do
        local mob = mobs[i]
        mobX[i] = mob.x
        mobY[i] = mob.y
        mobActive[i] = mob.active
        mobRadius[i] = mob.cachedRadius or 8
        mobEmits[i] = mob.emits
        mobDamage[i] = mob.damage
    end

    -- Clear any stale entries beyond current count
    for i = count + 1, self.mobCount do
        mobX[i] = nil
        mobY[i] = nil
        mobActive[i] = nil
        mobRadius[i] = nil
        mobEmits[i] = nil
        mobDamage[i] = nil
    end

    self.mobCount = count
end

function GameplayScene:updateCollectibles(dt)
    -- Use pool's update method (handles swap-and-pop and returns to pool)
    if self.collectiblePool then
        self.collectiblePool:update(dt)
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
    Utils.debugPrint("Wave " .. waveNum .. " started!")

    -- Play wave start sound
    AudioManager:playSFX("wave_start")

    -- Base spawn rates per wave (slightly faster than before for more action)
    -- Earlier waves: slower spawns, later waves: faster spawns
    local spawnRates = { 1.8, 1.5, 1.2, 1.0, 0.9, 0.8, 0.7 }
    local baseInterval = spawnRates[waveNum] or 0.5

    -- Episode difficulty multiplier (lower = faster spawns = harder)
    -- Episode 1: baseline, Episodes 2-3: faster, Episode 4: much slower (TrashBlobs = fewer, tougher entities)
    local episodeId = GameManager.currentEpisodeId or 1
    local episodeMultipliers = { 1.0, 0.5, 0.45, 0.80, 0.35 }  -- Ep4 slower for performance
    local episodeMult = episodeMultipliers[episodeId] or 0.35

    -- Player level scaling (higher level = more mobs)
    -- Every 3 levels, spawn rate decreases by 10%
    local playerLevel = GameManager.playerLevel or 1
    local levelMult = 1.0 - (math.floor((playerLevel - 1) / 3) * 0.1)
    levelMult = math.max(levelMult, 0.5)  -- Cap at 50% reduction (2x spawn rate)

    -- Calculate final spawn interval
    self.spawnInterval = baseInterval * episodeMult * levelMult
    Utils.debugPrint("Spawn interval: " .. string.format("%.2f", self.spawnInterval) ..
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
            return "Trash Blobs"
        elseif waveNum <= 4 then
            return "Trash Blobs, Defense Turrets"
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
    local extraMobChance = (episodeId - 1) * 10
    -- Add 5% per 3 player levels
    extraMobChance = extraMobChance + math.floor(playerLevel / 3) * 5
    extraMobChance = math.min(extraMobChance, 60)  -- Cap at 60%

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
            health = 1.0 + (self.currentWave - 1) * 0.2,
            damage = 1.0 + (self.currentWave - 1) * 0.12,
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
        Utils.debugPrint("Spawning MOB for Episode " .. episodeId)
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

-- Episode 4: Debris field - Trash Blobs and Defense Turrets
-- Uses TrashBlob (larger, consolidated) instead of many small DebrisChunks for performance
function GameplayScene:chooseEpisode4MOB(x, y, multipliers, roll)
    -- Episode 4: Increased multipliers to compensate for reduced mob count (MAX_ACTIVE_MOBS = 24)
    -- Mobs are tougher but fewer, maintaining similar difficulty
    multipliers.health = multipliers.health * 1.5  -- Was 1.2
    multipliers.damage = multipliers.damage * 1.2  -- Was 1.1
    multipliers.rp = (multipliers.rp or 1.0) * 1.25  -- +25% RP to maintain progression

    if self.currentWave <= 2 then
        -- Early waves: Mostly Trash Blobs with some small debris
        if roll <= 70 then
            return TrashBlob(x, y, multipliers)
        elseif roll <= 90 then
            return DebrisChunk(x, y, multipliers)  -- Some small debris for variety
        else
            return Asteroid(x, y, multipliers, 1)
        end
    elseif self.currentWave <= 4 then
        -- Mid waves: Mix of Trash Blobs and Defense Turrets
        if roll <= 45 then
            return TrashBlob(x, y, multipliers)
        elseif roll <= 80 then
            return DefenseTurret(x, y, multipliers)
        else
            return Asteroid(x, y, multipliers, math.random(1, 2))
        end
    else
        -- Late waves: Heavy Turret presence with Trash Blobs
        if roll <= 30 then
            return TrashBlob(x, y, multipliers)
        elseif roll <= 75 then
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

-- Build spatial grid for collision optimization
-- Assigns each active mob to the grid cell(s) it occupies
-- Uses lazy clearing: only clears cells that had mobs last frame (performance optimization)
function GameplayScene:buildMobGrid()
    local grid = self.mobGrid
    local dirtyCells = self.dirtyCells
    local oldDirtyCount = self.dirtyCellCount

    -- Clear only cells that had mobs last frame (lazy clearing)
    for i = 1, oldDirtyCount do
        local cellIndex = dirtyCells[i]
        if cellIndex then
            grid[cellIndex] = nil
        end
    end

    local cellSize = self.gridCellSize
    local cols = self.gridCols
    local rows = self.gridRows
    local newDirtyCount = 0

    -- Assign mobs to cells using DOD parallel arrays for position data
    -- Use numeric for loop (8x faster than ipairs per Playdate optimization guides)
    local mobs = self.mobs
    local mobX = self.mobX
    local mobY = self.mobY
    local mobActive = self.mobActive
    local mobCount = self.mobCount

    for i = 1, mobCount do
        if mobActive[i] then
            -- Get cell coordinates using cached position arrays (no table lookup)
            local cellX = math_floor(mobX[i] / cellSize)
            local cellY = math_floor(mobY[i] / cellSize)

            -- Clamp to grid bounds
            cellX = math_max(0, math_min(cols - 1, cellX))
            cellY = math_max(0, math_min(rows - 1, cellY))

            -- Calculate cell index (1-based)
            local cellIndex = cellY * cols + cellX + 1

            -- Add mob to cell and track dirty cell
            -- Still store mob object (needed for damage calls)
            if not grid[cellIndex] then
                grid[cellIndex] = {}
                newDirtyCount = newDirtyCount + 1
                dirtyCells[newDirtyCount] = cellIndex
            end
            grid[cellIndex][#grid[cellIndex] + 1] = mobs[i]
        end
    end

    -- Clear any stale entries in dirty cells list
    for i = newDirtyCount + 1, oldDirtyCount do
        dirtyCells[i] = nil
    end

    self.dirtyCellCount = newDirtyCount
end

-- Get mobs in cells near a position (for collision checking)
-- Reuses a cached table to avoid allocation per call
function GameplayScene:getMobsNearPosition(x, y)
    local cellSize = self.gridCellSize
    local cols = self.gridCols
    local rows = self.gridRows
    local grid = self.mobGrid

    -- Get center cell (use localized math functions)
    local cellX = math_floor(x / cellSize)
    local cellY = math_floor(y / cellSize)

    -- Reuse cached table (clear it first)
    local nearbyMobs = self.nearbyMobsCache
    local count = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            local nx = cellX + dx
            local ny = cellY + dy

            -- Check bounds
            if nx >= 0 and nx < cols and ny >= 0 and ny < rows then
                local cellIndex = ny * cols + nx + 1
                local cellMobs = grid[cellIndex]
                if cellMobs then
                    -- Numeric for loop (8x faster than ipairs)
                    local cellCount = #cellMobs
                    for j = 1, cellCount do
                        count = count + 1
                        nearbyMobs[count] = cellMobs[j]
                    end
                end
            end
        end
    end

    -- Clear any stale entries beyond current count
    for i = count + 1, #nearbyMobs do
        nearbyMobs[i] = nil
    end

    return nearbyMobs
end

-- Inline constant for vectorToAngle (avoids Utils table lookup + function call)
local RAD_TO_DEG <const> = 180 / math.pi

function GameplayScene:checkCollisions()
    -- Build spatial grid for this frame
    self:buildMobGrid()

    local collisionFrame = self.collisionFrame
    local isEvenFrame = (collisionFrame % 2 == 0)

    -- Projectiles vs MOBs (using spatial partitioning)
    -- Performance: split into two halves, alternating frames
    -- Safe because projectiles move 7-10px/frame vs 16-32px mob widths (no tunneling)
    local projectiles = self.projectilePool:getActive()

    -- Minimum distance projectile must travel from spawn before collision is enabled
    local minTravelDistSq = 100  -- 10 * 10 pixels from spawn point

    local projCount = #projectiles
    local halfCount = math_ceil(projCount / 2)
    local startIdx, endIdx
    if isEvenFrame then
        startIdx, endIdx = 1, halfCount
    else
        startIdx, endIdx = halfCount + 1, projCount
    end

    -- Pre-cache mob collision base values for inner loop
    local mobCollisionBase = self.mobCollisionBase

    for pi = startIdx, endIdx do
        local proj = projectiles[pi]
        if proj and proj.active then
            -- Early bounds check: skip projectiles near screen edge
            local px, py = proj.x, proj.y
            if px > -20 and px < 420 and py > -20 and py < 260 then
                -- Check if projectile has traveled far enough from its spawn point
                local tdx = px - (proj.spawnX or px)
                local tdy = py - (proj.spawnY or py)
                local travelDistSq = tdx * tdx + tdy * tdy

                if travelDistSq >= minTravelDistSq then
                    -- Get only mobs near this projectile (spatial partitioning)
                    local nearbyMobs = self:getMobsNearPosition(px, py)
                    local projSpeed = proj.speed or 8
                    local projSpeedBonus = projSpeed * 0.25

                    local nearbyCount = #nearbyMobs
                    for mi = 1, nearbyCount do
                        local mob = nearbyMobs[mi]
                        if mob.active then
                            local dx = px - mob.x
                            local dy = py - mob.y
                            local distSq = dx * dx + dy * dy

                            -- Use pre-cached collision base + speed bonus
                            local collisionDist = (mob.cachedRadius or 8) + 6 + projSpeedBonus
                            local collisionDistSq = collisionDist * collisionDist

                            if distSq < collisionDistSq then
                                if proj.usesTickDamage then
                                    local canDamage = proj:onHit(mob)
                                    if canDamage then
                                        mob:takeDamage(proj:getDamage(), nil, px, py)
                                    end
                                else
                                    mob:takeDamage(proj:getDamage(), nil, px, py)
                                    proj:onHit(mob)
                                end

                                if not proj.active then
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- MOBs vs Station (using DOD parallel arrays for cache efficiency)
    -- Runs EVERY frame - important for gameplay feel (ramming mobs should feel immediate)
    local stationX, stationY = self.station.x, self.station.y
    local stationRadius = Constants.STATION_RADIUS

    local mobX = self.mobX
    local mobY = self.mobY
    local mobActive = self.mobActive
    local mobRadius = self.mobRadius
    local mobEmits = self.mobEmits
    local mobDamage = self.mobDamage
    local mobCount = self.mobCount
    local mobs = self.mobs

    for i = 1, mobCount do
        if mobActive[i] and not mobEmits[i] then
            local dx = mobX[i] - stationX
            local dy = mobY[i] - stationY
            local distSq = dx * dx + dy * dy
            local collisionDist = stationRadius + mobRadius[i]

            if distSq < collisionDist * collisionDist then
                local mob = mobs[i]
                if mob then
                    -- Inline vectorToAngle (avoids Utils table lookup + function call)
                    local attackAngle = math_atan(dx, -dy) * RAD_TO_DEG
                    self.station:takeDamage(mobDamage[i], attackAngle, "ram")
                    mob:onDestroyed()
                end
            end
        end
    end

    -- Enemy Projectiles vs Station
    -- Performance: only check on odd frames (enemy projectiles move slowly at speed 3,
    -- station is 64px wide - no tunneling risk, 1-frame delay is imperceptible)
    if not isEvenFrame then
        local enemyProjectiles = self.enemyProjectilePool:getActive()
        local stationCollisionDistSq = (stationRadius + 4) * (stationRadius + 4)
        local enemyProjCount = #enemyProjectiles
        for i = 1, enemyProjCount do
            local proj = enemyProjectiles[i]
            if proj and proj.active then
                local dx = proj.x - stationX
                local dy = proj.y - stationY
                local distSq = dx * dx + dy * dy
                if distSq < stationCollisionDistSq then
                    -- Inline vectorToAngle for attack angle
                    local attackAngle = math_atan(dx, -dy) * RAD_TO_DEG
                    self.station:takeDamage(proj:getDamage(), attackAngle, "projectile")

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
end

function GameplayScene:checkGameConditions()
    -- Check for game over (station destroyed sequence is triggered by Station:onDestroyed)
    -- This is a safety fallback in case the sequence wasn't triggered
    if self.station.health <= 0 and not self.showingStationDestroyed then
        -- Station should have triggered the sequence, but if not, trigger it now
        self:startStationDestroyedSequence()
        return
    end

    -- Check for boss spawn (use episode length set during enter)
    local bossSpawnTime = self.episodeLength or 180

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

-- Create a visual pulse effect (expanding ring)
function GameplayScene:createPulseEffect(x, y, maxRadius, duration, effectType)
    table.insert(self.pulseEffects, {
        x = x,
        y = y,
        maxRadius = maxRadius,
        duration = duration,
        elapsed = 0,
        effectType = effectType or "default"
    })
end

-- Update pulse effects
function GameplayScene:updatePulseEffects(dt)
    for i = #self.pulseEffects, 1, -1 do
        local effect = self.pulseEffects[i]
        effect.elapsed = effect.elapsed + dt

        if effect.elapsed >= effect.duration then
            table.remove(self.pulseEffects, i)
        end
    end
end

-- Draw pulse effects
function GameplayScene:drawPulseEffects()
    for _, effect in ipairs(self.pulseEffects) do
        local progress = effect.elapsed / effect.duration
        local currentRadius = effect.maxRadius * progress

        -- Fade out as the ring expands
        local alpha = 1 - progress

        -- Set line width based on effect type
        local lineWidth = 2
        if effect.effectType == "tractor" then
            lineWidth = 3
        end

        gfx.setLineWidth(lineWidth)

        -- Draw expanding ring (single draw call for performance)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(effect.x, effect.y, currentRadius)

        gfx.setLineWidth(1)
    end
end

-- Create a lightning arc visual effect (for chain lightning)
function GameplayScene:createLightningArc(x1, y1, x2, y2)
    table.insert(self.lightningArcs, {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        duration = 0.15,  -- Short flash
        elapsed = 0,
        segments = self:generateLightningSegments(x1, y1, x2, y2)
    })
end

-- Generate zigzag lightning segments between two points
function GameplayScene:generateLightningSegments(x1, y1, x2, y2)
    local segments = {}
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Number of segments based on distance
    local numSegments = math.max(3, math.floor(dist / 15))

    -- Perpendicular vector for offsets
    local perpX = -dy / dist
    local perpY = dx / dist

    local prevX, prevY = x1, y1
    for i = 1, numSegments do
        local t = i / numSegments
        local baseX = x1 + dx * t
        local baseY = y1 + dy * t

        -- Add random perpendicular offset (except for endpoints)
        local offset = 0
        if i < numSegments then
            offset = (math.random() - 0.5) * 16  -- Random offset up to 8 pixels
        end

        local pointX = baseX + perpX * offset
        local pointY = baseY + perpY * offset

        table.insert(segments, {
            x1 = prevX, y1 = prevY,
            x2 = pointX, y2 = pointY
        })

        prevX, prevY = pointX, pointY
    end

    return segments
end

-- Update lightning arcs
function GameplayScene:updateLightningArcs(dt)
    for i = #self.lightningArcs, 1, -1 do
        local arc = self.lightningArcs[i]
        arc.elapsed = arc.elapsed + dt

        if arc.elapsed >= arc.duration then
            table.remove(self.lightningArcs, i)
        end
    end
end

-- Draw lightning arcs
function GameplayScene:drawLightningArcs()
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(2)

    for _, arc in ipairs(self.lightningArcs) do
        -- Draw each segment of the lightning (line width 2 already handles thickness)
        for _, seg in ipairs(arc.segments) do
            gfx.drawLine(seg.x1, seg.y1, seg.x2, seg.y2)
        end
    end

    gfx.setLineWidth(1)
end

-- Draw background (called before sprite.update)
function GameplayScene:drawBackground()
    -- Background is now a sprite, so nothing to do here
    -- The sprite system will draw it automatically
end

-- Draw overlay (called after sprite.update)
-- All game entities are drawn manually for performance (sprite.update only handles background)
-- Draw order: collectibles → mobs → station → tools → projectiles → effects → HUD
function GameplayScene:drawOverlay()
    -- Draw collectibles (lowest layer - RP orbs on the ground)
    local collectibles = self.collectiblePool.active
    local cCount = #collectibles
    for i = 1, cCount do
        local c = collectibles[i]
        if c.active and c.drawVisible and c.drawImage then
            c.drawImage:draw(c.drawX - 4, c.drawY - 4)
        end
    end

    -- Draw MOBs (Z:50 equivalent)
    local mobs = self.mobs
    local mobCount = #mobs
    for i = 1, mobCount do
        local mob = mobs[i]
        if mob.active and mob.drawImage then
            mob.drawImage:drawRotated(mob.x, mob.y, mob.drawRotation or 0)
        end
    end

    -- Draw Station (Z:100 equivalent)
    local station = self.station
    if station and station.drawImage then
        station.drawImage:drawRotated(station.x, station.y, station.drawRotation or 0)
    end

    -- Draw Tools (Z:150 equivalent)
    if station then
        local tools = station.tools
        local toolCount = #tools
        for i = 1, toolCount do
            local tool = tools[i]
            if tool.drawImage then
                tool.drawImage:drawRotated(tool.x, tool.y, tool.drawRotation or 0)
            end
        end
    end

    -- Draw enemy projectiles
    local enemyProj = self.enemyProjectilePool.active
    local epCount = #enemyProj
    for i = 1, epCount do
        local ep = enemyProj[i]
        if ep.active and ep.drawImage then
            ep.drawImage:drawRotated(ep.x, ep.y, ep.drawRotation)
        end
    end

    -- Draw player projectiles
    local playerProj = self.projectilePool.active
    local ppCount = #playerProj
    for i = 1, ppCount do
        local pp = playerProj[i]
        if pp.active and pp.drawImage then
            pp.drawImage:drawRotated(pp.x, pp.y, pp.drawRotation)
        end
    end

    -- Batch MOB health bar drawing (reduces gfx.setColor toggling)
    -- Collect all visible health bars, then draw backgrounds, then fills
    local mobs = self.mobs
    local mobCount = #mobs
    local barCount = 0

    -- Reuse pre-allocated table for health bar data
    local healthBars = self._healthBarCache

    for i = 1, mobCount do
        local mob = mobs[i]
        if mob.showHealthBar and mob.active then
            barCount = barCount + 1
            local barX = mob.x - 10  -- barWidth / 2
            local barY = mob.y - mob.cachedRadius - 6
            local fillWidth = (mob.health / mob.maxHealth) * 18  -- barWidth - 2
            -- Store as flat values (table pre-allocated in init)
            local b = healthBars[barCount]
            b[1] = barX
            b[2] = barY
            b[3] = fillWidth
        end
        -- DEBUG: Draw MOB type labels to diagnose sprite issues
        if mob.drawDebugLabel then
            mob:drawDebugLabel()
        end
    end

    if barCount > 0 then
        -- All black backgrounds at once
        gfx.setColor(gfx.kColorBlack)
        for i = 1, barCount do
            local b = healthBars[i]
            gfx.fillRect(b[1], b[2], 20, 3)
        end
        -- All white fills at once
        gfx.setColor(gfx.kColorWhite)
        for i = 1, barCount do
            local b = healthBars[i]
            gfx.fillRect(b[1] + 1, b[2] + 1, b[3], 1)
        end
    end

    -- Draw pulse effects (expanding rings for tools like Tractor Pulse)
    self:drawPulseEffects()

    -- Draw lightning arc effects (for Tesla Coil chain lightning)
    self:drawLightningArcs()

    -- Draw shield effect (before HUD so it's behind UI elements)
    self.station:drawShield()

    -- Draw HUD
    self:drawHUD()

    -- Draw frame rate if enabled in creative mode
    if SaveManager and SaveManager:isDebugFeatureEnabled("showFrameRate") then
        FontManager:setBodyFont()
        local fps = playdate.getFPS()
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.drawText(tostring(fps), 3, 3)
        gfx.drawText(tostring(fps), 5, 3)
        gfx.drawText(tostring(fps), 3, 5)
        gfx.drawText(tostring(fps), 5, 5)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(tostring(fps), 4, 4)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw on-screen messages
    self:drawMessages()

    -- Draw upgrade selection UI if visible (drawn on top of everything)
    if self.isLevelingUp and UpgradeSelection.isVisible then
        UpgradeSelection:draw()
    end

    -- Draw tool placement UI if visible (drawn on top of upgrade selection)
    if self.isLevelingUp and ToolPlacementScreen.isVisible then
        ToolPlacementScreen:draw()
    end

    -- Draw tool evolution screen if visible (on top of everything)
    if self.isLevelingUp and ToolEvolutionScreen.isVisible then
        ToolEvolutionScreen:draw()
    end

    -- Draw mission intro overlay (on top of everything)
    if self.showingMissionIntro then
        self:drawMissionIntro()
    end

    -- Draw boss defeat celebration (on top of everything)
    if self.showingBossDefeated then
        self:drawBossDefeated()
    end

    -- Draw station destroyed sequence (on top of everything)
    if self.showingStationDestroyed then
        self:drawStationDestroyed()
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
    -- RP Bar (top of screen) - thin line on black
    local rpPercent = GameManager.currentRP / GameManager.rpToNextLevel
    rpPercent = Utils.clamp(rpPercent, 0, 1)

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 6)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(0, 0, Constants.SCREEN_WIDTH, 6)
    gfx.fillRect(1, 1, (Constants.SCREEN_WIDTH - 2) * rpPercent, 4)

    -- Top info bar: black fill, white text, white rule below
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 6, Constants.SCREEN_WIDTH, 18)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 24, Constants.SCREEN_WIDTH, 1)  -- fillRect faster than drawLine for horizontal

    -- Timer (top left) - bold
    FontManager:setMenuFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local timeStr = Utils.formatTime(self.elapsedTime)
    gfx.drawText(timeStr, 8, 8)

    -- Wave (top center)
    gfx.drawTextAligned("Wave " .. self.currentWave, Constants.SCREEN_WIDTH / 2, 8, kTextAlignment.center)

    -- Level (top right)
    gfx.drawTextAligned("Lv." .. GameManager.playerLevel, Constants.SCREEN_WIDTH - 8, 8, kTextAlignment.right)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Bottom HUD bar: black fill, white rule above
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 1)  -- fillRect faster than drawLine

    -- Health Bar (bottom right)
    local healthBarWidth = 100
    local healthBarHeight = 12
    local healthBarX = Constants.SCREEN_WIDTH - healthBarWidth - 8
    local healthBarY = Constants.SCREEN_HEIGHT - 18

    -- Health percentage
    local healthPercent = self.station.health / self.station.maxHealth
    healthPercent = Utils.clamp(healthPercent, 0, 1)

    -- Draw health bar border (white on black)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(healthBarX - 1, healthBarY - 1, healthBarWidth + 2, healthBarHeight + 2)

    -- Draw health bar background (empty = black)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(healthBarX, healthBarY, healthBarWidth, healthBarHeight)

    -- Draw health bar fill (white = health remaining)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight)

    -- Draw health text next to bar
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local healthStr = math.floor(self.station.health) .. "/" .. self.station.maxHealth
    gfx.drawTextAligned(healthStr, healthBarX - 6, healthBarY, kTextAlignment.right)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw boss health bar AFTER the HUD (so it's not covered by the white background)
    if self.boss and self.boss.active then
        self.boss:drawHealthBar()
    end

    -- Draw equipment slots on sides
    self:drawEquipmentSlots()
end

-- Invalidate cached equipment strip (call when equipment changes)
function GameplayScene:invalidateEquipmentStrip()
    self.equipmentStripDirty = true
end

-- Draw equipment slots (tools and items combined) in a vertical column on the left
-- Performance: renders to cached image, only re-renders when equipment changes
function GameplayScene:drawEquipmentSlots()
    local maxSlots = 8
    local slotSize = 24
    local topY = 24  -- Below top bar
    local leftX = 0
    local stripHeight = maxSlots * slotSize

    -- Only re-render the strip image when equipment has changed
    if self.equipmentStripDirty or not self.equipmentStripImage then
        -- Create or reuse the strip image
        if not self.equipmentStripImage then
            self.equipmentStripImage = gfx.image.new(slotSize, stripHeight)
        end

        gfx.pushContext(self.equipmentStripImage)
        gfx.clear(gfx.kColorBlack)

        -- Use equipment order from UpgradeSystem (maintains acquisition order)
        local equipmentOrder = UpgradeSystem and UpgradeSystem.equipmentOrder or {}

        for i = 1, maxSlots do
            local slotY = (i - 1) * slotSize
            local equipEntry = equipmentOrder[i]
            local equip = nil

            if equipEntry then
                if equipEntry.type == "tool" then
                    local tools = self.station and self.station.tools or {}
                    for _, tool in ipairs(tools) do
                        if tool.data and tool.data.id == equipEntry.id then
                            equip = { iconPath = tool.data.iconPath or tool.data.imagePath, name = tool.data.name or "?" }
                            break
                        end
                    end
                    if not equip then
                        local toolData = ToolsData and ToolsData[equipEntry.id]
                        if toolData then
                            equip = { iconPath = toolData.iconPath or toolData.imagePath, name = toolData.name or "?" }
                        end
                    end
                elseif equipEntry.type == "item" then
                    local itemData = BonusItemsData and BonusItemsData[equipEntry.id]
                    if itemData then
                        equip = { iconPath = itemData.iconPath, name = itemData.name or "?" }
                    end
                end
            end

            if equip then
                -- Filled slot: black background with icon
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(0, slotY, slotSize, slotSize)

                -- Draw icon
                local icon = nil
                if equip.iconPath then
                    local filename = equip.iconPath:match("([^/]+)$")
                    local onBlackPath = "images/icons_on_black/" .. filename
                    icon = Utils.getCachedImage(onBlackPath)
                end

                if icon then
                    local iconW, iconH = icon:getSize()
                    local padding = 4
                    local targetSize = slotSize - padding
                    local scale = math.min(targetSize / iconW, targetSize / iconH)
                    local scaledW = iconW * scale
                    local scaledH = iconH * scale
                    local drawX = (slotSize - scaledW) / 2
                    local drawY = slotY + (slotSize - scaledH) / 2
                    icon:drawScaled(drawX, drawY, scale)
                else
                    -- Fallback letter
                    local letter = string.upper(string.sub(equip.name, 1, 1))
                    local letterImg = letterImageCache[letter]
                    if not letterImg then
                        local boldFont = FontManager.boldFont
                        local fullW = boldFont:getTextWidth(letter)
                        local fullH = boldFont:getHeight()
                        letterImg = gfx.image.new(fullW, fullH)
                        gfx.pushContext(letterImg)
                        gfx.setFont(boldFont)
                        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                        gfx.drawText(letter, 0, 0)
                        gfx.popContext()
                        letterImageCache[letter] = letterImg
                    end
                    local fullW, fullH = letterImg:getSize()
                    local padding = 4
                    local targetSize = slotSize - padding
                    local scale = math.min(targetSize / fullW, targetSize / fullH)
                    local scaledW = fullW * scale
                    local scaledH = fullH * scale
                    local drawX = (slotSize - scaledW) / 2
                    local drawY = slotY + (slotSize - scaledH) / 2
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                    letterImg:drawScaled(drawX, drawY, scale)
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                -- Border
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(0, slotY, slotSize, slotSize)
            else
                -- Empty slot: black with white border
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(0, slotY, slotSize, slotSize)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(0, slotY, slotSize, slotSize)
            end
        end

        gfx.popContext()
        self.equipmentStripDirty = false
    end

    -- Draw the cached strip image (single blit instead of 8 draws per frame)
    self.equipmentStripImage:draw(leftX, topY)
end

function GameplayScene:onLevelUp()
    -- Always play level up sound
    AudioManager:playSFX("level_up")

    -- Level up HP bonus: restore 5% HP if damaged, or increase max HP by 5% if full
    if self.station then
        local hpBonus = math.floor(self.station.maxHealth * 0.05)
        if self.station.health < self.station.maxHealth then
            -- Restore HP (up to max)
            self.station.health = math.min(self.station.health + hpBonus, self.station.maxHealth)
            Utils.debugPrint("Level up: Restored " .. hpBonus .. " HP")
        else
            -- Increase max HP (and current HP)
            self.station.maxHealth = self.station.maxHealth + hpBonus
            self.station.health = self.station.health + hpBonus
            Utils.debugPrint("Level up: Increased max HP by " .. hpBonus)
        end
    end

    -- Get upgrade options from the upgrade system
    local toolOptions, bonusOptions = UpgradeSystem:getUpgradeOptions(self.station)

    -- If no options available, skip the level up UI (sound already played)
    if #toolOptions == 0 and #bonusOptions == 0 then
        Utils.debugPrint("Level up! No upgrades available - skipping UI (8/8 tools and items maxed)")
        return
    end

    Utils.debugPrint("Level up! Showing upgrade selection...")
    self.isLevelingUp = true

    -- Show the upgrade selection UI
    UpgradeSelection:show(toolOptions, bonusOptions, function(selectionType, selectionData)
        -- Callback when player makes a selection
        self:onUpgradeSelected(selectionType, selectionData)
    end)
end

-- Called when player selects an upgrade
function GameplayScene:onUpgradeSelected(selectionType, selectionData)
    Utils.debugPrint("Selected " .. selectionType .. ": " .. (selectionData.name or "unknown"))

    -- Invalidate cached equipment HUD strip (new tool/item acquired)
    self:invalidateEquipmentStrip()

    if selectionType == "tool" then
        -- Check if tool placement is enabled and this is a NEW tool
        local toolPlacementEnabled = SaveManager and SaveManager:getDebugSetting("toolPlacementEnabled", true)

        -- Debug logging
        Utils.debugPrint("Tool Placement Check: toolPlacementEnabled=" .. tostring(toolPlacementEnabled) ..
              ", isNew=" .. tostring(selectionData.isNew))

        if toolPlacementEnabled and selectionData.isNew then
            -- Show tool placement interface
            ToolPlacementScreen:show(selectionData, self.station, function(slotIndex)
                -- Callback when slot is selected
                local success, evolutionInfo = UpgradeSystem:applyToolSelection(selectionData, self.station, slotIndex)
                -- Track tool for episode stats
                if selectionData.id then
                    self:trackToolObtained(selectionData.id)
                end
                -- Check for evolution
                if evolutionInfo and evolutionInfo.evolved then
                    self:showToolEvolution(evolutionInfo)
                else
                    -- Resume gameplay
                    self.isLevelingUp = false
                end
            end)
        else
            -- Normal flow: auto-place tool
            local success, evolutionInfo = UpgradeSystem:applyToolSelection(selectionData, self.station)
            -- Track tool for episode stats
            if selectionData.id then
                self:trackToolObtained(selectionData.id)
            end
            -- Check for evolution
            if evolutionInfo and evolutionInfo.evolved then
                self:showToolEvolution(evolutionInfo)
            else
                -- Resume gameplay
                self.isLevelingUp = false
            end
        end
    else
        local success, evolutionInfo = UpgradeSystem:applyBonusSelection(selectionData, self.station)
        -- Track bonus item for episode stats
        if selectionData.id then
            self:trackItemObtained(selectionData.id)
        end
        -- Check for evolution
        if evolutionInfo and evolutionInfo.evolved then
            self:showToolEvolution(evolutionInfo)
        else
            -- Resume gameplay
            self.isLevelingUp = false
        end
    end
end

-- Show tool evolution screen
function GameplayScene:showToolEvolution(evolutionInfo)
    -- Invalidate equipment HUD (evolved tool has new icon)
    self:invalidateEquipmentStrip()

    ToolEvolutionScreen:show(evolutionInfo.originalData, evolutionInfo.evolvedData, function()
        -- Resume gameplay after evolution screen
        self.isLevelingUp = false
    end)
end

function GameplayScene:exit()
    Utils.debugPrint("Exiting gameplay scene")

    -- Clean up pools
    self.projectilePool:releaseAll()
    self.enemyProjectilePool:releaseAll()
    if self.collectiblePool then
        self.collectiblePool:releaseAll()
    end
    gfx.sprite.removeAll()

    -- Restore dirty-rect optimization for menu screens
    gfx.sprite.setAlwaysRedraw(false)
end

return GameplayScene
