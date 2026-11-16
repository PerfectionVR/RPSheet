-- "More classes" page under Customize: the classes taken after the first, set
-- directly. Nothing is refused here; what goes against the rules is said in red.
-- Levels are normally taken on the Character tab, which does check.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

-- Sets the character's levels in one class; the whole character's level follows.
local function SetClassLevel(key, levels)
    local sheet = Sheet()
    RPSheet:SetLevel(sheet.level + levels - ns.ClassLevel(sheet, key), key)
    ns.RebuildOptions()
    Opt.Changed()
end

-- The most levels a class can have while the character stays within the highest level.
local function Room(key)
    local sheet = Sheet()
    return ns.ClassLevel(sheet, key) + R.MAX_LEVEL - sheet.level
end

-- A dropdown for a field of a later class's entry, from one of the class's lists.
local function EntryPicker(key, field, order, name, desc, list)
    local function Entry() return ns.ClassEntry(Sheet(), key) end
    return {
        type = "select", order = order, name = name, desc = desc,
        hidden = function() return #list() == 0 end,
        values = function() return (Opt.ListMap(list(), true)) end,
        sorting = function() return (select(2, Opt.ListMap(list(), true))) end,
        get = function()
            local current = Entry() and Entry()[field] or ""
            for _, value in ipairs(list()) do
                if value == current then return current end
            end
            return ""
        end,
        set = function(_, value)
            Opt.Regrant(function()
                if Entry() then Entry()[field] = value end
            end)
        end,
    }
end

local STYLE_HELP = "The Fighting Style this class gives. Each class with the feature picks its own; a style picked twice only counts once."

-- The styles to offer for a slot of a later class: none before it has the feature.
local function Styles(key, slot)
    return ns.HasStyleSlot(Sheet(), slot, key) and R.FIGHTING_STYLE_ORDER or {}
end

-- The controls of one class taken after the first.
local function ClassGroup(key, order)
    local class = R.CLASSES[key]
    return {
        type = "group", inline = true, order = order, name = class.name,
        args = {
            levels = Opt.Bounded({
                type = "range", order = 1, name = "Levels", min = 1, max = R.MAX_LEVEL - 1, step = 1,
                desc = "Its features, resources and choices follow this level, and the character's level follows the levels of all its classes.",
                get = function() return ns.ClassLevel(Sheet(), key) end,
                set = function(_, value) SetClassLevel(key, value) end,
            }, function() return 1, Room(key) end),
            subclass = EntryPicker(key, "subclass", 2, "Subclass",
                "Its features start at level 3 of this class.", function() return class.subclasses end),
            spec = EntryPicker(key, "spec", 3, "Specialization",
                "The World of Warcraft specialization for this class. It is shown with the class.", function() return class.specs end),
            skill = EntryPicker(key, "skill", 4, "Skill from this class",
                "The one skill this class gives when it is taken after your first. Changing it adds the new skill; take the old one off under Proficiencies.",
                function()
                    local entry = ns.ClassEntry(Sheet(), key)
                    return ns.MulticlassSkills(Sheet(), key, entry and entry.skill or "")
                end),
            -- The class's own Fighting Styles, once it has the feature. Every style is
            -- offered here; the level dialog only offers the ones the class may take.
            style = EntryPicker(key, "fightingStyle", 4.1, "Fighting Style", STYLE_HELP, function() return Styles(key, 1) end),
            style2 = EntryPicker(key, "fightingStyle2", 4.2, "Second Fighting Style", STYLE_HELP, function() return Styles(key, 2) end),
            remove = {
                type = "execute", order = 5, name = "Remove this class",
                desc = "Takes every level of this class off the character, with the features and choices they gave.",
                confirm = function() return ("Remove every %s level from this character?"):format(class.name) end,
                func = function() SetClassLevel(key, 0) end,
            },
        },
    }
end

local args = {
    intro = {
        type = "description", order = 1,
        name = "A character can have levels in more than one class. The class under Class and origin is its first: it gave the saving throws and the full training. Each class listed here has its own level, hit die, features, resources and spells; the character's level is all of them together.\n",
    },
    summary = {
        type = "description", order = 2, fontSize = "medium",
        name = function()
            local sheet = Sheet()
            local lines = { Opt.GOLD .. (ns.IsMulticlass(sheet) and ns.ClassLine(sheet) or "One class.") .. "|r" }
            for _, warning in ipairs(ns.MulticlassWarnings(sheet)) do lines[#lines + 1] = Opt.RED .. warning .. "|r" end
            return table.concat(lines, "\n") .. "\n"
        end,
    },
    first = Opt.Bounded({
        type = "range", order = 3, min = 1, max = R.MAX_LEVEL, step = 1,
        name = function()
            local class = RPSheet:ClassData()
            return "Levels in " .. (class and class.name or "the first class")
        end,
        hidden = function() return not ns.IsMulticlass(Sheet()) end,
        get = function() return ns.ClassLevel(Sheet(), Sheet().class) end,
        set = function(_, value) SetClassLevel(Sheet().class, value) end,
    }, function() return 1, Room(Sheet().class) end),
    add = {
        type = "select", order = 4, name = "Add a class",
        desc = "Adds one level of the class. A hero class comes with its subclass.",
        hidden = function() return RPSheet:ClassData() == nil end,
        disabled = function() return Sheet().level >= R.MAX_LEVEL end,
        values = function()
            local sheet, values = Sheet(), {}
            for _, key in ipairs(R.CLASS_ORDER) do
                if ns.ClassLevel(sheet, key) == 0 then values[key] = R.CLASSES[key].name end
            end
            return values
        end,
        get = function() return "" end,
        set = function(_, value) SetClassLevel(value, 1) end,
    },
    full = {
        type = "description", order = 5,
        name = function() return ("%sThe character is level %d: lower a class's levels to make room for another.|r"):format(Opt.RED, R.MAX_LEVEL) end,
        hidden = function() return Sheet().level < R.MAX_LEVEL end,
    },
}

Opt.custom.multiclass = { type = "group", order = 6.5, name = "More classes", args = args }

-- One group per class the character has beside its first.
table.insert(Opt.rebuilders, function()
    for key in pairs(args) do
        if key:find("^later") then args[key] = nil end
    end
    for index, key in ipairs(ns.ExtraClassKeys(Sheet())) do
        args["later" .. key] = ClassGroup(key, 10 + index)
    end
end)
