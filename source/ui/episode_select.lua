-- Episode Select UI
-- Allows player to choose which episode to play

local gfx <const> = playdate.graphics

EpisodeSelect = {
    isVisible = false,
    selectedIndex = 1,
    episodes = {},
    unlockedEpisodes = {},
    onSelect = nil,
}

function EpisodeSelect:init()
    -- Load episode data
    self:refreshEpisodes()
    print("EpisodeSelect initialized")
end

function EpisodeSelect:refreshEpisodes()
    self.episodes = {}
    self.unlockedEpisodes = {}

    -- Check if debug mode is enabled
    local debugMode = SaveManager and SaveManager:getSetting("debugMode", false)

    -- Get all episodes
    for i = 1, Constants.TOTAL_EPISODES do
        local data = EpisodesData.get(i)
        if data then
            table.insert(self.episodes, data)

            -- Check if unlocked using SaveManager (or debug mode)
            local isUnlocked = debugMode or SaveManager:isEpisodeUnlocked(i)
            self.unlockedEpisodes[i] = isUnlocked
        end
    end
end

function EpisodeSelect:show(callback)
    self.isVisible = true
    self.selectedIndex = 1
    self.onSelect = callback
    self:refreshEpisodes()

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
end

function EpisodeSelect:update()
    if not self.isVisible then return end

    -- Handle input - up/down to navigate
    if InputManager.buttonJustPressed.up then
        self:moveSelection(-1)
    elseif InputManager.buttonJustPressed.down then
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

    -- Clear screen
    gfx.clear(gfx.kColorWhite)

    -- Draw title
    gfx.drawTextAligned("*SELECT EPISODE*", Constants.SCREEN_WIDTH / 2, 8, kTextAlignment.center)

    -- Draw horizontal line
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(20, 26, Constants.SCREEN_WIDTH - 20, 26)

    -- Draw episodes (compact list)
    local startY = 32
    local itemHeight = 22

    for i, episode in ipairs(self.episodes) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == self.selectedIndex)
        local isUnlocked = self.unlockedEpisodes[i]

        -- Draw selection highlight
        if isSelected then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(10, y, Constants.SCREEN_WIDTH - 20, itemHeight - 2, 3)
        end

        -- Set draw mode based on selection
        if isSelected then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        -- Episode number and title (or locked)
        local titleText
        if isUnlocked then
            titleText = i .. ". " .. episode.title
        else
            titleText = i .. ". [LOCKED]"
        end

        gfx.drawText(titleText, 18, y + 3)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw selected episode details below the list
    local detailY = startY + (#self.episodes * itemHeight) + 8
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(20, detailY - 4, Constants.SCREEN_WIDTH - 20, detailY - 4)

    local selectedEpisode = self.episodes[self.selectedIndex]
    if selectedEpisode then
        local isUnlocked = self.unlockedEpisodes[self.selectedIndex]

        if isUnlocked then
            -- Show tagline
            gfx.drawTextAligned("\"" .. selectedEpisode.tagline .. "\"",
                Constants.SCREEN_WIDTH / 2, detailY, kTextAlignment.center)
        else
            -- Show unlock requirement
            gfx.drawTextAligned("Complete Episode " .. (self.selectedIndex - 1) .. " to unlock",
                Constants.SCREEN_WIDTH / 2, detailY, kTextAlignment.center)
        end
    end

    -- Draw instructions at bottom
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 20, Constants.SCREEN_WIDTH, 20)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("[A] Select   [B] Back   Crank to scroll",
        Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 14, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return EpisodeSelect
