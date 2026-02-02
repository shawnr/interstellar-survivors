-- Research Specs Screen UI
-- Shows unlocked and locked Research Specs

local gfx <const> = playdate.graphics

ResearchSpecsScreen = {
    isVisible = false,
    selectedIndex = 1,
    specs = {},
    scrollOffset = 0,
    maxVisibleItems = 3,  -- Only 3 items to fit taller rows properly
    fromState = nil,
    patternBg = nil,
}

function ResearchSpecsScreen:init()
    -- Load pattern background
    self.patternBg = gfx.image.new("images/ui/menu_pattern_bg")
end

function ResearchSpecsScreen:refreshSpecs()
    self.specs = {}

    -- Get all specs from data, sorted by episode source
    local allSpecs = ResearchSpecsData.getAll()

    -- Sort by episode source (nil = special unlock, goes last)
    table.sort(allSpecs, function(a, b)
        local aSource = a.episodeSource or 99
        local bSource = b.episodeSource or 99
        return aSource < bSource
    end)

    -- Build specs list with unlock status
    local debugUnlockAll = SaveManager and SaveManager:isDebugFeatureEnabled("unlockAllResearchSpecs")

    for _, specData in ipairs(allSpecs) do
        local isUnlocked = debugUnlockAll or (SaveManager and SaveManager:isResearchSpecUnlocked(specData.id))
        table.insert(self.specs, {
            data = specData,
            unlocked = isUnlocked
        })
    end
end

function ResearchSpecsScreen:show(fromState)
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.fromState = fromState or GameManager.states.EPISODE_SELECT
    self:refreshSpecs()

    -- Load pattern if not already loaded
    if not self.patternBg then
        self.patternBg = gfx.image.new("images/ui/menu_pattern_bg")
    end
end

function ResearchSpecsScreen:hide()
    self.isVisible = false
end

function ResearchSpecsScreen:update()
    if not self.isVisible then return end

    -- Handle input - up/right = up, down/left = down
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self:moveSelection(-1)
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self:moveSelection(1)
    end

    -- B button to go back
    if InputManager.buttonJustPressed.b then
        if AudioManager then
            AudioManager:playSFX("menu_back", 0.3)
        end
        self:hide()
        GameManager:setState(self.fromState)
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

function ResearchSpecsScreen:moveSelection(direction)
    local newIndex = self.selectedIndex + direction

    -- Clamp (don't wrap for scrolling list)
    if newIndex < 1 then
        newIndex = 1
    elseif newIndex > #self.specs then
        newIndex = #self.specs
    end

    if newIndex ~= self.selectedIndex then
        self.selectedIndex = newIndex

        -- Adjust scroll offset to keep selection visible
        if self.selectedIndex < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedIndex - 1
        elseif self.selectedIndex > self.scrollOffset + self.maxVisibleItems then
            self.scrollOffset = self.selectedIndex - self.maxVisibleItems
        end

        -- Play navigation sound
        if AudioManager then
            AudioManager:playSFX("menu_move", 0.3)
        end
    end
end

function ResearchSpecsScreen:draw()
    if not self.isVisible then return end

    -- Draw pattern background
    if self.patternBg then
        self.patternBg:draw(0, 0)
    else
        gfx.clear(gfx.kColorWhite)
    end

    -- Title bar with white background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    gfx.drawTextAligned("*RESEARCH SPECS*", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)

    -- Draw specs list
    local startY = 46
    local itemHeight = 52  -- Taller rows for two lines of bold text with padding

    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + self.maxVisibleItems - 1, #self.specs)

    for i = startIdx, endIdx do
        local spec = self.specs[i]
        local displayIdx = i - self.scrollOffset
        local y = startY + (displayIdx - 1) * itemHeight
        local isSelected = (i == self.selectedIndex)

        self:drawSpecItem(spec, y, isSelected)
    end

    -- Draw scroll indicators if needed
    if self.scrollOffset > 0 then
        -- Up arrow
        gfx.setColor(gfx.kColorBlack)
        gfx.fillTriangle(
            Constants.SCREEN_WIDTH - 20, 44,
            Constants.SCREEN_WIDTH - 15, 40,
            Constants.SCREEN_WIDTH - 10, 44
        )
    end

    if self.scrollOffset + self.maxVisibleItems < #self.specs then
        -- Down arrow
        local arrowY = startY + self.maxVisibleItems * itemHeight - 4
        gfx.setColor(gfx.kColorBlack)
        gfx.fillTriangle(
            Constants.SCREEN_WIDTH - 20, arrowY,
            Constants.SCREEN_WIDTH - 15, arrowY + 6,
            Constants.SCREEN_WIDTH - 10, arrowY
        )
    end

    -- Draw instructions at bottom with white background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)

    local unlockCount = 0
    for _, s in ipairs(self.specs) do
        if s.unlocked then unlockCount = unlockCount + 1 end
    end
    gfx.drawTextAligned(unlockCount .. "/" .. #self.specs .. " Unlocked   [B] Back",
        Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
end

function ResearchSpecsScreen:drawSpecItem(spec, y, isSelected)
    local itemWidth = Constants.SCREEN_WIDTH - 40
    local rowHeight = 46  -- Height for two lines of bold text with padding

    -- Row background for readability
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(20, y, itemWidth, rowHeight, 4)

    -- Selection highlight or border
    gfx.setColor(gfx.kColorBlack)
    if isSelected then
        gfx.fillRoundRect(20, y, itemWidth, rowHeight, 4)
    else
        gfx.drawRoundRect(20, y, itemWidth, rowHeight, 4)
    end

    -- Set draw mode based on selection
    if isSelected then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    if spec.unlocked then
        -- Show spec name (bold) on first line - 8px from top
        gfx.drawText("*" .. spec.data.name .. "*", 28, y + 8)

        -- Draw description (bold) on second line - 26px from top
        gfx.drawText("*" .. spec.data.description .. "*", 28, y + 26)
    else
        -- Show locked indicator (bold) - centered vertically
        local lockText = "[LOCKED]"

        -- Show hint about how to unlock
        if spec.data.episodeSource then
            lockText = "[LOCKED] - Complete Episode " .. spec.data.episodeSource
        else
            lockText = "[LOCKED] - Special unlock"
        end

        gfx.drawText("*" .. lockText .. "*", 28, y + 16)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return ResearchSpecsScreen
