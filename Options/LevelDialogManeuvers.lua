-- The level dialog: which of a Battle Master's maneuvers have to stay. One maneuver
-- can be exchanged each time new ones are learned, so:
--   * taking a level that raises the number known: one earlier maneuver may go;
--   * taking any other level, in this class or another: the earlier ones stay;
--   * opened again for a level the character already has: they stay, the window is
--     for filling in what is still open.
-- L.draft.maneuversBefore are the maneuvers known before the dialog opened.
local _, ns = ...
local R = ns.Rules
local L = ns.LevelDialog

local NONE = {}

-- Called when the dialog opens.
function L.RememberManeuvers(sheet)
    local draft = L.draft
    -- A name the rules no longer know would never be counted right.
    for name in pairs(draft.maneuvers) do
        if not R.MANEUVERS[name] then draft.maneuvers[name] = nil end
    end
    local limit = ns.SheetManeuverLimit(sheet)
    draft.maneuverLimit, draft.maneuversBefore = limit, {}
    -- More maneuvers than the rules allow are left free, so it can be put right.
    if limit > 0 and L.ManeuversPicked() <= limit then draft.maneuversBefore = CopyTable(draft.maneuvers) end
end

-- How many earlier maneuvers this dialog lets go.
local function Swaps()
    local draft = L.draft
    if not draft.taking then return 0 end
    return L.ManeuverLimit() > (draft.maneuverLimit or 0) and 1 or 0
end

local function Used()
    local used = 0
    for name in pairs(L.draft.maneuversBefore or NONE) do
        if not L.draft.maneuvers[name] then used = used + 1 end
    end
    return used
end

-- True if a maneuver known before the dialog opened has to stay.
function L.ManeuverLocked(name)
    local draft = L.draft
    if not (draft.maneuversBefore or NONE)[name] or not draft.maneuvers[name] then return false end
    return Used() >= Swaps()
end

-- A few words for the heading about what may still be exchanged, or "".
function L.ManeuverNote()
    local draft = L.draft
    if not draft or not next(draft.maneuversBefore or NONE) then return "" end
    if not draft.taking then return "; the ones you had stay" end
    if Swaps() == 0 then return "; earlier ones stay, one can be exchanged when you learn new ones" end
    if Used() >= Swaps() then return "; this level's exchange is made" end
    return "; one earlier maneuver may be exchanged"
end
