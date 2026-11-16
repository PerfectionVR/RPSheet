-- Protective spells that do more than give a resistance (form of the entries: see
-- Data/SpellWards.lua): protection that rolls what it takes off the damage, and a bond
-- that changes the caster as well as the one it guards.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

local W = R.SPELL_WARDS

-- One damage type, chosen at the casting; psychic and force can't be chosen.
W["Resistance"] = { hours = 0, conc = true }
for _, name in ipairs(R.AllDamage("force", "psychic")) do
    table.insert(W["Resistance"], { label = name, roll = { 1, 4 }, reduce = { name }, perTurn = true })
end

-- A reaction to damage being taken: it comes off that damage, and is paid back later.
W["Time Dilation"] = { hours = 0, { roll = { 4, 8 }, once = true, owed = 4 } }

-- The caster always guards someone else; the one guarded switches their side on by hand.
W["Warding Bond"] = { hours = 1, cast = 1,
    { label = "you guard", guard = true,
      text = "each time the creature you guard takes damage, you take the same amount",
      desc = "On while your Warding Bond guards someone within 60 feet: each time they take damage, you take the same amount. Take it with \"Take damage\", Warding Bond. It ends when you drop to 0 hit points, when the two of you are more than 60 feet apart, or when the spell is cast again on either of you: click to switch it off then." },
    { label = "on you", byHand = true, resist = R.AllDamage(),
      effects = { Kit.Bonus("AC", 1), Kit.Bonus("SAVES", 1) },
      text = "+1 to Armor Class and saving throws, and resistance to all damage",
      desc = "Switch on while someone else's Warding Bond guards you and they are within 60 feet: +1 to Armor Class and saving throws, and resistance to all damage. Tell them what you take: they take the same. Switch it off when the spell ends, after an hour at most." },
}
