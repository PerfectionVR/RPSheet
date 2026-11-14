-- Choices a class or subclass feature asks for beyond the level's own:
--   * the maneuvers a Battle Master knows (sheet.maneuvers[<name>] = true), each a
--     clickable ability marked auto = "maneuver:<name>";
--   * a skill a feature lets the character pick (sheet.featureSkills[<feature>]), such
--     as Student of War. The skill it made proficient is kept in
--     sheet.featureSkillGranted so it can be taken back.
-- Data in Data/Maneuvers.lua; the choosing happens in Options/LevelDialog.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

local PREFIX = "maneuver:"

local Mod = Kit.Mod

---------------------------------------------------------------------------
-- Maneuvers
---------------------------------------------------------------------------
-- How many maneuvers a character of this subclass and level knows; 0 for anyone else.
function ns.ManeuverLimit(subclass, level)
    if subclass ~= "Battle Master" then return 0 end
    return Kit.AtLevel(level, R.MANEUVERS_KNOWN) or 0
end

function ns.ManeuversKnown(sheet)
    local count = 0
    for name in pairs(sheet.maneuvers) do
        if R.MANEUVERS[name] then count = count + 1 end
    end
    return count
end

-- Puts the chosen maneuvers on the sheet as abilities, with the die and save DC of
-- the character's level, and takes off those no longer chosen.
function ns.ApplyManeuvers(sheet)
    local limit = ns.ManeuverLimit(sheet.subclass, sheet.level)
    local wanted = {}
    if limit > 0 then
        for name in pairs(sheet.maneuvers) do
            if R.MANEUVERS[name] and not sheet.dismissed[PREFIX .. name] then wanted[PREFIX .. name] = name end
        end
    end
    for index = #sheet.abilities, 1, -1 do
        local auto = sheet.abilities[index].auto or ""
        if auto:find("^" .. PREFIX) and not wanted[auto] then table.remove(sheet.abilities, index) end
    end

    local die = Kit.AtLevel(sheet.level, R.SUPERIORITY_DIE) or 8
    local best = math.max(Mod(sheet, "STR"), Mod(sheet, "DEX"))
    local dc = 8 + best + math.ceil(sheet.level / 4) + 1
    for key, name in pairs(wanted) do
        local maneuver, ability = R.MANEUVERS[name], nil
        for _, entry in ipairs(sheet.abilities) do
            if entry.auto == key then ability = entry end
        end
        if not ability then
            ability = { name = name, auto = key }
            sheet.abilities[#sheet.abilities + 1] = ability
        end
        local flat = (maneuver.add == "BEST" and best) or (maneuver.add == "HALFLEVEL" and math.floor(sheet.level / 2)) or 0
        ability.actions = { Kit.Spend("Superiority Dice"), Kit.Dice(1, die, "", maneuver.dice, flat) }
        ability.desc = "Maneuver. " .. maneuver.desc
        if maneuver.save then
            ability.desc = ("%s %s save DC %d."):format(ability.desc, R.STAT_NAMES[maneuver.save], dc)
        end
    end
end

---------------------------------------------------------------------------
-- A skill picked for a feature
---------------------------------------------------------------------------
-- Features of the character that let it pick a skill, as { name = feature }.
local function SkillFeatures(sheet)
    local found = {}
    for level = 1, sheet.level do
        for _, feature in ipairs(ns.FeaturesGainedAt(sheet.class, sheet.subclass, level)) do
            if feature.skillChoice then found[feature.name] = feature end
        end
    end
    return found
end

-- Names of those features, sorted.
function ns.SkillChoiceFeatures(sheet)
    local names = {}
    for name in pairs(SkillFeatures(sheet)) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- Skills that can be picked for a feature: from its list, not yet proficient.
-- `skillChoice = "CLASS"` means the class's own skill list.
function ns.FeatureSkillOptions(sheet, featureName)
    local feature = SkillFeatures(sheet)[featureName]
    local class = R.CLASSES[sheet.class]
    local pool = feature and (feature.skillChoice == "CLASS" and class and class.skills or feature.skillChoice) or {}
    local current, names = sheet.featureSkills[featureName], {}
    for _, skill in ipairs(type(pool) == "table" and pool or {}) do
        if skill == current or (sheet.skills[skill] or 0) == 0 then names[#names + 1] = skill end
    end
    return names
end

-- Features whose skill hasn't been picked.
function ns.OpenFeatureSkills(sheet)
    local open = {}
    for _, name in ipairs(ns.SkillChoiceFeatures(sheet)) do
        if (sheet.featureSkills[name] or "") == "" then open[#open + 1] = name end
    end
    return open
end

-- Makes the picked skills proficient, and gives back ones that are no longer picked
-- or whose feature the character lost.
function ns.ApplyFeatureSkills(sheet)
    local features = SkillFeatures(sheet)
    for name, skill in pairs(sheet.featureSkillGranted) do
        if not features[name] or sheet.featureSkills[name] ~= skill then
            if sheet.skills[skill] == 1 then sheet.skills[skill] = nil end
            sheet.featureSkillGranted[name] = nil
        end
    end
    for name in pairs(sheet.featureSkills) do
        if not features[name] then sheet.featureSkills[name] = nil end
    end
    for name in pairs(features) do
        local skill = sheet.featureSkills[name]
        if skill and skill ~= "" and (sheet.skills[skill] or 0) == 0 then
            sheet.skills[skill], sheet.featureSkillGranted[name] = 1, skill
        end
    end
end

-- True if a maneuver or a feature's skill is still to be chosen.
function ns.OpenClassChoices(sheet)
    local limit = ns.ManeuverLimit(sheet.subclass, sheet.level)
    return (limit > 0 and ns.ManeuversKnown(sheet) ~= limit) or #ns.OpenFeatureSkills(sheet) > 0
        or #ns.OpenOptionFeatures(sheet) > 0
end
