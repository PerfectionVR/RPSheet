-- The gadgets an engineer makes from journeyman skill up (the common ones are in
-- Data/MagicItemsTrinkets.lua, the jetpack in Data/MagicItemsSet.lua). None adds a
-- number the sheet keeps; the descriptions, in our own words, say what they do.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }

Magic("Baba Yaga's Dancing Broom", "Uncommon", "A Magic action brings the broom to life under your command; it acts right after you until a word stills it again.", nil, ATTUNE)
Magic("Driftglobe", "Uncommon", "A glass ball that, on your word within 60 feet, shines as Light or, once a day, as Daylight. It can float just off the ground and follow you.", nil, { weight = 1 })
Magic("Eversmoking Bottle", "Uncommon", "Opened, it pours out smoke that hides everything within 60 feet and spreads farther each minute, up to 120 feet. Closed, the cloud lingers for ten minutes.")
Magic("Goblin Jumper Cables", "Uncommon", "Once a day, clamped to a creature dead for no more than a minute: a DC 15 Arcana check with tinker's tools brings it back with 1 hit point. On a failure you take 2d6 lightning damage.")
Magic("Goggles of Night", "Uncommon", "You have darkvision out to 60 feet, or 60 feet farther if you had it already.")
Magic("Lantern of Revealing", "Uncommon", "A hooded lantern that burns six hours on a pint of oil. Invisible creatures and things show in its bright light, 30 feet around.")
Magic("Wind Fan", "Uncommon", "Casts Gust of Wind, save DC 13. Each further use before dawn has a growing chance to tear it to useless tatters.")

Magic("Chime of Opening", "Rare", "Struck with a Magic action, it casts Knock with a clear note heard 300 feet away. It can be struck only so many times before it cracks.", nil, { weight = 1 })
Magic("Cube of Summoning", "Rare", "Once a day, winding its crank plays a tune and calls a creature with a 5th-level summoning spell that needs no concentration. A roll says which.")
Magic("Daern's Instant Fortress", "Rare", "A tiny statuette that a word grows into an adamantine tower 20 feet on a side and 30 feet high, pushing aside whatever stood there. The word shrinks it again once it is empty.", nil, ATTUNE)
Magic("Horn of Blasting", "Rare", "Blown, it blasts a 30-foot cone: a DC 15 Constitution save against 5d8 thunder damage and a minute of deafness, half and no deafness on a success. Each use has a chance to burst the horn.")
-- The horns call warrior spirits for an hour, once in seven days. All but the silver
-- one ask something of the blower, or the spirits turn on them.
for _, row in ipairs({ { "Silver", "Rare", "two", "anyone" }, { "Brass", "Rare", "three", "one proficient with all simple weapons" },
    { "Bronze", "Very rare", "four", "one trained in all medium armor" }, { "Iron", "Legendary", "five", "one proficient with all martial weapons" } }) do
    Magic(("Horn of Valhalla, %s"):format(row[1]), row[2],
        ("Blown, it calls %s berserker spirits within 60 feet for an hour, once in seven days. They follow %s; for another they turn on the blower."):format(row[3], row[4]))
end
Magic("Portable Hole", "Rare", "A black cloth that unfolds to a circle 6 feet across. Laid on a solid surface it opens a hole 10 feet deep in a space of its own; folded up, what is inside goes with it.")

Magic("Cauldron of Rebirth", "Very rare", "For a Druid or Warlock. A spellcasting focus that brews a Potion of Greater Healing after each long rest, good for a day, and that can grow to bring a dead humanoid back with salt and patience.", nil, ATTUNE)
Magic("Apparatus of Kwalish", "Legendary", "An iron barrel with a hidden hatch and ten levers, room for two. Worked right, it walks and swims like a giant lobster: Armor Class 20, 200 hit points, speed 30 feet.", nil, { weight = 500 })
Magic("Cubic Gate", "Legendary", "A cube with a plane of existence on each face. Three charges, of which 1d3 come back each dawn; a charge and a face cast Gate or Plane Shift to that plane.")
Magic("Sphere of Annihilation", "Legendary", "A two-foot hole in the world that destroys whatever it swallows, and deals 8d10 force damage to what it only touches. A DC 25 Arcana check from within 60 feet steers it for a turn.")
Magic("Talisman of the Sphere", "Legendary", "You have advantage on Arcana checks to steer a Sphere of Annihilation, and once in control you can move it farther each turn.", nil, { attune = true, weight = 1 })
Magic("Well of Many Worlds", "Legendary", "A black cloth that unfolds to a circle 6 feet across. Laid down it opens a two-way door to another world, a different one each time, until someone folds it up.")
