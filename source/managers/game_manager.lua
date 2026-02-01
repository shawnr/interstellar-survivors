-- Game Manager
-- Handles game state machine and scene transitions

local gfx <const> = playdate.graphics

GameManager = {
    -- Game states
    states = {
        BOOT = "boot",
        TITLE = "title",
        MAIN_MENU = "main_menu",
        EPISODE_SELECT = "episode_select",
        RESEARCH_SPECS = "research_specs",
        SETTINGS = "settings",
        STORY_INTRO = "story_intro",
        GAMEPLAY = "gameplay",
        PAUSE = "pause",
        LEVELUP = "levelup",
        GAME_OVER = "game_over",
        VICTORY = "victory",
        STORY_ENDING = "story_ending",
        CREDITS = "credits"
    },

    -- Current state tracking
    currentState = nil,
    previousState = nil,
    currentScene = nil,

    -- Scene registry
    scenes = {},

    -- Episode tracking
    episodeInProgress = false,
    currentEpisodeId = nil,

    -- Gameplay state (shared across scenes)
    playerLevel = 1,
    currentRP = 0,
    rpToNextLevel = 0,
}

function GameManager:init()
    -- Register scenes (will be created as we implement them)

    -- Create placeholder title scene
    self.scenes[self.states.TITLE] = self:createTitleScene()

    -- Create episode select scene
    self.scenes[self.states.EPISODE_SELECT] = self:createEpisodeSelectScene()

    -- Create story intro scene
    self.scenes[self.states.STORY_INTRO] = self:createStoryIntroScene()

    -- Register gameplay scene
    GameplayScene:init()
    self.scenes[self.states.GAMEPLAY] = GameplayScene

    -- Create game over scene
    self.scenes[self.states.GAME_OVER] = self:createGameOverScene()

    -- Create settings scene
    self.scenes[self.states.SETTINGS] = self:createSettingsScene()

    -- Create victory/story ending scene
    self.scenes[self.states.VICTORY] = self:createVictoryScene()

    -- Initialize RP to next level
    self.rpToNextLevel = Utils.xpToNextLevel(1)
end

function GameManager:setState(newState, params)
    -- Exit current scene
    if self.currentScene and self.currentScene.exit then
        self.currentScene:exit()
    end

    -- Track state transition
    self.previousState = self.currentState
    self.currentState = newState

    -- Get new scene
    self.currentScene = self.scenes[newState]

    -- Enter new scene
    if self.currentScene and self.currentScene.enter then
        self.currentScene:enter(params)
    end

    print("GameManager: State changed to " .. newState)
end

function GameManager:returnToPreviousState()
    if self.previousState then
        self:setState(self.previousState)
    end
end

-- Register a scene for a state
function GameManager:registerScene(state, scene)
    self.scenes[state] = scene
end

-- Award RP to the player (called when MOBs destroyed or collectibles gathered)
function GameManager:awardRP(amount)
    -- Apply RP bonus from research specs
    local rpBonus = 0
    if ResearchSpecSystem then
        rpBonus = ResearchSpecSystem:getRPBonus()
    end

    local adjustedAmount = math.floor(amount * (1 + rpBonus))
    self.currentRP = self.currentRP + adjustedAmount

    -- Check for level up
    if self.currentRP >= self.rpToNextLevel then
        self:levelUp()
    end
end

-- Handle level up
function GameManager:levelUp()
    self.playerLevel = self.playerLevel + 1

    -- Calculate new RP threshold
    local oldThreshold = self.rpToNextLevel
    self.rpToNextLevel = Utils.xpToNextLevel(self.playerLevel)

    -- Carry over excess RP
    self.currentRP = self.currentRP - oldThreshold

    -- Trigger level up UI
    if self.currentScene and self.currentScene.onLevelUp then
        self.currentScene:onLevelUp()
    end

    print("Level Up! Now level " .. self.playerLevel)
end

-- Reset gameplay state for new episode
function GameManager:startNewEpisode(episodeId)
    self.currentEpisodeId = episodeId
    self.episodeInProgress = true

    -- Check for starting level bonus from research specs
    local startingLevel = 1
    if ResearchSpecSystem then
        startingLevel = ResearchSpecSystem:getStartingLevel()
    end

    self.playerLevel = startingLevel
    self.currentRP = 0
    self.rpToNextLevel = Utils.xpToNextLevel(startingLevel)
end

-- End current episode
function GameManager:endEpisode(victory)
    self.episodeInProgress = false

    if victory then
        -- Mark episode as completed and save
        SaveManager:markEpisodeCompleted(self.currentEpisodeId)
        SaveManager:flush()
        self:setState(self.states.VICTORY)
    else
        -- Track death and save
        SaveManager:incrementDeaths()
        SaveManager:flush()
        self:setState(self.states.GAME_OVER)
    end
end

-- Create title scene with background, rotating taglines, and theme music
function GameManager:createTitleScene()
    local titleScene = {}

    local bgImage = nil
    local blinkTimer = 0
    local showText = true
    local taglineTimer = 0
    local currentTagline = ""

    -- Taglines from design doc
    local taglines = {
        "Boldly going to have boldly gone!",
        "My gosh, it's full of paperwork!",
        "Intrepid Space Adventurers Wanted",
        "To probability, and beyond!",
        "Live long and file reports.",
        "In space, no one can hear you take notes.",
        "The spice must document.",
        "So long, and thanks for all the data.",
        "Collect knowledge. Avoid death. Repeat.",
        "The universe is trying to kill you. Write it down.",
        "Every discovery could be your last. Make it count.",
        "Curiosity killed the cat. You're not a cat... probably.",
        "Set phasers to 'document.'",
        "Tea. Earl Grey. And a comprehensive survey.",
        "The truth is out there. Go catalog it.",
        "Warning: May contain trace amounts of existential dread.",
        "Now with 40% more inexplicable alien artifacts!",
        "Your sacrifice will be noted. Literally.",
        "Knowledge is power. Power is survival. Survival is unlikely.",
        "Maserati sends her regards.",
        "Do NOT insult the poetry.",
        "Diplomatic hugs incoming.",
        "11,000 verses. One fly.",
        "Please rate your survival experience.",
        "Synergy. Alignment. Explosion.",
        "Quarterly targets: survival optional.",
        "The consultants are here to help.",
        "The whale seems fine.",
        "Please file Form 42-B.",
        "The sofa remains unexplained.",
        "Reality is more of a suggestion.",
        "Coincidence rate: Improbable.",
        "The Chomper remembers.",
        "Salvage rights: contested.",
        "Always let the Vorthian win.",
        "Peer review can be brutal. Literally.",
        "Attendance is mandatory. Survival is extra credit.",
        "The Professor has notes.",
        "A qualified success.",
    }

    local function pickNewTagline()
        local newTagline = taglines[math.random(#taglines)]
        -- Reject if same as current
        while newTagline == currentTagline and #taglines > 1 do
            newTagline = taglines[math.random(#taglines)]
        end
        currentTagline = newTagline
    end

    function titleScene:enter(params)
        print("Entering title scene")

        -- Load background image
        bgImage = gfx.image.new("images/ui/title_bg")
        if not bgImage then
            print("Warning: Could not load title background")
        end

        -- Pick initial tagline
        pickNewTagline()
        taglineTimer = 0

        -- Play theme music
        print("Title scene: Attempting to play music...")
        print("AudioManager.musicMuted = " .. tostring(AudioManager.musicMuted))
        print("AudioManager.musicVolume = " .. tostring(AudioManager.musicVolume))
        AudioManager:playMusic("sounds/music_title_theme", true)
    end

    function titleScene:update()
        -- Blink "Press any button" text
        blinkTimer = blinkTimer + 1
        if blinkTimer >= 30 then
            blinkTimer = 0
            showText = not showText
        end

        -- Rotate tagline every 20 seconds (600 frames at 30fps)
        taglineTimer = taglineTimer + 1
        if taglineTimer >= 600 then
            taglineTimer = 0
            pickNewTagline()
        end

        -- Check for any button to go to episode select
        if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.b then
            GameManager:setState(GameManager.states.EPISODE_SELECT)
        end
    end

    function titleScene:drawOverlay()
        -- Draw background image (full screen)
        if bgImage then
            bgImage:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        -- Draw tagline in a 145x90 box positioned to bottom-right of rocket
        -- Text box: 145px wide, 90px tall, top-left at approximately (250, 125)
        local boxX = 250
        local boxY = 125
        local boxWidth = 145
        local boxHeight = 90

        -- Format tagline with bold markers
        local taglineText = "*" .. currentTagline .. "*"

        -- Check text length and use smaller font for longer taglines
        -- Default system font is about 16px tall, we need text to fit in 90px height
        -- Longer taglines (over ~35 chars) may need wrapping or smaller consideration
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        -- Draw text wrapped within the rectangle
        -- drawTextInRect returns (width, height, textWasTruncated)
        local _, textHeight, truncated = gfx.getTextSizeForMaxWidth(taglineText, boxWidth)

        -- If text would be too tall, we need to handle it
        -- For now, draw with wrapping enabled
        gfx.drawTextInRect(taglineText, boxX, boxY, boxWidth, boxHeight, nil, nil, kTextAlignment.left)

        -- Draw blinking prompt at bottom
        if showText then
            gfx.drawTextAligned("*Press Any Button to Start*", Constants.SCREEN_WIDTH / 2, 210, kTextAlignment.center)
        end

        -- Draw version number in lower left corner
        local versionText = "v" .. Constants.VERSION
        gfx.drawText(versionText, 4, Constants.SCREEN_HEIGHT - 14)
    end

    function titleScene:exit()
        print("Exiting title scene")
        -- Stop theme music when leaving title
        AudioManager:stopMusic()
    end

    return titleScene
end

-- Create episode select scene
function GameManager:createEpisodeSelectScene()
    local scene = {}

    function scene:enter(params)
        print("Entering episode select scene")

        -- Show episode select UI
        EpisodeSelect:show(function(episodeId)
            -- Episode selected - start it
            GameManager:startNewEpisode(episodeId)
            GameManager:setState(GameManager.states.STORY_INTRO)
        end)
    end

    function scene:update()
        EpisodeSelect:update()
    end

    function scene:drawOverlay()
        EpisodeSelect:draw()
    end

    function scene:exit()
        print("Exiting episode select scene")
        EpisodeSelect:hide()
    end

    return scene
end

-- Create game over scene
function GameManager:createGameOverScene()
    local scene = {}

    local bgImage = nil

    function scene:enter(params)
        print("Entering game over scene")
        bgImage = gfx.image.new("images/shared/to_be_continued")
    end

    function scene:update()
        -- Check for button press to return to episode select
        if InputManager.buttonJustPressed.a then
            GameManager:setState(GameManager.states.EPISODE_SELECT)
        end
    end

    function scene:drawOverlay()
        gfx.clear(gfx.kColorBlack)

        if bgImage then
            bgImage:draw(0, 0)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned("*TO BE CONTINUED...*", 200, 100, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("Press A to continue", 200, 200, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    function scene:exit()
        print("Exiting game over scene")
    end

    return scene
end

-- Create story intro scene
function GameManager:createStoryIntroScene()
    local scene = {}

    function scene:enter(params)
        print("Entering story intro scene")

        -- Get episode data
        local episodeData = EpisodesData.get(GameManager.currentEpisodeId)

        if episodeData and episodeData.introPanels and #episodeData.introPanels > 0 then
            -- Show intro panels
            StoryPanel:show(episodeData.introPanels, function()
                -- When done, transition to gameplay
                GameManager:setState(GameManager.states.GAMEPLAY)
            end)
        else
            -- No intro panels, go straight to gameplay
            GameManager:setState(GameManager.states.GAMEPLAY)
        end
    end

    function scene:update()
        StoryPanel:update()
    end

    function scene:drawOverlay()
        StoryPanel:draw()
    end

    function scene:exit()
        print("Exiting story intro scene")
    end

    return scene
end

-- Create victory scene (shows ending panels then returns to title)
function GameManager:createVictoryScene()
    local scene = {}
    local showingPanels = false
    local victoryShown = false

    function scene:enter(params)
        print("Entering victory scene")
        showingPanels = false
        victoryShown = false

        -- Get episode data
        local episodeData = EpisodesData.get(GameManager.currentEpisodeId)

        if episodeData and episodeData.endingPanels and #episodeData.endingPanels > 0 then
            -- Show ending panels
            showingPanels = true
            StoryPanel:show(episodeData.endingPanels, function()
                -- When done with panels, show victory screen
                showingPanels = false
                victoryShown = true
            end)
        else
            -- No ending panels, show victory screen directly
            victoryShown = true
        end
    end

    function scene:update()
        if showingPanels then
            StoryPanel:update()
        elseif victoryShown then
            -- Check for button press to return to episode select
            if InputManager.buttonJustPressed.a then
                GameManager:setState(GameManager.states.EPISODE_SELECT)
            end
        end
    end

    function scene:drawOverlay()
        if showingPanels then
            StoryPanel:draw()
        elseif victoryShown then
            gfx.clear(gfx.kColorBlack)

            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned("*EPISODE COMPLETE!*", 200, 80, kTextAlignment.center)

            -- Show stats
            gfx.drawTextAligned("Final Level: " .. GameManager.playerLevel, 200, 120, kTextAlignment.center)

            -- Get episode data for title
            local episodeData = EpisodesData.get(GameManager.currentEpisodeId)
            if episodeData then
                gfx.drawTextAligned(episodeData.title, 200, 150, kTextAlignment.center)
            end

            gfx.drawTextAligned("Press A to continue", 200, 200, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end

    function scene:exit()
        print("Exiting victory scene")
        showingPanels = false
        victoryShown = false
    end

    return scene
end

-- Create settings scene
function GameManager:createSettingsScene()
    local scene = {}

    local menuItems = {
        { label = "Music Volume", type = "slider", key = "musicVolume", min = 0, max = 1, step = 0.1 },
        { label = "SFX Volume", type = "slider", key = "sfxVolume", min = 0, max = 1, step = 0.1 },
        { label = "Debug Mode", type = "toggle", key = "debugMode" },
        { label = "Reset All Data", type = "action", action = "reset" },
        { label = "Back", type = "action", action = "back" },
    }

    local selectedIndex = 1
    local confirmingReset = false
    local confirmIndex = 2  -- Default to "No"
    local patternBg = nil
    local previousState = nil  -- Track where we came from

    function scene:enter(params)
        print("Entering settings scene")
        selectedIndex = 1
        confirmingReset = false
        -- Track where we came from so we can return there
        previousState = params and params.fromState or GameManager.states.EPISODE_SELECT
        -- Load pattern background
        patternBg = gfx.image.new("images/ui/menu_pattern_bg")
    end

    function scene:update()
        if confirmingReset then
            -- Handle reset confirmation
            if InputManager.buttonJustPressed.left then
                confirmIndex = 1  -- Yes
            elseif InputManager.buttonJustPressed.right then
                confirmIndex = 2  -- No
            elseif InputManager.buttonJustPressed.a then
                if confirmIndex == 1 then
                    -- Confirmed reset
                    SaveManager:resetAllData()
                    confirmingReset = false
                else
                    -- Cancelled
                    confirmingReset = false
                end
            elseif InputManager.buttonJustPressed.b then
                confirmingReset = false
            end
            return
        end

        -- Navigation
        if InputManager.buttonJustPressed.up then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then
                selectedIndex = #menuItems
            end
        elseif InputManager.buttonJustPressed.down then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #menuItems then
                selectedIndex = 1
            end
        end

        -- Handle selected item
        local item = menuItems[selectedIndex]

        if item.type == "slider" then
            local currentValue = SaveManager:getSetting(item.key, 0.7)

            if InputManager.buttonJustPressed.left then
                currentValue = math.max(item.min, currentValue - item.step)
                SaveManager:setSetting(item.key, currentValue)
                SaveManager:flush()
                -- Update audio manager
                if item.key == "musicVolume" and AudioManager then
                    AudioManager:setMusicVolume(currentValue)
                elseif item.key == "sfxVolume" and AudioManager then
                    AudioManager:setSFXVolume(currentValue)
                end
            elseif InputManager.buttonJustPressed.right then
                currentValue = math.min(item.max, currentValue + item.step)
                SaveManager:setSetting(item.key, currentValue)
                SaveManager:flush()
                -- Update audio manager
                if item.key == "musicVolume" and AudioManager then
                    AudioManager:setMusicVolume(currentValue)
                elseif item.key == "sfxVolume" and AudioManager then
                    AudioManager:setSFXVolume(currentValue)
                end
            end
        elseif item.type == "toggle" then
            if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.left or InputManager.buttonJustPressed.right then
                local currentValue = SaveManager:getSetting(item.key, false)
                SaveManager:setSetting(item.key, not currentValue)
                SaveManager:flush()

                -- Refresh episode select when debug mode changes
                if item.key == "debugMode" and EpisodeSelect then
                    EpisodeSelect:refreshEpisodes()
                end
            end
        elseif item.type == "action" then
            if InputManager.buttonJustPressed.a then
                if item.action == "back" then
                    GameManager:setState(previousState or GameManager.states.EPISODE_SELECT)
                elseif item.action == "reset" then
                    confirmingReset = true
                    confirmIndex = 2  -- Default to "No"
                end
            end
        end

        -- B button always goes back
        if InputManager.buttonJustPressed.b then
            GameManager:setState(previousState or GameManager.states.EPISODE_SELECT)
        end
    end

    function scene:drawOverlay()
        -- Draw pattern background
        if patternBg then
            patternBg:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        -- Title bar with white background for readability
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
        gfx.drawTextAligned("*SETTINGS*", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)

        -- Draw menu items
        local startY = 52
        local itemHeight = 32

        for i, item in ipairs(menuItems) do
            local y = startY + (i - 1) * itemHeight
            local isSelected = (i == selectedIndex)

            -- Row background for readability
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26)

            -- Selection indicator or border
            gfx.setColor(gfx.kColorBlack)
            if isSelected then
                gfx.fillRoundRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26, 4)
            else
                gfx.drawRoundRect(20, y - 4, Constants.SCREEN_WIDTH - 40, 26, 4)
            end

            if item.type == "slider" then
                local value = SaveManager:getSetting(item.key, 0.7)
                local percent = math.floor(value * 100)

                -- Label (white if selected, black otherwise)
                if isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end
                gfx.drawText(item.label, 30, y)

                -- Slider track
                local sliderX = 220
                local sliderWidth = 100
                local sliderY = y + 4

                gfx.setImageDrawMode(gfx.kDrawModeCopy)
                if isSelected then
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillRect(sliderX, sliderY, sliderWidth, 10)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.drawRect(sliderX, sliderY, sliderWidth, 10)
                    -- Fill
                    local fillWidth = math.floor(value * (sliderWidth - 2))
                    gfx.fillRect(sliderX + 1, sliderY + 1, fillWidth, 8)
                else
                    gfx.setColor(gfx.kColorBlack)
                    gfx.drawRect(sliderX, sliderY, sliderWidth, 10)
                    local fillWidth = math.floor(value * (sliderWidth - 2))
                    gfx.fillRect(sliderX + 1, sliderY + 1, fillWidth, 8)
                end

                -- Percentage text
                if isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end
                gfx.drawText(percent .. "%", sliderX + sliderWidth + 10, y)

            elseif item.type == "toggle" then
                local value = SaveManager:getSetting(item.key, false)

                -- Text mode
                if isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                gfx.drawText(item.label, 30, y)
                local toggleText = value and "ON" or "OFF"
                gfx.drawText(toggleText, 320, y)

            elseif item.type == "action" then
                -- Text mode
                if isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                gfx.drawText(item.label, 30, y)

                if item.action == "reset" then
                    gfx.drawText("(press A)", 280, y)
                elseif item.action == "back" then
                    gfx.drawText("(press A or B)", 250, y)
                end
            end

            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        -- Instructions bar at bottom
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
        gfx.drawTextAligned("D-pad to navigate, A to select", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)

        -- Reset confirmation dialog
        if confirmingReset then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(50, 80, 300, 80)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(50, 80, 300, 80)

            gfx.drawTextAligned("Reset all progress?", Constants.SCREEN_WIDTH / 2, 95, kTextAlignment.center)
            gfx.drawTextAligned("This cannot be undone!", Constants.SCREEN_WIDTH / 2, 115, kTextAlignment.center)

            local yesX = 120
            local noX = 230
            local buttonY = 138

            if confirmIndex == 1 then
                gfx.fillRoundRect(yesX - 10, buttonY - 2, 60, 20, 4)
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                gfx.drawText("Yes", yesX, buttonY)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
                gfx.drawText("No", noX, buttonY)
            else
                gfx.drawText("Yes", yesX, buttonY)
                gfx.fillRoundRect(noX - 10, buttonY - 2, 60, 20, 4)
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                gfx.drawText("No", noX, buttonY)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end
        end
    end

    function scene:exit()
        print("Exiting settings scene")
        confirmingReset = false
    end

    return scene
end

return GameManager
