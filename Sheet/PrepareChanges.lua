-- Preparing a spell or putting one away after a long rest, held to the rule of the
-- class the spell is prepared for (which classes and rules: Sheet/PrepareRules.lua).
--   state.prepareSwap[<class key>] = { out = <spell put away>, into = <spell taken in
--   its place> }  for a class that changes one spell per long rest
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The exchange a class has made since the last long rest, or nil.
local function SwapOf(self, class)
    local state = self:State()
    local swaps = state.prepareSwap
    if type(swaps) ~= "table" then return end
    if type(swaps.out) == "string" then
        -- Saved before each class had its own: it was the exchange of the one class
        -- that changes a single spell.
        local old = { out = swaps.out, into = type(swaps.into) == "string" and swaps.into or nil }
        swaps = {}
        for _, entry in ipairs(ns.PrepareRules(self:Sheet())) do
            if entry.rule == "REST_ONE" then
                swaps[entry.class] = old
                break
            end
        end
        state.prepareSwap = swaps
    end
    return type(swaps[class]) == "table" and swaps[class] or nil
end

local function SetSwap(self, class, swap)
    local state = self:State()
    if type(state.prepareSwap) ~= "table" or type(state.prepareSwap.out) == "string" then state.prepareSwap = {} end
    state.prepareSwap[class] = swap
end

-- Prepares a spell that isn't prepared, or puts away one that is, if the rule of the
-- class allows it right now: `classKey`, or the first class that changes its spells
-- after a long rest. Returns true when the list changed; says why when it didn't.
function RPSheet:ChangePrepared(name, classKey)
    local sheet, state = self:Sheet(), self:State()
    local entry = ns.RestPreparer(sheet, classKey)
    if not entry then return false end
    local key, view = entry.key, entry.view
    local list = R.PICK_LISTS[key]
    if not list.items[name] then return false end
    if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
    local picks = sheet.picks[key]
    if state.prepareClosed then
        self:Print("You change your prepared spells when you finish a long rest. You have cast a spell since, so the list stays as it is until your next one.")
        return false
    end
    local one = entry.rule == "REST_ONE"
    local swap = SwapOf(self, entry.class)
    if picks[name] then
        if one and swap and swap.into == name then
            swap.into = nil -- taking the exchange back
        elseif one and swap then
            self:Print(swap.into and ("You change one prepared spell per long rest, and %s made way for %s. Put %s away to take that back."):format(swap.out, swap.into, swap.into)
                or ("You change one prepared spell per long rest, and %s is put away. Prepare a spell in its place, or %s again."):format(swap.out, swap.out))
            return false
        elseif one then
            SetSwap(self, entry.class, { out = name })
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
            if swap.out == name then SetSwap(self, entry.class, nil) else swap.into = name end
        end
        picks[name] = true
    end
    ns.ApplyPreparedPicks(sheet) -- the spell list follows the picks
    ns.RebuildOptions()          -- and so do the pages under Customize
    return true
end

-- A line about what a class can change right now, for the window.
function RPSheet:PrepareStatus(classKey)
    local entry = ns.RestPreparer(self:Sheet(), classKey)
    if self:State().prepareClosed then return "You have cast a spell since your last long rest: the list is fixed until the next one." end
    if not entry or entry.rule ~= "REST_ONE" then return "You have just rested: any of them can be changed until you cast a spell." end
    local swap = SwapOf(self, entry.class)
    if not swap then return "You have just rested: one of them can be exchanged until you cast a spell." end
    if not swap.into then return ("%s is put away: prepare one spell in its place."):format(swap.out) end
    return ("%s made way for %s. That was this rest's exchange."):format(swap.out, swap.into)
end
