-- A Mage's spellbook: the spells of level 1 and higher the character owns. The spells
-- on the sheet's spell list are the ones prepared from it. Cantrips are not in the book.
-- The book has two parts:
--   sheet.picks.spellbook[<name>] = true  the spells the rules give: six, and two per
--                                         level, chosen in the level dialog
--   sheet.spellbook[<name>] = true        spells on top of those, copied in by hand
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local BOOK_CLASS = "Wizard" -- the Player's Handbook class that keeps a spellbook

function ns.HasSpellbook(sheet)
    local class = R.CLASSES[sheet.class]
    return class ~= nil and class.base == BOOK_CLASS
end

local function Parts(sheet)
    if type(sheet.spellbook) ~= "table" then sheet.spellbook = {} end
    if type(sheet.picks.spellbook) ~= "table" then sheet.picks.spellbook = {} end
    return sheet.picks.spellbook, sheet.spellbook
end

-- Spells the rules put in the book at a level. Spells copied in come on top.
function ns.SpellbookSize(sheet)
    return ns.PickLimit("spellbook", sheet.class, sheet.level)
end

function ns.InSpellbook(sheet, name)
    local picks, extra = Parts(sheet)
    return picks[name] == true or extra[name] == true
end

local function Picked(sheet)
    local count = 0
    for name in pairs((Parts(sheet))) do
        if R.SPELLS[name] then count = count + 1 end
    end
    return count
end

-- Writes a spell into the book: as one of the level's spells while those aren't all
-- chosen, as a copied-in spell after that.
function ns.SpellbookAdd(sheet, name)
    if not R.SPELLS[name] or ns.InSpellbook(sheet, name) then return end
    local picks, extra = Parts(sheet)
    if Picked(sheet) < ns.SpellbookSize(sheet) then picks[name] = true else extra[name] = true end
end

function ns.SpellbookRemove(sheet, name)
    local picks, extra = Parts(sheet)
    picks[name], extra[name] = nil, nil
end

local ByLevel = R.SpellBefore -- core spells first, then by level

-- Names of the spells in the book: the core spells, then those of Azeroth, each lowest
-- level first.
function ns.SpellbookNames(sheet)
    local picks, extra = Parts(sheet)
    local seen, names = {}, {}
    for _, part in ipairs({ picks, extra }) do
        for name in pairs(part) do
            if R.SPELLS[name] and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end
    table.sort(names, ByLevel)
    return names
end

-- Spells of the class that could still be written into the book: level 1 and higher,
-- up to the highest level the character has slots for.
function ns.SpellbookChoices(sheet, highest)
    local class, names = R.CLASSES[sheet.class], {}
    for _, name in ipairs(class and R.SPELL_LISTS[class.base] or {}) do
        local level = R.SPELLS[name].level
        if level > 0 and level <= highest and not ns.InSpellbook(sheet, name) then names[#names + 1] = name end
    end
    table.sort(names, ByLevel)
    return names
end

-- Sheet upkeep (see Sheet/ClassFeatures.lua). A prepared spell has to be in the book,
-- so spells added to the spell list by hand are written into it; and copied-in spells
-- count as the level's own spells while those aren't all chosen.
function ns.ApplySpellbook(sheet)
    if not ns.HasSpellbook(sheet) then return end
    local picks, extra = Parts(sheet)
    local list = {}
    for _, name in ipairs(R.SPELL_LISTS[BOOK_CLASS] or {}) do list[name] = true end
    for _, spell in ipairs(sheet.spells) do
        local known = R.SPELLS[spell.name]
        if known and known.level > 0 and known.level == spell.level and list[spell.name] and not spell.free then
            ns.SpellbookAdd(sheet, spell.name)
        end
    end
    local names = {}
    for name in pairs(extra) do
        if R.PICK_LISTS.spellbook.items[name] then names[#names + 1] = name end
    end
    table.sort(names, ByLevel)
    local room = ns.SpellbookSize(sheet) - Picked(sheet)
    for index = 1, math.min(room, #names) do
        picks[names[index]], extra[names[index]] = true, nil
    end
end

-- The entry on the spell list for a spell of the book, or nil when it isn't prepared.
function RPSheet:PreparedSpell(name)
    for _, spell in ipairs(self:Sheet().spells) do
        if spell.name == name then return spell end
    end
end

-- Prepares a spell from the book, if one more fits. Returns true when it did.
function RPSheet:PrepareSpell(name)
    local known = R.SPELLS[name]
    if not known or self:PreparedSpell(name) then return false end
    if not self:SpellFits(known.level) then
        local _, maxPrepared, highest = self:SpellLimits()
        if known.level > highest then
            self:Print(("%s is of a level you have no spell slots for."):format(name))
        else
            self:Print(("You can prepare %d spells. Put one away first."):format(maxPrepared))
        end
        return false
    end
    local spells = self:Sheet().spells
    spells[#spells + 1] = CopyTable(known)
    return true
end

-- Takes a spell off the prepared list. One that is always prepared stays.
function RPSheet:UnprepareSpell(name)
    local spells = self:Sheet().spells
    for index, spell in ipairs(spells) do
        if spell.name == name then
            if spell.free then
                self:Print(("%s is always prepared."):format(name))
                return false
            end
            table.remove(spells, index)
            return true
        end
    end
    return false
end

-- Casting from the open book: a prepared spell is cast as usual; a ritual spell can
-- be cast straight from the book without being prepared and without a slot.
function RPSheet:CastFromBook(name, mode)
    local prepared = self:PreparedSpell(name)
    if prepared then return self:CastSpell(prepared, mode) end
    local known = R.SPELLS[name]
    if known and known.ritual then return self:CastSpell(CopyTable(known), mode, true) end
    self:Print(("%s isn't prepared. Right-click it in the spellbook to prepare it."):format(name))
end
