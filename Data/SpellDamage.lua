-- The damage type of a spell, by name, for features that treat one type differently
-- (see Sheet/Metamorphosis.lua). Data/SpellsCore.lua fills in the spells it lists;
-- the ones written by hand in the other spell files are named here. Only force is
-- needed so far.
local _, ns = ...
local R = ns.Rules

local FORCE = {
    "Eldritch Blast", "Arcane Pulse", "Azure Strike", "Shattering Star", "Azure Sweep",
    "Consume Soul", "Eye Beam", "Soul Reap", "Chaos Nova", "Collapsing Star", "Sigil of Chains",
}
for _, name in ipairs(FORCE) do R.SPELL_DAMAGE[name] = "force" end
