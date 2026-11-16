-- What a Paladin's features ask before they are used (see Actions/AbilityFlows.lua):
-- Lay on Hands asks whom it heals and how many points of the pool it spends, or which
-- condition it ends; a smite asks whether the target is a fiend or an undead, which
-- takes one more die.
local _, ns = ...
local Kit = ns.FeatureKit

local POOL = "Lay on Hands"
-- Conditions Restoring Touch can end, besides poisoned.
local RESTORING = { "Blinded", "Charmed", "Deafened", "Frightened", "Paralyzed", "Stunned" }

local function LayOnHands(self, ability, mode)
    local pool = self:FindTracker(POOL)
    if not pool then return false end
    local left = pool.get()
    if left <= 0 then
        self:Print("Your Lay on Hands pool is empty: a long rest fills it.")
        return true
    end
    local function Heal(kind, whom)
        local prompt = ("Lay on Hands: how many hit points do you restore to %s? Up to %d."):format(whom, left)
        ns.AskFeatureAmount(prompt, math.min(5, left), function(amount)
            amount = math.min(amount, pool.get())
            if amount <= 0 then return end
            ns.UseAsked(self, ability, mode, { Kit.Spend(POOL, amount), Kit.Dice(0, 4, "", kind, amount) })
        end)
    end
    local function Cure(condition)
        return function()
            ns.UseAsked(self, ability, mode, { Kit.Spend(POOL, 5) }, { name = ("%s: end %s"):format(POOL, condition:lower()) })
        end
    end
    local choices = {
        { "Heal someone else", function() Heal("HEALING", "the creature") end },
        { "Heal yourself", function() Heal("SELFHEAL", "yourself") end },
    }
    if left >= 5 then
        choices[#choices + 1] = { "End the poisoned condition (5 points)", Cure("Poisoned") }
        -- Restoring Touch: 5 points for each condition it ends.
        if ns.PassiveOn(self:Sheet(), "Restoring Touch") then
            for _, condition in ipairs(RESTORING) do
                choices[#choices + 1] = { ("End the %s condition (5 points)"):format(condition:lower()), Cure(condition) }
            end
        end
    end
    ns.FlowMenu(("Lay on Hands (%d points left)"):format(left), choices)
    return true
end
ns.ABILITY_FLOWS[POOL] = LayOnHands

-- A smite deals one more d8 against a fiend or an undead.
local function Smite(self, ability, mode)
    local function More()
        local steps = CopyTable(ability.actions)
        for _, step in ipairs(steps) do
            if step.type == "DICE" then
                step.count = step.count + 1
                break
            end
        end
        ns.UseAsked(self, ability, mode, steps)
    end
    ns.FlowMenu("Is the target a fiend or an undead?", {
        { "No", function() ns.UseAsked(self, ability, mode, ability.actions) end },
        { "Yes: 1d8 more", More },
    })
    return true
end
ns.ABILITY_FLOWS["Divine Smite"] = Smite
ns.ABILITY_FLOWS["Paladin's Smite"] = Smite
