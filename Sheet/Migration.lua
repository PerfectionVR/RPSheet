-- Brings a saved sheet into the current shape, whatever version saved it.
-- Version 1 used a simplified homebrew ruleset; it is converted in place, keeping the
-- character's numbers as close as the 5e rules allow.
local _, ns = ...
local R = ns.Rules
local Util = ns.Util

local OLD_WEAPON = {
    ONE = { 1, 4 }, RANGED = { 1, 6 }, TWO = { 1, 8 }, HEAL = { 1, 3, true },
}
local OLD_ARMOR = { CLOTH = "NONE", LEATHER = "LEATHER", MAIL = "CHAINMAIL", PLATE = "PLATE" }
local OLD_SIZE_HP = { SMALL = 6, MEDIUM = 8, LARGE = 10 }

local function MigrateV1(state)
    local sheet = state.sheet
    local function mod(stat)
        return Util.ScoreMod((sheet.base[stat] or 8) + (sheet.bonus[stat] or 0))
    end

    -- Hit points: old = size base + 2 x CON; new (no class yet) = 8 + CON. Keep the old total.
    local oldSize = rawget(sheet, "size")
    local oldHP = (OLD_SIZE_HP[oldSize] or 8) + 2 * mod("CON")
    sheet.hpAdjust = oldHP - (R.DEFAULT_HIT_DIE + mod("CON"))
    sheet.size = "M"

    sheet.armor = OLD_ARMOR[rawget(sheet, "armor") or "CLOTH"] or "NONE"
    local oldShield = rawget(sheet, "shield")
    sheet.shield = oldShield == "SMALL" or oldShield == "LARGE"

    -- Class resource and custom counter become ordinary resources.
    local resourceName = rawget(sheet, "resourceName") or "Energy"
    local counterName = rawget(sheet, "counterName") or ""
    local counterMax = rawget(sheet, "counterMax") or 0
    local resources = {}
    local resourceMax = math.max(0, mod(rawget(sheet, "resourceStat") or "STR") * mod("CON") * 2)
    if resourceMax > 0 and resourceName ~= "" then
        resources[#resources + 1] = { name = resourceName, flat = resourceMax, stat = "", times = 1, startEmpty = false }
        state.res[resourceName] = rawget(state, "resource")
    end
    if counterMax > 0 and counterName ~= "" then
        resources[#resources + 1] = { name = counterName, flat = counterMax, stat = "", times = 1, startEmpty = true }
        state.res[counterName] = rawget(state, "counter")
    end
    sheet.resources = resources

    for _, weapon in pairs(sheet.weapons) do
        if type(weapon) == "table" then
            local old = OLD_WEAPON[weapon.kind or "ONE"]
            if old then weapon.dice, weapon.sides, weapon.heal = old[1], old[2], old[3] or false end
            weapon.kind = nil
            weapon.proficient = false -- the old rules had no proficiency bonus
        end
    end

    for _, ability in pairs(sheet.abilities) do
        if type(ability) == "table" and not ability.actions then
            local actions = {}
            if (ability.cost or 0) > 0 then
                actions[#actions + 1] = {
                    type = "SPEND", resource = resourceName, amount = ability.cost,
                    freeIfFull = ability.usesCounter and counterName or "",
                }
            end
            if R.STAT_NAMES[ability.stat1] then
                actions[#actions + 1] = {
                    type = "ROLL", kind = (ability.weaponDamage or 0) > 0 and "ATTACK" or "CHECK",
                    stat = ability.stat1, stat2 = R.STAT_NAMES[ability.stat2] and ability.stat2 or "", proficient = false,
                }
            end
            if (ability.weaponDamage or 0) > 0 then
                actions[#actions + 1] = { type = "WEAPON", times = ability.weaponDamage }
            end
            if ability.usesCounter and counterName ~= "" then
                actions[#actions + 1] = { type = "EMPTY", resource = counterName }
            end
            ability.actions = actions
            ability.cost, ability.stat1, ability.stat2, ability.weaponDamage, ability.usesCounter = nil, nil, nil, nil, nil
        end
    end

    for _, passive in pairs(sheet.passives) do
        if type(passive) == "table" then
            passive.effects = passive.effects or {}
            if (passive.skill or "") ~= "" and R.STAT_NAMES[passive.stat] then
                table.insert(passive.effects, { target = "SKILL:" .. passive.skill, flat = 0, stat = passive.stat, times = 1 })
            end
            passive.skill, passive.stat = nil, nil
        end
    end
    local acBonus = rawget(sheet, "acBonus")
    if type(acBonus) == "number" and acBonus ~= 0 then
        table.insert(sheet.passives, {
            name = "AC bonus", desc = "", enabled = true,
            effects = { { target = "AC", flat = acBonus, stat = "", times = 1 } },
        })
    end

    for _, key in ipairs({ "resourceName", "resourceStat", "counterName", "counterMax", "acBonus" }) do
        sheet[key] = nil
    end
    sheet.scoreMethod = "MANUAL" -- old sheets could spend 27 + 3 points
    sheet.version = 2
    state.resource, state.counter, state.initialized = nil, nil, nil
    state.created = true
end

local function Any() return true end

-- Converts old versions, then makes sure every list is a clean array and every
-- choice still names something that exists in the rules data.
function ns.NormalizeState(state)
    if rawget(state, "initialized") ~= nil or rawget(state.sheet, "resourceStat") ~= nil then
        MigrateV1(state)
    end
    if type(state.conditions) ~= "table" then state.conditions = {} end
    state.exhaustion = tonumber(state.exhaustion) or 0
    local sheet = state.sheet
    sheet.extraLanguages = tonumber(sheet.extraLanguages) or 0
    if type(sheet.asi) ~= "table" then sheet.asi = {} end
    for _, stat in ipairs(R.STATS) do sheet.asi[stat] = tonumber(sheet.asi[stat]) or 0 end
    -- Choices are kept per level (see Sheet/Levels.lua); the totals follow from them.
    ns.Levels.Migrate(sheet)
    ns.Levels.Recompute(sheet)
    for _, key in ipairs({ "dismissed", "languages", "renown", "traitChoices", "traitGranted", "maneuvers", "featureSkills", "featureSkillGranted", "featureScores", "featureOptions", "picks", "expertise", "expertiseGranted", "featSkills", "featSkillGranted", "tools", "spellbook" }) do
        if type(sheet[key]) ~= "table" then sheet[key] = {} end
    end
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
    end
    sheet.lineage, sheet.allegiance = sheet.lineage or "", sheet.allegiance or ""
    Util.NormalizeList(sheet.resources, R.TEMPLATES.resource)
    Util.NormalizeList(sheet.weapons, R.TEMPLATES.weapon)
    Util.NormalizeList(sheet.abilities, R.TEMPLATES.ability)
    Util.NormalizeList(sheet.passives, R.TEMPLATES.passive)
    if type(sheet.spells) ~= "table" then sheet.spells = {} end
    Util.NormalizeList(sheet.spells, R.TEMPLATES.spell)
    for _, ability in ipairs(sheet.abilities) do
        Util.NormalizeList(ability.actions, R.TEMPLATES.action, Any)
        for _, action in ipairs(ability.actions) do
            if not R.ACTIONS[action.type] then action.type = "ROLL" end
        end
    end
    for _, passive in ipairs(sheet.passives) do
        -- Earlier versions pointed to the rulebook; say what the trait or feat does instead.
        local origin, pointed = passive.desc:gsub("%s*See the book for what it does%.", "")
        if pointed > 0 then
            local summary = ns.Glossary[passive.name]
            passive.desc = summary and (origin .. " " .. summary) or origin
        end
        Util.NormalizeList(passive.effects, R.TEMPLATES.effect, Any)
        for i = #passive.effects, 1, -1 do
            if not R.EFFECT_TARGETS[passive.effects[i].target] then table.remove(passive.effects, i) end
        end
    end
    if not R.ARMOR[sheet.armor] then sheet.armor = "NONE" end
    if type(sheet.shield) ~= "boolean" then sheet.shield = false end
    if not R.CLASSES[sheet.class] then sheet.class = "" end
    if not R.SPECIES[sheet.species] then sheet.species = "" end
    if not R.BACKGROUNDS[sheet.background] then sheet.background = "" end
    sheet.level = math.max(1, math.min(R.MAX_LEVEL, tonumber(sheet.level) or 1))
end
