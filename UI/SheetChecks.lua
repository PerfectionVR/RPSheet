-- The sheet's ability checks and saving throws, each a roll to click.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

function UI.CheckSection(self, body)
    UI.AddHeading(body, "Ability checks")
    for _, stat in ipairs(R.STATS) do
        local mod = self:CheckMod(stat)
        UI.AddLabel(body, 0.33, ("%s %d %s(%s)|r"):format(stat, self:Score(stat), UI.GREY, Signed(mod)),
            function() self:RollCheck(stat .. " check", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat], ("%s\n\nClick to roll a %s check.\n%s"):format(ns.Glossary[stat], R.STAT_NAMES[stat], ns.ROLL_MODE_HELP),
            function() self:ExplainCheck(stat) end)
    end
end

function UI.SaveSection(self, body)
    local saves = self:Sheet().saves
    UI.AddHeading(body, "Saving throws")
    for _, stat in ipairs(R.STATS) do
        local mod = self:SaveMod(stat)
        local name = saves[stat] and (UI.ACCENT .. stat .. "|r") or stat
        UI.AddLabel(body, 0.33, ("%s %s%s|r"):format(name, UI.GREY, Signed(mod)),
            function() self:RollCheck(stat .. " save", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat] .. " saving throw",
            ("%s\n\n%s\n\n%s"):format(saves[stat] and "Proficient." or "Not proficient.", ns.Glossary["Saving throw"], ns.ROLL_MODE_HELP),
            function() self:ExplainSave(stat) end)
    end
end
