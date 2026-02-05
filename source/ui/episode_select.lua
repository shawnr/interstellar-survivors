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
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    -- White rule above footer
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
    -- White footer text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setFooterFont()
    gfx.drawTextAligned("[A] Select   [B] Back",
        Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return EpisodeSelect
