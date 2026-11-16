-- The damage type of a spell, by name, for features that treat one type differently
-- (see Sheet/Metamorphosis.lua). Data/SpellsCore.lua fills in the spells it lists;
-- the ones written by hand in the other spell files are named here: force for
-- Metamorphosis, the others for Elemental Affinity and Infusion of Light
-- (Actions/SpellFeatures.lua, Actions/FeatureDice.lua) and the feats that work on a type
-- (Elemental Adept, Clearcasting: Sheet/DiceFeats.lua). A spell whose type is chosen
-- when it is cast, or that deals two, is left out.
local _, ns = ...
local R = ns.Rules

local FORCE = {
    "Eldritch Blast", "Arcane Pulse", "Azure Strike", "Shattering Star", "Azure Sweep",
    "Consume Soul", "Eye Beam", "Soul Reap", "Chaos Nova", "Collapsing Star", "Sigil of Chains",
}
for _, name in ipairs(FORCE) do R.SPELL_DAMAGE[name] = "force" end
local TYPED = {
    acid = { "Acid Splash" },
    cold = { "Ray of Frost", "Frost Nova", "Flurry", "Chains of Ice", "Frostscythe", "Remorseless Winter" },
    fire = { "Fire Bolt", "Produce Flame", "Burning Hands", "Hellish Rebuke", "Searing Smite", "Living Flame", "Eruption", "Emberstorm", "Lay Waste", "Explosive Trap", "Fel Rush", "Infernal Strike", "Fiery Brand", "Sigil of Flame" },
    lightning = { "Shocking Grasp", "Witch Bolt", "Wrath" },
    necrotic = { "Chill Touch", "Toll the Dead", "Arms of Hadar", "Hex", "Inflict Wounds", "Wrathful Smite", "Void Eruption", "Rune Strike", "Scourge Strike", "Death and Decay", "Leeching Strike", "Bonestorm" },
    piercing = { "Thorn Whip", "Ensnaring Strike", "Hail of Thorns" },
    poison = { "Poison Spray", "Ray of Sickness", "Serpent Sting" },
    psychic = { "Mind Sliver", "Vicious Mockery", "Dissonant Whispers", "Shadow Word: Pain", "Psychic Horror", "Curse of Agony" },
    radiant = { "Sacred Flame", "Starry Wisp", "Word of Radiance", "Divine Favor", "Guiding Bolt", "Holy Nova", "Consecration", "Moonfire", "Starfall" },
    thunder = { "Thunderclap", "Thunderous Smite", "Thunderwave" },
}
for kind, names in pairs(TYPED) do
    for _, name in ipairs(names) do R.SPELL_DAMAGE[name] = R.SPELL_DAMAGE[name] or kind end
end
-- A core spell whose line of facts leaves the type out.
R.SPELL_DAMAGE["Symbol"] = "necrotic"

