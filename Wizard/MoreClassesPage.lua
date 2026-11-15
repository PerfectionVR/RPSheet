-- The "More classes" part of the wizard's class step, for a character made above
-- level 1: a row per other class with its levels, its subclass once it has the levels
-- for one, and the one skill a few classes give. The rules behind it are in
-- Wizard/MoreClasses.lua; the scores of 13 are checked on the ability score step.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local GOLD, RED = Opt.GOLD, Opt.RED

local function Row(index)
    return W.draft and W.Extras()[index] or nil
end

local function RowClass(index)
    local row = Row(index)
    return row and R.CLASSES[row.class]
end

-- Levels row `index` can have: the first class keeps one, the other rows theirs.
local function Room(index)
    return W.draft.level - 1 - W.ExtraLevels(index)
end

local function Open()
    return W.draft ~= nil and R.CLASSES[W.draft.class] ~= nil and W.draft.level >= 2
end

-- A row is shown when it is filled, and the next one while a level is left for it.
local function Shown(index)
    if not Open() then return false end
    local count = #W.Extras()
    return index <= count or (index == count + 1 and Room() > 0)
end

-- The classes row `index` can be: not the first class, not another row's.
local function Choices(index)
    local used, keys = { [W.draft.class] = true }, {}
    for other, row in ipairs(W.Extras()) do
        if other ~= index then used[row.class] = true end
    end
    for _, key in ipairs(R.CLASS_ORDER) do
        if not used[key] then keys[#keys + 1] = key end
    end
    return keys
end

-- "Strength or Dexterity" for the abilities a class needs at 13.
local function Needs(class)
    local rule, names = R.MULTICLASS[class.base], {}
    for _, stat in ipairs(rule and rule.primary or {}) do names[#names + 1] = ns.Term(R.STAT_NAMES[stat]) end
    return table.concat(names, rule and rule.either and " or " or " and ")
end

local function Summary()
    if not Open() then return "" end
    local draft, rows = W.draft, W.Extras()
    if #rows == 0 then
        return "Above level 1 you can split your levels over more than one class. Your first class gives its saving throws and full training; another class gives less, and asks for a score of 13 in its main abilities and in those of your first class.\n"
    end
    local first = R.CLASSES[draft.class]
    local parts = { ("%s %d"):format(first.name, W.FirstLevel()) }
    for _, row in ipairs(rows) do parts[#parts + 1] = ("%s %d"):format(R.CLASSES[row.class].name, row.level) end
    local lines = { ("%sLevel %d: %s|r"):format(GOLD, draft.level, table.concat(parts, " / ")) }
    lines[#lines + 1] = ("%s, your first class, needs %s %d or higher to take another."):format(first.name, Needs(first), R.MULTICLASS_SCORE)
    for index, row in ipairs(rows) do
        local class = R.CLASSES[row.class]
        lines[#lines + 1] = ("%s%s|r needs %s %d or higher and gives %s."):format(
            GOLD, class.name, Needs(class), R.MULTICLASS_SCORE, ns.MulticlassGains(row.class))
        local block = W.ExtraBlock(index, false)
        if block then lines[#lines + 1] = ("%s%s: %s.|r"):format(RED, class.name, block) end
    end
    lines[#lines + 1] = "|cff909090The scores are checked on the ability score step. The choices of each class's levels are asked after the character is made.|r"
    return table.concat(lines, "\n") .. "\n"
end

local function ClassPicker(index, order)
    return {
        type = "select", order = order,
        name = function() return Row(index) and "Another class" or "Add a class" end,
        desc = "A class to take levels in beside your first. Choose None to take it away again. A class in grey can't be taken, for the reason given.",
        hidden = function() return not Shown(index) end,
        values = function()
            local values = { [""] = "None" }
            for _, key in ipairs(Choices(index)) do
                local block = W.ExtraBlock(index, false, key)
                values[key] = block and ("|cff888888%s (%s)|r"):format(R.CLASSES[key].name, block) or R.CLASSES[key].name
            end
            return values
        end,
        sorting = function()
            local order = Choices(index)
            table.insert(order, 1, "")
            return order
        end,
        get = function()
            local row = Row(index)
            return row and row.class or ""
        end,
        set = function(_, value)
            local rows, class = W.draft.classes, R.CLASSES[value]
            if not class then
                if rows[index] then table.remove(rows, index) end
                return
            end
            -- A hero class is its subclass: the choice is fixed from the start.
            rows[index] = {
                class = value, level = rows[index] and rows[index].level or 1,
                subclass = class.hero and class.subclasses[1] or "", skill = "",
            }
        end,
    }
end

local function LevelSlider(index, order)
    return Opt.Bounded({
        type = "range", order = order, min = 1, max = R.MAX_LEVEL - 1, step = 1,
        name = function()
            local class = RowClass(index)
            return class and ("Levels in " .. class.name) or "Levels"
        end,
        desc = "How many of the character's levels are in this class. Your first class keeps the rest, and at least one.",
        hidden = function() return not Row(index) end,
        get = function()
            local row = Row(index)
            return row and row.level or 1
        end,
        set = function(_, value)
            local row = Row(index)
            if row then row.level = value end
        end,
    }, function()
        if not Row(index) then return 1, 1 end
        return 1, math.max(1, Room(index))
    end)
end

-- A dropdown for a field of a row, from a list of names.
local function RowPicker(index, order, field, name, desc, list)
    return {
        type = "select", order = order, name = name, desc = desc,
        hidden = function() return not Row(index) or #list() == 0 end,
        values = function() return (Opt.ListMap(list(), true)) end,
        sorting = function() return (select(2, Opt.ListMap(list(), true))) end,
        get = function()
            local row = Row(index)
            return row and row[field] or ""
        end,
        set = function(_, value)
            local row = Row(index)
            if row then row[field] = value end
        end,
    }
end

-- Adds the rows to the options of the wizard's class page, under the class skills.
function W.AddMoreClassArgs(args)
    args.moreHeader = { type = "header", order = 7, name = "More classes", hidden = function() return not Open() end }
    args.moreSummary = {
        type = "description", order = 7.1, fontSize = "medium", name = Summary, dialogControl = "RPSheetTermLabel",
        hidden = function() return not Open() end,
    }
    for index = 1, W.MOST_EXTRAS do
        local order = 7.2 + index * 0.1
        args["moreClass" .. index] = ClassPicker(index, order)
        args["moreLevel" .. index] = LevelSlider(index, order + 0.01)
        args["moreSubclass" .. index] = RowPicker(index, order + 0.02, "subclass", "Subclass",
            "This class has a subclass from level 3 of the class.", function()
                local row, class = Row(index), RowClass(index)
                if not class or class.hero or row.level < R.SUBCLASS_LEVEL then return {} end
                return class.subclasses
            end)
        args["moreSkill" .. index] = RowPicker(index, order + 0.03, "skill", "Skill from this class",
            "The one skill this class gives when it isn't your first class.", function() return W.ExtraSkills(index) end)
        args["moreBreak" .. index] = { type = "description", order = order + 0.04, name = "", hidden = function() return not Shown(index) end }
    end
end
