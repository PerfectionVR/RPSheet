-- Keeps the copies of listed spells on a sheet in step with the spell data, so a
-- correction there reaches the characters that already have the spell.
--   * A copy the player changed under Customize (spell.edited) keeps the fields that
--     page can change; the rest still follows.
--   * A copy saved before changes were recorded (spell.tracked is false) is compared
--     once with what its entry used to say (Data/SpellFormer.lua): a field that
--     holds a former value is brought up to date, and a field that holds anything
--     else was set by the player, which marks the copy as edited.
-- A spell whose level was changed, or that isn't in the data, is the player's own.
local _, ns = ...
local R = ns.Rules

-- The listed spell a spell on a sheet is a copy of, or nil.
function ns.ListedSpell(spell)
    local known = R.SPELLS[spell.name or ""]
    if known and known.level == spell.level then return known end
end

-- True for a field that says nothing while another field hides it: the save of a
-- spell that forces none, the die of a spell that rolls nothing.
local function Idle(spell, known, field)
    if field == "save" then return spell.kind ~= "SAVE" and known.kind ~= "SAVE" end
    local rolls = (spell.count or 0) > 0 or known.count > 0
    if field == "sides" or field == "dice" or field == "addMod" or field == "up" then return not rolls end
    if field == "scales" then return not rolls or known.level > 0 end
    return false
end

-- The first look at a copy saved before changes were recorded.
local function Compare(spell, known)
    local changed = false
    for _, field in ipairs(R.SPELL_OWN_FIELDS) do
        local value = spell[field]
        if value == nil or Idle(spell, known, field) or R.SpellHadValue(spell.name, field, value) then
            spell[field] = known[field]
        elseif value ~= known[field] then
            changed = true
        end
    end
    spell.edited = spell.edited or changed
    spell.tracked = true
end

-- Brings one spell up to date. `restore` makes it the listed spell again, whatever
-- the player changed.
function ns.RefreshSpell(spell, restore)
    local known = ns.ListedSpell(spell)
    if not known then return end
    if restore then spell.edited, spell.tracked = false, true end
    if not spell.tracked then Compare(spell, known) end
    if not spell.edited then
        for _, field in ipairs(R.SPELL_OWN_FIELDS) do spell[field] = known[field] end
    end
    for _, field in ipairs(R.SPELL_LISTED_FIELDS) do spell[field] = known[field] end
end

-- Sheet upkeep (called by ns.ApplyPreparedSpells).
function ns.RefreshListedSpells(sheet)
    for _, spell in ipairs(sheet.spells) do ns.RefreshSpell(spell) end
end
