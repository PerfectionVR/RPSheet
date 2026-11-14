-- Coins: the five denominations, what each is worth, and turning sums into text and
-- text into sums. Every price and sum in the addon is kept in copper pieces.
local _, ns = ...
local R = ns.Rules

R.COINS = {
    pp = { name = "Platinum", value = 1000 },
    gp = { name = "Gold", value = 100 },
    ep = { name = "Electrum", value = 50 },
    sp = { name = "Silver", value = 10 },
    cp = { name = "Copper", value = 1 },
}
R.COIN_ORDER = { "pp", "gp", "ep", "sp", "cp" } -- largest first
-- Money handed to the character comes as gold, silver and copper: platinum and
-- electrum only turn up when the player enters them.
R.CHANGE_ORDER = { "gp", "sp", "cp" }
R.COINS_PER_POUND = 50

-- Gold a class offers in place of its starting gear, by the class it builds on; a
-- background offers the same amount whichever it is.
R.START_GOLD = {
    Barbarian = 75, Bard = 90, Cleric = 110, Druid = 50, Fighter = 155, Monk = 50,
    Paladin = 150, Ranger = 150, Rogue = 100, Sorcerer = 50, Warlock = 100, Wizard = 55,
}
R.BACKGROUND_GOLD = 50

-- Words a player may type for a coin: "gp", "gold", "g".
local WORDS = {}
for key, coin in pairs(R.COINS) do
    WORDS[key], WORDS[coin.name:lower()], WORDS[key:sub(1, 1)] = key, key, key
end

-- 1234 -> "12 gp 3 sp 4 cp". Nothing at all reads "0 gp".
function ns.CoinText(copper)
    local parts = {}
    copper = math.max(0, math.floor(copper or 0))
    for _, key in ipairs(R.CHANGE_ORDER) do
        local count = math.floor(copper / R.COINS[key].value)
        if count > 0 then parts[#parts + 1] = ("%d %s"):format(count, key) end
        copper = copper - count * R.COINS[key].value
    end
    return #parts > 0 and table.concat(parts, " ") or "0 gp"
end

-- A purse as it is, coin by coin: "2 pp  15 gp  3 sp  0 cp". Electrum only shows when
-- there is some. `mark` is a colour code for the numbers.
function ns.PurseText(purse, mark)
    local parts = {}
    for _, key in ipairs(R.COIN_ORDER) do
        local count = purse[key] or 0
        if key ~= "ep" or count > 0 then
            parts[#parts + 1] = ("%s%d|r %s"):format(mark or "", count, key)
        end
    end
    return table.concat(parts, "  ")
end

-- "5 gp 3 sp", "12 gold" or a bare number (gold) as copper pieces; nil when the
-- text can't be read as money.
function ns.ParseCoins(text)
    text = (text or ""):lower():gsub(",", "")
    local bare = tonumber(text:match("^%s*(%d+)%s*$"))
    if bare then return bare * R.COINS.gp.value end
    local total, found = 0, false
    for amount, word in text:gmatch("(%d+)%s*(%a+)") do
        local key = WORDS[word]
        if not key then return nil end
        total, found = total + tonumber(amount) * R.COINS[key].value, true
    end
    return found and total or nil
end
