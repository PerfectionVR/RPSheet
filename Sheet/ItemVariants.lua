-- Magic makes of plain armor, shields, weapons and ammunition (Data/ItemVariants.lua)
-- as carried items: making one, and what the sheet counts for the one that is worn.
-- The item remembers its make in item.variant, so a renamed one still counts.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The plain items a variant can be made of, in the order of the item lists.
function ns.VariantBases(variant)
    local bases = {}
    for _, name in ipairs(R.ITEM_NAMES["Armor and shields"]) do
        if R.VariantFits(variant, name) then bases[#bases + 1] = name end
    end
    for _, name in ipairs(R.WEAPON_ORDER) do
        if R.VariantFits(variant, name) then bases[#bases + 1] = name end
    end
    for _, name in ipairs(R.AMMO_PIECES) do
        if R.VariantFits(variant, name) then bases[#bases + 1] = name end
    end
    return bases
end

-- Writes what a make of a plain item is onto an entry: everything but its name,
-- how many there are and whether it is worn and attuned. It counts as the plain
-- item, weighs the same, and is worth what its rarity says (half for one that is
-- used up) on top of the plain item's price.
local function Fill(item, variant, base)
    local cost, weight = R.VariantPlain(base)
    item.base, item.variant = base, variant.key
    item.bonus, item.desc = variant.bonus or 0, variant.desc
    item.magic, item.rarity, item.attune = true, variant.rarity, variant.attune == true
    item.weight = weight
    item.cost = R.MagicItemValue(variant.rarity, variant.stacks) + cost
    item.effects = {}
    for _, effect in ipairs(variant.effects or {}) do item.effects[#item.effects + 1] = CopyTable(effect) end
end

-- A sheet entry for the variant of a plain item, or nil when the two don't go together.
function ns.NewVariantItem(key, base)
    local variant = R.ITEM_VARIANT[key]
    if not variant or not R.VariantFits(variant, base) then return nil end
    local item = CopyTable(R.TEMPLATES.item)
    item.name, item.tracked = R.VariantName(variant, base), true
    Fill(item, variant, base)
    return item
end

-- Brings an unedited make up to date with the data; part of the items' upkeep
-- (Sheet/ItemUpkeep.lua). One whose plain item no longer fits is left alone.
function ns.RefreshVariantItem(item)
    local variant = R.ITEM_VARIANT[item.variant or ""]
    if variant and R.VariantFits(variant, item.base) then
        Fill(item, variant, item.base)
        if not item.attune then item.attuned = false end
    end
end

-- Adds the variant of a plain item to the inventory. Each is an entry of its own,
-- except magic ammunition, where identical pieces share one (Sheet/ItemStacks.lua).
function RPSheet:AddVariantItem(key, base)
    local item = ns.NewVariantItem(key, base)
    if not item then return nil end
    local items = self:Sheet().items
    local stack = ns.StackFor(items, item.name, R.ITEM_VARIANT[key])
    if stack then
        stack.qty = stack.qty + 1
        return stack
    end
    items[#items + 1] = item
    return item
end

-- Pays for the variant of a plain item and adds it; the price is the one for whoever
-- the character is buying from (Sheet/Shop.lua). False when it can't be paid.
function RPSheet:BuyVariantItem(key, base)
    local price, percent, faction = self:VariantBuyPrice(key, base)
    if price <= 0 then return false end
    local name = R.VariantName(R.ITEM_VARIANT[key], base)
    if not self:SpendCoins(price, percent and ("%s, %d%% off with %s"):format(name, percent, faction) or name) then return false end
    self:AddVariantItem(key, base)
    return true
end

-- The variant an item is, or nil.
function ns.ItemVariant(item)
    return R.ITEM_VARIANT[item.variant or ""]
end

-- The resistances, immunities and vulnerabilities an item's make gives, in the form
-- Sheet/Defenses.lua reads, or nil. They count while the item is active (equipped,
-- and attuned when it asks for that).
function ns.ItemDefenses(item)
    local variant = ns.ItemVariant(item)
    return variant and (variant.resist or variant.immune or variant.vulnerable) and variant or nil
end

-- True if the suit of armor that is on is of a make that lifts `flag`: "noStealth"
-- for the armor's disadvantage on Stealth, "noStrength" for the Strength it asks.
function ns.ArmorWaives(sheet, flag)
    for _, item in ipairs(sheet.items or {}) do
        if item.equipped and item.name ~= "" and ns.ItemSlot(item) == "armor" then
            local variant = ns.ItemVariant(item)
            if variant and variant[flag] then return true end
        end
    end
    return false
end
