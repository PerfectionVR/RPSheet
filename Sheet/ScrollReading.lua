-- Who can read a spell scroll, and how far its reader's own casting reaches.
-- A scroll can be read when its spell is on the spell list of one of the reader's
-- classes; spells a class feature always keeps prepared count as that class's.
-- A spell of a higher level than that class prepares at the reader's level in it
-- can still be tried, with an ability check (Actions/Scrolls.lua).
local _, ns = ...
local R = ns.Rules

local listed -- [Player's Handbook class] = { [spell name] = true }, built when first asked
local function OnList(base, name)
    if not listed then
        listed = {}
        for class, names in pairs(R.SPELL_LISTS) do
            listed[class] = {}
            for _, spell in ipairs(names) do listed[class][spell] = true end
        end
    end
    return listed[base] ~= nil and listed[base][name] == true
end

-- The class the character reads a scroll of this spell as, and the highest spell
-- level that class prepares at its level; nil when the spell is on none of its lists.
-- Of several classes that have the spell, the one that reaches highest reads it.
function ns.ScrollReader(sheet, name)
    local best, reach
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local class = R.CLASSES[key]
        if class and class.caster and OnList(class.base, name) then
            local level = ns.ClassSpellLevel(class, ns.ClassLevel(sheet, key))
            if not reach or level > reach then best, reach = key, level end
        end
    end
    if best then return best, reach end
    -- A spell a feature keeps prepared is the character's own, whatever list it is from.
    if ns.AlwaysPrepared(sheet)[name] then
        for _, spell in ipairs(sheet.spells or {}) do
            if spell.name == name then
                local key = ns.SpellClass(sheet, spell)
                local class = key and R.CLASSES[key]
                if class then return key, ns.ClassSpellLevel(class, ns.ClassLevel(sheet, key)) end
            end
        end
    end
end
