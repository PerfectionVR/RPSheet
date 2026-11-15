-- Prices for the magic items of the catalogue: each is worth what its rarity says
-- (Rules.MAGIC_VALUES in Data/Items.lua), half of that when it is used up, plus the
-- price of the plain thing it is made from. So they can be bought and sold, and a
-- faction's discount reaches them (Sheet/Shop.lua). This runs after every item list,
-- because the lists mark their consumables (Rules.CONSUMABLES) as they go. An item
-- that names a price of its own keeps it; an artifact stays without one.
local _, ns = ...
local R = ns.Rules

for _, name in ipairs(R.ITEM_NAMES["Magic items"] or {}) do
    local item = R.ITEMS[name]
    if (item.cost or 0) == 0 then
        item.cost = R.MagicItemValue(item.rarity, R.CONSUMABLES[name], R.RECIPE_BASE[name])
    end
end
