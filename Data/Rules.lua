-- Rules data: D&D 5e (2024 rules) as used by the "D&D: World of Warcraft" setting book.
-- Only mechanics are encoded here (names and numbers); wording is our own and brief.
-- Look up full feature text in the books. Core numbers follow the System Reference
-- Document 5.2 (CC-BY-4.0, Wizards of the Coast).
--
-- Nothing in this file belongs to one character; characters are created in game.
local _, ns = ...

local R = {}
ns.Rules = R

---------------------------------------------------------------------------
-- Ability scores
---------------------------------------------------------------------------
R.STATS = { "STR", "DEX", "CON", "INT", "WIS", "CHA" }
R.STAT_NAMES = {
    STR = "Strength", DEX = "Dexterity", CON = "Constitution",
    INT = "Intelligence", WIS = "Wisdom", CHA = "Charisma",
}

R.MAX_LEVEL = 20
R.MAX_SCORE = 20
R.BOON_MAX_SCORE = 30 -- an Epic Boon can raise a score past the usual limit

-- Point buy: every score starts at 8 and can be bought up to 15.
R.POINTS = 27
R.BASE_MIN = 8
R.BASE_MAX = 15
R.COST = { [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9 }
R.STANDARD_ARRAY = { 15, 14, 13, 12, 10, 8 }

R.SCORE_METHODS = {
    POINTBUY = "Point buy (27 points)",
    ARRAY = "Standard array (15, 14, 13, 12, 10, 8)",
    MANUAL = "Rolled or set by hand",
}
R.SCORE_METHOD_ORDER = { "POINTBUY", "ARRAY", "MANUAL" }

-- A background raises three abilities: +2 and +1, or +1 to all three (never above 20).
R.BONUS_TOTAL = 3
R.BONUS_MAX = 2

R.ALIGNMENTS = {
    "Lawful Good", "Neutral Good", "Chaotic Good",
    "Lawful Neutral", "Neutral", "Chaotic Neutral",
    "Lawful Evil", "Neutral Evil", "Chaotic Evil",
}

R.SIZE_NAMES = { S = "Small", M = "Medium", L = "Large" }

---------------------------------------------------------------------------
-- Skills
---------------------------------------------------------------------------
R.SKILLS = {
    { name = "Athletics",       stat = "STR" },
    { name = "Acrobatics",      stat = "DEX" },
    { name = "Sleight of Hand", stat = "DEX" },
    { name = "Stealth",         stat = "DEX" },
    { name = "Arcana",          stat = "INT" },
    { name = "History",         stat = "INT" },
    { name = "Investigation",   stat = "INT" },
    { name = "Nature",          stat = "INT" },
    { name = "Religion",        stat = "INT" },
    { name = "Animal Handling", stat = "WIS" },
    { name = "Insight",         stat = "WIS" },
    { name = "Medicine",        stat = "WIS" },
    { name = "Perception",      stat = "WIS" },
    { name = "Survival",        stat = "WIS" },
    { name = "Deception",       stat = "CHA" },
    { name = "Intimidation",    stat = "CHA" },
    { name = "Performance",     stat = "CHA" },
    { name = "Persuasion",      stat = "CHA" },
}
R.PROFICIENCY_NAMES = { [0] = "Not proficient", [1] = "Proficient", [2] = "Expertise" }

---------------------------------------------------------------------------
-- Armor: AC = base + DEX modifier (capped for medium armor, none for heavy)
---------------------------------------------------------------------------
R.ARMOR = {
    NONE      = { name = "No armor", ac = 10 },
    PADDED    = { name = "Padded (light)", ac = 11 },
    LEATHER   = { name = "Leather (light)", ac = 11 },
    STUDDED   = { name = "Studded leather (light)", ac = 12 },
    HIDE      = { name = "Hide (medium)", ac = 12, dexCap = 2 },
    CHAINSHIRT = { name = "Chain shirt (medium)", ac = 13, dexCap = 2 },
    SCALE     = { name = "Scale mail (medium)", ac = 14, dexCap = 2 },
    BREASTPLATE = { name = "Breastplate (medium)", ac = 14, dexCap = 2 },
    HALFPLATE = { name = "Half plate (medium)", ac = 15, dexCap = 2 },
    RINGMAIL  = { name = "Ring mail (heavy)", ac = 14, dexCap = 0 },
    CHAINMAIL = { name = "Chain mail (heavy)", ac = 16, dexCap = 0, minStr = 13 },
    SPLINT    = { name = "Splint (heavy)", ac = 17, dexCap = 0, minStr = 15 },
    PLATE     = { name = "Plate (heavy)", ac = 18, dexCap = 0, minStr = 15 },
}
R.ARMOR_ORDER = {
    "NONE", "PADDED", "LEATHER", "STUDDED", "HIDE", "CHAINSHIRT", "SCALE", "BREASTPLATE",
    "HALFPLATE", "RINGMAIL", "CHAINMAIL", "SPLINT", "PLATE",
}
R.SHIELD_AC = 2

---------------------------------------------------------------------------
-- Spell slots
---------------------------------------------------------------------------
-- Slots per spell level for a full caster, by character level.
R.FULL_SLOTS = {
    { 2 }, { 3 }, { 4, 2 }, { 4, 3 }, { 4, 3, 2 }, { 4, 3, 3 }, { 4, 3, 3, 1 }, { 4, 3, 3, 2 },
    { 4, 3, 3, 3, 1 }, { 4, 3, 3, 3, 2 }, { 4, 3, 3, 3, 2, 1 }, { 4, 3, 3, 3, 2, 1 },
    { 4, 3, 3, 3, 2, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1, 1 },
    { 4, 3, 3, 3, 2, 1, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1, 1, 1 }, { 4, 3, 3, 3, 3, 1, 1, 1, 1 },
    { 4, 3, 3, 3, 3, 2, 1, 1, 1 }, { 4, 3, 3, 3, 3, 2, 2, 1, 1 },
}
-- Pact magic: { number of slots, slot level } by character level.
R.PACT_SLOTS = {
    { 1, 1 }, { 2, 1 }, { 2, 2 }, { 2, 2 }, { 2, 3 }, { 2, 3 }, { 2, 4 }, { 2, 4 }, { 2, 5 }, { 2, 5 },
    { 3, 5 }, { 3, 5 }, { 3, 5 }, { 3, 5 }, { 3, 5 }, { 3, 5 }, { 4, 5 }, { 4, 5 }, { 4, 5 }, { 4, 5 },
}
R.ORDINALS = { "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th" }

