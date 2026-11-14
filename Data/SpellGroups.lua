-- Spells come in two groups that are shown apart wherever spells are listed: the core
-- spells, and the spells of Azeroth that the setting adds (R.AZEROTH_SPELLS, filled in
-- Data/SpellsAzeroth.lua).
local _, ns = ...
local R = ns.Rules

R.SPELL_GROUPS = { "Core spells", "Spells of Azeroth" }
R.SPELL_GROUP_TAG = { "", "Azeroth" } -- short form, behind a spell's name in a dropdown

-- 1 for a core spell, 2 for one of Azeroth.
function R.SpellGroup(name)
    return R.AZEROTH_SPELLS[name] and 2 or 1
end

-- Sorting for a list of spell names: by group, then level, then name.
function R.SpellBefore(a, b)
    local groupA, groupB = R.SpellGroup(a), R.SpellGroup(b)
    if groupA ~= groupB then return groupA < groupB end
    if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
    return a < b
end

-- "Fireball (3rd level)" or "Frost Nova (2nd level, Azeroth)", for a dropdown.
function R.SpellChoiceLabel(name)
    local tag = R.SPELL_GROUP_TAG[R.SpellGroup(name)]
    return ("%s (%s%s)"):format(name, R.SPELL_LEVELS[R.SPELLS[name].level]:lower(), tag ~= "" and (", " .. tag) or "")
end
