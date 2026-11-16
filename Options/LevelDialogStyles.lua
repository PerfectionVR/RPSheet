-- The level dialog: Fighting Styles left empty (given up under Customize, or never
-- picked on an older character) are asked for when the choices are looked at again,
-- like the other open choices. A style that the level being taken opens is asked for
-- in Options/LevelDialogClass.lua instead.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local L = ns.LevelDialog
local args = L.args

local MAX_OPEN = 4 -- two slots each for at most two classes with the feature

-- The empty slots, each { class =, slot =, pick = <the style picked here, or ""> }.
-- Worked out once when the dialog opens: the sheet doesn't change while it is open.
function L.OpenStyles()
    if not L.draft or L.draft.taking then return {} end
    if not L.draft.openStyles then
        local open = {}
        for _, slot in ipairs(ns.OpenStyleSlots(L.Sheet())) do
            if #open < MAX_OPEN then open[#open + 1] = { class = slot.class, slot = slot.slot, pick = "" } end
        end
        L.draft.openStyles = open
    end
    return L.draft.openStyles
end

-- The styles an open slot may take: what the class may pick, less what the other
-- slots hold or were given here (a style can't be taken twice).
local function Choices(open)
    local others = {}
    for _, other in ipairs(L.OpenStyles()) do
        if other ~= open then others[other.pick] = true end
    end
    local names = {}
    for _, name in ipairs(ns.StyleChoices(ns.ClassView(L.Sheet(), open.class), open.slot)) do
        if not others[name] then names[#names + 1] = name end
    end
    return names
end

-- Writes the picks to the sheet when the dialog is confirmed.
function L.ApplyOpenStyles(sheet)
    for _, open in ipairs(L.OpenStyles()) do
        if open.pick ~= "" then ns.SetClassStyle(sheet, open.class, open.slot, open.pick) end
    end
end

-- The first open slot without a pick, for the line in red.
function L.StyleMissing()
    for _, open in ipairs(L.OpenStyles()) do
        if open.pick == "" then return open end
    end
end

for index = 1, MAX_OPEN do
    local function Open() return L.OpenStyles()[index] end
    args["openStyle" .. index] = {
        type = "select", order = 11.05 + index / 1000, width = "double",
        name = function()
            local open = Open()
            if not open then return "" end
            local name = open.slot == 1 and "Fighting Style" or "Second Fighting Style"
            if ns.IsMulticlass(L.Sheet()) then name = ("%s (%s)"):format(name, R.CLASSES[open.class].name) end
            return name
        end,
        desc = function()
            local lines = {}
            for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return Open() == nil end,
        values = function() return (Opt.ListMap(Open() and Choices(Open()), true)) end,
        sorting = function() return (select(2, Opt.ListMap(Open() and Choices(Open()), true))) end,
        get = function() return Open() and Open().pick or "" end,
        set = function(_, value) if Open() then Open().pick = value end end,
    }
end
