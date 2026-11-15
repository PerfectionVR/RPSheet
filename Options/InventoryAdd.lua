-- The top of the Customize > Inventory page: where the character stands (money,
-- weight, attunement), the coins, and the way into the item browser.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

local function Standing()
    local attuned = #RPSheet:AttunedItems()
    local weight, capacity = RPSheet:CarriedWeight(), RPSheet:CarryCapacity()
    return ("Money: %s%s|r     Carried: %s%.1f of %d lb.|r     Attuned: %s%d of %d|r\n"):format(
        Opt.GOLD, ns.CoinText(RPSheet:Coins()),
        weight > capacity and Opt.RED or Opt.GOLD, weight, capacity,
        attuned > R.ATTUNE_LIMIT and Opt.RED or Opt.GOLD, attuned, R.ATTUNE_LIMIT)
end

function Opt.InventoryExtra(args)
    args.standing = { type = "description", order = 0.1, fontSize = "medium", name = Standing }
    Opt.AddCoinArgs(args, 0.2)
    args.listHeader = { type = "header", order = 0.5, name = "Add an item" }
    args.browse = {
        type = "execute", order = 0.51, name = "Browse items", width = "double",
        desc = "Opens the item browser: what you carry and every listed item as a block, with what it is and does and buttons to add, buy, equip and remove it.",
        func = function() RPSheet:ToggleItemBrowser() end,
    }
    Opt.VariantArgs(args, 0.6) -- a magic make of a plain armor or weapon (Options/InventoryVariant.lua)
end
