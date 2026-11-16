-- The spells Eldritch Invocations let a Warlock cast without a slot (data in
-- Data/InvocationSpells.lua): on the spell list marked auto = "invocation:<spell>",
-- cast with the Warlock's ability, and cast without a slot through ns.SpellChoice
-- (Sheet/SpellChoices.lua, Actions/SpellChoices.lua) as often as the invocation
-- allows. Agonizing Blast ticks "Add spellcasting modifier" on a damaging Warlock
-- cantrip the character knows, one for each time it is taken.
local _, ns = ...
local R = ns.Rules

local PREFIX = "invocation:"
local NONE = {}

-- The Warlock class of the character (a key), or nil.
local function WarlockKey(sheet)
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        if R.CLASSES[key].base == "Warlock" then return key end
    end
end

-- The invocations picked, as { [name] = true }, while the list is the character's.
local function Picked(sheet)
    local picks = type(sheet.picks) == "table" and sheet.picks.invocations
    if type(picks) ~= "table" or ns.SheetPickLimit(sheet, "invocations") <= 0 then return NONE end
    return picks
end

-- True if the character has Pact of the Blade: a weapon can be ticked as its pact
-- weapon (Options/Weapons.lua, Sheet/Armoury.lua).
function ns.HasPactBlade(sheet)
    return Picked(sheet)["Pact of the Blade"] == true
end

-- { [spell] = { invocation =, data = } } for the spells the invocations give.
function ns.InvocationSpells(sheet)
    local found = {}
    local names = {}
    for name, on in pairs(Picked(sheet)) do
        if on and R.INVOCATION_SPELLS[name] then names[#names + 1] = name end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local data = R.INVOCATION_SPELLS[name]
        if R.SPELLS[data.spell] and not found[data.spell] then found[data.spell] = { invocation = name, data = data } end
    end
    return found
end

-- How a spell is cast without a slot because an invocation gives it, in the form of
-- an entry of R.SPELL_CHOICES, or nil.
function ns.InvocationSpellCasting(sheet, name)
    local given = ns.InvocationSpells(sheet)[name]
    if not given or (sheet.dismissed or NONE)[PREFIX .. name] then return end
    local data = given.data
    local when = data.note and (" " .. data.note) or ""
    return {
        feature = given.invocation, spellLevel = R.SPELLS[name].level, once = data.once == true, maxDice = data.maxDice,
        mark = "invocation",
        note = data.once and ("%s: you cast it once without a spell slot%s; a long rest brings that casting back. Other castings spend a slot."):format(given.invocation, when)
            or ("%s: you cast it without a spell slot%s, as often as you like."):format(given.invocation, when),
    }
end

-- Agonizing Blast: the damaging Warlock cantrips known, Eldritch Blast first, that get
-- the Charisma modifier on their damage: as many as the times it was taken.
local function Agonizing(sheet)
    local count = 0
    for name, on in pairs(Picked(sheet)) do
        if on and name:find("^Agonizing Blast") then count = count + 1 end
    end
    local list = {}
    local onList = {}
    for _, name in ipairs(R.SPELL_LISTS.Warlock or NONE) do onList[name] = true end
    for _, spell in ipairs(sheet.spells) do
        if spell.level == 0 and onList[spell.name] and (spell.count or 0) > 0 and spell.dice == "DAMAGE" then list[#list + 1] = spell end
    end
    table.sort(list, function(a, b)
        if (a.name == "Eldritch Blast") ~= (b.name == "Eldritch Blast") then return a.name == "Eldritch Blast" end
        return a.name < b.name
    end)
    local chosen = {}
    for index = 1, math.min(count, #list) do chosen[list[index]] = true end
    for _, spell in ipairs(sheet.spells) do
        if chosen[spell] then
            spell.addMod, spell.agonizing = true, true
        elseif spell.agonizing then
            spell.addMod, spell.agonizing = false, nil
        end
    end
end

-- Sheet upkeep, after the class's spells and the picks: keeps the list in step.
function ns.ApplyInvocationSpells(sheet)
    local wanted = ns.InvocationSpells(sheet)
    for name in pairs(wanted) do
        if sheet.dismissed[PREFIX .. name] then wanted[name] = nil end
    end
    -- A spell another source put on the list isn't listed twice.
    local have = {}
    for _, spell in ipairs(sheet.spells) do
        local auto = spell.auto or ""
        if wanted[spell.name] and not auto:find("^" .. PREFIX) and R.SPELLS[spell.name].level == spell.level then have[spell.name] = true end
    end
    for index = #sheet.spells, 1, -1 do
        local own = (sheet.spells[index].auto or ""):match("^" .. PREFIX .. "(.+)$")
        if own then
            if wanted[own] and not have[own] then have[own] = true else table.remove(sheet.spells, index) end
        end
    end
    local warlock = WarlockKey(sheet)
    local names = {}
    for name in pairs(wanted) do
        if not have[name] then names[#names + 1] = name end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.free, spell.auto, spell.class = true, PREFIX .. name, warlock
        sheet.spells[#sheet.spells + 1] = spell
    end
    Agonizing(sheet)
end
