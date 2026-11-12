-- The ruleset's fixed numbers. Characters themselves are created in game (/sheet config)
-- and saved per character; nothing in this file is specific to one character.
local _, ns = ...

ns.Rules = {
    STATS = { "STR", "DEX", "CON", "INT", "WIS", "CHA" },
    STAT_NAMES = {
        STR = "Strength", DEX = "Dexterity", CON = "Constitution",
        INT = "Intelligence", WIS = "Wisdom", CHA = "Charisma",
    },

    -- Point buy: every stat starts at 8 and can be bought up to 15.
    POINTS = 27,
    BASE_MIN = 8,
    BASE_MAX = 15,
    COST = { [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9 },
    -- Afterwards: +2 and +1, or +1 to three stats. Never +3 on one stat.
    BONUS_TOTAL = 3,
    BONUS_MAX = 2,

    -- HP = size base + 2 x CON modifier
    SIZES = {
        SMALL = { name = "Small", hp = 6 },
        MEDIUM = { name = "Medium", hp = 8 },
        LARGE = { name = "Large", hp = 10 },
    },
    SIZE_ORDER = { "SMALL", "MEDIUM", "LARGE" },

    -- AC = armor base + DEX modifier + shield + passive bonus
    ARMOR = {
        CLOTH = { name = "Cloth", ac = 5 },
        LEATHER = { name = "Leather", ac = 6 },
        MAIL = { name = "Mail", ac = 7, minStr = 13 },
        PLATE = { name = "Plate", ac = 8, minStr = 14 },
    },
    ARMOR_ORDER = { "CLOTH", "LEATHER", "MAIL", "PLATE" },
    SHIELDS = {
        NONE = { name = "No shield", ac = 0 },
        SMALL = { name = "Small shield", ac = 1 },
        LARGE = { name = "Large shield", ac = 2 },
    },
    SHIELD_ORDER = { "NONE", "SMALL", "LARGE" },

    -- Damage and healing rolls: dice + stat modifier
    WEAPON_KINDS = {
        ONE = { name = "One-handed (1d4)", dice = 1, sides = 4 },
        RANGED = { name = "Ranged (1d6)", dice = 1, sides = 6 },
        TWO = { name = "Two-handed (1d8)", dice = 1, sides = 8 },
        HEAL = { name = "Healing (1d3, no attack roll)", dice = 1, sides = 3, heal = true },
        CUSTOM = { name = "Custom dice" },
    },
    WEAPON_KIND_ORDER = { "ONE", "RANGED", "TWO", "HEAL", "CUSTOM" },

    -- What a passive effect can add to. Each skill is added below as "SKILL:<name>".
    EFFECT_TARGETS = {
        AC = "Armor Class",
        HP = "Maximum HP",
        RESOURCE = "Maximum resource",
        ATTACK = "Attack rolls",
        DAMAGE = "Damage rolls",
        HEALING = "Healing rolls",
        SKILLS = "All skill checks",
    },
    EFFECT_TARGET_ORDER = { "AC", "HP", "RESOURCE", "ATTACK", "DAMAGE", "HEALING", "SKILLS" },

    -- Blank entries for the lists a player can add to. There is no limit on how many.
    TEMPLATES = {
        weapon = { name = "", kind = "ONE", stat = "STR", dice = 1, sides = 4 },
        ability = { name = "", desc = "", cost = 0, stat1 = "", stat2 = "", weaponDamage = 0, usesCounter = false },
        passive = { name = "", desc = "", enabled = true, effects = {} },
        -- amount = flat + times x modifier of stat
        effect = { target = "AC", flat = 0, stat = "", times = 1 },
    },

    SKILLS = {
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
    },
}

for _, skill in ipairs(ns.Rules.SKILLS) do
    local key = "SKILL:" .. skill.name
    ns.Rules.EFFECT_TARGETS[key] = "Skill: " .. skill.name
    table.insert(ns.Rules.EFFECT_TARGET_ORDER, key)
end

-- Example character, loadable from the settings. Shows how abilities and passives are set up.
ns.ExampleCharacter = {
    base = { STR = 10, DEX = 14, CON = 12, INT = 10, WIS = 15, CHA = 10 },
    bonus = { STR = 0, DEX = 2, CON = 0, INT = 0, WIS = 1, CHA = 0 },
    size = "MEDIUM", armor = "LEATHER", shield = "NONE",
    resourceName = "Energy", resourceStat = "WIS",
    counterName = "Fatal Marks", counterMax = 5,
    weapons = {
        { name = "Rapier", kind = "ONE", stat = "DEX", dice = 1, sides = 4 },
    },
    abilities = {
        { name = "Perfect Defense", cost = 2, stat1 = "DEX", stat2 = "WIS", weaponDamage = 0, usesCounter = false,
          desc = "Once per combat, when targeted by an incoming attack, roll D20 + DEX + WIS against the DM's attack roll. On success, negate the damage." },
        { name = "Execute", cost = 4, stat1 = "DEX", stat2 = "", weaponDamage = 2, usesCounter = true,
          desc = "Finishing strike. Attack: D20 + DEX. Damage: 2 x weapon damage dice + DEX. Consumes all Fatal Marks. Free at 5 Fatal Marks." },
        { name = "Exotic Stance", cost = 2, stat1 = "", stat2 = "", weaponDamage = 0, usesCounter = false,
          desc = "For two rounds, add WIS modifier to melee damage rolls. Switch the Exotic Stance passive on while it lasts." },
    },
    passives = {
        { name = "Celerity", enabled = true, desc = "Add twice your DEX modifier to AC.",
          effects = { { target = "AC", flat = 0, stat = "DEX", times = 1 } } }, -- armor already adds DEX once
        { name = "Fatality", enabled = true, effects = {},
          desc = "Each successful melee attack or Perfect Deflection (enemy rolls 1 on attack) applies 1 Fatal Mark to the target (max 5). A natural 20 on the attack applies 2. At 5 marks, cast an ability without using any Energy." },
        { name = "Anomaly", enabled = true, effects = {}, desc = "Once per event, re-roll a bad roll." },
        { name = "Exotic Stance", enabled = false, desc = "While the stance is up: WIS modifier added to damage rolls.",
          effects = { { target = "DAMAGE", flat = 0, stat = "WIS", times = 1 } } },
    },
}
