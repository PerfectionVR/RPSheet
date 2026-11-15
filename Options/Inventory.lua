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
        qty = With({ type = "range", order = 2, min = 1, max = 9999, softMax = 50, step = 1, name = "Quantity" }, self, "qty"),
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
                RPSheet:AddCoins(math.floor(item.cost / 2), "sold " .. item.name)
                RPSheet:DropItem(item) -- the last one takes the entry with it, and comes off first
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
        desc = With({ type = "input", order = 7, width = "full", multiline = 2, name = "Note" }, self, "desc", true),
        base = {
            type = "select", order = 8, name = "Counts as", width = 1.4,
            desc = "For a magic or named weapon, suit of armor or shield: the plain thing it is. Equipping the item then puts that armor on, raises the shield or readies the weapon under this item's name. Leave it at None for anything else, and for plain gear, which is known by its name.",
            values = function()
                local values = { [""] = "None" }
                for _, name in ipairs(R.ITEM_NAMES["Armor and shields"]) do values[name] = name end
                for _, name in ipairs(R.WEAPON_ORDER) do values[name] = name end
                return values
            end,
            sorting = function()
                local order = { "" }
                for _, name in ipairs(R.ITEM_NAMES["Armor and shields"]) do order[#order + 1] = name end
                for _, name in ipairs(R.WEAPON_ORDER) do order[#order + 1] = name end
                return order
            end,
            get = function() return item.base end,
            set = function(_, value)
                -- Taken off as what it was, put back on as what it is now.
                local worn = item.equipped
                if worn then RPSheet:SetEquipped(item, false) end
                item.base = value
                if worn then RPSheet:SetEquipped(item, true) end
                Opt.Changed()
            end,
        },
        bonus = With({
            type = "range", order = 9, min = 0, max = 3, step = 1, name = "Magic bonus",
            desc = "Armor and shields add it to your Armor Class while equipped. A weapon gets it on its attack and damage rolls when the item is first equipped; after that it is set on the weapon, on the Weapons page.",
            hidden = function() return ns.ItemSlot(item) == nil end,
        }, self, "bonus"),
        scribed = With({
            type = "toggle", order = 9.5, name = "Written by you", hidden = function() return ns.ScrollSpell(item) == nil end,
            desc = "A scroll you wrote casts with your own spell save DC and spell attack bonus. One that was found or bought casts with the fixed numbers of a scroll of its level.",
        }, self, "scribed"),
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
        "What the item adds to your numbers while it is equipped, and attuned if it requires that. Each effect adds a flat number, a modifier, your level or your proficiency bonus to one thing, or sets an ability score or your speed to a number that counts when it is higher than your own. A magic weapon's own bonus is set on the weapon, on the Weapons page.",
        100)
    return args
end

Opt.lists.items = {
    extra = Opt.InventoryExtra,
    order = 5.5, title = "Inventory", noun = "item", template = R.TEMPLATES.item, build = Build,
    help = "Your money and what you carry. Listed items are added and bought in the item browser; an item of your own is added here as an empty one to fill in. Equip armor, a shield or a weapon to wear or ready it (a weapon of your own goes by its name); the Defense and Weapons pages can still set those directly.\n",
}
