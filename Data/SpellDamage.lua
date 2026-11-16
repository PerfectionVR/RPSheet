-- The damage type of a spell, by name, for features that treat one type differently
-- (see Sheet/Metamorphosis.lua). Data/SpellsCore.lua fills in the spells it lists;
-- the ones written by hand in the other spell files are named here.
local _, ns = ...
local R = ns.Rules

local FORCE = {
    "Eldritch Blast", "Arcane Pulse", "Azure Strike", "Shattering Star", "Azure Sweep",
    "Consume Soul", "Eye Beam", "Soul Reap", "Chaos Nova", "Collapsing Star", "Sigil of Chains",
}
for _, name in ipairs(FORCE) do R.SPELL_DAMAGE[name] = "force" end
-- A core spell whose line of facts leaves the type out.
R.SPELL_DAMAGE["Symbol"] = "necrotic"

-- Spells written by hand that deal one type of damage, for the feats that work on a
-- type (Elemental Adept, Clearcasting: Sheet/DiceFeats.lua). Spells whose type is
-- chosen or mixed are left out.
local ONE_TYPE = {
    acid = { "Acid Splash" },
    cold = { "Chains of Ice", "Flurry", "Frost Nova", "Frostscythe", "Ray of Frost", "Remorseless Winter" },
    fire = { "Emberstorm", "Eruption", "Explosive Trap", "Fel Rush", "Fiery Brand", "Fire Bolt", "Infernal Strike", "Lay Waste",
             "Living Flame", "Produce Flame", "Sigil of Flame" },
    lightning = { "Shocking Grasp", "Wrath" },
    thunder = { "Thunderclap" },
    necrotic = { "Bonestorm", "Chill Touch", "Death and Decay", "Leeching Strike", "Rune Strike", "Scourge Strike", "Toll the Dead", "Void Eruption" },
    radiant = { "Consecration", "Holy Nova", "Moonfire", "Sacred Flame", "Starfall", "Starry Wisp", "Word of Radiance" },
    psychic = { "Curse of Agony", "Mind Sliver", "Psychic Horror", "Shadow Word: Pain", "Vicious Mockery" },
    poison = { "Poison Spray", "Serpent Sting" },
}
for damage, names in pairs(ONE_TYPE) do
    for _, name in ipairs(names) do R.SPELL_DAMAGE[name] = R.SPELL_DAMAGE[name] or damage end
end
