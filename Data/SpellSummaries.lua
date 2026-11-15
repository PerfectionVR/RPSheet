-- Puts the hand-written summaries (Data/SpellSummaries2.lua to 9) on the core spells
-- of 2nd level and higher, in place of the line of facts Data/SpellsCore.lua builds.
-- Only the text changes: level, save, dice and slot growth stay as they were.
local _, ns = ...
local R = ns.Rules

-- The line of facts each spell had before, by name, so a copy of the spell that a
-- character saved earlier can be told apart from one the player reworded
-- (see ns.ApplyPreparedSpells).
R.SPELL_FACT_LINES = {}

for name, text in pairs(R.SPELL_SUMMARIES or {}) do
    local spell = R.SPELLS[name]
    -- The setting's own spells keep the summaries written beside them.
    if spell and spell.level >= 2 and not R.AZEROTH_SPELLS[name] then
        R.SPELL_FACT_LINES[name] = spell.desc
        spell.desc = text
    end
end

-- Lines of facts that were corrected since: a saved copy may still carry the old one.
local FORMER = {
    ["Banishing Smite"] = "Conjuration. Range Self. 5d10 force damage. Concentration.",
    ["Control Weather"] = "Transmutation. Range Self, 5-foot sphere. Concentration.",
    ["Conjure Fey"] = "Conjuration. Range 60 feet. 3d12 psychic damage. 1d12 more for each slot level above 6th. Concentration.",
    ["Earthquake"] = "Transmutation. Range 500 feet. Constitution save. 12d6 bludgeoning damage. Concentration.",
}

-- The summary a saved copy of a spell should now show, or nil to leave it alone:
-- only a copy that still carries the old line of facts is brought up to date.
function R.FreshSpellSummary(saved)
    local known = R.SPELLS[saved.name]
    if known and known.level == saved.level and (R.SPELL_FACT_LINES[saved.name] == saved.desc or FORMER[saved.name] == saved.desc) then
        return known.desc
    end
end
