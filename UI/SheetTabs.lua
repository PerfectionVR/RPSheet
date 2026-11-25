-- The strip of tabs under the top part of the sheet. The top part (hit points, rests,
-- conditions, combat numbers, the weapon) is always there; the rest of the sheet is
-- split over the tabs and only the open one is drawn. A tab's look is in UI/Tab.lua,
-- the strip in UI/Parts.lua.
local _, ns = ...
local UI = ns.UI

-- Adds the tab strip and returns the open tab. `tabs` is a list of { name, tip, ... }.
-- The choice is kept per game character.
function UI.AddTabBar(self, body, tabs)
    local saved = self.db.char
    local open = tabs[1]
    for _, tab in ipairs(tabs) do
        if tab.name == saved.sheetTab then open = tab end
    end
    UI.AddLabel(body, 1, " ") -- a blank line between the top part and the tabs
    UI.AddTabStrip(body, tabs, open.name, function(name)
        saved.sheetTab = name
        self:PopulateSoon()
    end)
    return open
end
