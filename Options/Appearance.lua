-- "Appearance" tab: theme presets plus every individual value (see UI/Themes.lua).
local _, ns = ...
local RPSheet = ns.addon
local Opt = ns.Opt

local function Theme() return RPSheet.db.profile.theme end

-- Any manual change turns the current look into a custom one.
local function Touched()
    RPSheet.db.profile.themePreset = "CUSTOM"
    RPSheet:ApplyTheme()
end

local function Color(order, key, name, desc, hasAlpha)
    return {
        type = "color", order = order, name = name, desc = desc, hasAlpha = hasAlpha,
        get = function()
            local color = Theme()[key]
            return color[1], color[2], color[3], color[4]
        end,
        set = function(_, r, g, b, a)
            local color = Theme()[key]
            color[1], color[2], color[3], color[4] = r, g, b, hasAlpha and a or 1
            Touched()
        end,
    }
end

local function Value(option, key)
    option.get = function() return Theme()[key] end
    option.set = function(_, value)
        Theme()[key] = value
        Touched()
    end
    return option
end

-- Dropdown of everything LibSharedMedia knows of one kind ("font", "statusbar"),
-- read when the dropdown opens so media registered later by other addons shows up.
local function MediaValues(kind)
    return function()
        local values = {}
        for _, name in ipairs(LibStub("LibSharedMedia-3.0"):List(kind)) do values[name] = name end
        return values
    end
end

local PRESET_VALUES, PRESET_ORDER = { CUSTOM = "Custom" }, {}
for _, key in ipairs(ns.THEME_ORDER) do
    PRESET_VALUES[key] = ns.Themes[key].name
    PRESET_ORDER[#PRESET_ORDER + 1] = key
end
PRESET_ORDER[#PRESET_ORDER + 1] = "CUSTOM"

Opt.tabs.appearance = {
    type = "group", order = 10, name = "Appearance",
    args = {
        preset = {
            type = "select", order = 1, name = "Theme",
            desc = "Pick a ready-made look. You can change any colour, the font or the size afterwards.",
            values = PRESET_VALUES, sorting = PRESET_ORDER,
            get = function() return RPSheet.db.profile.themePreset end,
            set = function(_, key)
                if key ~= "CUSTOM" then RPSheet:LoadThemePreset(key) end
            end,
        },
        colorHeader = { type = "header", order = 10, name = "Colours" },
        bg = Color(11, "bg", "Background", "Window background. The opacity slider makes it see-through.", true),
        border = Color(12, "border", "Border", "The thin edge of the window. Set opacity to 0 to hide it.", true),
        accent = Color(13, "accent", "Accent", "Title, section headings and highlighted words."),
        text = Color(14, "text", "Text", "Normal text."),
        muted = Color(15, "muted", "Secondary text", "Modifiers and switched-off passives."),
        highlight = Color(16, "highlight", "Row highlight", "Glow under the row your mouse is on.", true),
        barHP = Color(17, "barHP", "HP bar", "Fill colour of the HP bar.", true),
        barResource = Color(18, "barResource", "Class resource bars", "Fill colour of class resources such as Rage or Focus Points.", true),
        barCounter = Color(19, "barCounter", "Own resource bars", "Fill colour of the resources you added yourself.", true),

        textHeader = { type = "header", order = 20, name = "Text and size" },
        font = Value({
            type = "select", order = 21, name = "Font", values = MediaValues("font"),
            desc = "Fonts registered by your other addons are listed too.",
        }, "font"),
        barTexture = Value({
            type = "select", order = 25, name = "Bar texture", values = MediaValues("statusbar"),
            desc = "Texture of the HP and resource bars. \"Solid\" is flat; textures from your other addons are listed too.",
        }, "barTexture"),
        fontSize = Value({ type = "range", order = 22, min = 8, max = 18, step = 1, name = "Font size" }, "fontSize"),
        scale = Value({
            type = "range", order = 23, min = 0.6, max = 1.6, step = 0.05, name = "Window scale",
            desc = "Scales the whole window. Changing it can shift the window slightly.",
        }, "scale"),
        shadow = Value({
            type = "toggle", order = 24, name = "Text shadow",
            desc = "A dark outline behind the text. Best on dark or see-through backgrounds.",
        }, "shadow"),
    },
}
