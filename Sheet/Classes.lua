-- The classes of a character. The first class stays where it always was
-- (sheet.class, sheet.subclass, sheet.spec) and sheet.level is the whole character's
-- level. Classes taken later are kept beside it:
--   sheet.classes[<class key>] = { level = n, subclass = "", spec = "", skill = "",
--                                  fightingStyle = "", fightingStyle2 = "" }
-- The first class's own level is what the others leave of sheet.level. A character
-- with one class has an empty sheet.classes and works as it did before.
-- Views of one class at a time are in Sheet/ClassViews.lua.
local _, ns = ...
local R = ns.Rules

local NONE = {}

-- A later class's saved entry, or nil when there is none worth counting.
local function Entry(sheet, key)
    local extras = sheet.classes
    local entry = type(extras) == "table" and extras[key]
    if type(entry) == "table" and key ~= sheet.class and R.CLASSES[key] and type(entry.level) == "number" and entry.level >= 1 then
        return entry
    end
end
ns.ClassEntry = Entry

-- Keys of the classes taken after the first, in the usual class order.
function ns.ExtraClassKeys(sheet)
    local keys = {}
    if type(sheet.classes) ~= "table" or next(sheet.classes) == nil then return keys end
    for _, key in ipairs(R.CLASS_ORDER) do
        if Entry(sheet, key) then keys[#keys + 1] = key end
    end
    return keys
end

function ns.IsMulticlass(sheet)
    return #ns.ExtraClassKeys(sheet) > 0
end

-- Every class of the character: the first one, then the others.
function ns.ClassKeys(sheet)
    local keys = ns.ExtraClassKeys(sheet)
    if R.CLASSES[sheet.class] then table.insert(keys, 1, sheet.class) end
    return keys
end

-- This character's levels in a class; 0 for a class it doesn't have.
function ns.ClassLevel(sheet, key)
    if key == sheet.class then
        local others = 0
        for _, other in ipairs(ns.ExtraClassKeys(sheet)) do others = others + sheet.classes[other].level end
        return math.max(1, (sheet.level or 1) - others)
    end
    local entry = Entry(sheet, key)
    return entry and entry.level or 0
end

function ns.ClassSubclass(sheet, key)
    if key == sheet.class then return sheet.subclass or "" end
    local entry = Entry(sheet, key)
    return entry and entry.subclass or ""
end

function ns.ClassSpec(sheet, key)
    if key == sheet.class then return sheet.spec or "" end
    local entry = Entry(sheet, key)
    return entry and entry.spec or ""
end

function ns.SetSubclass(sheet, key, value)
    if key == sheet.class then
        sheet.subclass = value
    elseif Entry(sheet, key) then
        sheet.classes[key].subclass = value
    end
end

-- The whole character's level, also for a view of one class (whose `level` is that
-- class's own).
function ns.CharacterLevel(sheet)
    return sheet.characterLevel or sheet.level
end

local function Clean(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("[|%c]", "")):sub(1, 60)
end

local function Style(value)
    return R.FIGHTING_STYLES[value] and value or ""
end

-- A safe copy of later classes that came from outside (an import string).
function ns.CleanClasses(source)
    local clean = {}
    if type(source) ~= "table" then return clean end
    for _, key in ipairs(R.CLASS_ORDER) do
        local entry = source[key]
        local level = type(entry) == "table" and math.floor(tonumber(entry.level) or 0) or 0
        if level >= 1 then
            clean[key] = {
                level = math.min(R.MAX_LEVEL - 1, level),
                subclass = Clean(entry.subclass), spec = Clean(entry.spec), skill = Clean(entry.skill),
                -- The class's own Fighting Styles (Sheet/FightingStyles.lua).
                fightingStyle = Style(entry.fightingStyle), fightingStyle2 = Style(entry.fightingStyle2),
            }
        end
    end
    return clean
end

-- Keeps the later classes in shape: known classes only, never the first class again,
-- whole levels, and at least one level left for the first class.
function ns.NormalizeClasses(sheet)
    local clean = ns.CleanClasses(sheet.classes)
    local room = R.CLASSES[sheet.class] and (math.floor(tonumber(sheet.level) or 1) - 1) or 0
    if type(sheet.classes) ~= "table" then sheet.classes = {} end
    for key in pairs(sheet.classes) do
        if not clean[key] or key == sheet.class then sheet.classes[key] = nil end
    end
    for _, key in ipairs(R.CLASS_ORDER) do
        local entry = clean[key]
        if entry and key ~= sheet.class then
            entry.level = math.min(entry.level, room)
            room = room - entry.level
            sheet.classes[key] = entry.level >= 1 and entry or nil
        end
    end
    if type(sheet.lastClass) ~= "string" then sheet.lastClass = "" end
    ns.AdoptStyles(sheet) -- a style picked before each class had its own
end

-- The character as it would be with `level` levels in one of its classes (or in a new
-- one) and, when given, that class's `subclass`. Nothing is saved; what is written to
-- it lands on the sheet itself. The level dialog looks at this before a level is taken.
function ns.SheetWith(sheet, key, level, subclass)
    local first = key == sheet.class
    local total, classes = sheet.level - ns.ClassLevel(sheet, key) + level, sheet.classes
    if not first then
        local old = Entry(sheet, key) or NONE
        classes = {}
        for other, entry in pairs(type(sheet.classes) == "table" and sheet.classes or NONE) do classes[other] = entry end
        classes[key] = {
            level = level, subclass = subclass or old.subclass or "", spec = old.spec or "", skill = old.skill or "",
            -- The class keeps the Fighting Styles it picked (Sheet/FightingStyles.lua).
            fightingStyle = old.fightingStyle, fightingStyle2 = old.fightingStyle2,
        }
    end
    return setmetatable({}, {
        __index = function(_, field)
            if field == "level" then return total end
            if field == "classes" then return classes end
            if field == "subclass" and first and subclass then return subclass end
            return sheet[field]
        end,
        __newindex = sheet,
    })
end
