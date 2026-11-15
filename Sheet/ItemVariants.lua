-- Magic makes of plain armor, shields and weapons (Data/ItemVariants.lua) as carried
-- items: making one, and what the sheet counts for the one that is worn. The item
-- remembers its make in item.variant, so a renamed one still counts.
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
    return bases
end

-- A sheet entry for the variant of a plain item, or nil when the two don't go
-- together. It counts as the plain item, weighs the same, and is worth what its
-- rarity says on top of the plain item's price.
function ns.NewVariantItem(key, base)
    local variant = R.ITEM_VARIANT[key]
    if not variant or not R.VariantFits(variant, base) then return nil end
    local plain = R.ITEMS[base]
    local item = CopyTable(R.TEMPLATES.item)
    item.name, item.base, item.variant = R.VariantName(variant, base), base, key
    item.bonus, item.desc = variant.bonus or 0, variant.desc
    item.magic, item.rarity, item.attune = true, variant.rarity, variant.attune == true
    item.weight = plain and plain.weight or 0
    item.cost = R.MagicItemValue(variant.rarity, false, base)
    return item
end

-- Adds the variant of a plain item to the inventory; each is an entry of its own.
function RPSheet:AddVariantItem(key, base)
    local item = ns.NewVariantItem(key, base)
    if not item then return nil end
    local items = self:Sheet().items
    items[#items + 1] = item
    return item
end

-- The variant an item is, or nil.
function ns.ItemVariant(item)
    return R.ITEM_VARIANT[item.variant or ""]
end

-- The resistances an item's make gives, in the form Sheet/Defenses.lua reads, or nil.
-- They count while the item is active (equipped, and attuned when it asks for that).
function ns.ItemDefenses(item)
    local variant = ns.ItemVariant(item)
    return variant and variant.resist and variant or nil
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
