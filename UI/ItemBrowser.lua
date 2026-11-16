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
--   words(self, entry)     optional: what the search looks at besides the name and the
--                          marks, when building the block's lines for it costs too much
--   ownListed              true when the first tab only repeats entries of the other
--                          tabs, so a search of every tab leaves it out
--
-- Only one page of blocks is built at a time (UI/ItemPages.lua); the search goes over
-- the whole tab, or over every tab at once (UI/ItemBrowserSearch.lua).
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

-- What the window is showing, shared with UI/ItemBrowserParts.lua and ItemBrowserFill.lua:
--   source   the source it shows
--   open     the open tab: source.first or one of source.kinds
--   search   the text searched for, in small letters
--   everywhere   the search goes over every tab, not only the open one
--   toTop    a page was turned: start reading it at its top
--   fills    how often the window was filled, to tell whether showing it did
local B = { search = "", everywhere = false, toTop = false, fills = 0 }
UI.ItemBrowserState = B

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
    window:SetCallback("OnEditClick", function() (B.source and B.source.options or ns.OpenInventoryOptions)() end)
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
    local same = B.source == wanted
    if not same then
        B.source, B.open, B.search, B.everywhere = wanted, tab or wanted.first, "", false
    end
    local before = B.fills
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
    if B.fills == before then self:PopulateItemBrowser() end
end

-- Shows the browser on a source at one of its tabs. Unlike ShowItemBrowser it never
-- closes the window.
function RPSheet:OpenItemBrowser(wanted, tab)
    local shown = self.itemWindow and self.itemWindow.frame:IsShown()
    if B.source ~= wanted or not shown then
        if B.source == wanted then B.source = nil end -- or showing it again would be taken as closing it
        self:ShowItemBrowser(wanted, tab)
    else
        B.open = tab or B.open
        self:PopulateItemBrowser()
    end
end

-- Closes the browser if it is showing that source.
function RPSheet:HideItemBrowser(shown)
    if self.itemWindow and B.source == shown then self.itemWindow:Hide() end
end
