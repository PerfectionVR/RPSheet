-- A Mage's cantrip exchange: when a long rest is finished, one of the class's cantrips
-- can be given up for another from its list. The sheet keeps no clock, so the time for
-- it is the one for changing prepared spells: from a long rest until the first spell
-- cast after it (state.prepareClosed, Sheet/PrepareRules.lua).
--   state.cantripSwap = { out = <the cantrip given up>, into = <the one taken in its
--   place> }   this rest's exchange; cleared by a long rest (Actions/Rest.lua)
-- The rows are in the spellbook window (UI/SpellbookCantrips.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local BOOK_CLASS = "Wizard"
local KEY = R.CANTRIP_LISTS[BOOK_CLASS] -- the pick list of its cantrips (Data/SpellPicks.lua)

-- The class that keeps the book, its picked cantrips and how many it knows; nothing
-- for a character without one.
local function Book(sheet)
    local view = KEY and ns.BaseView(sheet, BOOK_CLASS)
    if not view then return end
    if type(sheet.picks[KEY]) ~= "table" then sheet.picks[KEY] = {} end
    return view, sheet.picks[KEY], ns.PickLimit(KEY, view.class, view.level)
end

-- This rest's exchange, or nil when none was started.
local function Swap(self)
    local swap = self:State().cantripSwap
    return type(swap) == "table" and type(swap.out) == "string" and swap or nil
end

-- The cantrips the book's class knows, and the ones on offer while one is given up
-- and nothing has taken its place: two lists of names in the list's order.
function RPSheet:BookCantrips()
    local known, offered = {}, {}
    local view, picks = Book(self:Sheet())
    if not view then return known, offered end
    local swap = Swap(self)
    for _, name in ipairs(R.PICK_LISTS[KEY].order) do
        if picks[name] then
            known[#known + 1] = name
        elseif swap and not swap.into then
            offered[#offered + 1] = name
        end
    end
    return known, offered
end

-- Gives up a cantrip the character knows, or learns one in the place of the one
-- given up. Returns true when the cantrips changed; says why when they didn't.
function RPSheet:ChangeCantrip(name)
    local sheet, state = self:Sheet(), self:State()
    local view, picks, limit = Book(sheet)
    if not view or not R.PICK_LISTS[KEY].items[name] then return false end
    local swap = Swap(self)
    if picks[name] then
        if swap and swap.into ~= name then
            self:Print(swap.into and ("You exchange one cantrip per long rest, and %s made way for %s."):format(swap.out, swap.into)
                or ("%s is given up already. Learn a cantrip in its place, or %s again."):format(swap.out, swap.out))
            return false
        end
        if state.prepareClosed then
            self:Print("You exchange a cantrip when you finish a long rest. You have cast a spell since, so your cantrips stay until your next one.")
            return false
        end
        -- Giving up the one that was taken in opens the exchange again.
        if swap then swap.into = nil else state.cantripSwap = { out = name } end
        picks[name] = nil
    else
        -- An exchange that is half made can be finished whenever.
        if not swap or swap.into then
            self:Print(swap and ("You exchange one cantrip per long rest, and %s made way for %s."):format(swap.out, swap.into)
                or "Give up one of your cantrips first: the new one takes its place.")
            return false
        end
        if ns.PicksKnown(sheet, KEY) >= limit then
            self:Print(("You know %d cantrips already."):format(limit))
            return false
        end
        -- The cantrip given up comes back, or another takes its place.
        if swap.out == name then state.cantripSwap = nil else swap.into = name end
        picks[name] = true
    end
    ns.ApplySpellPicks(sheet) -- the spell list follows the picks
    ns.RebuildOptions()       -- and so do the pages under Customize
    return true
end

-- A line about what can be exchanged right now, for the window.
function RPSheet:CantripStatus()
    local swap = Swap(self)
    if swap and not swap.into then return ("%s is given up: learn one cantrip in its place."):format(swap.out) end
    if swap then return ("%s made way for %s. That was this rest's exchange."):format(swap.out, swap.into) end
    if self:State().prepareClosed then return "You have cast a spell since your last long rest: your cantrips stay until the next one." end
    return "You have just rested: one cantrip can be exchanged until you cast a spell."
end
