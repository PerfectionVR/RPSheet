-- A Mage's spellbook: the spells of level 1 and higher the character owns
-- (sheet.spellbook[<spell name>] = true). The spells on the sheet's spell list are the
-- ones prepared from it. Cantrips are not in the book.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local BOOK_CLASS = "Wizard" -- the Player's Handbook class that keeps a spellbook

function ns.HasSpellbook(sheet)
    local class = R.CLASSES[sheet.class]
    return class ~= nil and class.base == BOOK_CLASS
end

-- The book of a sheet, made if it has none yet.
function ns.Spellbook(sheet)
    if type(sheet.spellbook) ~= "table" then sheet.spellbook = {} end
    return sheet.spellbook
end

-- Spells the rules put in the book at a level: six to start, two more per level.
-- Spells copied in from scrolls and other books come on top.
function ns.SpellbookSize(level)
    return 6 + 2 * (math.max(1, level) - 1)
end

local function ByLevel(a, b)
    if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
    return a < b
end

-- Names of the spells in the book, lowest level first.
function ns.SpellbookNames(sheet)
    local names = {}
    for name in pairs(ns.Spellbook(sheet)) do
        if R.SPELLS[name] then names[#names + 1] = name end
    end
    table.sort(names, ByLevel)
    return names
end

-- Spells of the class that could still be written into the book: level 1 and higher,
-- up to the highest level the character has slots for.
function ns.SpellbookChoices(sheet, highest)
    local class, book, names = R.CLASSES[sheet.class], ns.Spellbook(sheet), {}
    for _, name in ipairs(class and R.SPELL_LISTS[class.base] or {}) do
        local level = R.SPELLS[name].level
        if not book[name] and level > 0 and level <= highest then names[#names + 1] = name end
    end
    table.sort(names, ByLevel)
    return names
end

-- A prepared spell has to be in the book: spells added to the spell list by hand are
-- written into it. Runs with the other sheet upkeep (see Sheet/ClassFeatures.lua).
function ns.ApplySpellbook(sheet)
    if not ns.HasSpellbook(sheet) then return end
    local book = ns.Spellbook(sheet)
    local list = {}
    for _, name in ipairs(R.SPELL_LISTS[BOOK_CLASS] or {}) do list[name] = true end
    for _, spell in ipairs(sheet.spells) do
        local known = R.SPELLS[spell.name]
        if known and known.level > 0 and known.level == spell.level and list[spell.name] and not spell.free then
            book[spell.name] = true
        end
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
