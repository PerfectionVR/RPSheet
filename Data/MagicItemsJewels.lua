-- The rings and worn jewelry jewelcrafting makes beyond those of the earlier lists.
-- Almost all of it is resistance, senses or a spell held in a stone, which the sheet
-- doesn't keep as numbers: the descriptions, in our own words, say what they give.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE, PENDANT = { attune = true }, { attune = true, weight = 1 }
local THREE = "Three charges, of which 1d3 come back each dawn."

-- Rings.
Magic("Ring of Jumping", "Uncommon", "While you wear it you can cast Jump on yourself.", nil, ATTUNE)
Magic("Ring of Mind Shielding", "Uncommon", "Magic can't read your thoughts, tell whether you lie, or learn your alignment or kind, and nobody speaks into your mind unless you allow it.", nil, ATTUNE)
Magic("Ring of Warmth", "Uncommon", "Lowers cold damage you take by 2d8, and you and what you carry are unharmed by freezing cold.", nil, ATTUNE)
Magic("Ring of Water Walking", "Uncommon", "While you wear it you can cast Water Walk on yourself.")
for _, kind in ipairs({ "Acid", "Cold", "Fire", "Force", "Lightning", "Necrotic", "Poison", "Psychic", "Radiant", "Thunder" }) do
    Magic(("Ring of %s Resistance"):format(kind), "Rare", ("While you wear it you resist %s damage."):format(kind:lower()))
end
Magic("Ring of Animal Influence", "Rare", THREE .. " A charge casts Animal Friendship, Speak with Animals, or Fear on beasts only, save DC 13.")
Magic("Ring of Feather Falling", "Rare", "When you fall you sink 60 feet a round and take no damage.", nil, ATTUNE)
Magic("Ring of Spell Storing", "Rare", "Holds up to five levels of spells cast into it by anyone, each of 5th level or lower. Its wearer casts them later with the first caster's numbers.", nil, ATTUNE)
Magic("Ring of the Ram", "Rare", THREE .. " One to three make a ranged spell attack at +7 within 60 feet: 2d10 force damage and a 5-foot push for each charge. It can also batter an object.", nil, ATTUNE)
Magic("Ring of X-ray Vision", "Rare", "A Magic action lets you see through solid things within 30 feet for a minute; thick stone, metal or a sheet of lead stops it. A second use before a long rest asks a DC 15 Constitution save against exhaustion.", nil, ATTUNE)
Magic("Ring of Regeneration", "Very rare", "While you have at least 1 hit point you regain 1d6 hit points every ten minutes, and a lost body part grows back in 1d6 + 1 days.", nil, ATTUNE)
Magic("Ring of Shooting Stars", "Very rare", "Casts Dancing Lights and Light. Six charges, of which 1d6 come back each dawn, for Faerie Fire, spheres of lightning and more.", nil, ATTUNE)
Magic("Ring of Telekinesis", "Very rare", "While you wear it you can cast Telekinesis.", nil, ATTUNE)
Magic("Ring of Djinni Summoning", "Legendary", "A Magic action calls one particular djinni to within 120 feet. It obeys you while you concentrate, for up to an hour, and then can't be called for a good while.", nil, ATTUNE)
for _, plane in ipairs({ "Air", "Earth", "Fire", "Water" }) do
    Magic(("Ring of Elemental Command (%s)"):format(plane), "Legendary",
        ("Bound to the plane of %s. You have advantage on attacks against elementals and they have disadvantage against you, and a Magic action can compel one within 60 feet (a DC 18 Wisdom save). It holds more powers of its plane."):format(plane:lower()),
        nil, ATTUNE)
end
Magic("Ring of Invisibility", "Legendary", "A Magic action makes you invisible until you take the ring off or end it with a bonus action.", nil, ATTUNE)
Magic("Ring of Spell Turning", "Legendary", "You have advantage on saves against spells. A spell of 7th level or lower you save against does nothing to you, and one aimed at you alone can be thrown back at its caster with a reaction.", nil, ATTUNE)
Magic("Ring of Three Wishes", "Legendary", "Three charges, each a casting of Wish. With the last one spent it is a plain ring.")
R.CONSUMABLES["Ring of Three Wishes"] = true

-- Worn at the neck, on the brow or over the eyes.
Magic("Amulet of Proof against Detection and Location", "Uncommon", "Divination spells can't target you and scrying can't see you unless you allow it.", nil, PENDANT)
Magic("Brooch of Shielding", "Uncommon", "You resist force damage, and Magic Missile can't harm you.", nil, ATTUNE)
Magic("Circlet of Blasting", "Uncommon", "Once a day you can cast Scorching Ray from it, at +5 to hit.")
Magic("Eyes of Charming", "Uncommon", "Lenses with three charges a day. A charge casts Charm Person (save DC 13), a spell level higher for each charge after the first.", nil, ATTUNE)
Magic("Eyes of Minute Seeing", "Uncommon", "Lenses that sharpen what is within a foot of you: darkvision there, and advantage on Investigation checks to study something that close.")
Magic("Medallion of Thoughts", "Uncommon", "Five charges, of which 1d4 come back each dawn. A charge casts Detect Thoughts, save DC 13.", nil, PENDANT)
Magic("Necklace of Adaptation", "Uncommon", "You breathe normally anywhere, and have advantage on saves against being poisoned.", nil, PENDANT)
Magic("Pearl of Power", "Uncommon", "Once a day a Magic action gives back one spent spell slot of 3rd level or lower. For a spellcaster.", nil, ATTUNE)
Magic("Periapt of Health", "Uncommon", "Once a day a Magic action restores 2d4 + 2 hit points, and you have advantage on saves against being poisoned.", nil, PENDANT)
Magic("Periapt of Wound Closure", "Uncommon", "A death saving throw of 9 or lower counts as a 10, and a Hit Die you spend heals twice what it rolls.", nil, PENDANT)
Magic("Amulet of the Planes", "Very rare", "A Magic action and a DC 15 Arcana check cast Plane Shift to a place you know on another plane. On a failure you and all within 15 feet land somewhere at random.", nil, PENDANT)
Magic("Necklace of Fireballs", "Rare", "Carries 1d6 + 3 beads. A bead thrown up to 60 feet bursts as a 3rd-level Fireball, save DC 15; several thrown together make a stronger one.", nil, { weight = 1 })
Magic("Necklace of Prayer Beads", "Rare", "Carries 1d4 + 2 magic beads, each holding one spell of blessing, healing or smiting that you cast from it. For a Priest, Druid or Paladin.", nil, PENDANT)
R.CONSUMABLES["Necklace of Fireballs"] = true

-- Loose stones and lenses.
Magic("Gem of Brightness", "Uncommon", "Fifty charges. One word makes it shine like a lantern for nothing; another spends a charge on a blinding beam at a creature within 60 feet; a third spends more on a blinding flash.")
Magic("Gem of Seeing", "Rare", THREE .. " A charge gives you truesight out to 120 feet for ten minutes while you look through it.", nil, ATTUNE)
Magic("Elemental Gem", "Uncommon", "Breaking it calls an elemental that obeys you for a while: air from a sapphire, earth from a yellow diamond, fire from a red corundum, water from an emerald.")
Magic("Bead of Force", "Rare", "Thrown up to 60 feet, it bursts in a 10-foot sphere: a DC 15 Dexterity save or 5d4 force damage and a minute shut inside a sphere of force.", nil, { weight = 0.5 })
Magic("Censer of Controlling Air Elementals", "Rare", "Once a day, swung gently, it calls an air elemental, which obeys you for up to an hour.")
Magic("Cube of Force", "Rare", "Ten charges, of which 1d6 come back each dawn. Its faces cast warding spells, from Mage Armor and Shield for one charge to Wall of Force for five, save DC 17.", nil, ATTUNE)
Magic("Mirror of Life Trapping", "Very rare", "A tall hanging mirror, switched on and off with a word. A creature that sees itself in it may be drawn into one of its cells, to stay until freed.", nil, { weight = 50 })
for _, name in ipairs({ "Gem of Brightness", "Elemental Gem", "Bead of Force" }) do R.CONSUMABLES[name] = true end
