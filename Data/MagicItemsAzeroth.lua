-- Azeroth's own magic items that the earlier lists left out, and its artifacts: the
-- named weapons of its heroes and villains. An artifact has no price and is found, not
-- made. Descriptions are in our own words; a weapon's bonus is set on the weapon, on
-- the Weapons page.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }
local BONUS = " with a magic bonus of 3 (set it on the Weapons page). "

Magic("Hearthstone", "Uncommon", "A Magic action at an inn sets it to that place. Used for a minute, with a Magic action, it takes you back to within 30 feet of there.", nil, ATTUNE)
Magic("Gnomeregan Engineering Device", "Rare", "Lent by Gnomeregan's leaders to those Revered there, for a task done in their name. It works like a Wand of Wonder, for you alone, never regains charges and bursts harmlessly with the last one.")
Magic("Crown of the Ogre King", "Very rare", "A Magic action lets out a belch heard 300 feet away: creatures in a 20-foot cone are pushed 20 feet and knocked prone unless they pass a DC 17 Strength save. It is cursed: you eat three times as much and lose your table manners until the curse is lifted.", nil, ATTUNE)
Magic("Vithrak, Gaze of the Deadman", "Very rare", "A ring with three charges, of which 1d3 come back each dawn. A charge and a Magic action tell you what a creature within 120 feet resists, is immune to and is vulnerable to.")
Magic("Judgment Armor", "Legendary", "Plate armor that keeps Detect Evil and Good and Protection from Evil and Good on you without concentration. A Paladin's protection reaches the allies in its aura.", nil, { weight = 65 })
Magic("Steamwheedle Apparatus", "Legendary", "The goblin make of the Apparatus of Kwalish: an iron barrel for two that, worked right, walks and swims like a giant lobster.", nil, { weight = 500, cost = 10000000 })
R.RECIPE_BASE["Judgment Armor"] = "Plate Armor"

-- Artifacts
Magic("Ashbringer", "Artifact", "A greatsword" .. BONUS .. "It deals 1d10 more fire damage, 3d10 against undead. It has a mind of its own and two states, true and corrupted, each with a power; legendary deeds turn it from one to the other. For a Paladin.", nil, { attune = true, weight = 6 })
Magic("Doomhammer", "Artifact", "A warhammer" .. BONUS .. "It deals 1d8 more lightning damage. While you rage your speed doubles and you attack once more each turn; you walk on lava unharmed, and a reaction stops lightning damage to a creature within 60 feet. For a Shaman.", nil, { attune = true, weight = 5 })
Magic("Frostmourne", "Artifact", "A greatsword" .. BONUS .. "It deals 2d12 more cold damage. A creature it brings to 0 hit points dies and its soul is caught in the blade. The Lich King sees, hears and speaks through whoever is attuned to it.", nil, { attune = true, weight = 6 })
Magic("Helm of Domination", "Artifact", "Attuning takes a DC 18 Charisma save: pass and take 10d6 psychic damage, fail and the Lich King takes your body for good. You can't give it up again. It lets you send commands to the undead of the Scourge.", nil, ATTUNE)
Magic("Shalamayne", "Artifact", "A greatsword" .. BONUS .. "It deals 2d12 more force damage, and one who has mastered the greatsword uses Graze and Sap at once. A Magic action splits it into two longswords with a bonus of 3 that need no attunement, or joins them again.", nil, { attune = true, weight = 6 })
Magic("Sulfuras, Hand of Ragnaros", "Artifact", "A maul" .. BONUS .. "It deals 1d10 more fire damage and sets the target burning for 1d10 at the start of each of its turns. Once a day each it turns the elements on your foes, such as boiling all water within a mile.", nil, { attune = true, weight = 10 })
Magic("Twin Blades of Azzinoth", "Artifact", "A pair of warglaives" .. BONUS .. "Each deals 2d8 more psychic damage to fiends, which nothing reduces. Hit one creature with both in a turn and it must pass a DC 18 Wisdom save or be stunned. A thrown blade becomes a fiend that fights for you.", nil, { attune = true, weight = 3 })
