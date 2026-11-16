-- Changing prepared spells after a long rest, for the classes that prepare from their
-- class list and change them then (R.PREPARE_RULES in Data/PreparedPicks.lua): all of
-- them, or only one, by class. A character with several such classes changes each
-- class's spells by that class's own rule and count. A Mage does the same from the
-- spellbook (Sheet/Spellbook.lua). The sheet keeps no clock, so the time to change
-- them runs from a long rest until the first spell cast after it:
--   state.prepareClosed  true once a spell was cast (Actions/Spells.lua)
--   state.prepareSwap    the one exchange of each class that changes one spell per
--                        long rest (Sheet/PrepareChanges.lua)
-- Both are cleared by a long rest (Actions/Rest.lua). The window is UI/PreparedWindow.lua.
local _, ns = ...
local R = ns.Rules

-- Every class of the character that prepares from its class list, the first class
-- first, each as
--   { class = <class key>, rule = "LEVEL", "REST" or "REST_ONE", key = <its list of
--     prepared spells>, view = <the class's view; the sheet itself for one class> }
function ns.PrepareRules(sheet)
    local found = {}
    for _, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        local key = class and R.PREPARED_LISTS[class.base]
        if key and ns.PickLimit(key, view.class, view.level) > 0 then
            found[#found + 1] = { class = view.class, rule = R.PREPARE_RULES[class.base], key = key, view = view }
        end
    end
    return found
end

-- Those of them that change prepared spells after a long rest.
function ns.RestPreparers(sheet)
    local found = {}
    for _, entry in ipairs(ns.PrepareRules(sheet)) do
        if entry.rule == "REST" or entry.rule == "REST_ONE" then found[#found + 1] = entry end
    end
    return found
end

-- The one of a class; without a class, the first that changes them after a long rest.
function ns.RestPreparer(sheet, classKey)
    for _, entry in ipairs(ns.RestPreparers(sheet)) do
        if not classKey or entry.class == classKey then return entry end
    end
end

-- True if the character changes prepared spells from a class list after a long rest.
function ns.ChangesPreparedAtRest(sheet)
    return #ns.RestPreparers(sheet) > 0
end

-- True if casting a spell ends the time to change prepared spells: the above, and a Mage.
function ns.PreparesAtRest(sheet)
    return ns.HasSpellbook(sheet) or ns.ChangesPreparedAtRest(sheet)
end

-- The spells a class (an entry of ns.PrepareRules) could have prepared right now, in
-- the list's order: the prepared ones and those of a level it has slots for that
-- aren't always prepared.
function ns.PreparedChoices(sheet, entry)
    local names = {}
    if not entry then return names end
    local list, picks, view = R.PICK_LISTS[entry.key], sheet.picks[entry.key] or {}, entry.view
    for _, name in ipairs(list.order) do
        if picks[name] or not ns.PickBlocked(entry.key, name, view.level, picks, view.subclass, view) then
            names[#names + 1] = name
        end
    end
    return names
end
