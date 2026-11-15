-- The spell list of each class. Most classes have the list of their Player's Handbook
-- class (R.SPELL_LISTS, filled by the spell files above). Two don't: a Death Knight and
-- a Demon Hunter cast from the Paladin's and the Ranger's list as the core rules have
-- them, without the spells the setting adds for Paladins and Hunters.
-- Everything that asks "is this a spell of that class?" asks here: the pick lists
-- (Sheet/PreparedPicks.lua), the Spells page, the spellbook.
local _, ns = ...
local R = ns.Rules

-- [class key] = the spells of its core class's list that it doesn't get.
local LEFT_OUT = {
    DEATHKNIGHT = { "Consecration", "Guided Prayer", "Divine Shield" },
    DEMONHUNTER = { "Freezing Trap", "Serpent Sting", "Explosive Trap" },
}

local lists, sets = {}, {} -- by class key, made when first asked for

-- The names on the spell list of a class (a class key), in the order of the data.
-- An empty list for a class that has none.
function R.ClassSpellList(classKey)
    if lists[classKey] then return lists[classKey] end
    local class = R.CLASSES[classKey]
    local names, set, without = {}, {}, {}
    for _, name in ipairs(LEFT_OUT[classKey] or {}) do without[name] = true end
    for _, name in ipairs(class and R.SPELL_LISTS[class.base] or {}) do
        if not without[name] and not set[name] then
            names[#names + 1], set[name] = name, true
        end
    end
    lists[classKey], sets[classKey] = names, set
    return names
end

-- True if a spell is on the spell list of a class.
function R.OnClassSpellList(classKey, name)
    R.ClassSpellList(classKey)
    return sets[classKey][name] == true
end
