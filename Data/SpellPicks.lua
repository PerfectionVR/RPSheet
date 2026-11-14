-- Spells a character chooses when it is made and when it levels, as pick lists for the
-- level dialog (see Data/Picks.lua for the form):
--   cantrips<Class>  the cantrips a spellcasting class knows
--   spellbook        the spells a Mage writes into the spellbook: six, and two per level
-- Both are `custom`: Sheet/SpellPicks.lua and Sheet/Spellbook.lua put them on the sheet.
local _, ns = ...
local R = ns.Rules

-- Cantrips, one list per Player's Handbook class that knows any.
R.CANTRIP_LISTS = {} -- [class] = key of its pick list
for _, base in ipairs({ "Cleric", "Druid", "Sorcerer", "Warlock", "Wizard" }) do
    local items, order = {}, {}
    for _, name in ipairs(R.SPELL_LISTS[base] or {}) do
        local spell = R.SPELLS[name]
        if spell and spell.level == 0 and not items[name] then
            items[name] = { desc = spell.desc }
            order[#order + 1] = name
        end
    end
    table.sort(order)
    if R.CANTRIPS_KNOWN[base] and #order > 0 then
        local key = "cantrips" .. base
        R.PICK_LISTS[key] = { title = "Cantrips", base = base, custom = true, known = R.CANTRIPS_KNOWN[base], items = items, order = order }
        R.CANTRIP_LISTS[base] = key
        R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = key
    end
end

-- The spellbook. A spell of level n can be written in from character level 2n - 1,
-- when the first slots of that level arrive; spells above that are hidden.
local BOOK_CLASS = "Wizard"
local items, order, known = {}, {}, {}
for _, name in ipairs(R.SPELL_LISTS[BOOK_CLASS] or {}) do
    local spell = R.SPELLS[name]
    if spell and spell.level > 0 and not items[name] then
        items[name] = { desc = spell.desc, level = 2 * spell.level - 1, tag = R.ORDINALS[spell.level] }
        order[#order + 1] = name
    end
end
table.sort(order, function(a, b)
    if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
    return a < b
end)
for level = 1, R.MAX_LEVEL do known[level] = { level, 6 + 2 * (level - 1) } end

R.PICK_LISTS.spellbook = {
    title = "Spellbook spells", base = BOOK_CLASS, custom = true, hideBlocked = true,
    known = known, items = items, order = order,
}
R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = "spellbook"
