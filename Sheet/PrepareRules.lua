-- Changing prepared spells after a long rest, for the classes that prepare from their
-- class list and change them then (R.PREPARE_RULES in Data/PreparedPicks.lua): all of
-- them, or only one, by class. A Mage does the same from the spellbook
-- (Sheet/Spellbook.lua). The sheet keeps no clock, so the time to change them runs
-- from a long rest until the first spell cast after it:
--   state.prepareClosed  true once a spell was cast (Actions/Spells.lua)
--   state.prepareSwap    { out = <spell put away>, into = <spell taken in its place> }
--                        for a class that changes one spell per long rest
-- Both are cleared by a long rest (Actions/Rest.lua). The window is UI/PreparedWindow.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The class's rule ("LEVEL", "REST" or "REST_ONE") and the key of its list of
-- prepared spells; nothing for a class that doesn't prepare from its class list.
-- Of several classes the first that prepares this way is the one: its view is the
-- third thing returned (the sheet itself for a character of one class).
function ns.PrepareRule(sheet)
    for _, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        local key = class and R.PREPARED_LISTS[class.base]
        if key and ns.PickLimit(key, view.class, view.level) > 0 then return R.PREPARE_RULES[class.base], key, view end
    end
end

-- True if the character changes prepared spells from its class list after a long rest.
function ns.ChangesPreparedAtRest(sheet)
    local rule = ns.PrepareRule(sheet)
    return rule == "REST" or rule == "REST_ONE"
end

-- True if casting a spell ends the time to change prepared spells: the above, and a Mage.
function ns.PreparesAtRest(sheet)
    return ns.HasSpellbook(sheet) or ns.ChangesPreparedAtRest(sheet)
end

-- The spells the character could have prepared right now, in the list's order: the
-- prepared ones and those of a level it has slots for that aren't always prepared.
function ns.PreparedChoices(sheet)
    local rule, key, view = ns.PrepareRule(sheet)
    local names = {}
    if not rule then return names end
    local list, picks = R.PICK_LISTS[key], sheet.picks[key] or {}
    for _, name in ipairs(list.order) do
        if picks[name] or not ns.PickBlocked(key, name, view.level, picks, view.subclass, view) then
            names[#names + 1] = name
        end
    end
    return names
end

-- Prepares a spell that isn't prepared, or puts away one that is, if the class's rule
-- allows it right now. Returns true when the list changed; says why when it didn't.
function RPSheet:ChangePrepared(name)
    local sheet, state = self:Sheet(), self:State()
    local rule, key, view = ns.PrepareRule(sheet)
    if rule ~= "REST" and rule ~= "REST_ONE" then return false end
    local list = R.PICK_LISTS[key]
    if not list.items[name] then return false end
    if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
    local picks = sheet.picks[key]
    if state.prepareClosed then
        self:Print("You change your prepared spells when you finish a long rest. You have cast a spell since, so the list stays as it is until your next one.")
        return false
    end
    local one = rule == "REST_ONE"
    local swap = type(state.prepareSwap) == "table" and state.prepareSwap or nil
    if picks[name] then
        if one and swap and swap.into == name then
            swap.into = nil -- taking the exchange back
        elseif one and swap then
            self:Print(swap.into and ("You change one prepared spell per long rest, and %s made way for %s. Put %s away to take that back."):format(swap.out, swap.into, swap.into)
                or ("You change one prepared spell per long rest, and %s is put away. Prepare a spell in its place, or %s again."):format(swap.out, swap.out))
            return false
        elseif one then
            state.prepareSwap = { out = name }
        end
        picks[name] = nil
    else
        local why = ns.PickBlocked(key, name, view.level, picks, view.subclass, view)
        if why then
            self:Print(("%s can't be prepared: %s."):format(name, why))
            return false
        end
        local limit = ns.PickLimit(key, view.class, view.level)
        if ns.PicksKnown(sheet, key) >= limit then
            self:Print(("You can prepare %d spells. Put one away first."):format(limit))
            return false
        end
        if one and swap and not swap.into then
            -- The spell put away comes back, or another takes its place.
            if swap.out == name then state.prepareSwap = nil else swap.into = name end
        end
        picks[name] = true
    end
    ns.ApplyPreparedPicks(sheet) -- the spell list follows the picks
    ns.RebuildOptions()          -- and so do the pages under Customize
    return true
end

-- A line about what can be changed right now, for the window.
function RPSheet:PrepareStatus()
    local rule = ns.PrepareRule(self:Sheet())
    local state = self:State()
    if state.prepareClosed then return "You have cast a spell since your last long rest: the list is fixed until the next one." end
    if rule ~= "REST_ONE" then return "You have just rested: any of them can be changed until you cast a spell." end
    local swap = type(state.prepareSwap) == "table" and state.prepareSwap or nil
    if not swap then return "You have just rested: one of them can be exchanged until you cast a spell." end
    if not swap.into then return ("%s is put away: prepare one spell in its place."):format(swap.out) end
    return ("%s made way for %s. That was this rest's exchange."):format(swap.out, swap.into)
end
