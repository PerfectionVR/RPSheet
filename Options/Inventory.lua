-- "Inventory" page under Customize: one page per carried item. The top of the page
-- (coins, adding and buying) is in Options/InventoryAdd.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- Whether the item's effects count right now, and if not, why.
local function Status(item)
    if #item.effects == 0 then return "" end
    local active, why = RPSheet:ItemActive(item)
    if active then return Opt.GREEN .. "Its effects are counted.|r\n" end
    return ("%sIts effects are not counted: %s.|r\n"):format(Opt.RED, why)
end

local function Build(item)
    local function self() return item end
    local function IsMagic() return item.magic end
    local args = {
        status = { type = "description", order = 0.5, fontSize = "medium", name = function() return Status(item) end },
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        qty = With({ type = "range", order = 2, min = 0, max = 9999, softMax = 50, step = 1, name = "Quantity" }, self, "qty"),
        weight = {
            type = "input", order = 3, width = 0.6, name = "Weight (lb.)", desc = "Pounds for one of them.",
            get = function() return tostring(item.weight) end,
            set = function(_, value)
                item.weight = math.max(0, math.min(9999, tonumber(value) or 0))
                Opt.Changed()
            end,
        },
        cost = {
            type = "input", order = 4, width = 0.8, name = "Price",
            desc = "What one of them costs, written like 5 gp 3 sp. Selling gives back half.",
            get = function() return item.cost > 0 and ns.CoinText(item.cost) or "" end,
            set = function(_, value)
                item.cost = ns.ParseCoins(value) or 0
                Opt.Changed()
            end,
        },
        equipped = {
            type = "toggle", order = 5, name = "Equipped",
            desc = "Worn or held. An item's effects only count while it is equipped. Equipping armor or a shield puts it on, and equipping a basic weapon readies it on the sheet. You can also click the item on the sheet.",
            get = function() return item.equipped end,
            set = function(_, value)
                RPSheet:SetEquipped(item, value)
                Opt.Changed()
            end,
        },
        sell = {
            type = "execute", order = 6, name = "Sell one",
            desc = function() return ("Takes one off the list and gives you half its price: %s."):format(ns.CoinText(math.floor(item.cost / 2))) end,
            hidden = function() return item.cost <= 0 end,
            disabled = function() return item.qty <= 0 end,
            func = function()
                item.qty = item.qty - 1
                RPSheet:AddCoins(math.floor(item.cost / 2), "sold " .. item.name)
                Opt.Changed()
            end,
        },
        desc = With({ type = "input", order = 7, width = "full", multiline = 2, name = "Note" }, self, "desc", true),
        magicHeader = { type = "header", order = 20, name = "Magic" },
        magic = With({ type = "toggle", order = 21, name = "Magic item" }, self, "magic"),
        rarity = With({
            type = "select", order = 22, name = "Rarity", hidden = function() return not IsMagic() end,
            values = R.RARITIES, sorting = R.RARITY_ORDER,
        }, self, "rarity"),
        attune = With({
            type = "toggle", order = 23, name = "Requires attunement", hidden = function() return not IsMagic() end,
            desc = "Its magic only works once you are attuned to it, which takes a short rest spent with the item.",
        }, self, "attune"),
        attuned = With({
            type = "toggle", order = 24, hidden = function() return not (IsMagic() and item.attune) end,
            name = function()
                local count = #RPSheet:AttunedItems()
                return ("Attuned (%s%d of %d|r)"):format(count > R.ATTUNE_LIMIT and Opt.RED or "", count, R.ATTUNE_LIMIT)
            end,
            desc = ("You can be attuned to %d items at a time. The sheet holds you to that; here the count turns red when you go over."):format(R.ATTUNE_LIMIT),
        }, self, "attuned"),
        limit = With({
            type = "select", order = 25, name = "Its effects count", hidden = function() return not IsMagic() end,
            desc = "Some items stop working in armor, such as bracers that only protect an unarmored wearer.",
            values = R.ITEM_LIMITS, sorting = R.ITEM_LIMIT_ORDER,
        }, self, "limit"),
    }
    Opt.AddEffectArgs(args, item,
        "What the item adds to your numbers while it is equipped, and attuned if it requires that. Each effect adds a flat number, a modifier, your level or your proficiency bonus to one thing. A magic weapon's own bonus is set on the weapon, on the Weapons page.",
        100)
    return args
end

Opt.lists.items = {
    extra = Opt.InventoryExtra,
    order = 5.5, title = "Inventory", noun = "item", template = R.TEMPLATES.item, build = Build,
    help = "Your money and what you carry. Listed items are added and bought in the item browser; an item of your own is added here as an empty one to fill in. Equip armor, a shield or a basic weapon to wear or ready it; the Defense and Weapons pages can still set those directly.\n",
}
