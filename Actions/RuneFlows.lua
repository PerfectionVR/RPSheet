-- What a Death Knight's Runic Power and Runic Mastery ask before they are used (see
-- Actions/AbilityFlows.lua and Data/Runes.lua): while Aspect of the Horsemen is on,
-- which rune's effect; with the Blood rune, Runic Power asks how much necrotic damage
-- the Rune Strike dealt, suggesting the last one the sheet rolled.
local _, ns = ...

local SUBCLASS = "Oath of the Ebon Blade"
local ASPECT = "Aspect of the Horsemen active"

-- `first` (the step that pays) followed by `rest`.
local function With(first, rest)
    local steps = { first }
    for _, step in ipairs(rest) do steps[#steps + 1] = step end
    return steps
end

-- Calls go(rune): the character's own, or the one picked while the Aspect is on.
-- Returns false when nothing needs asking and the ability can go as it is.
local function PickRune(self, title, go, needsOwn)
    local sheet = self:Sheet()
    if ns.PassiveOn(sheet, ASPECT) then
        local choices = {}
        for _, rune in ipairs(ns.RUNES) do choices[#choices + 1] = { rune, function() go(rune) end } end
        ns.FlowMenu(title, choices)
        return true
    end
    local view = ns.SubclassView(sheet, SUBCLASS) or sheet
    if not needsOwn(view.spec) then return false end
    go(view.spec)
    return true
end

ns.ABILITY_FLOWS["Runic Power"] = function(self, ability, mode)
    return PickRune(self, "Runic Power: which rune's effect?", function(rune)
        if rune ~= "Blood" then
            return ns.UseAsked(self, ability, mode, With(ability.actions[1], ns.RunicPowerSteps(rune)))
        end
        ns.AskFeatureAmount("Runic Power: how much necrotic damage did your Rune Strike deal? You regain that many hit points.",
            self.runeStrikeDamage or 0, function(amount)
                ns.UseAsked(self, ability, mode, With(ability.actions[1], ns.RunicPowerSteps("Blood", amount)))
            end)
    end, function(own) return own == "Blood" end)
end

ns.ABILITY_FLOWS["Runic Mastery"] = function(self, ability, mode)
    local view = ns.SubclassView(self:Sheet(), SUBCLASS) or self:Sheet()
    return PickRune(self, "Runic Mastery: which rune's effect?", function(rune)
        ns.UseAsked(self, ability, mode, With(ability.actions[1], ns.RunicMasterySteps(rune, view.level)))
    end, function() return false end)
end
