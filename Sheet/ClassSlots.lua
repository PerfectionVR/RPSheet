-- Numbers for the levels of each class, so that the choices kept per level
-- (sheet.levels, Sheet/Levels.lua) can tell the classes apart. A class's improvements
-- come at its own levels, not the character's.
--   the first class:  its own level, 1 to 20, as it always was
--   a later class:    100 x its place in the class order, plus its own level
-- So a character with one class keeps the numbers it had.
local _, ns = ...
local R = ns.Rules

local STEP = 100

local function Place(key)
    for index, other in ipairs(R.CLASS_ORDER) do
        if other == key then return index end
    end
end

-- The number for a level of one of the character's classes.
function ns.LevelSlot(sheet, key, classLevel)
    if key == sheet.class then return classLevel end
    return (Place(key) or 0) * STEP + classLevel
end

-- The class key and the class's own level a number stands for.
function ns.SlotClass(sheet, slot)
    if slot < STEP then return sheet.class, slot end
    return R.CLASS_ORDER[math.floor(slot / STEP)], slot % STEP
end

-- True if the character has reached that level of that class.
function ns.HasSlot(sheet, slot)
    local key, classLevel = ns.SlotClass(sheet, slot)
    -- The first class's levels are only ever the plain numbers: a number of the other
    -- kind that names it is left over from when it was a later class, and would count
    -- that level's choice a second time.
    if slot >= STEP and key == sheet.class then return false end
    return key ~= nil and classLevel >= 1 and classLevel <= ns.ClassLevel(sheet, key)
end

-- Every level the character has, class by class, the first class first.
function ns.LevelSlots(sheet)
    local slots = {}
    for level = 1, ns.ClassLevel(sheet, sheet.class) do slots[#slots + 1] = level end
    for _, key in ipairs(ns.ExtraClassKeys(sheet)) do
        for level = 1, ns.ClassLevel(sheet, key) do slots[#slots + 1] = ns.LevelSlot(sheet, key, level) end
    end
    return slots
end

-- Every number that can stand for a level, for cleaning data that came from outside.
function ns.AllLevelSlots()
    local slots = {}
    for place = 0, #R.CLASS_ORDER do
        for level = 1, R.MAX_LEVEL do slots[#slots + 1] = place * STEP + level end
    end
    return slots
end

-- "level 4" for a character of one class, "Mage level 4" for one of several.
function ns.SlotLabel(sheet, slot)
    local key, classLevel = ns.SlotClass(sheet, slot)
    if not ns.IsMulticlass(sheet) or not R.CLASSES[key] then return ("level %d"):format(classLevel) end
    return ("%s level %d"):format(R.CLASSES[key].name, classLevel)
end
