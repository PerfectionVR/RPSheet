-- What a carried item is made of, the limits that go with carrying and attuning, and
-- the catalogue the item lists fill (Data/Gear.lua, Data/GearArms.lua, Data/MagicItems.lua).
local _, ns = ...
local R = ns.Rules

-- An entry of sheet.items. Its effects are the same as a passive's (Rules.EFFECT_TARGETS)
-- and count while it is equipped, and attuned if it asks for that.
R.TEMPLATES.item = {
    name = "", desc = "",
    qty = 1,
    weight = 0,        -- pounds, each
    cost = 0,          -- copper pieces, each; 0 = no listed price
    equipped = false,  -- worn or held
    base = "",         -- the plain armor, shield or weapon it counts as (Sheet/Equipment.lua)
    bonus = 0,         -- magic bonus of such an item: to Armor Class, or to the weapon's rolls
    magic = false, rarity = "",
    attune = false,    -- needs attunement before its magic works
    attuned = false,
    limit = "",        -- "UNARMORED": its effects stop in armor or with a shield (Sheet/Limits.lua)
    variant = "",      -- the magic make of a plain armor or weapon it is (Data/ItemVariants.lua)
    scribed = false,   -- a spell scroll this character wrote itself (Actions/Scrolls.lua)
    edited = false,    -- the player changed it under Customize: the catalogue leaves it alone from then on
    tracked = false,   -- made since edits are recorded; an older item is refreshed with care (Sheet/ItemUpkeep.lua)
    effects = {},
}

R.ATTUNE_LIMIT = 3 -- magic items one character can be attuned to at a time

-- Pounds carried per point of Strength, by size.
R.CARRY_PER_STRENGTH = { S = 15, M = 15, L = 30 }
R.OVERLOADED_SPEED = 5 -- feet, at most, while carrying more than that

R.RARITY_ORDER = { "", "Common", "Uncommon", "Rare", "Very rare", "Legendary", "Artifact" }
R.RARITIES = { [""] = "Not set" }
R.RARITY_COLORS = {
    Common = "|cffffffff", Uncommon = "|cff1eff00", Rare = "|cff0070dd",
    ["Very rare"] = "|cffa335ee", Legendary = "|cffff8000", Artifact = "|cffe6cc80",
}
for _, rarity in ipairs(R.RARITY_ORDER) do
    if rarity ~= "" then R.RARITIES[rarity] = rarity end
end

-- What a magic item is worth by how rare it is, in copper; an artifact has no price.
-- One that is used up is worth half, and one made from a priced thing (a suit of
-- armor, a weapon) is worth that thing's price on top.
R.MAGIC_VALUES = {
    Common = 10000, Uncommon = 40000, Rare = 400000, ["Very rare"] = 4000000, Legendary = 20000000,
}
function R.MagicItemValue(rarity, consumable, base)
    local value = R.MAGIC_VALUES[rarity] or 0
    if value == 0 then return 0 end
    if consumable then value = value / 2 end
    return math.floor(value + (base and R.ITEMS[base] and R.ITEMS[base].cost or 0))
end

R.ITEM_LIMITS = { [""] = "Always", UNARMORED = "Only without armor and shield", NOHEAVY = "Not in heavy armor" }
R.ITEM_LIMIT_ORDER = { "", "UNARMORED", "NOHEAVY" }

---------------------------------------------------------------------------
-- The catalogue
---------------------------------------------------------------------------
-- R.ITEMS[name] = { kind, cost, weight } and, for a magic item, rarity, attune, desc,
-- effects and limit. R.ITEM_NAMES[kind] lists a kind's names in alphabetical order.
R.ITEMS, R.ITEM_NAMES, R.ITEM_KINDS = {}, {}, {}

local function Register(kind, name, entry)
    if not R.ITEM_NAMES[kind] then
        R.ITEM_NAMES[kind] = {}
        R.ITEM_KINDS[#R.ITEM_KINDS + 1] = kind
    end
    entry.kind = kind
    R.ITEMS[name] = entry
    table.insert(R.ITEM_NAMES[kind], name)
    table.sort(R.ITEM_NAMES[kind])
end

-- Plain gear, written as "Name|price in copper|pounds" with ";" between items.
function R.AddGear(kind, list)
    for name, cost, weight in list:gmatch("([^|;]+)|([%d%.]+)|([%d%.]+)") do
        Register(kind, strtrim(name), { cost = tonumber(cost), weight = tonumber(weight) })
    end
end

-- A magic item. `extra` can carry weight, cost, attune (true) and limit. One without
-- a cost of its own is priced by its rarity once every list has loaded and the ones
-- that are used up are known (Data/MagicItemPrices.lua).
function R.AddMagicItem(name, rarity, desc, effects, extra)
    local entry = { cost = 0, weight = 0, rarity = rarity, desc = desc, effects = effects or {} }
    for key, value in pairs(extra or {}) do entry[key] = value end
    Register("Magic items", name, entry)
end

-- "5 gp, 2 lb." for a dropdown or a tooltip; either part is left out when it is zero.
function R.ItemSummary(cost, weight)
    local parts = {}
    if (cost or 0) > 0 then parts[#parts + 1] = ns.CoinText(cost) end
    if (weight or 0) > 0 then parts[#parts + 1] = ("%s lb."):format(weight) end
    return table.concat(parts, ", ")
end
