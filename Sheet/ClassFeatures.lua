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

-- Adds or refreshes every feature in `features` the character's level has reached.
-- `prefix` ("class" or "subclass") keeps the two sets of keys apart.
-- `skip` is a set of feature names to leave out.
local function Apply(sheet, features, prefix, skip)
    for _, feature in ipairs(features or {}) do
        local key = ("%s:%s:%s"):format(prefix, feature.kind, feature.name)
        if sheet.level >= feature.level and not sheet.dismissed[key] and not (skip and skip[feature.name]) then
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
    end
end

-- Features of a subclass the character no longer has are taken off the sheet.
local function RemoveOtherSubclass(sheet, features)
    local current = {}
    for _, feature in ipairs(features or {}) do
        current[("subclass:%s:%s"):format(feature.kind, feature.name)] = true
    end
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local auto = list[index].auto or ""
            if auto:find("^subclass:") and not current[auto] then table.remove(list, index) end
        end
    end
end

function ns.ApplyClassFeatures(sheet)
    local class = R.CLASSES[sheet.class]
    local subclass = R.SUBCLASS_FEATURES[sheet.subclass]
    RemoveOtherSubclass(sheet, subclass)
    if not class then return end

    -- A World of Warcraft class can replace some of its base class's features.
    local override = R.CLASS_OVERRIDES[sheet.class] or {}
    local replaced = {}
    for _, name in ipairs(override.remove or {}) do replaced[name] = true end
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local kind, name = (list[index].auto or ""):match("^class:(%a+):(.+)$")
            if kind and replaced[name] then table.remove(list, index) end
        end
    end

    Apply(sheet, R.FEATURES[class.base], "class", replaced)
    Apply(sheet, override.features, "class")
    Apply(sheet, subclass, "subclass")
end

-- Called when an entry is deleted in the editor.
function ns.DismissAuto(sheet, entry)
    if entry.auto and entry.auto ~= "" then
        sheet.dismissed[entry.auto] = true
    end
end
