-- Looks for the sheet window. A theme is plain data; picking a preset copies it into
-- the saved settings, where every value can then be changed in /sheet config > Appearance.
-- To add a preset: copy one block, give it a new key, and add the key to THEME_ORDER.
local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

-- Fonts and bar textures are named as in LibSharedMedia, so anything another addon
-- registers there can be picked too. These four fonts ship with the game.
local FRIZ = "Friz Quadrata TT"

-- File path of a theme's font. Older saved themes stored the path itself.
function ns.ThemeFont(theme)
    local font = theme.font or FRIZ
    if font:find("[/\\]") then return font end
    return LSM:Fetch("font", font)
end

-- File path of a theme's bar texture.
function ns.ThemeBarTexture(theme)
    return LSM:Fetch("statusbar", theme.barTexture or "Solid")
end

-- Colours are { red, green, blue, alpha } from 0 to 1.
--   bg / border   window background and its 1px edge
--   accent        title, section headings, highlighted words
--   text / muted  normal text and secondary text (modifiers, costs, switched-off passives)
--   highlight     glow under the row the mouse is on
ns.Themes = {
    DARK = {
        name = "Dark",
        bg = { 0.05, 0.05, 0.07, 0.92 }, border = { 0.35, 0.35, 0.40, 1 },
        accent = { 1.00, 0.82, 0.00, 1 }, text = { 1, 1, 1, 1 }, muted = { 0.56, 0.56, 0.56, 1 },
        highlight = { 1.00, 0.82, 0.00, 0.25 },
        font = FRIZ, fontSize = 11, scale = 1, shadow = true,
    },
    PARCHMENT = {
        name = "Parchment",
        bg = { 0.87, 0.80, 0.64, 0.96 }, border = { 0.35, 0.24, 0.12, 1 },
        accent = { 0.50, 0.14, 0.06, 1 }, text = { 0.16, 0.11, 0.06, 1 }, muted = { 0.42, 0.33, 0.22, 1 },
        highlight = { 1, 1, 1, 0.35 },
        font = "Morpheus", fontSize = 12, scale = 1, shadow = false,
    },
    ALLIANCE = {
        name = "Alliance",
        bg = { 0.04, 0.08, 0.18, 0.92 }, border = { 0.78, 0.65, 0.25, 1 },
        accent = { 0.95, 0.80, 0.35, 1 }, text = { 0.90, 0.94, 1.00, 1 }, muted = { 0.55, 0.62, 0.75, 1 },
        highlight = { 0.30, 0.50, 1.00, 0.30 },
        font = FRIZ, fontSize = 11, scale = 1, shadow = true,
    },
    HORDE = {
        name = "Horde",
        bg = { 0.16, 0.03, 0.03, 0.92 }, border = { 0.55, 0.10, 0.08, 1 },
        accent = { 1.00, 0.45, 0.20, 1 }, text = { 1.00, 0.93, 0.88, 1 }, muted = { 0.70, 0.50, 0.45, 1 },
        highlight = { 1.00, 0.30, 0.10, 0.30 },
        font = FRIZ, fontSize = 11, scale = 1, shadow = true,
    },
    FEL = {
        name = "Fel",
        bg = { 0.03, 0.09, 0.04, 0.92 }, border = { 0.30, 0.80, 0.20, 1 },
        accent = { 0.60, 1.00, 0.30, 1 }, text = { 0.90, 1.00, 0.88, 1 }, muted = { 0.50, 0.68, 0.48, 1 },
        highlight = { 0.40, 1.00, 0.20, 0.25 },
        font = FRIZ, fontSize = 11, scale = 1, shadow = true,
    },
    VOID = {
        name = "Void",
        bg = { 0.08, 0.04, 0.14, 0.92 }, border = { 0.50, 0.30, 0.80, 1 },
        accent = { 0.78, 0.60, 1.00, 1 }, text = { 0.94, 0.90, 1.00, 1 }, muted = { 0.60, 0.52, 0.72, 1 },
        highlight = { 0.60, 0.30, 1.00, 0.30 },
        font = FRIZ, fontSize = 11, scale = 1, shadow = true,
    },
    MINIMAL = {
        name = "Minimal (see-through)",
        bg = { 0, 0, 0, 0.35 }, border = { 0, 0, 0, 0 },
        accent = { 1, 1, 1, 1 }, text = { 1, 1, 1, 1 }, muted = { 0.75, 0.75, 0.75, 1 },
        highlight = { 1, 1, 1, 0.20 },
        font = "Arial Narrow", fontSize = 12, scale = 1, shadow = true,
    },
}
ns.THEME_ORDER = { "DARK", "PARCHMENT", "ALLIANCE", "HORDE", "FEL", "VOID", "MINIMAL" }

-- Bar colours (HP, class resource, counter). A theme may set its own; otherwise these apply.
local BAR_DEFAULTS = {
    barHP = { 0.20, 0.62, 0.24, 0.90 },
    barResource = { 0.22, 0.45, 0.90, 0.90 },
    barCounter = { 0.80, 0.55, 0.10, 0.90 },
}
ns.Themes.PARCHMENT.barHP = { 0.42, 0.62, 0.30, 0.85 }
ns.Themes.PARCHMENT.barResource = { 0.38, 0.55, 0.78, 0.85 }
ns.Themes.PARCHMENT.barCounter = { 0.80, 0.60, 0.28, 0.85 }
for _, theme in pairs(ns.Themes) do
    for key, color in pairs(BAR_DEFAULTS) do
        theme[key] = theme[key] or { unpack(color) }
    end
end

-- Bars are flat by default; "Blizzard" and any texture from other addons can be picked.
for _, theme in pairs(ns.Themes) do
    theme.barTexture = theme.barTexture or "Solid"
end
