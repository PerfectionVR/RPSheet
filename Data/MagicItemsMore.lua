-- Magic items the earlier lists left out: odd finds, cursed things, the bards'
-- instruments, and named makes of armor and weapons. None changes a number the sheet
-- counts by itself, so each is a description in our own words; a weapon's bonus is
-- set on the weapon, on the Weapons page.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }
local BONUS = "A weapon with a magic bonus of %d (set it on the Weapons page). "

-- Finds
Magic("Candle of the Deep", "Common", "A candle whose flame keeps burning under water.")
Magic("Eyes of the Eagle", "Uncommon", "Crystal lenses: advantage on Perception checks that rely on sight, and in clear weather you make out far-off things as small as 2 feet across.")
Magic("Hag Eye", "Uncommon", "Three charges, back each dawn. A charge casts Darkvision on yourself or See Invisibility. The coven that made it can look through it.")
Magic("Dust of Sneezing and Choking", "Uncommon", "Looks like Dust of Disappearance. Thrown, it makes you and everyone within 30 feet pass a DC 15 Constitution save or sneeze helplessly: incapacitated and suffocating, with a new save at the end of each turn.")
Magic("Belt of Dwarvenkind", "Rare", "You know Dwarvish, have advantage on Persuasion with dwarves, and your Constitution rises by 2, to 20 at most (raise it by hand). If you are no dwarf you also see in the dark for 60 feet and shrug off poison like one.", nil, ATTUNE)
Magic("Folding Boat", "Rare", "A wooden box that unfolds, on one command word, into a rowboat and, on another, into a keelboat; a third folds it up again.", nil, { weight = 4 })
Magic("Bag of Devouring", "Very rare", "Looks like a Bag of Holding but is the mouth of something from elsewhere. What is put in is eaten, and a hand reaching in has an even chance of being pulled in after it.")
Magic("Candle of Invocation", "Very rare", "Burns for 4 hours in all. In its light you have advantage on d20 rolls, and a Priest or Druid casts prepared 1st-level spells without slots. Lit for the first time it can cast Gate instead, which uses it up.", nil, ATTUNE)
Magic("Crystal Ball", "Very rare", "While touching it you can cast Scrying, save DC 17.", nil, { attune = true, weight = 3 })
Magic("Efreeti Bottle", "Very rare", "Unstoppered, it lets out an efreeti. The first time, the DM rolls for what it does: serve you for a while, grant wishes, or attack.")
Magic("Lute of Thunderous Thumping", "Very rare", "A reinforced lute that is swung as a magic club and deals 2d8 extra thunder damage. A bard who sings along attacks with Charisma.", nil, { weight = 2 })
Magic("Deck of Many Things", "Legendary", "Say how many cards you draw, then draw them: each takes effect at once, for great good or great harm, and can't be taken back.")
Magic("Talisman of Pure Good", "Legendary", "A holy symbol that adds 2 to spell attack rolls. Seven charges: one opens a fiery fissure under a creature within 120 feet, which a failed DC 20 Dexterity save drops it into. Fiends and undead that touch it take 8d6 radiant damage. For Priests and Paladins.", nil, { attune = true, weight = 1 })
Magic("Talisman of Ultimate Evil", "Legendary", "An unholy symbol that adds 2 to spell attack rolls. Six charges: one opens a fiery fissure under a creature within 120 feet. Anyone but a fiend or an undead who touches it takes 8d6 necrotic damage.", nil, { attune = true, weight = 1 })
R.CONSUMABLES["Dust of Sneezing and Choking"], R.CONSUMABLES["Candle of Invocation"] = true, true

-- The seven instruments of the bards, by rarity.
local INSTRUMENT = "An instrument only a bard can attune to. Once a day each it casts Fly, Invisibility, Levitate and Protection from Evil and Good, and a few spells of its own. Anyone else who plays it risks 2d4 psychic damage (DC 15 Wisdom save)."
for name, rarity in pairs({
    ["Doss Lute"] = "Uncommon", ["Fochlucan Bandore"] = "Uncommon", ["Mac-Fuirmidh Cittern"] = "Uncommon",
    ["Canaith Mandolin"] = "Rare", ["Cli Lyre"] = "Rare", ["Anstruth Harp"] = "Very rare", ["Ollamh Harp"] = "Legendary",
}) do
    Magic("Instrument of the Bards, " .. name, rarity, INSTRUMENT, nil, ATTUNE)
end

-- Makes of armor
Magic("Armor of Gleaming", "Common", "A suit of armor that never gets dirty.")
Magic("Cast-Off Armor", "Common", "A suit of armor you can take off with a single action.")
Magic("Smoldering Armor", "Common", "A suit of armor that gives off wisps of harmless smoke while worn.")
Magic("Mariner's Armor", "Uncommon", "A suit of armor that lets you swim as fast as you walk and lifts you 60 feet toward the surface whenever you start a turn under water at 0 hit points.")
Magic("Armor of Vulnerability", "Rare", "A suit of armor that gives resistance to one of bludgeoning, piercing or slashing damage. It is cursed: you are vulnerable to the other two until the curse is lifted, even with the armor off.", nil, ATTUNE)
Magic("Demon Armor", "Very rare", "Armor that adds 1 to your Armor Class and whose claws make your unarmed strikes deal 1d8 slashing damage with a bonus of 1. It is cursed: it won't come off, and you fight demons at a disadvantage.", nil, ATTUNE)
Magic("Efreeti Chain", "Legendary", "Chain armor that adds 3 to your Armor Class, makes you immune to fire damage and lets you walk on molten rock.", nil, ATTUNE)
Magic("Plate Armor of Etherealness", "Legendary", "Plate or half plate. Once a day a Magic action and a command word send you into the Ethereal Plane, as the Etherealness spell, until you say the word again or take the armor off.", nil, ATTUNE)

-- Makes of weapons
Magic("Moon-Touched Sword", "Common", "A sword whose drawn blade sheds moonlight in darkness: bright for 15 feet and dim for 15 more.")
Magic("Sylvan Talon", "Common", "While you carry it, you and fey understand each other without words, and once a day it casts Message.", nil, ATTUNE)
Magic("Sword of Vengeance", "Uncommon", BONUS:format(1) .. "It is cursed: you won't part with it, attack worse with any other weapon, and when hurt may be driven to attack whoever hurt you.", nil, ATTUNE)
Magic("Berserker Axe", "Rare", BONUS:format(1) .. "Attuned, you have 1 more hit point for each level (add them by hand). It is cursed: you won't part with it, attack worse with other weapons, and may go berserk when hurt.", nil, ATTUNE)
Magic("Sword of Wounding", "Rare", "Once a turn a hit wounds: the target takes 1d4 necrotic damage at the start of each of its turns for every wound, until it passes a DC 15 Constitution save. Hit points it takes are regained only by resting.", nil, ATTUNE)
Magic("Dancing Sword", "Very rare", "A bonus action sets it hovering: it flies up to 30 feet and attacks a creature with your own attack roll, and can be sent on with further bonus actions.", nil, ATTUNE)
Magic("Energy Bow", "Very rare", BONUS:format(1) .. "A stringless bow that makes its own arrows of golden light, which deal force damage and shine brightly.", nil, ATTUNE)
Magic("Executioner's Axe", "Very rare", BONUS:format(1) .. "A humanoid it hits takes 2d6 more slashing damage, and you gain that much in temporary hit points.")
Magic("Nine Lives Stealer", "Very rare", BONUS:format(2) .. "It has 1d8 + 1 charges. A critical hit on a creature with fewer than 100 hit points kills it outright unless it passes a DC 15 Constitution save, which uses a charge.", nil, ATTUNE)
Magic("Oathbow", "Very rare", "Name a target your sworn enemy as you shoot: until it dies or a week passes you have advantage against it, ignore its cover and long range, and deal 3d6 more piercing damage. Meanwhile you attack worse with other weapons.", nil, ATTUNE)
Magic("Sword of Sharpness", "Very rare", "Against objects its damage dice count as their highest. A 20 on the attack roll deals 14 more slashing damage, and a second 20 on a d20 lops off a limb.", nil, ATTUNE)
Magic("Defender", "Legendary", BONUS:format(3) .. "With the first attack of your turn you can move some or all of the bonus to your Armor Class until your next turn.", nil, ATTUNE)
Magic("Hammer of Thunderbolts", "Legendary", BONUS:format(1) .. "Five charges: a charge hurls it 20 or 60 feet, and on a hit a thunderclap stuns the target and everyone within 30 feet of it that fails a DC 17 Constitution save.", nil, ATTUNE)
Magic("Moonblade", "Legendary", BONUS:format(1) .. "An elven heirloom with a will of its own, which chooses its bearer. Each rune on the blade gives it another property, for the DM to decide.", nil, ATTUNE)
Magic("Vorpal Sword", "Legendary", BONUS:format(3) .. "It ignores resistance to slashing damage, and a 20 on the attack roll takes off a head, which kills most creatures that have only the one.", nil, ATTUNE)
for _, name in ipairs({ "Sword of Vengeance", "Berserker Axe", "Sword of Wounding", "Dancing Sword", "Energy Bow", "Executioner's Axe", "Nine Lives Stealer",
    "Oathbow", "Sword of Sharpness", "Defender", "Hammer of Thunderbolts", "Moonblade", "Vorpal Sword", "Moon-Touched Sword", "Sylvan Talon" }) do
    R.RECIPE_OPEN[name] = "the plain weapon"
end
for _, name in ipairs({ "Armor of Gleaming", "Cast-Off Armor", "Smoldering Armor", "Mariner's Armor", "Armor of Vulnerability", "Demon Armor", "Efreeti Chain", "Plate Armor of Etherealness" }) do
    R.RECIPE_OPEN[name] = "the plain suit of armor"
end
