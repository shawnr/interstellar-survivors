-- Story Panel UI
-- Displays intro and ending story panels for episodes

local gfx <const> = playdate.graphics

StoryPanel = {
    isVisible = false,
    panels = {},        -- Array of panel data {image, text}
    currentPanel = 1,
    onComplete = nil,   -- Callback when all panels viewed
    inputDelay = 0,     -- Brief delay before accepting input (prevents carry-over)
}

function StoryPanel:init()
    print("StoryPanel initialized")
end

-- Show story panels
-- panelData: array of {imagePath, text} tables
-- callback: function to call when done
function StoryPanel:show(panelData, callback)
    self.isVisible = true
    self.currentPanel = 1
    self.onComplete = callback
    self.panels = {}
    self.inputDelay = 0.2  -- 200ms delay before accepting input (prevents button carry-over)

    -- Load panel images
    for i, data in ipairs(panelData) do
        local panel = {
            image = data.imagePath and gfx.image.new(data.imagePath) or nil,
            text = data.text or ""
        }
        table.insert(self.panels, panel)
    end

    print("StoryPanel showing " .. #self.panels .. " panels")
end

function StoryPanel:hide()
    self.isVisible = false
    self.panels = {}
    self.currentPanel = 1
    self.onComplete = nil
    self.inputDelay = 0
end

function StoryPanel:update()
    if not self.isVisible then return end

    -- Decrement input delay
    if self.inputDelay > 0 then
        self.inputDelay = self.inputDelay - (1/30)  -- Assuming 30fps
        return  -- Don't accept input during delay
    end

    -- A button or any button advances to next panel
    if InputManager.buttonJustPressed.a or InputManager.buttonJustPressed.b then
        self:nextPanel()
    end
end

function StoryPanel:nextPanel()
    print("StoryPanel:nextPanel() - advancing from panel " .. self.currentPanel .. " of " .. #self.panels)
    self.currentPanel = self.currentPanel + 1

    -- Add small delay between panels too
    self.inputDelay = 0.15

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
    end
end

function StoryPanel:draw()
    if not self.isVisible then return end
    if #self.panels == 0 then return end

    local panel = self.panels[self.currentPanel]
    if not panel then return end

    -- Clear screen
    gfx.clear(gfx.kColorBlack)

    local hasImage = panel.image ~= nil

    -- Draw panel image (full screen or centered)
    if hasImage then
        local imgW, imgH = panel.image:getSize()
        local x = (Constants.SCREEN_WIDTH - imgW) / 2
        local y = 10
        panel.image:draw(x, y)
    end

    -- Draw text
    if panel.text and panel.text ~= "" then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

        -- Word wrap the text
        local maxWidth = Constants.SCREEN_WIDTH - 40
        local wrappedText = self:wrapText(panel.text, maxWidth)

        local textY
        if hasImage then
            -- Text at bottom when there's an image
            textY = Constants.SCREEN_HEIGHT - 60
        else
            -- Center text vertically when there's no image
            local textHeight = #wrappedText * 18
            textY = (Constants.SCREEN_HEIGHT - textHeight) / 2 - 10
        end

        for _, line in ipairs(wrappedText) do
            gfx.drawTextAligned(line, Constants.SCREEN_WIDTH / 2, textY, kTextAlignment.center)
            textY = textY + 18
        end

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw progress indicator
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local progressText = self.currentPanel .. "/" .. #self.panels .. "  [A] Continue"
    gfx.drawTextAligned(progressText, Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 12, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Simple word wrap function
function StoryPanel:wrapText(text, maxWidth)
    local lines = {}
    local currentLine = ""

    for word in text:gmatch("%S+") do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        local width = gfx.getTextSize(testLine)

        if width > maxWidth and currentLine ~= "" then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = testLine
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

return StoryPanel
