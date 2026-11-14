-- The spells a class prepares from its own list, as pick lists for the level dialog
-- (see Data/Picks.lua for the form):
--   prepared<Class>  one per Player's Handbook class that prepares from its class list
-- A Mage is not here: it prepares from the spellbook (Data/SpellPicks.lua).
-- How many are prepared at a level is R.SPELLS_PREPARED, the table the Spells page
-- counts against, so the dialog and that page agree.
-- A spell can be picked from the character level that brings the first slot of its
-- level; spells above that are hidden. `follows` makes the dialog drop a pick that a
-- subclass chosen there turns into an always-prepared spell.
-- The lists are `custom`: Sheet/PreparedPicks.lua puts the spells on the sheet.
local _, ns = ...
local R = ns.Rules

-- The first character level with a slot of each spell level, for a kind of caster
-- (the same reading of the slot tables as RPSheet:SpellSlots).
local function SlotLevels(caster)
    local first = {}
    for level = R.MAX_LEVEL, 1, -1 do
        if caster == "PACT" then
            -- Pact slots are all of one level; lower spells are cast with them too.
            for spellLevel = 1, R.PACT_SLOTS[level][2] do first[spellLevel] = level end
        else
            local row = R.FULL_SLOTS[caster == "HALF" and math.ceil(level / 2) or level]
            for spellLevel in ipairs(row) do first[spellLevel] = level end
        end
    end
    return first
end

local function Caster(base)
    for _, key in ipairs(R.CLASS_ORDER) do
        if R.CLASSES[key].base == base then return R.CLASSES[key].caster end
    end
end

R.PREPARED_LISTS = {} -- [class] = key of its pick list
for _, base in ipairs({ "Bard", "Cleric", "Druid", "Paladin", "Ranger", "Sorcerer", "Warlock" }) do
    local caster, numbers = Caster(base), R.SPELLS_PREPARED[base]
    local items, order, known = {}, {}, {}
    if caster and numbers then
        local first = SlotLevels(caster)
        for _, name in ipairs(R.SPELL_LISTS[base] or {}) do
            local spell = R.SPELLS[name]
            -- A spell of a level the class never has slots for is left out (a
            -- Warlock's 6th level and higher come from Mystic Arcanum).
            if spell and spell.level > 0 and first[spell.level] and not items[name] then
                items[name] = {
                    desc = spell.desc, level = first[spell.level],
                    group = ("%s: %s"):format(R.SPELL_GROUPS[R.SpellGroup(name)], R.SPELL_LEVELS[spell.level]:lower()),
                }
                order[#order + 1] = name
            end
        end
        table.sort(order, R.SpellBefore)
        for level = 1, R.MAX_LEVEL do known[level] = { level, numbers[level] or 0 } end
    end
    if #order > 0 then
        local key = "prepared" .. base
        R.PICK_LISTS[key] = {
            title = "Prepared spells", base = base, custom = true, hideBlocked = true, follows = "subclass",
            known = known, items = items, order = order,
        }
        R.PREPARED_LISTS[base] = key
        R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = key
    end
end
