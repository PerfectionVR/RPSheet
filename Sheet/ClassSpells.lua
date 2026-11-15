-- Which class a spell belongs to, for a character with several classes: every class
-- prepares its own spells and casts them with its own spellcasting ability.
-- A spell on the sheet names its class in spell.class (a class key). A spell without
-- one belongs to the first of the character's classes that casts spells, so nothing
-- changes for a character with one class.
local _, ns = ...
local R = ns.Rules

-- The first class of the character that casts spells (a view, or the sheet itself for
-- a character of one class), or nil.
function ns.CasterView(sheet)
    for _, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        if class and class.caster then return view end
    end
end

-- Keys of the character's classes that cast spells, the first class first.
function ns.CasterKeys(sheet)
    local keys = {}
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        if R.CLASSES[key].caster then keys[#keys + 1] = key end
    end
    return keys
end

-- The class key a spell of the character is cast as, or nil for a character that
-- doesn't cast. `spell` may be nil: the class spells go to by default.
function ns.SpellClass(sheet, spell)
    local keys = ns.CasterKeys(sheet)
    for _, key in ipairs(keys) do
        if spell and spell.class == key then return key end
    end
    return keys[1]
end

-- What a spell is called in a list of the character's spells. Two classes that each
-- prepare the same spell both have it, each cast with its own ability, so a spell
-- that is on the list more than once names its class: "Cure Wounds (Druid)".
function ns.SpellRowName(sheet, spell)
    local same = 0
    for _, other in ipairs(sheet.spells or {}) do
        if other.name == spell.name then same = same + 1 end
    end
    local class = same > 1 and R.CLASSES[ns.SpellClass(sheet, spell) or ""]
    return class and ("%s (%s)"):format(spell.name, class.name) or spell.name
end

-- The class key to write on a spell that a class's upkeep puts on the sheet: only a
-- view of one class of several has one. A character of one class leaves it empty.
function ns.SpellTag(sheet)
    return sheet.viewOf and sheet.class or nil
end

-- True if upkeep for the class `tag` may treat a spell added by hand as its own.
function ns.SpellIsOf(spell, tag)
    return not tag or (spell.class or "") == "" or spell.class == tag
end

-- { [name] = true } for what the character's other classes picked from their lists of
-- one kind (`lists` maps a Player's Handbook class to its pick list), so that one
-- class's upkeep leaves the other classes' spells on the sheet.
function ns.ForeignPicks(view, lists)
    local names = {}
    if not view.viewOf then return names end
    for _, other in ipairs(ns.ClassViews(view.viewOf)) do
        local class = R.CLASSES[other.class]
        local key = other ~= view and class and lists[class.base]
        if key and ns.PickLimit(key, other.class, other.level) > 0 then
            for name in pairs(other.picks[key] or {}) do names[name] = true end
        end
    end
    return names
end

-- { [name] = true } for the spells a class of several still has on the list with a
-- mark of one kind (`prefix`, such as "spell:"). Two classes can have the same spell
-- under the same mark; when the player deletes one, the mark is noted as deleted
-- (sheet.dismissed), and the class whose entry is still there isn't the one meant.
function ns.OwnEntries(sheet, prefix, tag)
    local names = {}
    if not tag then return names end
    for _, spell in ipairs(sheet.spells) do
        if spell.class == tag and (spell.auto or "") == prefix .. spell.name then names[spell.name] = true end
    end
    return names
end

-- Runs one class's upkeep (`apply`) for every class of the character.
function ns.ForEachClass(sheet, apply)
    for _, view in ipairs(ns.ClassViews(sheet)) do apply(view) end
end
