-- The Combat section's rows for what the character shrugs off: damage it resists, is
-- immune to or is vulnerable to, and conditions it can't be put under (gathered in
-- Sheet/Defenses.lua). A row is only there when it has something to say.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local SWITCH = "\n\nEach follows the passive, form or condition named behind it: switch that off and it goes. A passive of your own counts when its text says so, for example \"resistance to fire damage\" or \"immune to poison damage\"."

local ROWS = {
    { field = "resist", label = "Resists", title = "Resistances",
      tip = "You take half damage of these types, rounded down. Take damage, under the bars, works it out." },
    { field = "immune", label = "Immune to", title = "Immunities",
      tip = "You take no damage of these types." },
    { field = "vulnerable", label = "Vulnerable to", title = "Vulnerabilities",
      tip = "You take double damage of these types. A type you also resist is halved first, then doubled." },
    { field = "conditionImmune", label = "Can't be", title = "Condition immunities", conditions = true,
      tip = "Conditions you can't be put under. The sheet doesn't stop you from ticking them: it is a reminder." },
}

function UI.AddDefenseRows(addon, body)
    local defenses = addon:Defenses()
    for _, row in ipairs(ROWS) do
        local names, lines = ns.DefenseNames(defenses[row.field])
        if #names > 0 then
            local shown
            if row.conditions then
                for index, name in ipairs(names) do names[index] = name:lower() end
                shown = table.concat(names, ", ")
            else
                shown = R.DamageList(names)
            end
            UI.AddLabel(body, 1, ("%s %s%s|r"):format(row.label, UI.ACCENT, shown), nil, row.title,
                row.tip .. "\n\n" .. table.concat(lines, "\n") .. SWITCH)
        end
    end
end
