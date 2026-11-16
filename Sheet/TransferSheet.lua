-- Importing a character: a fresh sheet built field by field from one that came from
-- outside, keeping only known fields of the right type.
local _, ns = ...
local R = ns.Rules
local Text = ns.TransferKit.Text
local Number = ns.TransferKit.Number
local CleanList = ns.TransferKit.CleanList
local CleanChoices = ns.TransferKit.CleanChoices

local function CleanSheet(source)
    local sheet = ns.NewSheet()
    for key, default in pairs(sheet) do
        local kind = type(default)
        if kind == "string" then
            sheet[key] = Text(source[key], 60)
        elseif kind == "number" then
            sheet[key] = Number(source[key], key, default)
        elseif kind == "boolean" then
            sheet[key] = source[key] == true
        end
    end
    sheet.version = 2
    if not R.SCORE_METHODS[sheet.scoreMethod] then sheet.scoreMethod = "MANUAL" end
    if not R.SIZE_NAMES[sheet.size] then sheet.size = "M" end

    local base, bonus = type(source.base) == "table" and source.base or {}, type(source.bonus) == "table" and source.bonus or {}
    for _, stat in ipairs(R.STATS) do
        sheet.base[stat] = math.max(1, math.min(30, Number(base[stat], "score", R.BASE_MIN)))
        sheet.bonus[stat] = math.max(0, math.min(R.BONUS_MAX, Number(bonus[stat], "score", 0)))
        sheet.asi[stat] = math.max(0, math.min(12, Number(type(source.asi) == "table" and source.asi[stat], "score", 0)))
    end
    -- Absent in strings from older versions: the totals above are then spread over levels.
    sheet.levels = ns.Levels.Clean(source.levels)
    -- Classes taken after the first (Sheet/Classes.lua).
    sheet.classes = ns.CleanClasses(source.classes)
    ns.NormalizeClasses(sheet)
    if type(source.skills) == "table" then
        for _, skill in ipairs(R.SKILLS) do
            local rank = tonumber(source.skills[skill.name])
            if rank == 1 or rank == 2 then sheet.skills[skill.name] = rank end
        end
    end
    if type(source.saves) == "table" then
        for _, stat in ipairs(R.STATS) do
            if source.saves[stat] == true then sheet.saves[stat] = true end
        end
    end

    if type(source.languages) == "table" then
        for _, language in ipairs(R.ALL_LANGUAGES) do
            if source.languages[language] == true then sheet.languages[language] = true end
        end
    end
    if type(source.renown) == "table" then
        for _, faction in ipairs(R.ALL_FACTIONS) do
            local score = Number(source.renown[faction], "renown", 0)
            if score > 0 then sheet.renown[faction] = math.min(100, score) end
        end
    end
    -- The highest tier each faction ever reached: only a tier's own lowest score is a
    -- valid record. A string from before the record brings none, and the scores set it.
    sheet.renownReached = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        local reached = type(source.renownReached) == "table" and tonumber(source.renownReached[faction])
        for _, tier in ipairs(R.RENOWN_TIERS) do
            if reached == tier[1] then sheet.renownReached[faction] = reached end
        end
    end
    -- What a faction's trainers taught, and what that added to the sheet.
    for _, field in ipairs({ "renownTraining", "renownGranted" }) do
        sheet[field] = {}
        for _, faction in ipairs(R.ALL_FACTIONS) do
            local pick = type(source[field]) == "table" and source[field][faction]
            if type(pick) == "string" then sheet[field][faction] = Text(pick, 60) end
        end
    end
    CleanChoices(sheet, source) -- Sheet/TransferChoices.lua

    sheet.resources = CleanList(source.resources, R.TEMPLATES.resource)
    sheet.weapons = CleanList(source.weapons, R.TEMPLATES.weapon)
    sheet.abilities = CleanList(source.abilities, R.TEMPLATES.ability, "actions", R.TEMPLATES.action)
    sheet.passives = CleanList(source.passives, R.TEMPLATES.passive, "effects", R.TEMPLATES.effect)
    sheet.spells = CleanList(source.spells, R.TEMPLATES.spell)
    sheet.items = CleanList(source.items, R.TEMPLATES.item, "effects", R.TEMPLATES.effect)
    ns.NormalizeInventory(sheet, source) -- coins, and weights that are fractions
    sheet.mounts = CleanList(source.mounts, R.TEMPLATES.mount)
    ns.NormalizeMounts(sheet)
    ns.NormalizeProfessions(sheet, source) -- gathered materials, fragments, learned recipes
    -- A spell's level and dice count may be 0, unlike the character level and other dice.
    for index, spell in ipairs(sheet.spells) do
        local original = source.spells[index]
        spell.level = math.max(0, math.min(9, math.floor(tonumber(original.level) or 0)))
        spell.count = math.max(0, math.min(40, math.floor(tonumber(original.count) or 0)))
        if not R.DAMAGE_TYPE[spell.damage] then spell.damage = "" end
    end
    -- A damage type is one of the known ones or not set.
    for _, ability in ipairs(sheet.abilities) do
        for _, action in ipairs(ability.actions) do
            if not R.DAMAGE_TYPE[action.damage] then action.damage = "" end
        end
    end
    return sheet
end

ns.TransferKit.CleanSheet = CleanSheet
