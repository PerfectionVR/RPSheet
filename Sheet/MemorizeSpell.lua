-- Memorize Spell: after a short rest a Mage can replace one prepared spell with another
-- from the spellbook, though a spell was cast since the long rest and the list is
-- otherwise fixed (Sheet/Spellbook.lua). The chance is kept in state.memorizeSwap:
-- "open" after a short rest, then the name of the spell put away, until one is
-- prepared in its place. A long rest clears it, as it opens the whole list again.
local _, ns = ...
local RPSheet = ns.addon

local FEATURE = "Memorize Spell"

-- Called by a short rest.
function RPSheet:OpenMemorize()
    local state = self:State()
    if state.prepareClosed and ns.HasFeature(self:Sheet(), FEATURE) then state.memorizeSwap = "open" end
end

-- True if the list, fixed since a spell was cast, still lets this change through:
-- `kind` is "unprepare" (first) or "prepare" (the spell that takes its place).
function RPSheet:MemorizeAllows(kind)
    local swap = self:State().memorizeSwap
    if type(swap) ~= "string" then return false end
    if kind == "unprepare" then return swap == "open" end
    return swap ~= "open"
end

-- Called after a change MemorizeAllows let through.
function RPSheet:MemorizeUsed(kind, name)
    local state = self:State()
    if kind == "unprepare" then
        state.memorizeSwap = name
        self:Print(("Memorize Spell: %s is put away. Prepare another spell from your book in its place."):format(name))
    else
        local out = state.memorizeSwap
        state.memorizeSwap = nil
        self:Print(("Memorize Spell: %s takes the place of %s until your next long rest."):format(name, out))
    end
end
