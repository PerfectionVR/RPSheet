-- The character's money. Anything that costs or pays money goes through these four:
--   RPSheet:Coins()                     what the character has, in copper pieces
--   RPSheet:CanAfford(copper)           true if that much can be paid
--   RPSheet:SpendCoins(copper, reason)  pays it, or refuses and says why; true if paid
--   RPSheet:AddCoins(copper, reason)    hands it over
-- Amounts are in copper pieces (see Data/Coins.lua); `reason` is a few words for the
-- note the player gets, such as the name of what was bought.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The coins themselves: { pp, gp, ep, sp, cp }.
function RPSheet:Purse()
    local sheet = self:Sheet()
    if type(sheet.coins) ~= "table" then sheet.coins = {} end
    for _, key in ipairs(R.COIN_ORDER) do sheet.coins[key] = sheet.coins[key] or 0 end
    return sheet.coins
end

function RPSheet:Coins()
    local purse, total = self:Purse(), 0
    for _, key in ipairs(R.COIN_ORDER) do
        total = total + purse[key] * R.COINS[key].value
    end
    return total
end

function RPSheet:CanAfford(copper)
    return (copper or 0) <= self:Coins()
end

-- Puts `copper` in the purse as the largest everyday coins it makes.
local function Give(purse, copper)
    for _, key in ipairs(R.CHANGE_ORDER) do
        local count = math.floor(copper / R.COINS[key].value)
        purse[key], copper = purse[key] + count, copper - count * R.COINS[key].value
    end
end

local function Why(reason)
    return (reason and reason ~= "") and (" (" .. reason .. ")") or ""
end

function RPSheet:AddCoins(copper, reason)
    copper = math.max(0, math.floor(copper or 0))
    if copper == 0 then return true end
    Give(self:Purse(), copper)
    self:Print(("Gained %s%s. You now have %s."):format(ns.CoinText(copper), Why(reason), ns.CoinText(self:Coins())))
    self:PopulateSoon()
    return true
end

function RPSheet:SpendCoins(copper, reason)
    copper = math.max(0, math.floor(copper or 0))
    if not self:CanAfford(copper) then
        self:Print(("You can't afford %s%s: you have %s."):format(ns.CoinText(copper), Why(reason), ns.CoinText(self:Coins())))
        return false
    end
    if copper == 0 then return true end
    -- Pay with whole coins first, the largest that fit.
    local purse, left = self:Purse(), copper
    for _, key in ipairs(R.COIN_ORDER) do
        local value = R.COINS[key].value
        local used = math.min(purse[key], math.floor(left / value))
        purse[key], left = purse[key] - used, left - used * value
    end
    -- Short of small coins: every coin still in the purse is worth more than what is
    -- left to pay, so the smallest of them is broken and the change comes back.
    if left > 0 then
        for index = #R.COIN_ORDER, 1, -1 do
            local key = R.COIN_ORDER[index]
            if purse[key] > 0 then
                purse[key] = purse[key] - 1
                Give(purse, R.COINS[key].value - left)
                break
            end
        end
    end
    self:Print(("Spent %s%s. You have %s left."):format(ns.CoinText(copper), Why(reason), ns.CoinText(self:Coins())))
    self:PopulateSoon()
    return true
end
