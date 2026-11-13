-- Puts the class and subclass features for the character's level on the sheet
-- (see Data/Features.lua and Data/SubclassFeatures.lua) and keeps their
-- level-dependent numbers up to date.
--
-- An entry added here is marked with `auto`, a key naming the feature. That is how it
-- is found again to refresh it. Deleting such an entry in the editor records the key
-- in sheet.dismissed, so it doesn't come back on the next level change.
local _, ns = ...
local R = ns.Rules

local function FindAuto(list, key)
    for _, entry in ipairs(list) do
        if entry.auto == key then return entry end
    end
end

-- A feature's effects or actions may be a fixed table or a function of the level.
local function Resolve(value, level)
    if type(value) == "function" then value = value(level) end
    return CopyTable(value or {})
end

local function Key(prefix, feature)
    return ("%s:%s:%s"):format(prefix, feature.kind, feature.name)
end

-- Calls visit(feature, key) for every feature the character has right now: reached by
-- level, not deleted by the player, and not replaced by its World of Warcraft class.
local function EachFeature(sheet, visit)
    local class = R.CLASSES[sheet.class]
    if not class then return end
    local override = R.CLASS_OVERRIDES[sheet.class] or {}
    local replaced = {}
    for _, name in ipairs(override.remove or {}) do replaced[name] = true end

    local sources = {
        { "class", R.FEATURES[class.base], replaced },
        { "class", override.features },
        { "subclass", R.SUBCLASS_FEATURES[sheet.subclass] },
    }
    for _, source in ipairs(sources) do
        local prefix, features, skip = source[1], source[2], source[3]
        for _, feature in ipairs(features or {}) do
            local key = Key(prefix, feature)
            if sheet.level >= feature.level and not sheet.dismissed[key] and not (skip and skip[feature.name]) then
                visit(feature, key)
            end
        end
    end
end

-- Adds a feature to the sheet, or refreshes the one already there.
local function Apply(sheet, feature, key)
    local isAbility = feature.kind == "ability"
    local list = isAbility and sheet.abilities or sheet.passives
    local entry = FindAuto(list, key)
    if not entry then
        entry = { name = feature.name, auto = key }
        if not isAbility then entry.enabled = not feature.startsOff end
        list[#list + 1] = entry
    end
    -- Refreshed every time, so dice and bonuses follow the level.
    entry.desc = feature.desc
    if isAbility then
        entry.actions = Resolve(feature.actions, sheet.level)
    else
        entry.effects = Resolve(feature.effects, sheet.level)
    end
    for _, skill in ipairs(feature.skills or {}) do
        sheet.skills[skill] = math.max(sheet.skills[skill] or 0, 1)
    end
end

function ns.ApplyClassFeatures(sheet)
    local current = {}
    EachFeature(sheet, function(_, key) current[key] = true end)

    -- Class and subclass entries the character no longer has are taken off the sheet:
    -- another subclass's, another class's, or ones a newer version replaced.
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local auto = list[index].auto or ""
            if (auto:find("^class:") or auto:find("^subclass:")) and not current[auto] then
                table.remove(list, index)
            end
        end
    end

    EachFeature(sheet, function(feature, key) Apply(sheet, feature, key) end)
end

-- Resources that come with features of their own (see Kit.Limited in Data/FeatureKit.lua),
-- in the same form as class `pools`.
function ns.FeaturePools(sheet)
    local pools = {}
    EachFeature(sheet, function(feature)
        if feature.pool then pools[#pools + 1] = feature.pool end
    end)
    return pools
end

-- The features a character of this class and subclass gains on reaching `level`.
function ns.FeaturesGainedAt(class, subclass, level)
    local gained = {}
    EachFeature({ class = class, subclass = subclass, level = level, dismissed = {} }, function(feature)
        if feature.level == level then gained[#gained + 1] = feature end
    end)
    return gained
end

-- Called when an entry is deleted in the editor.
function ns.DismissAuto(sheet, entry)
    if entry.auto and entry.auto ~= "" then
        sheet.dismissed[entry.auto] = true
    end
end
