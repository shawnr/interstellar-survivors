-- Upgrade Selection UI
-- Shows 4 cards (2 tools, 2 bonus items) when player levels up
-- Retro terminal aesthetic: black panels, white borders, inverted selection

local gfx <const> = playdate.graphics

UpgradeSelection = {
    isVisible = false,
    selectedIndex = 1,
    options = {},
    onSelect = nil,
    scrollOffset = 0,  -- For scrolling when items don't fit
}

function UpgradeSelection:init()
    Utils.debugPrint("UpgradeSelection initialized")
end

function UpgradeSelection:show(tools, bonusItems, callback)
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.crankAccum = 0  -- Reset crank accumulator
    self.onSelect = callback
    self.options = {}

    -- Add tools (up to 2)
    for i = 1, math.min(2, #tools) do
        local iconOnBlack = nil
        if tools[i].iconPath then
            local filename = tools[i].iconPath:match("([^/]+)$")
            iconOnBlack = gfx.image.new("images/icons_on_black/" .. filename)
        end
        table.insert(self.options, {
            type = "tool",
            data = tools[i],
            iconOnBlack = iconOnBlack,
        })
    end

    -- Add bonus items (up to 2)
    for i = 1, math.min(2, #bonusItems) do
        local iconOnBlack = nil
        if bonusItems[i].iconPath then
            local filename = bonusItems[i].iconPath:match("([^/]+)$")
            iconOnBlack = gfx.image.new("images/icons_on_black/" .. filename)
        end
        table.insert(self.options, {
            type = "bonus",
            data = bonusItems[i],
            iconOnBlack = iconOnBlack,
        })
    end

    Utils.debugPrint("UpgradeSelection showing " .. #self.options .. " options")
end

function UpgradeSelection:hide()
    self.isVisible = false
    self.options = {}
    self.onSelect = nil
end

function UpgradeSelection:update()
    if not self.isVisible then return end

    -- Initialize crank accumulator if not exists
    self.crankAccum = self.crankAccum or 0

    -- up/right = up, down/left = down
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.options end
        if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.options then self.selectedIndex = 1 end
        if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
    elseif InputManager.buttonJustPressed.a then
        self:confirmSelection()
    end

    -- Crank scrolling (accumulate degrees, move on threshold)
    local crankChange = playdate.getCrankChange()
    if crankChange ~= 0 then
        self.crankAccum = self.crankAccum + crankChange
        local threshold = 30  -- Degrees per selection change

        if self.crankAccum >= threshold then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.options then self.selectedIndex = 1 end
            self.crankAccum = 0
            if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
        elseif self.crankAccum <= -threshold then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = #self.options end
            self.crankAccum = 0
            if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
        end
    end
end

function UpgradeSelection:confirmSelection()
    if #self.options == 0 then return end
    if AudioManager then AudioManager:playSFX("card_confirm", 0.5) end
    local selected = self.options[self.selectedIndex]
    if self.onSelect then
        self.onSelect(selected.type, selected.data)
    end
    self:hide()
end

-- Helper function to draw A button icon (black circle with white A)
function UpgradeSelection:drawAButtonIcon(x, y, radius)
    radius = radius or 8
    -- Draw black filled circle
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y, radius)
    -- Draw white outline
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(x, y, radius)
    -- Draw white "A" centered in circle
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setBoldFont()
    local font = FontManager.boldFont
    local textW = font:getTextWidth("A")
    local textH = font:getHeight()
    gfx.drawText("A", x - textW/2, y - textH/2)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Helper function to get type text for a bonus item
function UpgradeSelection:getBonusTypeText(bonusData)
    if not bonusData.pairsWithTool then
        return "BONUS"
    end

    -- Look up the tool name
    local toolId = bonusData.pairsWithTool
    local toolData = ToolsData and ToolsData[toolId]
    if toolData then
        return "UPGR. " .. toolData.name
    else
        -- Fallback: format the tool ID nicely
        local toolName = toolId:gsub("_", " "):gsub("(%a)([%w_']*)", function(a, b) return string.upper(a) .. b end)
        return "UPGR. " .. toolName
    end
end

function UpgradeSelection:draw()
    if not self.isVisible then return end

    -- Layout constants
    local panelX, panelY = 10, 10
    local panelW, panelH = 380, 220
    local headerH = 30
    local footerH = 26
    local toolCardH = 54   -- Height for tool cards
    local bonusCardH = 68  -- Taller cards for bonus items (includes type line)
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

    -- 1. Dim the background (50% dither overlay)
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setDitherPattern(0)

    -- 2. Draw solid BLACK panel background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(panelX, panelY, panelW, panelH)

    -- 3. Draw WHITE panel border (double line for emphasis)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(panelX, panelY, panelW, panelH)
    gfx.drawRect(panelX + 2, panelY + 2, panelW - 4, panelH - 4)

    -- 4. Draw header text: "LEVEL UP!" in white on black
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("LEVEL UP!", 200, panelY + 8, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- 5. Draw white horizontal rule under header
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(panelX + 4, panelY + headerH, panelX + panelW - 4, panelY + headerH)

    -- Set clip rect for scrolling content area
    local contentY = panelY + headerH + 2
    gfx.setClipRect(panelX + 4, contentY, panelW - 8, contentAreaH - 4)

    -- Use body family for card text (supports *bold* markup)
    FontManager:setBodyFamily()

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

        if isSelected then
            -- Selected card: WHITE fill, BLACK text/border
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        else
            -- Unselected card: BLACK fill, WHITE border
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        end

        -- Icon (left side) - use fixed size for consistency
        local iconX = cardX + 6
        local iconY = cardY + 4
        local iconSize = 38  -- Fixed icon size

        -- Always draw a black background behind the icon for consistent appearance
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(iconX, iconY, iconSize, iconSize)

        -- Always use iconOnBlack (white icon on black background)
        local icon = option.iconOnBlack
        if icon then
            icon:drawScaled(iconX, iconY, iconSize / 32)
        else
            -- Fallback: draw white border if no icon available
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(iconX, iconY, iconSize, iconSize)
        end

        -- Text (right of icon)
        local textX = iconX + iconSize + 10
        local textY = cardY + 4

        if isSelected then
            -- Selected: BLACK text on white card
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            -- Unselected: WHITE text on black card
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- Name and level (if tool)
        local name = option.data.name or "Unknown"
        local levelText = ""
        if option.type == "tool" and option.data.level then
            levelText = " Lv" .. option.data.level
        end
        gfx.drawText("*" .. name .. levelText .. "*", textX, textY)

        -- Description on second line (increased spacing)
        local desc = option.data.description or ""
        gfx.drawText(desc, textX, textY + 18)

        -- For bonus items, show type text on third row (small bold, right-aligned)
        if option.type == "bonus" then
            local bonusText = self:getBonusTypeText(option.data)
            gfx.setFont(FontManager.smallBoldFont)
            gfx.drawTextAligned(bonusText, cardX + cardW - 10, textY + 36, kTextAlignment.right)
            FontManager:setBodyFamily()
        end

        -- Type badge on right
        local badge = option.type == "tool" and "[TOOL]" or "[ITEM]"
        gfx.drawTextAligned(badge, cardX + cardW - 10, textY, kTextAlignment.right)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        ::continue::
    end

    -- Clear clip rect
    gfx.clearClipRect()

    -- Draw white horizontal rule above footer
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(panelX + 4, panelY + panelH - footerH, panelX + panelW - 4, panelY + panelH - footerH)

    -- 7. Draw footer instructions: white text on black background
    FontManager:setFooterFont()

    local footerTextY = panelY + panelH - footerH + 3
    local footerCenterX = 200
    local iconRadius = 7

    -- Calculate positions for centered layout: "Up/Down: Select  (A): Confirm"
    local leftText = "Up/Down: Select   "
    local rightText = ": Confirm"
    local font = FontManager.footerFont
    local leftWidth = font:getTextWidth(leftText)
    local rightWidth = font:getTextWidth(rightText)
    local totalWidth = leftWidth + (iconRadius * 2) + rightWidth

    local startX = footerCenterX - totalWidth / 2

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(leftText, startX, footerTextY)

    -- Draw A button icon (black circle with white A)
    local iconCenterX = startX + leftWidth + iconRadius
    local iconCenterY = footerTextY + font:getHeight() / 2
    self:drawAButtonIcon(iconCenterX, iconCenterY, iconRadius)

    -- Draw rest of footer text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
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
