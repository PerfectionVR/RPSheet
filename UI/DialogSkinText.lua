-- The dialog skin's colour words. The pages mark words with fixed colour codes: gold
-- for what matters, red for warnings, green for what is in order. Gold becomes the
-- theme's accent colour, and on a light theme red and green become darker ones that
-- can be read there. The text is put back as it was written when its part is handed
-- back, unless the library has written another text there by then.
local _, ns = ...
local Skin = ns.DialogSkin

-- The codes as Options/Common.lua has them, should that file not say.
local GOLD, RED, GREEN = "|cffffd100", "|cffff5555", "|cff80ff80"
local DARK_RED, DARK_GREEN = "|cffc01010", "|cff1a6e1a"

local changed = setmetatable({}, { __mode = "k" }) -- text -> { original = , set = }

local function Replace(text, from, to)
    if from == to then return text end
    return (text:gsub(from:gsub("%p", "%%%0"), (to:gsub("%%", "%%%%"))))
end

local function Light(theme)
    local bg = theme.bg
    return 0.299 * bg[1] + 0.587 * bg[2] + 0.114 * bg[3] > 0.5
end

local function Swap(text, theme)
    local codes = ns.Opt or {}
    text = Replace(text, codes.GOLD or GOLD, ns.Util.HexCode(theme.accent))
    if Light(theme) then
        text = Replace(text, codes.RED or RED, DARK_RED)
        text = Replace(text, codes.GREEN or GREEN, DARK_GREEN)
    end
    return text
end

-- `text` is a text on the window's background; never what the player typed.
function Skin.Recolor(widget, text, theme)
    if not (text and text.GetText and text.SetText) then return end
    local now = text:GetText()
    if type(now) ~= "string" then return end
    local state = changed[text]
    -- Still showing what was put there last time: start again from what was written.
    local source = state and state.set == now and state.original or now
    if not source:find("|c", 1, true) then return end
    local wanted = Swap(source, theme)
    if wanted == now then return end
    if not state then
        state = {}
        changed[text] = state
    end
    state.original, state.set = source, wanted
    if Skin.First(widget, "words", text) then
        Skin.Undo(widget, function()
            local last = changed[text]
            changed[text] = nil
            if last and text:GetText() == last.set then text:SetText(last.original) end
        end)
    end
    text:SetText(wanted)
end
