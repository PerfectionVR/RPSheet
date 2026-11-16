-- Coins: text and parsing, adding, spending with change from every mix of
-- denominations, refusing when short, and the add/spend box.
dofile(ARG3 .. "/t-test-items-lib.lua")
NewChar("WARRIOR", 1)
local sheet = RPSheet:Sheet()

-- Text
Eq(ns.CoinText(0), "0 gp", "CoinText 0")
Eq(ns.CoinText(1234), "12 gp 3 sp 4 cp", "CoinText 1234")
Eq(ns.CoinText(100000), "1000 gp", "CoinText 100000")
Eq(ns.CoinText(7), "7 cp", "CoinText 7")
Eq(ns.CoinText(-5), "0 gp", "CoinText negative")
Eq(ns.CoinText(nil), "0 gp", "CoinText nil")
Eq(ns.CoinText(10.9), "1 sp", "CoinText fraction")

-- Parsing
local PARSE = {
    { "5", 500 }, { " 12 ", 1200 }, { "5 gp 3 sp", 530 }, { "5gp3sp", 530 }, { "12 gold", 1200 }, { "3 g", 300 },
    { "1 pp", 1000 }, { "1 platinum 2 electrum", 1100 }, { "4 ep", 200 }, { "7 cp", 7 }, { "7 copper", 7 }, { "2 s", 20 },
    { "1,000 gp", 100000 }, { "1,000", 100000 }, { "5 GP", 500 }, { "0", 0 }, { "0 gp", 0 },
    { "5 gp, 3 sp", 530 }, { "5 gp and 3 sp", 530 }, { "", false }, { "abc", false }, { "5 zz", false }, { "gp", false },
    { "-5", false }, { "1.5 gp", false }, { "5 gp 3", false }, { "3 5 gp", false }, { "5 gpx", false }, { "x 5 gp", false },
}
for _, case in ipairs(PARSE) do
    local got = Run("ParseCoins " .. case[1], ns.ParseCoins, case[1])
    Eq(got or false, case[2], ("ParseCoins(%q)"):format(case[1]))
end
Eq(ns.ParseCoins(nil), nil, "ParseCoins nil")

-- Adding: comes as gold, silver, copper
local purse = RPSheet:Purse()
local function Set(pp, gp, ep, sp, cp) purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = pp, gp, ep, sp, cp end
Set(0, 0, 0, 0, 0)
local mark = #PRINTED
RPSheet:AddCoins(1234, "a find")
Eq(purse.gp, 12, "AddCoins gp"); Eq(purse.sp, 3, "AddCoins sp"); Eq(purse.cp, 4, "AddCoins cp"); Eq(purse.pp + purse.ep, 0, "AddCoins no pp/ep")
Check(PrintedSince(mark):find("Gained 12 gp 3 sp 4 cp (a find). You now have 12 gp 3 sp 4 cp.", 1, true), "AddCoins message: " .. PrintedSince(mark))
mark = #PRINTED
Check(RPSheet:AddCoins(0) == true and #PRINTED == mark, "AddCoins 0 is silent")
Check(RPSheet:AddCoins(-50) == true and RPSheet:Coins() == 1234, "AddCoins negative does nothing")
RPSheet:AddCoins(12.7)
Eq(RPSheet:Coins(), 1246, "AddCoins fraction floors")
Check(RPSheet:CanAfford(1246) and not RPSheet:CanAfford(1247) and RPSheet:CanAfford(nil), "CanAfford")

-- Spending: every mix of which denominations are in the purse, a range of prices.
local VALUE = { pp = 1000, gp = 100, ep = 50, sp = 10, cp = 1 }
local counted = 0
for mask = 1, 31 do
    for _, amount in ipairs({ 1, 2, 3 }) do
        local have = {}
        for index, key in ipairs(R.COIN_ORDER) do have[key] = (math.floor(mask / 2 ^ (index - 1)) % 2 == 1) and amount or 0 end
        local total = 0
        for key, count in pairs(have) do total = total + count * VALUE[key] end
        for _, price in ipairs({ 1, 9, 10, 11, 49, 50, 51, 99, 100, 101, 555, 999, 1000, 1001, total - 1, total, total + 1 }) do
            if price >= 1 then
                Set(have.pp, have.gp, have.ep, have.sp, have.cp)
                local before = { pp = have.pp, gp = have.gp, ep = have.ep, sp = have.sp, cp = have.cp }
                local ok = RPSheet:SpendCoins(price, "test")
                counted = counted + 1
                local label = ("spend %d from pp%d gp%d ep%d sp%d cp%d"):format(price, have.pp, have.gp, have.ep, have.sp, have.cp)
                if price > total then
                    Check(ok == false and RPSheet:Coins() == total, label .. ": should refuse and keep the purse")
                    for key in pairs(VALUE) do Check(purse[key] == before[key], label .. ": purse changed on refusal") end
                else
                    Check(ok == true, label .. ": refused though affordable")
                    Eq(RPSheet:Coins(), total - price, label .. ": what is left")
                    for key in pairs(VALUE) do
                        Check(purse[key] >= 0 and purse[key] == math.floor(purse[key]), label .. ": " .. key .. " is " .. tostring(purse[key]))
                    end
                    -- Change never comes back as platinum or electrum beyond what was there.
                    Check(purse.pp <= before.pp and purse.ep <= before.ep, label .. ": change came as platinum or electrum")
                end
            end
        end
    end
end
-- Messages
Set(0, 5, 0, 0, 0)
mark = #PRINTED
Check(RPSheet:SpendCoins(600, "a horse") == false, "refuse 6 gp with 5")
Check(PrintedSince(mark):find("You can't afford 6 gp (a horse): you have 5 gp.", 1, true), "refusal message: " .. PrintedSince(mark))
mark = #PRINTED
Check(RPSheet:SpendCoins(125) == true, "spend 1 gp 2 sp 5 cp")
Check(PrintedSince(mark):find("Spent 1 gp 2 sp 5 cp. You have 3 gp 7 sp 5 cp left.", 1, true), "spend message: " .. PrintedSince(mark))
Eq(purse.gp, 3, "broke one gold: gp"); Eq(purse.sp, 7, "broke one gold: sp"); Eq(purse.cp, 5, "broke one gold: cp")
mark = #PRINTED
Check(RPSheet:SpendCoins(0) == true and #PRINTED == mark, "spending nothing is silent and fine")
Check(RPSheet:SpendCoins(-5) == true and RPSheet:Coins() == 375, "spending a negative amount does nothing")

-- A purse with holes (an older character)
sheet.coins = { gp = 2 }
Eq(RPSheet:Coins(), 200, "purse with missing coins")
sheet.coins = nil
Eq(RPSheet:Coins(), 0, "no purse at all")
purse = RPSheet:Purse()

-- The box
local popup = StaticPopupDialogs.RPSHEET_COINS
Check(type(popup) == "table", "the coin popup exists")
Run("CoinDialog add", function() RPSheet:CoinDialog(false) end)
Run("CoinDialog spend", function() RPSheet:CoinDialog(true) end)
Check(#SHOWN_POPUPS == 2 and SHOWN_POPUPS[2].data.spend == true and SHOWN_POPUPS[1].text:find("Add how much%? You have 0 gp"), "CoinDialog asks")
local dialog, box = FakePopup("5 gp 3 sp", { spend = false })
Run("popup OnShow", popup.OnShow, dialog)
Eq(box:GetText(), "", "OnShow empties the box")
box:SetText("5 gp 3 sp")
Run("popup OnAccept add", popup.OnAccept, dialog)
Eq(RPSheet:Coins(), 530, "box adds")
dialog, box = FakePopup("2 gp", { spend = true })
Run("popup Enter spend", popup.EditBoxOnEnterPressed, box)
Eq(RPSheet:Coins(), 330, "box spends")
Check(dialog.hidden, "Enter closes the box")
dialog, box = FakePopup("nonsense", { spend = true })
mark = #PRINTED
Run("popup nonsense", popup.OnAccept, dialog)
Check(RPSheet:Coins() == 330 and PrintedSince(mark):find("doesn't read as money"), "nonsense is refused with a word")
dialog, box = FakePopup("99 gp", { spend = true })
Run("popup too much", popup.OnAccept, dialog)
Eq(RPSheet:Coins(), 330, "box refuses more than there is")
dialog, box = FakePopup("1 gp", nil)
Run("popup without data adds", popup.OnAccept, dialog)
Eq(RPSheet:Coins(), 430, "box without data adds")
Run("popup Escape", popup.EditBoxOnEscapePressed, box)
Check(dialog.hidden, "Escape closes the box")

-- Coins weigh: fifty to the pound
Set(1, 20, 4, 15, 10)
Eq(RPSheet:CarriedWeight(), 1, "50 coins weigh a pound")

-- Saved data
sheet.coins = { pp = -3, gp = "12", ep = 0 / 0, sp = 2.9, cp = 1e12 }
ns.NormalizeInventory(sheet)
Eq(sheet.coins.pp, 0, "normalize negative"); Eq(sheet.coins.gp, 12, "normalize text"); Eq(sheet.coins.ep, 0, "normalize nan")
Eq(sheet.coins.sp, 2, "normalize fraction"); Eq(sheet.coins.cp, 9999999, "normalize huge")

print("spend cases", counted)
Done("coins")
