-- Episode Select UI
-- Allows player to choose which episode to play
-- Includes resume prompt when a saved session exists

local gfx <const> = playdate.graphics

EpisodeSelect = {
    isVisible = false,
    selectedIndex = 1,
    episodes = {},
    unlockedEpisodes = {},
    onSelect = nil,
    onResume = nil,

    -- Resume prompt state
    showingResumePrompt = false,
    resumeData = nil,
    resumeConfirmIndex = 1,  -- 1 = Resume, 2 = New Game
}

function EpisodeSelect:init()
    -- Load episode data
    self:refreshEpisodes()
    Utils.debugPrint("EpisodeSelect initialized")
end

function EpisodeSelect:refreshEpisodes()
    self.episodes = {}
    self.unlockedEpisodes = {}

    -- Check if debug mode unlock all episodes is enabled
    local unlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllEpisodes")

    -- Get all episodes
    for i = 1, Constants.TOTAL_EPISODES do
        local data = EpisodesData.get(i)
        if data then
            table.insert(self.episodes, data)

            -- Check if unlocked using SaveManager (or debug mode)
            local isUnlocked = unlockAll or SaveManager:isEpisodeUnlocked(i)
            self.unlockedEpisodes[i] = isUnlocked
        end
    end
end

function EpisodeSelect:show(selectCallback, resumeCallback)
    self.isVisible = true
    self.selectedIndex = 1
    self.onSelect = selectCallback
    self.onResume = resumeCallback
    self:refreshEpisodes()

    -- Check for saved session
    local sessionData = SaveManager:loadEpisodeState()
    if sessionData and sessionData.episodeId then
        self.showingResumePrompt = true
        self.resumeData = sessionData
        self.resumeConfirmIndex = 1  -- Default to Resume
    else
        self.showingResumePrompt = false
        self.resumeData = nil
    end

    -- Find first unlocked episode
    for i, _ in ipairs(self.episodes) do
        if self.unlockedEpisodes[i] then
            self.selectedIndex = i
            break
        end
    end
end

function EpisodeSelect:hide()
    self.isVisible = false
    self.onSelect = nil
    self.onResume = nil
    self.showingResumePrompt = false
    self.resumeData = nil
end

function EpisodeSelect:update()
    if not self.isVisible then return end

    -- Handle resume prompt input
    if self.showingResumePrompt then
        self:updateResumePrompt()
        return
    end

    -- Handle input - up/right = up, down/left = down
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self:moveSelection(-1)
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self:moveSelection(1)
    end

    -- A button to select
    if InputManager.buttonJustPressed.a then
        self:confirmSelection()
    end

    -- B button to go back
    if InputManager.buttonJustPressed.b then
        self:hide()
        GameManager:setState(GameManager.states.TITLE)
    end

    -- Crank can also navigate (every 30 degrees)
    local crankChange = playdate.getCrankChange()
    if math.abs(crankChange) > 15 then
        if crankChange > 0 then
            self:moveSelection(1)
        else
            self:moveSelection(-1)
        end
    end
end

function EpisodeSelect:updateResumePrompt()
    if InputManager.buttonJustPressed.left or InputManager.buttonJustPressed.up then
        self.resumeConfirmIndex = 1  -- Resume
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    elseif InputManager.buttonJustPressed.right or InputManager.buttonJustPressed.down then
        self.resumeConfirmIndex = 2  -- New Game
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    elseif InputManager.buttonJustPressed.a then
        if self.resumeConfirmIndex == 1 then
            -- Resume saved session
            if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
            local data = self.resumeData
            local callback = self.onResume
            self:hide()
            if callback and data then
                callback(data)
            end
        else
            -- New Game: clear save and show episode list
            if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
            SaveManager:clearEpisodeState()
            self.showingResumePrompt = false
            self.resumeData = nil
        end
    elseif InputManager.buttonJustPressed.b then
        -- B dismisses prompt and shows episode list (save persists)
        if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
        self.showingResumePrompt = false
    end
end

function EpisodeSelect:moveSelection(direction)
    local newIndex = self.selectedIndex + direction

    -- Wrap around
    if newIndex < 1 then
        newIndex = #self.episodes
    elseif newIndex > #self.episodes then
        newIndex = 1
    end

    self.selectedIndex = newIndex

    -- Play navigation sound
    if AudioManager then
        AudioManager:playSFX("menu_move", 0.3)
    end
end

function EpisodeSelect:confirmSelection()
    local episode = self.episodes[self.selectedIndex]
    if not episode then return end

    -- Check if unlocked
    if not self.unlockedEpisodes[self.selectedIndex] then
        -- Play error sound
        if AudioManager then
            AudioManager:playSFX("menu_error", 0.5)
        end
        return
    end

    -- Play confirm sound
    if AudioManager then
        AudioManager:playSFX("menu_confirm", 0.5)
    end

    -- Call callback with selected episode
    local callback = self.onSelect
    self:hide()

    if callback then
        callback(episode.id)
    end
end

function EpisodeSelect:draw()
    if not self.isVisible then return end

    gfx.clear(gfx.kColorBlack)

    -- Title bar with black background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    -- White horizontal rule below header
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    -- White header text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setTitleFont()
    gfx.drawTextAligned("SELECT EPISODE", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw episodes
    local startY = 52
    local itemHeight = 32

    FontManager:setMenuFont()

    for i, episode in ipairs(self.episodes) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == self.selectedIndex)
        local isUnlocked = self.unlockedEpisodes[i]

        if isSelected then
            -- Selected: WHITE fill, BLACK text
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            -- Unselected: BLACK fill, WHITE border, WHITE text
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26, 4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRoundRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- Episode number and title (or locked)
        local titleText
        if isUnlocked then
            titleText = i .. ". " .. episode.title
        else
            titleText = i .. ". [LOCKED]"
        end

        gfx.drawText(titleText, 30, y)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw instructions at bottom with black background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, 26)
    -- White rule above footer
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 26)
    -- White footer text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setFooterFont()
    gfx.drawTextAligned("[A] Select   [B] Back",
        Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 19, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw resume prompt overlay if active
    if self.showingResumePrompt then
        self:drawResumePrompt()
    end
end

function EpisodeSelect:drawResumePrompt()
    local data = self.resumeData
    if not data then return end

    -- Dim background
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Dialog box
    local dialogW = 320
    local dialogH = 140
    local dialogX = (Constants.SCREEN_WIDTH - dialogW) / 2
    local dialogY = (Constants.SCREEN_HEIGHT - dialogH) / 2

    -- BLACK fill
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(dialogX, dialogY, dialogW, dialogH)
    -- WHITE double-line border
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(dialogX, dialogY, dialogW, dialogH)
    gfx.drawRect(dialogX + 2, dialogY + 2, dialogW - 4, dialogH - 4)

    -- Title
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setTitleFont()
    gfx.drawTextAligned("GAME IN PROGRESS", Constants.SCREEN_WIDTH / 2, dialogY + 12, kTextAlignment.center)

    -- Episode name
    FontManager:setMenuFont()
    local episodeName = "Unknown Episode"
    local episodeData = EpisodesData.get(data.episodeId)
    if episodeData then
        episodeName = "Ep " .. data.episodeId .. ": " .. episodeData.title
    end
    gfx.drawTextAligned("*" .. episodeName .. "*", Constants.SCREEN_WIDTH / 2, dialogY + 38, kTextAlignment.center)

    -- Metadata line
    FontManager:setBodyFont()
    local wave = data.currentWave or 1
    local level = data.playerLevel or 1
    local elapsed = data.elapsedTime or 0
    local mins = math.floor(elapsed / 60)
    local secs = math.floor(elapsed % 60)
    local metaText = "Level " .. level .. "  |  Wave " .. wave .. "  |  " .. string.format("%d:%02d", mins, secs)
    gfx.drawTextAligned(metaText, Constants.SCREEN_WIDTH / 2, dialogY + 58, kTextAlignment.center)

    -- Prompt
    gfx.drawTextAligned("Resume this game?", Constants.SCREEN_WIDTH / 2, dialogY + 78, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Buttons
    local resumeX = dialogX + 60
    local newGameX = dialogX + dialogW - 130
    local buttonY = dialogY + dialogH - 30
    local buttonW = 80
    local buttonH = 22

    FontManager:setMenuFont()

    if self.resumeConfirmIndex == 1 then
        -- Resume selected: WHITE fill, BLACK text
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(resumeX, buttonY, buttonW, buttonH, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.drawTextAligned("*Resume*", resumeX + buttonW / 2, buttonY + 3, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("*New Game*", newGameX + buttonW / 2, buttonY + 3, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    else
        -- New Game selected: WHITE fill, BLACK text
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("*Resume*", resumeX + buttonW / 2, buttonY + 3, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(newGameX, buttonY, buttonW, buttonH, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.drawTextAligned("*New Game*", newGameX + buttonW / 2, buttonY + 3, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

return EpisodeSelect
