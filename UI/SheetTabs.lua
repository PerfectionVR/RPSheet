-- The strip of tabs under the top part of the sheet. The top part (hit points, rests,
-- conditions, combat numbers, the weapon) is always there; the rest of the sheet is
-- split over the tabs and only the open one is drawn. A tab's look is in UI/Tab.lua.
local _, ns = ...
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

-- Adds the tab strip and returns the open tab. `tabs` is a list of { name, tip, ... }.
-- The choice is kept per game character.
function UI.AddTabBar(self, body, tabs)
    local saved, theme = self.db.char, self.db.profile.theme
    local open = tabs[1]
    for _, tab in ipairs(tabs) do
        if tab.name == saved.sheetTab then open = tab end
    end
    UI.AddLabel(body, 1, " ") -- a blank line between the top part and the tabs
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab == open)
        button:SetText(tab.name)
        -- A hair under an even share: the shares are added up as they are laid out, and
        -- rounding can push the sum past the full width, which drops the last tab a row.
        button:SetRelativeWidth(0.999 / #tabs)
        button:SetCallback("OnClick", function()
            if tab == open then return end
            saved.sheetTab = tab.name
            self:PopulateSoon()
        end)
        button:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:AddLine(tab.name)
            GameTooltip:AddLine(tab.tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetCallback("OnLeave", GameTooltip_Hide)
        body:AddChild(button)
    end
    return open
end
