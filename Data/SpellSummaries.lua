-- Puts the hand-written summaries (Data/SpellSummaries1.lua to 9) on the core spells
-- that Data/Spells.lua doesn't already describe, in place of the line of facts
-- Data/SpellsCore.lua builds.
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
    if spell and spell.level >= 1 and not R.AZEROTH_SPELLS[name] then
        R.SPELL_FACT_LINES[name] = spell.desc
        spell.desc = text
    end
end

-- The summary a saved copy of a spell should now show, or nil to leave it alone:
-- only a copy that still carries the line of facts, or a summary the spell had
-- before (Data/SpellFormer.lua), is brought up to date.
function R.FreshSpellSummary(saved)
    local known = R.SPELLS[saved.name]
    if known and known.level == saved.level and R.SpellHadValue(saved.name, "desc", saved.desc) then
        return known.desc
    end
end
