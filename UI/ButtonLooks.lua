-- The looks of an "RPSheetButton" (UI/Button.lua), painted with the theme's tokens
-- (UI/Tokens.lua). A look is of a kind, which says how the widget is set out:
--   gap / below   space kept free to the right and under it
--   pad / room    between its edge and the text: left and right, above and below together
--   split         text after two spaces stands on the right
--   tile          text before a line break is a small label over the rest
local _, ns = ...

local BUTTON = { gap = 4, below = 4, pad = 8, room = 12 }
local ROW = { gap = 8, below = 0, pad = 6, room = 12, split = true }
local TILE = { gap = 4, below = 4, pad = 8, room = 12, tile = true }

-- look = { kind, fill, text colour, side text colour, line under it }
local LOOKS = {
    on = { BUTTON, "wash", "text" },
    off = { BUTTON, "faint", "muted" },
    picked = { BUTTON, "accent", "onAccent" },
    row = { ROW, nil, "text", "muted", true },
    rowoff = { ROW, nil, "muted", "muted", true },
    tile = { TILE, "wash", "text", "muted" },
}

local function Font(region, theme, size, color)
    region:SetFont(ns.ThemeFont(theme), size, "")
    region:SetTextColor(color[1], color[2], color[3])
    region:SetShadowOffset(1, -1)
    region:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
end

-- Paints `widget` and returns the kind of its look.
function ns.PaintButton(widget, theme, look)
    local tokens = ns.Tokens(theme)
    local style = LOOKS[look] or LOOKS.on
    local kind = style[1]
    local fill = style[2] == "faint" and { tokens.text[1], tokens.text[2], tokens.text[3], 0.03 } or tokens[style[2] or ""]
    if fill then
        widget.fill:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    else
        widget.fill:SetColorTexture(0, 0, 0, 0)
    end
    Font(widget.text, theme, kind.tile and theme.fontSize + 5 or theme.fontSize, tokens[style[3]])
    Font(widget.side, theme, kind.tile and math.max(9, theme.fontSize - 2) or theme.fontSize, tokens[style[4] or "muted"])
    widget.line:SetShown(style[5] == true)
    widget.line:SetColorTexture(unpack(tokens.line))
    widget.hover:SetColorTexture(unpack(tokens.hover))
    widget.markHover:SetColorTexture(unpack(tokens.washStrong))
    Font(widget.markText, theme, math.max(9, theme.fontSize - 1), tokens.muted)
    return kind
end
