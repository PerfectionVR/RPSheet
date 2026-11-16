-- Magic items whose magic depends on the situation: a bonus against one kind of
-- creature, on some rolls only, or paid for with charges. The sheet counts the part
-- that always holds (as effects) and the description, in our own words, says the rest.
-- A weapon's own bonus is set on the weapon, on the Weapons page.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }
local function Adds(target, flat)
    return { { target = target, flat = flat, stat = "", times = 1 } }
end

-- Weapons.
Magic("Dragon Slayer", "Rare", "A weapon with a magic bonus of 1 (set it on the Weapons page). Against a dragon it deals 3d6 more damage of its own kind.")
Magic("Giant Slayer", "Rare", "A weapon with a magic bonus of 1 (set it on the Weapons page). A giant it hits takes 2d6 more damage and must pass a DC 15 Strength save or fall prone.")
Magic("Mace of Smiting", "Rare", "A mace with a magic bonus of 1, or 3 against constructs (set it on the Weapons page). A natural 20 adds 7 bludgeoning damage, 14 against a construct.", nil, { weight = 4 })
Magic("Mace of Disruption", "Rare", "A fiend or undead it hits takes 2d6 more radiant damage, and one left with 25 hit points or fewer must pass a DC 15 Wisdom save or be destroyed.", nil, { attune = true, weight = 4 })
Magic("Sun Blade", "Rare", "A hilt that grows a blade of light: a finesse longsword with a magic bonus of 2 (set it on the Weapons page) that deals radiant damage, and 1d8 more to undead. Its light is sunlight.", nil, { attune = true, weight = 3 })
Magic("Flame Tongue", "Rare", "A bonus action and a word set the weapon ablaze: it sheds light and deals 2d6 more fire damage on a hit until you put it out or put it away.", nil, ATTUNE)
Magic("Frost Brand", "Very rare", "Deals 1d6 more cold damage on a hit, and you resist fire damage while you hold it. Drawing it can put out the flames around you, once an hour.", nil, ATTUNE)
Magic("Vicious Weapon", "Rare", "Deals 2d6 more damage of its own kind to any creature it hits.")
Magic("Sword of Life Stealing", "Rare", "On a natural 20 the target takes 15 more necrotic damage, unless it is a construct or undead, and you gain as many temporary hit points.", nil, ATTUNE)
Magic("Holy Avenger", "Legendary", "A weapon for a Paladin with a magic bonus of 3 (set it on the Weapons page). Fiends and undead take 2d10 more radiant damage, and while it is drawn you and your friends within 10 feet have advantage on saves against spells and magic.", nil, ATTUNE)
Magic("Luck Blade", "Legendary", "A weapon with a magic bonus of 1 (set it on the Weapons page) that adds 1 to every saving throw while you carry it. Once a day it lets you reroll a failed d20, and it holds a few wishes.",
    Adds("SAVES", 1), ATTUNE)
Magic("Weapon of Warning", "Uncommon", "While it is within reach, you and allies within 30 feet have advantage on initiative rolls and are woken from natural sleep when a fight starts.", nil, ATTUNE)
Magic("Javelin of Lightning", "Uncommon", "Can deal lightning damage instead of piercing. Once a day, thrown at a target within 120 feet, it becomes a bolt: everyone in the line makes a DC 13 Dexterity save for 4d6 lightning damage, half on a success.", nil, { weight = 2 })
Magic("Staff of Striking", "Very rare", "A quarterstaff with a magic bonus of 3 (set it on the Weapons page) and 10 charges. On a hit you can spend up to 3 charges for 1d6 force damage each; 1d6 + 4 charges come back at dawn.", nil, { attune = true, weight = 4 })
Magic("Bracers of Archery", "Uncommon", "While you wear them you are proficient with longbows and shortbows and deal 2 more damage with them. The sheet doesn't add that by itself, since it is for those bows only.", nil, ATTUNE)

-- Armor and shields.
Magic("Dwarven Plate", "Very rare", "Plate armor that adds 2 to your Armor Class. When something pushes you along the ground you can use your reaction to be moved up to 10 feet less.", Adds("AC", 2), { weight = 65 })
Magic("Elven Chain", "Rare", "A chain shirt that adds 1 to your Armor Class and that anyone can wear as if trained in it.", Adds("AC", 1), { weight = 20 })
Magic("Arrow-Catching Shield", "Rare", "A shield that adds 2 more to your Armor Class against ranged attacks only (not counted on the sheet). As a reaction you can draw a ranged attack on someone within 5 feet onto yourself.", nil, { attune = true, weight = 6 })
Magic("Sentinel Shield", "Uncommon", "While you hold it you have advantage on initiative rolls and on Perception checks.", nil, { weight = 6 })
Magic("Spellguard Shield", "Very rare", "While you hold it you have advantage on saves against spells and magic, and spell attacks against you have disadvantage.", nil, { attune = true, weight = 6 })

-- Worn and carried.
Magic("Mantle of Spell Resistance", "Rare", "While you wear it you have advantage on saving throws against spells.", nil, ATTUNE)
Magic("Ring of Evasion", "Rare", "Three charges, of which 1d3 come back each dawn. When you fail a Dexterity save you can spend one as a reaction to succeed instead.", nil, ATTUNE)
Magic("Ring of Free Action", "Rare", "Difficult terrain costs you no extra movement, and magic can't slow you, paralyze you or restrain you.", nil, ATTUNE)
Magic("Periapt of Proof against Poison", "Rare", "While you wear it, poison can't harm you: you are immune to poison damage and to being poisoned.", nil, { attune = true, weight = 1 })
Magic("Cloak of Elvenkind", "Uncommon", "While you wear it you have advantage on Stealth checks, and Perception checks to notice you have disadvantage.", nil, ATTUNE)
Magic("Boots of Elvenkind", "Uncommon", "Your steps make no sound, and you have advantage on Stealth checks.")
Magic("Cloak of Displacement", "Rare", "Attack rolls against you have disadvantage. Taking damage switches that off until your next turn starts, and it doesn't work while your speed is 0.", nil, ATTUNE)
Magic("Gloves of Missile Snaring", "Uncommon", "When a ranged or thrown weapon hits you, a reaction lowers the damage by 1d10 + your Dexterity modifier if you have a hand free; at 0 you catch it.", nil, ATTUNE)
Magic("Wand of Magic Missiles", "Uncommon", "Seven charges, of which 1d6 + 1 come back each dawn. Spend 1 to 3 to cast Magic Missile, a spell level higher for each charge after the first.", nil, { weight = 1 })
Magic("Staff of Healing", "Rare", "Ten charges, of which 1d6 + 4 come back each dawn, spent to cast healing spells with your own spellcasting ability. For Priests and Druids.", nil, { attune = true, weight = 4 })
Magic("Defias Leather", "Rare", "Leather armor that gives advantage on Stealth checks to hide behind stonework, and once a day lets you cast Meld into Stone.", nil, { weight = 10 })
