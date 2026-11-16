-- Cloth and leather goods from journeyman skill up, beyond the cloaks, boots and gloves
-- of the earlier lists (the common ones are in Data/MagicItemsTrinkets.lua). The sheet
-- counts the one plain bonus here, the thief's gloves; the rest is told, in our own words.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }

-- A tailor's.
Magic("Bag of Holding", "Uncommon", "Bigger inside than out: it holds 500 pounds or 64 cubic feet and always weighs 5 pounds. Overfilled or torn, it is destroyed and what was in it is lost.", nil, { weight = 5 })
Magic("Bag of Tricks", "Uncommon", "A Magic action pulls out a small fuzzy ball and throws it up to 20 feet, where it becomes a friendly animal until dawn; a roll says which. Gray, rust and tan bags hold different animals.")
Magic("Cap of Water Breathing", "Uncommon", "Underwater, a Magic action wraps your head in a bubble of air that stays while you wear the cap.")
Magic("Gloves of Swimming and Climbing", "Uncommon", "Climbing and swimming cost you no extra movement, and you add 5 to Athletics checks to climb or swim (not counted on the sheet).", nil, ATTUNE)
Magic("Gloves of Thievery", "Uncommon", "Can't be seen while worn, and add 5 to your Sleight of Hand checks.",
    { { target = "SKILL:Sleight of Hand", flat = 5, stat = "", times = 1 } })
Magic("Hat of Disguise", "Uncommon", "While you wear it you can cast Disguise Self; taking it off ends the spell.", nil, ATTUNE)
Magic("Nature's Mantle", "Uncommon", "For a Druid or Hunter. A spellcasting focus that takes on the look of the land; in a lightly obscured place you can hide as a bonus action even while watched.", nil, ATTUNE)
Magic("Robe of Useful Items", "Uncommon", "Covered in patches, each of which a Magic action pulls off to become the thing it shows: a lantern, a dagger, a rope, a sack and stranger things. With the last patch gone it is a plain robe.")
Magic("Rope of Climbing", "Uncommon", "Sixty feet of rope that holds 3,000 pounds. On your word its far end crawls where you send it, 10 feet a turn, and ties or unties itself.")
for bonus, rarity in ipairs({ "Uncommon", "Rare", "Very rare" }) do
    Magic(("+%d Wraps of Unarmed Power"):format(bonus), rarity,
        ("Add %d to the attack and damage rolls of your unarmed strikes, which can deal force damage instead of their own kind. The sheet doesn't add that by itself."):format(bonus))
end
Magic("Bag of Beans", "Rare", "Holds 3d4 beans. Tipped out, they burst: a DC 15 Dexterity save against 5d4 force damage within 10 feet. A bean planted and watered grows into a surprise a minute later.", nil, { weight = 0.5 })
Magic("Cape of the Mountebank", "Rare", "Once a day you can cast Dimension Door from it, leaving a puff of smoke where you stood.")
Magic("Robe of Eyes", "Rare", "You have advantage on Perception checks that rely on sight, and darkvision and truesight out to 120 feet. Sudden magical light on or near the robe blinds you for a time.", nil, ATTUNE)
Magic("Rope of Entanglement", "Rare", "Thirty feet of rope. A Magic action sends its end at a creature within 20 feet: a DC 15 Dexterity save or it is restrained until it breaks free or you let go.")
Magic("Carpet of Flying", "Very rare", "A Magic action and a word make it hover and fly as you direct from within 30 feet. The 4-by-6-foot one carries 400 pounds at 60 feet a turn, or twice that load at half the speed; other sizes trade speed for load.")
Magic("Hat of Many Spells", "Very rare", "For a Mage. A spellcasting focus; with a slot of the right level and a check you can try to pull a mage spell you don't know out of the hat.", nil, ATTUNE)
Magic("Robe of Scintillating Colors", "Very rare", "Three charges, of which 1d3 come back each dawn. A charge makes it blaze until your next turn ends: attacks against you have disadvantage, and those in its light who see you must pass a DC 15 Wisdom save or be stunned.", nil, ATTUNE)
Magic("Cloak of Invisibility", "Legendary", "Three charges, of which 1d3 come back each dawn. A charge and the hood pulled up make you invisible for an hour, or until you pull it down.", nil, ATTUNE)
R.CONSUMABLES["Bag of Beans"], R.CONSUMABLES["Robe of Useful Items"] = true, true

-- A leatherworker's.
Magic("Boots of the Winterlands", "Uncommon", "You resist cold damage, bear freezing cold without other protection, and ignore difficult terrain made of ice or snow.", nil, ATTUNE)
Magic("Heward's Handy Haversack", "Rare", "A backpack that always weighs 5 pounds. Its two side pouches hold 200 pounds each and the middle one 500, and what you reach for is always on top.", nil, { weight = 5 })
Magic("Quiver of Ehlonna", "Uncommon", "Never weighs more than 2 pounds. Its three parts hold 60 arrows or bolts, 18 javelins, and 6 long things such as bows, staffs or spears.", nil, { weight = 2 })
Magic("Saddle of the Cavalier", "Uncommon", "While you are in it and conscious you can't be thrown from your mount, and attack rolls against the mount have disadvantage.")
Magic("Boots of Levitation", "Rare", "While you wear them you can cast Levitate on yourself.", nil, ATTUNE)
