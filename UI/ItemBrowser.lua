-- The item browser: a window of its own that shows items as blocks, each saying what
-- it is and does, with buttons under it. What is listed and what the buttons do comes
-- from a source: the character's inventory (UI/ItemBrowserSheet.lua) or the starting
-- closet of the creation wizard (Wizard/ClosetBrowser.lua), or what the character's
-- professions can make (UI/CraftBrowser.lua).
--
-- A source is a table of:
--   title(self)            the window's title
--   first                  { name, tip }: the tab for what was taken or is carried
--   kinds                  the other tabs, a list of { name, kind } (Rules.ITEM_NAMES),
--                          or a function(self) returning the list as it is now
--   list(self, tab)        optional: the entries of such a tab, when they are not
--                          simply every item of its kind
--   notes(self, entry)     optional: lines added under what the block says
--   standing(self)         the line above the tabs
--   top(self, body)        optional: adds more above the tabs (whose merchant is selling)
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
--
-- Only one page of blocks is built at a time (UI/ItemPages.lua); the search goes over
-- the whole tab.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local Pages = UI.ItemPages

local source     -- what the window is showing
local open       -- the open tab: source.first or one of source.kinds
local search = ""
local toTop = false -- a page was turned: start reading it at its top
local fills = 0     -- how often the window was filled, to tell whether showing it did

-- The kinds of part the dialog skin (UI/DialogSkin.lua) styles in this window. The
-- texts and tabs are themed where they are made.
local THEMED = { ScrollFrame = true, InlineGroup = true, Button = true, EditBox = true }

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

-- Shows the browser on a source, at its first tab or the one given; on the source it
-- already shows, this closes it.
function RPSheet:ShowItemBrowser(wanted, tab)
    local same = source == wanted
    if not same then
        source, open, search = wanted, tab or wanted.first, ""
    end
    local before = fills
    if not self.itemWindow then
        Build(self) -- a new window is already shown
    elseif same and self.itemWindow.frame:IsShown() then
        self.itemWindow:Hide()
        return
    else
        self.itemWindow:Show()
    end
    self.itemWindow.frame:Raise()
    -- Showing a hidden window has filled it already (OnShow); building blocks twice is slow.
    if fills == before then self:PopulateItemBrowser() end
end

-- Shows the browser on a source at one of its tabs. Unlike ShowItemBrowser it never
-- closes the window.
function RPSheet:OpenItemBrowser(wanted, tab)
    local shown = self.itemWindow and self.itemWindow.frame:IsShown()
    if source ~= wanted or not shown then
        if source == wanted then source = nil end -- or showing it again would be taken as closing it
        self:ShowItemBrowser(wanted, tab)
    else
        open = tab or open
        self:PopulateItemBrowser()
    end
end

-- Closes the browser if it is showing that source.
function RPSheet:HideItemBrowser(shown)
    if self.itemWindow and source == shown then self.itemWindow:Hide() end
end

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
    local marks = source.marks(self, entry)
    local plain = ns.Util.HexCode(self.db.profile.theme.text) -- the title itself is in the accent colour
    card:SetTitle(#marks > 0 and ("%s  %s(%s)|r"):format(entry.name, plain, table.concat(marks, ", ")) or entry.name)
    local lines = source.lines and source.lines(self, entry) or UI.ItemLines(self, entry.name, entry.item, source.class(self))
    for _, line in ipairs(source.notes and source.notes(self, entry) or {}) do lines[#lines + 1] = line end
    UI.AddLabel(card, 1, table.concat(lines, "\n"))
    source.buttons(self, card, entry, first)
    body:AddChild(card)
end

local function Later(self)
    C_Timer.After(0, function() self:PopulateItemBrowser() end)
end

local function AddTabs(self, body)
    local theme = self.db.profile.theme
    local tabs, found = { source.first }, open == source.first
    local kinds = type(source.kinds) == "function" and source.kinds(self) or source.kinds
    for _, tab in ipairs(kinds) do
        tabs[#tabs + 1] = tab
        found = found or tab == open
    end
    if not found then open = source.first end -- its tab is gone
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab == open)
        button:SetText(tab.name)
        button:SetRelativeWidth(0.999 / #tabs) -- a hair under an even share: see UI/SheetTabs.lua
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
    fills = fills + 1
    if source.gone and source.gone() then
        window:Hide()
        return
    end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(source.title(self))

    body:PauseLayout()
    body:ReleaseChildren()
    UI.AddLabel(body, 1, source.standing(self) .. "\n ")
    if source.top then source.top(self, body) end
    AddTabs(self, body)
    AddSearch(self, body)

    local first = open == source.first
    local entries = first and source.own(self) or {}
    if not first and source.list then
        entries = source.list(self, open)
    elseif not first then
        for _, name in ipairs(source.names and source.names(open.kind) or R.ITEM_NAMES[open.kind] or {}) do
            entries[#entries + 1] = { name = name, item = source.find(self, name) }
        end
    end
    -- The search goes over the whole tab; only the page that is open is built.
    local matching = {}
    for _, entry in ipairs(entries) do
        if Matches(entry.name) then matching[#matching + 1] = entry end
    end
    local from, to = Pages.Range(#matching, source, open, search)
    local function Turn(step)
        Pages.Turn(step)
        toTop = true
        Later(self)
    end
    Pages.AddControls(body, from, to, #matching, Turn)
    for index = from, to do
        AddCard(self, body, matching[index], first)
    end
    if #matching == 0 then
        -- `source.empty` is what the first tab says; another tab that is empty says so itself.
        local nothing = (search ~= "" and "Nothing here matches your search.") or (first and source.empty) or "Nothing is listed in this tab."
        UI.AddLabel(body, 1, UI.GREY .. nothing .. "|r")
    end
    Pages.AddControls(body, from, to, #matching, Turn)
    body:ResumeLayout()
    -- The blocks, buttons and search box in the theme's look, like the dialogs.
    ns.DialogSkin.ApplyTo(body, self.db.profile.theme, THEMED)
    if toTop then
        toTop = false
        body:SetScroll(0)
    end
    body:DoLayout()
end
