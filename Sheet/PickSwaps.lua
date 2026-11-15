-- Exchanging picks when a level is gained. Some lists let only so many of the picks
-- made at earlier levels be given up for others at a level-up: one Mystic Arcanum
-- spell, one prepared spell of a class that changes them by level. The list says so
-- with `swapGroup` and `swaps` (Data/Picks.lua); the level dialog asks here.
--   before  { [list] = { [name] = true } }  the picks the character had before the level
--   picks   the same shape: the picks as they are being made
--   like    the character as the dialog would leave it, for a list's own check
local _, ns = ...
local R = ns.Rules

local NONE = {}

-- How many earlier picks of a group have been given up. A pick the rules took away
-- (a spell that is always prepared now) is not an exchange.
function ns.PickSwapsUsed(group, before, picks, like)
    local used = 0
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        if list.swapGroup == group then
            local now = picks[key] or NONE
            for name in pairs(before[key] or NONE) do
                if list.items[name] and not now[name] and not (list.blocked and list.blocked(like, name)) then
                    used = used + 1
                end
            end
        end
    end
    return used
end

-- True if an earlier pick has to stay: the exchanges of this level are used up.
function ns.PickSwapLocked(key, name, before, picks, like)
    local list = R.PICK_LISTS[key]
    if not list.swaps or not (before[key] or NONE)[name] or not (picks[key] or NONE)[name] then return false end
    return ns.PickSwapsUsed(list.swapGroup, before, picks, like) >= list.swaps
end

-- A few words for the list's heading about what may still be exchanged, or "".
function ns.PickSwapNote(key, before, picks, like)
    local list = R.PICK_LISTS[key]
    if not list.swaps or not next(before[key] or NONE) then return "" end
    if list.swaps == 0 then return "; earlier spells stay, you change them after a long rest" end
    local left = list.swaps - ns.PickSwapsUsed(list.swapGroup, before, picks, like)
    if left <= 0 then return "; this level's exchange is made" end
    return "; one earlier spell may be exchanged"
end
