-- The common magic items an apprentice makes: small conveniences and curiosities with
-- no numbers for the sheet to count. Descriptions are summaries in our own words.
local _, ns = ...
local R = ns.Rules

local ATTUNE = { attune = true }
local function Common(name, desc, extra)
    R.AddMagicItem(name, "Common", desc, nil, extra)
end

-- A cook's.
Common("Bead of Nourishment", "Dissolves on the tongue and feeds you like a day of rations.")
Common("Bead of Refreshment", "Dropped into up to a pint of liquid, turns it into cold, clean water. No use against poison or magic.")
R.CONSUMABLES["Bead of Nourishment"], R.CONSUMABLES["Bead of Refreshment"] = true, true
Common("Heward's Handy Spice Pouch", "Ten charges. A Magic action and a charge bring out a pinch of any seasoning you name, enough for one meal.")
Common("Tankard of Sobriety", "Ale, wine and the like drunk from it can't make you drunk. No use against poison or magic.")

-- An engineer's.
Common("Clockwork Amulet", "Once a day, when you make an attack roll, you can take a 10 on the die without rolling.")
Common("Ear Horn of Hearing", "Held to your ear, it lets you hear in spite of being deafened.")
Common("Ersatz Eye", "Takes the place of a lost eye and sees as well. Putting it in or taking it out is a Magic action; nobody else can remove it.")
Common("Horn of Silent Alarm", "Four charges, of which 1d4 come back each dawn. A charge sounds it for one creature of your choice within 600 feet, and for nobody else.")
Common("Instrument of Illusions", "While you play it, a Magic action fills the air around it with harmless illusions; farther for a bard.")
Common("Instrument of Scribing", "Three charges a day. While you play it, a charge writes a message on a surface you see within 30 feet.")
Common("Lock of Trickery", "Looks like any lock and comes with one key. Picking it is done at disadvantage.")
Common("Mystery Key", "Has a small chance to open any lock it is tried in, and vanishes when it does.")
Common("Orb of Direction", "An arcane focus. A Magic action tells you where north is.", { weight = 3 })
Common("Orb of Time", "An arcane focus. A Magic action tells you whether it is morning, afternoon, evening or night.", { weight = 3 })
Common("Pipe of Smoke Monsters", "A Magic action puffs out smoke in the shape of a small creature, which drifts apart after a few seconds.")
Common("Pole of Angling", "A pole that a Magic action turns into a fishing rod with hook, line and reel, and back.")
Common("Pole of Collapsing", "A pole that a Magic action folds into a foot-long rod, and back. It weighs the same either way.")
Common("Prosthetic Limb", "Takes the place of a lost hand, arm, foot or leg and works as well. Putting it on or off is a Magic action; nobody else can remove it.")
Common("Rival Coin", "Two rivals, one on each side. Once a day a Magic action tosses it, and the side that lands decides which of two small effects a creature feels.")
Common("Veteran's Cane", "A walking cane that a bonus action turns into a plain longsword, and back.")

-- A tailor's and a leatherworker's.
Common("Cloak of Billowing", "A bonus action makes it billow dramatically for a minute.")
Common("Cloak of Many Fashions", "A bonus action changes its style, color and apparent quality. It stays a cloak and gains no other magic.")
Common("Clothes of Mending", "An outfit that mends its own wear and tear. A piece that is destroyed stays lost.")
Common("Hat of Vermin", "Three charges. A Magic action and a charge pull a bat, a frog or a rat out of it, which makes off as fast as it can.")
Common("Hat of Wizardry", "For a Mage. A spellcasting focus; once between long rests you can try a mage cantrip you don't know with a DC 10 Arcana check.", ATTUNE)
Common("Rope of Mending", "Fifty feet of rope whose cut pieces knit together again with a Magic action. A piece that is lost stays lost.")
Common("Talking Doll", "Over a short rest you teach it up to six short phrases and when to say each; it speaks them when that happens within 5 feet of it.", ATTUNE)
Common("Boots of False Tracks", "Leave the footprints of any kind of humanoid of your size, as you wish.", ATTUNE)

-- A smith's, an enchanter's, a scribe's and a jeweler's.
Common("Dark Shard Amulet", "For a Warlock. A spellcasting focus; once between long rests you can try a warlock cantrip you don't know with an Arcana check.", { attune = true, weight = 1 })
Common("Dread Helm", "A fearsome steel helm: your eyes glow red and the rest of your face is lost in shadow.")
Common("Shield of Expression", "A shield shaped like a face, whose expression a bonus action changes.", { weight = 6 })
Common("Charlatan's Die", "A six-sided die that rolls the number you want.", ATTUNE)
Common("Pot of Awakening", "A shrub planted in this clay pot awakens after 30 days as a friendly, thinking plant, breaking the pot.", { weight = 10 })
Common("Enduring Spellbook", "A spellbook that fire, water and age can't harm.")
Common("Ruby of the War Mage", "For a spellcaster. Pressed to a weapon, it lets that weapon serve as your spellcasting focus.", ATTUNE)
Common("Wand of Conducting", "Three charges a day. A charge and a wave of the wand make orchestral music that carries 120 feet.", { weight = 1 })
Common("Wand of Pyrotechnics", "Seven charges. A charge sets off a harmless burst of colored light at a point within 120 feet, with a crackle heard 300 feet away.", { weight = 1 })
Common("Staff of Adornment", "A Tiny object set above its tip floats there until it is taken away.", { weight = 4 })
Common("Staff of Birdcalls", "Ten charges. A charge makes it give one of several bird calls, heard 120 feet away.", { weight = 4 })
Common("Staff of Flowers", "Ten charges. A charge makes a flower sprout from soil within 5 feet, or from the staff itself.", { weight = 4 })
Common("Walloping Ammunition", "A creature it hits must pass a DC 10 Strength save or fall prone.")
R.CONSUMABLES["Walloping Ammunition"] = true
