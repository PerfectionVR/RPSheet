-- Fills the item browser: the tabs, the search box and the open page of blocks
-- (see UI/ItemBrowser.lua for the window and what a source is).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local Pages = UI.ItemPages
local AddCard = UI.ItemBrowserParts.AddCard
local Later = UI.ItemBrowserParts.Later
local AddTabs = UI.ItemBrowserParts.AddTabs
local AddSearch = UI.ItemBrowserParts.AddSearch
local B = UI.ItemBrowserState

-- The kinds of part the dialog skin (UI/DialogSkin.lua) styles in this window. The
-- texts and tabs are themed where they are made.
local THEMED = { ScrollFrame = true, InlineGroup = true, Button = true, EditBox = true }

local function Matches(name)
    return B.search == "" or name:lower():find(B.search, 1, true) ~= nil
end

-- Fills the window. Called when it opens and whenever what it shows has changed.
function RPSheet:PopulateItemBrowser()
    local window, body = self.itemWindow, self.itemBody
    if not window or not B.source or not window.frame:IsShown() then return end
    B.fills = B.fills + 1
    if B.source.gone and B.source.gone() then
        window:Hide()
        return
    end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(B.source.title(self))

    body:PauseLayout()
    body:ReleaseChildren()
    UI.AddLabel(body, 1, B.source.standing(self) .. "\n ")
    if B.source.top then B.source.top(self, body) end
    AddTabs(self, body)
    AddSearch(self, body)

    local first = B.open == B.source.first
    local entries = first and B.source.own(self) or {}
    if not first and B.source.list then
        entries = B.source.list(self, B.open)
    elseif not first then
        for _, name in ipairs(B.source.names and B.source.names(B.open.kind) or R.ITEM_NAMES[B.open.kind] or {}) do
            entries[#entries + 1] = { name = name, item = B.source.find(self, name) }
        end
    end
    -- The search goes over the whole tab; only the page that is open is built.
    local matching = {}
    for _, entry in ipairs(entries) do
        if Matches(entry.name) then matching[#matching + 1] = entry end
    end
    local from, to = Pages.Range(#matching, B.source, B.open, B.search)
    local function Turn(step)
        Pages.Turn(step)
        B.toTop = true
        Later(self)
    end
    Pages.AddControls(body, from, to, #matching, Turn)
    for index = from, to do
        AddCard(self, body, matching[index], first)
    end
    if #matching == 0 then
        -- `source.empty` is what the first tab says; another tab that is empty says so itself.
        local nothing = (B.search ~= "" and "Nothing here matches your search.") or (first and B.source.empty) or "Nothing is listed in this tab."
        UI.AddLabel(body, 1, UI.GREY .. nothing .. "|r")
    end
    Pages.AddControls(body, from, to, #matching, Turn)
    body:ResumeLayout()
    -- The blocks, buttons and search box in the theme's look, like the dialogs.
    ns.DialogSkin.ApplyTo(body, self.db.profile.theme, THEMED)
    if B.toTop then
        B.toTop = false
        body:SetScroll(0)
    end
    body:DoLayout()
end
