-- Taking a rest back. A rest happens at one click and changes a lot: hit points,
-- slots, resources, what was running. Instead of asking "are you sure?" every time,
-- the play state from just before the last rest is kept in memory (never saved), and
-- "/sheet undo" or a right-click on the rest's row puts it back, until the next roll,
-- spell, damage or rest, or any change to the character.
--
-- This wraps RPSheet:LongRest and RPSheet:ShortRest (Actions/Rest.lua), so it must load
-- after that file.
local _, ns = ...
local RPSheet = ns.addon

local longRest, shortRest = RPSheet.LongRest, RPSheet.ShortRest

local kept            -- the last rest, while it can still be taken back
local resting = false -- a rest is running: what it announces itself doesn't count

-- Whatever is announced after a rest (a roll, a spell, damage, a condition) settles
-- it. Called by RPSheet:Announce.
function ns.RestUndoExpire()
    if not resting then kept = nil end
end

local function Same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do
        if not Same(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function Rest(self, name, rest)
    local state = self:State()
    local before = { key = self.sheetKey, name = name, state = CopyTable(state), refunds = self.refunds }
    kept, resting = nil, true
    local ok, problem = pcall(rest, self)
    resting = false
    if not ok then error(problem, 0) end
    -- The character as the rest left it: if it is changed afterwards (a level, an
    -- item bought, an edit under Customize), putting the old one back would undo that too.
    before.sheet, before.after = state.sheet, CopyTable(state.sheet)
    kept = before
    self:Print(("Rested by mistake? |cffffd100/sheet undo|r (or a right-click on the rest) takes the %s back, until your next roll, spell or damage."):format(name))
end

function RPSheet:LongRest()
    Rest(self, "long rest", longRest)
end

function RPSheet:ShortRest()
    Rest(self, "short rest", shortRest)
end

-- Why the last rest can't be taken back, or nil when it can.
local function Refusal(self)
    if kept and (kept.key ~= self.sheetKey or self:State().sheet ~= kept.sheet) then kept = nil end -- another character now
    if not kept then
        return "There is no rest to take back: only the last one, and only until your next roll, spell, damage or rest."
    end
    if self.busy or self:IsRolling() then return "Wait for the roll to finish." end
    if not Same(self:Sheet(), kept.after) then
        kept = nil
        return "The character was changed since the rest, so it can't be taken back any more."
    end
end

-- Puts everything back as it was just before the last rest, and tells the channel the
-- rest was announced on. Returns true when it did.
function RPSheet:UndoRest()
    local why = Refusal(self)
    if why then
        self:Print(why)
        return false
    end
    local state, name = self:State(), kept.name
    wipe(state)
    for key, value in pairs(kept.state) do state[key] = value end
    self.refunds = kept.refunds
    kept = nil
    ns.NormalizeState(state)
    self:ClampState()
    ns.RebuildOptions()
    self:PopulateSoon()
    self:Announce(("takes back the %s: everything is as it was before it."):format(name))
    self:QueueBroadcast()
    return true
end
