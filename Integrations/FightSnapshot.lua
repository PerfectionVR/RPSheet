-- Combat sessions, part 5: the snapshot. Joining a session keeps the character's play
-- state (hit points, slots, resources, conditions) as it was. The fight is played on
-- the sheet as always; when it is over the player keeps the outcome or puts the state
-- from before the fight back. The character itself (levels, items) is not part of it.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local function Copy(state)
    local copy = {}
    for key, value in pairs(state) do
        if key ~= "sheet" then copy[key] = type(value) == "table" and CopyTable(value) or value end
    end
    return copy
end

function F.KeepSnapshot()
    RPSheet.db.char.fightSnapshot = { key = RPSheet.sheetKey, state = Copy(RPSheet:State()) }
end

-- True when there is a snapshot of the sheet that is open now.
function F.HasSnapshot()
    local kept = RPSheet.db.char.fightSnapshot
    return type(kept) == "table" and kept.key == RPSheet.sheetKey and type(kept.state) == "table"
end

function F.DropSnapshot()
    RPSheet.db.char.fightSnapshot = nil
    F.Changed()
end

function F.RestoreSnapshot()
    if not F.HasSnapshot() then return false end
    local state, kept = RPSheet:State(), RPSheet.db.char.fightSnapshot.state
    for key in pairs(state) do
        if key ~= "sheet" then state[key] = nil end
    end
    for key, value in pairs(Copy(kept)) do state[key] = value end
    RPSheet.db.char.fightSnapshot = nil
    RPSheet:ClampState()
    RPSheet:Populate()
    RPSheet:Print("Your hit points, slots, resources and conditions are as they were before the fight.")
    F.Changed()
    return true
end
