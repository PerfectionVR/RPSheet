-- Protection that lasts only while something holds: a spell that is running, a brew
-- with a choice of damage types, a boon that works in the dark. The sheet keeps each as
-- a passive that is switched on and off (Sheet/Wards.lua, Sheet/WardCasting.lua,
-- Sheet/DefensePicks.lua), so "Take damage" counts it like any other defense.
local _, ns = ...
local R = ns.Rules

local BLADES = R.WEAPON_DAMAGE

-- Spells that protect the one they are cast on while they last.
-- R.SPELL_WARDS[<spell>] = {
--     hours     how long it lasts, in whole hours (0: under an hour); a rest that long ends it
--     conc      true if it ends with the caster's concentration
--     own       true if it is always on the caster: no need to ask who it is for
--     { label, resist = {}, immune = {}, conditionImmune = {} }, ...   one entry, or
--               the options the caster chooses between (label names the option)
-- }
R.SPELL_WARDS = {
    ["Protection from Poison"] = { hours = 1, { resist = { "poison" } } },
    ["Protection from Energy"] = { hours = 1, conc = true,
        { label = "acid", resist = { "acid" } }, { label = "cold", resist = { "cold" } },
        { label = "fire", resist = { "fire" } }, { label = "lightning", resist = { "lightning" } },
        { label = "thunder", resist = { "thunder" } } },
    ["Feign Death"] = { hours = 1, { resist = R.AllDamage("psychic"), conditionImmune = { "Poisoned" } } },
    ["Gaseous Form"] = { hours = 1, conc = true, { resist = BLADES, conditionImmune = { "Prone" } } },
    ["Aura of Life"] = { hours = 0, conc = true, own = true, { resist = { "necrotic" } } },
    ["Aura of Purity"] = { hours = 0, conc = true, own = true, { resist = { "poison" } } },
    ["Fire Shield"] = { hours = 0, own = true,
        { label = "warm shield", resist = { "cold" } }, { label = "chill shield", resist = { "fire" } } },
    ["Fount of Moonlight"] = { hours = 0, conc = true, own = true, { resist = { "radiant" } } },
    ["Stoneskin"] = { hours = 1, conc = true, { resist = BLADES } },
    ["Heroes' Feast"] = { hours = 24, { resist = { "poison" }, conditionImmune = { "Frightened", "Poisoned" } } },
    ["Wind Walk"] = { hours = 8, { label = "as a cloud", resist = BLADES, conditionImmune = { "Prone" } } },
    ["Mind Blank"] = { hours = 24, { immune = { "psychic" }, conditionImmune = { "Charmed" } } },
    ["Apotheosis"] = { hours = 0, own = true, { resist = { "bludgeoning", "piercing", "radiant", "slashing" } } },
    ["Combustion"] = { hours = 0, own = true, { immune = { "fire" } } },
    ["Divine Shield"] = { hours = 0, own = true, { immune = R.AllDamage() } },
    ["Tranquility"] = { hours = 0, conc = true, { resist = BLADES } },
}

-- The key of a ward's passive, and the spell and option it names.
function R.WardKey(spell, index)
    return ("ward:%s:%d"):format(spell, index)
end
function R.WardOf(auto)
    local spell, index = (auto or ""):match("^ward:(.+):(%d+)$")
    local ward = spell and R.SPELL_WARDS[spell]
    local option = ward and ward[tonumber(index)]
    if option then return ward, option, spell end
end

-- Passives whose resistance is a choice of damage types, made when they are switched
-- on: sheet.defensePicks[<passive>] = { "cold", "radiant" }.
R.DEFENSE_PICKS = {
    ["Heavenly Spirit"] = { count = 2, from = { "cold", "necrotic", "psychic", "radiant" } },
}

-- Defenses of a feat that only hold in a situation: a passive of their own, off until
-- the player switches it on.
R.DEFENSE_SWITCHES = {
    { feat = "Boon of the Night Spirit", name = "Shadowy Form", resist = R.AllDamage("psychic", "radiant"),
      desc = "Switch on while you are in dim light or darkness, and off when you step into bright light: you resist all damage except psychic and radiant." },
}
