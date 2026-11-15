-- What alchemy makes beyond the plain potion of healing: potions, oils and elixirs,
-- and the dusts, glues and the stone of the higher skill levels. A potion is drunk,
-- not worn, so none of these has effects the sheet counts; the descriptions, in our
-- own words, say what the table plays out. Everything here but the jug and the stone
-- is used up (R.CONSUMABLES): half the time and cost to make, nothing to disenchant.
local _, ns = ...
local R = ns.Rules

local VIAL = { weight = 0.5 }
local function Potion(name, rarity, desc, extra)
    R.AddMagicItem(name, rarity, desc, nil, extra or VIAL)
    R.CONSUMABLES[name] = true
end

-- Healing, and the setting's potions that bring back spell slots.
Potion("Potion of Greater Healing", "Uncommon", "Drinking it as a bonus action restores 4d4 + 4 hit points.")
Potion("Potion of Superior Healing", "Rare", "Drinking it as a bonus action restores 8d4 + 8 hit points.")
Potion("Potion of Supreme Healing", "Very rare", "Drinking it as a bonus action restores 10d4 + 20 hit points.")
Potion("Potion of Mana", "Common", "Drinking it gives back one spent 1st-level spell slot.", {})
Potion("Potion of Mana (Greater)", "Uncommon", "Drinking it gives back one spent spell slot of 3rd level or lower, your choice.", {})
Potion("Potion of Mana (Superior)", "Rare", "Drinking it gives back one spent spell slot of 5th level or lower, your choice.", {})
Potion("Potion of Rejuvenation", "Uncommon", "Drinking it restores 3d4 + 3 hit points and one spent 1st-level spell slot.", {})
Potion("Potion of Rejuvenation (Greater)", "Rare", "Drinking it restores 6d4 + 6 hit points and one spent spell slot of 3rd level or lower.", {})
Potion("Potion of Rejuvenation (Superior)", "Very rare", "Drinking it restores 9d4 + 9 hit points and one spent spell slot of 5th level or lower.", {})
-- Troll's blood: hit points now and again at the start of each turn for a minute.
for _, row in ipairs({ { "", "Uncommon", 2 }, { " (Greater)", "Rare", 4 }, { " (Superior)", "Very rare", 6 }, { " (Supreme)", "Legendary", 8 } }) do
    Potion("Troll's Blood Elixir" .. row[1], row[2],
        ("Drinking it restores %d hit points, and as many again at the start of each of your turns for a minute while you have at least 1."):format(row[3]), {})
end

-- An hour of resistance to one kind of damage.
for _, kind in ipairs({ "Acid", "Cold", "Fire", "Force", "Lightning", "Necrotic", "Poison", "Psychic", "Radiant", "Thunder" }) do
    Potion(("Potion of %s Resistance"):format(kind), "Uncommon", ("For an hour after drinking it you resist %s damage."):format(kind:lower()))
end
-- The strength potions are listed with the belts (Data/MagicItemsSet.lua).
for _, kind in ipairs({ "Hill", "Frost", "Stone", "Fire", "Cloud", "Storm" }) do
    R.CONSUMABLES[("Potion of %s Giant Strength"):format(kind)] = true
end

Potion("Potion of Climbing", "Common", "For an hour you climb as fast as you walk, with advantage on Athletics checks to climb.")
Potion("Potion of Comprehension", "Common", "For an hour you understand any language you hear or read, as the spell Comprehend Languages.")
Potion("Potion of Animal Friendship", "Uncommon", "Lets you cast Animal Friendship as a 3rd-level spell, save DC 13.")
Potion("Potion of Fire Breath", "Uncommon", "A bonus action breathes fire at a target within 30 feet: a DC 13 Dexterity save against 4d6 fire damage, half on a success. Three breaths, then it is spent.")
Potion("Potion of Growth", "Uncommon", "For ten minutes you are enlarged, as the spell Enlarge/Reduce, without concentrating.")
Potion("Potion of Poison", "Uncommon", "Looks and tastes like a helpful potion. Whoever drinks it takes 4d6 poison damage and must pass a DC 13 Constitution save or be poisoned.")
Potion("Potion of Pugilism", "Uncommon", "For ten minutes your unarmed strikes deal 1d6 more force damage.")
Potion("Potion of Water Breathing", "Uncommon", "You breathe underwater for 24 hours.")
Potion("Oil of Slipperiness", "Uncommon", "Ten minutes to rub over a Medium or smaller creature, which then moves freely for 8 hours, as under Freedom of Movement. Poured out, it greases a 10-foot square for as long.")
Potion("Philter of Love", "Uncommon", "The next creature you see within ten minutes of drinking it charms you for an hour.")
Potion("Elixir of Health", "Rare", "Cures magical diseases and ends blindness, deafness, paralysis and poisoning on you.")
Potion("Noggenfogger Elixir", "Rare", "A goblin trade prince's brew with an effect nobody can predict: a d6 decides what becomes of the drinker.", {})
Potion("Oil of Etherealness", "Rare", "Ten minutes to rub over a Medium or smaller creature, which is then ethereal for an hour, as the spell Etherealness.")
Potion("Potion of Clairvoyance", "Rare", "Gives you the effect of the spell Clairvoyance, without concentrating.")
Potion("Potion of Diminution", "Rare", "For 1d4 hours you are shrunk, as the spell Enlarge/Reduce, without concentrating.")
Potion("Potion of Gaseous Form", "Rare", "For an hour you are a cloud, as the spell Gaseous Form, without concentrating; a bonus action ends it early.")
Potion("Potion of Heroism", "Rare", "For an hour you have 10 temporary hit points and the effect of Bless, without concentrating.")
Potion("Potion of Invisibility", "Rare", "You are invisible for an hour, or until you attack, deal damage or cast a spell.")
Potion("Potion of Invulnerability", "Rare", "For a minute you resist all damage.")
Potion("Potion of Mind Reading", "Rare", "For ten minutes you read thoughts as with Detect Thoughts (save DC 13), without concentrating.")
Potion("Flask of the Titans", "Very rare", "For an hour your hit point maximum and your hit points are 30 higher. Not counted by itself: raise them by hand while it lasts.", {})
Potion("Oil of Sharpness", "Very rare", "A minute to coat a plain slashing or piercing melee weapon, or twenty pieces of ammunition, which then count as magic ones with a bonus of 3.")
Potion("Potion of Flying", "Very rare", "For an hour you fly as fast as you walk and can hover. When it ends in the air you fall.")
Potion("Potion of Greater Invisibility", "Very rare", "You are invisible for an hour, whatever you do.")
Potion("Potion of Longevity", "Very rare", "Makes your body 1d6 + 6 years younger, never younger than 13. Every further one has a growing chance to age you instead.")
Potion("Potion of Speed", "Very rare", "For a minute you are under Haste, without concentrating and without the tiredness after.")
Potion("Potion of Vitality", "Very rare", "Ends all exhaustion and poisoning on you, and for 24 hours every Hit Die you spend heals its highest number.")

-- The other things an alchemist makes.
Potion("Perfume of Bewitching", "Common", "One use. For an hour you have advantage on Deception and Persuasion checks to sway a creature within 5 feet of you.", {})
Potion("Dust of Disappearance", "Uncommon", "One use. Thrown into the air, it makes you and everything within 10 feet of you invisible for 2d4 minutes.", {})
Potion("Dust of Dryness", "Uncommon", "A packet of 1d6 + 4 pinches. A pinch turns up to a 15-foot cube of water into a pellet, which gives the water back when broken.", {})
Potion("Keoghtom's Ointment", "Uncommon", "A jar of 1d4 + 1 doses. A dose, swallowed or rubbed on, restores 2d8 + 2 hit points and ends poisoning.", VIAL)
Potion("Sovereign Glue", "Legendary", "A flask of 1d6 + 1 ounces. An ounce covers a square foot and bonds two things for good; only the strongest solvent or magic parts them.", {})
Potion("Universal Solvent", "Legendary", "A tube of 1d6 + 1 ounces. An ounce dissolves a square foot of any glue, the strongest included.", {})
R.AddMagicItem("Alchemy Jug", "Uncommon", "A Magic action and a word make it pour a liquid of your choice from its list, from water and beer to acid and poison, in the amount the list gives for a day.", nil, { weight = 12 })
R.AddMagicItem("Philosopher's Stone", "Very rare", "Works only for the alchemist who made it. Carried, it is a spellcasting focus and turns one kind of crafting material into another.", nil, { attune = true })
