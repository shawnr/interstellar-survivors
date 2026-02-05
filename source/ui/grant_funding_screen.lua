-- Grant Funding Screen UI
-- Allows players to spend Grant Funds to upgrade station stats
-- Retro terminal aesthetic: black background, white text, inverted selection

local gfx <const> = playdate.graphics

GrantFundingScreen = {
    isVisible = false,
    selectedIndex = 1,
    scrollOffset = 0,
    maxVisibleItems = 3,  -- Fits 3 items at 46px each in available space
    stats = {},  -- Display data for each stat
    fromState = nil,
    confirmingPurchase = false,
    confirmIndex = 2,  -- Default to "No"
}

function GrantFundingScreen:init()
end

function GrantFundingScreen:show(fromState)
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.fromState = fromState or GameManager.states.TITLE
    self.confirmingPurchase = false
    self:refreshStats()
end

function GrantFundingScreen:hide()
    self.isVisible = false
end

function GrantFundingScreen:refreshStats()
    self.stats = {}

    local statOrder = GrantFundingData.getStatOrder()
    for _, statId in ipairs(statOrder) do
        local data = GrantFundingData.get(statId)
        local currentLevel = SaveManager:getGrantFundingLevel(statId)
        local nextLevel = currentLevel + 1
        local cost = 0
        local nextLabel = nil
        local maxed = false

        if nextLevel <= 4 then
            cost = GrantFundingData.getCost(statId, nextLevel)
            nextLabel = data.levels[nextLevel].label
        else
            maxed = true
        end

        table.insert(self.stats, {
            id = statId,
            data = data,
            currentLevel = currentLevel,
            nextLevel = nextLevel,
            cost = cost,
            nextLabel = nextLabel,
            maxed = maxed,
        })
    end
end

function GrantFundingScreen:update()
    if not self.isVisible then return end

    -- Handle purchase confirmation dialog
    if self.confirmingPurchase then
        if InputManager.buttonJustPressed.left then
            self.confirmIndex = 1  -- Yes
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        elseif InputManager.buttonJustPressed.right then
            self.confirmIndex = 2  -- No
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        elseif InputManager.buttonJustPressed.a then
            if self.confirmIndex == 1 then
                -- Confirmed purchase
                self:confirmPurchase()
            end
            self.confirmingPurchase = false
        elseif InputManager.buttonJustPressed.b then
            self.confirmingPurchase = false
        end
        return
    end

    -- Navigation (up/right = up, down/left = down)
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self:moveSelection(-1)
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self:moveSelection(1)
    end

    -- A button to purchase
    if InputManager.buttonJustPressed.a then
        local stat = self.stats[self.selectedIndex]
        if stat and not stat.maxed then
            local funds = SaveManager:getGrantFunds()
            if funds >= stat.cost then
                -- Show confirmation
                self.confirmingPurchase = true
                self.confirmIndex = 2  -- Default to No
                if AudioManager then AudioManager:playSFX("menu_confirm", 0.5) end
            else
                -- Can't afford
                if AudioManager then AudioManager:playSFX("menu_back", 0.5) end
            end
        end
    end

    -- B button to go back
    if InputManager.buttonJustPressed.b then
        if AudioManager then
            AudioManager:playSFX("menu_back", 0.3)
        end
        self:hide()
        GameManager:setState(self.fromState)
    end

    -- Crank can also navigate
    local crankChange = playdate.getCrankChange()
    if math.abs(crankChange) > 15 then
        if crankChange > 0 then
            self:moveSelection(1)
        else
            self:moveSelection(-1)
        end
    end
end

function GrantFundingScreen:moveSelection(direction)
    local newIndex = self.selectedIndex + direction

    if newIndex < 1 then
        newIndex = #self.stats
        -- Jump to bottom
        self.scrollOffset = math.max(0, #self.stats - self.maxVisibleItems)
    elseif newIndex > #self.stats then
        newIndex = 1
        self.scrollOffset = 0
    end

    if newIndex ~= self.selectedIndex then
        self.selectedIndex = newIndex

        -- Adjust scroll to keep selection visible
        if self.selectedIndex < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedIndex - 1
        elseif self.selectedIndex > self.scrollOffset + self.maxVisibleItems then
            self.scrollOffset = self.selectedIndex - self.maxVisibleItems
        end

        if AudioManager then
            AudioManager:playSFX("menu_move", 0.3)
        end
    end
end

function GrantFundingScreen:confirmPurchase()
    local stat = self.stats[self.selectedIndex]
    if not stat or stat.maxed then return end

    local success = SaveManager:upgradeGrantFunding(stat.id, stat.cost)
    if success then
        if AudioManager then AudioManager:playSFX("level_up", 0.7) end
        SaveManager:flush()
        self:refreshStats()
    end
end

function GrantFundingScreen:draw()
    if not self.isVisible then return end

    gfx.clear(gfx.kColorBlack)

    -- Title bar with BLACK background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, 40)
    -- White horizontal rule below header
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, 40, Constants.SCREEN_WIDTH, 40)
    -- WHITE header text on black
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setTitleFont()
    gfx.drawTextAligned("GRANT FUNDING", Constants.SCREEN_WIDTH / 2, 6, kTextAlignment.center)

    -- Current funds display: WHITE text on black
    FontManager:setBodyFont()
    gfx.drawTextAligned("*Funds: " .. SaveManager:getGrantFunds() .. "*", Constants.SCREEN_WIDTH / 2, 22, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw stats list with scrolling
    local startY = 46
    local itemHeight = 46
    local funds = SaveManager:getGrantFunds()

    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + self.maxVisibleItems - 1, #self.stats)

    for i = startIdx, endIdx do
        local stat = self.stats[i]
        local displayIdx = i - self.scrollOffset
        local y = startY + (displayIdx - 1) * itemHeight
        local isSelected = (i == self.selectedIndex)

        self:drawStatItem(stat, y, isSelected, funds)
    end

    -- Scroll indicators (white on black background)
    if self.scrollOffset > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 25, 50, Constants.SCREEN_WIDTH - 20, 44, Constants.SCREEN_WIDTH - 15, 50)
    end
    if self.scrollOffset + self.maxVisibleItems < #self.stats then
        local arrowY = startY + self.maxVisibleItems * itemHeight - 8
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(Constants.SCREEN_WIDTH - 25, arrowY, Constants.SCREEN_WIDTH - 20, arrowY + 6, Constants.SCREEN_WIDTH - 15, arrowY)
    end

    -- Footer: BLACK background with white rule above and WHITE text
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setFooterFont()
    gfx.drawTextAligned("[D-pad] Navigate   [A] Purchase   [B] Back",
        Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw confirmation dialog if active
    if self.confirmingPurchase then
        self:drawConfirmDialog()
    end
end

function GrantFundingScreen:drawStatItem(stat, y, isSelected, funds)
    local itemWidth = Constants.SCREEN_WIDTH - 40
    local rowHeight = 42
    local leftPadding = 32
    local rightPadding = 32

    if isSelected then
        -- Selected: WHITE fill, BLACK text
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(20, y, itemWidth, rowHeight, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    else
        -- Unselected: BLACK fill, WHITE border, WHITE text
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(20, y, itemWidth, rowHeight, 4)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRoundRect(20, y, itemWidth, rowHeight, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    -- Stat name and level (first line)
    FontManager:setMenuFont()
    local levelText = "Lv " .. stat.currentLevel .. "/4"
    gfx.drawText("*" .. stat.data.name .. "*", leftPadding, y + 6)
    gfx.drawTextAligned("*" .. levelText .. "*", Constants.SCREEN_WIDTH - rightPadding, y + 6, kTextAlignment.right)

    -- Second line: next upgrade info or MAXED
    FontManager:setBodyFont()
    if stat.maxed then
        gfx.drawText("*MAXED OUT*", leftPadding, y + 24)
    else
        -- Show next upgrade and cost
        local costText = "Cost: " .. stat.cost
        local canAfford = funds >= stat.cost

        -- Show abbreviated next label
        local shortLabel = stat.nextLabel
        if #shortLabel > 22 then
            shortLabel = shortLabel:sub(1, 19) .. "..."
        end

        gfx.drawText(shortLabel, leftPadding, y + 24)

        -- Cost on right side: bold if affordable
        if canAfford then
            gfx.drawTextAligned("*" .. costText .. "*", Constants.SCREEN_WIDTH - rightPadding, y + 24, kTextAlignment.right)
        else
            gfx.drawTextAligned(costText, Constants.SCREEN_WIDTH - rightPadding, y + 24, kTextAlignment.right)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function GrantFundingScreen:drawConfirmDialog()
    local stat = self.stats[self.selectedIndex]
    if not stat then return end

    -- Dim background
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Dialog box: BLACK fill, WHITE double-line border
    local dialogW = 300
    local dialogH = 100
    local dialogX = (Constants.SCREEN_WIDTH - dialogW) / 2
    local dialogY = (Constants.SCREEN_HEIGHT - dialogH) / 2

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(dialogX, dialogY, dialogW, dialogH)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(dialogX, dialogY, dialogW, dialogH)
    gfx.drawRect(dialogX + 2, dialogY + 2, dialogW - 4, dialogH - 4)

    -- WHITE text on black dialog
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setMenuFont()
    gfx.drawTextAligned("*Purchase " .. stat.data.name .. " Upgrade?*", Constants.SCREEN_WIDTH / 2, dialogY + 15, kTextAlignment.center)
    FontManager:setBodyFont()
    gfx.drawTextAligned("*Cost: " .. stat.cost .. " Funds*", Constants.SCREEN_WIDTH / 2, dialogY + 35, kTextAlignment.center)
    gfx.drawTextAligned(stat.nextLabel, Constants.SCREEN_WIDTH / 2, dialogY + 52, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Yes/No buttons
    local yesX = dialogX + 60
    local noX = dialogX + dialogW - 100
    local buttonY = dialogY + dialogH - 28

    FontManager:setMenuFont()

    if self.confirmIndex == 1 then
        -- Yes selected: WHITE fill, BLACK text
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(yesX - 10, buttonY - 2, 60, 22, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.drawText("*Yes*", yesX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("*No*", noX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    else
        -- No selected: WHITE fill, BLACK text
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("*Yes*", yesX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(noX - 10, buttonY - 2, 60, 22, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        gfx.drawText("*No*", noX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

return GrantFundingScreen
