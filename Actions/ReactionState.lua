-- What the damage reactions keep between one damage and the next (Actions/DamageSteps.lua):
--   state.reactionUsed    a reaction was spent; back when the player says so, at
--                         initiative or after a rest
--   state.noseReady       initiative was rolled and no damage taken since (Nose for Trouble)
--   state.delayedDice     d6s in the Delayed Reaction pool (Stagger and Sway)
--   state.relentlessUses  Relentless Rage saves made since the last rest
-- and Superior Hunter's Defense's resistance for the rest of the turn, a passive marked
-- auto = "reaction:<type>" that goes when it is clicked off or at a rest.
-- Loads after Actions/Rest.lua and before Actions/RestUndo.lua, which wraps the rests too.
local _, ns = ...
local RPSheet = ns.addon

local PREFIX = "reaction:"
local HUNTER = "Superior Hunter's Defense"

local function ClearHunter(sheet, all)
    for at = #sheet.passives, 1, -1 do
        local passive = sheet.passives[at]
        if (passive.auto or ""):find("^" .. PREFIX) and (all or not passive.enabled) then table.remove(sheet.passives, at) end
    end
end

-- Resistance to damage of this type until the end of the turn.
function RPSheet:StartHunterDefense(damageType)
    if not damageType then return end
    local sheet, key = self:Sheet(), PREFIX .. damageType
    for _, passive in ipairs(sheet.passives) do
        if passive.auto == key then
            passive.enabled = true
            return
        end
    end
    sheet.passives[#sheet.passives + 1] = { name = ("%s (%s)"):format(HUNTER, damageType), auto = key, enabled = true, effects = {},
        resist = { damageType },
        desc = ("You took %s damage and used your reaction: you resist %s damage until the end of this turn. Click it off when the turn ends; a rest ends it too."):format(damageType, damageType) }
    self:PopulateSoon()
end

-- A Superior Hunter's Defense passive that was clicked off is gone at the next upkeep.
local applyWards = ns.ApplyWards
function ns.ApplyWards(sheet)
    applyWards(sheet)
    ClearHunter(sheet, false)
end

-- The reaction is back (the start of the character's turn).
function RPSheet:ReactionBack()
    self:State().reactionUsed = nil
    self:Print("Your reaction is back: the damage menu offers your reactions again.")
    self:PopulateSoon()
end

-- A rest ends a fight: what was kept for it goes.
local function AfterRest(self)
    local state = self:State()
    state.reactionUsed, state.noseReady, state.delayedDice, state.relentlessUses = nil, nil, nil, nil
    ClearHunter(self:Sheet(), true)
end
local longRest, shortRest = RPSheet.LongRest, RPSheet.ShortRest
function RPSheet:LongRest(...)
    AfterRest(self)
    return longRest(self, ...)
end
function RPSheet:ShortRest(...)
    AfterRest(self)
    return shortRest(self, ...)
end

-- Rolling initiative starts a fight: the reaction is fresh and the next damage is the first.
local rollCheck = RPSheet.RollCheck
function RPSheet:RollCheck(label, ...)
    if label == "initiative" then
        local state = self:State()
        state.noseReady, state.reactionUsed = true, nil
    end
    return rollCheck(self, label, ...)
end
