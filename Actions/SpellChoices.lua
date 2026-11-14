-- Casting the spells chosen for a class feature (see Sheet/SpellChoices.lua) without
-- a spell slot: a Mystic Arcanum once per long rest, a mastered spell at will, a
-- Signature Spell once per short or long rest.
-- state.spellUsed[<spell name>] = true while the one free casting is gone.
local _, ns = ...
local RPSheet = ns.addon

local function Choice(self, spell)
    local how = ns.SpellChoice(self:Sheet(), spell.name)
    -- Only at the spell's own level: an entry edited to another level is an ordinary spell.
    if how and spell.level == how.spellLevel then return how end
end

local function Used(self, spell, how)
    return how.once == true and self:State().spellUsed[spell.name] == true
end

-- How `spell` is cast without a slot right now (an entry of R.SPELL_CHOICES), or nil
-- when it takes a slot as any spell does. A second value says why it can't be cast.
function RPSheet:ChosenCasting(spell)
    local how = Choice(self, spell)
    if not how then return end
    local used = Used(self, spell, how)
    if how.only then
        if used then
            return nil, ("%s is spent: your %s casts it once. A long rest brings it back."):format(spell.name, how.feature)
        end
        return how
    end
    -- A higher level set at "Cast at" spends a slot, and so does a casting after the free one.
    if used or (self.castLevel or 0) > spell.level then return end
    return how
end

-- Called when a casting without a slot went through.
function RPSheet:SpendChosenCasting(spell, how)
    if not how.once then return end
    self:State().spellUsed[spell.name] = true
    self:PopulateSoon() -- the row now shows it as used
end

-- A rest brings the free castings back: all of them on a long rest, the ones that say
-- so on a short rest. Returns the names of the spells it restored.
function RPSheet:RestoreChosenCastings(short)
    local state, sheet = self:State(), self:Sheet()
    local restored = {}
    for name in pairs(state.spellUsed) do
        local how = ns.SpellChoice(sheet, name)
        if not short or (how and how.short) then restored[#restored + 1] = name end
    end
    for _, name in ipairs(restored) do state.spellUsed[name] = nil end
    table.sort(restored)
    return restored
end

-- For the spell's row: a word behind its name, the tooltip line about casting it, and
-- true when the usual line about slots doesn't apply.
function RPSheet:ChosenSpellNote(spell)
    local how = Choice(self, spell)
    if not how then return end
    local used = Used(self, spell, how)
    local note = how.note
    if used then
        note = note .. " It has been used."
    elseif not how.only then
        note = note .. " Set a higher level at \"Cast at\" to spend a slot of that level instead."
    end
    return how.mark .. (used and ", used" or ""), note, how.only
end
