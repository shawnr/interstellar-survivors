-- Font Manager
-- Loads and provides access to Roobert font family

local gfx <const> = playdate.graphics

FontManager = {}

function FontManager:init()
    -- Load font variants
    self.titleFont = gfx.font.new("fonts/Roobert-11-Medium-Halved")  -- Menu titles
    self.footerFont = gfx.font.new("fonts/Roobert-11-Medium-Halved") -- Footer instructions
    self.menuFont = gfx.font.new("fonts/Roobert-11-Mono-Condensed")  -- Menu items
    self.bodyFont = gfx.font.new("fonts/Roobert-11-Medium")          -- Body text
    self.boldFont = gfx.font.new("fonts/Roobert-11-Bold")            -- Bold text

    -- Register bold variant so *bold* markup works with body font
    local bodyFamily = gfx.font.newFamily({
        [gfx.font.kVariantNormal] = "fonts/Roobert-11-Medium",
        [gfx.font.kVariantBold] = "fonts/Roobert-11-Bold",
    })
    self.bodyFamily = bodyFamily
end

function FontManager:setTitleFont()
    gfx.setFont(self.titleFont)
end

function FontManager:setMenuFont()
    gfx.setFont(self.menuFont)
end

function FontManager:setBodyFont()
    gfx.setFont(self.bodyFont)
end

function FontManager:setBoldFont()
    gfx.setFont(self.boldFont)
end

function FontManager:setFooterFont()
    gfx.setFont(self.footerFont)
end

function FontManager:setBodyFamily()
    gfx.setFontFamily(self.bodyFamily)
end

return FontManager
