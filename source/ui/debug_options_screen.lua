-- Creative Options Screen
-- Allows configuration of creative mode settings (unlocks, god mode, etc.)

local gfx <const> = playdate.graphics

DebugOptionsScreen = {
    isVisible = false,
    selectedIndex = 1,
    fromState = nil,
    patternBg = nil,
    scrollOffset = 0,
}

function DebugOptionsScreen:init()
    self.isVisible = false
    self.selectedIndex = 1
    self.scrollOffset = 0
end

-- Menu items configuration
DebugOptionsScreen.menuItems = {
    { label = "Episode Length", key = "episodeLength", type = "time", min = 30, max = 420, step = 30 },
    { label = "Wave Length", key = "waveLength", type = "time", min = 5, max = 60, step = 5 },
    { label = "Difficulty", key = "difficultyMultiplier", type = "multiplier", min = 0.25, max = 3.0, step = 0.25 },
    { label = "Station Invincible", key = "stationInvincible", type = "toggle" },
    { label = "Tool Placement", key = "toolPlacementEnabled", type = "toggle" },
    { label = "Unlock All Equipment", key = "unlockAllEquipment", type = "toggle" },
    { label = "Unlock All Episodes", key = "unlockAllEpisodes", type = "toggle" },
    { label = "Unlock All Database", key = "unlockAllDatabase", type = "toggle" },
    { label = "Unlock All Research", key = "unlockAllResearchSpecs", type = "toggle" },
    { label = "Back", type = "action", action = "back" },
}

function DebugOptionsScreen:show(fromState)
    self.isVisible = true
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.fromState = fromState or GameManager.states.SETTINGS
    self.patternBg = gfx.image.new("images/ui/menu_pattern_bg")
end

function DebugOptionsScreen:hide()
    self.isVisible = false
    self.patternBg = nil
end

function DebugOptionsScreen:update()
    if not self.isVisible then return end

    -- Layout constants
    local startY = 48
    local itemHeight = 24
    local contentTop = 48
    local contentBottom = Constants.SCREEN_HEIGHT - 22 - itemHeight  -- Leave room for one item above footer

    -- Navigation
    if InputManager.buttonJustPressed.up then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.menuItems
        end
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    elseif InputManager.buttonJustPressed.down then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.menuItems then
            self.selectedIndex = 1
        end
        if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
    end

    -- Auto-scroll to keep selected item visible
    local selectedY = startY + (self.selectedIndex - 1) * itemHeight - self.scrollOffset
    if selectedY < contentTop then
        self.scrollOffset = self.scrollOffset - (contentTop - selectedY)
    elseif selectedY > contentBottom then
        self.scrollOffset = self.scrollOffset + (selectedY - contentBottom)
    end
    self.scrollOffset = math.max(0, self.scrollOffset)

    -- Handle selected item
    local item = self.menuItems[self.selectedIndex]

    if item.type == "time" then
        local currentValue = SaveManager:getDebugSetting(item.key, item.min)

        if InputManager.buttonJustPressed.left then
            currentValue = math.max(item.min, currentValue - item.step)
            SaveManager:setDebugSetting(item.key, currentValue)
            SaveManager:flush()
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        elseif InputManager.buttonJustPressed.right then
            currentValue = math.min(item.max, currentValue + item.step)
            SaveManager:setDebugSetting(item.key, currentValue)
            SaveManager:flush()
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        end
    elseif item.type == "multiplier" then
        local currentValue = SaveManager:getDebugSetting(item.key, 1.0)

        if InputManager.buttonJustPressed.left then
            currentValue = math.max(item.min, currentValue - item.step)
            -- Round to avoid floating point issues
            currentValue = math.floor(currentValue * 100 + 0.5) / 100
            SaveManager:setDebugSetting(item.key, currentValue)
            SaveManager:flush()
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        elseif InputManager.buttonJustPressed.right then
            currentValue = math.min(item.max, currentValue + item.step)
            -- Round to avoid floating point issues
            currentValue = math.floor(currentValue * 100 + 0.5) / 100
            SaveManager:setDebugSetting(item.key, currentValue)
            SaveManager:flush()
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        end
    elseif item.type == "toggle" then
        if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.left or InputManager.buttonJustPressed.right then
            local currentValue = SaveManager:getDebugSetting(item.key, true)
            SaveManager:setDebugSetting(item.key, not currentValue)
            SaveManager:flush()
            if AudioManager then AudioManager:playSFX("menu_select", 0.3) end
        end
    elseif item.type == "action" then
        if InputManager.buttonJustPressed.a then
            if item.action == "back" then
                if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
                GameManager:setState(self.fromState)
            end
        end
    end

    -- B button always goes back
    if InputManager.buttonJustPressed.b then
        if AudioManager then AudioManager:playSFX("menu_back", 0.3) end
        GameManager:setState(self.fromState)
    end
end

function DebugOptionsScreen:draw()
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
    gfx.drawTextAligned("*CREATIVE OPTIONS*", Constants.SCREEN_WIDTH / 2, 12, kTextAlignment.center)

    -- Draw menu items with scrolling
    local startY = 48
    local itemHeight = 24
    local contentTop = 48
    local contentBottom = Constants.SCREEN_HEIGHT - 22

    -- Set clip rect to content area (between title and footer)
    gfx.setClipRect(0, contentTop, Constants.SCREEN_WIDTH, contentBottom - contentTop)

    for i, item in ipairs(self.menuItems) do
        local y = startY + (i - 1) * itemHeight - self.scrollOffset
        local isSelected = (i == self.selectedIndex)

        -- Skip if off-screen
        if y + 20 >= contentTop and y - 2 < contentBottom then
            -- Row background
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 20)

            -- Selection indicator or border
            gfx.setColor(gfx.kColorBlack)
            if isSelected then
                gfx.fillRoundRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 20, 3)
            else
                gfx.drawRoundRect(20, y - 2, Constants.SCREEN_WIDTH - 40, 20, 3)
            end

            -- Set text mode
            if isSelected then
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            else
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end

            if item.type == "time" then
                local value = SaveManager:getDebugSetting(item.key, item.min)
                local timeStr = self:formatTime(value)

                gfx.drawText(item.label, 30, y)
                gfx.drawTextAligned("< " .. timeStr .. " >", Constants.SCREEN_WIDTH - 30, y, kTextAlignment.right)

            elseif item.type == "multiplier" then
                local value = SaveManager:getDebugSetting(item.key, 1.0)
                local valueStr = string.format("%.2fx", value)

                gfx.drawText(item.label, 30, y)
                gfx.drawTextAligned("< " .. valueStr .. " >", Constants.SCREEN_WIDTH - 30, y, kTextAlignment.right)

            elseif item.type == "toggle" then
                local value = SaveManager:getDebugSetting(item.key, true)
                local toggleText = value and "ON" or "OFF"

                gfx.drawText(item.label, 30, y)
                gfx.drawTextAligned(toggleText, Constants.SCREEN_WIDTH - 30, y, kTextAlignment.right)

            elseif item.type == "action" then
                gfx.drawTextAligned("*" .. item.label .. "*", Constants.SCREEN_WIDTH / 2, y, kTextAlignment.center)
            end

            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end

    gfx.clearClipRect()

    -- Instructions bar at bottom
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, Constants.SCREEN_HEIGHT - 22, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT - 22)
    gfx.drawTextAligned("D-pad: Navigate/Adjust   A: Toggle   B: Back", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 16, kTextAlignment.center)
end

-- Format seconds as M:SS
function DebugOptionsScreen:formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", mins, secs)
end

return DebugOptionsScreen
