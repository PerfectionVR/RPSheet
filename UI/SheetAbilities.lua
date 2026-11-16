-- The sheet's abilities: click to use one, right-click to take a cost back (or to
-- roll for a beast's action that recharges). A right-click never uses the ability.
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
        -- A beast's action with a limit shows what is left of it (Actions/BeastUses.lua).
        local uses = self:BeastUseText(ability)
        UI.AddLabel(body, 1, uses and ("%s  %s%s|r"):format(ability.name, UI.GREY, uses) or ability.name, function(button)
            if button == "RightButton" then
                -- A right-click takes back a cost that turned out not to be spent, if one
                -- is open, or rolls a recharge. It never does the left-click's job.
                if self:TakeBack(ability.name) or self:RollBeastRecharge(ability) then return end
                self:Print(("Nothing to take back for %s: a right-click only takes back a cost that turned out not to be spent."):format(ability.name))
                return
            end
            self:UseAbility(ability, ns.RollMode())
        end, ability.name, function() return Tip(self, ability) end)
    end
end
