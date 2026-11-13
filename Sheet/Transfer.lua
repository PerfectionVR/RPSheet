-- Exporting a character as a text string and importing one.
-- An imported string comes from someone else, so nothing in it is trusted: a fresh
-- sheet is built field by field, keeping only known fields of the right type, with
-- text stripped of colour codes and numbers kept inside sane limits.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Codec = ns.Codec

local PREFIX = "!RPS1!" -- marks an RP Sheet export, format 1
local MAX_ENTRIES = 100 -- per list
local MAX_STEPS = 30    -- effects per passive, steps per ability

-- Limits for numeric fields, by field name. Anything not listed is kept within -999..999.
local LIMITS = {
    level = { 1, R.MAX_LEVEL }, hpAdjust = { -100, 100 },
    dice = { 1, 20 }, count = { 1, 20 }, sides = { 2, 100 },
    times = { 1, 10 }, amount = { 0, 999 }, flat = { -200, 200 },
}

local function Text(value, maxLength)
    if type(value) ~= "string" then return "" end
    return (value:gsub("[|%c]", "")):sub(1, maxLength)
end

local function Number(value, key, default)
    value = tonumber(value)
    if not value or value ~= value then return default end
    local limit = LIMITS[key]
    local low, high = limit and limit[1] or -999, limit and limit[2] or 999
    return math.floor(math.max(low, math.min(high, value)))
end

-- A copy of `source` holding exactly the scalar fields of `template`.
local function CleanEntry(source, template)
    local clean = {}
    for key, default in pairs(template) do
        local kind = type(default)
        if kind == "string" then
            clean[key] = Text(source[key], key == "desc" and 600 or 60)
        elseif kind == "number" then
            clean[key] = Number(source[key], key, default)
        elseif kind == "boolean" then
            clean[key] = source[key] == true
        end
    end
    return clean
end

-- `nested` names a list inside each entry (effects or actions) and its template.
local function CleanList(source, template, nested, nestedTemplate)
    local clean = {}
    if type(source) ~= "table" then return clean end
    for i = 1, MAX_ENTRIES do
        local entry = source[i]
        if type(entry) ~= "table" then break end
        local copy = CleanEntry(entry, template)
        if nested then
            copy[nested] = {}
            if type(entry[nested]) == "table" then
                for j = 1, MAX_STEPS do
                    if type(entry[nested][j]) ~= "table" then break end
                    copy[nested][j] = CleanEntry(entry[nested][j], nestedTemplate)
                end
            end
        end
        clean[i] = copy
    end
    return clean
end

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
    if not R.ALLEGIANCES[sheet.allegiance] then sheet.allegiance = "" end

    sheet.resources = CleanList(source.resources, R.TEMPLATES.resource)
    sheet.weapons = CleanList(source.weapons, R.TEMPLATES.weapon)
    sheet.abilities = CleanList(source.abilities, R.TEMPLATES.ability, "actions", R.TEMPLATES.action)
    sheet.passives = CleanList(source.passives, R.TEMPLATES.passive, "effects", R.TEMPLATES.effect)
    sheet.spells = CleanList(source.spells, R.TEMPLATES.spell)
    -- A spell's level and dice count may be 0, unlike the character level and other dice.
    for index, spell in ipairs(sheet.spells) do
        local original = source.spells[index]
        spell.level = math.max(0, math.min(9, math.floor(tonumber(original.level) or 0)))
        spell.count = math.max(0, math.min(40, math.floor(tonumber(original.count) or 0)))
    end
    return sheet
end

---------------------------------------------------------------------------
-- Export and import
---------------------------------------------------------------------------
-- The active character as one line of text. Current HP and resources are not included.
function RPSheet:ExportSheet()
    return PREFIX .. Codec.Pack("print", { format = 1, name = self:GetCharacterName(), sheet = self:Sheet() })
end

-- Reads an export string. Returns a clean sheet and the exported name, or nil and
-- a message saying what is wrong with the text.
function RPSheet:DecodeSheet(text)
    text = (text or ""):gsub("%s+", "")
    if text == "" then return nil, "Paste an export string first." end
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "This is not an RP Sheet export string. It should start with " .. PREFIX
    end
    local ok, payload = Codec.Unpack("print", text:sub(#PREFIX + 1))
    if not ok or type(payload) ~= "table" or type(payload.sheet) ~= "table" then
        return nil, "The string is damaged or incomplete. Copy the whole thing and try again."
    end
    if payload.format ~= 1 then
        return nil, "This string was made by a newer version of RP Sheet. Update the addon to import it."
    end
    return CleanSheet(payload.sheet), Text(payload.name, 40)
end

-- One line describing a sheet that isn't the active one, e.g. "Level 3 Rogue, Human".
function RPSheet:DescribeSheet(sheet)
    local class, species = R.CLASSES[sheet.class], R.SPECIES[sheet.species]
    local parts = { ("Level %d %s"):format(sheet.level, class and class.name or "character without a class") }
    if species then parts[#parts + 1] = species.name end
    parts[#parts + 1] = ("%d abilities, %d passives"):format(#sheet.abilities, #sheet.passives)
    return table.concat(parts, ", ")
end
