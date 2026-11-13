-- The thirteen World of Warcraft classes and the Player's Handbook class each one uses.
local _, ns = ...
local R = ns.Rules

---------------------------------------------------------------------------
-- Classes
-- The thirteen World of Warcraft classes each use a Player's Handbook class.
--   hitDie       hit point die; level 1 takes the maximum, later levels the average
--   saves        saving throw proficiencies
--   skillCount   how many skills to pick from `skills`
--   cast/caster  spellcasting ability and progression: FULL, HALF or PACT
--   unarmored    without armor, AC adds this ability's modifier on top of DEX
--   pools        class resources that grow with level:
--                steps = { {level, uses}, ... } or perLevel = n (from = first level)
--                short = what a short rest gives back: a number of uses or "ALL"
--   hero         hero class: normally starts at level 3 or higher
---------------------------------------------------------------------------
local BASE = {
    Barbarian = {
        hitDie = 12, saves = { "STR", "CON" }, skillCount = 2,
        skills = { "Animal Handling", "Athletics", "Intimidation", "Nature", "Perception", "Survival" },
        training = "Light and medium armor, shields; simple and martial weapons",
        unarmored = "CON", unarmoredShield = true,
        pools = { { name = "Rage", short = 1, steps = { { 1, 2 }, { 3, 3 }, { 6, 4 }, { 12, 5 }, { 17, 6 } } } },
    },
    Cleric = {
        hitDie = 8, saves = { "WIS", "CHA" }, skillCount = 2,
        skills = { "History", "Insight", "Medicine", "Persuasion", "Religion" },
        training = "Light and medium armor, shields; simple weapons",
        cast = "WIS", caster = "FULL",
        pools = { { name = "Channel Divinity", short = 1, steps = { { 2, 2 }, { 6, 3 }, { 18, 4 } } } },
    },
    Druid = {
        hitDie = 8, saves = { "INT", "WIS" }, skillCount = 2,
        skills = { "Arcana", "Animal Handling", "Insight", "Medicine", "Nature", "Perception", "Religion", "Survival" },
        training = "Light armor, shields; simple weapons",
        cast = "WIS", caster = "FULL",
        pools = { { name = "Wild Shape", short = 1, steps = { { 2, 2 }, { 6, 3 }, { 17, 4 } } } },
    },
    Fighter = {
        hitDie = 10, saves = { "STR", "CON" }, skillCount = 2,
        asiLevels = { 6, 14 }, -- extra Ability Score Improvements on top of the usual levels
        skills = { "Acrobatics", "Animal Handling", "Athletics", "History", "Insight", "Intimidation", "Persuasion", "Perception", "Survival" },
        training = "All armor, shields; simple and martial weapons",
        pools = {
            { name = "Second Wind", short = 1, steps = { { 1, 2 }, { 4, 3 }, { 10, 4 } } },
            { name = "Action Surge", short = "ALL", steps = { { 2, 1 }, { 17, 2 } } },
            { name = "Indomitable", steps = { { 9, 1 }, { 13, 2 }, { 17, 3 } } },
        },
    },
    Monk = {
        hitDie = 8, saves = { "STR", "DEX" }, skillCount = 2,
        skills = { "Acrobatics", "Athletics", "History", "Insight", "Religion", "Stealth" },
        training = "No armor; simple weapons and light martial weapons",
        unarmored = "WIS",
        pools = { { name = "Focus Points", short = "ALL", perLevel = 1, from = 2 } },
    },
    Paladin = {
        hitDie = 10, saves = { "WIS", "CHA" }, skillCount = 2,
        skills = { "Athletics", "Insight", "Intimidation", "Medicine", "Persuasion", "Religion" },
        training = "All armor, shields; simple and martial weapons",
        cast = "CHA", caster = "HALF",
        pools = {
            { name = "Lay on Hands", perLevel = 5 },
            { name = "Channel Divinity", short = 1, steps = { { 3, 2 }, { 11, 3 } } },
        },
    },
    Ranger = {
        hitDie = 10, saves = { "STR", "DEX" }, skillCount = 3,
        skills = { "Animal Handling", "Athletics", "Insight", "Investigation", "Nature", "Perception", "Stealth", "Survival" },
        training = "Light and medium armor, shields; simple and martial weapons",
        cast = "WIS", caster = "HALF",
        pools = { { name = "Favored Enemy", steps = { { 1, 2 }, { 5, 3 }, { 9, 4 }, { 13, 5 }, { 17, 6 } } } },
    },
    Rogue = {
        hitDie = 8, saves = { "DEX", "INT" }, skillCount = 4,
        asiLevels = { 10 },
        skills = { "Acrobatics", "Athletics", "Deception", "Insight", "Intimidation", "Investigation", "Perception", "Persuasion", "Sleight of Hand", "Stealth" },
        training = "Light armor; simple weapons and finesse or light martial weapons",
    },
    Sorcerer = {
        hitDie = 6, saves = { "CON", "CHA" }, skillCount = 2,
        skills = { "Arcana", "Deception", "Insight", "Intimidation", "Persuasion", "Religion" },
        training = "No armor; simple weapons",
        cast = "CHA", caster = "FULL",
        pools = {
            { name = "Sorcery Points", perLevel = 1, from = 2 },
            { name = "Innate Sorcery", steps = { { 1, 2 } } },
        },
    },
    Warlock = {
        hitDie = 8, saves = { "WIS", "CHA" }, skillCount = 2,
        skills = { "Arcana", "Deception", "History", "Intimidation", "Investigation", "Nature", "Religion" },
        training = "Light armor; simple weapons",
        cast = "CHA", caster = "PACT",
    },
    Wizard = {
        hitDie = 6, saves = { "INT", "WIS" }, skillCount = 2,
        skills = { "Arcana", "History", "Insight", "Investigation", "Medicine", "Nature", "Religion" },
        training = "No armor; simple weapons",
        cast = "INT", caster = "FULL",
        pools = { { name = "Arcane Recovery", steps = { { 1, 1 } } } },
    },
}

local function Class(name, base, extra)
    local class = { name = name, base = base }
    for key, value in pairs(BASE[base]) do class[key] = value end
    for key, value in pairs(extra) do class[key] = value end
    return class
end

R.CLASSES = {
    DEATHKNIGHT = Class("Death Knight", "Paladin", {
        hero = true, subclasses = { "Oath of the Ebon Blade" }, specs = { "Blood", "Frost", "Unholy" },
    }),
    DEMONHUNTER = Class("Demon Hunter", "Ranger", {
        hero = true, subclasses = { "Demon Hunter" }, specs = { "Devourer", "Havoc", "Vengeance" },
    }),
    DRUID = Class("Druid", "Druid", {
        subclasses = { "Circle of the Land", "Circle of the Moon", "Circle of the Stars" },
        specs = { "Balance", "Feral", "Guardian", "Restoration" },
    }),
    EVOKER = Class("Evoker", "Sorcerer", {
        hero = true, subclasses = { "Draconic Sorcery" }, specs = { "Augmentation", "Devastation", "Preservation" },
    }),
    HUNTER = Class("Hunter", "Ranger", {
        subclasses = { "Beast Master", "Hunter" }, specs = { "Beast Mastery", "Marksmanship", "Survival" },
    }),
    MAGE = Class("Mage", "Wizard", {
        subclasses = { "Evoker" }, specs = { "Arcane", "Fire", "Frost" },
    }),
    MONK = Class("Monk", "Monk", {
        subclasses = { "Warrior of Mercy", "Warrior of Mystic Brews", "Warrior of the Open Hand" },
        specs = { "Brewmaster", "Mistweaver", "Windwalker" },
    }),
    PALADIN = Class("Paladin", "Paladin", {
        subclasses = { "Oath of Devotion", "Oath of the Holy", "Oath of Vengeance" },
        specs = { "Holy", "Protection", "Retribution" },
    }),
    PRIEST = Class("Priest", "Cleric", {
        subclasses = { "Discipline Domain", "Life Domain", "Shadow Domain" },
        specs = { "Discipline", "Holy", "Shadow" },
    }),
    ROGUE = Class("Rogue", "Rogue", {
        subclasses = { "Assassin", "Soulknife", "Swashbuckler" },
        specs = { "Assassination", "Outlaw", "Subtlety" },
    }),
    SHAMAN = Class("Shaman", "Barbarian", {
        subclasses = { "Path of the Elements", "Path of the Spiritual Guardian", "Path of the World Tree" },
        specs = { "Elemental", "Enhancement", "Restoration" },
    }),
    WARLOCK = Class("Warlock", "Warlock", {
        subclasses = { "Fiend Patron", "Great Old One Patron" },
        specs = { "Affliction", "Demonology", "Destruction" },
    }),
    WARRIOR = Class("Warrior", "Fighter", {
        subclasses = { "Battle Master", "Champion" }, specs = { "Arms", "Fury", "Protection" },
    }),
}
R.CLASS_ORDER = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK",
    "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR",
}
R.HERO_START_LEVEL = 3
R.DEFAULT_HIT_DIE = 8 -- used until a class is chosen


-- Levelling
R.SUBCLASS_LEVEL = 3
R.ASI_LEVELS = { 4, 8, 12, 16 } -- every class improves ability scores (or takes a feat) here
R.ASI_POINTS = 2                -- points per improvement: +2 to one ability or +1 to two
R.EPIC_BOON_LEVEL = 19
