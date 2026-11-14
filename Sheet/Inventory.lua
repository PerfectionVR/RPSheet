-- What the character carries (sheet.items): which items count right now, what they
-- add, how much it all weighs, attunement, and adding or buying an item.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

---------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------
-- An item's effects count while it is equipped, attuned if it needs that, and not
-- stopped by armor (Bracers of Defense). Returns false and the reason otherwise.
function RPSheet:ItemActive(item)
    if item.name == "" or not item.equipped then return false, "not equipped" end
    if item.attune and not item.attuned then return false, "not attuned" end
    local stopped = self:PassiveBlocked(item)
    if stopped then return false, ("you have %s on"):format(stopped) end
    return true
end

-- Total of what active items add to `target`; part of RPSheet:Bonus.
function RPSheet:ItemBonus(target)
    local total = 0
    for _, item in ipairs(self:Sheet().items or NONE) do
        if #item.effects > 0 and self:ItemActive(item) then
            for _, effect in ipairs(item.effects) do
                if effect.target == target then total = total + self:EffectValue(effect) end
            end
        end
    end
    return total
end

---------------------------------------------------------------------------
-- Attunement
---------------------------------------------------------------------------
-- The items the character is attuned to.
function RPSheet:AttunedItems()
    local attuned = {}
    for _, item in ipairs(self:Sheet().items or NONE) do
        if item.name ~= "" and item.attune and item.attuned then attuned[#attuned + 1] = item end
    end
    return attuned
end

---------------------------------------------------------------------------
-- Weight
---------------------------------------------------------------------------
-- Pounds carried: every item, and the coins at fifty to the pound.
function RPSheet:CarriedWeight()
    local total, coins = 0, 0
    for _, item in ipairs(self:Sheet().items or NONE) do
        if item.name ~= "" then total = total + item.qty * item.weight end
    end
    for _, key in ipairs(R.COIN_ORDER) do coins = coins + self:Purse()[key] end
    return total + coins / R.COINS_PER_POUND
end

-- Pounds the character can carry: Strength score times 15, twice that when Large.
function RPSheet:CarryCapacity()
    local sheet = self:Sheet()
    return self:Score("STR", true) * (R.CARRY_PER_STRENGTH[sheet.size] or R.CARRY_PER_STRENGTH.M)
end

---------------------------------------------------------------------------
-- Adding and buying
---------------------------------------------------------------------------
-- A sheet entry for `name`: filled in from the catalogue when it is listed there
-- (Data/Items.lua), otherwise an empty item of that name.
function ns.NewItem(name)
    local item = CopyTable(R.TEMPLATES.item)
    item.name = name
    local known = R.ITEMS[name]
    if not known then return item end
    item.cost, item.weight, item.desc = known.cost, known.weight, known.desc or ""
    item.magic, item.rarity = known.rarity ~= nil, known.rarity or ""
    item.attune, item.limit = known.attune == true, known.limit or ""
    for _, effect in ipairs(known.effects or NONE) do
        item.effects[#item.effects + 1] = CopyTable(effect)
    end
    return item
end

-- Adds `quantity` of an item. Plain gear of the same name stacks; a magic item is
-- always an entry of its own, since each is equipped and attuned by itself.
function RPSheet:AddItem(name, quantity)
    local items = self:Sheet().items
    quantity = math.max(1, math.floor(quantity or 1))
    for _, item in ipairs(items) do
        if item.name == name and not item.magic then
            item.qty = item.qty + quantity
            return item
        end
    end
    local item = ns.NewItem(name)
    item.qty = quantity
    items[#items + 1] = item
    return item
end

-- Price of `quantity` of a listed item in copper; 0 when it has no listed price.
function ns.ItemPrice(name, quantity)
    local known = R.ITEMS[name]
    return known and known.cost * math.max(1, math.floor(quantity or 1)) or 0
end

-- Pays for a listed item and adds it. False when the character can't afford it.
function RPSheet:BuyItem(name, quantity)
    quantity = math.max(1, math.floor(quantity or 1))
    local label = quantity > 1 and ("%s x%d"):format(name, quantity) or name
    if not self:SpendCoins(ns.ItemPrice(name, quantity), label) then return false end
    self:AddItem(name, quantity)
    return true
end

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
local function Whole(value, high)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.max(0, math.min(high, math.floor(value)))
end

-- Makes the coins and the item list of a saved or imported sheet well-formed.
-- `source` is the untrusted sheet an import was read from: its weights are taken
-- from there, because they can be fractions.
function ns.NormalizeInventory(sheet, source)
    if type(sheet.coins) ~= "table" then sheet.coins = {} end
    local coins = source and (type(source.coins) == "table" and source.coins or NONE) or sheet.coins
    for _, key in ipairs(R.COIN_ORDER) do sheet.coins[key] = Whole(coins[key], 9999999) end
    if type(sheet.items) ~= "table" then sheet.items = {} end
    for index, item in ipairs(sheet.items) do
        local weight = tonumber((source and source.items[index] or item).weight)
        item.weight = (weight and weight == weight) and math.max(0, math.min(9999, weight)) or 0
        item.qty, item.cost = Whole(item.qty, 9999), Whole(item.cost, 99999999)
        if not R.RARITIES[item.rarity] then item.rarity = "" end
        if not R.ITEM_LIMITS[item.limit] then item.limit = "" end
        for at = #item.effects, 1, -1 do
            if not R.EFFECT_TARGETS[item.effects[at].target] then table.remove(item.effects, at) end
        end
    end
end
