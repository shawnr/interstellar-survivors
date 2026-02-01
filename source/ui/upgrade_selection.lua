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

    -- up/right = up, down/left = down
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.options end
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
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

-- Helper function to draw A button icon (white circle with black A)
function UpgradeSelection:drawAButtonIcon(x, y, radius)
    radius = radius or 8
    -- Draw white filled circle
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, radius)
    -- Draw black outline
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(x, y, radius)
    -- Draw black "A" centered in circle
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    local font = gfx.getSystemFont(gfx.font.kVariantBold)
    gfx.setFont(font)
    local textW = font:getTextWidth("A")
    local textH = font:getHeight()
    gfx.drawText("A", x - textW/2, y - textH/2)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Helper function to get "Helps:" text for a bonus item
function UpgradeSelection:getHelpsText(bonusData)
    if not bonusData.pairsWithTool then
        return "Helps: All"
    end

    -- Look up the tool name
    local toolId = bonusData.pairsWithTool
    local toolData = ToolsData and ToolsData[toolId]
    if toolData then
        return "Helps: " .. toolData.name
    else
        -- Fallback: format the tool ID nicely
        local toolName = toolId:gsub("_", " "):gsub("(%a)([%w_']*)", function(a, b) return string.upper(a) .. b end)
        return "Helps: " .. toolName
    end
end

function UpgradeSelection:draw()
    if not self.isVisible then return end

    -- Layout constants
    local panelX, panelY = 10, 10
    local panelW, panelH = 380, 220
    local headerH = 30
    local footerH = 24
    local toolCardH = 50   -- Height for tool cards
    local bonusCardH = 64  -- Taller cards for bonus items (includes "Helps:" line)
    local cardMargin = 6
    local cardW = panelW - (cardMargin * 2)
    local contentAreaH = panelH - headerH - footerH

    -- Calculate total height and card positions based on variable heights
    local totalHeight = 0
    local cardPositions = {}
    for i, option in ipairs(self.options) do
        cardPositions[i] = totalHeight
        local cardH = option.type == "bonus" and bonusCardH or toolCardH
        totalHeight = totalHeight + cardH
    end

    -- Get selected card bounds
    local selectedCardTop = cardPositions[self.selectedIndex] or 0
    local selectedCardH = self.options[self.selectedIndex] and
        (self.options[self.selectedIndex].type == "bonus" and bonusCardH or toolCardH) or toolCardH
    local selectedCardBottom = selectedCardTop + selectedCardH

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

    -- 6. Draw each card (with scroll offset and variable heights)
    for i, option in ipairs(self.options) do
        local cardH = option.type == "bonus" and bonusCardH or toolCardH
        local cardY = contentY + cardPositions[i] - self.scrollOffset
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

        -- Icon placeholder (left side) - use fixed size for consistency
        local iconX = cardX + 6
        local iconY = cardY + 4
        local iconSize = 38  -- Fixed icon size

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
        local textY = cardY + 4

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
        gfx.drawText(desc, textX, textY + 16)

        -- For bonus items, show "Helps:" line on third row
        if option.type == "bonus" then
            local helpsText = self:getHelpsText(option.data)
            gfx.drawText(helpsText, textX, textY + 32)
        end

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

    -- Draw footer text with A button icon
    local footerTextY = panelY + panelH - footerH + 5
    local footerCenterX = 200
    local iconRadius = 7

    -- Calculate positions for centered layout: "Up/Down: Select  (A): Confirm"
    local leftText = "Up/Down: Select   "
    local rightText = ": Confirm"
    local font = gfx.getSystemFont()
    local leftWidth = font:getTextWidth(leftText)
    local rightWidth = font:getTextWidth(rightText)
    local totalWidth = leftWidth + (iconRadius * 2) + rightWidth

    local startX = footerCenterX - totalWidth / 2

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawText(leftText, startX, footerTextY)

    -- Draw A button icon
    local iconX = startX + leftWidth + iconRadius
    local iconY = footerTextY + font:getHeight() / 2
    self:drawAButtonIcon(iconX, iconY, iconRadius)

    -- Draw rest of text
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawText(rightText, startX + leftWidth + (iconRadius * 2), footerTextY)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function UpgradeSelection:getSelectedOption()
    if #self.options > 0 then
        return self.options[self.selectedIndex]
    end
    return nil
end

return UpgradeSelection
