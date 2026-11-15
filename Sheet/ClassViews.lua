-- One class of a character at a time. Most of the sheet's upkeep reads sheet.class,
-- sheet.subclass and sheet.level; a view answers those for one class (its key, its
-- subclass, its own level) and passes everything else on to the sheet, so the same
-- code works out each class of a character with several.
--   view.characterLevel  the whole character's level
--   view.viewOf          the sheet the view looks at
-- A character with one class gets the sheet itself in place of a view.
local _, ns = ...
local R = ns.Rules

-- Views are kept per sheet and class: they hold nothing, so they never go stale.
local cache = setmetatable({}, { __mode = "k" })

function ns.ClassView(sheet, key)
    local views = cache[sheet]
    if not views then
        views = {}
        cache[sheet] = views
    end
    if views[key] then return views[key] end
    local view = setmetatable({}, {
        __index = function(_, field)
            if field == "class" then return key end
            if field == "level" then return ns.ClassLevel(sheet, key) end
            if field == "subclass" then return ns.ClassSubclass(sheet, key) end
            if field == "spec" then return ns.ClassSpec(sheet, key) end
            if field == "classes" then return nil end -- on its own it is a character of one class
            if field == "characterLevel" then return sheet.level end
            if field == "viewOf" then return sheet end
            return sheet[field]
        end,
        __newindex = function(_, field, value)
            if field == "subclass" then
                ns.SetSubclass(sheet, key, value)
            elseif field ~= "class" and field ~= "level" then
                sheet[field] = value
            end
        end,
    })
    views[key] = view
    return view
end

-- The character one class at a time, the first class first. `sheet` may be a stand-in
-- with just class, subclass and level: it comes back as it is.
function ns.ClassViews(sheet)
    local extras = ns.ExtraClassKeys(sheet)
    if #extras == 0 then return { sheet } end
    local views = { ns.ClassView(sheet, sheet.class) }
    for _, key in ipairs(extras) do views[#views + 1] = ns.ClassView(sheet, key) end
    return views
end

-- The class of the character that uses a Player's Handbook class, or nil.
function ns.BaseView(sheet, base)
    for _, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        if class and class.base == base then return view end
    end
end

-- The class of the character that has a subclass, or nil.
function ns.SubclassView(sheet, subclass)
    for _, view in ipairs(ns.ClassViews(sheet)) do
        if view.subclass == subclass then return view end
    end
end

function ns.HasSubclass(sheet, subclass)
    return ns.SubclassView(sheet, subclass) ~= nil
end

-- The character's level in the class that has a subclass; 0 without it.
function ns.SubclassLevel(sheet, subclass)
    local view = ns.SubclassView(sheet, subclass)
    return view and view.level or 0
end

-- The class a pick list belongs to (Data/Picks.lua); the first class when none does.
function ns.ListView(sheet, key)
    local list = R.PICK_LISTS[key]
    return list and ns.BaseView(sheet, list.base) or ns.ClassViews(sheet)[1]
end

-- How many options of a list the character knows, whichever of its classes has the
-- list. `anySubclass` leaves the subclass out of it, for a list no subclass owns.
function ns.SheetPickLimit(sheet, key, anySubclass)
    local view = ns.ListView(sheet, key)
    -- A list of what a class starts with is only for the character's first class.
    local list = R.PICK_LISTS[key]
    local whole = view
    while whole.viewOf do whole = whole.viewOf end
    if list and list.firstClass and whole.class ~= view.class then return 0 end
    return ns.PickLimit(key, view.class, view.level, not anySubclass and view.subclass or nil)
end

-- Calls visit(feature, view) for every class feature the character has reached, each
-- class by its own level. Features that hang on a specialization or on a picked option
-- are left out (see ns.FeaturesGainedAt).
function ns.EachGainedFeature(sheet, visit)
    for _, view in ipairs(ns.ClassViews(sheet)) do
        if R.CLASSES[view.class] then
            for level = 1, view.level do
                for _, feature in ipairs(ns.FeaturesGainedAt(view.class, view.subclass, level)) do
                    visit(feature, view)
                end
            end
        end
    end
end
