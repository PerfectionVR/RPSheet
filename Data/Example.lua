-- A finished character, loadable from the settings.
local _, ns = ...

---------------------------------------------------------------------------
-- Example character, loadable from the settings. Shows how things fit together.
---------------------------------------------------------------------------
ns.ExampleCharacter = {
    version = 2,
    level = 3, class = "ROGUE", subclass = "Swashbuckler", spec = "Outlaw",
    species = "HUMAN", size = "M", background = "CRIMINAL", alignment = "Chaotic Good",
    scoreMethod = "POINTBUY",
    base = { STR = 10, DEX = 15, CON = 12, INT = 10, WIS = 14, CHA = 10 },
    bonus = { STR = 0, DEX = 2, CON = 1, INT = 0, WIS = 0, CHA = 0 },
    skills = { ["Sleight of Hand"] = 1, Stealth = 2, Acrobatics = 1, Perception = 2, Deception = 1, Insight = 1 },
    saves = { DEX = true, INT = true },
    armor = "LEATHER", shield = false, hpAdjust = 0, castStat = "",
    resources = {
        { name = "Energy", flat = 6, stat = "", times = 1, startEmpty = false },
        { name = "Fatal Marks", flat = 5, stat = "", times = 1, startEmpty = true },
    },
    weapons = {
        { name = "Rapier", stat = "DEX", dice = 1, sides = 8, proficient = true, heal = false },
    },
    abilities = {
        { name = "Sneak Attack", desc = "Once per turn, extra damage on a hit with advantage or an ally next to the target. 2d6 at level 3.",
          actions = { { type = "DICE", count = 2, sides = 6, dice = "DAMAGE", stat = "" } } },
        { name = "Execute", desc = "Finishing strike: attack, then twice the weapon's dice. Costs 4 Energy, or nothing at 5 Fatal Marks; either way the marks are consumed.",
          actions = {
              { type = "SPEND", resource = "Energy", amount = 4, freeIfFull = "Fatal Marks" },
              { type = "ROLL", kind = "ATTACK", stat = "DEX", stat2 = "", proficient = true },
              { type = "WEAPON", times = 2 },
              { type = "EMPTY", resource = "Fatal Marks" },
          } },
        { name = "Exotic Stance", desc = "Spend 2 Energy to enter a stance that adds Wisdom to damage. Click the passive to end it.",
          actions = {
              { type = "SPEND", resource = "Energy", amount = 2, freeIfFull = "" },
              { type = "TOGGLE", passive = "Exotic Stance", mode = "ON" },
          } },
    },
    passives = {
        { name = "Exotic Stance", enabled = false, desc = "While the stance is up: Wisdom modifier added to damage rolls.",
          effects = { { target = "DAMAGE", flat = 0, stat = "WIS", times = 1 } } },
        { name = "Alert", enabled = true, desc = "Origin feat from the Criminal background.",
          effects = { { target = "INIT", flat = 0, stat = "PROF", times = 1 } } },
        { name = "Resourceful", enabled = true, desc = "Human trait.", effects = {} },
        { name = "Skillful", enabled = true, desc = "Human trait.", effects = {} },
        { name = "Versatile", enabled = true, desc = "Human trait.", effects = {} },
    },
}
