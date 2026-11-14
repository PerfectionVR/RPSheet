-- Common cantrips and 1st-level spells from the core rules, ready to add to a character's spell list
-- (see Options/Spells.lua), with short summaries in our own words. This is a starting
-- set, not every spell: anything else is entered by hand.
--
-- Each entry has the fields of Rules.TEMPLATES.spell. R.SPELL_LISTS names the spells
-- each Player's Handbook class can pick from here.
local _, ns = ...
local R = ns.Rules

R.SPELLS = {}

-- how: "ATTACK" (spell attack), a saving throw ability such as "DEX", or nil for no roll.
-- dice: { count, sides } or nil. extra: other template fields.
function R.DefineSpell(name, level, how, dice, desc, extra)
    local spell = CopyTable(R.TEMPLATES.spell)
    spell.name, spell.level, spell.desc = name, level, desc
    if how == "ATTACK" then
        spell.kind = "ATTACK"
    elseif how then
        spell.kind, spell.save = "SAVE", how
    end
    if dice then spell.count, spell.sides = dice[1], dice[2] end
    -- A cantrip's dice grow at character levels 5, 11 and 17.
    if level == 0 and dice then spell.scales = true end
    for key, value in pairs(extra or {}) do spell[key] = value end
    R.SPELLS[name] = spell
end
local Spell = R.DefineSpell

local HEAL = { dice = "HEALING", addMod = true }
local CONC = { concentration = true }

-- Cantrips
Spell("Acid Splash", 0, "DEX", { 1, 6 }, "Creatures in a 5-foot sphere within 60 feet take acid damage unless they pass the save.")
Spell("Blade Ward", 0, nil, nil, "Reaction when a creature you can see attacks you: it subtracts 1d4 from the attack roll.")
Spell("Chill Touch", 0, "ATTACK", { 1, 10 }, "Melee spell attack. Necrotic damage, and the target can't regain hit points until the end of your next turn.")
Spell("Dancing Lights", 0, nil, nil, "Four floating lights within 120 feet that you can move as a bonus action.", CONC)
Spell("Druidcraft", 0, nil, nil, "A small nature effect: predict the weather, make a flower bloom, a harmless sensory effect, or light or snuff a small flame.")
Spell("Eldritch Blast", 0, "ATTACK", { 1, 10 }, "A beam of force at a creature within 120 feet. You fire more beams at higher levels, each with its own attack roll: click once per beam.", { scales = false })
Spell("Elementalism", 0, nil, nil, "A minor effect of air, earth, fire or water within 30 feet.")
Spell("Fire Bolt", 0, "ATTACK", { 1, 10 }, "A mote of fire at a creature or object within 120 feet.")
Spell("Friends", 0, "WIS", nil, "A creature within 10 feet that fails the save is charmed by you for up to a minute, and knows it afterwards.", CONC)
Spell("Guidance", 0, nil, nil, "Touch a willing creature: it adds 1d4 to checks with one skill you choose, for up to a minute.", CONC)
Spell("Light", 0, nil, nil, "An object you touch sheds bright light in a 20-foot radius for an hour.")
Spell("Mage Hand", 0, nil, nil, "A spectral hand within 30 feet that can carry up to 10 pounds and handle objects.")
Spell("Mending", 0, nil, nil, "Repair a single break or tear in an object you touch.")
Spell("Message", 0, nil, nil, "Whisper to a creature within 120 feet; only it hears you and it can whisper back.")
Spell("Mind Sliver", 0, "INT", { 1, 6 }, "Psychic damage to a creature within 60 feet, and it subtracts 1d4 from its next saving throw.")
Spell("Minor Illusion", 0, nil, nil, "A sound or a small image within 30 feet that lasts a minute.")
Spell("Poison Spray", 0, "ATTACK", { 1, 12 }, "A puff of toxic mist at a creature within 30 feet.")
Spell("Prestidigitation", 0, nil, nil, "A minor trick: a harmless sensory effect, clean or soil an object, warm or chill food, light a candle.")
Spell("Produce Flame", 0, "ATTACK", { 1, 8 }, "A flame in your hand that gives light, and that you can hurl at a creature within 60 feet.")
Spell("Ray of Frost", 0, "ATTACK", { 1, 8 }, "Cold damage to a creature within 60 feet, and its speed drops by 10 feet until your next turn.")
Spell("Resistance", 0, nil, nil, "Touch a willing creature: once per turn it reduces damage of one type you choose by 1d4, for up to a minute.", CONC)
Spell("Sacred Flame", 0, "DEX", { 1, 8 }, "Radiant damage to a creature within 60 feet; cover doesn't help it.")
Spell("Shillelagh", 0, nil, nil, "Your club or quarterstaff uses your spellcasting ability for attacks and deals more damage for a minute.")
Spell("Shocking Grasp", 0, "ATTACK", { 1, 8 }, "Melee spell attack. Lightning damage, and the target can't make opportunity attacks until its next turn.")
Spell("Sorcerous Burst", 0, "ATTACK", { 1, 8 }, "Elemental damage of a type you choose at a creature within 120 feet. An 8 on a die adds another die.")
Spell("Spare the Dying", 0, nil, nil, "A creature at 0 HP within 15 feet becomes stable.")
Spell("Starry Wisp", 0, "ATTACK", { 1, 8 }, "Radiant damage to a creature or object within 60 feet, which glows and can't be invisible until your next turn.")
Spell("Thaumaturgy", 0, nil, nil, "A minor wonder: a booming voice, flickering flames, tremors, or a brief sound.")
Spell("Thorn Whip", 0, "ATTACK", { 1, 6 }, "Melee spell attack with 30-foot reach. Piercing damage, and you can pull the target up to 10 feet closer.")
Spell("Thunderclap", 0, "CON", { 1, 6 }, "Each creature within 5 feet of you takes thunder damage unless it passes the save.")
Spell("Toll the Dead", 0, "WIS", { 1, 8 }, "Necrotic damage to a creature within 60 feet. Use d12s if it is already missing hit points.")
Spell("True Strike", 0, nil, nil, "Make one weapon attack using your spellcasting ability; it can deal radiant damage, and deals extra at higher levels.")
Spell("Word of Radiance", 0, "CON", { 1, 6 }, "Each creature of your choice within 5 feet takes radiant damage unless it passes the save.")

-- 1st level
Spell("Armor of Agathys", 1, nil, nil, "You gain 5 temporary HP for an hour. While you have them, a creature that hits you in melee takes 5 cold damage.")
Spell("Arms of Hadar", 1, "STR", { 2, 6 }, "Each creature within 10 feet of you takes necrotic damage and can't take reactions; half damage only on a success.")
Spell("Bane", 1, "CHA", nil, "Up to three creatures within 30 feet that fail subtract 1d4 from attack rolls and saves for a minute.", CONC)
Spell("Bless", 1, nil, nil, "Up to three creatures within 30 feet add 1d4 to attack rolls and saves for a minute.", CONC)
Spell("Burning Hands", 1, "DEX", { 3, 6 }, "Fire damage to each creature in a 15-foot cone; half on a success.")
Spell("Charm Person", 1, "WIS", nil, "A humanoid within 30 feet that fails is charmed by you for an hour, and knows it afterwards.")
Spell("Chromatic Orb", 1, "ATTACK", { 3, 8 }, "An orb of a damage type you choose at a creature within 90 feet. Matching dice let it leap to another target.")
Spell("Command", 1, "WIS", nil, "A one-word order to a creature within 60 feet, which it follows on its next turn if it fails.")
Spell("Compelled Duel", 1, "WIS", nil, "A creature within 30 feet that fails has disadvantage attacking anyone but you and struggles to move away.", CONC)
Spell("Cure Wounds", 1, nil, { 2, 8 }, "A creature you touch regains hit points.", HEAL)
Spell("Detect Magic", 1, nil, nil, "For 10 minutes you sense magic within 30 feet and can see its aura and school.", CONC)
Spell("Dissonant Whispers", 1, "WIS", { 3, 6 }, "Psychic damage to a creature within 60 feet, which must use its reaction to move away; half and no movement on a success.")
Spell("Divine Favor", 1, nil, { 1, 4 }, "For a minute your weapon hits deal extra radiant damage. Click for the extra dice on each hit.")
Spell("Ensnaring Strike", 1, "STR", { 1, 6 }, "When you hit with a weapon: the target is restrained by vines if it fails, taking piercing damage each turn.", CONC)
Spell("Entangle", 1, "STR", nil, "Plants fill a 20-foot square within 90 feet. Creatures there that fail are restrained.", CONC)
Spell("Faerie Fire", 1, "DEX", nil, "Creatures in a 20-foot cube that fail are outlined: attacks against them have advantage and they can't be invisible.", CONC)
Spell("Feather Fall", 1, nil, nil, "Reaction: up to five falling creatures within 60 feet descend slowly and land unharmed.")
Spell("Find Familiar", 1, nil, nil, "Summon a spirit in animal form that serves as your familiar.")
Spell("Fog Cloud", 1, nil, nil, "A 20-foot sphere of fog within 120 feet, heavily obscured, for up to an hour.", CONC)
Spell("Goodberry", 1, nil, nil, "Ten berries appear. Eating one restores 1 hit point and feeds a creature for a day.")
Spell("Guiding Bolt", 1, "ATTACK", { 4, 6 }, "Radiant damage to a creature within 120 feet, and the next attack against it has advantage.")
Spell("Hail of Thorns", 1, "DEX", { 1, 10 }, "When you hit with a ranged weapon: the target and creatures within 5 feet take piercing damage; half on a success.")
Spell("Healing Word", 1, nil, { 2, 4 }, "Bonus action. A creature within 60 feet regains hit points.", HEAL)
Spell("Hellish Rebuke", 1, "DEX", { 2, 10 }, "Reaction when a creature within 60 feet damages you: it takes fire damage; half on a success.")
Spell("Heroism", 1, nil, nil, "A creature you touch can't be frightened and gains temporary HP equal to your spellcasting modifier each turn.", CONC)
Spell("Hex", 1, nil, { 1, 6 }, "Curse a creature within 90 feet: your hits deal extra necrotic damage and it has disadvantage on checks with one ability. Click for the extra dice on each hit.", CONC)
Spell("Hunter's Mark", 1, nil, { 1, 6 }, "Mark a creature within 90 feet: your hits deal extra force damage, and you track it more easily. Click for the extra dice on each hit.", CONC)
Spell("Ice Knife", 1, "ATTACK", { 1, 10 }, "A shard of ice at a creature within 60 feet. Hit or miss it bursts: creatures within 5 feet take 2d6 cold damage unless they pass a Dexterity save.")
Spell("Inflict Wounds", 1, "CON", { 2, 10 }, "Necrotic damage to a creature you touch; half on a success.")
Spell("Jump", 1, nil, nil, "A creature you touch can jump up to 30 feet once per turn, for a minute.")
Spell("Longstrider", 1, nil, nil, "A creature you touch gains 10 feet of speed for an hour.")
Spell("Mage Armor", 1, nil, nil, "A willing creature without armor has an AC of 13 + its Dexterity modifier for 8 hours.")
Spell("Magic Missile", 1, nil, { 3, 4 }, "Three darts that always hit, each dealing 1d4 + 1 force damage to a creature within 120 feet. Add 3 to the total rolled.")
Spell("Protection from Evil and Good", 1, nil, nil, "A creature you touch is protected against aberrations, celestials, elementals, fey, fiends and undead.", CONC)
Spell("Ray of Sickness", 1, "ATTACK", { 2, 8 }, "Poison damage to a creature within 60 feet, and it is poisoned until the end of your next turn.")
Spell("Sanctuary", 1, nil, nil, "Creatures must pass a Wisdom save to attack the creature you ward, until it attacks or casts on an enemy.")
Spell("Searing Smite", 1, nil, { 1, 6 }, "After a weapon hit: extra fire damage, and the target burns each turn until it passes a Constitution save.")
Spell("Shield", 1, nil, nil, "Reaction when you are hit: +5 AC until your next turn, including against that attack, and Magic Missile can't hurt you.")
Spell("Shield of Faith", 1, nil, nil, "A creature within 60 feet gains +2 AC for up to 10 minutes.", CONC)
Spell("Sleep", 1, "WIS", nil, "Creatures in a 5-foot sphere within 60 feet that fail grow drowsy, and fall asleep if they fail again.", CONC)
Spell("Speak with Animals", 1, nil, nil, "For 10 minutes you can understand and speak with beasts.")
Spell("Tasha's Hideous Laughter", 1, "WIS", nil, "A creature within 30 feet that fails falls prone laughing and can't act, repeating the save each turn.", CONC)
Spell("Thunderous Smite", 1, nil, { 2, 6 }, "After a weapon hit: extra thunder damage, and the target is pushed 10 feet and knocked prone unless it passes a Strength save.")
Spell("Thunderwave", 1, "CON", { 2, 8 }, "Thunder damage to each creature in a 15-foot cube from you, pushing it 10 feet; half and no push on a success.")
Spell("Witch Bolt", 1, "ATTACK", { 2, 12 }, "Lightning damage to a creature within 60 feet. On later turns a bonus action deals 1d12 more while you concentrate.", CONC)
Spell("Wrathful Smite", 1, nil, { 1, 6 }, "After a weapon hit: extra necrotic damage, and the target is frightened of you if it fails a Wisdom save.")

-- Cantrips known as { {level, cantrips}, ... } and spells prepared at each level,
-- by Player's Handbook class.
R.CANTRIPS_KNOWN = {
    Cleric = { { 1, 3 }, { 4, 4 }, { 10, 5 } },
    Druid = { { 1, 2 }, { 4, 3 }, { 10, 4 } },
    Sorcerer = { { 1, 4 }, { 4, 5 }, { 10, 6 } },
    Warlock = { { 1, 2 }, { 4, 3 }, { 10, 4 } },
    Wizard = { { 1, 3 }, { 4, 4 }, { 10, 5 } },
}
R.SPELLS_PREPARED = {
    Cleric = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22 },
    Druid = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22 },
    Paladin = { 2, 3, 4, 5, 6, 6, 7, 7, 9, 9, 10, 10, 11, 11, 12, 12, 14, 14, 15, 15 },
    Ranger = { 2, 3, 4, 5, 6, 6, 7, 7, 9, 9, 10, 10, 11, 11, 12, 12, 14, 14, 15, 15 },
    Sorcerer = { 2, 4, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22 },
    Warlock = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15 },
    Wizard = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 18, 19, 21, 22, 23, 24, 25 },
}

R.SPELL_LISTS = {
    Cleric = {
        "Guidance", "Light", "Mending", "Resistance", "Sacred Flame", "Spare the Dying", "Thaumaturgy", "Toll the Dead", "Word of Radiance",
        "Bane", "Bless", "Command", "Cure Wounds", "Detect Magic", "Guiding Bolt", "Healing Word", "Inflict Wounds",
        "Protection from Evil and Good", "Sanctuary", "Shield of Faith",
    },
    Druid = {
        "Druidcraft", "Elementalism", "Guidance", "Mending", "Message", "Poison Spray", "Produce Flame", "Resistance", "Shillelagh",
        "Spare the Dying", "Starry Wisp", "Thorn Whip", "Thunderclap",
        "Charm Person", "Cure Wounds", "Detect Magic", "Entangle", "Faerie Fire", "Fog Cloud", "Goodberry", "Healing Word", "Ice Knife",
        "Jump", "Longstrider", "Speak with Animals", "Thunderwave",
    },
    Paladin = {
        "Bless", "Command", "Compelled Duel", "Cure Wounds", "Detect Magic", "Divine Favor", "Heroism",
        "Protection from Evil and Good", "Searing Smite", "Shield of Faith", "Thunderous Smite", "Wrathful Smite",
    },
    Ranger = {
        "Cure Wounds", "Detect Magic", "Ensnaring Strike", "Entangle", "Fog Cloud", "Goodberry", "Hail of Thorns", "Hunter's Mark",
        "Jump", "Longstrider", "Speak with Animals",
    },
    Sorcerer = {
        "Acid Splash", "Blade Ward", "Chill Touch", "Dancing Lights", "Elementalism", "Fire Bolt", "Friends", "Light", "Mage Hand",
        "Mending", "Message", "Minor Illusion", "Poison Spray", "Prestidigitation", "Ray of Frost", "Shocking Grasp", "Sorcerous Burst",
        "Thunderclap", "True Strike",
        "Burning Hands", "Charm Person", "Chromatic Orb", "Detect Magic", "Feather Fall", "Fog Cloud", "Ice Knife", "Jump", "Mage Armor",
        "Magic Missile", "Ray of Sickness", "Shield", "Sleep", "Thunderwave", "Witch Bolt",
    },
    Warlock = {
        "Blade Ward", "Chill Touch", "Eldritch Blast", "Friends", "Mage Hand", "Mind Sliver", "Minor Illusion", "Poison Spray",
        "Prestidigitation", "Thunderclap", "Toll the Dead", "True Strike",
        "Armor of Agathys", "Arms of Hadar", "Bane", "Charm Person", "Command", "Detect Magic", "Dissonant Whispers", "Hellish Rebuke",
        "Hex", "Protection from Evil and Good", "Speak with Animals", "Tasha's Hideous Laughter", "Witch Bolt",
    },
    Wizard = {
        "Acid Splash", "Blade Ward", "Chill Touch", "Dancing Lights", "Elementalism", "Fire Bolt", "Friends", "Light", "Mage Hand",
        "Mending", "Message", "Mind Sliver", "Minor Illusion", "Poison Spray", "Prestidigitation", "Ray of Frost", "Shocking Grasp",
        "Thunderclap", "Toll the Dead", "True Strike",
        "Burning Hands", "Charm Person", "Chromatic Orb", "Detect Magic", "Feather Fall", "Find Familiar", "Fog Cloud", "Ice Knife", "Jump",
        "Longstrider", "Mage Armor", "Magic Missile", "Ray of Sickness", "Shield", "Sleep", "Tasha's Hideous Laughter", "Thunderwave",
        "Witch Bolt",
    },
}
