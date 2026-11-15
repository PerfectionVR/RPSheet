-- The Fighting Styles of a wizard character: one for each of its classes that has the
-- feature by its own level, and a second where its subclass gives another (a Champion
-- from level 7 of the class). The first class's picks are draft.fightingStyle and
-- draft.fightingStyle2; a later class keeps the same two fields on its row
-- (Wizard/MoreClasses.lua). A style can be taken once, whichever class has it.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local NAMES = { "Fighting Style", "Second Fighting Style" }

-- The subclass a class of the draft ends up with: a hero class is its subclass, any
-- other has one from level 3 of the class.
function W.EntrySubclass(entry)
    local class = R.CLASSES[entry.class]
    if not class then return "" end
    if class.hero then return class.subclasses[1] or "" end
    return entry.level >= R.SUBCLASS_LEVEL and entry.subclass or ""
end

-- Every style the draft's classes pick, the first class first:
--   { class = <class key>, slot = 1 or 2, holder = <the draft or the class's row>,
--     field = <the holder's field>, name = <the style picked, or ""> }
function W.StyleSlots()
    local slots = {}
    if not W.draft or not R.CLASSES[W.draft.class] then return slots end
    for index, entry in ipairs(W.DraftClasses()) do
        local holder = index == 1 and W.draft or entry
        for slot, field in ipairs(ns.STYLE_FIELDS) do
            local level = ns.StyleLevel(entry.class, W.EntrySubclass(entry), slot)
            if level and entry.level >= level then
                slots[#slots + 1] = { class = entry.class, slot = slot, holder = holder, field = field, name = holder[field] or "" }
            end
        end
    end
    return slots
end

function W.HasStyleSlot(key, slot)
    for _, each in ipairs(W.StyleSlots()) do
        if each.class == key and each.slot == slot then return true end
    end
    return false
end

-- The styles a class can take in a slot: its own, without those picked elsewhere.
function W.StyleChoices(key, slot)
    local taken, names = {}, {}
    -- Where two hold the same style (a level raised after both were picked), the
    -- first keeps it and only the later one is asked again.
    local mine, passed
    for _, other in ipairs(W.StyleSlots()) do
        if other.class == key and other.slot == slot then mine = other.name end
    end
    for _, other in ipairs(W.StyleSlots()) do
        if other.class == key and other.slot == slot then
            passed = true
        elseif not (passed and other.name == mine) then
            taken[other.name] = true
        end
    end
    for _, name in ipairs(ns.StyleChoices({ class = key, passives = {} }, slot)) do
        if not taken[name] then names[#names + 1] = name end
    end
    return names
end

-- True if a class could take that style in a slot.
function W.StyleOpen(key, slot, name)
    for _, each in ipairs(W.StyleChoices(key, slot)) do
        if each == name then return true end
    end
    return false
end

-- What is still to be chosen, or nil.
function W.StyleProblem()
    for _, each in ipairs(W.StyleSlots()) do
        local class, fits = R.CLASSES[each.class].name, false
        for _, name in ipairs(W.StyleChoices(each.class, each.slot)) do
            if name == each.name then fits = true end
        end
        if each.name == "" then
            return (each.slot == 1 and "Choose a Fighting Style for %s." or "Choose the second Fighting Style %s has by its level."):format(class)
        elseif not fits then
            return ("%s can't be the %s of %s: it is picked for another class, or it isn't one of that class's. Pick another."):format(each.name, NAMES[each.slot]:lower(), class)
        end
    end
end

-- Puts the picks on the new sheet, each with its class (Sheet/FightingStyles.lua).
-- Called once the other classes are on it.
function W.ApplyStyles(sheet)
    for _, each in ipairs(W.StyleSlots()) do
        ns.SetClassStyle(sheet, each.class, each.slot, each.name)
    end
end

local function Help()
    local lines = {}
    for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
        lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
    end
    return table.concat(lines, "\n\n")
end

-- A dropdown for one style of one class. `entry()` is the class's holder: the draft
-- for the first class, a row for a later one, nil when there is none.
function W.StyleOption(order, slot, entry)
    local field = ns.STYLE_FIELDS[slot]
    local function Key()
        local holder = W.draft and entry()
        return holder and R.CLASSES[holder.class] and holder.class or nil
    end
    local function Choices()
        return Key() and W.StyleChoices(Key(), slot) or {}
    end
    return {
        type = "select", order = order, name = NAMES[slot], desc = Help,
        -- Only when the class has the feature by its own level.
        hidden = function() return not Key() or not W.HasStyleSlot(Key(), slot) end,
        values = function() return (Opt.ListMap(Choices(), true)) end,
        sorting = function() return (select(2, Opt.ListMap(Choices(), true))) end,
        get = function() return entry()[field] or "" end,
        set = function(_, value) entry()[field] = value end,
    }
end
