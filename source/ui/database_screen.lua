-- Database Screen UI
-- Encyclopedia of discovered game content
-- Retro terminal aesthetic: black background, white text/borders

local gfx <const> = playdate.graphics

DatabaseScreen = {
    isVisible = false,
    fromState = nil,
    -- Screen states
    STATE_CATEGORIES = 1,
    STATE_LIST = 2,
    STATE_DETAIL = 3,
    currentState = 1,

    -- Category menu
    categories = {
        { id = "gameplay", name = "Gameplay", total = 3 },
        { id = "tools", name = "Tools", total = 14 },
        { id = "bonusItems", name = "Items", total = 30 },
        { id = "enemies", name = "Research Subjects", total = 11 },
        { id = "bosses", name = "Bosses", total = 5 },
        { id = "episodes", name = "Episodes", total = 5 },
    },
    categoryScrollOffset = 0,
    maxVisibleCategories = 5,

    -- Gameplay detail scroll
    gameplayScrollOffset = 0,
    gameplayMaxScroll = 0,
    selectedCategory = 1,

    -- List view
    currentCategoryId = nil,
    entries = {},
    selectedEntry = 1,
    scrollOffset = 0,
    maxVisibleItems = 5,

    -- Detail view
    currentEntry = nil,
    currentSprite = nil,

    -- Input delay
    inputDelay = 0,
}

function DatabaseScreen:init()
end

function DatabaseScreen:show(fromState)
    self.isVisible = true
    self.fromState = fromState or GameManager.states.TITLE
    self.currentState = self.STATE_CATEGORIES
    self.selectedCategory = 1
    self.categoryScrollOffset = 0
    self.selectedEntry = 1
    self.scrollOffset = 0
    self.inputDelay = 0.2

end

function DatabaseScreen:hide()
    self.isVisible = false
    self.currentSprite = nil
    self.entries = {}
end

function DatabaseScreen:update()
    if not self.isVisible then return end

    local dt = 1/30

    -- Handle input delay
    if self.inputDelay > 0 then
        self.inputDelay = self.inputDelay - dt
        return
    end

    if self.currentState == self.STATE_CATEGORIES then
        self:updateCategoryMenu()
    elseif self.currentState == self.STATE_LIST then
        self:updateEntryList()
    elseif self.currentState == self.STATE_DETAIL then
        self:updateDetailView()
    end
end

-- ============================================
-- Category Menu
-- ============================================

function DatabaseScreen:updateCategoryMenu()
    -- Navigation (up/right = up, down/left = down)
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self.selectedCategory = self.selectedCategory - 1
        if self.selectedCategory < 1 then
            self.selectedCategory = #self.categories
            -- Jump to bottom
            self.categoryScrollOffset = math.max(0, #self.categories - self.maxVisibleCategories)
        end
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self.selectedCategory = self.selectedCategory + 1
        if self.selectedCategory > #self.categories then
            self.selectedCategory = 1
            self.categoryScrollOffset = 0
        end
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    end

    -- Adjust scroll to keep selection visible
    if self.selectedCategory < self.categoryScrollOffset + 1 then
        self.categoryScrollOffset = self.selectedCategory - 1
    elseif self.selectedCategory > self.categoryScrollOffset + self.maxVisibleCategories then
        self.categoryScrollOffset = self.selectedCategory - self.maxVisibleCategories
    end

    -- Select category
    if InputManager.buttonJustPressed.a then
        if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
        self:openCategory(self.categories[self.selectedCategory].id)
    end

    -- Back
    if InputManager.buttonJustPressed.b then
        self:hide()
        GameManager:setState(self.fromState)
    end
end

function DatabaseScreen:openCategory(categoryId)
    self.currentCategoryId = categoryId
    self.selectedEntry = 1
    self.scrollOffset = 0
    self.currentState = self.STATE_LIST
    self.inputDelay = 0.1

    -- Load entries for this category
    self:loadEntriesForCategory(categoryId)
end

function DatabaseScreen:loadEntriesForCategory(categoryId)
    self.entries = {}

    if categoryId == "gameplay" then
        self:loadGameplayEntries()
    elseif categoryId == "tools" then
        self:loadToolEntries()
    elseif categoryId == "bonusItems" then
        self:loadBonusItemEntries()
    elseif categoryId == "enemies" then
        self:loadEnemyEntries()
    elseif categoryId == "bosses" then
        self:loadBossEntries()
    elseif categoryId == "episodes" then
        self:loadEpisodeEntries()
    end
end

function DatabaseScreen:loadGameplayEntries()
    -- Gameplay guide entries - always unlocked
    local gameplayDefs = {
        { id = "controls", name = "Controls", unlocked = true },
        { id = "settings", name = "Settings", unlocked = true },
        { id = "station_systems", name = "Station Systems", unlocked = true },
    }

    for _, def in ipairs(gameplayDefs) do
        table.insert(self.entries, {
            id = def.id,
            data = def,
            unlocked = true,
            name = def.name,
            iconPath = nil,
        })
    end
end

function DatabaseScreen:loadToolEntries()
    -- Get all tools from ToolsData
    local toolIds = {
        "rail_driver", "frequency_scanner", "tractor_pulse",
        "thermal_lance", "cryo_projector", "emp_burst",
        "probe_launcher", "repulsor_field", "plasma_sprayer",
        "modified_mapping_drone", "micro_missile_pod",
        "singularity_core", "tesla_coil", "phase_disruptor"
    }

    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")

    for _, id in ipairs(toolIds) do
        local data = ToolsData[id]
        if data then
            local unlocked = debugUnlockAll or SaveManager:isDatabaseEntryUnlocked("tools", id)
            table.insert(self.entries, {
                id = id,
                data = data,
                unlocked = unlocked,
                name = data.name,
                iconPath = data.iconPath,
            })
        end
    end
end

function DatabaseScreen:loadBonusItemEntries()
    -- Get all bonus items
    local itemIds = {
        "alloy_gears", "expanded_dish", "magnetic_coils", "cooling_vents",
        "compressor_unit", "capacitor_bank", "probe_swarm", "field_amplifier",
        "reinforced_hull", "emergency_thrusters", "shield_capacitor",
        "overclocked_capacitors", "power_relay", "salvage_drone",
        "rapid_repair", "quantum_stabilizer", "critical_matrix",
        "brain_buddy", "kinetic_absorber", "scrap_collector",
        "rapid_loader", "backup_generator",
        "ablative_coating", "multi_spectrum_rounds",
        "targeting_matrix", "fuel_injector", "arc_capacitors",
        "guidance_module", "phase_modulators", "graviton_lens"
    }

    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")

    for _, id in ipairs(itemIds) do
        local data = BonusItemsData[id]
        if data then
            local unlocked = debugUnlockAll or SaveManager:isDatabaseEntryUnlocked("bonusItems", id)
            table.insert(self.entries, {
                id = id,
                data = data,
                unlocked = unlocked,
                name = data.name,
                iconPath = data.iconPath,
            })
        end
    end
end

function DatabaseScreen:loadEnemyEntries()
    -- Enemy definitions (from mob classes)
    local enemyDefs = {
        { id = "greeting_drone", name = "Greeting Drone", episode = 1, iconPath = "images/episodes/ep1/ep1_greeting_drone", health = 5, damage = 3, speed = "Fast", behavior = "Eager to hug your station" },
        { id = "silk_weaver", name = "Silk Weaver", episode = 1, iconPath = "images/episodes/ep1/ep1_silk_weaver", health = 12, damage = 2, speed = "Slow", behavior = "Hovers at range, fires webbing" },
        { id = "asteroid", name = "Asteroid", episode = 1, iconPath = "images/shared/asteroid", health = 3, damage = 5, speed = "Slow", behavior = "Drifts in from the void" },
        { id = "survey_drone", name = "Survey Drone", episode = 2, iconPath = "images/episodes/ep2/ep2_survey_drone", health = 6, damage = 4, speed = "Normal", behavior = "Corporate efficiency in action" },
        { id = "efficiency_monitor", name = "Efficiency Monitor", episode = 2, iconPath = "images/episodes/ep2/ep2_efficiency_monitor", health = 15, damage = 8, speed = "Slow", behavior = "Heavily armored enforcer" },
        { id = "probability_fluctuation", name = "Probability Fluctuation", episode = 3, iconPath = "images/episodes/ep3/ep3_probability_fluctuation", health = 7, damage = 5, speed = "Fast", behavior = "Flickers unpredictably" },
        { id = "paradox_node", name = "Paradox Node", episode = 3, iconPath = "images/episodes/ep3/ep3_paradox_node", health = 18, damage = 10, speed = "Slow", behavior = "Shouldn't exist, but does" },
        { id = "debris_chunk", name = "Debris Chunk", episode = 4, iconPath = "images/episodes/ep4/ep4_debris_chunk", health = 8, damage = 5, speed = "Slow", behavior = "Tumbles through space" },
        { id = "defense_turret", name = "Defense Turret", episode = 4, iconPath = "images/episodes/ep4/ep4_defense_turret", health = 20, damage = 6, speed = "Stationary", behavior = "Hovers at range, fires shots" },
        { id = "debate_drone", name = "Debate Drone", episode = 5, iconPath = "images/episodes/ep5/ep5_debate_drone", health = 5, damage = 3, speed = "Fast", behavior = "Three species, one argument" },
        { id = "citation_platform", name = "Citation Platform", episode = 5, iconPath = "images/episodes/ep5/ep5_citation_platform", health = 16, damage = 7, speed = "Slow", behavior = "Academic references hurt" },
    }

    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")

    for _, def in ipairs(enemyDefs) do
        local unlocked = debugUnlockAll or SaveManager:isDatabaseEntryUnlocked("enemies", def.id)
        table.insert(self.entries, {
            id = def.id,
            data = def,
            unlocked = unlocked,
            name = def.name,
            iconPath = def.iconPath,
        })
    end
end

function DatabaseScreen:loadBossEntries()
    local bossDefs = {
        { id = "cultural_attache", name = "Cultural Attache", episode = 1, iconPath = "images/episodes/ep1/ep1_boss_cultural_attache", health = 200, damage = 5, tagline = "Demands you accept their poetry", phases = {"Drone Wave", "Poetry", "Enraged"} },
        { id = "productivity_liaison", name = "Productivity Liaison", episode = 2, iconPath = "images/episodes/ep2/ep2_boss_productivity_liaison", health = 300, damage = 6, tagline = "Your performance is under review", phases = {"Survey Swarm", "Feedback", "Enraged"} },
        { id = "improbability_engine", name = "Improbability Engine", episode = 3, iconPath = "images/episodes/ep3/ep3_boss_improbability", health = 400, damage = 7, tagline = "Reality is just a suggestion", phases = {"Probability Storm", "Reality Warp", "Paradox", "Enraged"} },
        { id = "chomper", name = "Chomper", episode = 4, iconPath = "images/episodes/ep4/ep4_boss_chomper", health = 500, damage = 8, tagline = "Very large. Very hungry.", phases = {"Circling", "Charging", "Enraged"} },
        { id = "distinguished_professor", name = "Distinguished Professor", episode = 5, iconPath = "images/episodes/ep5/ep5_boss_professor", health = 600, damage = 8, tagline = "Your research is... derivative.", phases = {"Lecturing", "Summoning", "Enraged"} },
    }

    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")

    for _, def in ipairs(bossDefs) do
        local unlocked = debugUnlockAll or SaveManager:isDatabaseEntryUnlocked("bosses", def.id)
        table.insert(self.entries, {
            id = def.id,
            data = def,
            unlocked = unlocked,
            name = def.name,
            iconPath = def.iconPath,
        })
    end
end

function DatabaseScreen:loadEpisodeEntries()
    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")

    for i = 1, 5 do
        local epData = EpisodesData.get(i)
        if epData then
            -- Episodes unlock when available (not just completed)
            local unlocked = debugUnlockAll or SaveManager:isEpisodeUnlocked(i)
            local completed = SaveManager:isEpisodeCompleted(i)
            table.insert(self.entries, {
                id = i,
                data = epData,
                unlocked = unlocked,
                completed = completed,
                name = "Episode " .. i .. ": " .. epData.title,
                iconPath = nil,  -- Episodes don't have icons
            })
        end
    end
end

-- ============================================
-- Entry List
-- ============================================

function DatabaseScreen:updateEntryList()
    -- Navigation (up/right = up, down/left = down)
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self:moveListSelection(-1)
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self:moveListSelection(1)
    end

    -- Select entry
    if InputManager.buttonJustPressed.a then
        local entry = self.entries[self.selectedEntry]
        if entry and entry.unlocked then
            if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
            self:openDetailView(entry)
        end
    end

    -- Back to categories
    if InputManager.buttonJustPressed.b then
        self.currentState = self.STATE_CATEGORIES
        self.currentSprite = nil
        self.entries = {}
    end

    -- Crank scrolling
    local crankChange = playdate.getCrankChange()
    if math.abs(crankChange) > 15 then
        if crankChange > 0 then
            self:moveListSelection(1)
        else
            self:moveListSelection(-1)
        end
    end
end

function DatabaseScreen:moveListSelection(direction)
    local newIndex = self.selectedEntry + direction

    if newIndex < 1 then
        newIndex = 1
    elseif newIndex > #self.entries then
        newIndex = #self.entries
    end

    if newIndex ~= self.selectedEntry then
        self.selectedEntry = newIndex

        -- Adjust scroll
        if self.selectedEntry < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedEntry - 1
        elseif self.selectedEntry > self.scrollOffset + self.maxVisibleItems then
            self.scrollOffset = self.selectedEntry - self.maxVisibleItems
        end

        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    end
end

function DatabaseScreen:openDetailView(entry)
    self.currentEntry = entry
    self.currentState = self.STATE_DETAIL
    self.inputDelay = 0.1
    self.gameplayScrollOffset = 0
    self.gameplayMaxScroll = 0

    -- Load sprite (use pre-processed icon on black background)
    if entry.iconPath then
        local filename = entry.iconPath:match("([^/]+)$")  -- Get filename from path
        local onBlackPath = "images/icons_on_black/" .. filename
        self.currentSprite = gfx.image.new(onBlackPath)
    else
        self.currentSprite = nil
    end
end

-- ============================================
-- Detail View
-- ============================================

function DatabaseScreen:updateDetailView()
    -- Back to list
    if InputManager.buttonJustPressed.b then
        self.currentState = self.STATE_LIST
        self.currentSprite = nil
        self.currentEntry = nil
        self.gameplayScrollOffset = 0
        return
    end

    -- Gameplay entries support scrolling
    if self.currentCategoryId == "gameplay" then
        -- Scroll with d-pad
        if InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
            self.gameplayScrollOffset = math.min(self.gameplayScrollOffset + 30, self.gameplayMaxScroll)
        elseif InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
            self.gameplayScrollOffset = math.max(self.gameplayScrollOffset - 30, 0)
        end

        -- Crank scrolling
        local crankChange = playdate.getCrankChange()
        if math.abs(crankChange) > 2 then
            self.gameplayScrollOffset = self.gameplayScrollOffset + crankChange * 0.5
            self.gameplayScrollOffset = math.max(0, math.min(self.gameplayScrollOffset, self.gameplayMaxScroll))
        end
    else
        -- Navigate to previous entry
        if InputManager.buttonJustPressed.left then
            self:navigateDetailEntry(-1)
        end

        -- Navigate to next entry
        if InputManager.buttonJustPressed.right then
            self:navigateDetailEntry(1)
        end
    end
end

function DatabaseScreen:navigateDetailEntry(direction)
    -- Find next unlocked entry in direction
    local startIdx = self.selectedEntry
    local newIdx = startIdx + direction

    while newIdx >= 1 and newIdx <= #self.entries do
        local entry = self.entries[newIdx]
        if entry.unlocked then
            -- Found an unlocked entry
            self.selectedEntry = newIdx
            self:openDetailView(entry)
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
            return
        end
        newIdx = newIdx + direction
    end
    -- No unlocked entry found in that direction
end

-- ============================================
-- Drawing
-- ============================================

function DatabaseScreen:draw()
    if not self.isVisible then return end

    gfx.clear(gfx.kColorBlack)

    if self.currentState == self.STATE_CATEGORIES then
        self:drawCategoryMenu()
    elseif self.currentState == self.STATE_LIST then
        self:drawEntryList()
    elseif self.currentState == self.STATE_DETAIL then
        self:drawDetailView()
    end
end

function DatabaseScreen:drawCategoryMenu()
    -- Title bar - BLACK bar with WHITE text
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("DATABASE", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Category list with scrolling
    local startY = 55
    local itemHeight = 32

    local startIdx = self.categoryScrollOffset + 1
    local endIdx = math.min(startIdx + self.maxVisibleCategories - 1, #self.categories)

    FontManager:setMenuFont()

    for i = startIdx, endIdx do
        local cat = self.categories[i]
        local displayIdx = i - self.categoryScrollOffset
        local y = startY + (displayIdx - 1) * itemHeight
        local isSelected = (i == self.selectedCategory)

        -- Get unlock count
        local unlockCount = 0
        if cat.id == "gameplay" then
            -- Gameplay entries are always unlocked
            unlockCount = 3
        elseif cat.id == "episodes" then
            -- Count unlocked episodes
            local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllDatabase")
            for ep = 1, 5 do
                if debugUnlockAll or SaveManager:isEpisodeUnlocked(ep) then
                    unlockCount = unlockCount + 1
                end
            end
        else
            unlockCount = SaveManager:getDatabaseUnlockCount(cat.id)
        end

        if isSelected then
            -- Selected: WHITE fill, BLACK text
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(40, y - 4, Constants.SCREEN_WIDTH - 80, 26, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            -- Unselected: BLACK fill, WHITE border
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(40, y - 4, Constants.SCREEN_WIDTH - 80, 26, 4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRoundRect(40, y - 4, Constants.SCREEN_WIDTH - 80, 26, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- Category name
        gfx.drawText("*" .. cat.name .. "*", 55, y)

        -- Unlock count
        local countText = "*[" .. unlockCount .. "/" .. cat.total .. "]*"
        gfx.drawTextAligned(countText, Constants.SCREEN_WIDTH - 55, y, kTextAlignment.right)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Scroll indicators (white on black)
    if self.categoryScrollOffset > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 25, 50, Constants.SCREEN_WIDTH - 20, 44, Constants.SCREEN_WIDTH - 15, 50)
    end
    if self.categoryScrollOffset + self.maxVisibleCategories < #self.categories then
        local arrowY = startY + self.maxVisibleCategories * itemHeight - 8
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 25, arrowY, Constants.SCREEN_WIDTH - 20, arrowY + 6, Constants.SCREEN_WIDTH - 15, arrowY)
    end

    -- Footer - WHITE rule, WHITE text on BLACK
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, 26)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 26)
    FontManager:setFooterFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("D-pad navigate   A select   B back", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 19, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function DatabaseScreen:drawEntryList()
    -- Find category name
    local catName = "ENTRIES"
    for _, cat in ipairs(self.categories) do
        if cat.id == self.currentCategoryId then
            catName = string.upper(cat.name)
            break
        end
    end

    -- Title bar - BLACK bar with WHITE text
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(catName, Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Entry list
    local startY = 50
    local itemHeight = 32

    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + self.maxVisibleItems - 1, #self.entries)

    FontManager:setMenuFont()

    for i = startIdx, endIdx do
        local entry = self.entries[i]
        local displayIdx = i - self.scrollOffset
        local y = startY + (displayIdx - 1) * itemHeight
        local isSelected = (i == self.selectedEntry)

        if isSelected then
            -- Selected: WHITE fill, BLACK text
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 28, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            -- Unselected: BLACK fill, WHITE border
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 28, 4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRoundRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 28, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        if entry.unlocked then
            -- Draw sprite thumbnail if available
            if entry.iconPath then
                -- Convert to pre-processed icon on black background
                local filename = entry.iconPath:match("([^/]+)$")  -- Get filename from path
                local onBlackPath = "images/icons_on_black/" .. filename
                local icon = gfx.image.new(onBlackPath)
                if icon then
                    local iconW, iconH = icon:getSize()
                    local scale = math.min(24 / iconW, 24 / iconH)
                    local scaledW = iconW * scale
                    local scaledH = iconH * scale
                    local iconX = 27 + (26 - scaledW) / 2
                    local iconY = y - 1 + (26 - scaledH) / 2

                    -- Draw BLACK background for icon (terminal-appropriate)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillRect(26, y - 1, 28, 26)
                    -- Draw WHITE border around icon area
                    gfx.setColor(gfx.kColorWhite)
                    gfx.drawRect(26, y - 1, 28, 26)

                    -- Reset draw mode for pre-processed icons (they're ready to use directly)
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                    icon:drawScaled(iconX, iconY, scale)
                end
            end

            -- Name text - restore correct draw mode after icon
            if isSelected then
                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            else
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            end
            gfx.drawText("*" .. entry.name .. "*", 58, y + 4)

            -- Checkmark for completed episodes
            if self.currentCategoryId == "episodes" and entry.completed then
                gfx.drawText("*+*", Constants.SCREEN_WIDTH - 40, y + 4)
            end
        else
            -- Locked
            gfx.drawText("*??????*", 58, y + 4)
            gfx.drawTextAligned("*-*", Constants.SCREEN_WIDTH - 40, y + 4, kTextAlignment.right)
        end

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Scroll indicators (white on black)
    if self.scrollOffset > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 20, 48, Constants.SCREEN_WIDTH - 15, 44, Constants.SCREEN_WIDTH - 10, 48)
    end

    if self.scrollOffset + self.maxVisibleItems < #self.entries then
        local arrowY = startY + self.maxVisibleItems * itemHeight - 8
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 20, arrowY, Constants.SCREEN_WIDTH - 15, arrowY + 4, Constants.SCREEN_WIDTH - 10, arrowY)
    end

    -- Footer - WHITE rule, WHITE text on BLACK
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, 26)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 26)
    FontManager:setFooterFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("D-pad navigate   A view   B back", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 19, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function DatabaseScreen:drawDetailView()
    if not self.currentEntry then return end

    local entry = self.currentEntry
    local data = entry.data

    -- Title bar - BLACK bar with WHITE text
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(string.upper(entry.name), Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- All detail content drawn in WHITE on BLACK
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    -- Draw based on category
    if self.currentCategoryId == "gameplay" then
        self:drawGameplayDetail(entry.id)
    elseif self.currentCategoryId == "tools" then
        self:drawToolDetail(data)
    elseif self.currentCategoryId == "bonusItems" then
        self:drawBonusItemDetail(data)
    elseif self.currentCategoryId == "enemies" then
        self:drawEnemyDetail(data)
    elseif self.currentCategoryId == "bosses" then
        self:drawBossDetail(data)
    elseif self.currentCategoryId == "episodes" then
        self:drawEpisodeDetail(data, entry.completed)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Footer - WHITE rule, WHITE text on BLACK
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, 26)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 26, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 26)

    FontManager:setFooterFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    if self.currentCategoryId == "gameplay" then
        gfx.drawTextAligned("D-pad/Crank scroll   B back", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 19, kTextAlignment.center)
    else
        gfx.drawTextAligned("B back", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 19, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function DatabaseScreen:drawToolDetail(data)
    local spriteX = 25
    local spriteY = 58
    local spriteBoxSize = 56
    local textX = 100
    local y = 58

    -- Draw sprite in black background box (scaled up)
    if self.currentSprite then
        local iconW, iconH = self.currentSprite:getSize()
        local scale = math.min((spriteBoxSize - 8) / iconW, (spriteBoxSize - 8) / iconH)
        local scaledW = iconW * scale
        local scaledH = iconH * scale
        local iconX = spriteX + (spriteBoxSize - scaledW) / 2
        local iconY = spriteY + (spriteBoxSize - scaledH) / 2

        -- Black background with white border
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(spriteX, spriteY, spriteBoxSize, spriteBoxSize)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(spriteX, spriteY, spriteBoxSize, spriteBoxSize)

        -- Pre-processed icons are already white on black, just draw them
        self.currentSprite:drawScaled(iconX, iconY, scale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    -- Description
    FontManager:setBodyFont()
    gfx.drawText("*" .. (data.description or "") .. "*", textX, y)
    y = y + 24

    -- Stats
    FontManager:setMenuFont()
    gfx.drawText("*DMG: " .. (data.baseDamage or 0) .. "*", textX, y)
    y = y + 18
    gfx.drawText("*RATE: " .. (data.fireRate or 0) .. "/s*", textX, y)
    y = y + 18
    gfx.drawText("*Pattern: " .. (data.pattern or "straight") .. "*", textX, y)
    y = y + 26

    -- Evolution info
    if data.pairsWithBonus then
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(textX, y, Constants.SCREEN_WIDTH - 30, y)
        y = y + 10
        FontManager:setBodyFont()
        local bonusData = BonusItemsData[data.pairsWithBonus]
        local bonusName = bonusData and bonusData.name or data.pairsWithBonus
        gfx.drawText("*Pairs with: " .. bonusName .. "*", textX, y)
        y = y + 18
        if data.upgradedName then
            gfx.drawText("*> Evolves to: " .. data.upgradedName .. "*", textX, y)
        end
    end
end

function DatabaseScreen:drawBonusItemDetail(data)
    local spriteX = 25
    local spriteY = 58
    local spriteBoxSize = 56
    local textX = 100
    local y = 58

    -- Draw sprite in black background box (scaled up)
    if self.currentSprite then
        local iconW, iconH = self.currentSprite:getSize()
        local scale = math.min((spriteBoxSize - 8) / iconW, (spriteBoxSize - 8) / iconH)
        local scaledW = iconW * scale
        local scaledH = iconH * scale
        local iconX = spriteX + (spriteBoxSize - scaledW) / 2
        local iconY = spriteY + (spriteBoxSize - scaledH) / 2

        -- Black background with white border
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(spriteX, spriteY, spriteBoxSize, spriteBoxSize)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(spriteX, spriteY, spriteBoxSize, spriteBoxSize)

        -- Pre-processed icons are already white on black, just draw them
        self.currentSprite:drawScaled(iconX, iconY, scale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    -- Effect
    FontManager:setBodyFont()
    gfx.drawText("*" .. (data.description or "") .. "*", textX, y)
    y = y + 34

    -- Pairing info
    FontManager:setMenuFont()
    if data.pairsWithTool then
        local toolData = ToolsData[data.pairsWithTool]
        local toolName = toolData and toolData.name or data.pairsWithTool
        gfx.drawText("*Pairs with: " .. toolName .. "*", textX, y)
        y = y + 18
        if data.upgradesTo then
            gfx.drawText("*> Creates: " .. data.upgradesTo .. "*", textX, y)
        end
    else
        gfx.drawText("*Passive bonus*", textX, y)
    end
end

function DatabaseScreen:drawEnemyDetail(data)
    local spriteX = 30
    local spriteY = 65
    local textX = 100
    local y = 58

    -- Draw sprite (scaled up) - keep black background
    if self.currentSprite then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.currentSprite:drawScaled(spriteX, spriteY, 2)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    -- Episode
    FontManager:setMenuFont()
    gfx.drawText("*Episode " .. (data.episode or "?") .. "*", textX, y)
    y = y + 22

    -- Stats
    gfx.drawText("*HP: " .. (data.health or "?") .. "*", textX, y)
    gfx.drawText("*DMG: " .. (data.damage or "?") .. "*", textX + 80, y)
    y = y + 18
    gfx.drawText("*Speed: " .. (data.speed or "?") .. "*", textX, y)
    y = y + 26

    -- Behavior
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(textX, y, Constants.SCREEN_WIDTH - 30, y)
    y = y + 10
    FontManager:setBodyFont()
    gfx.drawTextInRect("*" .. (data.behavior or "") .. "*", textX, y, Constants.SCREEN_WIDTH - textX - 30, 40)
end

function DatabaseScreen:drawBossDetail(data)
    local spriteX = 20
    local spriteY = 55
    local textX = 90
    local y = 55

    -- Draw sprite (scaled) - keep black background
    if self.currentSprite then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        local w, h = self.currentSprite:getSize()
        local scale = math.min(60 / w, 60 / h)
        self.currentSprite:drawScaled(spriteX, spriteY, scale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    -- Tagline
    FontManager:setBodyFont()
    gfx.drawText("*\"" .. (data.tagline or "") .. "\"*", textX, y)
    y = y + 20
    FontManager:setMenuFont()
    gfx.drawText("*Episode " .. (data.episode or "?") .. " Boss*", textX, y)
    y = y + 22

    -- Stats
    gfx.drawText("*HP: " .. (data.health or "?") .. "*", textX, y)
    gfx.drawText("*DMG: " .. (data.damage or "?") .. "*", textX + 100, y)
    y = y + 22

    -- Phases
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(textX, y, Constants.SCREEN_WIDTH - 20, y)
    y = y + 8
    gfx.drawText("*PHASES:*", textX, y)
    y = y + 16

    if data.phases then
        FontManager:setBodyFont()
        for _, phase in ipairs(data.phases) do
            gfx.drawText("*" .. phase .. "*", textX + 10, y)
            y = y + 16
        end
    end
end

function DatabaseScreen:drawEpisodeDetail(data, completed)
    local y = 55
    local margin = 25

    -- Title and tagline
    FontManager:setBodyFont()
    gfx.drawText("*" .. data.title .. "*", margin, y)
    y = y + 20
    gfx.drawText("*\"" .. (data.tagline or "") .. "\"*", margin, y)
    y = y + 26

    -- Separator
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(margin, y, Constants.SCREEN_WIDTH - margin, y)
    y = y + 12

    -- Enemies
    FontManager:setMenuFont()
    gfx.drawText("*ENEMIES:*", margin, y)
    y = y + 16
    FontManager:setBodyFont()
    local enemyText = data.enemyNames or "Various threats"
    gfx.drawTextInRect("*" .. enemyText .. "*", margin + 10, y, Constants.SCREEN_WIDTH - margin * 2 - 10, 30)
    y = y + 30

    -- Boss
    FontManager:setMenuFont()
    gfx.drawText("*BOSS: " .. (data.bossName or "Unknown") .. "*", margin, y)
    y = y + 20

    -- Research spec reward
    if data.researchSpecUnlock then
        local specData = ResearchSpecsData and ResearchSpecsData.get(data.researchSpecUnlock)
        local specName = specData and specData.name or data.researchSpecUnlock
        gfx.drawText("*REWARD: " .. specName .. "*", margin, y)
    end

    -- Completion status
    y = Constants.SCREEN_HEIGHT - 55
    FontManager:setMenuFont()
    if completed then
        gfx.drawTextAligned("*+ COMPLETED*", Constants.SCREEN_WIDTH / 2, y, kTextAlignment.center)
    else
        gfx.drawTextAligned("*NOT YET COMPLETED*", Constants.SCREEN_WIDTH / 2, y, kTextAlignment.center)
    end
end

-- ============================================
-- Gameplay Detail Views
-- ============================================

function DatabaseScreen:drawGameplayDetail(entryId)
    if entryId == "controls" then
        self:drawControlsDetail()
    elseif entryId == "settings" then
        self:drawSettingsDetail()
    elseif entryId == "station_systems" then
        self:drawStationSystemsDetail()
    end
end

function DatabaseScreen:drawControlsDetail()
    local margin = 20
    local contentTop = 44
    local contentHeight = Constants.SCREEN_HEIGHT - 70

    -- Set clip rect for scrolling
    gfx.setClipRect(0, contentTop, Constants.SCREEN_WIDTH - 14, contentHeight)

    local y = contentTop - self.gameplayScrollOffset

    -- Section: Crank
    FontManager:setBoldFont()
    gfx.drawText("CRANK", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Rotate the crank to spin your station.", margin, y)
    y = y + 20
    gfx.drawText("Tools fire in the direction they face.", margin, y)
    y = y + 20
    gfx.drawText("Aim by positioning tools toward enemies.", margin, y)
    y = y + 32

    -- Section: D-Pad
    FontManager:setBoldFont()
    gfx.drawText("D-PAD", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Navigate menus (Up/Down or Left/Right).", margin, y)
    y = y + 20
    gfx.drawText("Scroll content in some screens.", margin, y)
    y = y + 32

    -- Section: A Button
    FontManager:setBoldFont()
    gfx.drawText("A BUTTON", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Confirm selections in menus.", margin, y)
    y = y + 20
    gfx.drawText("Continue through story panels.", margin, y)
    y = y + 32

    -- Section: B Button
    FontManager:setBoldFont()
    gfx.drawText("B BUTTON", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Go back / Cancel.", margin, y)
    y = y + 20
    gfx.drawText("Pause during gameplay.", margin, y)
    y = y + 32

    -- Section: Menu Button
    FontManager:setBoldFont()
    gfx.drawText("MENU BUTTON", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Pause the game during an episode.", margin, y)
    y = y + 32

    -- Calculate max scroll
    self.gameplayMaxScroll = math.max(0, y + self.gameplayScrollOffset - Constants.SCREEN_HEIGHT + 30)

    gfx.clearClipRect()

    -- Draw scroll indicator if needed
    if self.gameplayMaxScroll > 0 then
        self:drawScrollIndicator()
    end
end

function DatabaseScreen:drawSettingsDetail()
    local margin = 20
    local contentTop = 44
    local contentHeight = Constants.SCREEN_HEIGHT - 70

    -- Set clip rect for scrolling
    gfx.setClipRect(0, contentTop, Constants.SCREEN_WIDTH - 14, contentHeight)

    local y = contentTop - self.gameplayScrollOffset

    -- Section: Music Volume
    FontManager:setBoldFont()
    gfx.drawText("MUSIC VOLUME", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Adjust background music volume.", margin, y)
    y = y + 20
    gfx.drawText("Range: 0% (off) to 100% (full).", margin, y)
    y = y + 32

    -- Section: SFX Volume
    FontManager:setBoldFont()
    gfx.drawText("SFX VOLUME", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Adjust sound effects volume.", margin, y)
    y = y + 20
    gfx.drawText("Includes hits, pickups, and UI sounds.", margin, y)
    y = y + 32

    -- Section: Creative Mode
    FontManager:setBoldFont()
    gfx.drawText("CREATIVE MODE", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Sandbox mode for exploration.", margin, y)
    y = y + 20
    gfx.drawText("- Unlock all content instantly", margin, y)
    y = y + 20
    gfx.drawText("- Customize episode/wave timing", margin, y)
    y = y + 20
    gfx.drawText("- Optional invincibility", margin, y)
    y = y + 32

    -- Section: Reset All Data
    FontManager:setBoldFont()
    gfx.drawText("RESET ALL DATA", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Clears all save data and progress.", margin, y)
    y = y + 20
    gfx.drawText("Resets episodes, specs, and database.", margin, y)
    y = y + 20
    gfx.drawText("Cannot be undone!", margin, y)
    y = y + 32

    -- Calculate max scroll
    self.gameplayMaxScroll = math.max(0, y + self.gameplayScrollOffset - Constants.SCREEN_HEIGHT + 30)

    gfx.clearClipRect()

    -- Draw scroll indicator if needed
    if self.gameplayMaxScroll > 0 then
        self:drawScrollIndicator()
    end
end

function DatabaseScreen:drawStationSystemsDetail()
    local margin = 20
    local contentTop = 44
    local contentHeight = Constants.SCREEN_HEIGHT - 70

    -- Set clip rect for scrolling
    gfx.setClipRect(0, contentTop, Constants.SCREEN_WIDTH - 14, contentHeight)

    local y = contentTop - self.gameplayScrollOffset

    -- Section: Tools
    FontManager:setBoldFont()
    gfx.drawText("TOOLS", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Weapons that auto-fire from your station.", margin, y)
    y = y + 20
    gfx.drawText("Max 8 different tools per episode.", margin, y)
    y = y + 20
    gfx.drawText("Each tool can be upgraded to level 4.", margin, y)
    y = y + 20
    gfx.drawText("Pair a max tool + bonus item to evolve.", margin, y)
    y = y + 32

    -- Section: Bonus Items
    FontManager:setBoldFont()
    gfx.drawText("BONUS ITEMS", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Passive upgrades and stat boosts.", margin, y)
    y = y + 20
    gfx.drawText("Max 8 different items per episode.", margin, y)
    y = y + 20
    gfx.drawText("Each item can be upgraded to level 4.", margin, y)
    y = y + 20
    gfx.drawText("Some items pair with tools for evolution.", margin, y)
    y = y + 32

    -- Section: Level Up
    FontManager:setBoldFont()
    gfx.drawText("LEVEL UP", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Collect RP (Research Points) from enemies.", margin, y)
    y = y + 20
    gfx.drawText("Fill the bar at top to level up.", margin, y)
    y = y + 20
    gfx.drawText("Choose from 2 tools and 2 bonus items.", margin, y)
    y = y + 32

    -- Section: Research Specs
    FontManager:setBoldFont()
    gfx.drawText("RESEARCH SPECS", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("Permanent bonuses unlocked by", margin, y)
    y = y + 20
    gfx.drawText("completing episodes.", margin, y)
    y = y + 20
    gfx.drawText("Active specs apply to all future runs.", margin, y)
    y = y + 32

    -- Section: Episodes
    FontManager:setBoldFont()
    gfx.drawText("EPISODES", margin, y)
    y = y + 22
    FontManager:setBodyFont()
    gfx.drawText("7 waves of enemies + 1 boss fight.", margin, y)
    y = y + 20
    gfx.drawText("Defeat the boss to complete the episode.", margin, y)
    y = y + 20
    gfx.drawText("Each episode has unique enemies.", margin, y)
    y = y + 32

    -- Calculate max scroll
    self.gameplayMaxScroll = math.max(0, y + self.gameplayScrollOffset - Constants.SCREEN_HEIGHT + 30)

    gfx.clearClipRect()

    -- Draw scroll indicator if needed
    if self.gameplayMaxScroll > 0 then
        self:drawScrollIndicator()
    end
end

function DatabaseScreen:drawScrollIndicator()
    -- Show scroll hint in footer area
    local scrollPct = 0
    if self.gameplayMaxScroll > 0 then
        scrollPct = self.gameplayScrollOffset / self.gameplayMaxScroll
    end

    -- Draw small scroll bar on right (white on black)
    local barX = Constants.SCREEN_WIDTH - 12
    local barY = 48
    local barH = Constants.SCREEN_HEIGHT - 78
    local thumbH = math.max(20, barH * 0.3)
    local thumbY = barY + scrollPct * (barH - thumbH)

    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(barX, barY, 6, barH)
    gfx.fillRect(barX + 1, thumbY, 4, thumbH)
end

return DatabaseScreen
