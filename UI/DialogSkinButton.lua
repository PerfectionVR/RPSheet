-- The dialog skin's button: a flat box filled and edged in the theme's accent colour,
-- with accent text that turns to the text colour, over a glow, under the mouse.
-- Used for the buttons in the window and for the window's own Close button.
local _, ns = ...
local Skin = ns.DialogSkin

local FILL, EDGE = 0.15, 0.7 -- how solid the accent colour is in the box and on its edge

-- A button picks its text's font and colour by its state (normal, under the mouse,
-- switched off), so the theme is given as three fonts of our own rather than set on
-- the text, where the next change of state would wipe it.
local fonts

local function SetFont(font, theme, color)
    local _, size = GameFontNormal:GetFont()
    font:SetFont(ns.ThemeFont(theme), size or 12, "")
    font:SetTextColor(color[1], color[2], color[3])
    font:SetShadowOffset(1, -1)
    font:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
end

local function Fonts(theme)
    if not fonts then
        fonts = {
            normal = CreateFont("RPSheetDialogButtonFont"),
            hover = CreateFont("RPSheetDialogButtonHoverFont"),
            off = CreateFont("RPSheetDialogButtonOffFont"),
        }
        for _, font in pairs(fonts) do
            font:CopyFontObject(GameFontNormal) -- spacing and alignment as the game has them
        end
    end
    SetFont(fonts.normal, theme, theme.accent)
    SetFont(fonts.hover, theme, theme.text)
    SetFont(fonts.off, theme, theme.muted)
    return fonts
end

local function ThemeText(widget, button, theme)
    if not (button.GetNormalFontObject and button.GetHighlightFontObject and button.GetDisabledFontObject
        and button.SetNormalFontObject and button.SetHighlightFontObject and button.SetDisabledFontObject) then return end
    local normal, hover, off = button:GetNormalFontObject(), button:GetHighlightFontObject(), button:GetDisabledFontObject()
    -- All three or none: one that is missing could not be put back afterwards.
    if not (normal and hover and off) then return end
    if Skin.First(widget, "buttonFonts", button) then
        Skin.Undo(widget, function()
            button:SetNormalFontObject(normal)
            button:SetHighlightFontObject(hover)
            button:SetDisabledFontObject(off)
        end)
    end
    local themed = Fonts(theme)
    button:SetNormalFontObject(themed.normal)
    button:SetHighlightFontObject(themed.hover)
    button:SetDisabledFontObject(themed.off)
end

-- `button` is the game's button frame: a button part's own frame, or a button that
-- belongs to another part (`widget` is the part whose handing back undoes it).
function Skin.Button(widget, button, theme)
    if not (button and button.GetRegions and button.CreateTexture) then return end
    -- The game's button art, its glow included, makes way for ours.
    Skin.FadeArt(widget, button)
    local fill = Skin.Box(widget, button, theme.accent, FILL, EDGE, 1)
    local glow = Skin.Texture(widget, button, "glow", "HIGHLIGHT")
    glow:SetAllPoints(fill)
    glow:SetColorTexture(unpack(theme.highlight))
    ThemeText(widget, button, theme)
    Skin.Recolor(widget, button.GetFontString and button:GetFontString(), theme)
end

Skin.styles.Button = function(widget, theme)
    Skin.Button(widget, widget.frame, theme)
end
