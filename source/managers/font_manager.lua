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
    self.episodeTitleFont = gfx.font.new("fonts/Roobert-20-Medium")  -- Large episode titles
    self.smallBoldFont = gfx.font.new("fonts/Roobert-10-Bold-Halved")  -- Small bold (version numbers)

    -- Register bold variant so *bold* markup works with body font
    local bodyFamily = gfx.font.newFamily({
        [gfx.font.kVariantNormal] = "fonts/Roobert-11-Medium",
        [gfx.font.kVariantBold] = "fonts/Roobert-11-Bold",
    })
    self.bodyFamily = bodyFamily
end

-- Each setter also sets the bold variant to the same font,
-- preventing a lingering bold variant from setBodyFamily()
-- from interfering with *bold* markup in other contexts.

function FontManager:setTitleFont()
    gfx.setFont(self.titleFont)
    gfx.setFont(self.titleFont, gfx.font.kVariantBold)
end

function FontManager:setMenuFont()
    gfx.setFont(self.menuFont)
    gfx.setFont(self.menuFont, gfx.font.kVariantBold)
end

function FontManager:setBodyFont()
    gfx.setFont(self.bodyFont)
    gfx.setFont(self.bodyFont, gfx.font.kVariantBold)
end

function FontManager:setBoldFont()
    gfx.setFont(self.boldFont)
    gfx.setFont(self.boldFont, gfx.font.kVariantBold)
end

function FontManager:setFooterFont()
    gfx.setFont(self.footerFont)
    gfx.setFont(self.footerFont, gfx.font.kVariantBold)
end

function FontManager:setEpisodeTitleFont()
    gfx.setFont(self.episodeTitleFont)
    gfx.setFont(self.episodeTitleFont, gfx.font.kVariantBold)
end

function FontManager:setBodyFamily()
    gfx.setFontFamily(self.bodyFamily)
end

return FontManager
