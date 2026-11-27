-- The sheet's ability checks and saving throws, each a tile to click for the roll; a
-- right-click shows how the number is worked out (UI.AddRollLabel).
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

function UI.CheckSection(self, body)
    UI.AddHeading(body, "Ability checks")
    for _, stat in ipairs(R.STATS) do
        local mod = self:CheckMod(stat)
        UI.AddRollLabel(body, 0.33, ("%s %d\n%s"):format(stat, self:Score(stat), Signed(mod)),
            function() self:RollCheck(stat .. " check", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat],
            function() return ("%s\n\nClick to roll a %s check.\n%s"):format(ns.Glossary[stat], R.STAT_NAMES[stat], ns.ROLL_MODE_HELP) end,
            function() self:ExplainCheck(stat) end, "tile")
    end
end

function UI.SaveSection(self, body)
    local saves = self:Sheet().saves
    UI.AddHeading(body, "Saving throws")
    for _, stat in ipairs(R.STATS) do
        local mod = self:SaveMod(stat)
        local name = saves[stat] and (UI.MARK .. stat .. ", proficient|r") or stat
        UI.AddRollLabel(body, 0.33, ("%s\n%s"):format(name, Signed(mod)),
            function() self:RollCheck(stat .. " save", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat] .. " saving throw",
            -- Advantage that only counts against some things is named too (Sheet/SaveAdvantages.lua).
            function()
                local advantage = self:SaveAdvantageText(stat)
                return ("%s%s\n\n%s\n\n%s"):format(saves[stat] and "Proficient." or "Not proficient.",
                    advantage and ("\n\n" .. advantage) or "", ns.Glossary["Saving throw"], ns.ROLL_MODE_HELP)
            end,
            function() self:ExplainSave(stat) end, "tile")
    end
end
