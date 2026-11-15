-- The level dialog: which earlier picks have to stay (bookkeeping in Sheet/PickSwaps.lua).
--   * Taking a level: a list lets one earlier pick be exchanged, or none (list.swaps);
--     a list of another class than the one the level is taken in lets none.
--   * Opened again for a level the character already has: the dialog is for filling
--     in what is still open, so what was chosen stays. Spells are changed on the
--     Spells page under Customize and the class's options on the page beside it
--     (Options/ClassPicks.lua); those hold to nothing.
-- L.draft.before[<list>] are the picks made before the dialog opened, and
-- L.draft.fixed[<list>] says why none of them may go ("OPEN" or "CLASS").
-- A Battle Master's maneuvers are held the same way (Options/LevelDialogManeuvers.lua).
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local L = ns.LevelDialog
local args = L.args

-- Called when the dialog opens, once the draft's picks are in place.
function L.RememberPicks(sheet)
    local draft = L.draft
    local class = R.CLASSES[draft.class]
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        local limit = ns.SheetPickLimit(sheet, key)
        -- A list with more picks than it allows is left free, so it can be put right.
        local fits = L.PicksChosen(key) <= limit
        if limit > 0 and draft.taking and list.swaps then
            if fits then
                draft.before[key] = CopyTable(draft.picks[key])
                if not (class and class.base == list.base) then draft.fixed[key] = "CLASS" end
            end
        elseif limit > 0 and not draft.taking and list.swapGroup and fits then
            draft.before[key] = CopyTable(draft.picks[key])
            draft.fixed[key] = "OPEN"
        end
    end
end

-- True if a pick made before the dialog opened has to stay.
function L.SwapLocked(key, name)
    return ns.PickSwapLocked(key, name, L.draft.before, L.draft.picks, L.Picking(), L.draft.fixed[key])
end

-- A few words for the list's heading about what may still be exchanged, or "".
function L.SwapNote(key)
    return ns.PickSwapNote(key, L.draft.before, L.draft.picks, L.Picking(), L.draft.fixed[key])
end

-- True if the dialog was opened again and holds on to picks that were made.
local function HoldsPicks()
    if not L.draft or L.draft.taking then return false end
    for key, why in pairs(L.draft.fixed) do
        if why == "OPEN" and next(L.draft.before[key] or {}) then return true end
    end
    return next(L.draft.maneuversBefore or {}) ~= nil
end

args.settled = {
    type = "description", order = 2.5,
    hidden = function() return not HoldsPicks() end,
    name = Opt.GOLD .. "The spells, cantrips and class options you had chosen stay as they are here: this window is for filling in what is still open.|r "
        .. "The rules let you exchange one when you gain a level, or after a long rest, depending on the class. "
        .. "To change one anyway, go to Customize: delete a spell under Spells, or untick an option under " .. Opt.CLASS_PICKS_PAGE .. ". Nothing is held to the rules there, and its place can then be filled here.\n",
}
