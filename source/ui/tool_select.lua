-- Tool Selection UI
-- Shows a grid of all tools for the player to choose their starting tool

local gfx <const> = playdate.graphics

ToolSelect = {
    isVisible = false,
    tools = {},
    selectedIndex = 1,
    columns = 4,
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
            local iconOnWhite = nil
            local iconPath = toolData.iconPath or toolData.imagePath
            if iconPath then
                local filename = iconPath:match("([^/]+)$")
                iconOnBlack = gfx.image.new("images/icons_on_black/" .. filename)
                iconOnWhite = gfx.image.new("images/icons_on_white/" .. filename)
            end
            table.insert(self.tools, {
                id = toolId,
                data = toolData,
                iconOnBlack = iconOnBlack,
                iconOnWhite = iconOnWhite
            })
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

    -- Handle input
    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.tools
        end
        if AudioManager then AudioManager:playSFX("menu_move") end
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.tools then
            self.selectedIndex = 1
        end
        if AudioManager then AudioManager:playSFX("menu_move") end
    elseif playdate.buttonJustPressed(playdate.kButtonUp) then
        self.selectedIndex = self.selectedIndex - self.columns
        if self.selectedIndex < 1 then
            self.selectedIndex = self.selectedIndex + #self.tools
        end
        if AudioManager then AudioManager:playSFX("menu_move") end
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self.selectedIndex = self.selectedIndex + self.columns
        if self.selectedIndex > #self.tools then
            self.selectedIndex = self.selectedIndex - #self.tools
        end
        if AudioManager then AudioManager:playSFX("menu_move") end
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        -- Select this tool
        local selectedTool = self.tools[self.selectedIndex]
        if selectedTool and self.callback then
            if AudioManager then AudioManager:playSFX("menu_select") end
            self.callback(selectedTool.id)
        end
        self:hide()
    end
end

function ToolSelect:draw()
    if not self.isVisible then return end

    -- Draw semi-transparent background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)

    -- Draw title
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setTitleFont()
    gfx.drawTextAligned("*CHOOSE STARTING TOOL*", Constants.SCREEN_WIDTH / 2, 15, kTextAlignment.center)

    -- Grid layout
    local gridStartX = 30
    local gridStartY = 50
    local cellSize = 48
    local cellPadding = 8
    local totalCellSize = cellSize + cellPadding

    -- Draw tool grid
    for i, tool in ipairs(self.tools) do
        local col = (i - 1) % self.columns
        local row = math.floor((i - 1) / self.columns)
        local x = gridStartX + col * totalCellSize
        local y = gridStartY + row * totalCellSize

        local isSelected = (i == self.selectedIndex)

        -- Draw cell background
        if isSelected then
            -- Selected: white background
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(x, y, cellSize, cellSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRect(x, y, cellSize, cellSize)
            gfx.setLineWidth(1)
        else
            -- Not selected: black background with white border
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(x, y, cellSize, cellSize)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(x, y, cellSize, cellSize)
        end

        -- Draw tool icon (use pre-processed icons)
        local icon = isSelected and tool.iconOnWhite or tool.iconOnBlack
        if icon then
            local iconW, iconH = icon:getSize()
            local padding = 6
            local targetSize = cellSize - padding * 2
            local scale = math.min(targetSize / iconW, targetSize / iconH)
            local scaledW = iconW * scale
            local scaledH = iconH * scale
            local drawX = x + (cellSize - scaledW) / 2
            local drawY = y + (cellSize - scaledH) / 2

            -- Pre-processed icons are ready to use directly
            icon:drawScaled(drawX, drawY, scale)
        end
    end

    -- Draw selected tool info at bottom
    local selectedTool = self.tools[self.selectedIndex]
    if selectedTool then
        local infoY = Constants.SCREEN_HEIGHT - 50

        -- Draw info background (black with white rule divider)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, infoY, Constants.SCREEN_WIDTH, 50)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(0, infoY, Constants.SCREEN_WIDTH, infoY)

        -- Draw tool name and description (white text on black)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        FontManager:setMenuFont()
        gfx.drawTextAligned(selectedTool.data.name, Constants.SCREEN_WIDTH / 2, infoY + 8, kTextAlignment.center)

        FontManager:setBodyFont()
        gfx.drawTextAligned(selectedTool.data.description or "", Constants.SCREEN_WIDTH / 2, infoY + 28, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw instructions
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    FontManager:setFooterFont()
    gfx.drawTextAligned("D-Pad: Navigate   A: Select", Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 55, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return ToolSelect
