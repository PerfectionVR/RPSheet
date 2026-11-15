-- What enchanting makes beyond the wands and rods of Data/MagicItems.lua: wands,
-- rods, gear with a spell bound into it, magic ammunition and a few wooden and clay
-- wonders. Their magic is spent in charges or works on others, so the sheet counts
-- almost none of it; the descriptions, in our own words, say what they do.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local WAND, WAND_ATTUNE, ROD = { weight = 1 }, { attune = true, weight = 1 }, { attune = true, weight = 2 }
local SEVEN = "Seven charges, of which 1d6 + 1 come back each dawn."

Magic("Wand of Magic Detection", "Uncommon", "Three charges, of which 1d3 come back each dawn. A charge casts Detect Magic.", nil, WAND)
Magic("Wand of Secrets", "Uncommon", "Three charges, of which 1d3 come back each dawn. A charge makes it point at the nearest secret door or trap within 60 feet.", nil, WAND)
Magic("Wand of Web", "Uncommon", SEVEN .. " A charge casts Web, save DC 13. For a spellcaster.", nil, WAND_ATTUNE)
Magic("Wand of Binding", "Rare", "Seven charges. Two cast Hold Person, five Hold Monster, save DC 17.", nil, WAND_ATTUNE)
Magic("Wand of Enemy Detection", "Rare", "Seven charges. A charge tells you for a minute in which direction the nearest hostile creature within 60 feet is.", nil, WAND_ATTUNE)
Magic("Wand of Fear", "Rare", "Seven charges, spent to cast Command (flee or grovel only) or a cone of Fear, save DC 15.", nil, WAND_ATTUNE)
Magic("Wand of Fireballs", "Rare", SEVEN .. " One to three cast Fireball (save DC 15), a spell level higher for each charge after the first. For a spellcaster.", nil, WAND_ATTUNE)
Magic("Wand of Lightning Bolts", "Rare", SEVEN .. " One to three cast Lightning Bolt (save DC 15), a spell level higher for each charge after the first. For a spellcaster.", nil, WAND_ATTUNE)
Magic("Wand of Paralysis", "Rare", "Seven charges. A charge fires a ray at a creature within 60 feet, which must pass a DC 15 Constitution save or be paralyzed. For a spellcaster.", nil, WAND_ATTUNE)
Magic("Wand of Wonder", "Rare", "Seven charges. A charge looses a random spell or stranger effect at a point within 120 feet; a roll on its long list says which.", nil, WAND_ATTUNE)
Magic("Wand of Polymorph", "Very rare", SEVEN .. " A charge casts Polymorph, save DC 15. For a spellcaster.", nil, WAND_ATTUNE)

Magic("Immovable Rod", "Uncommon", "Pressing its button fixes it in place, even in mid-air, until the button is pressed again. It holds up to 8,000 pounds.", nil, { weight = 2 })
Magic("Rod of Rulership", "Rare", "A Magic action demands obedience of creatures you choose within 120 feet: a DC 15 Wisdom save or they are charmed by you for 8 hours.", nil, ROD)
Magic("Tentacle Rod", "Rare", "A Magic action sends its three tentacles at creatures within 15 feet, each with an attack roll at +9 for 1d6 psychic damage. One struck by all three must pass a DC 15 Dexterity save or be restrained.", nil, ROD)
Magic("Rod of Absorption", "Very rare", "A reaction swallows a spell aimed at you alone and stores its levels, which a spellcaster can spend from the rod as spell slots. It takes in 50 levels in all.", nil, ROD)
Magic("Rod of Alertness", "Very rare", "While you hold it you have advantage on Perception checks and initiative rolls, and it casts a handful of detecting spells. Planted in the ground, it warns of enemies and strengthens friends nearby.", nil, ROD)
Magic("Rod of Security", "Very rare", "A Magic action takes you and up to 199 willing creatures you see to a paradise of your design, where nobody ages or hungers. The stay is shorter the more of you there are.", nil, { weight = 2 })
Magic("Rod of the Sleepwalker", "Very rare", "Casts Dominate Monster (save DC 17) as a sleepwalking trance that can last up to 8 hours of concentration. Creatures that never sleep are immune.")
Magic("Rod of Lordly Might", "Legendary", "A mace with a magic bonus of 3 (set it on the Weapons page). Its six buttons turn it into other weapons and tools, and it can drain, frighten and paralyze.", nil, ROD)
Magic("Rod of Resurrection", "Legendary", "Five charges, one back each dawn. One casts Heal, all five Resurrection.", nil, ROD)

-- A spell bound into armor, a staff or a weapon when it is made: six charges, of
-- which 1d6 come back each dawn, one for a casting. By the spell's level.
local BOUND = {
    { "Uncommon", "a cantrip or a 1st-level spell", 13, 5 }, { "Rare", "a 2nd- or 3rd-level spell", 15, 7 },
    { "Very rare", "a 4th- or 5th-level spell", 17, 9 }, { "Legendary", "a spell of 6th to 8th level", 18, 10 },
}
for _, row in ipairs(BOUND) do
    for _, kind in ipairs({ "Armor", "Staff", "Weapon" }) do
        Magic(("Enspelled %s (%s)"):format(kind, row[1]), row[1],
            ("Holds %s, chosen when it is made. Six charges, of which 1d6 come back each dawn; a charge casts it, at save DC %d and attack +%d at most (less for the lower level)."):format(row[2], row[3], row[4]),
            nil, { attune = true, weight = kind == "Staff" and 4 or 0 })
    end
end

-- Ammunition is magic for one hit.
for bonus, rarity in ipairs({ "Uncommon", "Rare", "Very rare" }) do
    local name = ("+%d Ammunition"):format(bonus)
    Magic(name, rarity, ("One piece. Adds %d to the attack and damage roll made with it, and is plain again once it hits."):format(bonus))
    R.CONSUMABLES[name] = true
end
Magic("Ammunition of Slaying", "Very rare", "One piece, made against one kind of creature. Such a creature it wounds makes a DC 17 Constitution save against 6d10 more force damage, half on a success.")
R.CONSUMABLES["Ammunition of Slaying"] = true

Magic("Decanter of Endless Water", "Uncommon", "A Magic action and one of three words make it pour fresh or salt water: a stream, a fountain, or a geyser that can knock a creature down.", nil, { weight = 2 })
Magic("Pipes of Haunting", "Uncommon", "Three charges, of which 1d3 come back each dawn. A charge plays a tune: creatures you choose within 30 feet must pass a DC 15 Wisdom save or be frightened of you for a minute.")
Magic("Pipes of the Sewers", "Uncommon", "Rats leave you alone. Three charges, of which 1d3 come back each dawn; playing calls a swarm of rats for each charge spent, which may do as you say.", nil, { attune = true })
Magic("Bowl of Commanding Water Elementals", "Rare", "Filled with water, a Magic action calls a water elemental out of it, which obeys you for up to an hour. Once a day.")
Magic("Figurine of Wondrous Power, Ebony Fly", "Rare", "Thrown down, the statuette becomes a giant fly you can ride, for up to 12 hours. Then it rests for 2 days.")
Magic("Quarterstaff of the Acrobat", "Very rare", "A quarterstaff with a magic bonus of 2 (set it on the Weapons page). It can glow green, and a bonus action makes it a 6-inch rod or a 10-foot pole, each with a use of its own.", nil, { attune = true, weight = 4 })
Magic("Thunderous Greatclub", "Very rare", "While attuned your Strength score is 20, if it is lower. It deals 1d8 more thunder damage to creatures and 3d8 more to things nobody holds.",
    { { target = "SCORE:STR", flat = 20, stat = "", times = 1, mode = "MIN" } }, { attune = true, weight = 10 })
