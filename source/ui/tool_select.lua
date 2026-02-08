-- Tool Selection UI
-- Shows a scrollable list of all tools (same style as Level Up menu)
-- Retro terminal aesthetic: black panels, white borders, inverted selection

local gfx <const> = playdate.graphics

ToolSelect = {
    isVisible = false,
    tools = {},
    selectedIndex = 1,
    scrollOffset = 0,
    crankAccum = 0,
    callback = nil,
}

function ToolSelect:init()
    self.isVisible = false
    self.tools = {}
    self.selectedIndex = 1
end

function ToolSelect:show(callback)
    self.callback = callback
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.crankAccum = 0

    -- Load all available tools
    self.tools = {}
    local toolOrder = {
        "rail_driver", "frequency_scanner", "tractor_pulse", "thermal_lance",
        "cryo_projector", "emp_burst", "probe_launcher", "repulsor_field",
        "modified_mapping_drone", "singularity_core", "plasma_sprayer",
        "tesla_coil", "micro_missile_pod", "phase_disruptor"
    }

    for _, toolId in ipairs(toolOrder) do
        local toolData = ToolsData[toolId]
        if toolData then
            local iconOnBlack = nil
            local iconPath = toolData.iconPath or toolData.imagePath
            if iconPath then
                local filename = iconPath:match("([^/]+)$")
                iconOnBlack = gfx.image.new("images/icons_on_black/" .. filename)
            end
            self.tools[#self.tools + 1] = {
                id = toolId,
                data = toolData,
                iconOnBlack = iconOnBlack,
            }
        end
    end

    Utils.debugPrint("ToolSelect: Loaded " .. #self.tools .. " tools")
end

function ToolSelect:hide()
    self.isVisible = false
    self.tools = {}
end

function ToolSelect:update()
    if not self.isVisible then return end

    -- up/right = up, down/left = down (matches Level Up menu)
    if InputManager.buttonJustPressed.up or InputManager.buttonJustPressed.right then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.tools end
        if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
    elseif InputManager.buttonJustPressed.down or InputManager.buttonJustPressed.left then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.tools then self.selectedIndex = 1 end
        if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
    elseif InputManager.buttonJustPressed.a then
        local selectedTool = self.tools[self.selectedIndex]
        if selectedTool and self.callback then
            if AudioManager then AudioManager:playSFX("card_confirm", 0.5) end
            self.callback(selectedTool.id)
        end
        self:hide()
    end

    -- Crank scrolling (accumulate degrees, move on threshold)
    local crankChange = playdate.getCrankChange()
    if crankChange ~= 0 then
        self.crankAccum = self.crankAccum + crankChange
        local threshold = 30

        if self.crankAccum >= threshold then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.tools then self.selectedIndex = 1 end
            self.crankAccum = 0
            if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
        elseif self.crankAccum <= -threshold then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = #self.tools end
            self.crankAccum = 0
            if AudioManager then AudioManager:playSFX("menu_move", 0.5) end
        end
    end
end

-- Helper function to draw A button icon (black circle with white A)
function ToolSelect:drawAButtonIcon(x, y, radius)
    radius = radius or 8
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y, radius)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(x, y, radius)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setBoldFont()
    local font = FontManager.boldFont
    local textW = font:getTextWidth("A")
    local textH = font:getHeight()
    gfx.drawText("A", x - textW/2, y - textH/2)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function ToolSelect:draw()
    if not self.isVisible then return end

    -- Layout constants (matches Level Up menu style)
    local panelX, panelY = 10, 10
    local panelW, panelH = 380, 220
    local headerH = 30
    local footerH = 26
    local cardH = 50
    local cardMargin = 6
    local cardW = panelW - (cardMargin * 2)
    local contentAreaH = panelH - headerH - footerH

    -- Calculate card positions
    local cardPositions = {}
    for i = 1, #self.tools do
        cardPositions[i] = (i - 1) * cardH
    end

    -- Get selected card bounds
    local selectedCardTop = cardPositions[self.selectedIndex] or 0
    local selectedCardBottom = selectedCardTop + cardH

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

    -- 4. Draw header text
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("CHOOSE STARTING TOOL", 200, panelY + 8, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- 5. Draw white horizontal rule under header
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(panelX + 4, panelY + headerH, panelX + panelW - 4, panelY + headerH)

    -- Set clip rect for scrolling content area
    local contentY = panelY + headerH + 2
    gfx.setClipRect(panelX + 4, contentY, panelW - 8, contentAreaH - 4)

    -- Use body family for card text (supports *bold* markup)
    FontManager:setBodyFamily()

    -- 6. Draw each card (with scroll offset)
    for i, tool in ipairs(self.tools) do
        local cardY = contentY + cardPositions[i] - self.scrollOffset
        local cardX = panelX + cardMargin
        local isSelected = (i == self.selectedIndex)

        -- Skip if card is outside visible area
        if cardY + cardH < contentY or cardY > contentY + contentAreaH then
            goto continue
        end

        if isSelected then
            -- Selected card: WHITE fill, BLACK text
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        else
            -- Unselected card: BLACK fill, WHITE border
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(cardX, cardY, cardW, cardH - 4, 4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRoundRect(cardX, cardY, cardW, cardH - 4, 4)
        end

        -- Icon (left side)
        local iconX = cardX + 6
        local iconY = cardY + 4
        local iconSize = 38

        -- Black background behind icon
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(iconX, iconY, iconSize, iconSize)

        -- Draw icon
        local icon = tool.iconOnBlack
        if icon then
            local iconW, iconH = icon:getSize()
            local scale = iconSize / math.max(iconW, iconH)
            icon:drawScaled(iconX, iconY, scale)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(iconX, iconY, iconSize, iconSize)
        end

        -- Text (right of icon)
        local textX = iconX + iconSize + 10
        local textY = cardY + 4

        if isSelected then
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        -- Name
        local name = tool.data.name or "Unknown"
        gfx.drawText("*" .. name .. "*", textX, textY)

        -- Description on second line
        local desc = tool.data.description or ""
        gfx.drawText(desc, textX, textY + 16)

        -- [TOOL] badge on right
        gfx.drawTextAligned("[TOOL]", cardX + cardW - 10, textY, kTextAlignment.right)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        ::continue::
    end

    -- Clear clip rect
    gfx.clearClipRect()

    -- Draw white horizontal rule above footer
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(panelX + 4, panelY + panelH - footerH, panelX + panelW - 4, panelY + panelH - footerH)

    -- 7. Draw footer instructions
    FontManager:setFooterFont()

    local footerTextY = panelY + panelH - footerH + 3

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("Up/Down: Select   A: Confirm", 200, footerTextY, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return ToolSelect
