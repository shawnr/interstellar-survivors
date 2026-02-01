-- Story Panel UI
-- Displays intro and ending story panels for episodes
-- Per design doc: Shows text line by line (5 sec each) on white bar at bottom

local gfx <const> = playdate.graphics

StoryPanel = {
    isVisible = false,
    panels = {},        -- Array of panel data {image, lines}
    currentPanel = 1,
    currentLine = 0,    -- Which line of text we're showing (0 = none, 1+ = showing that line)
    onComplete = nil,   -- Callback when all panels viewed
    inputDelay = 0,     -- Brief delay before accepting input
    lineTimer = 0,      -- Timer for auto-advancing lines (5 seconds)
    allLinesShown = false,  -- Whether all lines have been shown for current panel
    LINE_DISPLAY_TIME = 5.0,  -- Seconds to show each line before auto-advance
}

function StoryPanel:init()
    print("StoryPanel initialized")
end

-- Show story panels
-- panelData: array of {imagePath, lines} tables where lines is array of strings
-- callback: function to call when done
function StoryPanel:show(panelData, callback)
    self.isVisible = true
    self.currentPanel = 1
    self.currentLine = 0
    self.onComplete = callback
    self.panels = {}
    self.inputDelay = 0.3  -- Delay before accepting input
    self.lineTimer = 0
    self.allLinesShown = false

    -- Load panel images
    for i, data in ipairs(panelData) do
        local panel = {
            image = data.imagePath and gfx.image.new(data.imagePath) or nil,
            lines = data.lines or {},  -- Array of text lines
            -- Legacy support: convert single text to lines
            text = data.text or nil
        }
        -- If old-style single text, convert to single line
        if panel.text and #panel.lines == 0 then
            panel.lines = {panel.text}
        end
        table.insert(self.panels, panel)
    end

    print("StoryPanel showing " .. #self.panels .. " panels")

    -- Start showing first line (will also play audio hit)
    self:startNextLine()
end

function StoryPanel:hide()
    self.isVisible = false
    self.panels = {}
    self.currentPanel = 1
    self.currentLine = 0
    self.onComplete = nil
    self.inputDelay = 0
    self.lineTimer = 0
    self.allLinesShown = false
end

-- Play a random audio hit from the hits folder
function StoryPanel:playRandomHit()
    local hitNum = math.random(1, 5)
    local hitPath = "sounds/hits/" .. hitNum
    -- Try to play the hit sound directly
    local hitSound = playdate.sound.sampleplayer.new(hitPath)
    if hitSound then
        hitSound:setVolume(0.8)
        hitSound:play()
    end
end

function StoryPanel:startNextLine()
    self.currentLine = self.currentLine + 1
    self.lineTimer = 0
    self.inputDelay = 0.2  -- Small delay to prevent accidental double-press

    local panel = self.panels[self.currentPanel]
    if not panel then return end

    if self.currentLine > #panel.lines then
        -- All lines shown, wait for button press to continue
        self.allLinesShown = true
        self.currentLine = #panel.lines  -- Keep showing last line
    else
        -- Play audio hit for new line
        self:playRandomHit()
    end
end

function StoryPanel:update()
    if not self.isVisible then return end

    local dt = 1/30  -- Assuming 30fps

    -- Decrement input delay
    if self.inputDelay > 0 then
        self.inputDelay = self.inputDelay - dt
        return  -- Don't accept input during delay
    end

    -- If showing lines, timer advances them
    if not self.allLinesShown then
        self.lineTimer = self.lineTimer + dt
        if self.lineTimer >= self.LINE_DISPLAY_TIME then
            self:startNextLine()
        end
    end

    -- A or B button advances
    if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.b then
        if self.allLinesShown then
            -- Move to next panel
            self:nextPanel()
        else
            -- Show next line immediately
            self:startNextLine()
        end
    end
end

function StoryPanel:nextPanel()
    print("StoryPanel:nextPanel() - advancing from panel " .. self.currentPanel .. " of " .. #self.panels)
    self.currentPanel = self.currentPanel + 1
    self.currentLine = 0
    self.allLinesShown = false
    self.lineTimer = 0
    self.inputDelay = 0.3

    if self.currentPanel > #self.panels then
        -- Done with all panels
        print("StoryPanel: All panels complete, calling callback")
        local callback = self.onComplete
        self:hide()
        if callback then
            callback()
        end
    else
        print("StoryPanel: Now showing panel " .. self.currentPanel)
        -- Start showing first line (will also play audio hit)
        self:startNextLine()
    end
end

function StoryPanel:draw()
    if not self.isVisible then return end
    if #self.panels == 0 then return end

    local panel = self.panels[self.currentPanel]
    if not panel then return end

    -- Clear screen with black
    gfx.clear(gfx.kColorBlack)

    -- Draw panel image (full screen or centered)
    if panel.image then
        local imgW, imgH = panel.image:getSize()
        local x = (Constants.SCREEN_WIDTH - imgW) / 2
        local y = 10
        panel.image:draw(x, y)
    end

    -- Draw current line on white bar at bottom
    if self.currentLine > 0 and self.currentLine <= #panel.lines then
        local line = panel.lines[self.currentLine]
        if line and line ~= "" then
            local barPadding = 10
            local maxTextWidth = Constants.SCREEN_WIDTH - (barPadding * 2)

            -- Measure text to determine if wrapping is needed
            local textWidth, textHeight = gfx.getTextSize(line)
            local needsWrap = (#line > 40) or (textWidth > maxTextWidth)

            -- Dynamic bar height - taller if text needs wrapping
            local barHeight = needsWrap and 48 or 32
            local barY = Constants.SCREEN_HEIGHT - barHeight - 14  -- Room for prompt below

            -- Draw white bar background
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, barY, Constants.SCREEN_WIDTH, barHeight)

            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

            if needsWrap then
                -- Long text - wrap it using drawTextInRect
                -- Calculate wrapped height to center vertically
                local wrappedW, wrappedH = gfx.getTextSizeForMaxWidth(line, maxTextWidth)
                local textY = barY + (barHeight - wrappedH) / 2
                gfx.drawTextInRect(line, barPadding, textY, maxTextWidth, barHeight - 4, nil, "...", kTextAlignment.center)
            else
                -- Short text fits on one line - center it vertically
                local textY = barY + (barHeight - textHeight) / 2
                gfx.drawTextAligned(line, Constants.SCREEN_WIDTH / 2, textY, kTextAlignment.center)
            end

            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end

    -- Draw simple prompt at very bottom
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local promptText
    if self.allLinesShown then
        promptText = "Press Ⓐ to continue"
    else
        promptText = "Press Ⓐ to skip"
    end
    gfx.drawTextAligned(promptText, Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 14, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return StoryPanel
