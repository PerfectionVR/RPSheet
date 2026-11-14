-- What passives and abilities are made of, and the blank entries new ones start from.
local _, ns = ...
local R = ns.Rules

---------------------------------------------------------------------------
-- Effects: the building blocks of passives and abilities
---------------------------------------------------------------------------
-- A passive effect adds  flat + times x value  to a target, where the value is an
-- ability modifier, the character level, or the proficiency bonus.
R.AMOUNT_SOURCES = { [""] = "None", LEVEL = "Character level", PROF = "Proficiency bonus" }
R.AMOUNT_SOURCE_ORDER = { "" }
for _, stat in ipairs(R.STATS) do
    R.AMOUNT_SOURCES[stat] = R.STAT_NAMES[stat] .. " modifier"
    table.insert(R.AMOUNT_SOURCE_ORDER, stat)
end
table.insert(R.AMOUNT_SOURCE_ORDER, "LEVEL")
table.insert(R.AMOUNT_SOURCE_ORDER, "PROF")

R.EFFECT_TARGETS = {
    AC = "Armor Class",
    HP = "Maximum HP",
    INIT = "Initiative",
    SPEED = "Speed (feet)",
    ATTACK = "Attack rolls",
    DAMAGE = "Damage rolls",
    HEALING = "Healing rolls",
    SPELLDC = "Spell save DC",
    SPELLATK = "Spell attack rolls",
    SAVES = "All saving throws",
    CHECKS = "All ability checks",
    SKILLS = "All skill checks",
}
R.EFFECT_TARGET_ORDER = {
    "AC", "HP", "INIT", "SPEED", "ATTACK", "DAMAGE", "HEALING", "SPELLDC", "SPELLATK", "SAVES", "CHECKS", "SKILLS",
}
for _, stat in ipairs(R.STATS) do
    R.EFFECT_TARGETS["SAVE:" .. stat] = "Saving throw: " .. R.STAT_NAMES[stat]
    table.insert(R.EFFECT_TARGET_ORDER, "SAVE:" .. stat)
end
for _, skill in ipairs(R.SKILLS) do
    R.EFFECT_TARGETS["SKILL:" .. skill.name] = "Skill: " .. skill.name
    table.insert(R.EFFECT_TARGET_ORDER, "SKILL:" .. skill.name)
end

-- What an ability does when clicked, in order. An ability can have any number of these.
R.ACTIONS = {
    ROLL = "Roll a d20",
    DICE = "Roll dice (damage or healing)",
    WEAPON = "Roll the equipped weapon's dice",
    SPEND = "Spend a resource",
    GAIN = "Regain a resource",
    EMPTY = "Empty a resource",
    TOGGLE = "Switch a passive on or off",
}
R.ACTION_ORDER = { "ROLL", "DICE", "WEAPON", "SPEND", "GAIN", "EMPTY", "TOGGLE" }
R.ROLL_KINDS = { ATTACK = "Attack", CHECK = "Check", SAVE = "Saving throw", SPELL = "Spell attack" }
R.ROLL_KIND_ORDER = { "ATTACK", "SPELL", "CHECK", "SAVE" }
-- What rolled dice count as. The last two act on the character itself.
R.DICE_KINDS = {
    DAMAGE = "Damage", HEALING = "Healing (someone else)",
    SELFHEAL = "Healing (heals you)", TEMPHP = "Temporary HP (yours)",
    DRAIN = "Damage that heals you by the same amount", OTHER = "Other (added to a roll)",
}
R.DICE_KIND_ORDER = { "DAMAGE", "DRAIN", "HEALING", "SELFHEAL", "TEMPHP", "OTHER" }
R.TOGGLE_MODES = { ON = "Switch on", OFF = "Switch off", TOGGLE = "Flip" }

-- Blank entries for the lists a player can add to. There is no limit on how many.
R.TEMPLATES = {
    -- style: the character's Fighting Style applies to it; mastery: see Rules.MASTERIES
    weapon = { name = "", stat = "STR", dice = 1, sides = 8, proficient = true, heal = false, style = true, mastery = "" },
    resource = { name = "", flat = 1, stat = "", times = 1, startEmpty = false, shortRest = false },
    ability = { name = "", desc = "", auto = "", actions = {} },
    passive = { name = "", desc = "", auto = "", enabled = true, effects = {} },
    effect = { target = "AC", flat = 0, stat = "", times = 1 },
    action = {
        type = "ROLL",
        kind = "ATTACK", stat = "STR", stat2 = "", proficient = true, -- ROLL
        count = 1, sides = 6, dice = "DAMAGE", flat = 0,               -- DICE (uses stat too)
        times = 1,                                                     -- WEAPON
        resource = "", amount = 1, freeIfFull = "",                    -- SPEND / GAIN / EMPTY
        passive = "", mode = "TOGGLE",                                 -- TOGGLE
    },
}


-- Short names used when describing an effect or action.
R.AMOUNT_SHORT = { LEVEL = "level", PROF = "proficiency" }

---------------------------------------------------------------------------
-- Spells: entered by the player, cast from the sheet
---------------------------------------------------------------------------
R.SPELL_KINDS = { NONE = "No roll", ATTACK = "Spell attack", SAVE = "Saving throw" }
R.SPELL_KIND_ORDER = { "NONE", "ATTACK", "SAVE" }
R.SPELL_LEVELS = { [0] = "Cantrip" }
for level, ordinal in ipairs(R.ORDINALS) do R.SPELL_LEVELS[level] = ordinal .. " level" end

R.TEMPLATES.spell = {
    name = "", desc = "",
    level = 0,                 -- 0 = cantrip, which needs no slot
    kind = "NONE", save = "DEX", -- how it is resolved, and the save it forces
    count = 0, sides = 8,      -- dice rolled; a count of 0 rolls nothing
    dice = "DAMAGE",           -- see DICE_KINDS
    addMod = false,            -- add the spellcasting modifier to the dice
    concentration = false,
    scales = false,            -- cantrip whose dice grow at character levels 5, 11 and 17
    free = false,              -- doesn't count against cantrips known or spells prepared
}
