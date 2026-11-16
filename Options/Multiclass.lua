-- The Character tab's part of having more than one class: the class the next level is
-- taken in, and the class a level is taken from when going back one. The level dialog
-- (Options/LevelDialog.lua) checks what the rules ask of a new class; setting classes
-- freely is on the Customize page in Options/MulticlassPage.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

local chosen = "" -- the class key picked for the next level; "" is the first class
local chosenFor   -- the character it was picked for: another one starts with its first class

-- The class the next level is taken in.
local function NextClass()
    local sheet = Sheet()
    if chosenFor ~= sheet then chosen = "" end
    return (R.CLASSES[chosen] and R.CLASSES[sheet.class]) and chosen or sheet.class
end

-- The class that loses a level when going back one: the class picked here when it has
-- a level to give, else the one the last level was taken in (ns.LevelDownClass).
local function DownClass()
    local sheet = Sheet()
    local key = NextClass()
    local spare = ns.ClassLevel(sheet, key) - (key == sheet.class and 1 or 0)
    if chosen ~= "" and spare > 0 then return key end
    return ns.LevelDownClass(sheet)
end

local tab = Opt.tabs.character.args

tab.levelClass = {
    type = "select", order = 3.05, name = "Next level in", width = "double",
    desc = "The class your next level is taken in: your first class unless you pick another. A class you don't have yet makes a character of several classes. It asks for a score of 13 in its main abilities and in those of every class you have, and it gives less training than a first class and no saving throws.\n\nGoing back a level takes it from the class picked here, when that class has a level to give.",
    hidden = function() return RPSheet:ClassData() == nil end,
    values = function()
        local sheet, values = Sheet(), {}
        for _, key in ipairs(R.CLASS_ORDER) do
            local name, levels = R.CLASSES[key].name, ns.ClassLevel(sheet, key)
            local block = ns.MulticlassBlock(sheet, key)
            if levels > 0 then
                values[key] = ("%s (level %d)"):format(name, levels)
            elseif block then
                values[key] = ("|cff888888%s (%s)|r"):format(name, block)
            else
                values[key] = name .. " (new class)"
            end
        end
        return values
    end,
    -- The classes the character has come first.
    sorting = function()
        local sheet = Sheet()
        local order = ns.ClassKeys(sheet)
        for _, key in ipairs(R.CLASS_ORDER) do
            if ns.ClassLevel(sheet, key) == 0 then order[#order + 1] = key end
        end
        return order
    end,
    get = function() return NextClass() end,
    set = function(_, value) chosen, chosenFor = value == Sheet().class and "" or value, Sheet() end,
}

tab.levelUp.name = function()
    local sheet = Sheet()
    if sheet.level >= R.MAX_LEVEL then return "Highest level" end
    local key = NextClass()
    if key == sheet.class and not ns.IsMulticlass(sheet) then return "Take level " .. (sheet.level + 1) end
    return ("Take level %d (%s %d)"):format(sheet.level + 1, R.CLASSES[key].name, ns.ClassLevel(sheet, key) + 1)
end
tab.levelUp.func = function() ns.OpenLevelDialog(nil, nil, NextClass()) end

-- A character of one class is asked what it always was.
local confirmOne = tab.levelDown.confirm
tab.levelDown.confirm = function(...)
    local sheet = Sheet()
    if not ns.IsMulticlass(sheet) then return confirmOne(...) end
    return ("Go back to level %d? Your last level of %s is removed with everything it gave, including the choice you made for it."):format(
        sheet.level - 1, R.CLASSES[DownClass()].name)
end
tab.levelDown.func = function()
    RPSheet:LevelDown(DownClass())
    ns.RebuildOptions()
    Opt.Changed()
end
