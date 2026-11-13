-- The shape of everything the addon saves, and the values a fresh install starts with.
local _, ns = ...

ns.defaults = {
    -- Settings shared by all characters.
    profile = {
        channel = "EMOTE",
        useTRP3 = true,
        tooltip = true,
        share = true,
        locked = false,
        minimap = { hide = false },
        themePreset = "DARK",
        theme = CopyTable(ns.Themes.DARK),
        window = { width = 300, height = 560 },
    },
    -- Per WoW character.
    char = {
        name = "",
        shown = true,
    },
    -- One entry per Total RP 3 profile ("trp3:<profile id>"), shared by the whole account
    -- like TRP3's own profiles. Without TRP3 the key is "char:<Name-Realm>".
    -- "*" is AceDB's wildcard: any key that doesn't exist yet starts from these values.
    global = {
        sheets = {
            ["*"] = {
                created = false, -- set once the creation wizard was finished or skipped
                weapon = 1,
                -- Current values. hp and hitDice are filled to their maximum on first use.
                tempHP = 0,
                inspiration = false, -- Heroic Inspiration
                deathPass = 0, deathFail = 0,
                res = {},   -- custom resources, by name
                pool = {},  -- class resources, by name
                slots = {}, -- spell slots, by spell level
                sheet = {
                    version = 2,
                    level = 1,
                    class = "", subclass = "", spec = "",
                    species = "", lineage = "", size = "M",
                    allegiance = "", -- ALLIANCE, HORDE or NEUTRAL
                    languages = {}, -- [language] = true
                    renown = {},    -- [faction] = score
                    extraLanguages = 0, -- languages granted by features, on top of the usual three
                    asi = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 }, -- points from level-ups
                    background = "", alignment = "",
                    scoreMethod = "POINTBUY",
                    base = { STR = 8, DEX = 8, CON = 8, INT = 8, WIS = 8, CHA = 8 },
                    bonus = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 },
                    skills = {}, -- [skill name] = 1 (proficient) or 2 (expertise)
                    saves = {},  -- [stat] = true
                    armor = "NONE", shield = false,
                    hpAdjust = 0,  -- for rolled hit points or DM rulings
                    castStat = "", -- empty = the class's spellcasting ability
                    -- Lists of any length; entries follow Rules.TEMPLATES.
                    resources = {},
                    weapons = {},
                    abilities = {},
                    passives = {},
                    spells = {},
                    dismissed = {}, -- class features the player deleted: [auto key] = true
                },
            },
        },
    },
}

-- A blank sheet, as a plain table.
function ns.NewSheet()
    return CopyTable(ns.defaults.global.sheets["*"].sheet)
end
