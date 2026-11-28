-- The pages of the sheet. The top part (hit points, rests, conditions, combat numbers,
-- the weapon) is always there; under it is a strip of tabs, and under the tabs the
-- rows of the open page. Only the open page is drawn.
local _, ns = ...
local UI = ns.UI

-- Adds the strip of tabs and returns the open one. `tabs` is a list of
-- { name, tip, ... }. The choice is kept per game character. `self.sheetPages` lists
-- the tabs shown: { frame, name, open, text }.
function UI.AddTabBar(self, body, tabs)
    local saved = self.db.char
    local open = tabs[1]
    for _, tab in ipairs(tabs) do
        if tab.name == saved.sheetTab then open = tab end
    end
    -- The lower part starts here, after a blank line.
    UI.AddHeading(body, ""):SetUserData("page", true)
    self.sheetPages = {}
    for index, button in ipairs(UI.AddTabStrip(body, tabs, open.name, function(name)
        saved.sheetTab = name
        self:PopulateSoon()
    end)) do
        self.sheetPages[index] = { frame = button.frame, name = tabs[index].name, open = tabs[index] == open, text = button.text }
    end
    return open
end
