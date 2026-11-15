-- The item browser: a window of its own that shows what you carry and every listed
-- item as a block, with what it is and does and buttons to add, buy and remove it.
-- Opened from the sheet's Items tab and from Customize > Inventory.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local CARRIED = "Carried"
-- The tabs: what you carry, then each kind of listed item under a short name.
local TABS = {
    { name = CARRIED, tip = "Everything you carry." },
    { name = "Weapons", kind = "Weapons and ammunition" },
    { name = "Armor", kind = "Armor and shields" },
    { name = "Gear", kind = "Adventuring gear" },
    { name = "Packs", kind = "Packs" },
    { name = "Focuses", kind = "Spellcasting focuses" },
    { name = "Tools", kind = "Tools and instruments" },
    { name = "Magic", kind = "Magic items" },
}
local open, search = TABS[1], ""

local function Build(self)
    local profile = self.db.profile
    profile.itemWindow = profile.itemWindow or { width = 560, height = 520 }

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(profile.itemWindow)
    window:SetLayout("Fill")
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnMinimizeClick", function() window:SetMinimized(not window.minimized) end)
    window:SetCallback("OnEditClick", function()
        AceConfigDialog:Open(ADDON)
        AceConfigDialog:SelectGroup(ADDON, "customize", "items")
    end)
    window:SetCallback("OnShow", function() self:PopulateItemBrowser() end)
    self.itemWindow = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.itemBody = body
end

function RPSheet:ToggleItemBrowser()
    if not self.itemWindow then
        Build(self) -- a new window is already shown
        self:PopulateItemBrowser()
        return
    end
    if self.itemWindow.frame:IsShown() then self.itemWindow:Hide() else self.itemWindow:Show() end
end

-- After a button changed the inventory: on the next frame, because the button is part
-- of what gets rebuilt. Rebuilding the sheet rebuilds this window too.
local function Changed(self)
    C_Timer.After(0, function()
        ns.RebuildOptions() -- an item's page under Customize may have come or gone
        self:SheetChanged()
    end)
end

local function AddButton(card, width, text, enabled, onClick)
    local button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetRelativeWidth(width)
    button:SetDisabled(not enabled)
    button:SetCallback("OnClick", onClick)
    card:AddChild(button)
end

-- One block. `item` is the carried entry, when you have the thing.
local function AddCard(self, body, name, item, carriedTab)
    local known = R.ITEMS[name]
    local card = AceGUI:Create("InlineGroup")
    card:SetLayout("Flow")
    card:SetRelativeWidth(0.5)
    local marks = {}
    if item then
        marks[#marks + 1] = "you have " .. item.qty
        if item.equipped then marks[#marks + 1] = "equipped" end
        if item.attune then marks[#marks + 1] = item.attuned and "attuned" or "not attuned" end
    end
    card:SetTitle(#marks > 0 and ("%s  |cffffffff(%s)|r"):format(name, table.concat(marks, ", ")) or name)
    UI.AddLabel(card, 1, table.concat(UI.ItemLines(self, name, item), "\n"))

    if carriedTab then
        AddButton(card, 0.34, item.equipped and "Put away" or "Equip", true, function()
            self:SetEquipped(item, not item.equipped)
            Changed(self)
        end)
        if item.attune then
            AddButton(card, 0.33, item.attuned and "End attunement" or "Attune", true, function()
                self:ToggleAttuned(item)
                Changed(self)
            end)
        else
            AddButton(card, 0.33, "Add one", true, function()
                item.qty = item.qty + 1
                Changed(self)
            end)
        end
    else
        local price = known.cost or 0
        AddButton(card, 0.3, "Add", true, function()
            self:AddItem(name, 1)
            Changed(self)
        end)
        AddButton(card, 0.4, price > 0 and ("Buy  " .. ns.CoinText(price)) or "No price", price > 0 and self:CanAfford(price), function()
            if self:BuyItem(name, 1) then Changed(self) end
        end)
    end
    AddButton(card, carriedTab and 0.33 or 0.3, "Remove", item ~= nil, function()
        self:DropItem(item)
        Changed(self)
    end)
    body:AddChild(card)
end

local function AddTabs(self, body)
    local theme = self.db.profile.theme
    for _, tab in ipairs(TABS) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab == open)
        button:SetText(tab.name)
        button:SetRelativeWidth(1 / #TABS)
        button:SetCallback("OnClick", function()
            open = tab
            C_Timer.After(0, function() self:PopulateItemBrowser() end)
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
        C_Timer.After(0, function() self:PopulateItemBrowser() end)
    end)
    body:AddChild(box)
end

local function Matches(name)
    return search == "" or name:lower():find(search, 1, true) ~= nil
end

-- Fills the window. Called when it opens and whenever the sheet is rebuilt.
function RPSheet:PopulateItemBrowser()
    local window, body = self.itemWindow, self.itemBody
    if not window or not window.frame:IsShown() then return end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(("%s - Items"):format(self:GetCharacterName()))

    body:PauseLayout()
    body:ReleaseChildren()
    local weight, capacity = self:CarriedWeight(), self:CarryCapacity()
    UI.AddLabel(body, 1, ("Money %s%s|r     Carried %s%.1f of %d lb.|r     Attuned %s%d of %d|r\n "):format(
        UI.ACCENT, ns.CoinText(self:Coins()), weight > capacity and "|cffff5555" or UI.ACCENT, weight, capacity,
        UI.ACCENT, #self:AttunedItems(), R.ATTUNE_LIMIT))
    AddTabs(self, body)
    AddSearch(self, body)

    local shown = 0
    if open.name == CARRIED then
        for _, item in ipairs(self:Sheet().items) do
            if item.name ~= "" and Matches(item.name) then
                AddCard(self, body, item.name, item, true)
                shown = shown + 1
            end
        end
    else
        for _, name in ipairs(R.ITEM_NAMES[open.kind] or {}) do
            if Matches(name) then
                AddCard(self, body, name, self:CarriedItem(name))
                shown = shown + 1
            end
        end
    end
    if shown == 0 then
        UI.AddLabel(body, 1, UI.GREY .. (search ~= "" and "Nothing here matches your search."
            or "You carry nothing yet. Open another tab to add or buy things.") .. "|r")
    end
    body:ResumeLayout()
    body:DoLayout()
end
