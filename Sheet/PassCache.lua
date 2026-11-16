-- One rebuild of the sheet window asks for the same numbers again and again: what the
-- passives and items add to a number (RPSheet:Bonus), what sets a number
-- (RPSheet:EffectFloor), the form the character is in (RPSheet:Form). Each of those
-- walks every passive and item of the sheet. While a pass is open the answers are
-- kept, so each is worked out once.
--
-- A pass is open only while the window's rows are being made (RPSheet:Populate in
-- UI/SheetContent.lua), which reads the sheet and changes nothing, and it is closed
-- before anything else runs: an answer never outlives a change to the sheet. Outside
-- a pass these functions work as they always did.
--
-- This file loads after the files that define the three functions and wraps them.
local _, ns = ...
local RPSheet = ns.addon

local kept         -- the answers of the open pass, or nil when none is open
local depth = 0    -- a pass opened inside a pass belongs to the outer one
local NOTHING = {} -- stands for an answer of nil

function ns.BeginPass()
    depth = depth + 1
    if depth == 1 then kept = { bonus = {}, floor = {}, floorFrom = {} } end
end

function ns.EndPass()
    depth = math.max(0, depth - 1)
    if depth == 0 then kept = nil end
end

-- For the tests (ns.checkPass): a kept answer must be what working it out again gives,
-- or something changed the sheet while the rows were being made.
local function Same(what, known, fresh)
    if ns.checkPass and known ~= fresh then
        error(("a number kept for the rebuild went stale: %s was %s and is now %s"):format(what, tostring(known), tostring(fresh)), 2)
    end
end

local Bonus = RPSheet.Bonus
function RPSheet:Bonus(target)
    if not kept or target == nil then return Bonus(self, target) end
    local known = kept.bonus[target]
    if known == nil then
        known = Bonus(self, target)
        kept.bonus[target] = known
    elseif ns.checkPass then
        Same("Bonus " .. target, known, (Bonus(self, target)))
    end
    return known
end

local EffectFloor = RPSheet.EffectFloor
function RPSheet:EffectFloor(target)
    if not kept or target == nil then return EffectFloor(self, target) end
    local known = kept.floor[target]
    if known == nil then
        local best, from = EffectFloor(self, target)
        known = best or NOTHING
        kept.floor[target], kept.floorFrom[target] = known, from
    elseif ns.checkPass then
        Same("EffectFloor " .. target, known, (EffectFloor(self, target)) or NOTHING)
    end
    if known == NOTHING then return nil, nil end
    return known, kept.floorFrom[target]
end

local Form = RPSheet.Form
function RPSheet:Form()
    if not kept then return Form(self) end
    local known = kept.form
    if known == nil then
        known = Form(self) or NOTHING
        kept.form = known
    elseif ns.checkPass then
        Same("Form", known, Form(self) or NOTHING)
    end
    if known == NOTHING then return end
    return known
end
