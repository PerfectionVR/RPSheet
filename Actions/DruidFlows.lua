-- What a Druid's Nature Magician asks before it is used (see Actions/AbilityFlows.lua):
-- how many Wild Shape uses become one spell slot, two slot levels for each.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

local USES = "Wild Shape"

ns.ABILITY_FLOWS["Nature Magician"] = function(self, ability, mode)
    local uses = self:FindTracker(USES)
    local left = uses and uses.get() or 0
    if left <= 0 then
        self:Print("Nature Magician: you have no Wild Shape uses left to turn into a spell slot.")
        return true
    end
    local choices = {}
    for count = 1, math.min(left, 4) do -- two levels a use, a 9th-level slot at most
        local level = 2 * count
        choices[#choices + 1] = { ("%d %s: a %s-level slot"):format(count, count == 1 and "use" or "uses", R.ORDINALS[level]), function()
            ns.UseAsked(self, ability, mode, { ability.actions[1], Kit.Spend(USES, count), { type = "SLOTS", mode = "MAKE", level = level } })
        end }
    end
    ns.FlowMenu("Nature Magician: how many Wild Shape uses?", choices)
    return true
end
