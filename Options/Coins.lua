-- The money part of the Customize > Inventory page: each kind of coin as a number to
-- set directly, and an amount to add or spend the way the sheet does it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

local amount = "" -- the text typed in the "Amount" box

-- Adds its options to `args` at orders from `base` up to base + 0.1.
function Opt.AddCoinArgs(args, base)
    args.coinsHeader = { type = "header", order = base, name = "Coins" }
    for index, key in ipairs(R.COIN_ORDER) do
        args["coin" .. key] = {
            type = "input", order = base + 0.01 + index / 1000, width = 0.5,
            name = ("%s (%s)"):format(R.COINS[key].name, key),
            desc = ("How many %s pieces you have. Worth %s each."):format(R.COINS[key].name:lower(),
                key == "cp" and "1 cp" or ns.CoinText(R.COINS[key].value)),
            get = function() return tostring(RPSheet:Purse()[key]) end,
            set = function(_, value)
                RPSheet:Purse()[key] = math.max(0, math.min(9999999, math.floor(tonumber(value) or 0)))
                Opt.Changed()
            end,
        }
    end
    args.coinBreak = { type = "description", order = base + 0.03, name = "" }
    args.coinAmount = {
        type = "input", order = base + 0.04, name = "Amount",
        desc = "Money to add or spend, written like 5 gp 3 sp. A bare number is gold.",
        get = function() return amount end,
        set = function(_, value) amount = value end,
    }
    args.coinAdd = {
        type = "execute", order = base + 0.05, name = "Add", width = 0.6,
        desc = "Adds the amount as gold, silver and copper.",
        disabled = function() return not ns.ParseCoins(amount) end,
        func = function()
            RPSheet:AddCoins(ns.ParseCoins(amount))
            Opt.Changed()
        end,
    }
    args.coinSpend = {
        type = "execute", order = base + 0.06, name = "Spend", width = 0.6,
        desc = "Pays the amount. Coins that fit are paid first; a larger coin is broken for change when the small ones run out. Refused when you don't have that much.",
        disabled = function()
            local copper = ns.ParseCoins(amount)
            return not copper or not RPSheet:CanAfford(copper)
        end,
        func = function()
            RPSheet:SpendCoins(ns.ParseCoins(amount))
            Opt.Changed()
        end,
    }
end
