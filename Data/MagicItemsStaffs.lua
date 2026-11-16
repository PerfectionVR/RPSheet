-- What inscription makes beyond the staffs of the earlier lists: staffs, the books
-- that are read once, a deck, pigments and the scrolls that hold no spell. (A scroll
-- of a spell is scribed, not listed: Sheet/Scribing.lua.) The sheet counts a staff's
-- bonus to spell attacks; the rest is told in the descriptions, in our own words.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local STAFF = { attune = true, weight = 4 }
local function SpellAttack(bonus)
    return { { target = "SPELLATK", flat = bonus, stat = "", times = 1 } }
end

Magic("Staff of the Adder", "Uncommon", "A bonus action wakes its head as a venomous snake for a minute. One of your attacks can be its bite, with your proficiency bonus and Wisdom: 1d6 piercing and 3d6 poison damage. If the head is killed the staff is lost.", nil, STAFF)
Magic("Staff of the Python", "Uncommon", "Thrown down within 10 feet, it becomes a giant constrictor snake that obeys you and acts right after you. If the snake dies the staff is lost.", nil, STAFF)
Magic("Staff of Charming", "Rare", "Ten charges. A charge casts Charm Person, Command or Comprehend Languages with your own save DC, or turns an enchantment aimed at you alone back on its caster. For a spellcaster.", nil, STAFF)
Magic("Staff of Swarming Insects", "Rare", "Ten charges. A charge surrounds you with a cloud of insects that hides everything within 30 feet from all but you for ten minutes; four or five cast Giant Insect or Insect Plague. For a spellcaster.", nil, STAFF)
Magic("Staff of the Woodlands", "Rare", "For a Druid. A quarterstaff with a magic bonus of 2 (set it on the Weapons page) that adds 2 to your spell attack rolls. Six charges cast spells of beasts and plants, and a charge plants it as a 60-foot tree.",
    SpellAttack(2), STAFF)
Magic("Staff of Withering", "Rare", "Three charges, of which 1d3 come back each dawn. On a hit as a quarterstaff, a charge deals 2d10 more necrotic damage, and the target must pass a DC 15 Constitution save or have disadvantage on Strength and Constitution checks and saves for an hour.", nil, STAFF)
Magic("Staff of Fire", "Very rare", "You resist fire damage while you hold it. Ten charges, of which 1d6 + 4 come back each dawn: one casts Burning Hands, three Fireball, four Wall of Fire, with your own save DC. For a spellcaster.", nil, STAFF)
Magic("Staff of Frost", "Very rare", "You resist cold damage while you hold it. Ten charges, of which 1d6 + 4 come back each dawn, cast Fog Cloud (one), Ice Storm or Wall of Ice (four) or Cone of Cold (five) with your own save DC. For a spellcaster.", nil, STAFF)
Magic("Staff of Thunder and Lightning", "Very rare", "A quarterstaff with a magic bonus of 2 (set it on the Weapons page). Once a day each: 2d6 more lightning damage on a hit; a crack of thunder on a hit (a DC 17 Constitution save or stunned until your next turn ends); a bolt of lightning; a thunderclap.", nil, STAFF)
Magic("Staff of the Magi", "Legendary", "A quarterstaff with a magic bonus of 2 (set it on the Weapons page) that adds 2 to your spell attack rolls. Fifty charges cast a long list of spells; you have advantage on saves against spells, and it can swallow a spell aimed at you alone. Breaking it is a last, ruinous blast.",
    SpellAttack(2), STAFF)
Magic("Staff of Light and Shadow", "Legendary", "For a Priest. At dawn you choose its state. In shadow you resist necrotic damage, and a necromancy spell of 1st to 5th level keeps its slot when a d6 rolls above its level. In light you resist radiant damage, and your healing spells count as cast one slot level higher.", nil, STAFF)

-- Books that are studied once: 48 hours within six days, then the magic is gone for a
-- century. The sheet doesn't add the points by itself: raise the score on the Scores page.
local STUDY = "Studying it for 48 hours within six days raises your %s score by 2, to 30 at most. Then its magic sleeps for a hundred years. Add the points on the Scores page."
for _, book in ipairs({ { "Manual of Bodily Health", "CON" }, { "Manual of Gainful Exercise", "STR" }, { "Manual of Quickness of Action", "DEX" },
    { "Tome of Clear Thought", "INT" }, { "Tome of Leadership and Influence", "CHA" }, { "Tome of Understanding", "WIS" } }) do
    Magic(book[1], "Very rare", STUDY:format(R.STAT_NAMES[book[2]]), nil, { weight = 5 })
end
-- A manual of golems is burnt up by the making, so it counts as used up.
for _, kind in ipairs({ "Clay", "Flesh", "Iron", "Stone" }) do
    local name = ("Manual of %s Golems"):format(kind)
    Magic(name, "Very rare", ("What a spellcaster with two 5th-level slots needs to build a %s golem: weeks of unbroken work and a fortune in supplies. The book burns up when the golem rises; anyone else who reads it takes 6d6 psychic damage."):format(kind:lower()),
        nil, { weight = 5 })
    R.CONSUMABLES[name] = true
end
Magic("Tome of the Stilled Tongue", "Legendary", "For a Mage. A spellbook and arcane focus; once a day, with it in hand, a bonus action casts a spell written in it without a slot, words or gestures.", nil, { attune = true, weight = 5 })

Magic("Deck of Illusions", "Uncommon", "A card drawn at random and thrown within 30 feet becomes the illusion of the creature on it, which lasts until dispelled. Each card works once.")
Magic("Nolzur's Marvelous Pigments", "Very rare", "A box of 1d4 pots and a brush. A pot and ten minutes of concentration paint real objects and terrain into being, within a 20-foot cube.", nil, { weight = 1 })
Magic("Spirit Board", "Very rare", "Three charges, one back each dawn. A minute at the board casts Augury (one charge) or Commune (three), the answers spelled out by its pointer.")
Magic("Scroll of Protection", "Rare", "Made against one kind of creature. Reading it raises a barrier around you that such creatures can't cross or reach through while it lasts.")
Magic("Scroll of Titan Summoning", "Legendary", "Reading it calls a titanic monster to a place you see within a mile. It is hostile to everything and stays until it is slain.")
for _, name in ipairs({ "Deck of Illusions", "Nolzur's Marvelous Pigments", "Scroll of Protection", "Scroll of Titan Summoning" }) do
    R.CONSUMABLES[name] = true
end
