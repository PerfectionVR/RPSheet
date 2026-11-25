-- The item browser's parts: a block with its buttons, the tabs and the search box
-- (see UI/ItemBrowser.lua for the window and what a source is).
local _, ns = ...
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local B = UI.ItemBrowserState

-- A button under a block. One that can't be used now is greyed and does nothing.
function UI.AddItemButton(card, width, text, enabled, onClick)
    local button = UI.AddButton(card, width, text, enabled and function() onClick() end or nil, nil, nil, enabled and "on" or "off")
    button:SetDisabled(not enabled)
    return button
end

local function AddCard(self, body, entry, first)
    local card = AceGUI:Create("InlineGroup")
    card:SetLayout("Flow")
    card:SetRelativeWidth(0.5)
    local marks = B.source.marks(self, entry)
    -- Among the entries of every tab, a block says which tab it is from.
    if entry.fromTab then table.insert(marks, 1, entry.fromTab.name) end
    local plain = ns.Util.HexCode(self.db.profile.theme.text) -- the title itself is in the accent colour
    card:SetTitle(#marks > 0 and ("%s  %s(%s)|r"):format(entry.name, plain, table.concat(marks, ", ")) or entry.name)
    local lines = B.source.lines and B.source.lines(self, entry) or UI.ItemLines(self, entry.name, entry.item, B.source.class(self))
    for _, line in ipairs(B.source.notes and B.source.notes(self, entry) or {}) do lines[#lines + 1] = line end
    -- Terms such as attunement and harness in the lines can be hovered.
    ns.EnableTermLinks(UI.AddLabel(card, 1, table.concat(lines, "\n")))
    B.source.buttons(self, card, entry, first)
    body:AddChild(card)
end

local function Later(self)
    C_Timer.After(0, function() self:PopulateItemBrowser() end)
end

local function AddTabs(self, body)
    local tabs, found = { B.source.first }, B.open == B.source.first
    local kinds = type(B.source.kinds) == "function" and B.source.kinds(self) or B.source.kinds
    for _, tab in ipairs(kinds) do
        tabs[#tabs + 1] = tab
        found = found or tab == B.open
    end
    if not found then B.open = B.source.first end -- its tab is gone
    -- (while the search goes over every tab none is the open one, and each can be clicked)
    UI.AddTabStrip(body, tabs, not B.everywhere and B.open.name or nil, function(name)
        for _, tab in ipairs(tabs) do
            if tab.name == name then B.open = tab end
        end
        B.everywhere = false -- a tab is one tab again
        Later(self)
    end)
end

-- The search box, and next to it the button that makes the search go over every tab
-- of the source at once and back.
local function AddSearch(self, body)
    local box = AceGUI:Create("EditBox")
    box:SetLabel(B.everywhere and "Search names and descriptions in every tab (press Enter; empty shows everything)"
        or "Search names and descriptions in this tab (press Enter; empty shows everything)")
    box:SetText(B.search)
    box:SetRelativeWidth(0.7)
    box:SetCallback("OnEnterPressed", function(_, _, text)
        B.search = strtrim(text or ""):lower()
        Later(self)
    end)
    body:AddChild(box)
    UI.AddItemButton(body, 0.3, B.everywhere and "This tab only" or "Search everything", true, function()
        B.everywhere = not B.everywhere
        Later(self)
    end)
end

UI.ItemBrowserParts = { AddCard = AddCard, Later = Later, AddTabs = AddTabs, AddSearch = AddSearch }
