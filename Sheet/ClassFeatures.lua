-- Puts the class and subclass features for the character's level on the sheet
-- (see Data/Features.lua and Data/SubclassFeatures.lua) and keeps their
-- level-dependent numbers up to date.
--
-- An entry added here is marked with `auto`, a key naming the feature. That is how it
-- is found again to refresh it. Deleting such an entry in the editor records the key
-- in sheet.dismissed, so it doesn't come back on the next level change.
local _, ns = ...
local R = ns.Rules

local FindAuto = ns.Util.FindAuto

-- A feature's effects or actions may be a fixed table or a function of the level.
local function Resolve(value, level, sheet)
    if type(value) == "function" then value = value(level, sheet) end
    return CopyTable(value or {})
end

-- "Your level" in a class feature is the level in that class. A character of one
-- class leaves it to the sheet (RPSheet:Amount); for one class of several the number
-- is written out, as the sheet only knows the whole character's level.
local function ClassLevels(steps, sheet)
    if not sheet.viewOf then return steps end
    for _, step in ipairs(steps) do
        if step.stat == "LEVEL" and (step.type == nil or step.type == "DICE") then
            local times = step.type == nil and step.times or 1
            step.flat, step.stat = (step.flat or 0) + (times or 1) * sheet.level, ""
        end
    end
    return steps
end

local function Key(prefix, feature)
    return ("%s:%s:%s"):format(prefix, feature.kind, feature.name)
end

-- Calls visit(feature, key, sheet) for every feature one class gives right now: reached
-- by its level, not deleted by the player, and not replaced by its World of Warcraft
-- class. `sheet` is a character of one class, or a view of one class of a character.
local function EachClassFeature(sheet, visit)
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
                visit(feature, key, sheet)
            end
        end
    end
end

-- The same for every class of the character, each by its own level.
local function EachFeature(sheet, visit)
    for _, view in ipairs(ns.ClassViews(sheet)) do EachClassFeature(view, visit) end
end

-- A feature may be a fixed text or follow the level.
local function Scales(feature)
    return type(feature.desc) == "function" or type(feature.effects) == "function" or type(feature.actions) == "function"
end

-- Two classes can give a feature of the same name (Extra Attack, Unarmored Defense).
-- They don't add up: the sheet shows one, the one that grows with its class's level
-- or else the one of the class with the most levels.
local function Outranks(feature, view, best)
    if Scales(feature) ~= Scales(best.feature) then return Scales(feature) end
    return view.level > best.view.level
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
    entry.martial = feature.martial or nil -- proficiency with martial weapons (Sheet/Armoury.lua)
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
    entry.tools = feature.tools and CopyTable(feature.tools) or nil -- tool proficiencies (Sheet/ToolPicks.lua)
    if not isAbility then ns.CopyDefenses(entry, feature, sheet) end -- damage it resists and the like
    for _, stat in ipairs(feature.saves or {}) do sheet.saves[stat] = true end
    for stat, points in pairs(feature.scores or {}) do
        sheet.featureScores[stat] = (sheet.featureScores[stat] or 0) + points
    end
    if isAbility then
        entry.actions = ClassLevels(Resolve(feature.actions, sheet.level, sheet), sheet)
    else
        entry.effects = ClassLevels(Resolve(feature.effects, sheet.level, sheet), sheet)
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
    local chosen = {}
    EachFeature(sheet, function(feature, key, view)
        local best = chosen[key]
        if not best or (best.view ~= view and Outranks(feature, view, best)) then chosen[key] = { feature = feature, view = view } end
    end)
    EachFeature(sheet, function(feature, key, view)
        if chosen[key].view == view then Apply(view, feature, key) end
    end)
    ns.ApplyFightingStyles(sheet)
    ns.ApplyManeuvers(sheet)
    ns.ApplyPicks(sheet)
    ns.ApplyLessonFeats(sheet) -- an invocation's origin feat (Sheet/LessonFeats.lua)
    ns.ApplyBeastForms(sheet)
    ns.ApplyToolPicks(sheet)
    ns.ApplyFeatureSkills(sheet)
    ns.ApplyFeatSkills(sheet)
    ns.ApplyFeatChoices(sheet) -- before expertise: a feat's skill can be picked for it
    ns.ApplyFeatTools(sheet)   -- after the feats' own tools: one isn't picked twice
    ns.ApplyExpertise(sheet)
    ns.ApplySpellPicks(sheet)
    ns.ApplyPreparedPicks(sheet) -- before the always-prepared spells: a pick makes way for one
    ns.ApplyPreparedSpells(sheet)
    ns.ApplySpellbook(sheet)
    ns.ApplySpellChoices(sheet) -- after the spellbook: some are chosen from it
    ns.ApplyInvocationSpells(sheet) -- an invocation's spell, and Agonizing Blast on a cantrip
    ns.ApplyFeatSpells(sheet)   -- last: a spell the class prepares isn't listed twice
    ns.ApplyWards(sheet)        -- spell protection that is running, and a feat's situation passive
    ns.ApplyRenownPerks(sheet)  -- here, so a blessing's score points follow the reset above
end

-- The features of the character that offer a choice between options, in level order.
-- `sheet` may be a stand-in with class, subclass, level and featureOptions, or a view
-- of one class.
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
-- in the same form as class `pools`. Asked per class (a view) by a character with
-- several, as each grows with its own class's level.
function ns.FeaturePools(sheet)
    local pools = {}
    EachFeature(sheet, function(feature)
        if feature.pool then pools[#pools + 1] = feature.pool end
    end)
    return pools
end

-- The features a character of this class and subclass gains on reaching `level`.
-- The answer comes from the rules data alone, which doesn't change while the game runs,
-- and it is asked for hundreds of times when a level dialog opens: each list is made
-- once and kept. Don't change the list that comes back.
local gainedAt = {}
function ns.FeaturesGainedAt(class, subclass, level)
    local id = ("%s|%s|%s"):format(tostring(class), tostring(subclass), tostring(level))
    local gained = gainedAt[id]
    if gained then return gained end
    gained = {}
    EachFeature({ class = class, subclass = subclass, level = level, dismissed = {} }, function(feature)
        if feature.level == level then gained[#gained + 1] = feature end
    end)
    gainedAt[id] = gained
    return gained
end

-- The features one class of a character gains on reaching `level` of that class, for
-- this character: those that hang on its specialization, on an option it picked or on
-- something else of the sheet (the kind of beast its companion is) are counted only
-- when they apply. `view` is the character of one class or a view of one class (it
-- may carry options picked but not yet saved, in featureOptions); the features it
-- deleted are listed all the same. Worked out on every call: nothing is kept.
function ns.FeaturesGainedFor(view, level)
    local gained = {}
    local like = setmetatable({ level = level, dismissed = {} }, { __index = view })
    EachClassFeature(like, function(feature)
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
