-- Upgrade Selection UI
-- Shows 4 cards (2 tools, 2 bonus items) when player levels up

local gfx <const> = playdate.graphics

UpgradeSelection = {
    isVisible = false,
    selectedIndex = 1,
    options = {},
    onSelect = nil,
}

function UpgradeSelection:init()
    print("UpgradeSelection initialized")
end

function UpgradeSelection:show(tools, bonusItems, callback)
    self.isVisible = true
    self.selectedIndex = 1
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
    local panelX, panelY = 20, 20
    local panelW, panelH = 360, 200
    local headerH = 26
    local cardH = 38
    local cardMargin = 4
    local cardW = panelW - (cardMargin * 2)

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

    -- 4. Draw header
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("*LEVEL UP!*", 200, panelY + 6, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- 5. Draw horizontal line under header
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(panelX + 4, panelY + headerH, panelX + panelW - 4, panelY + headerH)

    -- 6. Draw each card
    for i, option in ipairs(self.options) do
        local cardY = panelY + headerH + 2 + (i - 1) * cardH
        local cardX = panelX + cardMargin
        local isSelected = (i == self.selectedIndex)

        -- Card background
        if isSelected then
            -- Selected: black fill
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(cardX, cardY, cardW, cardH - 2)
        else
            -- Unselected: white fill with black border
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(cardX, cardY, cardW, cardH - 2)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(cardX, cardY, cardW, cardH - 2)
        end

        -- Icon placeholder (left side)
        local iconX = cardX + 4
        local iconY = cardY + 2
        local iconSize = cardH - 6

        if option.icon then
            if isSelected then
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
        local textX = iconX + iconSize + 8
        local textY = cardY + 4

        if isSelected then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        end

        -- Name
        local name = option.data.name or "Unknown"
        gfx.drawText("*" .. name .. "*", textX, textY)

        -- Description
        local desc = option.data.description or ""
        gfx.drawText(desc, textX, textY + 16)

        -- Type badge on right
        local badge = option.type == "tool" and "[TOOL]" or "[BONUS]"
        gfx.drawTextAligned(badge, cardX + cardW - 8, textY, kTextAlignment.right)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- 7. Draw instructions at bottom
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("Up/Down: Select   A: Confirm",
        200, panelY + panelH - 16, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function UpgradeSelection:getSelectedOption()
    if #self.options > 0 then
        return self.options[self.selectedIndex]
    end
    return nil
end

return UpgradeSelection
