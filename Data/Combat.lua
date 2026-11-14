-- Fighting Styles and weapon masteries, with short summaries in our own words.
local _, ns = ...
local R = ns.Rules

-- A Fighting Style is chosen once (twice for a Champion). The numbers apply to the
-- weapons that have "Fighting Style applies" ticked.
--   attack / damage  added to those weapons' attack and damage rolls
--   minDie           their damage dice never count as less than this
--   armoredAC        added to Armor Class while wearing armor
--   base / class     only for this Player's Handbook class, or this World of Warcraft class
R.FIGHTING_STYLES = {
    ["Archery"] = { attack = 2, desc = "+2 to attack rolls with ranged weapons." },
    ["Blind Fighting"] = { desc = "Blindsight out to 10 feet." },
    ["Defense"] = { armoredAC = 1, desc = "+1 to Armor Class while you wear armor." },
    ["Dueling"] = { damage = 2, desc = "+2 damage with a melee weapon held in one hand while you hold no other weapon." },
    ["Great Weapon Fighting"] = { minDie = 3, desc = "With a melee weapon held in two hands, a 1 or 2 on a damage die counts as a 3." },
    ["Interception"] = { desc = "Reaction when a creature within 5 feet of you is hit: reduce the damage by 1d10 + your proficiency bonus. You need a shield or a weapon in hand." },
    ["Protection"] = { desc = "Reaction with a shield when a creature within 5 feet of you is attacked: the attack, and others against it until your next turn, have disadvantage." },
    ["Thrown Weapon Fighting"] = { damage = 2, desc = "+2 damage when you hit with a thrown weapon." },
    ["Two-Weapon Fighting"] = { desc = "You add your ability modifier to the damage of the extra attack made with a second light weapon." },
    ["Blessed Warrior"] = { base = "Paladin", desc = "You learn two Cleric cantrips, which count as Paladin spells and use Charisma." },
    ["Druidic Warrior"] = { base = "Ranger", desc = "You learn two Druid cantrips, which count as Ranger spells and use Wisdom." },
    ["Void Warrior"] = { class = "DEMONHUNTER", desc = "You learn two Warlock cantrips, which count as Ranger spells and use Wisdom. Chill Touch and Mind Sliver fit well." },
    ["Unarmed Fighting"] = { desc = "Your unarmed strikes deal 1d6 + Strength, or 1d8 with both hands free, and a creature you grapple takes 1d4 at the start of each of your turns." },
}
R.FIGHTING_STYLE_ORDER = {
    "Archery", "Blessed Warrior", "Blind Fighting", "Defense", "Druidic Warrior", "Dueling", "Great Weapon Fighting",
    "Interception", "Protection", "Thrown Weapon Fighting", "Two-Weapon Fighting", "Unarmed Fighting", "Void Warrior",
}

-- A weapon's mastery property. `note` is what is said when attacking with it; %d is
-- filled with a number worked out for the character (see Sheet/Combat.lua).
R.MASTERIES = {
    Cleave = { desc = "Once per turn, after hitting, you can attack a second creature within 5 feet of the first. That attack doesn't add your ability modifier to its damage.",
               note = "On a hit: can cleave into a second creature within 5 feet" },
    Graze = { desc = "If the attack misses, the target still takes damage equal to your ability modifier.",
              note = "On a miss: %d damage anyway" },
    Nick = { desc = "The extra attack of a second light weapon is part of your Attack action, not a bonus action. Once per turn.",
             note = "The extra light-weapon attack needs no bonus action" },
    Push = { desc = "On a hit you can push a creature up to one size larger than you 10 feet away.",
             note = "On a hit: pushes the target 10 feet" },
    Sap = { desc = "On a hit the target has disadvantage on its next attack roll before your next turn.",
            note = "On a hit: the target has disadvantage on its next attack" },
    Slow = { desc = "On a hit that deals damage, the target's speed drops by 10 feet until your next turn.",
             note = "On a hit: the target's speed drops by 10 feet" },
    Topple = { desc = "On a hit the target makes a Constitution save (DC 8 + your attack ability modifier + proficiency bonus) or falls prone.",
               note = "On a hit: Constitution save DC %d or prone" },
    Vex = { desc = "On a hit that deals damage, you have advantage on your next attack against that creature before the end of your next turn.",
            note = "On a hit: advantage on your next attack against it" },
}
-- How many weapons a class can use the mastery of, as { {level, weapons}, ... }.
R.MASTERY_LIMITS = {
    Fighter = { { 1, 3 }, { 4, 4 }, { 10, 5 }, { 16, 6 } },
    Barbarian = { { 1, 2 }, { 4, 3 }, { 10, 4 } },
    Paladin = { { 1, 2 } }, Ranger = { { 1, 2 } }, Rogue = { { 1, 2 } },
}
R.MASTERY_ORDER = { "", "Cleave", "Graze", "Nick", "Push", "Sap", "Slow", "Topple", "Vex" }
