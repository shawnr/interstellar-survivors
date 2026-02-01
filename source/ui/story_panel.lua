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

    -- A button skips to next panel (or completes sequence on last panel)
    if InputManager.buttonJustPressed.a then
        self:nextPanel()
    end

    -- B button goes back to previous panel (undocumented feature)
    if InputManager.buttonJustPressed.b then
        self:prevPanel()
    end
end

function StoryPanel:prevPanel()
    if self.currentPanel > 1 then
        print("StoryPanel:prevPanel() - going back from panel " .. self.currentPanel)
        self.currentPanel = self.currentPanel - 1
        self.currentLine = 0
        self.allLinesShown = false
        self.lineTimer = 0
        self.inputDelay = 0.3
        -- Start showing first line of previous panel
        self:startNextLine()
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

-- Helper function to draw A button icon (white circle with black A)
function StoryPanel:drawAButtonIcon(x, y, radius)
    radius = radius or 10
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

-- Helper function to draw line progress dots
-- Shows which line of text the player is on (or has skipped past)
function StoryPanel:drawProgressDots(lineCount, currentLine)
    if lineCount <= 0 then return end

    local dotRadius = 4
    local dotSpacing = 12  -- Space between dot centers
    local totalWidth = (lineCount - 1) * dotSpacing
    local startX = (Constants.SCREEN_WIDTH - totalWidth) / 2
    local dotY = 5 + dotRadius  -- 5px from top edge

    for i = 1, lineCount do
        local dotX = startX + (i - 1) * dotSpacing

        if i == currentLine then
            -- Current dot: white fill with black stroke
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(dotX, dotY, dotRadius)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(dotX, dotY, dotRadius)
        else
            -- Off dot: black fill with white stroke
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(dotX, dotY, dotRadius)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawCircleAtPoint(dotX, dotY, dotRadius)
        end
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

    -- Calculate bar position for dialogue and progress dots
    local barPadding = 10
    local maxTextWidth = Constants.SCREEN_WIDTH - (barPadding * 2)
    local barHeight = 32  -- Default height
    local barY = Constants.SCREEN_HEIGHT - barHeight - 6

    -- Draw current line on white bar at bottom
    if self.currentLine > 0 and self.currentLine <= #panel.lines then
        local line = panel.lines[self.currentLine]
        if line and line ~= "" then
            -- Measure text to determine if wrapping is needed
            local textWidth, textHeight = gfx.getTextSize(line)
            local needsWrap = (#line > 40) or (textWidth > maxTextWidth)

            -- Dynamic bar height - taller if text needs wrapping
            barHeight = needsWrap and 48 or 32
            barY = Constants.SCREEN_HEIGHT - barHeight - 6

            -- Draw white bar background
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, barY, Constants.SCREEN_WIDTH, barHeight)

            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

            -- Make text bold by wrapping with *
            local boldLine = "*" .. line .. "*"

            if needsWrap then
                -- Long text - wrap it using drawTextInRect
                -- Calculate wrapped height to center vertically
                local wrappedW, wrappedH = gfx.getTextSizeForMaxWidth(boldLine, maxTextWidth)
                local textY = barY + (barHeight - wrappedH) / 2
                gfx.drawTextInRect(boldLine, barPadding, textY, maxTextWidth, barHeight - 4, nil, "...", kTextAlignment.center)
            else
                -- Short text fits on one line - center it vertically
                local boldTextWidth, boldTextHeight = gfx.getTextSize(boldLine)
                local textY = barY + (barHeight - boldTextHeight) / 2
                gfx.drawTextAligned(boldLine, Constants.SCREEN_WIDTH / 2, textY, kTextAlignment.center)
            end

            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
    end

    -- Draw progress dots showing which line we're on (centered, 5px from top)
    if #panel.lines > 1 then
        self:drawProgressDots(#panel.lines, self.currentLine)
    end

    -- Draw "Press A" right-aligned, 5px from right and top edges
    local radius = 8
    local iconX = Constants.SCREEN_WIDTH - 5 - radius  -- 5px from right edge
    local iconY = 5 + radius  -- 5px from top edge

    -- Draw "Press" text before icon
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local smallFont = gfx.getSystemFont()
    gfx.setFont(smallFont)
    local pressWidth = smallFont:getTextWidth("Press ")
    gfx.drawText("Press ", iconX - pressWidth - 2, iconY - smallFont:getHeight()/2)

    -- Draw the A button icon
    self:drawAButtonIcon(iconX, iconY, radius)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return StoryPanel
