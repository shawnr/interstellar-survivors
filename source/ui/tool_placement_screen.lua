-- Tool Placement Screen
-- Allows player to choose which slot to attach a new tool to
-- Roulette-style: slots rotate past a fixed selection point at 3 o'clock

local gfx <const> = playdate.graphics

ToolPlacementScreen = {
    isVisible = false,
    toolData = nil,
    toolIcon = nil,
    onConfirm = nil,

    -- Station rotation (visual)
    rotation = 0,

    -- Slot data
    usedSlots = {},
    slotIcons = {},  -- Icons for equipped tools

    -- Confirmation state
    isConfirming = false,

    -- Animation
    pulseTimer = 0,
}

function ToolPlacementScreen:init()
    print("ToolPlacementScreen initialized")
end

function ToolPlacementScreen:show(toolData, station, callback)
    self.isVisible = true
    self.toolData = toolData
    self.onConfirm = callback
    self.isConfirming = false
    self.pulseTimer = 0

    -- Derive used slots directly from the tools array (more reliable than copying usedSlots)
    self.usedSlots = {}
    self.slotIcons = {}

    for _, tool in ipairs(station.tools) do
        if tool.slotIndex ~= nil then
            -- Mark slot as used
            self.usedSlots[tool.slotIndex] = true

            -- Load icon with fallback chain - try multiple sources
            local iconPath = nil
            local toolId = nil

            -- Try tool.data first (instance data)
            if tool.data then
                iconPath = tool.data.iconPath or tool.data.imagePath
                toolId = tool.data.id
            end

            -- Fallback: try class DATA if instance data missing
            if not iconPath and tool.DATA then
                iconPath = tool.DATA.iconPath or tool.DATA.imagePath
                toolId = tool.DATA.id
            end

            if iconPath then
                local filename = iconPath:match("([^/]+)$")
                -- Try icons_on_black first
                local icon = gfx.image.new("images/icons_on_black/" .. filename)
                -- Fall back to tools folder
                if not icon then
                    icon = gfx.image.new(iconPath)
                end
                self.slotIcons[tool.slotIndex] = icon

                if not icon then
                    print("WARNING: Failed to load icon for slot " .. tool.slotIndex .. " (tool: " .. (toolId or "unknown") .. ")")
                end
            else
                print("WARNING: No iconPath for tool in slot " .. tool.slotIndex)
            end
        end
    end

    -- Load the new tool icon (larger version for left panel) with fallback
    local newToolIconPath = toolData.iconPath or toolData.imagePath
    if newToolIconPath then
        local filename = newToolIconPath:match("([^/]+)$")
        self.toolIcon = gfx.image.new("images/icons_on_black/" .. filename)
        if not self.toolIcon then
            self.toolIcon = gfx.image.new(newToolIconPath)
        end
    end

    -- Start rotation so an available slot is at 3 o'clock (90 degrees)
    local firstAvailable = self:getFirstAvailableSlot()
    local slotAngle = Constants.TOOL_SLOTS[firstAvailable].angle
    self.rotation = 90 - slotAngle
end

function ToolPlacementScreen:hide()
    self.isVisible = false
    self.toolData = nil
    self.toolIcon = nil
    self.slotIcons = {}
    self.onConfirm = nil
end

function ToolPlacementScreen:getFirstAvailableSlot()
    for i = 0, Constants.STATION_SLOTS - 1 do
        if not self.usedSlots[i] then
            return i
        end
    end
    return 0
end

function ToolPlacementScreen:getSlotAtSelectionPoint()
    -- Selection point is at 3 o'clock (90 degrees)
    local selectionAngle = 90
    local closestSlot = 0
    local closestDiff = 360

    for i = 0, Constants.STATION_SLOTS - 1 do
        local slotBaseAngle = Constants.TOOL_SLOTS[i].angle
        local slotAngle = (slotBaseAngle + self.rotation) % 360
        if slotAngle < 0 then slotAngle = slotAngle + 360 end
        local diff = math.abs(slotAngle - selectionAngle)
        if diff > 180 then diff = 360 - diff end

        if diff < closestDiff then
            closestDiff = diff
            closestSlot = i
        end
    end

    return closestSlot, closestDiff
end

function ToolPlacementScreen:rotateToNextAvailable(direction)
    local currentSlot = self:getSlotAtSelectionPoint()

    local nextSlot = currentSlot
    for _ = 1, Constants.STATION_SLOTS do
        nextSlot = (nextSlot + direction) % Constants.STATION_SLOTS
        if not self.usedSlots[nextSlot] then
            local slotAngle = Constants.TOOL_SLOTS[nextSlot].angle
            self.rotation = 90 - slotAngle
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
            return
        end
    end
end

function ToolPlacementScreen:update()
    if not self.isVisible then return end

    self.pulseTimer = self.pulseTimer + (1/30)

    -- Handle crank rotation
    local crankChange = playdate.getCrankChange()
    if math.abs(crankChange) > 1 then
        self.rotation = self.rotation + crankChange
    end

    local selectedSlot = self:getSlotAtSelectionPoint()

    if self.isConfirming then
        if InputManager.buttonJustPressed.a then
            if not self.usedSlots[selectedSlot] then
                if AudioManager then AudioManager:playSFX("menu_confirm", 0.4) end
                if self.onConfirm then
                    self.onConfirm(selectedSlot)
                end
                self:hide()
            end
        elseif InputManager.buttonJustPressed.b then
            if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
            self.isConfirming = false
        end
    else
        if InputManager.buttonJustPressed.left or InputManager.buttonJustPressed.up then
            self:rotateToNextAvailable(-1)
        elseif InputManager.buttonJustPressed.right or InputManager.buttonJustPressed.down then
            self:rotateToNextAvailable(1)
        elseif InputManager.buttonJustPressed.a then
            if not self.usedSlots[selectedSlot] then
                if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
                self.isConfirming = true
            end
        end
    end
end

function ToolPlacementScreen:draw()
    if not self.isVisible then return end

    -- Dim background
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setDitherPattern(0)

    -- Draw panel
    local panelX, panelY = 40, 30
    local panelW, panelH = 320, 180

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(panelX, panelY, panelW, panelH)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(panelX, panelY, panelW, panelH)
    gfx.drawRect(panelX + 2, panelY + 2, panelW - 4, panelH - 4)

    -- Title
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("*TOOL PLACEMENT*", 200, panelY + 10, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Horizontal line under title
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(panelX + 4, panelY + 28, panelX + panelW - 4, panelY + 28)

    -- LEFT SIDE: Tool info (icon on top, text below with wrapping)
    local dividerX = panelX + 150
    local leftColumnWidth = dividerX - panelX - 16  -- Width with padding
    local leftCenterX = panelX + (dividerX - panelX) / 2

    -- Tool icon (larger, centered)
    local iconY = panelY + 40
    if self.toolIcon then
        local iconW, iconH = self.toolIcon:getSize()
        local iconScale = 1.5
        local scaledW = iconW * iconScale
        local scaledH = iconH * iconScale
        self.toolIcon:drawScaled(leftCenterX - scaledW / 2, iconY, iconScale)
        iconY = iconY + scaledH + 6
    end

    -- Tool name (centered, below icon)
    local toolName = self.toolData and self.toolData.name or "Tool"
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("*" .. toolName .. "*", leftCenterX, iconY, kTextAlignment.center)

    -- Description (wrapped text, below name)
    local desc = self.toolData and self.toolData.description or ""
    local textX = panelX + 8
    local textY = iconY + 18
    local textWidth = leftColumnWidth
    local textHeight = 50  -- Allow for wrapping
    gfx.drawTextInRect(desc, textX, textY, textWidth, textHeight, nil, nil, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Vertical divider line
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(dividerX, panelY + 35, dividerX, panelY + panelH - 30)

    -- RIGHT SIDE: Rotating slot wheel
    local selectedSlot = self:getSlotAtSelectionPoint()
    local centerX = panelX + 235
    local centerY = panelY + 95
    local slotRadius = 38
    local slotSize = 20

    -- Draw center dot
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(centerX, centerY, 3)

    -- Draw each slot
    for i = 0, Constants.STATION_SLOTS - 1 do
        local slotBaseAngle = Constants.TOOL_SLOTS[i].angle
        local slotAngle = Utils.degToRad(slotBaseAngle + self.rotation)

        local slotX = centerX + math.cos(slotAngle) * slotRadius
        local slotY = centerY + math.sin(slotAngle) * slotRadius

        local isUsed = self.usedSlots[i]
        local isAtSelectionPoint = (i == selectedSlot)

        -- Pulsing for selection point slot
        local pulse = 0
        if isAtSelectionPoint and not isUsed then
            pulse = math.sin(self.pulseTimer * 6) * 2
        end

        local drawSize = slotSize + pulse

        -- Draw connecting line
        gfx.setColor(gfx.kColorBlack)
        local lineEndX = centerX + math.cos(slotAngle) * 6
        local lineEndY = centerY + math.sin(slotAngle) * 6
        gfx.drawLine(lineEndX, lineEndY, slotX - math.cos(slotAngle) * (drawSize/2), slotY - math.sin(slotAngle) * (drawSize/2))

        -- Draw slot
        if isUsed then
            -- Occupied slot with tool icon
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(slotX, slotY, drawSize / 2)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(slotX, slotY, drawSize / 2)

            local icon = self.slotIcons[i]
            if icon then
                local iconW, iconH = icon:getSize()
                local iconScale = (drawSize - 4) / math.max(iconW, iconH)
                icon:drawScaled(slotX - iconW * iconScale / 2, slotY - iconH * iconScale / 2, iconScale)
            else
                -- Fallback: draw "X" if icon failed to load
                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
                gfx.drawTextAligned("X", slotX, slotY - 5, kTextAlignment.center)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end
        elseif isAtSelectionPoint then
            -- Selected available slot (at 3 o'clock)
            if self.isConfirming then
                if math.floor(self.pulseTimer * 8) % 2 == 0 then
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillCircleAtPoint(slotX, slotY, drawSize / 2)
                else
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillCircleAtPoint(slotX, slotY, drawSize / 2)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.setLineWidth(2)
                    gfx.drawCircleAtPoint(slotX, slotY, drawSize / 2)
                    gfx.setLineWidth(1)
                end
            else
                -- Show new tool icon preview in selected slot
                gfx.setColor(gfx.kColorWhite)
                gfx.fillCircleAtPoint(slotX, slotY, drawSize / 2)
                gfx.setColor(gfx.kColorBlack)
                gfx.setLineWidth(2)
                gfx.drawCircleAtPoint(slotX, slotY, drawSize / 2)
                gfx.setLineWidth(1)

                if self.toolIcon then
                    local iconW, iconH = self.toolIcon:getSize()
                    local iconScale = (drawSize - 4) / math.max(iconW, iconH)
                    self.toolIcon:drawScaled(slotX - iconW * iconScale / 2, slotY - iconH * iconScale / 2, iconScale)
                end
            end
        else
            -- Empty available slot
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(slotX, slotY, drawSize / 2)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(slotX, slotY, drawSize / 2)

            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            gfx.drawTextAligned("+", slotX, slotY - 5, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end

    -- Footer line
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(panelX + 4, panelY + panelH - 24, panelX + panelW - 4, panelY + panelH - 24)

    -- Instructions
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    if self.isConfirming then
        gfx.drawTextAligned("A: Confirm   B: Back", 200, panelY + panelH - 18, kTextAlignment.center)
    else
        gfx.drawTextAligned("D-Pad/Crank: Rotate   A: Place", 200, panelY + panelH - 18, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return ToolPlacementScreen
