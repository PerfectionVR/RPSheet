-- Importing a character: cleaning text, numbers and list entries that came from outside.
-- Nothing in an import string is trusted (see Sheet/Transfer.lua).
local _, ns = ...
local R = ns.Rules

local MAX_ENTRIES = 100 -- per list
local MAX_STEPS = 30    -- effects per passive, steps per ability

-- Limits for numeric fields, by field name. Anything not listed is kept within -999..999.
local LIMITS = {
    level = { 1, R.MAX_LEVEL }, hpAdjust = { -100, 100 },
    dice = { 1, 20 }, sides = { 1, 100 },
    count = { 0, 20 }, -- an ability's dice step with 0 dice gives just its flat amount
    times = { 1, 10 }, amount = { 0, 999 }, flat = { -200, 200 },
    magic = { 0, 3 }, qty = { 0, 9999 }, cost = { 0, 99999999 },
    capacity = { 0, 999999 }, loyalty = { 0, R.LOYALTY_MAX }, load = { 0, 999999 },
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

-- One weapon from outside, cleaned the same way (a shared weapon, Sheet/WeaponShare.lua).
function ns.CleanWeapon(source)
    return CleanEntry(source, R.TEMPLATES.weapon)
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

ns.TransferKit = { Text = Text, Number = Number, CleanEntry = CleanEntry, CleanList = CleanList }
