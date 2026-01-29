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
        },
    },

    -- Current episode state (deleted on episode end)
    episodeState = nil,

    -- File names
    GAME_DATA_FILE = "game_data",
    EPISODE_STATE_FILE = "episode_state",

    -- Dirty flags for save optimization
    gameDataDirty = false,
    episodeStateDirty = false,
}

function SaveManager:init()
    -- Load game data on init
    self:loadGameData()
    print("SaveManager initialized")
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
        end

        print("Game data loaded successfully")
    else
        print("No saved game data found, using defaults")
    end
end

function SaveManager:saveGameData()
    playdate.datastore.write(self.gameData, self.GAME_DATA_FILE)
    self.gameDataDirty = false
    print("Game data saved")
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
        print("Research Spec unlocked: " .. specId)
    end
end

function SaveManager:getUnlockedResearchSpecs()
    return self.gameData.unlockedResearchSpecs
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
-- Statistics
-- ============================================

function SaveManager:incrementDeaths()
    self.gameData.totalDeaths = self.gameData.totalDeaths + 1
    self:markGameDataDirty()
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
    print("Episode state saved")
end

function SaveManager:loadEpisodeState()
    local state = playdate.datastore.read(self.EPISODE_STATE_FILE)
    if state then
        self.episodeState = state
        print("Episode state loaded")
    end
    return state
end

function SaveManager:clearEpisodeState()
    self.episodeState = nil
    playdate.datastore.delete(self.EPISODE_STATE_FILE)
    print("Episode state cleared")
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
        },
    }
    playdate.datastore.delete(self.GAME_DATA_FILE)
    playdate.datastore.delete(self.EPISODE_STATE_FILE)
    print("All save data reset")
end

return SaveManager
