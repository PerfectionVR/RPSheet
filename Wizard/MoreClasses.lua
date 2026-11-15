-- A wizard character of several classes: the classes taken beside the first and how
-- the levels are split. draft.classes is a list of
--   { class = <class key>, level = n, subclass = "", skill = "" }
-- and the first class keeps the levels the others leave. What the rules ask of another
-- class is asked through the same check the level dialog uses (Sheet/ClassRules.lua),
-- on a stand-in for the character the draft would make (Wizard/MoreClassRules.lua).
-- The page is in Wizard/MoreClassesPage.lua. Without other classes everything here
-- answers as for a character of one class.
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard

W.MOST_EXTRAS = 3 -- other classes the wizard has rows for; more are added under Customize

local NONE = {}

-- The other classes that count: none for a level 1 character or before a class is chosen.
function W.Extras()
    local draft = W.draft
    if not draft or draft.level < 2 or not R.CLASSES[draft.class] then return NONE end
    return draft.classes or NONE
end

-- Levels the other classes take, leaving out row `except`.
function W.ExtraLevels(except)
    local total = 0
    for index, row in ipairs(W.Extras()) do
        if index ~= except then total = total + row.level end
    end
    return total
end

-- The first class's own level.
function W.FirstLevel()
    return math.max(1, W.draft.level - W.ExtraLevels())
end

-- Every class of the draft with its subclass and own level, the first class first.
function W.DraftClasses()
    local draft = W.draft
    local list = { { class = draft.class, subclass = draft.subclass, level = W.FirstLevel() } }
    for _, row in ipairs(W.Extras()) do list[#list + 1] = row end
    return list
end

-- The class that brings the Fighting Style feature by its level, or nil.
function W.StyleClass()
    if not W.draft or not R.CLASSES[W.draft.class] then return end
    for _, entry in ipairs(W.DraftClasses()) do
        for level = 1, entry.level do
            for _, feature in ipairs(ns.FeaturesGainedAt(entry.class, entry.subclass, level)) do
                if feature.name == ns.STYLE_FEATURES[1] then return entry.class end
            end
        end
    end
end

function W.NeedsFightingStyle()
    return W.StyleClass() ~= nil
end

-- Weapons whose mastery the new character may set: the class that allows the most counts.
function W.MasteryLimit()
    local most = 0
    for _, entry in ipairs(W.DraftClasses()) do
        local base = R.CLASSES[entry.class].base
        most = math.max(most, ns.FeatureKit.AtLevel(entry.level, R.MASTERY_LIMITS[base] or {}) or 0)
    end
    return most
end

-- Another first class was chosen: it can't be one of the others as well.
function W.DropExtra(key)
    local rows = W.draft.classes or NONE
    for index = #rows, 1, -1 do
        if rows[index].class == key then table.remove(rows, index) end
    end
end

-- Puts the other classes on the new sheet (Sheet/Classes.lua). A hero class comes
-- with its subclass; any other has one from level 3 of the class.
function W.ApplyExtras(sheet)
    if type(sheet.classes) ~= "table" then sheet.classes = {} end
    for _, row in ipairs(W.Extras()) do
        local class = R.CLASSES[row.class]
        local subclass = row.level >= R.SUBCLASS_LEVEL and row.subclass or ""
        if class.hero then subclass = class.subclasses[1] or "" end
        sheet.classes[row.class] = { level = row.level, subclass = subclass, spec = "", skill = row.skill or "" }
    end
    ns.NormalizeClasses(sheet)
end
