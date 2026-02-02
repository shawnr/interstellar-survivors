-- Grant Funding Screen UI
-- Allows players to spend Grant Funds to upgrade station stats

local gfx <const> = playdate.graphics

GrantFundingScreen = {
    isVisible = false,
    selectedIndex = 1,
    stats = {},  -- Display data for each stat
    fromState = nil,
    patternBg = nil,
    confirmingPurchase = false,
    confirmIndex = 2,  -- Default to "No"
}

function GrantFundingScreen:init()
    self.patternBg = gfx.image.new("images/ui/menu_pattern_bg")
end

function GrantFundingScreen:show(fromState)
    self.isVisible = true
    self.selectedIndex = 1
    self.fromState = fromState or GameManager.states.TITLE
    self.confirmingPurchase = false
    self:refreshStats()

    if not self.patternBg then
        self.patternBg = gfx.image.new("images/ui/menu_pattern_bg")
    end
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
    elseif newIndex > #self.stats then
        newIndex = 1
    end

    if newIndex ~= self.selectedIndex then
        self.selectedIndex = newIndex
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
    gfx.drawTextAligned("*GRANT FUNDING*", Constants.SCREEN_WIDTH / 2, 6, kTextAlignment.center)

    -- Current funds display
    local funds = SaveManager:getGrantFunds()
    gfx.drawTextAligned("*Funds: " .. funds .. "*", Constants.SCREEN_WIDTH / 2, 22, kTextAlignment.center)

    -- Draw stats list
    local startY = 46
    local itemHeight = 46  -- Increased for better spacing between items

    for i, stat in ipairs(self.stats) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == self.selectedIndex)

        self:drawStatItem(stat, y, isSelected, funds)
    end

    -- Draw instructions at bottom
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
    gfx.drawTextAligned("*D-pad navigate   A purchase   B back*", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)

    -- Draw confirmation dialog if active
    if self.confirmingPurchase then
        self:drawConfirmDialog()
    end
end

function GrantFundingScreen:drawStatItem(stat, y, isSelected, funds)
    local itemWidth = Constants.SCREEN_WIDTH - 40
    local rowHeight = 42  -- Increased height for better margins
    local leftPadding = 32  -- More padding inside box
    local rightPadding = 32

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

    -- Stat name and level (first line with more top margin)
    local levelText = "Lv " .. stat.currentLevel .. "/4"
    gfx.drawText("*" .. stat.data.name .. "*", leftPadding, y + 6)
    gfx.drawTextAligned("*" .. levelText .. "*", Constants.SCREEN_WIDTH - rightPadding, y + 6, kTextAlignment.right)

    -- Second line: next upgrade info or MAXED (more spacing between lines)
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

        -- Cost on right side
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

    -- Dialog box
    local dialogW = 300
    local dialogH = 100
    local dialogX = (Constants.SCREEN_WIDTH - dialogW) / 2
    local dialogY = (Constants.SCREEN_HEIGHT - dialogH) / 2

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(dialogX, dialogY, dialogW, dialogH)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(dialogX, dialogY, dialogW, dialogH)
    gfx.drawRect(dialogX + 2, dialogY + 2, dialogW - 4, dialogH - 4)

    -- Text
    gfx.drawTextAligned("*Purchase " .. stat.data.name .. " Upgrade?*", Constants.SCREEN_WIDTH / 2, dialogY + 15, kTextAlignment.center)
    gfx.drawTextAligned("*Cost: " .. stat.cost .. " Funds*", Constants.SCREEN_WIDTH / 2, dialogY + 35, kTextAlignment.center)
    gfx.drawTextAligned(stat.nextLabel, Constants.SCREEN_WIDTH / 2, dialogY + 52, kTextAlignment.center)

    -- Yes/No buttons
    local yesX = dialogX + 60
    local noX = dialogX + dialogW - 100
    local buttonY = dialogY + dialogH - 28

    if self.confirmIndex == 1 then
        gfx.fillRoundRect(yesX - 10, buttonY - 2, 60, 22, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("*Yes*", yesX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.drawText("*No*", noX, buttonY)
    else
        gfx.drawText("*Yes*", yesX, buttonY)
        gfx.fillRoundRect(noX - 10, buttonY - 2, 60, 22, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("*No*", noX, buttonY)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

return GrantFundingScreen
