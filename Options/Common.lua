-- Shared pieces for the settings, the character editor and the creation wizard:
-- dropdown lists and the helper that binds an option to a field.
--
-- Each tab file adds its AceConfig group to Opt.tabs; each list file (resources,
-- weapons, abilities, passives) adds a definition to Opt.lists. Options/Root.lua
-- assembles them.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Opt.rebuilders holds functions that ns.RebuildOptions runs, for tabs whose rows
-- depend on the sheet.
local Opt = { tabs = {}, lists = {}, rebuilders = {} }
ns.Opt = Opt

Opt.RED, Opt.GOLD, Opt.GREEN = "|cffff5555", "|cffffd100", "|cff80ff80"

function Opt.Sheet() return RPSheet:Sheet() end
function Opt.Changed() RPSheet:SheetChanged() end

---------------------------------------------------------------------------
-- Dropdown lists
---------------------------------------------------------------------------
-- { key = entry.name } for a rules table such as Rules.CLASSES.
function Opt.NameMap(source, order)
    local values = {}
    for _, key in ipairs(order) do values[key] = source[key].name end
    return values
end

-- { name = name } and its order, for a plain list of names. `withNone` adds an empty choice.
function Opt.ListMap(list, withNone)
    local values, order = {}, {}
    if withNone then
        values[""] = "None"
        order[1] = ""
    end
    for _, name in ipairs(list or {}) do
        values[name] = name
        order[#order + 1] = name
    end
    return values, order
end

-- A rules table as a dropdown with an empty "None" choice first.
local function WithNone(source, sourceOrder)
    local values, order = Opt.NameMap(source, sourceOrder), { "" }
    values[""] = "None"
    for _, key in ipairs(sourceOrder) do order[#order + 1] = key end
    return values, order
end

Opt.STAT_VALUES, Opt.STAT_OR_NONE, Opt.STAT_OR_NONE_ORDER = {}, { [""] = "None" }, { "" }
for _, stat in ipairs(R.STATS) do
    Opt.STAT_VALUES[stat] = R.STAT_NAMES[stat]
    Opt.STAT_OR_NONE[stat] = R.STAT_NAMES[stat]
    table.insert(Opt.STAT_OR_NONE_ORDER, stat)
end

Opt.CLASS_VALUES, Opt.CLASS_ORDER = WithNone(R.CLASSES, R.CLASS_ORDER)
Opt.SPECIES_VALUES, Opt.SPECIES_ORDER = WithNone(R.SPECIES, R.SPECIES_ORDER)
Opt.BACKGROUND_VALUES, Opt.BACKGROUND_ORDER = WithNone(R.BACKGROUNDS, R.BACKGROUND_ORDER)
Opt.ARMOR_VALUES = Opt.NameMap(R.ARMOR, R.ARMOR_ORDER)
Opt.ALIGNMENT_VALUES, Opt.ALIGNMENT_ORDER = Opt.ListMap(R.ALIGNMENTS, true)

Opt.ARRAY_VALUES, Opt.ARRAY_ORDER = {}, {}
for _, value in ipairs(R.STANDARD_ARRAY) do
    Opt.ARRAY_VALUES[value] = tostring(value)
    table.insert(Opt.ARRAY_ORDER, value)
end

Opt.DIE_VALUES, Opt.DIE_ORDER = {}, { 3, 4, 6, 8, 10, 12, 20 }
for _, sides in ipairs(Opt.DIE_ORDER) do Opt.DIE_VALUES[sides] = "d" .. sides end

-- Names of everything an ability can spend or restore.
function Opt.TrackerValues()
    local values = { [""] = "None" }
    for _, tracker in ipairs(RPSheet:GetTrackers()) do values[tracker.label] = tracker.label end
    return values
end

-- Names of the passives an ability can switch.
function Opt.PassiveValues()
    local values = { [""] = "None" }
    for _, passive in ipairs(RPSheet:Sheet().passives) do values[passive.name] = passive.name end
    return values
end

---------------------------------------------------------------------------
-- Binding
---------------------------------------------------------------------------
-- Adds get/set to an option for the field `key` of the table returned by `source()`.
-- Text fields are trimmed and stripped of colour codes and line breaks.
function Opt.With(option, source, key, isText)
    option.get = function() return source()[key] end
    option.set = function(_, value)
        if isText then value = value:trim():gsub("[|\n\r]", "") end
        source()[key] = value
        Opt.Changed()
    end
    return option
end

-- True if the sheet's background lets this ability be raised (any, when none is chosen).
function Opt.BackgroundAllows(backgroundKey, stat)
    local background = R.BACKGROUNDS[backgroundKey]
    if not background then return true end
    for _, allowed in ipairs(background.stats) do
        if allowed == stat then return true end
    end
    return false
end

-- After a choice that hands things out (class, species, lineage, background,
-- allegiance, level): add what it grants, then refresh the editor and the sheet.
function Opt.Regrant()
    ns.ApplyGrants(RPSheet:Sheet())
    ns.NormalizeState(RPSheet:State())
    ns.RebuildOptions()
    Opt.Changed()
end
