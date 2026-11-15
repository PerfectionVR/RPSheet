-- Ironwork and stonework a smith makes from journeyman skill up, beyond the arms and
-- armor of the earlier lists: helms, shackles, horseshoes, summoning stones, and a few
-- named weapons and shields. A weapon's own bonus is set on the weapon, on the Weapons
-- page; the descriptions, in our own words, say the rest.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE, SHIELD = { attune = true }, { attune = true, weight = 6 }

Magic("Helm of Comprehending Languages", "Uncommon", "While you wear it you can cast Comprehend Languages.")
Magic("Helm of Telepathy", "Uncommon", "You speak mind to mind within 30 feet, and once a day each can cast Detect Thoughts or Suggestion, save DC 13.", nil, ATTUNE)
Magic("Sending Stones", "Uncommon", "A matched pair. Once a day, touching one casts Sending to whoever carries the other. If one breaks, the other is plain stone.")
Magic("Trident of Fish Command", "Uncommon", "Three charges, of which 1d3 come back each dawn. A charge casts Dominate Beast (save DC 15) on a beast that swims.", nil, { attune = true, weight = 4 })

Magic("Brazier of Commanding Fire Elementals", "Rare", "Once a day a Magic action beside it calls a fire elemental, which obeys you for up to an hour.")
Magic("Stone of Controlling Earth Elementals", "Rare", "Once a day, touched to the ground, it calls an earth elemental within 30 feet, which obeys you for up to an hour.", nil, { weight = 5 })
Magic("Dimensional Shackles", "Rare", "Put on a helpless creature of Small to Large size, they stop it from teleporting or leaving the plane by magic. Once in 30 days it may break them with a DC 30 Athletics check.")
Magic("Helm of Teleportation", "Rare", "Three charges, of which 1d3 come back each dawn. A charge casts Teleport.", nil, ATTUNE)
Magic("Horseshoes of Speed", "Rare", "A set of four. A horse or the like shod with all of them is 30 feet faster.")
Magic("Iron Bands of Bilarro", "Rare", "An iron ball thrown at a Huge or smaller creature within 60 feet, with your Dexterity and proficiency bonus. On a hit it springs open and restrains the creature until you call it back.", nil, { weight = 1 })
Magic("Dagger of Venom", "Rare", "A dagger with a magic bonus of 1 (set it on the Weapons page). Once a day a bonus action coats it in poison for a minute: the next creature hit makes a DC 15 Constitution save or takes 2d10 poison damage and is poisoned for a minute.", nil, { weight = 1 })
Magic("Mace of Terror", "Rare", "Three charges, of which 1d3 come back each dawn. A charge sends out a wave of terror: creatures you choose within 30 feet must pass a DC 15 Wisdom save or flee in fright for a minute.", nil, { attune = true, weight = 4 })
Magic("Shield of Missile Attraction", "Rare", "You resist damage from ranged weapon attacks while you hold it. It is cursed: every ranged weapon attack on someone within 10 feet of you is aimed at you instead, and laying the shield down doesn't end that.", nil, SHIELD)

Magic("Helm of Brilliance", "Very rare", "Set with diamonds, rubies, fire opals and opals. While they last: its light burns undead near you for 1d6 radiant damage a turn, your weapon can flame for 1d6 more fire damage, you resist fire damage, and a gem can be spent to cast Daylight, Fireball, Prismatic Spray or Wall of Fire, save DC 18.", nil, ATTUNE)
Magic("Horseshoes of a Zephyr", "Very rare", "A set of four. A horse or the like shod with all of them floats a hand above the ground: it crosses water and lava, leaves no tracks, ignores difficult terrain and travels longer without tiring.")
Magic("Dwarven Thrower", "Very rare", "For a dwarf. A weapon with a magic bonus of 3 (set it on the Weapons page) that can be thrown 20 or 60 feet and flies back to your hand. Thrown, it deals 1d8 more force damage, 2d8 to a giant.", nil, { attune = true, weight = 5 })
Magic("Scimitar of Speed", "Very rare", "A scimitar with a magic bonus of 2 (set it on the Weapons page). You can attack with it once more as a bonus action each turn.", nil, { attune = true, weight = 3 })
Magic("Animated Shield", "Very rare", "A bonus action sends it floating beside you for a minute, guarding you as if you held it and leaving your hands free.", nil, SHIELD)

Magic("Iron Flask", "Legendary", "A Magic action aims it at a creature from another plane within 60 feet: a DC 17 Wisdom save or it is drawn into the flask, one at a time. Let out, it does as you say for an hour.")
Magic("Sword of Answering", "Legendary", "A sword with a magic bonus of 3 (set it on the Weapons page). As a reaction you strike back with advantage at a creature in reach that just hurt you, and that blow ignores its resistance and immunity.", nil, { attune = true, weight = 3 })
Magic("Armor of Invulnerability", "Legendary", "Plate armor in which you resist bludgeoning, piercing and slashing damage. Once a day a Magic action makes you immune to them for ten minutes.", nil, { attune = true, weight = 65 })
