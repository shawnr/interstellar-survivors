-- Upgrade Selection UI
-- Shows 4 cards (2 tools, 2 bonus items) when player levels up

local gfx <const> = playdate.graphics

UpgradeSelection = {
    isVisible = false,
    selectedIndex = 1,
    options = {},
    onSelect = nil,
    scrollOffset = 0,  -- For scrolling when items don't fit
}

function UpgradeSelection:init()
    print("UpgradeSelection initialized")
end

function UpgradeSelection:show(tools, bonusItems, callback)
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.onSelect = callback
    self.options = {}

    -- Add tools (up to 2)
    for i = 1, math.min(2, #tools) do
        table.insert(self.options, {
            type = "tool",
            data = tools[i],
            icon = tools[i].iconPath and gfx.image.new(tools[i].iconPath) or nil
        })
    end

    -- Add bonus items (up to 2)
    for i = 1, math.min(2, #bonusItems) do
        table.insert(self.options, {
            type = "bonus",
            data = bonusItems[i],
            icon = bonusItems[i].iconPath and gfx.image.new(bonusItems[i].iconPath) or nil
        })
    end

    print("UpgradeSelection showing " .. #self.options .. " options")
end

function UpgradeSelection:hide()
    self.isVisible = false
    self.options = {}
    self.onSelect = nil
end

function UpgradeSelection:update()
    if not self.isVisible then return end

    if InputManager.buttonJustPressed.up then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.options end
    elseif InputManager.buttonJustPressed.down then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.options then self.selectedIndex = 1 end
    elseif InputManager.buttonJustPressed.a then
        self:confirmSelection()
    end
end

function UpgradeSelection:confirmSelection()
    if #self.options == 0 then return end
    local selected = self.options[self.selectedIndex]
    if self.onSelect then
        self.onSelect(selected.type, selected.data)
    end
    self:hide()
end

function UpgradeSelection:draw()
    if not self.isVisible then return end

    -- Layout constants
    local panelX, panelY = 10, 10
    local panelW, panelH = 380, 220
    local headerH = 30
    local footerH = 24
    local cardH = 50  -- Larger cards for better readability
    local cardMargin = 6
    local cardW = panelW - (cardMargin * 2)
    local contentAreaH = panelH - headerH - footerH

    -- Calculate scroll offset to keep selected item visible
    local maxVisibleCards = math.floor(contentAreaH / cardH)
    local selectedCardTop = (self.selectedIndex - 1) * cardH
    local selectedCardBottom = selectedCardTop + cardH

    -- Adjust scroll to keep selected in view
    if selectedCardTop < self.scrollOffset then
        self.scrollOffset = selectedCardTop
    elseif selectedCardBottom > self.scrollOffset + contentAreaH then
        self.scrollOffset = selectedCardBottom - contentAreaH
    end

    -- 1. Dim the background
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setDitherPattern(0)

    -- 2. Draw solid white panel
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(panelX, panelY, panelW, panelH)

    -- 3. Draw panel border (double line)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(panelX, panelY, panelW, panelH)
    gfx.drawRect(panelX + 2, panelY + 2, panelW - 4, panelH - 4)

    -- 4. Draw header background and text
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(panelX + 4, panelY + 4, panelW - 8, headerH - 4)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("*LEVEL UP!*", 200, panelY + 8, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- 5. Draw horizontal line under header
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(panelX + 4, panelY + headerH, panelX + panelW - 4, panelY + headerH)

    -- Set clip rect for scrolling content area
    local contentY = panelY + headerH + 2
    gfx.setClipRect(panelX + 4, contentY, panelW - 8, contentAreaH - 4)

    -- 6. Draw each card (with scroll offset)
    for i, option in ipairs(self.options) do
        local cardY = contentY + (i - 1) * cardH - self.scrollOffset
        local cardX = panelX + cardMargin
        local isSelected = (i == self.selectedIndex)

        -- Skip if card is outside visible area
        if cardY + cardH < contentY or cardY > contentY + contentAreaH then
            goto continue
        end

        -- Card background
        if isSelected then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        end

        -- Icon placeholder (left side)
        local iconX = cardX + 6
        local iconY = cardY + 4
        local iconSize = cardH - 12

        if option.icon then
            -- Icons are white on transparent - invert when on white background (not selected)
            if not isSelected then
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            option.icon:drawScaled(iconX, iconY, iconSize / 32)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        else
            if isSelected then
                gfx.setColor(gfx.kColorWhite)
            else
                gfx.setColor(gfx.kColorBlack)
            end
            gfx.drawRect(iconX, iconY, iconSize, iconSize)
        end

        -- Text (right of icon)
        local textX = iconX + iconSize + 10
        local textY = cardY + 6

        if isSelected then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        end

        -- Name and level (if tool)
        local name = option.data.name or "Unknown"
        local levelText = ""
        if option.type == "tool" and option.data.level then
            levelText = " Lv" .. option.data.level
        end
        gfx.drawText("*" .. name .. levelText .. "*", textX, textY)

        -- Description on second line
        local desc = option.data.description or ""
        gfx.drawText(desc, textX, textY + 18)

        -- Type badge on right
        local badge = option.type == "tool" and "[TOOL]" or "[BONUS]"
        gfx.drawTextAligned(badge, cardX + cardW - 10, textY, kTextAlignment.right)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        ::continue::
    end

    -- Clear clip rect
    gfx.clearClipRect()

    -- Draw footer line
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(panelX + 4, panelY + panelH - footerH, panelX + panelW - 4, panelY + panelH - footerH)

    -- 7. Draw instructions at bottom (with padding from edges)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(panelX + 6, panelY + panelH - footerH + 2, panelW - 12, footerH - 6)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("Up/Down: Select   Ⓐ: Confirm",
        200, panelY + panelH - footerH + 5, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function UpgradeSelection:getSelectedOption()
    if #self.options > 0 then
        return self.options[self.selectedIndex]
    end
    return nil
end

return UpgradeSelection
