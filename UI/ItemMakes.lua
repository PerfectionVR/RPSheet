-- The Makes tab of the item browser on the inventory (UI/ItemBrowserSheet.lua): every
-- magic make of every plain suit of armor, shield, weapon and piece of ammunition it
-- exists of (Data/ItemVariants.lua), each as a block with Add, Buy and Remove. There
-- are well over a thousand, so the tab is one to search: "flame tongue", "longsword",
-- "mithral", "resistance".
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local Makes = { tab = { name = "Makes", makes = true } }
UI.ItemMakes = Makes

-- Every make with every plain item it fits, worked out once: the data doesn't change.
local all
local function All()
    if all then return all end
    all = {}
    for _, key in ipairs(R.ITEM_VARIANTS) do
        local variant = R.ITEM_VARIANT[key]
        for _, base in ipairs(ns.VariantBases(variant)) do
            all[#all + 1] = { name = R.VariantName(variant, base), variant = variant, base = base }
        end
    end
    return all
end

-- The tab's entries; `item` is the carried one of that make and name, if any.
function Makes.entries(self)
    local carried, entries = {}, {}
    for _, item in ipairs(self:Sheet().items) do
        if item.variant ~= "" and item.name ~= "" and not carried[item.name] then carried[item.name] = item end
    end
    for _, make in ipairs(All()) do
        local item = carried[make.name]
        entries[#entries + 1] = { name = make.name, variant = make.variant, base = make.base,
            item = item and item.variant == make.variant.key and item or nil }
    end
    return entries
end

-- What the search looks at, without making the item.
function Makes.words(_, entry)
    local variant, weapon = entry.variant, R.WEAPONS[entry.base]
    return table.concat({ variant.title, entry.base, "magic item", variant.rarity, variant.attune and "requires attunement" or "",
        weapon and R.WeaponSummary(entry.base) or "", variant.desc }, "\n")
end

-- A block says what the carried one is, or what a new one would be.
function Makes.lines(self, entry)
    return UI.ItemLines(self, entry.name, entry.item or ns.NewVariantItem(entry.variant.key, entry.base))
end

function Makes.buttons(self, card, entry, changed)
    local key, base, item = entry.variant.key, entry.base, entry.item
    -- What it costs from whoever is selling (Sheet/Shop.lua).
    local price, percent = self:VariantBuyPrice(key, base)
    UI.AddItemButton(card, 0.3, "Add", true, function()
        self:AddVariantItem(key, base)
        changed(self)
    end)
    UI.AddItemButton(card, 0.4, ns.BuyLabel(price, percent), price > 0 and self:CanAfford(price), function()
        if self:BuyVariantItem(key, base) then changed(self) end
    end)
    UI.AddItemButton(card, 0.3, "Remove", item ~= nil, function()
        self:DropItem(item)
        changed(self)
    end)
end
