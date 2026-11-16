-- Magic makes of a plain suit of armor, shield, weapon or piece of ammunition: the
-- same item in a rare metal, with a magic bonus, with a ward against one kind of
-- damage, or as one of the named makes (Data/ItemVariantsNamed.lua). The item
-- browser's Makes tab lists every make of every plain item it exists of
-- (UI/ItemMakes.lua, Sheet/ItemVariants.lua).
--
-- R.ITEM_VARIANT[key] = {
--     title      what the make is called
--     fits       what it is made of: "armor" any suit, "metal" medium and heavy armor
--                except hide, "shield", "weapon" any weapon, "melee" a melee weapon,
--                "sword", "ammo" a piece of ammunition, "arms" a melee weapon or a
--                piece of ammunition, or the plain items' names with commas between
--     format     the item's name, with %s for the plain item ("Mithral %s")
--     short      true when the name uses the suit's short name ("Plate", not "Plate Armor")
--     rarity, attune, bonus (to Armor Class or the weapon's rolls)
--     desc       what it does, in our own words
--     resist, immune, vulnerable   damage types, while it is worn and attuned (Sheet/Defenses.lua)
--     effects    what else the sheet counts while it is equipped, like an item's
--     noStealth, noStrength   the armor's Stealth disadvantage and Strength
--                requirement don't apply (Sheet/RollModes.lua)
--     stacks     used up by one use, like magic ammunition: worth half, and
--                identical ones share an entry
-- }
-- R.ITEM_VARIANTS lists the keys in the order they are shown.
local _, ns = ...
local R = ns.Rules

R.ITEM_VARIANT, R.ITEM_VARIANTS = {}, {}

function R.AddVariant(key, entry)
    entry.key = key
    -- A list of names is looked up as a set.
    if entry.fits:find(",") or R.ITEMS[entry.fits] then
        entry.bases = {}
        for name in entry.fits:gmatch("[^,]+") do entry.bases[name] = true end
    end
    R.ITEM_VARIANT[key] = entry
    R.ITEM_VARIANTS[#R.ITEM_VARIANTS + 1] = key
end
local Variant = R.AddVariant

-- Ammunition is sold by the bundle and enchanted by the piece: the pieces, with the
-- bundle each comes from. A piece costs and weighs its share of the bundle.
R.AMMO_PIECES = { "Arrow", "Bolt", "Firearm Bullet", "Needle", "Sling Bullet" }
R.AMMO_PIECE = { Arrow = "Arrows (20)", Bolt = "Bolts (20)", ["Firearm Bullet"] = "Firearm Bullets (10)", Needle = "Needles (50)",
    ["Sling Bullet"] = "Sling Bullets (20)" }
local SWORDS = { Greatsword = true, Longsword = true, Rapier = true, Scimitar = true, Shortsword = true }

-- Price in copper and weight in pounds of the plain item a make is made of.
function R.VariantPlain(base)
    local plain, bundle = R.ITEMS[base], R.ITEMS[R.AMMO_PIECE[base] or ""]
    if plain then return plain.cost, plain.weight end
    if not bundle then return 0, 0 end
    local pieces = tonumber(R.AMMO_PIECE[base]:match("%((%d+)%)$")) or 1
    return math.floor(bundle.cost / pieces), bundle.weight / pieces
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
for bonus = 1, 3 do
    Variant("ammo" .. bonus, { title = ("+%d Ammunition"):format(bonus), fits = "ammo", format = "%s +" .. bonus,
        rarity = OTHER_RARITY[bonus], stacks = true,
        desc = ("One piece. Adds %d to the attack and damage roll made with it, and is plain again once it hits. The sheet doesn't add that by itself: it is for the one shot."):format(bonus) })
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
Variant("adamantineWeapon", { title = "Adamantine Weapon", fits = "arms", format = "Adamantine %s", rarity = "Uncommon",
    desc = "A weapon or a piece of ammunition of adamantine: every hit with it on an object is a critical hit." })
Variant("silvered", { title = "Silvered Weapon", fits = "weapon", format = "Silvered %s", rarity = "Common",
    desc = "A weapon with silver bonded to it: a critical hit with it on a shape-shifted creature rolls one more damage die." })

-- True when the plain item `base` can be made as this variant.
function R.VariantFits(variant, base)
    local armor = R.ARMOR[R.ARMOR_ITEMS[base] or ""]
    local weapon, fits = R.WEAPONS[base], variant.fits
    if variant.bases then return variant.bases[base] == true and (armor ~= nil or weapon ~= nil) end
    if fits == "shield" then return base == R.SHIELD_ITEM end
    if fits == "armor" then return armor ~= nil end
    if fits == "metal" then
        -- Light armor has no cap on Dexterity; medium and heavy armor do.
        return armor ~= nil and armor.dexCap ~= nil and R.ARMOR_ITEMS[base] ~= "HIDE"
    end
    if fits == "weapon" then return weapon ~= nil end
    if fits == "sword" then return weapon ~= nil and SWORDS[base] == true end
    if fits == "ammo" then return R.AMMO_PIECE[base] ~= nil end
    local melee = weapon ~= nil and not weapon.ranged
    if fits == "arms" then return melee or R.AMMO_PIECE[base] ~= nil end
    return melee
end

-- "Mithral Chain Shirt", "Longsword +1", "Armor of Fire Resistance (Plate)".
function R.VariantName(variant, base)
    return variant.format:format(variant.short and (base:gsub(" Armor$", "")) or base)
end
