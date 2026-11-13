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

---------------------------------------------------------------------------
-- Sliders
---------------------------------------------------------------------------
-- Makes a slider only reach the values it may take right now, so it never has to
-- snap back. `limits()` returns the lowest and highest allowed value; the slider is
-- greyed out when there is nothing to choose. The options library reads `hidden`
-- before it sets a slider up, which is where the range is brought up to date.
function Opt.Bounded(option, limits)
    local hidden, disabled = option.hidden, option.disabled
    local function Range()
        local low, high = limits()
        local current = option.get()
        if type(current) == "number" then low, high = math.min(low, current), math.max(high, current) end
        return low, math.max(low, high)
    end
    option.softMin, option.softMax = nil, nil
    option.hidden = function(...)
        local isHidden = hidden
        if type(hidden) == "function" then isHidden = hidden(...) end
        if not isHidden then option.min, option.max = Range() end
        return isHidden or false
    end
    option.disabled = function(...)
        local low, high = Range()
        if high <= low then return true end
        if type(disabled) == "function" then return disabled(...) end
        return disabled or false
    end
    return option
end

-- Highest score point buy can still afford for one ability, given the others.
function Opt.PointBuyMax(base, stat)
    local spent = 0
    for _, other in ipairs(R.STATS) do spent = spent + (R.COST[base[other]] or 0) end
    local free = R.POINTS - spent + (R.COST[base[stat]] or 0)
    local best = R.BASE_MIN
    for value = R.BASE_MIN, R.BASE_MAX do
        if R.COST[value] <= free then best = value end
    end
    return best
end

-- Most background points one ability can hold, given what the others took.
function Opt.BonusMax(bonus, stat)
    local spent = 0
    for _, other in ipairs(R.STATS) do spent = spent + (bonus[other] or 0) end
    return math.min(R.BONUS_MAX, (bonus[stat] or 0) + R.BONUS_TOTAL - spent)
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
