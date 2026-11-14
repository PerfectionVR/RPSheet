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
local function Resolve(value, level, sheet)
    if type(value) == "function" then value = value(level, sheet) end
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
            local specFits = not feature.spec or feature.spec == sheet.spec -- some belong to one specialization
            -- ...and some to one option of a choice the character made.
            if feature.option and (sheet.featureOptions or {})[feature.option[1]] ~= feature.option[2] then specFits = false end
            if feature.when and not feature.when(sheet) then specFits = false end
            if sheet.level >= feature.level and specFits and not sheet.dismissed[key] and not (skip and skip[feature.name]) then
                visit(feature, key)
            end
        end
    end
end

-- The option the character picked for a feature that offers a choice, or nil.
local function PickedOption(sheet, feature)
    local picked = (sheet.featureOptions or {})[feature.name]
    for _, option in ipairs(feature.options or {}) do
        if option.name == picked then return option end
    end
end

-- Adds a feature to the sheet, or refreshes the one already there.
local function Apply(sheet, feature, key)
    -- A choice shows what was picked, and takes its effects from the pick.
    local base = feature
    if feature.options then
        local option = PickedOption(sheet, feature)
        local names = {}
        for _, each in ipairs(feature.options) do names[#names + 1] = each.name end
        feature = setmetatable({
            name = feature.name, level = feature.level, kind = feature.kind,
            desc = option and option.desc or ((type(feature.desc) == "string" and feature.desc or "")
                .. " Options: " .. table.concat(names, ", ") .. ". Not chosen yet: pick it on the Character tab or under Customize, Class and origin."),
            shown = option and (feature.name .. ": " .. option.name) or feature.name,
        }, { __index = option or {} })
    end
    local isAbility = feature.kind == "ability"
    local list = isAbility and sheet.abilities or sheet.passives
    local entry = FindAuto(list, key)
    if not entry then
        entry = { name = base.name, auto = key }
        if not isAbility then entry.enabled = not feature.startsOff end
        list[#list + 1] = entry
    end
    -- Refreshed every time, so dice and bonuses follow the level.
    -- Some features read differently for each specialization.
    if feature.shown then entry.name = feature.shown end
    entry.training = feature.training and CopyTable(feature.training) or nil
    local desc = feature.bySpec and feature.bySpec[sheet.spec] or feature.desc
    if type(desc) == "function" then desc = desc(sheet.level, sheet) end -- wording that follows the character
    entry.desc = desc
    -- Rolls the feature gives advantage on (see RPSheet:HasAdvantage).
    local advantage = feature.advantage
    if type(advantage) == "function" then advantage = advantage(sheet.level, sheet) end
    entry.advantage = advantage and CopyTable(advantage) or nil
    entry.flags = feature.flags and CopyTable(feature.flags) or nil
    entry.limit = feature.limit -- armor that stops it (see Sheet/Limits.lua)
    entry.strike = feature.strike and CopyTable(feature.strike) or nil
    for _, stat in ipairs(feature.saves or {}) do sheet.saves[stat] = true end
    for stat, points in pairs(feature.scores or {}) do
        sheet.featureScores[stat] = (sheet.featureScores[stat] or 0) + points
    end
    if isAbility then
        entry.actions = Resolve(feature.actions, sheet.level, sheet)
    else
        entry.effects = Resolve(feature.effects, sheet.level, sheet)
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

    sheet.featureScores = {} -- worked out again from the features the character has
    EachFeature(sheet, function(feature, key) Apply(sheet, feature, key) end)
    ns.ApplyFightingStyles(sheet)
    ns.ApplyManeuvers(sheet)
    ns.ApplyPicks(sheet)
    ns.ApplyBeastForms(sheet)
    ns.ApplyToolPicks(sheet)
    ns.ApplyFeatureSkills(sheet)
    ns.ApplyFeatSkills(sheet)
    ns.ApplyExpertise(sheet)
    ns.ApplySpellPicks(sheet)
    ns.ApplyPreparedPicks(sheet) -- before the always-prepared spells: a pick makes way for one
    ns.ApplyPreparedSpells(sheet)
    ns.ApplySpellbook(sheet)
    ns.ApplySpellChoices(sheet) -- after the spellbook: some are chosen from it
end

-- The features of the character that offer a choice between options, in level order.
-- `sheet` may be a stand-in with class, subclass, level and featureOptions.
function ns.OptionFeatures(sheet)
    local found = {}
    EachFeature(setmetatable({ dismissed = {} }, { __index = sheet }), function(feature)
        if feature.options then found[#found + 1] = feature end
    end)
    table.sort(found, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    return found
end

-- Those whose choice hasn't been made.
function ns.OpenOptionFeatures(sheet)
    local open = {}
    for _, feature in ipairs(ns.OptionFeatures(sheet)) do
        if not PickedOption(sheet, feature) then open[#open + 1] = feature end
    end
    return open
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
