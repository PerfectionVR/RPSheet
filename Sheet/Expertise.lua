-- Expertise a class feature lets the character pick (a Rogue's Expertise, a Hunter's
-- Deft Explorer, a Mage's Scholar). sheet.expertise[<skill>] = true.
-- A feature says how many with `expertise = { steps = { {level, count}, ... } }`, and
-- may limit the skills with `skills = { ... }`. The choosing happens in
-- Options/LevelDialog.lua; under Customize a skill's rank can be set to anything.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

-- How many skills the character picks expertise in, and the skills it may pick from
-- as a set (nil = any skill).
function ns.ExpertiseLimit(sheet)
    local count, allowed, anySkill = 0, {}, false
    if not R.CLASSES[sheet.class] then return 0 end
    for level = 1, sheet.level do
        for _, feature in ipairs(ns.FeaturesGainedAt(sheet.class, sheet.subclass, level)) do
            if feature.expertise then
                count = count + (Kit.AtLevel(sheet.level, feature.expertise.steps) or 0)
                if feature.expertise.skills then
                    for _, skill in ipairs(feature.expertise.skills) do allowed[skill] = true end
                else
                    anySkill = true
                end
            end
        end
    end
    return count, (not anySkill and count > 0) and allowed or nil
end

function ns.ExpertiseKnown(sheet)
    local count = 0
    for _ in pairs(sheet.expertise) do count = count + 1 end
    return count
end

-- True if the number of picks isn't what the features give.
function ns.OpenExpertise(sheet)
    local limit = ns.ExpertiseLimit(sheet)
    return limit > 0 and ns.ExpertiseKnown(sheet) ~= limit
end

-- Raises the picked skills to expertise, and takes it back from skills no longer picked.
function ns.ApplyExpertise(sheet)
    if ns.ExpertiseLimit(sheet) == 0 then wipe(sheet.expertise) end
    for skill in pairs(sheet.expertiseGranted) do
        if not sheet.expertise[skill] then
            if sheet.skills[skill] == 2 then sheet.skills[skill] = 1 end
            sheet.expertiseGranted[skill] = nil
        end
    end
    for skill in pairs(sheet.expertise) do
        if sheet.skills[skill] == 1 then
            sheet.skills[skill], sheet.expertiseGranted[skill] = 2, true
        end
    end
end
