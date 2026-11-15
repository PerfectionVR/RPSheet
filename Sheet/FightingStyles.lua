-- The Fighting Styles a character has picked (data in Data/Combat.lua). A class with
-- the Fighting Style feature picks one style; a Champion's Additional Fighting Style
-- adds a second. Every class of the character that has the feature has its own pick:
--   the first class:  sheet.fightingStyle, sheet.fightingStyle2
--   a later class:    the same two fields on its entry, sheet.classes[<class key>]
-- What the styles do to the numbers is in Sheet/StyleEffects.lua.
local _, ns = ...
local R = ns.Rules

local STYLE_FIELDS = { "fightingStyle", "fightingStyle2" }
local STYLE_FEATURES = { "Fighting Style", "Additional Fighting Style" }
ns.STYLE_FIELDS, ns.STYLE_FEATURES = STYLE_FIELDS, STYLE_FEATURES

local NONE = {}

-- The class level at which a class with that subclass gets each of the two features,
-- as { [slot] = level }. Worked out once per class and subclass.
local known = {}
local function StyleLevels(key, subclass)
    if not R.CLASSES[key] then return NONE end
    local id = key .. "|" .. subclass
    if not known[id] then
        local levels = {}
        for level = 1, R.MAX_LEVEL do
            for _, feature in ipairs(ns.FeaturesGainedAt(key, subclass, level)) do
                for slot, name in ipairs(STYLE_FEATURES) do
                    if feature.name == name then levels[slot] = levels[slot] or level end
                end
            end
        end
        known[id] = levels
    end
    return known[id]
end

-- The class level at which a class with that subclass picks the style of a slot, or
-- nil when it never does. The creation wizard asks before there is a sheet to look at.
function ns.StyleLevel(key, subclass, slot)
    return StyleLevels(key, subclass or "")[slot]
end

-- True if one of the character's classes has reached the feature of a slot.
local function Reaches(sheet, key, slot)
    local level = StyleLevels(key, ns.ClassSubclass(sheet, key))[slot]
    return level ~= nil and ns.ClassLevel(sheet, key) >= level
end

-- Where a class's styles are kept: the sheet for the first class, else its entry.
local function Holder(sheet, key)
    if key == sheet.class then return sheet end
    return ns.ClassEntry(sheet, key)
end

-- The style a class picked for a slot, or "".
function ns.ClassStyle(sheet, key, slot)
    local holder = Holder(sheet.viewOf or sheet, key)
    local name = holder and holder[STYLE_FIELDS[slot]]
    return type(name) == "string" and name or ""
end

function ns.SetClassStyle(sheet, key, slot, name)
    local holder = Holder(sheet.viewOf or sheet, key)
    if holder and STYLE_FIELDS[slot] then holder[STYLE_FIELDS[slot]] = name end
end

-- True if a class of the character can pick its first (slot 1) or second (slot 2)
-- Fighting Style: the first class when no class is named, or the class a view is of.
-- The feature has to be on the sheet: deleting it there gives the style up.
function ns.HasStyleSlot(sheet, slot, classKey)
    local key = classKey or sheet.class
    sheet = sheet.viewOf or sheet
    return Reaches(sheet, key, slot) and ns.FeaturePassive(sheet, STYLE_FEATURES[slot]) ~= nil
end

-- Every Fighting Style the character can pick, class by class, the first class first:
-- { class = <class key>, slot = 1 or 2, name = <the style picked, or ""> }
function ns.StyleSlots(sheet)
    sheet = sheet.viewOf or sheet
    local slots = {}
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        for slot in ipairs(STYLE_FEATURES) do
            if ns.HasStyleSlot(sheet, slot, key) then
                slots[#slots + 1] = { class = key, slot = slot, name = ns.ClassStyle(sheet, key, slot) }
            end
        end
    end
    return slots
end

-- The styles the character has chosen and is entitled to, each once however many of
-- its classes picked it: a list of { name = , style = <its data> }.
function ns.StylesHeld(sheet)
    local held, taken = {}, {}
    for _, slot in ipairs(ns.StyleSlots(sheet)) do
        local style = R.FIGHTING_STYLES[slot.name]
        if style and not taken[slot.name] then
            held[#held + 1], taken[slot.name] = { name = slot.name, style = style }, true
        end
    end
    return held
end

-- Styles that can go in a slot of the class `sheet` is (a view of one class, or a
-- stand-in with a class): a style can't be taken twice, whichever class has it.
function ns.StyleChoices(sheet, slot)
    local key, taken, names = sheet.class, {}, {}
    for _, other in ipairs(ns.StyleSlots(sheet)) do
        if other.class ~= key or other.slot ~= slot then taken[other.name] = true end
    end
    local class = R.CLASSES[key]
    for _, name in ipairs(R.FIGHTING_STYLE_ORDER) do
        local style = R.FIGHTING_STYLES[name]
        -- Some styles belong to one class.
        local allowed = (not style.base or (class and class.base == style.base)) and (not style.class or key == style.class)
        if allowed and not taken[name] then names[#names + 1] = name end
    end
    return names
end

-- Styles picked more than once, as a list of names: the second pick gives nothing.
function ns.RepeatedStyles(sheet)
    local seen, names = {}, {}
    for _, slot in ipairs(ns.StyleSlots(sheet)) do
        if R.FIGHTING_STYLES[slot.name] then
            if seen[slot.name] == 1 then names[#names + 1] = slot.name end
            seen[slot.name] = (seen[slot.name] or 0) + 1
        end
    end
    return names
end

-- Before every class had its own pick, the one style on the sheet served whichever
-- class had the feature. A first class without the feature hands its style to the
-- later class that has the feature and no pick yet. Needs only the classes and their
-- levels, so it can run before the rest of the sheet is in shape.
function ns.AdoptStyles(sheet)
    local extras = ns.ExtraClassKeys(sheet)
    if #extras == 0 or not R.CLASSES[sheet.class] then return end
    for slot, field in ipairs(STYLE_FIELDS) do
        if R.FIGHTING_STYLES[sheet[field]] and not Reaches(sheet, sheet.class, slot) then
            for _, key in ipairs(extras) do
                if Reaches(sheet, key, slot) and ns.ClassStyle(sheet, key, slot) == "" then
                    sheet.classes[key][field], sheet[field] = sheet[field], ""
                    break
                end
            end
        end
    end
end
