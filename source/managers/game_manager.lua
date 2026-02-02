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
        RESEARCH_MENU = "research_menu",
        RESEARCH_SPECS = "research_specs",
        GRANT_FUNDING = "grant_funding",
        DATABASE = "database",
        SETTINGS = "settings",
        DEBUG_OPTIONS = "debug_options",
        EPISODE_TITLE = "episode_title",
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

    -- Selected starting tool (from Tool Mastery research spec)
    selectedStartingTool = nil,  -- nil means use default (Rail Driver)
}

function GameManager:init()
    -- Register scenes (will be created as we implement them)

    -- Create placeholder title scene
    self.scenes[self.states.TITLE] = self:createTitleScene()

    -- Create episode select scene
    self.scenes[self.states.EPISODE_SELECT] = self:createEpisodeSelectScene()

    -- Create episode title scene
    self.scenes[self.states.EPISODE_TITLE] = self:createEpisodeTitleScene()

    -- Create story intro scene
    self.scenes[self.states.STORY_INTRO] = self:createStoryIntroScene()

    -- Register gameplay scene
    GameplayScene:init()
    self.scenes[self.states.GAMEPLAY] = GameplayScene

    -- Create game over scene
    self.scenes[self.states.GAME_OVER] = self:createGameOverScene()

    -- Create settings scene
    self.scenes[self.states.SETTINGS] = self:createSettingsScene()

    -- Create debug options scene
    self.scenes[self.states.DEBUG_OPTIONS] = self:createDebugOptionsScene()

    -- Create research menu scene
    self.scenes[self.states.RESEARCH_MENU] = self:createResearchMenuScene()

    -- Create research specs scene
    self.scenes[self.states.RESEARCH_SPECS] = self:createResearchSpecsScene()

    -- Create grant funding scene
    self.scenes[self.states.GRANT_FUNDING] = self:createGrantFundingScene()

    -- Create database scene
    self.scenes[self.states.DATABASE] = self:createDatabaseScene()

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

    -- Apply RP bonus from grant funding
    local grantRPBonus = 0
    if SaveManager and GrantFundingData then
        local researchLevel = SaveManager:getGrantFundingLevel("research")
        if researchLevel > 0 then
            grantRPBonus = GrantFundingData.getTotalBonus("research", researchLevel)
        end
    end

    local adjustedAmount = math.floor(amount * (1 + rpBonus + grantRPBonus))
    self.currentRP = self.currentRP + adjustedAmount

    -- Track for episode stats
    if GameplayScene then
        GameplayScene:trackRP(adjustedAmount)
    end

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

        -- Convert 1% of total RP earned to Grant Funds
        if GameplayScene then
            local stats = GameplayScene:getStats()
            local totalRP = stats and stats.totalRP or 0
            local grantFundsEarned = math.floor(totalRP / 100)
            if grantFundsEarned > 0 then
                SaveManager:addGrantFunds(grantFundsEarned)
                print("Converted " .. totalRP .. " RP to " .. grantFundsEarned .. " Grant Funds")
            end
        end

        SaveManager:flush()
        self:setState(self.states.GAME_OVER)
    end
end

-- Create title scene with background, rotating taglines, and main menu
function GameManager:createTitleScene()
    local titleScene = {}

    local bgImage = nil
    local blinkTimer = 0
    local showText = true
    local taglineTimer = 0
    local currentTagline = ""

    -- Title screen states
    local STATE_SPLASH = 1  -- Showing tagline, waiting for button press
    local STATE_MENU = 2    -- Showing main menu
    local titleState = STATE_SPLASH

    -- Menu items
    local menuItems = { "Episodes", "Research", "Database", "Settings" }
    local selectedIndex = 1

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
        -- Load background image
        bgImage = gfx.image.new("images/ui/title_bg")

        -- Pick initial tagline
        pickNewTagline()
        taglineTimer = 0
        titleState = STATE_SPLASH
        selectedIndex = 1

        -- Play theme music (if not already playing)
        if not AudioManager.currentMusic then
            AudioManager:playMusic("sounds/music_title_theme", true)
        end
    end

    function titleScene:update()
        if titleState == STATE_SPLASH then
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

            -- Check for any button to switch to menu
            if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.b then
                titleState = STATE_MENU
                selectedIndex = 1
            end
        else
            -- Menu state
            -- Navigation
            if InputManager.buttonJustPressed.up then
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then
                    selectedIndex = #menuItems
                end
                if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
            elseif InputManager.buttonJustPressed.down then
                selectedIndex = selectedIndex + 1
                if selectedIndex > #menuItems then
                    selectedIndex = 1
                end
                if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
            end

            -- Selection
            if InputManager.buttonJustPressed.a then
                if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end

                local selected = menuItems[selectedIndex]
                if selected == "Episodes" then
                    GameManager:setState(GameManager.states.EPISODE_SELECT)
                elseif selected == "Research" then
                    GameManager:setState(GameManager.states.RESEARCH_MENU, { fromState = GameManager.states.TITLE })
                elseif selected == "Database" then
                    GameManager:setState(GameManager.states.DATABASE, { fromState = GameManager.states.TITLE })
                elseif selected == "Settings" then
                    GameManager:setState(GameManager.states.SETTINGS, { fromState = GameManager.states.TITLE })
                end
            end

            -- B button goes back to splash
            if InputManager.buttonJustPressed.b then
                titleState = STATE_SPLASH
            end
        end
    end

    function titleScene:drawOverlay()
        -- Draw background image (full screen)
        if bgImage then
            bgImage:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        if titleState == STATE_SPLASH then
            -- Draw tagline in a 145x90 box positioned to bottom-right of rocket
            local boxX = 250
            local boxY = 125
            local boxWidth = 145
            local boxHeight = 90

            -- Format tagline with bold markers
            local taglineText = "*" .. currentTagline .. "*"
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            gfx.drawTextInRect(taglineText, boxX, boxY, boxWidth, boxHeight, nil, nil, kTextAlignment.left)

            -- Draw blinking prompt at bottom
            if showText then
                gfx.drawTextAligned("*Press Any Button to Start*", Constants.SCREEN_WIDTH / 2, 210, kTextAlignment.center)
            end
        else
            -- Draw main menu in the tagline area
            local menuX = 250
            local menuY = 125
            local menuWidth = 145
            local itemHeight = 22

            for i, item in ipairs(menuItems) do
                local y = menuY + (i - 1) * itemHeight
                local isSelected = (i == selectedIndex)

                if isSelected then
                    -- Draw selection background
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillRoundRect(menuX - 4, y - 2, menuWidth, itemHeight - 2, 3)
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                gfx.drawText("*" .. item .. "*", menuX, y)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end

            -- Draw navigation hint at bottom
            gfx.drawTextAligned("D-pad + A to select", Constants.SCREEN_WIDTH / 2, 210, kTextAlignment.center)
        end

        -- Draw version number in lower left corner
        local versionText = "v" .. Constants.VERSION
        gfx.drawText(versionText, 4, Constants.SCREEN_HEIGHT - 14)
    end

    function titleScene:exit()
        -- Don't stop music when leaving title - it will keep playing
        -- Music stops when entering gameplay
    end

    return titleScene
end

-- Create episode select scene
function GameManager:createEpisodeSelectScene()
    local scene = {}

    function scene:enter(params)
        -- Resume/start title music if not playing (e.g., returning from gameplay)
        if AudioManager and not AudioManager.currentMusic then
            AudioManager:playMusic("sounds/music_title_theme", true)
        end

        -- Show episode select UI
        EpisodeSelect:show(function(episodeId)
            -- Episode selected - start it
            GameManager:startNewEpisode(episodeId)
            GameManager:setState(GameManager.states.EPISODE_TITLE)
        end)
    end

    function scene:update()
        EpisodeSelect:update()
    end

    function scene:drawOverlay()
        EpisodeSelect:draw()
    end

    function scene:exit()
        EpisodeSelect:hide()
    end

    return scene
end

-- Create game over scene (matches episode complete style with stats)
function GameManager:createGameOverScene()
    local scene = {}
    local scrollOffset = 0
    local maxScroll = 0
    local stats = nil
    local patternBg = nil
    local grantFundsEarned = 0
    local toolIcons = {}  -- Cache for tool icons
    local itemIcons = {}  -- Cache for bonus item icons

    function scene:enter(params)
        print("Entering game over scene")
        scrollOffset = 0
        toolIcons = {}
        itemIcons = {}

        -- Get episode stats from gameplay scene
        if GameplayScene then
            stats = GameplayScene:getStats()
        else
            stats = { mobKills = {}, toolsObtained = {}, itemsObtained = {}, totalRP = 0, elapsedTime = 0, playerLevel = 1 }
        end

        -- Calculate grant funds earned (1% of total RP)
        grantFundsEarned = math.floor((stats.totalRP or 0) / 100)

        -- Load pattern background
        patternBg = gfx.image.new("images/ui/menu_pattern_bg")

        -- Pre-load tool icons (use pre-processed icons on black background)
        for toolId, _ in pairs(stats.toolsObtained or {}) do
            local toolData = ToolsData and ToolsData[toolId]
            if toolData and toolData.iconPath then
                local filename = toolData.iconPath:match("([^/]+)$")
                toolIcons[toolId] = gfx.image.new("images/icons_on_black/" .. filename)
            end
        end

        -- Pre-load bonus item icons (use pre-processed icons on black background)
        for itemId, _ in pairs(stats.itemsObtained or {}) do
            local itemData = BonusItemsData and BonusItemsData[itemId]
            if itemData and itemData.iconPath then
                local filename = itemData.iconPath:match("([^/]+)$")
                itemIcons[itemId] = gfx.image.new("images/icons_on_black/" .. filename)
            end
        end
    end

    function scene:update()
        -- Scroll with d-pad
        if InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
            scrollOffset = math.min(scrollOffset + 40, maxScroll)
        elseif InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
            scrollOffset = math.max(scrollOffset - 40, 0)
        end

        -- Crank scrolling
        local crankChange = playdate.getCrankChange()
        if math.abs(crankChange) > 2 then
            scrollOffset = scrollOffset + crankChange * 0.5
            scrollOffset = math.max(0, math.min(scrollOffset, maxScroll))
        end

        -- Check for button press to return to episode select
        if InputManager.buttonJustPressed.a then
            GameManager:setState(GameManager.states.EPISODE_SELECT)
        end
    end

    function scene:drawOverlay()
        -- Draw background
        if patternBg then
            patternBg:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        -- Get episode data
        local episodeData = EpisodesData.get(GameManager.currentEpisodeId)

        -- Box styling constants (matching Grant Funds box)
        local boxMargin = 10
        local boxPadding = 8
        local lineHeight = 20
        local headerHeight = 20
        local boxSpacing = 8
        local iconSize = 14  -- Size for list item icons
        local textIndent = iconSize + 4  -- Text starts after icon + spacing

        -- Header: "Episode X: Title" and GAME OVER
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 48)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, 48, Constants.SCREEN_WIDTH, 48)

        if episodeData then
            local episodeHeader = "Episode " .. GameManager.currentEpisodeId .. ": " .. episodeData.title
            gfx.drawTextAligned("*" .. episodeHeader .. "*", Constants.SCREEN_WIDTH / 2, 8, kTextAlignment.center)
        end
        gfx.drawTextAligned("*GAME OVER*", Constants.SCREEN_WIDTH / 2, 26, kTextAlignment.center)

        -- Scrollable content area
        gfx.setClipRect(0, 50, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 72)

        local contentY = 55 - scrollOffset
        local boxWidth = Constants.SCREEN_WIDTH - (boxMargin * 2)

        -- Stats box: Level, RP, Time
        local timeStr = string.format("%d:%02d", math.floor((stats.elapsedTime or 0) / 60), math.floor((stats.elapsedTime or 0) % 60))
        local statsBoxHeight = headerHeight + boxPadding
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(boxMargin, contentY, boxWidth, statsBoxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(boxMargin, contentY, boxWidth, statsBoxHeight)
        gfx.drawText("*Level: " .. (stats.playerLevel or GameManager.playerLevel) .. "*", boxMargin + boxPadding, contentY + boxPadding)
        gfx.drawTextAligned("*RP: " .. (stats.totalRP or 0) .. "*", Constants.SCREEN_WIDTH / 2, contentY + boxPadding, kTextAlignment.center)
        gfx.drawTextAligned("*Time: " .. timeStr .. "*", Constants.SCREEN_WIDTH - boxMargin - boxPadding, contentY + boxPadding, kTextAlignment.right)
        contentY = contentY + statsBoxHeight + boxSpacing

        -- Research Subjects box (mob kills)
        local mobCount = 0
        for mobType, count in pairs(stats.mobKills or {}) do
            mobCount = mobCount + 1
        end

        local mobBoxHeight = headerHeight + boxPadding + (mobCount > 0 and (mobCount * lineHeight) or lineHeight)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(boxMargin, contentY, boxWidth, mobBoxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(boxMargin, contentY, boxWidth, mobBoxHeight)

        -- Header inside box
        gfx.drawText("*Research Subjects*", boxMargin + boxPadding, contentY + 4)
        gfx.drawLine(boxMargin + boxPadding, contentY + headerHeight, Constants.SCREEN_WIDTH - boxMargin - boxPadding, contentY + headerHeight)

        local itemY = contentY + headerHeight + 4
        if mobCount > 0 then
            for mobType, count in pairs(stats.mobKills or {}) do
                local displayName = mobType:gsub("_", " "):gsub("(%a)([%w_']*)", function(a, b) return string.upper(a) .. b end)
                -- Draw bullet dot
                local bulletRadius = 4
                local bulletX = boxMargin + boxPadding + bulletRadius
                local bulletY = itemY + 8  -- Center vertically in line
                gfx.setColor(gfx.kColorBlack)
                gfx.fillCircleAtPoint(bulletX, bulletY, bulletRadius)
                -- Draw text after bullet
                gfx.drawText(displayName .. ": " .. count, boxMargin + boxPadding + textIndent, itemY)
                itemY = itemY + lineHeight
            end
        else
            gfx.drawText("None", boxMargin + boxPadding + textIndent, itemY)
        end
        contentY = contentY + mobBoxHeight + boxSpacing

        -- Tools Obtained box
        local toolCount = 0
        for _ in pairs(stats.toolsObtained or {}) do toolCount = toolCount + 1 end

        local toolBoxHeight = headerHeight + boxPadding + (toolCount > 0 and (toolCount * lineHeight) or lineHeight)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(boxMargin, contentY, boxWidth, toolBoxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(boxMargin, contentY, boxWidth, toolBoxHeight)

        -- Header inside box
        gfx.drawText("*Tools Obtained*", boxMargin + boxPadding, contentY + 4)
        gfx.drawLine(boxMargin + boxPadding, contentY + headerHeight, Constants.SCREEN_WIDTH - boxMargin - boxPadding, contentY + headerHeight)

        itemY = contentY + headerHeight + 4
        if toolCount > 0 then
            for toolId, _ in pairs(stats.toolsObtained or {}) do
                local toolData = ToolsData and ToolsData[toolId]
                local toolName = toolData and toolData.name or toolId
                -- Draw tool icon with black background box
                local icon = toolIcons[toolId]
                if icon then
                    local iconBoxX = boxMargin + boxPadding
                    local iconBoxY = itemY
                    local iconBoxSize = iconSize + 2

                    -- Pre-processed icons are already white on black, just draw them
                    local iconW, iconH = icon:getSize()
                    local scale = iconSize / math.max(iconW, iconH)
                    icon:drawScaled(iconBoxX + 1, iconBoxY + 1, scale)
                else
                    -- Fallback bullet
                    local bulletRadius = 4
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillCircleAtPoint(boxMargin + boxPadding + bulletRadius, itemY + 8, bulletRadius)
                end
                gfx.drawText(toolName, boxMargin + boxPadding + textIndent, itemY)
                itemY = itemY + lineHeight
            end
        else
            gfx.drawText("None", boxMargin + boxPadding + textIndent, itemY)
        end
        contentY = contentY + toolBoxHeight + boxSpacing

        -- Bonus Items Obtained box
        local itemCount = 0
        for _ in pairs(stats.itemsObtained or {}) do itemCount = itemCount + 1 end

        local itemsBoxHeight = headerHeight + boxPadding + (itemCount > 0 and (itemCount * lineHeight) or lineHeight)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(boxMargin, contentY, boxWidth, itemsBoxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(boxMargin, contentY, boxWidth, itemsBoxHeight)

        -- Header inside box
        gfx.drawText("*Bonus Items Obtained*", boxMargin + boxPadding, contentY + 4)
        gfx.drawLine(boxMargin + boxPadding, contentY + headerHeight, Constants.SCREEN_WIDTH - boxMargin - boxPadding, contentY + headerHeight)

        itemY = contentY + headerHeight + 4
        if itemCount > 0 then
            for itemId, _ in pairs(stats.itemsObtained or {}) do
                local itemData = BonusItemsData and BonusItemsData[itemId]
                local itemName = itemData and itemData.name or itemId
                -- Draw bonus item icon with black background box
                local icon = itemIcons[itemId]
                if icon then
                    local iconBoxX = boxMargin + boxPadding
                    local iconBoxY = itemY
                    local iconBoxSize = iconSize + 2

                    -- Pre-processed icons are already white on black, just draw them
                    local iconW, iconH = icon:getSize()
                    local scale = iconSize / math.max(iconW, iconH)
                    icon:drawScaled(iconBoxX + 1, iconBoxY + 1, scale)
                else
                    -- Fallback bullet
                    local bulletRadius = 4
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillCircleAtPoint(boxMargin + boxPadding + bulletRadius, itemY + 8, bulletRadius)
                end
                gfx.drawText(itemName, boxMargin + boxPadding + textIndent, itemY)
                itemY = itemY + lineHeight
            end
        else
            gfx.drawText("None", boxMargin + boxPadding + textIndent, itemY)
        end
        contentY = contentY + itemsBoxHeight + boxSpacing

        -- Grant Funds Earned box (displayed if any)
        if grantFundsEarned > 0 then
            local grantBoxHeight = headerHeight + boxPadding
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(boxMargin, contentY, boxWidth, grantBoxHeight)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(boxMargin, contentY, boxWidth, grantBoxHeight)
            gfx.drawTextAligned("*+" .. grantFundsEarned .. " Grant Funds earned*", Constants.SCREEN_WIDTH / 2, contentY + boxPadding, kTextAlignment.center)
            contentY = contentY + grantBoxHeight + boxSpacing
        end

        -- Calculate max scroll
        maxScroll = math.max(0, contentY + scrollOffset - Constants.SCREEN_HEIGHT + 80)

        gfx.clearClipRect()

        -- Footer
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
        gfx.drawTextAligned("*Press [A]   D-pad/Crank to scroll*", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
    end

    function scene:exit()
        print("Exiting game over scene")
        stats = nil
        patternBg = nil
    end

    return scene
end

-- Create episode title scene (shows before intro panels)
function GameManager:createEpisodeTitleScene()
    local scene = {}
    local bgImage = nil
    local elapsedTime = 0
    local fadeAlpha = 0
    local inputDelayTime = 1.0      -- 1 second before input accepted
    local autoAdvanceTime = 3.0     -- Auto-advance after 3 seconds
    local fadeDuration = 0.5        -- 0.5 second fade
    local isFading = false
    local fadeComplete = false

    -- Text wrapping helper
    local function wrapText(text, maxWidth, font)
        local words = {}
        for word in text:gmatch("%S+") do
            table.insert(words, word)
        end

        local lines = {}
        local currentLine = ""

        for _, word in ipairs(words) do
            local testLine = currentLine == "" and word or (currentLine .. " " .. word)
            local testWidth = font:getTextWidth(testLine)

            if testWidth <= maxWidth then
                currentLine = testLine
            else
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                end
                currentLine = word
            end
        end

        if currentLine ~= "" then
            table.insert(lines, currentLine)
        end

        return lines
    end

    function scene:enter(params)
        print("Entering episode title scene")
        elapsedTime = 0
        fadeAlpha = 0
        isFading = false
        fadeComplete = false

        -- Load background image
        bgImage = gfx.image.new("images/ui/episode_title_bg")

        -- Stop title theme music when starting an episode
        if AudioManager then
            AudioManager:stopMusic()
        end
    end

    function scene:update()
        local dt = 1/30  -- Approximate frame time

        elapsedTime = elapsedTime + dt

        -- Check for input after delay
        if elapsedTime >= inputDelayTime and not isFading then
            if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.b then
                if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
                isFading = true
            end
        end

        -- Auto-advance after 3 seconds
        if elapsedTime >= autoAdvanceTime and not isFading then
            isFading = true
        end

        -- Handle fade
        if isFading then
            fadeAlpha = fadeAlpha + (dt / fadeDuration)
            if fadeAlpha >= 1.0 then
                fadeAlpha = 1.0
                fadeComplete = true
            end
        end

        -- Transition when fade complete
        if fadeComplete then
            GameManager:setState(GameManager.states.STORY_INTRO)
        end
    end

    function scene:drawOverlay()
        -- Draw background
        if bgImage then
            bgImage:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        -- Get episode data
        local episodeData = EpisodesData.get(GameManager.currentEpisodeId)
        if not episodeData then return end

        -- Get fonts (use bold for both title and tagline)
        local boldFont = gfx.getSystemFont(gfx.font.kVariantBold)

        -- Build episode title text: "EP X: Title"
        local titleText = "EP " .. GameManager.currentEpisodeId .. ": " .. string.upper(episodeData.title)
        local taglineText = episodeData.tagline or ""

        -- Text positioning - below the logo (roughly bottom third of screen)
        local textStartY = 145
        local maxTextWidth = Constants.SCREEN_WIDTH - 40  -- 20px padding each side
        local centerX = Constants.SCREEN_WIDTH / 2

        -- Draw title with thick outline for legibility
        gfx.setFont(boldFont)

        -- Check if title needs wrapping (unlikely but safety check)
        local titleWidth = boldFont:getTextWidth(titleText)
        local titleLines = { titleText }
        if titleWidth > maxTextWidth then
            titleLines = wrapText(titleText, maxTextWidth, boldFont)
        end

        local titleY = textStartY
        local lineHeight = boldFont:getHeight() + 6

        for _, line in ipairs(titleLines) do
            -- Draw thick outline (3px radius for bolder look)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            for dx = -3, 3 do
                for dy = -3, 3 do
                    if dx ~= 0 or dy ~= 0 then
                        gfx.drawTextAligned("*" .. line .. "*", centerX + dx, titleY + dy, kTextAlignment.center)
                    end
                end
            end

            -- Draw main text
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            gfx.drawTextAligned("*" .. line .. "*", centerX, titleY, kTextAlignment.center)

            titleY = titleY + lineHeight
        end

        -- Draw tagline with bold font and outline
        local taglineY = titleY + 10

        -- Wrap tagline if needed (use bold font for measurement)
        local taglineWidth = boldFont:getTextWidth(taglineText)
        local taglineLines = { taglineText }
        if taglineWidth > maxTextWidth then
            taglineLines = wrapText(taglineText, maxTextWidth, boldFont)
        end

        local taglineLineHeight = boldFont:getHeight() + 4

        for _, line in ipairs(taglineLines) do
            -- Draw outline (2px radius for tagline)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            for dx = -2, 2 do
                for dy = -2, 2 do
                    if dx ~= 0 or dy ~= 0 then
                        gfx.drawTextAligned("*" .. line .. "*", centerX + dx, taglineY + dy, kTextAlignment.center)
                    end
                end
            end

            -- Draw main text (bold)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            gfx.drawTextAligned("*" .. line .. "*", centerX, taglineY, kTextAlignment.center)

            taglineY = taglineY + taglineLineHeight
        end

        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        -- Draw "Press A" right-aligned, 5px from right and top edges (after input delay)
        if elapsedTime >= inputDelayTime and not isFading then
            local radius = 8
            local iconX = Constants.SCREEN_WIDTH - 5 - radius  -- 5px from right edge
            local iconY = 5 + radius  -- 5px from top edge

            -- Draw "Press" text before icon
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            local smallFont = gfx.getSystemFont()
            gfx.setFont(smallFont)
            local pressWidth = smallFont:getTextWidth("Press ")
            gfx.drawText("Press ", iconX - pressWidth - 2, iconY - smallFont:getHeight()/2)

            -- Draw white filled circle
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(iconX, iconY, radius)
            -- Draw black outline
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(iconX, iconY, radius)
            -- Draw black "A" centered in circle
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            local iconFont = gfx.getSystemFont(gfx.font.kVariantBold)
            gfx.setFont(iconFont)
            local textW = iconFont:getTextWidth("A")
            local textH = iconFont:getHeight()
            gfx.drawText("A", iconX - textW/2, iconY - textH/2)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        -- Draw fade overlay
        if isFading then
            local alpha = math.floor(fadeAlpha * 16)  -- 0-16 dither levels
            if alpha > 0 then
                local pattern = gfx.image.new(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
                gfx.pushContext(pattern)
                gfx.setColor(gfx.kColorBlack)
                gfx.setDitherPattern(1 - fadeAlpha, gfx.image.kDitherTypeBayer8x8)
                gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
                gfx.popContext()
                pattern:draw(0, 0)
            end
        end
    end

    function scene:exit()
        print("Exiting episode title scene")
        bgImage = nil
    end

    return scene
end

-- Create story intro scene
function GameManager:createStoryIntroScene()
    local scene = {}
    local showingToolSelect = false

    -- Helper to transition to gameplay (potentially after tool select)
    local function goToGameplay()
        -- Check if player can select starting tool (Tool Mastery research spec)
        if ResearchSpecSystem and ResearchSpecSystem:canSelectStartingTool() then
            showingToolSelect = true
            ToolSelect:show(function(selectedToolId)
                GameManager.selectedStartingTool = selectedToolId
                showingToolSelect = false
                GameManager:setState(GameManager.states.GAMEPLAY)
            end)
        else
            -- No tool selection, use default
            GameManager.selectedStartingTool = nil
            GameManager:setState(GameManager.states.GAMEPLAY)
        end
    end

    function scene:enter(params)
        print("Entering story intro scene")
        showingToolSelect = false

        -- Stop title theme music when starting an episode
        if AudioManager then
            AudioManager:stopMusic()
        end

        -- Get episode data
        local episodeData = EpisodesData.get(GameManager.currentEpisodeId)

        if episodeData and episodeData.introPanels and #episodeData.introPanels > 0 then
            -- Show intro panels
            StoryPanel:show(episodeData.introPanels, function()
                -- When done, check for tool selection
                goToGameplay()
            end)
        else
            -- No intro panels, check for tool selection
            goToGameplay()
        end
    end

    function scene:update()
        if showingToolSelect then
            ToolSelect:update()
        else
            StoryPanel:update()
        end
    end

    function scene:drawOverlay()
        if showingToolSelect then
            ToolSelect:draw()
        else
            StoryPanel:draw()
        end
    end

    function scene:exit()
        print("Exiting story intro scene")
        showingToolSelect = false
    end

    return scene
end

-- Create victory scene (shows ending panels then detailed stats)
function GameManager:createVictoryScene()
    local scene = {}
    local showingPanels = false
    local victoryShown = false
    local scrollOffset = 0
    local maxScroll = 0
    local stats = nil
    local patternBg = nil
    local toolIcons = {}  -- Cache for tool icons
    local itemIcons = {}  -- Cache for bonus item icons

    function scene:enter(params)
        print("Entering victory scene")
        showingPanels = false
        victoryShown = false
        scrollOffset = 0
        toolIcons = {}
        itemIcons = {}

        -- Get episode stats from gameplay scene
        if GameplayScene then
            stats = GameplayScene:getStats()
        else
            stats = { mobKills = {}, toolsObtained = {}, itemsObtained = {}, totalRP = 0, elapsedTime = 0, playerLevel = 1 }
        end

        -- Load pattern background
        patternBg = gfx.image.new("images/ui/menu_pattern_bg")

        -- Pre-load tool icons (use pre-processed icons on black background)
        for toolId, _ in pairs(stats.toolsObtained or {}) do
            local toolData = ToolsData and ToolsData[toolId]
            if toolData and toolData.iconPath then
                local filename = toolData.iconPath:match("([^/]+)$")
                toolIcons[toolId] = gfx.image.new("images/icons_on_black/" .. filename)
            end
        end

        -- Pre-load bonus item icons (use pre-processed icons on black background)
        for itemId, _ in pairs(stats.itemsObtained or {}) do
            local itemData = BonusItemsData and BonusItemsData[itemId]
            if itemData and itemData.iconPath then
                local filename = itemData.iconPath:match("([^/]+)$")
                itemIcons[itemId] = gfx.image.new("images/icons_on_black/" .. filename)
            end
        end

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
            -- Scroll with d-pad
            if InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
                scrollOffset = math.min(scrollOffset + 40, maxScroll)
            elseif InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
                scrollOffset = math.max(scrollOffset - 40, 0)
            end

            -- Crank scrolling
            local crankChange = playdate.getCrankChange()
            if math.abs(crankChange) > 2 then
                scrollOffset = scrollOffset + crankChange * 0.5
                scrollOffset = math.max(0, math.min(scrollOffset, maxScroll))
            end

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
            -- Draw background
            if patternBg then
                patternBg:draw(0, 0)
            else
                gfx.clear(gfx.kColorWhite)
            end

            -- Get episode and research spec data
            local episodeData = EpisodesData.get(GameManager.currentEpisodeId)
            local specData = nil
            if episodeData and episodeData.researchSpecUnlock then
                specData = ResearchSpecsData and ResearchSpecsData.get(episodeData.researchSpecUnlock)
            end

            -- Calculate content height for scrolling
            local contentY = 10 - scrollOffset
            local startY = contentY

            -- Header: Episode Title
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 48)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawLine(0, 48, Constants.SCREEN_WIDTH, 48)

            if episodeData then
                gfx.drawTextAligned("*" .. episodeData.title .. "*", Constants.SCREEN_WIDTH / 2, 8, kTextAlignment.center)
            end
            gfx.drawTextAligned("*EPISODE COMPLETE!*", Constants.SCREEN_WIDTH / 2, 26, kTextAlignment.center)

            -- Scrollable content area
            gfx.setClipRect(0, 50, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 72)

            contentY = 55 - scrollOffset

            -- Research Spec Unlocked
            if specData then
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(10, contentY, Constants.SCREEN_WIDTH - 20, 38)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRect(10, contentY, Constants.SCREEN_WIDTH - 20, 38)
                gfx.drawText("*Research Spec Unlocked:*", 18, contentY + 4)
                gfx.drawText("*" .. specData.name .. "* - " .. specData.description, 18, contentY + 20)
                contentY = contentY + 46
            end

            -- Stats row: Level, RP, Time
            local timeStr = string.format("%d:%02d", math.floor((stats.elapsedTime or 0) / 60), math.floor((stats.elapsedTime or 0) % 60))
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(10, contentY, Constants.SCREEN_WIDTH - 20, 22)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(10, contentY, Constants.SCREEN_WIDTH - 20, 22)
            gfx.drawText("*Level: " .. (stats.playerLevel or GameManager.playerLevel) .. "*", 18, contentY + 4)
            gfx.drawTextAligned("*RP: " .. (stats.totalRP or 0) .. "*", Constants.SCREEN_WIDTH / 2, contentY + 4, kTextAlignment.center)
            gfx.drawTextAligned("*Time: " .. timeStr .. "*", Constants.SCREEN_WIDTH - 18, contentY + 4, kTextAlignment.right)
            contentY = contentY + 30

            -- Layout constants for lists
            local lineHeight = 20
            local iconSize = 14
            local textIndent = iconSize + 4
            local boxPadding = 6
            local boxMargin = 10

            -- Calculate Grant Funds earned
            local grantFundsEarned = math.floor((stats.totalRP or 0) / 100)

            -- Grant Funds Earned (new section)
            if grantFundsEarned > 0 then
                local grantBoxHeight = 22
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, grantBoxHeight)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, grantBoxHeight)
                gfx.drawTextAligned("*+" .. grantFundsEarned .. " Grant Funds earned*", Constants.SCREEN_WIDTH / 2, contentY + boxPadding, kTextAlignment.center)
                contentY = contentY + grantBoxHeight + 8
            end

            -- Research Subjects (mob kills)
            local mobCount = 0
            for mobType, count in pairs(stats.mobKills or {}) do
                mobCount = mobCount + 1
            end

            local mobBoxHeight = boxPadding + 16 + (mobCount > 0 and mobCount * lineHeight or lineHeight) + boxPadding
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, mobBoxHeight)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, mobBoxHeight)
            gfx.drawText("*Research Subjects:*", boxMargin + boxPadding, contentY + boxPadding)

            if mobCount > 0 then
                local mobY = contentY + boxPadding + 16
                for mobType, count in pairs(stats.mobKills or {}) do
                    -- Get display name
                    local displayName = mobType:gsub("_", " "):gsub("(%a)([%w_']*)", function(a, b) return string.upper(a) .. b end)
                    -- Draw bullet dot
                    local bulletRadius = 4
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillCircleAtPoint(boxMargin + boxPadding + bulletRadius, mobY + 8, bulletRadius)
                    gfx.drawText(displayName .. ": " .. count, boxMargin + boxPadding + textIndent, mobY)
                    mobY = mobY + lineHeight
                end
            else
                gfx.drawText("None", boxMargin + boxPadding + textIndent, contentY + boxPadding + 16)
            end
            contentY = contentY + mobBoxHeight + 8

            -- Tools Obtained
            local toolCount = 0
            for _ in pairs(stats.toolsObtained or {}) do toolCount = toolCount + 1 end

            local toolBoxHeight = boxPadding + 16 + (toolCount > 0 and toolCount * lineHeight or lineHeight) + boxPadding
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, toolBoxHeight)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, toolBoxHeight)
            gfx.drawText("*Tools Obtained:*", boxMargin + boxPadding, contentY + boxPadding)

            if toolCount > 0 then
                local toolY = contentY + boxPadding + 16
                for toolId, _ in pairs(stats.toolsObtained or {}) do
                    local toolData = ToolsData and ToolsData[toolId]
                    local toolName = toolData and toolData.name or toolId
                    -- Draw tool icon with black background box
                    local icon = toolIcons[toolId]
                    if icon then
                        local iconBoxX = boxMargin + boxPadding
                        local iconBoxY = toolY

                        -- Pre-processed icons are already white on black, just draw them
                        local iconW, iconH = icon:getSize()
                        local scale = iconSize / math.max(iconW, iconH)
                        icon:drawScaled(iconBoxX + 1, iconBoxY + 1, scale)
                    else
                        -- Fallback bullet
                        local bulletRadius = 4
                        gfx.setColor(gfx.kColorBlack)
                        gfx.fillCircleAtPoint(boxMargin + boxPadding + bulletRadius, toolY + 8, bulletRadius)
                    end
                    gfx.drawText(toolName, boxMargin + boxPadding + textIndent, toolY)
                    toolY = toolY + lineHeight
                end
            else
                gfx.drawText("None", boxMargin + boxPadding + textIndent, contentY + boxPadding + 16)
            end
            contentY = contentY + toolBoxHeight + 8

            -- Bonus Items Obtained
            local itemCount = 0
            for _ in pairs(stats.itemsObtained or {}) do itemCount = itemCount + 1 end

            local itemBoxHeight = boxPadding + 16 + (itemCount > 0 and itemCount * lineHeight or lineHeight) + boxPadding
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, itemBoxHeight)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(boxMargin, contentY, Constants.SCREEN_WIDTH - boxMargin * 2, itemBoxHeight)
            gfx.drawText("*Bonus Items Obtained:*", boxMargin + boxPadding, contentY + boxPadding)

            if itemCount > 0 then
                local itemY = contentY + boxPadding + 16
                for itemId, _ in pairs(stats.itemsObtained or {}) do
                    local itemData = BonusItemsData and BonusItemsData[itemId]
                    local itemName = itemData and itemData.name or itemId
                    -- Draw bonus item icon with black background box
                    local icon = itemIcons[itemId]
                    if icon then
                        local iconBoxX = boxMargin + boxPadding
                        local iconBoxY = itemY

                        -- Pre-processed icons are already white on black, just draw them
                        local iconW, iconH = icon:getSize()
                        local scale = iconSize / math.max(iconW, iconH)
                        icon:drawScaled(iconBoxX + 1, iconBoxY + 1, scale)
                    else
                        -- Fallback bullet
                        local bulletRadius = 4
                        gfx.setColor(gfx.kColorBlack)
                        gfx.fillCircleAtPoint(boxMargin + boxPadding + bulletRadius, itemY + 8, bulletRadius)
                    end
                    gfx.drawText(itemName, boxMargin + boxPadding + textIndent, itemY)
                    itemY = itemY + lineHeight
                end
            else
                gfx.drawText("None", boxMargin + boxPadding + textIndent, contentY + boxPadding + 16)
            end
            contentY = contentY + itemBoxHeight + 8

            -- Calculate max scroll
            maxScroll = math.max(0, contentY + scrollOffset - Constants.SCREEN_HEIGHT + 80)

            gfx.clearClipRect()

            -- Footer
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
            gfx.drawTextAligned("*[A] Continue   D-pad/Crank to scroll*", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
        end
    end

    function scene:exit()
        print("Exiting victory scene")
        showingPanels = false
        victoryShown = false
        stats = nil
        patternBg = nil
    end

    return scene
end

-- Create settings scene
function GameManager:createSettingsScene()
    local scene = {}

    local menuItems = {
        { label = "Music Volume", type = "slider", key = "musicVolume", min = 0, max = 1, step = 0.1 },
        { label = "SFX Volume", type = "slider", key = "sfxVolume", min = 0, max = 1, step = 0.1 },
        { label = "Debug Mode", type = "debug_toggle", key = "debugMode" },  -- Special type with gear icon
        { label = "Reset All Data", type = "action", action = "reset" },
        { label = "Back", type = "action", action = "back" },
    }

    -- Track if user is hovering the gear icon (sub-selection within debug row)
    local debugGearSelected = false

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
            debugGearSelected = false  -- Reset gear selection when changing rows
        elseif InputManager.buttonJustPressed.down then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #menuItems then
                selectedIndex = 1
            end
            debugGearSelected = false  -- Reset gear selection when changing rows
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
        elseif item.type == "debug_toggle" then
            -- Special handling for debug mode with gear icon
            if InputManager.buttonJustPressed.left then
                -- Move to toggle (if on gear)
                if debugGearSelected then
                    debugGearSelected = false
                else
                    -- Toggle debug mode off when pressing left
                    local currentValue = SaveManager:getSetting(item.key, false)
                    if currentValue then
                        SaveManager:setSetting(item.key, false)
                        SaveManager:flush()
                        if EpisodeSelect then EpisodeSelect:refreshEpisodes() end
                    end
                end
            elseif InputManager.buttonJustPressed.right then
                -- Move to gear (if on toggle) or toggle on
                if not debugGearSelected then
                    local currentValue = SaveManager:getSetting(item.key, false)
                    if currentValue then
                        -- Already on, move to gear
                        debugGearSelected = true
                    else
                        -- Turn on debug mode
                        SaveManager:setSetting(item.key, true)
                        SaveManager:flush()
                        if EpisodeSelect then EpisodeSelect:refreshEpisodes() end
                    end
                end
            elseif InputManager.buttonJustPressed.a then
                if debugGearSelected then
                    -- Open debug options
                    GameManager:setState(GameManager.states.DEBUG_OPTIONS, { fromState = GameManager.states.SETTINGS })
                else
                    -- Toggle debug mode
                    local currentValue = SaveManager:getSetting(item.key, false)
                    SaveManager:setSetting(item.key, not currentValue)
                    SaveManager:flush()
                    if EpisodeSelect then EpisodeSelect:refreshEpisodes() end
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
                    -- White outer stroke for emphasis when selected
                    gfx.setColor(gfx.kColorWhite)
                    gfx.setLineWidth(2)
                    gfx.drawRect(sliderX - 2, sliderY - 2, sliderWidth + 4, 14)
                    gfx.setLineWidth(1)
                    -- White fill for slider track
                    gfx.fillRect(sliderX, sliderY, sliderWidth, 10)
                    -- Black border inside
                    gfx.setColor(gfx.kColorBlack)
                    gfx.drawRect(sliderX, sliderY, sliderWidth, 10)
                    -- Black fill for progress
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

            elseif item.type == "debug_toggle" then
                local value = SaveManager:getSetting(item.key, false)

                -- Text mode for label
                if isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                gfx.drawText(item.label, 30, y)

                -- Draw ON/OFF toggle
                local toggleText = value and "ON" or "OFF"
                local toggleX = 280

                -- Highlight toggle if selected and not on gear
                if isSelected and not debugGearSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                    -- Draw selection box around toggle
                    gfx.setColor(gfx.kColorWhite)
                    gfx.drawRoundRect(toggleX - 4, y - 2, 40, 18, 2)
                elseif isSelected then
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end
                gfx.drawText(toggleText, toggleX, y)

                -- Draw gear icon (only visible when debug is ON)
                if value then
                    local gearX = 340
                    local gearY = y + 2
                    local gearSize = 14

                    -- Draw gear selection highlight if selected
                    if isSelected and debugGearSelected then
                        gfx.setColor(gfx.kColorWhite)
                        gfx.fillCircleAtPoint(gearX + gearSize/2, gearY + gearSize/2, gearSize/2 + 3)
                    end

                    -- Draw gear icon (simple representation)
                    gfx.setColor(isSelected and gfx.kColorWhite or gfx.kColorBlack)
                    local cx = gearX + gearSize/2
                    local cy = gearY + gearSize/2
                    local outerR = gearSize/2
                    local innerR = gearSize/4

                    -- Draw outer circle
                    gfx.drawCircleAtPoint(cx, cy, outerR)
                    -- Draw inner circle (filled)
                    gfx.fillCircleAtPoint(cx, cy, innerR)
                    -- Draw gear teeth (8 lines)
                    for angle = 0, 315, 45 do
                        local rad = math.rad(angle)
                        local x1 = cx + math.cos(rad) * innerR
                        local y1 = cy + math.sin(rad) * innerR
                        local x2 = cx + math.cos(rad) * (outerR + 2)
                        local y2 = cy + math.sin(rad) * (outerR + 2)
                        gfx.drawLine(x1, y1, x2, y2)
                    end
                end

                gfx.setImageDrawMode(gfx.kDrawModeCopy)

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

-- Create research specs scene
function GameManager:createResearchSpecsScene()
    local scene = {}

    function scene:enter(params)
        -- Pass the fromState so we can return to where we came from
        local fromState = params and params.fromState or GameManager.states.EPISODE_SELECT
        ResearchSpecsScreen:show(fromState)
    end

    function scene:update()
        ResearchSpecsScreen:update()
    end

    function scene:drawOverlay()
        ResearchSpecsScreen:draw()
    end

    function scene:exit()
        ResearchSpecsScreen:hide()
    end

    return scene
end

-- Create database scene
function GameManager:createDatabaseScene()
    local scene = {}

    function scene:enter(params)
        local fromState = params and params.fromState or GameManager.states.TITLE
        DatabaseScreen:show(fromState)
    end

    function scene:update()
        DatabaseScreen:update()
    end

    function scene:drawOverlay()
        DatabaseScreen:draw()
    end

    function scene:exit()
        DatabaseScreen:hide()
    end

    return scene
end

-- Create research menu scene (submenu for Research Specs and Grant Funding)
function GameManager:createResearchMenuScene()
    local scene = {}
    local menuItems = { "Research Specs", "Grant Funding", "Back" }
    local selectedIndex = 1
    local patternBg = nil
    local previousState = nil

    function scene:enter(params)
        selectedIndex = 1
        previousState = params and params.fromState or GameManager.states.TITLE
        patternBg = gfx.image.new("images/ui/menu_pattern_bg")
    end

    function scene:update()
        -- Navigation
        if InputManager.buttonJustPressed.up then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = #menuItems end
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        elseif InputManager.buttonJustPressed.down then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #menuItems then selectedIndex = 1 end
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        end

        -- Selection
        if InputManager.buttonJustPressed.a then
            if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
            local selected = menuItems[selectedIndex]
            if selected == "Research Specs" then
                GameManager:setState(GameManager.states.RESEARCH_SPECS, { fromState = GameManager.states.RESEARCH_MENU })
            elseif selected == "Grant Funding" then
                GameManager:setState(GameManager.states.GRANT_FUNDING, { fromState = GameManager.states.RESEARCH_MENU })
            elseif selected == "Back" then
                GameManager:setState(previousState)
            end
        end

        -- B button goes back
        if InputManager.buttonJustPressed.b then
            if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
            GameManager:setState(previousState)
        end
    end

    function scene:drawOverlay()
        -- Draw background
        if patternBg then
            patternBg:draw(0, 0)
        else
            gfx.clear(gfx.kColorWhite)
        end

        -- Title bar
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
        gfx.drawTextAligned("*RESEARCH*", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)

        -- Grant Funds display
        local funds = SaveManager:getGrantFunds()
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(10, 50, Constants.SCREEN_WIDTH - 20, 24)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(10, 50, Constants.SCREEN_WIDTH - 20, 24)
        gfx.drawTextAligned("*Grant Funds: " .. funds .. "*", Constants.SCREEN_WIDTH / 2, 56, kTextAlignment.center)

        -- Menu items
        local startY = 90
        local itemHeight = 36

        for i, item in ipairs(menuItems) do
            local y = startY + (i - 1) * itemHeight
            local isSelected = (i == selectedIndex)

            -- Row background
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(60, y - 4, Constants.SCREEN_WIDTH - 120, 30, 4)

            gfx.setColor(gfx.kColorBlack)
            if isSelected then
                gfx.fillRoundRect(60, y - 4, Constants.SCREEN_WIDTH - 120, 30, 4)
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            else
                gfx.drawRoundRect(60, y - 4, Constants.SCREEN_WIDTH - 120, 30, 4)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end

            gfx.drawTextAligned("*" .. item .. "*", Constants.SCREEN_WIDTH / 2, y + 2, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end

        -- Instructions
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
        gfx.drawTextAligned("*D-pad navigate   A select   B back*", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
    end

    function scene:exit()
        patternBg = nil
    end

    return scene
end

-- Create debug options scene
function GameManager:createDebugOptionsScene()
    local scene = {}

    function scene:enter(params)
        local fromState = params and params.fromState or GameManager.states.SETTINGS
        DebugOptionsScreen:show(fromState)
    end

    function scene:update()
        DebugOptionsScreen:update()
    end

    function scene:drawOverlay()
        DebugOptionsScreen:draw()
    end

    function scene:exit()
        DebugOptionsScreen:hide()
    end

    return scene
end

-- Create grant funding scene
function GameManager:createGrantFundingScene()
    local scene = {}

    function scene:enter(params)
        local fromState = params and params.fromState or GameManager.states.RESEARCH_MENU
        GrantFundingScreen:show(fromState)
    end

    function scene:update()
        GrantFundingScreen:update()
    end

    function scene:drawOverlay()
        GrantFundingScreen:draw()
    end

    function scene:exit()
        GrantFundingScreen:hide()
    end

    return scene
end

return GameManager
