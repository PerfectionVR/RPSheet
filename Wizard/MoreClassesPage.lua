-- The "More classes" part of the wizard's class step, for a character made above
-- level 1: a row per other class with its levels, its specialization, its subclass
-- once it has the levels for one, the one skill a few classes give and its Fighting
-- Styles (Wizard/Styles.lua). The rules behind it are in Wizard/MoreClasses.lua, the
-- text above the rows in Wizard/MoreClassSummary.lua; the scores of 13 are checked on
-- the ability score step.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

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

function W.MoreClassesOpen()
    return W.draft ~= nil and R.CLASSES[W.draft.class] ~= nil and W.draft.level >= 2
end
local Open = W.MoreClassesOpen

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
                subclass = class.hero and class.subclasses[1] or "", spec = "", skill = "",
                fightingStyle = "", fightingStyle2 = "",
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

-- A dropdown for a field of a row, from a list of names. `onSet(row, value)` runs
-- after a choice is made.
local function RowPicker(index, order, field, name, desc, list, onSet)
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
            if row and onSet then onSet(row, value) end
        end,
    }
end

-- A specialization pre-selects what it suggests, where that is a single choice.
local function FollowSpec(row, spec)
    local guide = R.SpecGuide(row.class, spec)
    if not guide then return end
    if guide.subclass and not R.CLASSES[row.class].hero then row.subclass = guide.subclass end
    if guide.style then row.fightingStyle = guide.style end
end

-- What the specialization suggests for the levels the row has, or "".
local function Suggested(index)
    local row = Row(index)
    local lines = row and R.SpecSuggestions(row.class, row.spec or "", row.level, 1) or {}
    if #lines == 0 then return "" end
    return ("%sSuggested for %s|r" .. "\n" .. "%s" .. "\n"):format(Opt.GOLD, row.spec, table.concat(lines, "\n"))
end

-- Adds the rows to the options of the wizard's class page, under the class skills.
function W.AddMoreClassArgs(args)
    args.moreHeader = { type = "header", order = 7, name = "More classes", hidden = function() return not Open() end }
    args.moreSummary = {
        type = "description", order = 7.1, fontSize = "medium", name = W.MoreClassSummary, dialogControl = "RPSheetTermLabel",
        hidden = function() return not Open() end,
    }
    for index = 1, W.MOST_EXTRAS do
        local order = 7.2 + index * 0.1
        local function Holder() return Row(index) end
        args["moreClass" .. index] = ClassPicker(index, order)
        args["moreLevel" .. index] = LevelSlider(index, order + 0.01)
        args["moreSubclass" .. index] = RowPicker(index, order + 0.02, "subclass", "Subclass",
            "This class has a subclass from level 3 of the class.", function()
                local row, class = Row(index), RowClass(index)
                if not class or class.hero or row.level < R.SUBCLASS_LEVEL then return {} end
                return class.subclasses
            end)
        args["moreSpec" .. index] = RowPicker(index, order + 0.015, "spec", "Specialization",
            "How you play this class. It has no rules of its own: it guides the choice of subclass and Fighting Style, and pre-selects what it suggests.",
            function()
                local class = RowClass(index)
                return class and class.specs or {}
            end, FollowSpec)
        args["moreSkill" .. index] = RowPicker(index, order + 0.03, "skill", "Skill from this class",
            "The one skill this class gives when it isn't your first class.", function() return W.ExtraSkills(index) end)
        args["moreStyle" .. index] = W.StyleOption(order + 0.032, 1, Holder)
        args["moreStyleTwo" .. index] = W.StyleOption(order + 0.034, 2, Holder)
        args["moreGuide" .. index] = {
            type = "description", order = order + 0.036, fontSize = "medium",
            name = function() return Suggested(index) end,
            hidden = function() return Suggested(index) == "" end,
        }
        args["moreBreak" .. index] = { type = "description", order = order + 0.04, name = "", hidden = function() return not Shown(index) end }
    end
end
