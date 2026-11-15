-- Magic makes of a plain suit of armor, shield or weapon: the same item in a rare
-- metal, with a magic bonus or with a ward against one kind of damage. The Inventory
-- page under Customize makes one from a variant and a plain item
-- (Options/InventoryVariant.lua, Sheet/ItemVariants.lua).
--
-- R.ITEM_VARIANT[key] = {
--     title      what the dropdown calls it
--     fits       "armor" any suit, "metal" medium and heavy armor except hide,
--                "shield", "weapon" any weapon, "melee" a melee weapon
--     format     the item's name, with %s for the plain item ("Mithral %s")
--     short      true when the name uses the suit's short name ("Plate", not "Plate Armor")
--     rarity, attune, bonus (to Armor Class or the weapon's rolls)
--     desc       what it does, in our own words
--     resist     damage types resisted while it is worn and attuned (Sheet/Defenses.lua)
--     noStealth, noStrength   the armor's Stealth disadvantage and Strength
--                requirement don't apply (Sheet/RollModes.lua)
-- }
-- R.ITEM_VARIANTS lists the keys in the dropdown's order.
local _, ns = ...
local R = ns.Rules

R.ITEM_VARIANT, R.ITEM_VARIANTS = {}, {}

local function Variant(key, entry)
    entry.key = key
    R.ITEM_VARIANT[key] = entry
    R.ITEM_VARIANTS[#R.ITEM_VARIANTS + 1] = key
end

local ARMOR_RARITY = { "Rare", "Very rare", "Legendary" }
local OTHER_RARITY = { "Uncommon", "Rare", "Very rare" }

for bonus = 1, 3 do
    Variant("armor" .. bonus, { title = ("+%d Armor"):format(bonus), fits = "armor", format = "%s +" .. bonus,
        rarity = ARMOR_RARITY[bonus], bonus = bonus,
        desc = ("Adds %d to your Armor Class on top of what the armor gives."):format(bonus) })
end
for bonus = 1, 3 do
    Variant("shield" .. bonus, { title = ("+%d Shield"):format(bonus), fits = "shield", format = "%s +" .. bonus,
        rarity = OTHER_RARITY[bonus], bonus = bonus,
        desc = ("Adds %d to your Armor Class on top of a shield's usual bonus."):format(bonus) })
end
for bonus = 1, 3 do
    Variant("weapon" .. bonus, { title = ("+%d Weapon"):format(bonus), fits = "weapon", format = "%s +" .. bonus,
        rarity = OTHER_RARITY[bonus], bonus = bonus,
        desc = ("Adds %d to attack and damage rolls made with it."):format(bonus) })
end

Variant("adamantineArmor", { title = "Adamantine Armor", fits = "metal", format = "Adamantine %s", rarity = "Uncommon",
    desc = "Armor strengthened with adamantine: a critical hit against you counts as an ordinary hit. The sheet doesn't roll your enemies' hits, so that is yours to remember." })
Variant("mithral", { title = "Mithral Armor", fits = "metal", format = "Mithral %s", rarity = "Uncommon",
    noStealth = true, noStrength = true,
    desc = "Armor of light, supple mithral: it gives no disadvantage on Stealth checks and asks for no Strength, which the sheet counts while you wear it." })
for _, name in ipairs({ "acid", "cold", "fire", "force", "lightning", "necrotic", "poison", "psychic", "radiant", "thunder" }) do
    local word = name:sub(1, 1):upper() .. name:sub(2)
    Variant("resist:" .. name, { title = ("Armor of %s Resistance"):format(word), fits = "armor", short = true,
        format = ("Armor of %s Resistance (%%s)"):format(word), rarity = "Rare", attune = true, resist = { name },
        desc = ("While you wear it and are attuned to it, you resist %s damage. The sheet counts that."):format(name) })
end
Variant("adamantineWeapon", { title = "Adamantine Weapon", fits = "melee", format = "Adamantine %s", rarity = "Uncommon",
    desc = "A weapon of adamantine: every hit with it on an object is a critical hit." })
Variant("silvered", { title = "Silvered Weapon", fits = "weapon", format = "Silvered %s", rarity = "Common",
    desc = "A weapon with silver bonded to it: a critical hit with it on a shape-shifted creature rolls one more damage die." })

-- True when the plain item `base` can be made as this variant.
function R.VariantFits(variant, base)
    local armor = R.ARMOR[R.ARMOR_ITEMS[base] or ""]
    local weapon = R.WEAPONS[base]
    if variant.fits == "shield" then return base == R.SHIELD_ITEM end
    if variant.fits == "armor" then return armor ~= nil end
    if variant.fits == "metal" then
        -- Light armor has no cap on Dexterity; medium and heavy armor do.
        return armor ~= nil and armor.dexCap ~= nil and R.ARMOR_ITEMS[base] ~= "HIDE"
    end
    if variant.fits == "weapon" then return weapon ~= nil end
    return weapon ~= nil and not weapon.ranged
end

-- "Mithral Chain Shirt", "Longsword +1", "Armor of Fire Resistance (Plate)".
function R.VariantName(variant, base)
    return variant.format:format(variant.short and (base:gsub(" Armor$", "")) or base)
end
