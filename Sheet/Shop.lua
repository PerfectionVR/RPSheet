-- What a purchase costs when the seller is a merchant of a faction the character
-- stands well with (the discounts: Data/RenownRules.lua). The sheet can't tell where
-- the character is shopping, so the player says whose merchant it is; that choice
-- lasts until the game is closed or the choice is changed.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local RANK = {}
for index, rarity in ipairs(R.RARITY_ORDER) do RANK[rarity] = index end

-- The share a faction's merchants take off for this character, in percent, and the
-- highest rarity of magic item it covers; nothing below Honored.
function ns.RenownDiscount(sheet, faction)
    local perk = R.RENOWN_DISCOUNT[R.RenownTier((ns.RenownScore(sheet, faction)))]
    if perk then return perk[1], perk[2] end
end

-- The factions whose merchants give this character a discount, in the usual order.
function ns.ShopFactions(sheet)
    local factions = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        if ns.RenownDiscount(sheet, faction) then factions[#factions + 1] = faction end
    end
    return factions
end

-- The faction the character is buying from right now, or nil for nobody in
-- particular. A faction that no longer gives a discount doesn't count.
function RPSheet:ShopFaction()
    local faction = self.shopFaction
    if faction and ns.RenownDiscount(self:Sheet(), faction) then return faction end
end

function RPSheet:SetShopFaction(faction)
    self.shopFaction = faction
end

-- `copper` with the discount of the faction bought from, when `covers(top rarity)`
-- says the thing is one it applies to. Also returns the percent and the faction.
local function Reduced(self, copper, covers)
    local faction = self:ShopFaction()
    if not faction or copper <= 0 then return copper end
    local percent, top = ns.RenownDiscount(self:Sheet(), faction)
    if not covers(top) then return copper end
    local reduced = math.floor(copper * (100 - percent) / 100 + 0.5)
    -- A price too small to lose a whole copper is not called a discount.
    if reduced >= copper then return copper end
    return reduced, percent, faction
end

-- What `quantity` of a listed item costs this character right now, in copper; with a
-- discount also the percent taken off and the faction giving it. Ordinary equipment
-- is covered, and magic items up to the rarity the standing reaches (they are priced
-- by their rarity, Data/MagicItemPrices.lua).
function RPSheet:ItemBuyPrice(name, quantity)
    local known = R.ITEMS[name]
    return Reduced(self, ns.ItemPrice(name, quantity), function(top)
        if not known then return false end
        if known.rarity then return (RANK[known.rarity] or 99) <= RANK[top] end
        return not R.NO_DISCOUNT_KINDS[known.kind] and not R.NO_DISCOUNT_ITEMS[name]
    end)
end

-- The same for a listed mount or vehicle: only the everyday ones are covered.
function RPSheet:MountBuyPrice(name)
    local known = R.MOUNTS[name]
    return Reduced(self, known and known.cost or 0, function() return R.DISCOUNT_RIDES[name] == true end)
end

-- "Buy  9 gp (-10%)" for a Buy button, or "No price".
function ns.BuyLabel(copper, percent)
    if copper <= 0 then return "No price" end
    return ("Buy  %s%s"):format(ns.CoinText(copper), percent and (" (-%d%%)"):format(percent) or "")
end
