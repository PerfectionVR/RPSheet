-- The sheet's passives and traits, each a switch.
local _, ns = ...
local UI = ns.UI
local Util = ns.Util

-- What a passive's tooltip says: its text, what it adds, and whether it counts now.
-- Worked out when it is hovered.
local function Tip(self, passive)
    local lines = {}
    if passive.desc ~= "" then lines[#lines + 1] = passive.desc end
    for _, effect in ipairs(passive.effects) do
        lines[#lines + 1] = UI.GREEN .. self:EffectText(effect) .. "|r"
    end
    local stopped = self:PassiveBlocked(passive)
    if stopped then lines[#lines + 1] = ("Not counted now: you have %s on."):format(stopped) end
    lines[#lines + 1] = "|cff909090Click to switch " .. (passive.enabled and "off" or "on") .. "|r"
    return table.concat(lines, "\n")
end

function UI.PassiveSection(self, body)
    local passives = Util.Named(self:Sheet().passives)
    if #passives == 0 then return end
    UI.AddHeading(body, "Passives and traits")
    for _, passive in ipairs(passives) do
        local text = passive.enabled and passive.name or (UI.GREY .. passive.name .. " (off)|r")
        UI.AddLabel(body, 0.5, text, function()
            passive.enabled = not passive.enabled
            if passive.enabled then self:PassiveSwitchedOn(passive) end -- some end others
            self:ClampState()
            self:PopulateSoon()
        end, passive.name, function() return Tip(self, passive) end)
    end
end
