-- The row of tabs under the top part of the sheet. The top part (hit points, rests,
-- conditions, combat numbers, the weapon) is always there; the rest of the sheet is
-- split over the tabs and only the open one is drawn.
local _, ns = ...
local UI = ns.UI

-- Adds the tab row and returns the open tab. `tabs` is a list of { name, tip, ... }.
-- The choice is kept per game character.
function UI.AddTabBar(self, body, tabs)
    local saved = self.db.char
    local open = tabs[1]
    for _, tab in ipairs(tabs) do
        if tab.name == saved.sheetTab then open = tab end
    end
    UI.AddLabel(body, 1, " ") -- a blank line between the top part and the tabs
    for _, tab in ipairs(tabs) do
        local text = tab == open and ("%s[%s]|r"):format(UI.ACCENT, tab.name) or (UI.GREY .. tab.name .. "|r")
        UI.AddLabel(body, 1 / #tabs, text, function()
            saved.sheetTab = tab.name
            self:PopulateSoon()
        end, tab.name, tab.tip)
    end
    return open
end
