-- The top of the Customize > Inventory page: where the character stands (money,
-- weight, attunement), the coins, and picking a listed item to add or buy.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

local kind, picked, quantity = R.ITEM_KINDS[1], "", 1

local function Price()
    return ns.ItemPrice(picked, quantity)
end

local function Standing()
    local attuned = #RPSheet:AttunedItems()
    local weight, capacity = RPSheet:CarriedWeight(), RPSheet:CarryCapacity()
    return ("Money: %s%s|r     Carried: %s%.1f of %d lb.|r     Attuned: %s%d of %d|r\n"):format(
        Opt.GOLD, ns.CoinText(RPSheet:Coins()),
        weight > capacity and Opt.RED or Opt.GOLD, weight, capacity,
        attuned > R.ATTUNE_LIMIT and Opt.RED or Opt.GOLD, attuned, R.ATTUNE_LIMIT)
end

local function Added()
    picked, quantity = "", 1
    ns.RebuildOptions()
    Opt.Changed()
end

function Opt.InventoryExtra(args)
    args.standing = { type = "description", order = 0.1, fontSize = "medium", name = Standing }
    Opt.AddCoinArgs(args, 0.2)
    args.listHeader = { type = "header", order = 0.5, name = "Add an item" }
    args.kind = {
        type = "select", order = 0.51, name = "Kind",
        values = function() return (Opt.ListMap(R.ITEM_KINDS)) end,
        sorting = R.ITEM_KINDS,
        get = function() return kind end,
        set = function(_, value) kind, picked = value, "" end,
    }
    args.listed = {
        type = "select", order = 0.52, name = "Item", width = "double",
        desc = "Each item with its price and weight. Magic items have no listed price: what one costs is up to the DM.",
        values = function()
            local values = {}
            for _, name in ipairs(R.ITEM_NAMES[kind]) do
                local known = R.ITEMS[name]
                local summary = R.ItemSummary(known.cost, known.weight)
                if known.rarity then summary = known.rarity:lower() .. (known.attune and ", attunement" or "") end
                values[name] = summary ~= "" and ("%s - %s"):format(name, summary) or name
            end
            return values
        end,
        sorting = function() return R.ITEM_NAMES[kind] end,
        get = function() return picked end,
        set = function(_, value) picked = value end,
    }
    args.quantity = {
        type = "range", order = 0.53, min = 1, max = 100, softMax = 20, step = 1, name = "How many",
        get = function() return quantity end,
        set = function(_, value) quantity = value end,
    }
    args.addListed = {
        type = "execute", order = 0.54, name = "Add", width = 0.6,
        desc = "Adds it without paying: found, given, or part of your starting gear.",
        disabled = function() return not R.ITEMS[picked] end,
        func = function()
            RPSheet:AddItem(picked, quantity)
            Added()
        end,
    }
    args.buyListed = {
        type = "execute", order = 0.55, width = 1.2,
        name = function() return Price() > 0 and ("Buy for %s"):format(ns.CoinText(Price())) or "Buy" end,
        desc = "Pays the price from your coins and adds it. Greyed out when it has no listed price or you can't afford it.",
        disabled = function() return Price() <= 0 or not RPSheet:CanAfford(Price()) end,
        func = function()
            if RPSheet:BuyItem(picked, quantity) then Added() end
        end,
    }
    args.listedInfo = {
        type = "description", order = 0.6,
        name = function()
            local known = R.ITEMS[picked]
            return known and known.desc and (known.desc .. "\n") or ""
        end,
    }
end
