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
        minimized = false, -- the sheet window is only its title bar until hovered
        minimap = { hide = false },
        themePreset = "DARK",
        theme = CopyTable(ns.Themes.DARK),
        -- Size and place of each window (the place is added when it is first moved).
        window = { width = 340, height = 560 },          -- the sheet; 340 is as narrow as it goes (UI/Window.lua)
        itemWindow = { width = 560, height = 520 },      -- item browser, stable, crafting (UI/ItemBrowser.lua)
        spellbookWindow = { width = 340, height = 420 }, -- UI/SpellbookWindow.lua
        preparedWindow = { width = 340, height = 420 },  -- UI/PreparedWindow.lua
    },
    -- Per WoW character.
    char = {
        name = "",
        shown = true,
        sheetTab = "Actions", -- the open tab of the sheet (UI/SheetTabs.lua)
    },
    -- One entry per Total RP 3 profile ("trp3:<profile id>"), shared by the whole account
    -- like TRP3's own profiles. Without TRP3 the key is "char:<Name-Realm>".
    -- "*" is AceDB's wildcard: any key that doesn't exist yet starts from these values.
    global = {
        -- The armoury: weapons kept for every character on the account, each shaped like
        -- an entry of a sheet's `weapons` (Sheet/WeaponStore.lua).
        weaponStore = {},
        sheets = {
            ["*"] = {
                created = false, -- set once the creation wizard was finished or skipped
                weapon = 1,
                -- Current values. hp and hitDice are filled to their maximum on first use.
                tempHP = 0,
                inspiration = false, -- Heroic Inspiration
                deathPass = 0, deathFail = 0,
                conditions = {}, -- [condition name] = true
                exhaustion = 0,  -- exhaustion level, 0 to 6
                res = {},   -- custom resources, by name
                pool = {},  -- class resources, by name
                slots = {}, -- spell slots, by spell level
                pactSlots = {},   -- a Warlock's slots, when another class's slots are kept beside them (Sheet/MulticlassSlots.lua)
                hitDiceMore = {}, -- [die size] = Hit Dice left of the classes whose die differs from the first class's
                freeUsed = {}, -- [ability name] = true: its free first use since a long rest is gone
                spellUsed = {}, -- [spell name] = true: its one casting without a slot is gone until a rest (Actions/SpellChoices.lua)
                sheet = {
                    version = 2,
                    level = 1,
                    class = "", subclass = "", spec = "",
                    -- Classes taken after the first: [class key] = { level, subclass, spec, skill }.
                    -- `level` above is the whole character's (Sheet/Classes.lua).
                    classes = {},
                    lastClass = "", -- the class the last level was taken in, for going back a level
                    fightingStyle = "", fightingStyle2 = "", -- see Rules.FIGHTING_STYLES
                    species = "", lineage = "", size = "M",
                    allegiance = "", -- ALLIANCE, HORDE or NEUTRAL
                    languages = {}, -- [language] = true
                    renown = {},    -- [faction] = score
                    renownReached = {},  -- [faction] = lowest score of the highest tier it ever reached (Sheet/RenownRules.lua)
                    renownTraining = {}, -- [faction] = language, tool or skill its trainers taught (Sheet/RenownTraining.lua)
                    renownGranted = {},  -- [faction] = the language or skill that pick added
                    stronghold = "",     -- the faction whose lands the character's stronghold stands in (Sheet/RenownRules.lua)
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
                    componentsWaived = false, -- true: spells are cast without checking for their priced components (a DM ruling)
                    spellbook = {},      -- [spell name] = true: a Mage's spellbook (Sheet/Spellbook.lua)
                    coins = { pp = 0, gp = 0, ep = 0, sp = 0, cp = 0 }, -- money (Sheet/Coins.lua)
                    items = {},          -- what is carried; entries follow Rules.TEMPLATES.item (Sheet/Inventory.lua)
                    mounts = {},         -- mounts, vehicles and companion creatures owned; entries follow Rules.TEMPLATES.mount (Sheet/Mounts.lua)
                    dismissed = {}, -- class features the player deleted: [auto key] = true
                    featureScores = {}, -- [ability] = points a capstone feature adds (worked out, not edited)
                    defensePicks = {},   -- [passive name] = { damage types chosen for its resistance } (Sheet/DefensePicks.lua)
                    featureOptions = {}, -- [feature name] = option picked for it (Primal Order: "Warden")
                    petMastery = false,  -- the companion's family is one of the Weapon Mastery picks (Sheet/Pet.lua)
                    tools = {},            -- [tool] = true: proficiency ticked by hand (Data/Tools.lua)
                    featSkills = {},       -- [skill] = true: proficiency picked for a feat (Skilled)
                    featSkillGranted = {}, -- [skill] = true where that pick made the skill proficient
                    featTools = {},        -- [tool] = true: a tool picked in place of one of those skills (Sheet/FeatTools.lua)
                    featChoices = {},      -- [feat instance] = the picks made for a feat's own choices (Sheet/FeatChoices.lua)
                    featGranted = {},      -- [skill] = ranks those picks added (Sheet/FeatGrants.lua)
                    expertise = {},        -- [skill] = true: expertise picked for a class feature
                    expertiseGranted = {}, -- [skill] = true where that pick raised the skill
                    picks = {},          -- [list][name] = true: Metamagic, Eldritch Invocations, a feature's tools (Data/Picks.lua)
                    maneuvers = {},     -- [maneuver name] = true, for a Battle Master
                    featureSkills = {}, -- [feature name] = skill picked for it (Student of War)
                    featureSkillGranted = {}, -- [feature name] = skill it made proficient
                    traitChoices = {}, -- [trait name] = the skill or feat picked for it
                    traitGranted = {}, -- [trait name] = skill it made proficient
                    -- Professions (Sheet/Professions.lua fills in what is missing).
                    materials = {}, -- [kind] = worth of gathered materials, in copper
                    recipes = {},   -- [item name] = true: a recipe learned beyond the basic ones
                    toolsWaived = false, -- true: things are made without checking that the tool is carried (a DM ruling)
                    fragments = {}, -- { plain, magic, failedAt }: archaeology finds
                },
            },
        },
    },
}

-- A blank sheet, as a plain table.
function ns.NewSheet()
    return CopyTable(ns.defaults.global.sheets["*"].sheet)
end
