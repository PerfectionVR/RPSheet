-- What taking a level in another class asks for and gives, by Player's Handbook class.
--   primary   the abilities that need a score of 13: all of them, or any one of them
--             when `either` is set
--   armor     armor training the new class adds ("light", "medium", "shield")
--   martial   it adds proficiency with martial weapons
--   skill     it adds one skill from the class's own list
--   tools     tool proficiencies it adds
-- A class taken later gives only these, never its saving throws.
local _, ns = ...
local R = ns.Rules

R.MULTICLASS_SCORE = 13

R.MULTICLASS = {
    Barbarian = { primary = { "STR" }, armor = { "shield" }, martial = true },
    Cleric = { primary = { "WIS" }, armor = { "light", "medium", "shield" } },
    Druid = { primary = { "WIS" }, armor = { "light", "shield" } },
    Fighter = { primary = { "STR", "DEX" }, either = true, armor = { "light", "medium", "shield" }, martial = true },
    Monk = { primary = { "DEX", "WIS" } },
    Paladin = { primary = { "STR", "CHA" }, armor = { "light", "medium", "shield" }, martial = true },
    Ranger = { primary = { "DEX", "WIS" }, armor = { "light", "medium", "shield" }, martial = true, skill = true },
    Rogue = { primary = { "DEX" }, armor = { "light" }, skill = true, tools = { "Thieves' Tools" } },
    Sorcerer = { primary = { "CHA" } },
    Warlock = { primary = { "CHA" }, armor = { "light" } },
    Wizard = { primary = { "INT" } },
}
