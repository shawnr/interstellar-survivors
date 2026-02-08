-- Save Manager
-- Handles all save/load operations using playdate.datastore

SaveManager = {
    -- Persistent game data (survives across sessions)
    gameData = {
        completedEpisodes = {},     -- Array of completed episode IDs
        unlockedResearchSpecs = {}, -- Array of unlocked spec IDs
        totalPlayTime = 0,          -- Total seconds played
        totalDeaths = 0,            -- Times station destroyed
        totalVictories = 0,         -- Episodes completed
        settings = {
            musicVolume = 0.7,
            sfxVolume = 1.0,
            debugMode = false,
            introSeen = false,
        },
        -- Debug mode sub-settings (used when debugMode is true)
        debugSettings = {
            episodeLength = 60,         -- Episode length in seconds (default: 1 min for debug)
            waveLength = 8,             -- Wave length in seconds (default: ~8s for debug)
            stationInvincible = true,   -- Station takes no damage
            unlockAllEquipment = true,  -- All tools and items available in upgrades
            unlockAllEpisodes = true,   -- All episodes selectable
            unlockAllDatabase = true,   -- All database entries visible
            unlockAllResearchSpecs = true,  -- All research specs available
            difficultyMultiplier = 1.0, -- Multiplier for MOB/BOSS health and damage
            toolPlacementEnabled = true, -- Manual tool placement on level-up
        },
        -- Database unlocks (discovered items)
        databaseUnlocks = {
            tools = {},         -- Tool IDs discovered
            bonusItems = {},    -- Bonus item IDs discovered
            enemies = {},       -- Enemy IDs defeated
            bosses = {},        -- Boss IDs encountered
        },
        -- Grant Funding (meta-progression currency)
        grantFunds = 0,
        grantFundingLevels = {
            health = 0,     -- 0-4, increases station base health
            damage = 0,     -- 0-4, increases all damage dealt
            shields = 0,    -- 0-4, increases shield capacity and reduces cooldown
            research = 0,   -- 0-4, increases RP earned
            expanded_memory = 0, -- 0-4, increases max equipped research specs
        },
        -- Equipped research specs (nil = auto-equip mode)
        equippedResearchSpecs = nil,
    },

    -- Current episode state (deleted on episode end)
    episodeState = nil,

    -- File names
    GAME_DATA_FILE = "game_data",
    EPISODE_STATE_FILE = "episode_state",

    -- Dirty flag for save optimization
    gameDataDirty = false,
}

function SaveManager:init()
    -- Load game data on init
    self:loadGameData()
    Utils.debugPrint("SaveManager initialized")
end

-- ============================================
-- Game Data (Persistent)
-- ============================================

function SaveManager:loadGameData()
    local data = playdate.datastore.read(self.GAME_DATA_FILE)

    if data then
        -- Merge loaded data with defaults (in case new fields were added)
        self.gameData.completedEpisodes = data.completedEpisodes or {}
        self.gameData.unlockedResearchSpecs = data.unlockedResearchSpecs or {}
        self.gameData.totalPlayTime = data.totalPlayTime or 0
        self.gameData.totalDeaths = data.totalDeaths or 0
        self.gameData.totalVictories = data.totalVictories or 0

        if data.settings then
            self.gameData.settings.musicVolume = data.settings.musicVolume or 0.7
            self.gameData.settings.sfxVolume = data.settings.sfxVolume or 1.0
            self.gameData.settings.debugMode = data.settings.debugMode or false
            self.gameData.settings.introSeen = data.settings.introSeen or false
        end

        -- Load debug settings
        if data.debugSettings then
            self.gameData.debugSettings.episodeLength = data.debugSettings.episodeLength or 60
            self.gameData.debugSettings.waveLength = data.debugSettings.waveLength or 8
            self.gameData.debugSettings.stationInvincible = data.debugSettings.stationInvincible ~= false
            self.gameData.debugSettings.unlockAllEquipment = data.debugSettings.unlockAllEquipment ~= false
            self.gameData.debugSettings.unlockAllEpisodes = data.debugSettings.unlockAllEpisodes ~= false
            self.gameData.debugSettings.unlockAllDatabase = data.debugSettings.unlockAllDatabase ~= false
            self.gameData.debugSettings.unlockAllResearchSpecs = data.debugSettings.unlockAllResearchSpecs ~= false
            self.gameData.debugSettings.difficultyMultiplier = data.debugSettings.difficultyMultiplier or 1.0
            self.gameData.debugSettings.toolPlacementEnabled = data.debugSettings.toolPlacementEnabled ~= false
        end

        -- Load database unlocks
        if data.databaseUnlocks then
            self.gameData.databaseUnlocks.tools = data.databaseUnlocks.tools or {}
            self.gameData.databaseUnlocks.bonusItems = data.databaseUnlocks.bonusItems or {}
            self.gameData.databaseUnlocks.enemies = data.databaseUnlocks.enemies or {}
            self.gameData.databaseUnlocks.bosses = data.databaseUnlocks.bosses or {}
        end

        -- Load grant funding data
        self.gameData.grantFunds = data.grantFunds or 0
        if data.grantFundingLevels then
            self.gameData.grantFundingLevels.health = data.grantFundingLevels.health or 0
            self.gameData.grantFundingLevels.damage = data.grantFundingLevels.damage or 0
            self.gameData.grantFundingLevels.shields = data.grantFundingLevels.shields or 0
            self.gameData.grantFundingLevels.research = data.grantFundingLevels.research or 0
            self.gameData.grantFundingLevels.expanded_memory = data.grantFundingLevels.expanded_memory or 0
        end

        -- Load equipped research specs
        self.gameData.equippedResearchSpecs = data.equippedResearchSpecs  -- nil = auto-equip

        Utils.debugPrint("Game data loaded successfully")
    else
        Utils.debugPrint("No saved game data found, using defaults")
    end
end

function SaveManager:saveGameData()
    playdate.datastore.write(self.gameData, self.GAME_DATA_FILE)
    self.gameDataDirty = false
    Utils.debugPrint("Game data saved")
end

function SaveManager:markGameDataDirty()
    self.gameDataDirty = true
end

-- Check if an episode is completed
function SaveManager:isEpisodeCompleted(episodeId)
    for _, id in ipairs(self.gameData.completedEpisodes) do
        if id == episodeId then
            return true
        end
    end
    return false
end

-- Mark an episode as completed
function SaveManager:markEpisodeCompleted(episodeId)
    if not self:isEpisodeCompleted(episodeId) then
        table.insert(self.gameData.completedEpisodes, episodeId)
        self.gameData.totalVictories = self.gameData.totalVictories + 1
        self:markGameDataDirty()

        -- Unlock research spec for this episode
        local episodeData = EpisodesData.get(episodeId)
        if episodeData and episodeData.researchSpecUnlock then
            self:unlockResearchSpec(episodeData.researchSpecUnlock)
        end

        -- Check meta-progression unlocks (victories count, all episodes, etc.)
        self:checkMetaProgressionUnlocks()
    end
end

-- Check if an episode is unlocked
function SaveManager:isEpisodeUnlocked(episodeId)
    local episodeData = EpisodesData.get(episodeId)
    if not episodeData then return false end

    -- Episode 1 is always unlocked
    if episodeData.unlockCondition == "start" then
        return true
    end

    -- Check if prerequisite episode is completed
    local prereqMatch = episodeData.unlockCondition:match("episode_(%d+)")
    if prereqMatch then
        local prereqId = tonumber(prereqMatch)
        return self:isEpisodeCompleted(prereqId)
    end

    return false
end

-- Get all unlocked episode IDs
function SaveManager:getUnlockedEpisodes()
    local unlocked = {}
    for i = 1, Constants.TOTAL_EPISODES do
        if self:isEpisodeUnlocked(i) then
            table.insert(unlocked, i)
        end
    end
    return unlocked
end

-- ============================================
-- Research Specs
-- ============================================

function SaveManager:isResearchSpecUnlocked(specId)
    -- Creative mode: all specs are unlocked
    if self:isDebugFeatureEnabled("unlockAllResearchSpecs") then
        return true
    end
    for _, id in ipairs(self.gameData.unlockedResearchSpecs) do
        if id == specId then
            return true
        end
    end
    return false
end

function SaveManager:unlockResearchSpec(specId)
    if not self:isResearchSpecUnlocked(specId) then
        table.insert(self.gameData.unlockedResearchSpecs, specId)
        self:markGameDataDirty()
        Utils.debugPrint("Research Spec unlocked: " .. specId)
    end
end

function SaveManager:getUnlockedResearchSpecs()
    -- Creative mode: return all spec IDs
    if self:isDebugFeatureEnabled("unlockAllResearchSpecs") then
        local allIds = {}
        local allSpecs = ResearchSpecsData.getAll()
        for _, spec in ipairs(allSpecs) do
            allIds[#allIds + 1] = spec.id
        end
        return allIds
    end
    return self.gameData.unlockedResearchSpecs
end

-- Check and unlock meta-progression research specs based on cumulative stats
function SaveManager:checkMetaProgressionUnlocks()
    local allSpecs = ResearchSpecsData.getAll()
    for _, spec in ipairs(allSpecs) do
        if spec.unlockCondition and not self:isResearchSpecUnlocked(spec.id) then
            local condition = spec.unlockCondition
            local shouldUnlock = false

            if condition == "total_victories_3" then
                shouldUnlock = self.gameData.totalVictories >= 3
            elseif condition == "total_deaths_5" then
                shouldUnlock = self.gameData.totalDeaths >= 5
            elseif condition == "all_episodes_complete" then
                shouldUnlock = true
                for i = 1, Constants.TOTAL_EPISODES do
                    if not self:isEpisodeCompleted(i) then
                        shouldUnlock = false
                        break
                    end
                end
            end

            if shouldUnlock then
                self:unlockResearchSpec(spec.id)
            end
        end
    end
end

-- ============================================
-- Database Unlocks
-- ============================================

-- Valid categories for database
local validCategories = {
    tools = true,
    bonusItems = true,
    enemies = true,
    bosses = true,
}

-- Check if a database entry is unlocked
function SaveManager:isDatabaseEntryUnlocked(category, id)
    if not validCategories[category] then return false end
    if not self.gameData.databaseUnlocks[category] then return false end

    for _, unlockedId in ipairs(self.gameData.databaseUnlocks[category]) do
        if unlockedId == id then
            return true
        end
    end
    return false
end

-- Unlock a database entry (returns true if newly unlocked)
function SaveManager:unlockDatabaseEntry(category, id)
    if not validCategories[category] then return false end

    -- Ensure category table exists
    if not self.gameData.databaseUnlocks[category] then
        self.gameData.databaseUnlocks[category] = {}
    end

    -- Check if already unlocked
    if self:isDatabaseEntryUnlocked(category, id) then
        return false
    end

    -- Add to unlocked list
    table.insert(self.gameData.databaseUnlocks[category], id)
    self:markGameDataDirty()
    return true
end

-- Get count of unlocked entries in a category
function SaveManager:getDatabaseUnlockCount(category)
    if not validCategories[category] then return 0 end
    if not self.gameData.databaseUnlocks[category] then return 0 end
    return #self.gameData.databaseUnlocks[category]
end

-- Get all unlocked IDs for a category
function SaveManager:getDatabaseUnlocks(category)
    if not validCategories[category] then return {} end
    return self.gameData.databaseUnlocks[category] or {}
end

-- ============================================
-- Settings
-- ============================================

function SaveManager:setSetting(key, value)
    if self.gameData.settings[key] ~= value then
        self.gameData.settings[key] = value
        self:markGameDataDirty()
    end
end

function SaveManager:getSetting(key, default)
    return self.gameData.settings[key] or default
end

-- ============================================
-- Debug Settings
-- ============================================

function SaveManager:setDebugSetting(key, value)
    if not self.gameData.debugSettings then
        self.gameData.debugSettings = {}
    end
    if self.gameData.debugSettings[key] ~= value then
        self.gameData.debugSettings[key] = value
        self:markGameDataDirty()
    end
end

function SaveManager:getDebugSetting(key, default)
    if not self.gameData.debugSettings then
        return default
    end
    local value = self.gameData.debugSettings[key]
    if value == nil then
        return default
    end
    return value
end

-- Check if debug mode is enabled and a specific debug setting is active
function SaveManager:isDebugFeatureEnabled(feature)
    local debugMode = self:getSetting("debugMode", false)
    if not debugMode then
        return false
    end
    return self:getDebugSetting(feature, true)
end

-- ============================================
-- Statistics
-- ============================================

function SaveManager:incrementDeaths()
    self.gameData.totalDeaths = self.gameData.totalDeaths + 1
    self:markGameDataDirty()
    self:checkMetaProgressionUnlocks()
end

function SaveManager:addPlayTime(seconds)
    self.gameData.totalPlayTime = self.gameData.totalPlayTime + seconds
    self:markGameDataDirty()
end

function SaveManager:getStats()
    return {
        totalPlayTime = self.gameData.totalPlayTime,
        totalDeaths = self.gameData.totalDeaths,
        totalVictories = self.gameData.totalVictories,
        episodesCompleted = #self.gameData.completedEpisodes,
        specsUnlocked = #self.gameData.unlockedResearchSpecs,
    }
end

-- ============================================
-- Episode State (Temporary)
-- ============================================

function SaveManager:saveEpisodeState(state)
    self.episodeState = state
    playdate.datastore.write(state, self.EPISODE_STATE_FILE)
    Utils.debugPrint("Episode state saved")
end

function SaveManager:loadEpisodeState()
    local state = playdate.datastore.read(self.EPISODE_STATE_FILE)
    if state then
        self.episodeState = state
        Utils.debugPrint("Episode state loaded")
    end
    return state
end

function SaveManager:clearEpisodeState()
    self.episodeState = nil
    playdate.datastore.delete(self.EPISODE_STATE_FILE)
    Utils.debugPrint("Episode state cleared")
end

function SaveManager:hasEpisodeState()
    return self.episodeState ~= nil or playdate.datastore.read(self.EPISODE_STATE_FILE) ~= nil
end

-- ============================================
-- Utility
-- ============================================

-- Save all dirty data (call periodically or on app pause/quit)
function SaveManager:flush()
    if self.gameDataDirty then
        self:saveGameData()
    end
end

-- Reset all save data (for testing or new game)
function SaveManager:resetAllData()
    self.gameData = {
        completedEpisodes = {},
        unlockedResearchSpecs = {},
        totalPlayTime = 0,
        totalDeaths = 0,
        totalVictories = 0,
        settings = {
            musicVolume = 0.7,
            sfxVolume = 1.0,
            debugMode = false,
            introSeen = false,
        },
        debugSettings = {
            episodeLength = 60,
            waveLength = 8,
            stationInvincible = true,
            unlockAllEquipment = true,
            unlockAllEpisodes = true,
            unlockAllDatabase = true,
            unlockAllResearchSpecs = true,
            difficultyMultiplier = 1.0,
            toolPlacementEnabled = true,
        },
        databaseUnlocks = {
            tools = {},
            bonusItems = {},
            enemies = {},
            bosses = {},
        },
        grantFunds = 0,
        grantFundingLevels = {
            health = 0,
            damage = 0,
            shields = 0,
            research = 0,
            expanded_memory = 0,
        },
        equippedResearchSpecs = nil,
    }
    playdate.datastore.delete(self.GAME_DATA_FILE)
    playdate.datastore.delete(self.EPISODE_STATE_FILE)
    Utils.debugPrint("All save data reset")
end

-- ============================================
-- Grant Funding
-- ============================================

-- Add grant funds (called when player loses)
function SaveManager:addGrantFunds(amount)
    self.gameData.grantFunds = self.gameData.grantFunds + amount
    self:markGameDataDirty()
    Utils.debugPrint("Added " .. amount .. " grant funds. Total: " .. self.gameData.grantFunds)
end

-- Spend grant funds (returns true if successful)
function SaveManager:spendGrantFunds(amount)
    if self.gameData.grantFunds >= amount then
        self.gameData.grantFunds = self.gameData.grantFunds - amount
        self:markGameDataDirty()
        return true
    end
    return false
end

-- Get current grant funds balance
function SaveManager:getGrantFunds()
    return self.gameData.grantFunds or 0
end

-- Get grant funding level for a stat (health, damage, shields, research, expanded_memory)
function SaveManager:getGrantFundingLevel(stat)
    -- Creative mode with Unlock All Research: all stats maxed
    if self:isDebugFeatureEnabled("unlockAllResearchSpecs") then
        return 4
    end
    if not self.gameData.grantFundingLevels then
        return 0
    end
    return self.gameData.grantFundingLevels[stat] or 0
end

-- Upgrade a grant funding stat (returns true if successful)
function SaveManager:upgradeGrantFunding(stat, cost)
    local currentLevel = self:getGrantFundingLevel(stat)
    if currentLevel >= 4 then
        return false  -- Already maxed
    end

    if not self:spendGrantFunds(cost) then
        return false  -- Can't afford
    end

    self.gameData.grantFundingLevels[stat] = currentLevel + 1
    self:markGameDataDirty()
    Utils.debugPrint("Upgraded " .. stat .. " to level " .. (currentLevel + 1))
    return true
end

-- ============================================
-- Equipped Research Specs
-- ============================================

-- Save equipped research spec IDs
function SaveManager:saveEquippedSpecs(specIds)
    self.gameData.equippedResearchSpecs = specIds
    self:markGameDataDirty()
end

-- Get equipped research spec IDs (nil = auto-equip mode)
function SaveManager:getEquippedResearchSpecs()
    return self.gameData.equippedResearchSpecs
end

return SaveManager
