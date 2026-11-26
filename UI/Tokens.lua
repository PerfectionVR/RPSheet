-- The colours every widget paints with, worked out from a theme (UI/Themes.lua). A
-- theme names few colours (ground, edge, accent, text, muted); the rest of the look
-- comes from these, so all windows share one ladder:
--   text / dim / muted   three steps of text: what matters, what supports it, hints
--   line                 a hairline between rows and round panes
--   wash / washStrong    the fill of a control, and of one that is selected
--   track                the empty part of a bar
--   onAccent             text that stands on the accent colour
--   shade                a darker pane inside a window (title bar, side rail)
-- ns.Tokens(theme) is kept per theme until ns.ForgetTokens() (a theme was changed).
local _, ns = ...

local kept = setmetatable({}, { __mode = "k" })

local function Mix(a, b, part)
    return { a[1] + (b[1] - a[1]) * part, a[2] + (b[2] - a[2]) * part, a[3] + (b[3] - a[3]) * part, 1 }
end

local function Faint(color, alpha)
    return { color[1], color[2], color[3], alpha }
end

function ns.Tokens(theme)
    local tokens = kept[theme]
    if tokens then return tokens end
    local text, accent = theme.text, theme.accent
    -- A light ground (parchment) is shaded and lined with its dark text all the same.
    local bright = accent[1] * 0.30 + accent[2] * 0.59 + accent[3] * 0.11
    tokens = {
        text = text, muted = theme.muted, accent = accent,
        dim = Mix(text, theme.muted, 0.45),
        line = Faint(text, 0.10),
        wash = Faint(text, 0.07),
        washStrong = Faint(text, 0.13),
        track = Faint(text, 0.12),
        onAccent = bright > 0.55 and { 0.10, 0.08, 0.04, 1 } or { 1, 1, 1, 1 },
        shade = { 0, 0, 0, 0.22 },
        hover = theme.highlight,
    }
    kept[theme] = tokens
    return tokens
end

function ns.ForgetTokens()
    wipe(kept)
end
