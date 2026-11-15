-- The sheet's conditions row (a menu of tick boxes) and exhaustion.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

-- What the character is under: conditions (a menu of tick boxes) and exhaustion.
function UI.ConditionSection(self, body)
    local active = self:Conditions()
    local lines = {}
    for _, condition in ipairs(R.CONDITIONS) do
        if self:State().conditions[condition.name] then
            lines[#lines + 1] = ("%s%s|r: %s"):format(UI.ACCENT, condition.name, condition.desc)
        end
    end
    lines[#lines + 1] = "Click to choose the conditions you are under."
    local label
    label = UI.AddLabel(body, 1,
        ("Conditions %s%s|r"):format(UI.ACCENT, #active > 0 and table.concat(active, ", ") or "none"),
        function() self:OpenConditionMenu(label.frame) end, "Conditions", table.concat(lines, "\n\n"))

    local exhaustion = self:Exhaustion()
    UI.AddLabel(body, 1, ("Exhaustion %s%d|r"):format(exhaustion > 0 and "|cffff5555" or UI.ACCENT, exhaustion),
        function(button) self:ChangeExhaustion(button == "RightButton" and -1 or 1) end,
        "Exhaustion", R.EXHAUSTION_HELP .. "\n\nLeft-click +1, right-click -1.")
end
