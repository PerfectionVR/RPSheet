-- The item browser's parts: a block with its buttons, the tabs and the search box
-- (see UI/ItemBrowser.lua for the window and what a source is).
local _, ns = ...
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local B = UI.ItemBrowserState

-- A button under a block. It is a hair narrower than asked: buttons whose widths add
-- up to the full row could otherwise be rounded past it, and the last one would wrap.
function UI.AddItemButton(card, width, text, enabled, onClick)
    local button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetRelativeWidth(width * 0.999)
    button:SetDisabled(not enabled)
    button:SetCallback("OnClick", onClick)
    card:AddChild(button)
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
    UI.AddLabel(card, 1, table.concat(lines, "\n"))
    B.source.buttons(self, card, entry, first)
    body:AddChild(card)
end

local function Later(self)
    C_Timer.After(0, function() self:PopulateItemBrowser() end)
end

local function AddTabs(self, body)
    local theme = self.db.profile.theme
    local tabs, found = { B.source.first }, B.open == B.source.first
    local kinds = type(B.source.kinds) == "function" and B.source.kinds(self) or B.source.kinds
    for _, tab in ipairs(kinds) do
        tabs[#tabs + 1] = tab
        found = found or tab == B.open
    end
    if not found then B.open = B.source.first end -- its tab is gone
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab == B.open and not B.everywhere)
        button:SetText(tab.name)
        button:SetRelativeWidth(0.999 / #tabs) -- a hair under an even share: see UI/SheetTabs.lua
        button:SetCallback("OnClick", function()
            B.open, B.everywhere = tab, false -- a tab is one tab again
            Later(self)
        end)
        body:AddChild(button)
    end
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
