-- Carved and cut things: the stones that circle the head, the statuettes that come
-- alive, the feather tokens and the crystal balls. Jewelcrafting makes most of them;
-- a few statuettes are a smith's or an enchanter's. A stone's raised score has a
-- ceiling the sheet's effects can't express, so it is told, not counted.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }

-- Stones that circle your head while attuned.
local function Stone(name, rarity, desc)
    Magic("Ioun Stone of " .. name, rarity, "Circles your head. " .. desc, nil, ATTUNE)
end
Stone("Awareness", "Rare", "You have advantage on initiative rolls and Perception checks.")
Stone("Reserve", "Rare", "Holds up to four levels of spells cast into it by anyone, each of 4th level or lower, for you to cast later.")
Stone("Sustenance", "Rare", "You need no food or drink.")
Stone("Absorption", "Very rare", "A reaction cancels a spell of 4th level or lower cast by a creature you see. After 20 levels of spells it burns out.")
for _, row in ipairs({ { "Agility", "DEX" }, { "Fortitude", "CON" }, { "Insight", "WIS" }, { "Intellect", "INT" }, { "Leadership", "CHA" }, { "Strength", "STR" } }) do
    Stone(row[1], "Very rare", ("Your %s score is 2 higher, to 20 at most. Not counted by itself: add the points on the Scores page while it circles."):format(R.STAT_NAMES[row[2]]))
end
Stone("Greater Absorption", "Legendary", "A reaction cancels a spell of 8th level or lower cast by a creature you see, until it burns out.")
Stone("Mastery", "Legendary", "Your proficiency bonus is 1 higher. Not counted by itself.")
Stone("Regeneration", "Legendary", "You regain 15 hit points at the end of each hour it circles, while you have at least 1.")

-- Statuettes: thrown down within 60 feet with a Magic action, they become the creature
-- for a time, then rest.
local function Figurine(name, rarity, desc)
    Magic("Figurine of Wondrous Power, " .. name, rarity, "Thrown down, the statuette becomes " .. desc)
end
Figurine("Silver Raven", "Uncommon", "a raven for up to 12 hours, which carries messages as Animal Messenger. Then it rests for 2 days.")
Figurine("Bronze Griffon", "Rare", "a griffon for up to 6 hours. Then it rests for 5 days.")
Figurine("Golden Lions", "Rare", "a lion for up to an hour; there are two, used alone or together. Each then rests for 7 days.")
Figurine("Ivory Goats", "Rare", "a goat; there are three, each with a gift of its own; one spreads terror while ridden and lends its horns as magic weapons.")
Figurine("Marble Elephant", "Rare", "an elephant for up to 24 hours. Then it rests for 7 days.")
Figurine("Onyx Dog", "Rare", "a mastiff for up to 6 hours, which speaks Common and has blindsight out to 60 feet. Then it rests for 7 days.")
Figurine("Serpentine Owl", "Rare", "a giant owl for up to 8 hours, which speaks to your mind at any distance. Then it rests for a time.")
Figurine("Jeweled Panther", "Rare", "a Large panther that flies 30 feet a turn and can be ridden, for up to 12 hours. Then it rests for a time.")
Figurine("Obsidian Steed", "Very rare", "a nightmare for up to 24 hours, which fights only to defend itself. Then it rests for 5 days.")

-- Feather tokens: each works once.
local function Token(name, rarity, desc)
    local full = "Quaal's Feather Token, " .. name
    Magic(full, rarity, "Works once. " .. desc)
    R.CONSUMABLES[full] = true
end
Token("Anchor", "Uncommon", "Touched to a boat or ship, it holds the vessel in place for 24 hours.")
Token("Fan", "Uncommon", "Tossed up aboard a ship, it becomes a great fan that speeds the ship by 5 miles an hour for 8 hours.")
Token("Tree", "Uncommon", "Touched to open ground outdoors, it becomes a full-grown oak.")
Token("Bird", "Rare", "Becomes an enormous bird that can't fight but carries 500 pounds through the air for a day's flight.")
Token("Swan Boat", "Rare", "Touched to a wide water, it becomes a 50-foot swan boat that moves by itself at 6 miles an hour for 24 hours.")
Token("Whip", "Rare", "Becomes a floating whip that strikes at your bidding for an hour: +9 to hit, 1d6 + 5 force damage.")

-- Crystal balls: each casts Scrying (save DC 17) while touched, and one thing more.
local BALL = { attune = true, weight = 3 }
Magic("Crystal Ball of Mind Reading", "Legendary", "Casts Scrying (save DC 17), and Detect Thoughts on creatures within 30 feet of what it shows.", nil, BALL)
Magic("Crystal Ball of Telepathy", "Legendary", "Casts Scrying (save DC 17). You can speak to the minds of creatures within 30 feet of what it shows, and once a day cast Suggestion on one of them.", nil, BALL)
Magic("Crystal Ball of True Seeing", "Legendary", "Casts Scrying (save DC 17), and you have truesight out to 120 feet around what it shows.", nil, BALL)
