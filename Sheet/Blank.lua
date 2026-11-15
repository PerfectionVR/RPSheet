-- Saved entries that hold no character are not kept.
--
-- Every key the addon looks at gets a sheet: each alt, each Total RP 3 profile, the
-- character's own key while Total RP 3 is still starting. Bringing a sheet into shape
-- (ns.NormalizeState) adds fields that are not defaults, so the saved-variables library
-- would keep about a kilobyte for each of them for ever. At logout the entries that
-- are still blank are taken out, those of earlier versions included.
--
-- Blank is judged strictly: the wizard was never finished or skipped, and nothing in
-- the entry differs from what a new one holds. Anything else stays: a character, one
-- half made by hand, a sheet of an old version, an entry this version can't read.
local _, ns = ...

-- Current values that follow from the character and are filled in on first use. They
-- say nothing about whether there is one.
local FOLLOWS = { hp = true, hitDice = true, hitDiceMore = true, pool = true, slots = true, pactSlots = true, res = true }

-- A new entry as it is after being brought into shape. Made on first use: the rules
-- data it is shaped by is complete by then.
local blank
local function Blank()
    if not blank then
        blank = CopyTable(ns.defaults.global.sheets["*"])
        ns.NormalizeState(blank)
    end
    return blank
end

-- A table with nothing in it, however deep.
local function Hollow(value)
    if type(value) ~= "table" then return false end
    for _, inner in pairs(value) do
        if not Hollow(inner) then return false end
    end
    return true
end

-- True when everything in `saved` is in `new` too, with the same value. (What `new` has
-- and `saved` lacks is a default that was left out when saving.)
local function Within(saved, new, skip)
    for key, value in pairs(saved) do
        if not (skip and skip[key]) then
            local same = new[key]
            if type(value) == "table" then
                if type(same) == "table" then
                    if not Within(value, same) then return false end
                elseif same ~= nil or not Hollow(value) then
                    return false
                end
            elseif value ~= same then
                return false
            end
        end
    end
    return true
end

-- True for a saved entry that holds no character and nothing else worth keeping.
function ns.IsBlankState(state)
    if type(state) ~= "table" then return false end
    return Within(state, Blank(), FOLLOWS)
end

-- Takes the blank entries out of the saved sheets. Returns how many.
function ns.DropBlankSheets(sheets)
    local dropped = 0
    if type(sheets) ~= "table" then return dropped end
    for key, state in pairs(sheets) do
        -- An entry that can't even be looked at is not ours to throw away.
        local ok, isBlank = pcall(ns.IsBlankState, state)
        if ok and isBlank then
            sheets[key] = nil
            dropped = dropped + 1
        end
    end
    return dropped
end
