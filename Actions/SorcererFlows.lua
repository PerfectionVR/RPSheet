-- Arcane Apotheosis (see Actions/AbilityFlows.lua): while Innate Sorcery is on, one
-- Metamagic option on each of your turns costs no Sorcery Points. The sheet keeps no
-- turns, so clicking a Metamagic option then asks whether this is that free one.
local _, ns = ...
local R = ns.Rules

local function Metamagic(self, ability, mode)
    local sheet = self:Sheet()
    if not (ns.PassiveOn(sheet, "Arcane Apotheosis") and ns.PassiveOn(sheet, "Innate Sorcery active")) then return false end
    local free = {}
    for _, step in ipairs(ability.actions) do
        if step.type ~= "SPEND" then free[#free + 1] = step end
    end
    ns.FlowMenu(("%s: Innate Sorcery is on"):format(ability.name), {
        { "Free: this turn's option of Arcane Apotheosis", function()
            ns.UseAsked(self, ability, mode, free, { name = ability.name .. " (free, Arcane Apotheosis)" })
        end },
        { "Spend the Sorcery Points", function() ns.UseAsked(self, ability, mode, ability.actions) end },
    })
    return true
end

for name in pairs(R.PICK_LISTS.metamagic.items) do ns.ABILITY_FLOWS[name] = Metamagic end
