-- The item browser: a window of its own that shows items as blocks, each saying what
-- it is and does, with buttons under it. What is listed and what the buttons do comes
-- from a source: the character's inventory (UI/ItemBrowserSheet.lua) or the starting
-- closet of the creation wizard (Wizard/ClosetBrowser.lua).
--
-- A source is a table of:
--   title(self)            the window's title
--   first                  { name, tip }: the tab for what was taken or is carried
--   kinds                  the other tabs, a list of { name, kind } (Rules.ITEM_NAMES)
--   standing(self)         the line above the tabs
--   own(self)              entries for the first tab, a list of { name, item }
--   find(self, name)       the carried entry of that name, or nil
--   marks(self, entry)     words after the block's title ("you have 2", "equipped")
--   class(self)            the class whose training the blocks are judged by
--   buttons(self, card, entry, first)   adds the block's buttons
--   empty                  what the first tab says when there is nothing in it
--   gone()                 optional: true when the source no longer applies
--   names(kind)            optional: the names of a tab, when they are not items
--   lines(self, entry)     optional: what a block says, when it is not an item
--   options()              optional: opens the Customize page behind the cog
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

local source     -- what the window is showing
local open       -- the open tab: source.first or one of source.kinds
local search = ""

local function Build(self)
    local profile = self.db.profile
    profile.itemWindow = profile.itemWindow or { width = 560, height = 520 }

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(profile.itemWindow)
    window:SetLayout("Fill")
    -- Above the settings window and the wizard, which open it.
    window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    window.frame:SetToplevel(true)
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnMinimizeClick", function() window:SetMinimized(not window.minimized) end)
    window:SetCallback("OnEditClick", function() (source and source.options or ns.OpenInventoryOptions)() end)
    window:SetCallback("OnShow", function() self:PopulateItemBrowser() end)
    self.itemWindow = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.itemBody = body
end

-- Shows the browser on a source; on the one it already shows, this closes it.
function RPSheet:ShowItemBrowser(wanted)
    local same = source == wanted
    if not same then
        source, open, search = wanted, wanted.first, ""
    end
    if not self.itemWindow then
        Build(self) -- a new window is already shown
    elseif same and self.itemWindow.frame:IsShown() then
        self.itemWindow:Hide()
        return
    else
        self.itemWindow:Show()
    end
    self.itemWindow.frame:Raise()
    self:PopulateItemBrowser()
end

-- Closes the browser if it is showing that source.
function RPSheet:HideItemBrowser(shown)
    if self.itemWindow and source == shown then self.itemWindow:Hide() end
end

-- A button under a block.
function UI.AddItemButton(card, width, text, enabled, onClick)
    local button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetRelativeWidth(width)
    button:SetDisabled(not enabled)
    button:SetCallback("OnClick", onClick)
    card:AddChild(button)
end

local function AddCard(self, body, entry, first)
    local card = AceGUI:Create("InlineGroup")
    card:SetLayout("Flow")
    card:SetRelativeWidth(0.5)
    local marks = source.marks(self, entry)
    card:SetTitle(#marks > 0 and ("%s  |cffffffff(%s)|r"):format(entry.name, table.concat(marks, ", ")) or entry.name)
    local lines = source.lines and source.lines(self, entry) or UI.ItemLines(self, entry.name, entry.item, source.class(self))
    UI.AddLabel(card, 1, table.concat(lines, "\n"))
    source.buttons(self, card, entry, first)
    body:AddChild(card)
end

local function Later(self)
    C_Timer.After(0, function() self:PopulateItemBrowser() end)
end

local function AddTabs(self, body)
    local theme = self.db.profile.theme
    local tabs = { source.first }
    for _, tab in ipairs(source.kinds) do tabs[#tabs + 1] = tab end
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab == open)
        button:SetText(tab.name)
        button:SetRelativeWidth(1 / #tabs)
        button:SetCallback("OnClick", function()
            open = tab
            Later(self)
        end)
        body:AddChild(button)
    end
end

local function AddSearch(self, body)
    local box = AceGUI:Create("EditBox")
    box:SetLabel("Search in this tab (press Enter; empty shows everything)")
    box:SetText(search)
    box:SetFullWidth(true)
    box:SetCallback("OnEnterPressed", function(_, _, text)
        search = strtrim(text or ""):lower()
        Later(self)
    end)
    body:AddChild(box)
end

local function Matches(name)
    return search == "" or name:lower():find(search, 1, true) ~= nil
end

-- Fills the window. Called when it opens and whenever what it shows has changed.
function RPSheet:PopulateItemBrowser()
    local window, body = self.itemWindow, self.itemBody
    if not window or not source or not window.frame:IsShown() then return end
    if source.gone and source.gone() then
        window:Hide()
        return
    end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(source.title(self))

    body:PauseLayout()
    body:ReleaseChildren()
    UI.AddLabel(body, 1, source.standing(self) .. "\n ")
    AddTabs(self, body)
    AddSearch(self, body)

    local first, shown = open == source.first, 0
    local entries = first and source.own(self) or {}
    if not first then
        for _, name in ipairs(source.names and source.names(open.kind) or R.ITEM_NAMES[open.kind] or {}) do
            entries[#entries + 1] = { name = name, item = source.find(self, name) }
        end
    end
    for _, entry in ipairs(entries) do
        if Matches(entry.name) then
            AddCard(self, body, entry, first)
            shown = shown + 1
        end
    end
    if shown == 0 then
        UI.AddLabel(body, 1, UI.GREY .. (search ~= "" and "Nothing here matches your search." or source.empty) .. "|r")
    end
    body:ResumeLayout()
    body:DoLayout()
end
