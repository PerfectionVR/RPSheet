-- Greater Divine Intervention (see Actions/AbilityFlows.lua): Divine Intervention can
-- cast Wish, and then stays spent until 2d4 long rests have passed. The roll is kept in
-- state.interventionRests, counted down by each long rest (Actions/Rest.lua).
local _, ns = ...
local Kit = ns.FeatureKit
local RPSheet = ns.addon

local NAME = "Divine Intervention"

ns.ABILITY_FLOWS[NAME] = function(self, ability, mode)
    if not ns.PassiveOn(self:Sheet(), "Greater Divine Intervention") then return false end
    ns.FlowMenu("Divine Intervention: which spell?", {
        { "A Cleric spell of 5th level or lower", function() ns.UseAsked(self, ability, mode, ability.actions) end },
        { "Wish: back after 2d4 long rests", function()
            ns.UseAsked(self, ability, mode, { ability.actions[1], Kit.Dice(2, 4, "", "OTHER") },
                { name = NAME .. ": Wish", lockRests = true })
        end },
    })
    return true
end

-- The 2d4 just rolled for Wish: how many long rests it stays spent. Returns the note.
function RPSheet:LockIntervention(rolls)
    local total = 0
    for _, roll in ipairs(rolls) do total = total + roll end
    self:State().interventionRests = total
    return ("Divine Intervention returns after %d long rests"):format(total)
end

-- Called by a long rest once everything is back: counts one rest off, and keeps
-- Divine Intervention spent while some are left.
function RPSheet:InterventionAfterRest()
    local state = self:State()
    local left = tonumber(state.interventionRests)
    if not left or left <= 0 then
        state.interventionRests = nil
        return
    end
    left = left - 1
    state.interventionRests = left > 0 and left or nil
    if left > 0 then
        local tracker = self:FindTracker(NAME)
        if tracker then tracker.set(0) end
        self:Print(("Divine Intervention stays spent after casting Wish: %d more long %s."):format(left, left == 1 and "rest" or "rests"))
    end
end
