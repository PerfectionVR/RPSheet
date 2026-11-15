-- The sheet's abilities: click to use one, right-click to take a cost back.
local _, ns = ...
local UI = ns.UI
local Util = ns.Util

-- What an ability's tooltip says: its text and its steps. Worked out when it is hovered.
local function Tip(self, ability)
    local lines = {}
    if ability.desc ~= "" then lines[#lines + 1] = ability.desc end
    for _, action in ipairs(ability.actions) do
        lines[#lines + 1] = UI.GREEN .. self:ActionText(action) .. "|r"
    end
    return table.concat(lines, "\n")
end

function UI.AbilitySection(self, body)
    local abilities = Util.Named(self:Sheet().abilities)
    if #abilities == 0 then return end
    UI.AddHeading(body, "Abilities")
    for _, ability in ipairs(abilities) do
        UI.AddLabel(body, 1, ability.name, function(button)
            -- A right-click takes back a cost that turned out not to be spent, if one is open.
            if button == "RightButton" and self:TakeBack(ability.name) then return end
            self:UseAbility(ability, ns.RollMode())
        end, ability.name, function() return Tip(self, ability) end)
    end
end
