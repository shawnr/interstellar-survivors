-- Tool Evolution Screen
-- Shows dramatic transformation when a tool evolves to its upgraded form
-- Retro terminal aesthetic: dark overlay, custom fonts, black panels with white borders

local gfx <const> = playdate.graphics

-- Pre-computed text outline offsets (1px and 2px)
local TEXT_OUTLINE_OFFSETS = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {1,0}, {-1,1}, {0,1}, {1,1} }
local TEXT_OUTLINE_OFFSETS_2PX = { {-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2}, {-2,-1}, {2,-1}, {-2,0}, {2,0}, {-2,1}, {2,1}, {-2,2}, {-1,2}, {0,2}, {1,2}, {2,2} }

ToolEvolutionScreen = {
    isVisible = false,
    timer = 0,

    -- Tool info
    originalName = "",
    evolvedName = "",
    originalIcon = nil,
    evolvedIcon = nil,
    evolutionBonus = "",  -- Description of the evolution bonus

    -- Animation state
    phase = 1,  -- 1=show original, 2=transition, 3=show evolved
    flashTimer = 0,
    arrowOffset = 0,

    -- Callback
    onComplete = nil,
}

function ToolEvolutionScreen:init()
    print("ToolEvolutionScreen initialized")
end

function ToolEvolutionScreen:show(originalToolData, evolvedToolData, callback)
    self.isVisible = true
    self.timer = 0
    self.phase = 1
    self.flashTimer = 0
    self.arrowOffset = 0
    self.onComplete = callback

    -- Store names
    self.originalName = originalToolData.name or "Tool"
    self.evolvedName = evolvedToolData.upgradedName or "Evolved Tool"

    -- Build evolution bonus description
    local bonuses = {}
    if evolvedToolData.upgradedDamage then
        local damageIncrease = evolvedToolData.upgradedDamage - (evolvedToolData.baseDamage or 1)
        if damageIncrease > 0 then
            table.insert(bonuses, "+" .. damageIncrease .. " Damage")
        end
    end
    if evolvedToolData.piercing then
        table.insert(bonuses, "Piercing shots")
    end
    if evolvedToolData.upgradedFireRate then
        table.insert(bonuses, "Faster fire rate")
    end
    if evolvedToolData.upgradedSpeed then
        table.insert(bonuses, "Faster projectiles")
    end
    -- Add tool-specific bonuses
    if evolvedToolData.id == "cryo_projector" then
        table.insert(bonuses, "Longer freeze")
    elseif evolvedToolData.id == "tesla_coil" then
        table.insert(bonuses, "More chain targets")
    elseif evolvedToolData.id == "tractor_pulse" then
        table.insert(bonuses, "Larger pull radius")
    elseif evolvedToolData.id == "emp_burst" then
        table.insert(bonuses, "Longer stun")
    end

    self.evolutionBonus = #bonuses > 0 and table.concat(bonuses, ", ") or "Enhanced power"

    -- Load icons (try icons_on_black first, fall back to tools images)
    local originalIconPath = originalToolData.iconPath or originalToolData.imagePath
    local evolvedIconPath = evolvedToolData.upgradedImagePath or originalIconPath

    if originalIconPath then
        local filename = originalIconPath:match("([^/]+)$")
        -- Try icons_on_black first, then fall back to the original path
        self.originalIcon = gfx.image.new("images/icons_on_black/" .. filename)
        if not self.originalIcon then
            self.originalIcon = gfx.image.new(originalIconPath)
        end
    end

    if evolvedIconPath then
        local filename = evolvedIconPath:match("([^/]+)$")
        -- Try icons_on_black first, then fall back to the original path
        self.evolvedIcon = gfx.image.new("images/icons_on_black/" .. filename)
        if not self.evolvedIcon then
            self.evolvedIcon = gfx.image.new(evolvedIconPath)
        end
        -- If still no evolved icon, use original icon
        if not self.evolvedIcon then
            self.evolvedIcon = self.originalIcon
        end
    end

    -- Play evolution sound
    if AudioManager then
        AudioManager:playSFX("level_up", 0.8)
    end

    print("Showing evolution: " .. self.originalName .. " -> " .. self.evolvedName)
end

function ToolEvolutionScreen:hide()
    self.isVisible = false
    self.originalIcon = nil
    self.evolvedIcon = nil
    self.onComplete = nil
end

function ToolEvolutionScreen:update()
    if not self.isVisible then return end

    local dt = 1/30
    self.timer = self.timer + dt
    self.flashTimer = self.flashTimer + dt
    self.arrowOffset = math.sin(self.timer * 4) * 3

    -- Phase transitions
    if self.phase == 1 and self.timer > 1.0 then
        self.phase = 2
        -- Play transformation sound
        if AudioManager then
            AudioManager:playSFX("menu_confirm", 0.6)
        end
    elseif self.phase == 2 and self.timer > 1.5 then
        self.phase = 3
    end

    -- Check for button press to skip (after 2 seconds)
    if self.timer > 2.0 then
        if playdate.buttonJustPressed(playdate.kButtonA) or
           playdate.buttonJustPressed(playdate.kButtonB) then
            self:complete()
            return
        end
    end

    -- Auto-advance after 4 seconds
    if self.timer >= 4.0 then
        self:complete()
    end
end

function ToolEvolutionScreen:complete()
    if self.onComplete then
        self.onComplete()
    end
    self:hide()
end

function ToolEvolutionScreen:draw()
    if not self.isVisible then return end

    local centerX = Constants.SCREEN_WIDTH / 2
    local centerY = Constants.SCREEN_HEIGHT / 2

    -- Draw darkened background overlay
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.6)
    gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Draw "TOOL EVOLVED!" title with flash effect
    local titleY = 25
    local titleText = "TOOL EVOLVED!"

    -- Flash effect during phase 2
    if self.phase == 2 and math.floor(self.flashTimer * 10) % 2 == 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    end

    -- Draw title with thick 2px outline using title font
    FontManager:setTitleFont()
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_2PX) do
        gfx.drawTextAligned(titleText, centerX + offset[1], titleY + offset[2], kTextAlignment.center)
    end
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
        gfx.drawTextAligned(titleText, centerX + offset[1], titleY + offset[2], kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(titleText, centerX, titleY, kTextAlignment.center)

    -- Icon positions
    local iconY = centerY - 20
    local iconScale = 2.0
    local leftX = centerX - 80
    local rightX = centerX + 80
    local arrowY = iconY + 16

    -- Draw original tool (left side)
    if self.originalIcon then
        local iconW, iconH = self.originalIcon:getSize()
        local scaledW = iconW * iconScale
        local scaledH = iconH * iconScale

        -- Draw black background for white-on-black icon
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(leftX - scaledW/2 - 2, iconY - scaledH/2 - 2, scaledW + 4, scaledH + 4)

        -- Always draw icon as white on black background
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        self.originalIcon:drawScaled(leftX - scaledW/2, iconY - scaledH/2, iconScale)
    end

    -- Draw original name below icon with outline
    FontManager:setBodyFont()
    local nameY = iconY + 45
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
        gfx.drawTextAligned(self.originalName, leftX + offset[1], nameY + offset[2], kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(self.originalName, leftX, nameY, kTextAlignment.center)

    -- Draw arrow in center (animated) with outline
    FontManager:setBoldFont()
    local arrowX = centerX + self.arrowOffset
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
        gfx.drawTextAligned(">>>", arrowX + offset[1], arrowY + offset[2], kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(">>>", arrowX, arrowY, kTextAlignment.center)

    -- Draw evolved tool (right side) - only visible in phase 2+
    if self.phase >= 2 then
        if self.evolvedIcon then
            local iconW, iconH = self.evolvedIcon:getSize()

            -- Pulsing effect for new tool
            local pulse = 1.0 + math.sin(self.timer * 6) * 0.1
            local pulseScale = iconScale * pulse
            local pulseW = iconW * pulseScale
            local pulseH = iconH * pulseScale

            -- Draw black background for white-on-black icon (slightly larger for pulse room)
            local maxPulseScale = iconScale * 1.1
            local maxW = iconW * maxPulseScale
            local maxH = iconH * maxPulseScale
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(rightX - maxW/2 - 2, iconY - maxH/2 - 2, maxW + 4, maxH + 4)

            -- Always draw icon as white on black background
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            self.evolvedIcon:drawScaled(rightX - pulseW/2, iconY - pulseH/2, pulseScale)
        end

        -- Draw evolved name with emphasis and thick outline using bold font
        FontManager:setBoldFont()
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        for _, offset in ipairs(TEXT_OUTLINE_OFFSETS_2PX) do
            gfx.drawTextAligned(self.evolvedName, rightX + offset[1], nameY + offset[2], kTextAlignment.center)
        end
        for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
            gfx.drawTextAligned(self.evolvedName, rightX + offset[1], nameY + offset[2], kTextAlignment.center)
        end
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(self.evolvedName, rightX, nameY, kTextAlignment.center)
    else
        -- Show "???" before reveal with outline
        FontManager:setBoldFont()
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
            gfx.drawTextAligned("???", rightX + offset[1], iconY + 10 + offset[2], kTextAlignment.center)
        end
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("???", rightX, iconY + 10, kTextAlignment.center)
    end

    -- Draw evolution bonus (phase 3 only)
    if self.phase >= 3 then
        local bonusY = centerY + 65
        -- Bonus text with outline using body font
        FontManager:setBodyFont()
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
            gfx.drawTextAligned(self.evolutionBonus, centerX + offset[1], bonusY + offset[2], kTextAlignment.center)
        end
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(self.evolutionBonus, centerX, bonusY, kTextAlignment.center)

        -- Draw continue hint
        if self.timer > 2.0 then
            FontManager:setMenuFont()
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            for _, offset in ipairs(TEXT_OUTLINE_OFFSETS) do
                gfx.drawTextAligned("Press A to continue", centerX + offset[1], bonusY + 25 + offset[2], kTextAlignment.center)
            end
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned("Press A to continue", centerX, bonusY + 25, kTextAlignment.center)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return ToolEvolutionScreen
