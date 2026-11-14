-- Feats a character can take when levelling (see Options/LevelDialog.lua), with short
-- summaries in our own words. A feat not listed here can still be typed in by name.
--   kind     "GENERAL" (from level 4), "ORIGIN" (also allowed there) or "BOON" (level 19)
--   stats    abilities the feat can raise by 1; none for origin feats
--   effects  passive effects the feat has by itself (see Data/Effects.lua)
--   repeatable  true if it can be taken more than once
--   save     true if it also grants saving throw proficiency in the raised ability
local _, ns = ...
local R = ns.Rules

local ANY = R.STATS
local MIND = { "INT", "WIS", "CHA" }
local BODY = { "STR", "DEX" }

local function General(name, stats, desc, extra)
    local feat = { name = name, kind = "GENERAL", stats = stats, desc = desc }
    for key, value in pairs(extra or {}) do feat[key] = value end
    return feat
end
local function Origin(name, desc, effects)
    return { name = name, kind = "ORIGIN", stats = {}, desc = desc, effects = effects, repeatable = name == "Magic Initiate" or name == "Skilled" }
end
local function Boon(name, desc, extra)
    local feat = { name = "Boon of " .. name, kind = "BOON", stats = ANY, desc = desc }
    for key, value in pairs(extra or {}) do feat[key] = value end
    return feat
end
local function Effect(target, flat, stat, times)
    return { target = target, flat = flat or 0, stat = stat or "", times = times or 1 }
end

local LIST = {
    General("Actor", { "CHA" }, "Advantage on Deception and Performance checks while pretending to be someone else, and you can mimic voices and sounds you have heard."),
    General("Athlete", BODY, "You gain a climbing speed, stand up from prone with 5 feet of movement, and need only a 5-foot run-up to jump."),
    General("Charger", BODY, "Dashing adds 10 feet to your speed. Once per turn, after moving 10 feet straight at a target, a hit deals 1d8 extra damage or pushes it 10 feet."),
    General("Chef", { "CON", "WIS" }, "On a short rest your cooking heals 1d8 extra to those who spend Hit Dice. After a long rest you make treats that give temporary HP equal to your proficiency bonus."),
    General("Crossbow Expert", { "DEX" }, "You ignore the loading property of crossbows, being next to an enemy doesn't hinder your shots, and you add your modifier to the damage of an extra light-crossbow attack."),
    General("Crusher", { "STR", "CON" }, "Once per turn a bludgeoning hit can move the target 5 feet. A bludgeoning critical hit gives attacks against that target advantage until your next turn."),
    General("Defensive Duelist", { "DEX" }, "Reaction when hit by a melee attack while holding a finesse weapon: add your proficiency bonus to your AC against melee attacks until your next turn."),
    General("Dual Wielder", BODY, "When you attack with a light weapon you can make the extra bonus-action attack with a different weapon that isn't two-handed, and you can draw or stow two weapons at once."),
    General("Durable", { "CON" }, "Advantage on death saving throws, and as a bonus action you can spend one Hit Die to heal."),
    General("Elemental Adept", MIND, "Choose acid, cold, fire, lightning or thunder. Your spells ignore resistance to it, and you treat any 1 on its damage dice as a 2. Can be taken again for another damage type.", { repeatable = true }),
    General("Fey Touched", MIND, "You learn Misty Step and one 1st-level divination or enchantment spell. Each can be cast once per long rest without a slot, and with your slots."),
    General("Grappler", BODY, "Once per turn an unarmed strike can both damage and grapple. You have advantage on attacks against a creature you grapple, and moving it doesn't slow you."),
    General("Great Weapon Master", { "STR" }, "A hit with a heavy weapon as part of the Attack action deals extra damage equal to your proficiency bonus. After a critical hit or a kill you can attack as a bonus action."),
    General("Heavily Armored", { "STR", "CON" }, "You gain training with heavy armor."),
    General("Heavy Armor Master", { "STR", "CON" }, "In heavy armor, bludgeoning, piercing and slashing damage you take is reduced by your proficiency bonus."),
    General("Inspiring Leader", { "WIS", "CHA" }, "After a rest, a rousing performance gives up to six allies temporary HP equal to your level plus the raised ability's modifier."),
    General("Keen Mind", { "INT" }, "Proficiency, or expertise if you have it already, in one of Arcana, History, Investigation, Nature or Religion. You can take the Study action as a bonus action."),
    General("Lightly Armored", BODY, "You gain training with light armor and shields."),
    General("Mage Slayer", BODY, "Creatures you damage have disadvantage on the save to keep concentrating. Once per rest you can turn a failed Intelligence, Wisdom or Charisma save into a success."),
    General("Martial Weapon Training", BODY, "You gain proficiency with martial weapons."),
    General("Medium Armor Master", BODY, "In medium armor you can add up to 3, rather than 2, from Dexterity to your AC."),
    General("Moderately Armored", BODY, "You gain training with medium armor."),
    General("Mounted Combatant", { "STR", "DEX", "WIS" }, "Advantage on attacks against unmounted creatures smaller than your mount, and you can protect your mount from attacks and area effects."),
    General("Observant", { "INT", "WIS" }, "Proficiency, or expertise if you have it already, in one of Insight, Investigation or Perception. You can take the Search action as a bonus action."),
    General("Piercer", BODY, "Once per turn reroll one damage die of a piercing hit. A piercing critical hit rolls one more damage die."),
    General("Poisoner", { "DEX", "INT" }, "Your poison ignores resistance. With a poisoner's kit you brew doses that add 2d8 poison damage and poison the target on a failed Constitution save."),
    General("Polearm Master", BODY, "Bonus action: strike with the butt of a quarterstaff, spear or reach weapon for a d4. Reaction: attack a creature that enters your reach."),
    General("Resilient", ANY, "You gain proficiency in saving throws with the ability this feat raises.", { save = true }),
    General("Ritual Caster", MIND, "You always have a few 1st-level ritual spells prepared, and once per long rest you can cast a ritual at its normal casting time."),
    General("Sentinel", BODY, "You can make an opportunity attack when a nearby creature disengages or attacks someone else. A creature you hit with one has its speed reduced to 0."),
    General("Shadow Touched", MIND, "You learn Invisibility and one 1st-level illusion or necromancy spell. Each can be cast once per long rest without a slot, and with your slots."),
    General("Shield Master", { "STR" }, "After a melee hit you can bash with your shield to push the target 5 feet or knock it prone. Reaction: take no damage from a Dexterity save you passed."),
    General("Skill Expert", ANY, "Proficiency in one skill, and expertise in one skill you are proficient in."),
    General("Skulker", { "DEX" }, "Blindsight out to 10 feet, advantage on Stealth checks to hide during combat, and missing an attack doesn't reveal where you are."),
    General("Slasher", BODY, "Once per turn a slashing hit reduces the target's speed by 10 feet. A slashing critical hit gives the target disadvantage on attacks until your next turn."),
    General("Speedy", { "DEX", "CON" }, "Your speed increases by 10 feet, Dash ignores difficult terrain, and opportunity attacks against you have disadvantage.", { effects = { Effect("SPEED", 10) } }),
    General("Spell Sniper", MIND, "Your spell attacks ignore half and three-quarters cover, being next to an enemy doesn't hinder them, and their range grows by 60 feet."),
    General("Telekinetic", MIND, "You know Mage Hand and can cast it unseen and at longer range. Bonus action: shove a creature within 30 feet 5 feet unless it passes a Strength save."),
    General("Telepathic", MIND, "You can speak mind to mind with a creature within 60 feet, and cast Detect Thoughts once per long rest without a slot."),
    General("War Caster", MIND, "Advantage on saves to keep concentrating, you can cast with weapons or a shield in hand, and you can cast a spell as an opportunity attack."),
    General("Weapon Master", BODY, "You can use the mastery property of one kind of weapon you are proficient with, and change which after a long rest."),

    Origin("Alert", "You add your proficiency bonus to initiative, and can swap your initiative with a willing ally.", { Effect("INIT", 0, "PROF") }),
    Origin("Crafter", "Proficiency with three kinds of artisan's tools, a discount on goods, and you can craft a simple item after a long rest."),
    Origin("Healer", "With a healer's kit you can let a creature spend a Hit Die to heal, and you reroll any 1 on healing dice."),
    Origin("Lucky", "After a long rest you have luck points equal to your proficiency bonus. Spend one for advantage on your d20 roll, or to give an attack against you disadvantage."),
    Origin("Magic Initiate", "Two cantrips and one 1st-level spell from the Cleric, Druid or Wizard list. The spell can be cast once per long rest without a slot."),
    Origin("Musician", "Proficiency with three instruments. After a rest your song gives Heroic Inspiration to as many allies as your proficiency bonus."),
    Origin("Savage Attacker", "Once per turn, roll a weapon's damage dice twice and use either result."),
    Origin("Skilled", "Proficiency in any three skills or tools."),
    Origin("Tavern Brawler", "Your unarmed strikes deal 1d4 + Strength, you reroll 1s on them, and once per turn a hit can push the target 5 feet. Improvised weapons count as proficient."),
    Origin("Tough", "Your maximum hit points increase by 2 for every level.", { Effect("HP", 0, "LEVEL", 2) }),

    Boon("Combat Prowess", "Once per turn, turn an attack that missed into a hit."),
    Boon("Dimensional Travel", "Right after you take the Attack or Magic action you can teleport up to 30 feet."),
    Boon("Energy Resistance", "Resistance to two damage types of your choice, changed after a long rest. Reaction when you take one of them: send some of it at another creature."),
    Boon("Fate", "When you or a creature within 60 feet rolls a d20, add or subtract 2d4. Once per rest, or again when you roll initiative."),
    Boon("Fortitude", "Your maximum hit points increase by 40, and once per turn healing you receive is increased by your Constitution modifier.", { effects = { Effect("HP", 40) } }),
    Boon("Irresistible Offense", "Your bludgeoning, piercing and slashing damage ignores resistance, and a natural 20 on an attack deals extra damage equal to the raised ability's score.", { stats = { "STR", "DEX" } }),
    Boon("Recovery", "Once per long rest, when you would drop to 0 HP you drop to 1 and regain half your maximum. You also have a pool of ten d10s to heal yourself with as a bonus action."),
    Boon("Skill", "Proficiency in every skill, and expertise in one of your choice."),
    Boon("Speed", "Your speed increases by 30 feet, and you can Disengage as a bonus action.", { effects = { Effect("SPEED", 30) } }),
    Boon("Spell Recall", "When you cast a spell with a slot of level 1 to 4, roll a d4: if it matches the slot's level, the slot isn't spent.", { stats = MIND }),
    Boon("the Night Spirit", "In dim light or darkness you can turn invisible as a bonus action, and you resist all damage except psychic and radiant."),
    Boon("Truesight", "You have truesight out to 60 feet."),
}

R.FEATS = {}           -- by name
R.FEAT_NAMES = { GENERAL = {}, BOON = {} } -- names for the dropdowns, in alphabetical order
for _, feat in ipairs(LIST) do
    R.FEATS[feat.name] = feat
    table.insert(R.FEAT_NAMES[feat.kind == "BOON" and "BOON" or "GENERAL"], feat.name)
end
table.sort(R.FEAT_NAMES.GENERAL)
table.sort(R.FEAT_NAMES.BOON)
