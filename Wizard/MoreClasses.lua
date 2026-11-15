-- A wizard character of several classes: the classes taken beside the first and how
-- the levels are split. draft.classes is a list of
--   { class = <class key>, level = n, subclass = "", spec = "", skill = "",
--     fightingStyle = "", fightingStyle2 = "" }   (the styles: Wizard/Styles.lua)
-- and the first class keeps the levels the others leave. What the rules ask of another
-- class is asked through the same check the level dialog uses (Sheet/ClassRules.lua),
-- on a stand-in for the character the draft would make (Wizard/MoreClassRules.lua).
-- The page is in Wizard/MoreClassesPage.lua. Without other classes everything here
-- answers as for a character of one class.
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard

-- A row for every class beside the first: how many can be taken is up to the levels
-- there are to split and to what the rules ask of each class.
W.MOST_EXTRAS = #R.CLASS_ORDER - 1

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

-- Weapons whose mastery the new character may set: what each of its classes allows at
-- its own level, added together (the reading is given at RPSheet:MasteryLimit).
function W.MasteryLimit()
    local total = 0
    for _, entry in ipairs(W.DraftClasses()) do
        local base = R.CLASSES[entry.class].base
        total = total + (ns.FeatureKit.AtLevel(entry.level, R.MASTERY_LIMITS[base] or {}) or 0)
    end
    return total
end

-- Another first class was chosen: it can't be one of the others as well.
function W.DropExtra(key)
    local rows = W.draft.classes or NONE
    for index = #rows, 1, -1 do
        if rows[index].class == key then table.remove(rows, index) end
    end
end

-- Puts the other classes on the new sheet (Sheet/Classes.lua). A hero class comes
-- with its subclass; any other has one from level 3 of the class. Their Fighting
-- Styles follow in W.ApplyStyles.
function W.ApplyExtras(sheet)
    if type(sheet.classes) ~= "table" then sheet.classes = {} end
    for _, row in ipairs(W.Extras()) do
        local spec = ""
        for _, name in ipairs(R.CLASSES[row.class].specs or {}) do
            if name == row.spec then spec = name end
        end
        sheet.classes[row.class] = { level = row.level, subclass = W.EntrySubclass(row), spec = spec, skill = row.skill or "" }
    end
    ns.NormalizeClasses(sheet)
end
