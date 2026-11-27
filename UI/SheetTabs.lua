-- The pages of the sheet. The top part (hit points, rests, conditions, combat numbers,
-- the weapon) is always there; the rest of the sheet is split over pages and only the
-- open one is drawn. The pages are picked on the window's side rail
-- (UI/WindowRail.lua).
local _, ns = ...
local UI = ns.UI

-- Puts the pages on the window's rail and returns the open one. `tabs` is a list of
-- { name, icon, tip, ... }. The choice is kept per game character. Over the entries
-- the rail says who the character is.
function UI.AddTabBar(self, body, tabs)
    local saved = self.db.char
    local open = tabs[1]
    for _, tab in ipairs(tabs) do
        if tab.name == saved.sheetTab then open = tab end
    end
    self.window:SetRail(self.db.profile.theme, self:Summary() or "No class chosen yet", tabs, open.name, function(name)
        saved.sheetTab = name
        self:PopulateSoon()
    end)
    UI.AddHeading(body, open.name):SetUserData("page", true) -- the page starts here
    return open
end
