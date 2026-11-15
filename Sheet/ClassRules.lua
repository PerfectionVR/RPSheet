-- What the rules ask before a character takes a level in another class, and what the
-- new class gives (numbers in Data/Multiclass.lua). The level dialog refuses what
-- ns.MulticlassBlock names; the Customize page only warns with ns.MulticlassWarnings.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

-- The abilities a class needs at 13 that the character has lower, as text; nil when
-- it qualifies. Some classes need all of theirs, a Warrior needs either.
local function Lacking(sheet, key)
    local rule = R.MULTICLASS[R.CLASSES[key].base]
    if not rule then return end
    local low, met = {}, false
    for _, stat in ipairs(rule.primary) do
        if Kit.Score(sheet, stat) >= R.MULTICLASS_SCORE then met = true else low[#low + 1] = R.STAT_NAMES[stat] end
    end
    if rule.either then return not met and table.concat(low, " or ") or nil end
    return #low > 0 and table.concat(low, " and ") or nil
end

-- Why the character can't take its next level in a class, or nil when it can. A class
-- it already has asks nothing more.
function ns.MulticlassBlock(sheet, key)
    local class = R.CLASSES[key]
    if not class or not R.CLASSES[sheet.class] then return "choose a first class first" end
    if ns.ClassLevel(sheet, key) > 0 then return end
    for _, own in ipairs(ns.ClassKeys(sheet)) do
        if R.CLASSES[own].base == class.base then
            return ("it is the same class as your %s"):format(R.CLASSES[own].name)
        end
    end
    if class.hero and sheet.level + 1 < R.HERO_START_LEVEL then
        return ("a hero class, open from character level %d"):format(R.HERO_START_LEVEL)
    end
    local lacking = Lacking(sheet, key)
    if lacking then return ("needs %s %d or higher"):format(lacking, R.MULTICLASS_SCORE) end
    for _, own in ipairs(ns.ClassKeys(sheet)) do
        lacking = Lacking(sheet, own)
        if lacking then
            return ("your %s needs %s %d or higher to take another class"):format(R.CLASSES[own].name, lacking, R.MULTICLASS_SCORE)
        end
    end
end

-- What a character of several classes has against the rules, as a list of sentences.
function ns.MulticlassWarnings(sheet)
    local warnings, bases = {}, {}
    local extras = ns.ExtraClassKeys(sheet)
    if #extras == 0 then return warnings end
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local class = R.CLASSES[key]
        local lacking = Lacking(sheet, key)
        if lacking then
            warnings[#warnings + 1] = ("%s needs %s %d or higher for a character with several classes."):format(class.name, lacking, R.MULTICLASS_SCORE)
        end
        if bases[class.base] then
            warnings[#warnings + 1] = ("%s and %s are the same class by the rules and can't be combined."):format(bases[class.base], class.name)
        end
        bases[class.base] = class.name
        if key ~= sheet.class and ns.ClassSubclass(sheet, key) ~= "" and ns.ClassLevel(sheet, key) < R.SUBCLASS_LEVEL and not class.hero then
            warnings[#warnings + 1] = ("%s: by the rules a subclass is chosen at level %d of the class."):format(class.name, R.SUBCLASS_LEVEL)
        end
    end
    for _, name in ipairs(ns.RepeatedStyles(sheet)) do
        warnings[#warnings + 1] = ("%s is picked as a Fighting Style more than once: a style can be taken only once, and it counts once."):format(name)
    end
    if sheet.level < R.HERO_START_LEVEL then
        for _, key in ipairs(extras) do
            if R.CLASSES[key].hero then
                warnings[#warnings + 1] = ("%s is a hero class: those normally start at level %d or higher."):format(R.CLASSES[key].name, R.HERO_START_LEVEL)
            end
        end
    end
    return warnings
end

-- What the first level in a class taken after the first gives, as text.
function ns.MulticlassGains(key)
    local class = R.CLASSES[key]
    local rule = class and R.MULTICLASS[class.base]
    local parts = {}
    for _, kind in ipairs(rule and rule.armor or {}) do
        parts[#parts + 1] = kind == "shield" and "shields" or (kind .. " armor")
    end
    if rule and rule.martial then parts[#parts + 1] = "martial weapons" end
    if rule and rule.skill then parts[#parts + 1] = "one skill from the class's list" end
    for _, tool in ipairs(rule and rule.tools or {}) do parts[#parts + 1] = tool end
    if #parts == 0 then return "no new training or proficiencies" end
    return "training with " .. table.concat(parts, ", ")
end

-- Skills a class taken after the first lets the character pick one of: the class's
-- list without those it is proficient in. `current` stays listed. Empty for a class
-- that gives no skill.
function ns.MulticlassSkills(sheet, key, current)
    local class = R.CLASSES[key]
    local rule = class and R.MULTICLASS[class.base]
    local names = {}
    for _, skill in ipairs(rule and rule.skill and class.skills or {}) do
        if skill == current or (sheet.skills[skill] or 0) == 0 then names[#names + 1] = skill end
    end
    return names
end
