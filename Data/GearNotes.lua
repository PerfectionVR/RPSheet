-- What plain gear is for, in a line or two of our own: shown on an item's block in
-- the item browser and its tooltip, and found by the browser's search. Weapons and
-- armor describe themselves from their numbers (UI/ItemCard.lua).
local _, ns = ...
local R = ns.Rules

local NOTES = {
    -- Thrown and used up
    ["Acid"] = "In place of one attack, throw the vial at a creature or object within 20 feet: Dexterity save (DC 8 + your Dexterity modifier and proficiency bonus) or 2d6 acid damage.",
    ["Alchemist's Fire"] = "In place of one attack, throw the flask at a creature or object within 20 feet: Dexterity save (DC 8 + your Dexterity modifier and proficiency bonus) or 1d4 fire damage, and it starts burning.",
    ["Holy Water"] = "In place of one attack, throw the flask at a creature within 20 feet: Dexterity save (DC 8 + your Dexterity modifier and proficiency bonus) or 2d8 radiant damage if it is a fiend or an undead.",
    ["Oil"] = "A flask of lamp oil: fuel for lamps and lanterns, or thrown in place of an attack to douse a creature or object, which then takes extra fire damage if it burns.",
    ["Net"] = "In place of one attack, throw it at a creature within 15 feet: Dexterity save (DC 8 + your Dexterity modifier and proficiency bonus) or Restrained until it gets free.",
    ["Antitoxin"] = "Drink it as a bonus action: advantage on saves against being Poisoned, and to end it, for an hour.",
    ["Basic Poison"] = "As a bonus action, coat a weapon or up to three pieces of ammunition: piercing or slashing damage from it adds 1d4 poison damage, for a minute or until it hits.",
    ["Ball Bearings"] = "Spill them over a 10-foot square within 10 feet: a creature that enters it for the first time on a turn makes a DC 10 Dexterity save or falls Prone. Gathering them up takes 10 minutes.",
    ["Caltrops"] = "Spread them over a 5-foot square next to you: a creature that enters it for the first time on a turn makes a DC 15 Dexterity save or takes 1 piercing damage and can't move until its next turn. Gathering them up takes 10 minutes.",
    ["Healer's Kit"] = "Ten uses. One use stabilizes a creature at 0 hit points without a Medicine check.",
    -- Poisons (the DM decides how they are applied)
    ["Assassin's Blood"] = "Ingested poison: DC 10 Constitution save or 1d12 poison damage and Poisoned for a day; half damage on a success.",
    ["Burnt Othur Fumes"] = "Inhaled poison: DC 13 Constitution save or 3d6 poison damage, then a save at the start of each turn, 1d6 more on each failure, until three saves succeed.",
    ["Carrion Crawler Mucus"] = "Contact poison: DC 13 Constitution save or Poisoned and Paralyzed for a minute, saving again at the end of each turn.",
    ["Essence of Ether"] = "Inhaled poison: DC 15 Constitution save or Poisoned and Unconscious for 8 hours; damage or a shake wakes the creature.",
    ["Lolth's Sting"] = "Injury poison: DC 13 Constitution save or Poisoned for an hour, and Unconscious too when failed by 5 or more.",
    ["Malice"] = "Inhaled poison: DC 15 Constitution save or Poisoned and Blinded for an hour.",
    ["Midnight Tears"] = "Ingested poison that waits until midnight: then a DC 17 Constitution save against 9d6 poison damage, half on a success, unless it was cured first.",
    ["Oil of Taggit"] = "Contact poison: DC 13 Constitution save or Poisoned and Unconscious for a day; damage wakes the creature.",
    ["Pale Tincture"] = "Ingested poison: DC 16 Constitution save or 1d6 poison damage and Poisoned, repeating every day; its damage can't be healed while it lasts.",
    ["Purple Worm Poison"] = "Injury poison: DC 21 Constitution save against 10d6 poison damage, half on a success.",
    ["Serpent Venom"] = "Injury poison: DC 11 Constitution save against 3d6 poison damage, half on a success.",
    ["Torpor"] = "Ingested poison: DC 15 Constitution save or Poisoned for 4d6 hours, at half speed.",
    ["Truth Serum"] = "Ingested poison: DC 11 Constitution save or Poisoned for an hour, unable to knowingly lie.",
    ["Wyvern Poison"] = "Injury poison: DC 14 Constitution save against 7d6 poison damage, half on a success.",
    -- Light
    ["Candle"] = "Burns for an hour: bright light 5 feet around, dim light 5 feet beyond.",
    ["Torch"] = "Burns for an hour: bright light 20 feet around, dim light 20 feet beyond. Can be swung as a simple melee weapon for 1 fire damage.",
    ["Lamp"] = "Burns oil: bright light 15 feet around, dim light 30 feet beyond.",
    ["Hooded Lantern"] = "Burns oil: bright light 30 feet around, dim light 30 feet beyond. Lowering the hood (a bonus action) dims it to 5 feet.",
    ["Bullseye Lantern"] = "Burns oil: bright light in a 60-foot cone, dim light 60 feet beyond.",
    ["Tinderbox"] = "Flint, steel and tinder. Lighting a candle, lamp, lantern or torch takes a bonus action; any other fire takes a minute.",
    -- Climbing, binding, breaking
    ["Rope"] = "Fifty feet of rope. Tying a knot is a DC 10 Sleight of Hand check, bursting it a DC 20 Athletics check; it can bind a grappled, incapacitated or restrained creature.",
    ["Chain"] = "Wraps a grappled, incapacitated or restrained creature next to you with a DC 13 Athletics check; bound legs keep it Restrained until it escapes.",
    ["Manacles"] = "Bind a grappled, incapacitated or restrained Small or Medium creature next to you with a DC 13 Sleight of Hand check: it attacks with disadvantage while bound.",
    ["Grappling Hook"] = "Throw it at a ledge or railing within 50 feet; a DC 13 Acrobatics check catches it, and a rope tied to it can then be climbed.",
    ["Climber's Kit"] = "Boot tips, gloves, pitons and a harness. Anchored, you can't fall or move more than 25 feet from the anchor.",
    ["Crowbar"] = "Advantage on Strength checks where its leverage helps.",
    ["Portable Ram"] = "+4 to the Strength check to break down a door; one helper gives advantage.",
    ["Block and Tackle"] = "Pulleys that let you hoist four times what you could lift.",
    ["Iron Spike"] = "Hammered into wood or earth to jam a door or tie a rope or chain to.",
    ["Iron Spikes"] = "A bundle of ten. Hammered into wood or earth to jam a door or tie a rope or chain to.",
    ["Hunting Trap"] = "A steel trap set on the ground and chained in place: a creature that steps on it makes a Dexterity save or is caught and hurt.",
    ["Lock"] = "Comes with its key. Picking it takes thieves' tools and a DC 15 Sleight of Hand check.",
    ["Pole"] = "Ten feet long: reaches things 10 feet away, and gives advantage on the Athletics check of a jump used to vault.",
    ["Ladder"] = "Ten feet tall; you climb to go up or down it.",
    ["Shovel"] = "An hour of work digs a hole 5 feet on each side in soft ground.",
    -- Containers
    ["Backpack"] = "Holds 30 pounds in a cubic foot; works as a saddlebag too.",
    ["Barrel"] = "Holds 40 gallons of liquid or 4 cubic feet of dry goods.",
    ["Basket"] = "Holds 40 pounds in 2 cubic feet.",
    ["Bucket"] = "Holds half a cubic foot.",
    ["Chest"] = "Holds 12 cubic feet.",
    ["Crossbow Bolt Case"] = "Holds 20 bolts.",
    ["Flask"] = "Holds a pint.",
    ["Glass Bottle"] = "Holds a pint and a half.",
    ["Iron Pot"] = "Holds a gallon.",
    ["Jug"] = "Holds a gallon.",
    ["Map or Scroll Case"] = "Holds 10 sheets of paper or 5 of parchment.",
    ["Pouch"] = "Holds 6 pounds in a fifth of a cubic foot.",
    ["Quiver"] = "Holds 20 arrows.",
    ["Sack"] = "Holds 30 pounds in a cubic foot.",
    ["Vial"] = "Holds 4 ounces.",
    ["Waterskin"] = "Holds 4 pints of water.",
    ["Component Pouch"] = "A watertight pouch with a place for every material component of your spells that has no price: carrying it, you don't need those components.",
    -- Camp and travel
    ["Bedroll"] = "Sleeps one Small or Medium creature; inside it you automatically pass saves against extreme cold.",
    ["Blanket"] = "Wrapped in it, you have advantage on saves against extreme cold.",
    ["Tent"] = "Sleeps two Small or Medium creatures.",
    ["Rations"] = "A day of travel food: jerky, dried fruit, hardtack and nuts.",
    ["Ale (mug)"] = "A mug of ale.",
    ["Bread (loaf)"] = "A loaf of bread.",
    ["Cheese (wedge)"] = "A wedge of cheese.",
    ["Common Wine (bottle)"] = "A bottle of everyday wine.",
    ["Fine Wine (bottle)"] = "A bottle of good wine.",
    ["Feed"] = "A day's feed for a mount or a draft animal.",
    ["Fuel"] = "Runs a powered vehicle for 8 hours of travel; alchemists can make it.",
    -- Writing, reading, finding
    ["Book"] = "Fiction or nonfiction. An accurate book on its subject gives +5 to Arcana, History, Nature or Religion checks about it.",
    ["Map"] = "An accurate map gives +5 to Survival checks to find your way in the place it shows.",
    ["Ink"] = "A one-ounce bottle: enough for about 500 pages.",
    ["Ink Pen"] = "For writing or drawing with ink.",
    ["Paper"] = "A sheet that takes about 250 handwritten words.",
    ["Parchment"] = "A sheet that takes about 250 handwritten words.",
    ["Spellbook"] = "A leather-bound book of blank pages for recording spells.",
    ["Magnifying Glass"] = "Advantage on checks to appraise or inspect a finely detailed object; in bright sunlight it can start a fire in about 5 minutes.",
    ["Spyglass"] = "Shows things at twice their size.",
    ["Mirror"] = "A small steel mirror: for grooming, looking around corners or flashing a signal.",
    ["Bell"] = "Rung, it is heard up to 60 feet away.",
    ["Signal Whistle"] = "Blown, it is heard up to 600 feet away.",
    ["String"] = "Ten feet of string.",
    -- Clothes
    ["Costume"] = "Advantage on checks to pass yourself off as the person or kind of person it shows.",
    ["Fine Clothes"] = "Costly, well-made clothes; some places only let in people who wear them.",
    ["Robe"] = "Clothing of a calling or a ceremony; some places only let in people who wear its colors or signs.",
    ["Traveler's Clothes"] = "Hard-wearing clothes made for the road.",
    ["Perfume"] = "For an hour after putting it on, advantage on Persuasion checks to sway an Indifferent humanoid within 5 feet.",
    -- Riding
    ["Riding Saddle"] = "A saddle with bit, bridle and reins.",
    ["Military Saddle"] = "A saddle with bit, bridle and reins; advantage on checks to stay mounted.",
    ["Exotic Saddle"] = "A saddle with bit, bridle and reins, needed to ride a flying or swimming mount.",
    -- Ammunition
    ["Arrow"] = "One arrow, for a bow.",
    ["Bolt"] = "One bolt, for a crossbow.",
    ["Arrows (20)"] = "Twenty arrows, for a bow.",
    ["Bolts (20)"] = "Twenty bolts, for a crossbow.",
    ["Needle"] = "One needle, for a blowgun.",
    ["Needles (50)"] = "Fifty needles, for a blowgun.",
    ["Firearm Bullet"] = "One bullet, for a pistol or musket; used up when fired.",
    ["Firearm Bullets (10)"] = "Ten bullets, for a pistol or musket; used up when fired.",
    ["Sling Bullets (20)"] = "Twenty bullets, for a sling.",
}

-- Packs: what is in them.
local PACKS = {
    ["Burglar's Pack"] = "Backpack, ball bearings, bell, 10 candles, crowbar, hooded lantern, 7 flasks of oil, 5 days of rations, rope, tinderbox and waterskin.",
    ["Diplomat's Pack"] = "Chest, fine clothes, ink, 5 ink pens, lamp, 2 map or scroll cases, 4 flasks of oil, 5 sheets of paper, 5 of parchment, perfume and tinderbox.",
    ["Dungeoneer's Pack"] = "Backpack, caltrops, crowbar, 2 flasks of oil, 10 days of rations, rope, tinderbox, 10 torches and waterskin.",
    ["Entertainer's Pack"] = "Backpack, bedroll, bell, bullseye lantern, 3 costumes, mirror, 8 flasks of oil, 9 days of rations, tinderbox and waterskin.",
    ["Explorer's Pack"] = "Backpack, bedroll, 2 flasks of oil, 10 days of rations, rope, tinderbox, 10 torches and waterskin.",
    ["Priest's Pack"] = "Backpack, blanket, holy water, lamp, 7 days of rations, robe and tinderbox.",
    ["Scholar's Pack"] = "Backpack, book, ink, ink pen, lamp, 10 flasks of oil, 10 sheets of parchment and tinderbox.",
}
for name, contents in pairs(PACKS) do NOTES[name] = "Bought and carried as one item: " .. contents end

-- Spellcasting focuses, by the kind of caster that uses them.
for _, name in ipairs({ "Crystal", "Orb", "Rod", "Staff", "Wand" }) do
    NOTES[name] = "An arcane focus: a spellcaster whose class uses one casts through it in place of material components that have no price."
end
for _, name in ipairs({ "Sprig of Mistletoe", "Wooden Staff", "Yew Wand" }) do
    NOTES[name] = "A druidic focus: a spellcaster whose class uses one casts through it in place of material components that have no price."
end
NOTES["Amulet"] = "A holy symbol, to be worn or held: a spellcaster whose class uses one casts through it in place of material components that have no price."
NOTES["Emblem"] = "A holy symbol, to be borne on a tabard, banner or shield: a spellcaster whose class uses one casts through it in place of material components that have no price."
NOTES["Reliquary"] = "A holy symbol, to be held: a spellcaster whose class uses one casts through it in place of material components that have no price."

-- Tools: the ability a check uses, what it is good for and what it makes.
local TOOLS = {
    ["Alchemist's Supplies"] = { "Intelligence", "identify a substance or start a fire (DC 15)", "acid, alchemist's fire, component pouch, oil, paper, perfume" },
    ["Brewer's Supplies"] = { "Intelligence", "find poison in a drink (DC 15) or name a drink (DC 10)", "antitoxin" },
    ["Calligrapher's Supplies"] = { "Dexterity", "write with flourishes that are hard to forge (DC 15)", "ink, spell scrolls" },
    ["Carpenter's Tools"] = { "Strength", "seal or pry open a door or container (DC 20)", "clubs, greatclubs, quarterstaffs, barrels, chests, ladders, poles, portable rams, torches" },
    ["Cartographer's Tools"] = { "Wisdom", "draft a map of a small area (DC 15)", "maps" },
    ["Cobbler's Tools"] = { "Dexterity", "fix up footwear for advantage on the wearer's next Acrobatics check (DC 10)", "climber's kits" },
    ["Cook's Utensils"] = { "Wisdom", "make food taste better (DC 10) or find spoiled or poisoned food (DC 15)", "rations" },
    ["Disguise Kit"] = { "Charisma", "apply makeup (DC 10)", "costumes" },
    ["Forgery Kit"] = { "Dexterity", "copy a few words of someone's handwriting (DC 15) or a wax seal (DC 20)" },
    ["Glassblower's Tools"] = { "Intelligence", "tell what a glass object held in the last day (DC 15)", "bottles, magnifying glasses, spyglasses, vials" },
    ["Herbalism Kit"] = { "Intelligence", "identify a plant (DC 10)", "antitoxin, candles, healer's kits, potions of healing" },
    ["Jeweler's Tools"] = { "Intelligence", "tell what a gem is worth (DC 15)", "arcane focuses, holy symbols" },
    ["Leatherworker's Tools"] = { "Dexterity", "decorate a leather item (DC 10)", "slings, whips, hide, leather and studded leather armor, backpacks, cases, parchment, pouches, quivers, waterskins" },
    ["Mason's Tools"] = { "Strength", "chisel a sign or a hole in stone (DC 10)", "blocks and tackles" },
    ["Navigator's Tools"] = { "Wisdom", "plot a course (DC 10) or find your position by the stars (DC 15)" },
    ["Painter's Supplies"] = { "Wisdom", "paint a recognizable picture of something you have seen (DC 10)", "druidic focuses, holy symbols" },
    ["Poisoner's Kit"] = { "Intelligence", "find poison on an object (DC 10)", "basic poison" },
    ["Potter's Tools"] = { "Intelligence", "tell what a ceramic object held in the last day (DC 15)", "jugs, lamps" },
    ["Smith's Tools"] = { "Strength", "pry open a door or container (DC 20)", "most melee weapons, medium and heavy armor, ball bearings, buckets, caltrops and more" },
    ["Thieves' Tools"] = { "Dexterity", "pick a lock or disarm a trap (DC 15)" },
    ["Tinker's Tools"] = { "Dexterity", "put together a tiny gadget from scrap that falls apart in a minute (DC 20)", "firearms, bells, lanterns, flasks, hunting traps, locks, manacles, mirrors and more" },
    ["Weaver's Tools"] = { "Dexterity", "mend a tear or sew a small design (DC 10)", "padded armor, baskets, bedrolls, blankets, clothes, nets, robes, rope, sacks, string, tents" },
    ["Woodcarver's Tools"] = { "Dexterity", "carve a pattern in wood (DC 10)", "clubs, greatclubs, quarterstaffs, bows and crossbows, arcane and druidic focuses, arrows, bolts, ink pens, needles" },
}
for _, name in ipairs({ "Dice Set", "Dragonchess Set", "Playing Cards", "Three-Dragon Ante Set" }) do
    TOOLS[name] = { "Wisdom", "spot a cheat (DC 10) or win the game (DC 20)" }
end
for _, name in ipairs({ "Bagpipes", "Drum", "Dulcimer", "Flute", "Horn", "Lute", "Lyre", "Pan Flute", "Shawm", "Viol" }) do
    TOOLS[name] = { "Charisma", "play a tune you know (DC 10) or make one up (DC 15)" }
end
for name, tool in pairs(TOOLS) do
    NOTES[name] = ("Checks with it use %s: %s.%s"):format(tool[1], tool[2], tool[3] and (" Makes " .. tool[3] .. ".") or "")
end

for name, note in pairs(NOTES) do
    local item = R.ITEMS[name]
    if item and (item.desc or "") == "" then item.desc = note end
end
