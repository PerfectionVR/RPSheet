-- Spells that help the one they are cast on with their rolls while they last
-- (form of the entries: Data/SpellWards.lua). An option can also have:
--     advantage, disadvantage   the rolls it gives that to, by the sheet's labels
--                               ("DEX save", "STR check", a skill, "attack", ...)
--     rollDie    { sides = 4, labels = {...} }: a die added to those rolls
--     minRoll    { value = 15, labels = {...} }: a lower d20 counts as that
--     strike     { count, sides, damage, all }: dice added to weapon hits, `all` for
--                ranged ones too (Sheet/SpellWeapons.lua)
-- (Actions/SpellRollBonus.lua applies them.) Advantage that depends on what a save is
-- against goes by the passive's name in Data/SaveAdvantages.lua.
local _, ns = ...
local R = ns.Rules
local Bonus = ns.FeatureKit.Bonus

local W = R.SPELL_WARDS

-- The sheet's labels for the rolls of each kind.
local SAVES, CHECKS, BY_STAT = {}, {}, {}
for _, stat in ipairs(R.STATS) do
    SAVES[#SAVES + 1] = stat .. " save"
    CHECKS[#CHECKS + 1] = stat .. " check"
    BY_STAT[stat] = { stat .. " check" }
end
BY_STAT.DEX[#BY_STAT.DEX + 1] = "initiative" -- a Dexterity check
for _, skill in ipairs(R.SKILLS) do
    CHECKS[#CHECKS + 1] = skill.name
    table.insert(BY_STAT[skill.stat], skill.name)
end
CHECKS[#CHECKS + 1] = "initiative"
local function Join(...)
    local all = {}
    for _, list in ipairs({ ... }) do for _, label in ipairs(list) do all[#all + 1] = label end end
    return all
end
local ATTACKS = { "attack", "spell attack" }
local ALL_SAVES = Join(SAVES, { "death save" })
R.D20_LABELS = Join(ATTACKS, ALL_SAVES, CHECKS)

W["Bless"] = { hours = 0, conc = true, { text = "1d4 added to your attack rolls and saving throws", rollDie = { sides = 4, labels = Join(ATTACKS, ALL_SAVES) } } }
W["Guidance"] = { hours = 0, conc = true }
for _, skill in ipairs(R.SKILLS) do
    table.insert(W["Guidance"], { label = skill.name, text = ("1d4 added to your %s checks"):format(skill.name), rollDie = { sides = 4, labels = { skill.name } } })
end
W["Enhance Ability"] = { hours = 1, conc = true }
for _, stat in ipairs({ "STR", "DEX", "INT", "WIS", "CHA" }) do
    table.insert(W["Enhance Ability"], { label = R.STAT_NAMES[stat], text = ("advantage on %s checks"):format(R.STAT_NAMES[stat]), advantage = BY_STAT[stat] })
end
W["Pass without Trace"] = { hours = 1, conc = true, { text = "+10 to Dexterity (Stealth) checks, and you leave no tracks, while in the aura", effects = { Bonus("SKILL:Stealth", 10) } } }
W["Foresight"] = { hours = 8, { text = "advantage on every d20 test, and attacks against you have disadvantage", advantage = R.D20_LABELS } }
W["Holy Aura"] = { hours = 0, conc = true, { text = "advantage on every saving throw while in the aura, and attacks against you have disadvantage", advantage = ALL_SAVES } }
W["Beacon of Hope"] = { hours = 0, conc = true, { text = "advantage on Wisdom saves and death saves, and healing restores the most it can", advantage = { "WIS save", "death save" } } }
W["Circle of Power"] = { hours = 0, conc = true, own = true, { text = "advantage on saves against spells and magic in the aura, and no damage on such a save that halves it" } }
W["Glibness"] = { hours = 1, own = true, { text = "a d20 under 15 on a Charisma check counts as 15",
    minRoll = { value = 15, labels = Join(BY_STAT.CHA) } } }
W["Enlarge/Reduce"] = { hours = 0, conc = true,
    { label = "enlarged", text = "advantage on Strength checks and saves, and 1d4 more damage on your weapon hits",
      advantage = Join(BY_STAT.STR, { "STR save" }), strike = { count = 1, sides = 4, damage = "Enlarge", all = true } },
    { label = "reduced", text = "disadvantage on Strength checks and saves, and 1d4 less damage on your weapon hits (right-click the spell to roll it)",
      disadvantage = Join(BY_STAT.STR, { "STR save" }) } }
W["Combustion"][1].advantage = { "spell attack" }
W["Combustion"][1].text = "immunity to fire damage and advantage on spell attack rolls"
