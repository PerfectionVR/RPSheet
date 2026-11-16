-- The item browser on the character's own inventory (UI/ItemBrowser.lua): what is
-- carried, every listed item, the magic makes of plain items (UI/ItemMakes.lua), and
-- adding, buying, selling, equipping, attuning and removing.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local Makes = UI.ItemMakes
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- The Customize > Inventory page, behind the cog of the browser.
function ns.OpenInventoryOptions()
    AceConfigDialog:Open(ADDON)
    AceConfigDialog:SelectGroup(ADDON, "customize", "items")
end

-- After a button changed the inventory. The sheet is rebuilt on the next frame,
-- because the button is part of what gets rebuilt, and the browser with it; what the
-- button did may have asked for that already (paying, attuning), and it happens once.
local function Changed(self)
    ns.RebuildOptions() -- an item's page under Customize may have come or gone
    self:ClampState()
    self:PopulateSoon()
end

local SHEET = {
    first = { name = "Carried", tip = "Everything you carry." },
    kinds = {
        { name = "Weapons", kind = "Weapons and ammunition" }, { name = "Armor", kind = "Armor and shields" },
        { name = "Gear", kind = "Adventuring gear" }, { name = "Packs", kind = "Packs" },
        { name = "Focuses", kind = "Spellcasting focuses" }, { name = "Tools", kind = "Tools and instruments" },
        { name = "Reagents", kind = "Spell components" }, { name = "Magic", kind = "Magic items" },
        Makes.tab,
    },
    empty = "You carry nothing yet. Open another tab to add or buy things.",
    title = function(self) return ("%s - Items"):format(self:GetCharacterName()) end,
    class = function() return nil end, -- judged by the active character
    find = function(self, name) return self:CarriedItem(name) end,
    top = function(self, body) UI.AddShopChoice(self, body) end,
}

function SHEET.standing(self)
    local weight, capacity = self:CarriedWeight(), self:CarryCapacity()
    return ("Money %s%s|r     Carried %s%.1f of %d lb.|r     Attuned %s%d of %d|r\n%sBuy pays the price from your coins; Add takes it for nothing. %s|r"):format(
        UI.ACCENT, ns.CoinText(self:Coins()), weight > capacity and "|cffff5555" or UI.ACCENT, weight, capacity,
        UI.ACCENT, #self:AttunedItems(), R.ATTUNE_LIMIT, UI.GREY, ns.SELL_HELP)
end

-- The Makes tab lists makes; every other tab the items of its kind.
function SHEET.list(self, tab)
    if tab.makes then return Makes.entries(self) end
    local entries = {}
    for _, name in ipairs(R.ITEM_NAMES[tab.kind] or {}) do
        entries[#entries + 1] = { name = name, item = self:CarriedItem(name) }
    end
    return entries
end

function SHEET.lines(self, entry)
    if entry.variant then return Makes.lines(self, entry) end
    return UI.ItemLines(self, entry.name, entry.item)
end

function SHEET.words(self, entry)
    if entry.variant then return Makes.words(self, entry) end
    return UI.ItemWords(self, entry.name, entry.item)
end

-- A magic item no profession makes says why (R.NOT_MADE, Data/RecipesFinds.lua).
function SHEET.notes(_, entry)
    local why = not entry.variant and R.NOT_MADE[entry.name]
    if not why then return {} end
    return { ("%sNo profession makes it: %s.|r"):format(UI.GREY, why) }
end

function SHEET.own(self)
    local entries = {}
    for _, item in ipairs(self:Sheet().items) do
        if item.name ~= "" then entries[#entries + 1] = { name = item.name, item = item } end
    end
    return entries
end

function SHEET.marks(_, entry)
    local item, marks = entry.item, {}
    if not item then return marks end
    marks[#marks + 1] = "you have " .. item.qty
    if item.equipped then marks[#marks + 1] = "equipped" end
    if item.attune then marks[#marks + 1] = item.attuned and "attuned" or "not attuned" end
    return marks
end

function SHEET.buttons(self, card, entry, first)
    local name, item = entry.name, entry.item
    if first then
        -- Two rows of two: wear it or attune to it, then sell it or drop it.
        UI.AddItemButton(card, 0.5, item.equipped and "Put away" or "Equip", true, function()
            self:SetEquipped(item, not item.equipped)
            Changed(self)
        end)
        if item.attune then
            UI.AddItemButton(card, 0.5, item.attuned and "End attunement" or "Attune", true, function()
                self:ToggleAttuned(item)
                Changed(self)
            end)
        else
            UI.AddItemButton(card, 0.5, "Add one", true, function()
                item.qty = item.qty + 1
                Changed(self)
            end)
        end
        UI.AddItemButton(card, 0.5, ns.SellLabel(item), ns.SellPrice(item) > 0, function()
            if self:SellItem(item) then Changed(self) end
        end)
    elseif entry.variant then
        Makes.buttons(self, card, entry, Changed)
        return
    else
        -- What it costs from whoever is selling (Sheet/Shop.lua).
        local price, percent = self:ItemBuyPrice(name, 1)
        UI.AddItemButton(card, 0.3, "Add", true, function()
            self:AddItem(name, 1)
            Changed(self)
        end)
        UI.AddItemButton(card, 0.4, ns.BuyLabel(price, percent), price > 0 and self:CanAfford(price), function()
            if self:BuyItem(name, 1) then Changed(self) end
        end)
    end
    UI.AddItemButton(card, first and 0.5 or 0.3, "Remove", item ~= nil, function()
        self:DropItem(item)
        Changed(self)
    end)
end

function RPSheet:ToggleItemBrowser()
    self:ShowItemBrowser(SHEET)
end
