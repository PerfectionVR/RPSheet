-- Mounts, vehicles and companion creatures: every catalogue entry added and bought,
-- ridden by riders of each size or refused for the stated reason, the Speed row and
-- its explanation in the saddle, companions called and dismissed, loyalty, each gift.
dofile(ARG3 .. "/t-test-items-lib.lua")
local UI = ns.UI

local function Gold(gp)
    local purse = RPSheet:Purse()
    purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0
end
local function Explained(fn, ...)
    local mark = #PRINTED
    Run("explain", fn, RPSheet, ...)
    local text = PrintedSince(mark)
    return tonumber(text:match("|cffffd100(%-?%d+)")), text
end
local function Skill(name)
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == name then return skill end
    end
end
local names = {}
for name in pairs(R.MOUNTS) do names[#names + 1] = name end
table.sort(names)

---------------------------------------------------------------------------
-- The catalogue holds together
---------------------------------------------------------------------------
local SIDES = { ALLIANCE = true, HORDE = true }
for _, name in ipairs(names) do
    local known = R.MOUNTS[name]
    Check(R.MOUNT_KINDS[known.kind] ~= nil, name .. ": kind " .. tostring(known.kind))
    Check(tContains(R.MOUNT_GROUPS, known.group), name .. ": group " .. tostring(known.group))
    Check(known.size == nil or R.MOUNT_SIZES[known.size] ~= nil, name .. ": size " .. tostring(known.size))
    for _, key in ipairs({ "cost", "speed", "fly", "swim", "climb", "capacity", "weight" }) do
        Check(known[key] == nil or (type(known[key]) == "number" and known[key] >= 0 and known[key] == math.floor(known[key])), name .. ": " .. key .. " is " .. tostring(known[key]))
    end
    if known.kind == "COMPANION" then Check(R.COMPANIONS[known.family] ~= nil, name .. ": family " .. tostring(known.family)) end
    if known.renown then
        Check(type(known.renown[1]) == "number" and #known.renown >= 2, name .. ": renown")
        for index = 2, #known.renown do
            Check(SIDES[known.renown[index]] or tContains(R.ALL_FACTIONS, known.renown[index]), name .. ": renown with " .. tostring(known.renown[index]))
        end
    end
    Check(type(known.desc) == "string" and known.desc ~= "", name .. ": no note")
end
for name in pairs(R.DISCOUNT_RIDES) do Check(R.MOUNTS[name] ~= nil, "discounted ride " .. name .. " is not in the catalogue") end
Check(R.ITEMS[R.EXOTIC_SADDLE] ~= nil, "the exotic saddle is an item")

---------------------------------------------------------------------------
-- Adding and buying every entry
---------------------------------------------------------------------------
local sheet = NewChar("WARRIOR", 5, { scores = { STR = 15, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
Eq(RPSheet:StartingLoyalty(), 1, "Charisma 12: loyalty starts at 1")
Eq(RPSheet:LoyaltyCap(), 12, "and can reach 12")
for _, name in ipairs(names) do
    local known = R.MOUNTS[name]
    sheet.mounts = {}
    sheet.renown = {}
    local entry = Run("add " .. name, RPSheet.AddMount, RPSheet, name)
    if entry then
        Check(#sheet.mounts == 1 and RPSheet:OwnedMount(name) == entry, name .. ": added")
        for key, default in pairs(R.TEMPLATES.mount) do
            local want = known[key]
            if want == nil then want = default end
            if key == "name" then want = name end
            if key == "loyalty" and known.kind == "COMPANION" then want = 1 end
            Eq(entry[key], want, name .. ": " .. key)
        end
        RPSheet:RemoveMount(entry)
        Eq(#sheet.mounts, 0, name .. ": removed")
    end
    -- buying
    Gold(0)
    local why = RPSheet:MountNotSold(name)
    local mark = #PRINTED
    if known.unsold then
        Eq(why, "it can't be bought", name .. ": not sold")
    elseif (known.cost or 0) <= 0 then
        Eq(why, "it has no listed price", name .. ": no price")
    elseif known.renown then
        local who = {}
        for index = 2, #known.renown do who[#who + 1] = SIDES[known.renown[index]] and ("any faction of the " .. R.SIDE_NAMES[known.renown[index]]) or known.renown[index] end
        local need = ("renown %d with %s"):format(known.renown[1], table.concat(who, " or "))
        Eq(why, "it is only sold to those with " .. need, name .. ": standing asked")
        Gold(1000000)
        Check(RPSheet:BuyMount(name) == false and #sheet.mounts == 0 and RPSheet:Coins() == 100000000, name .. ": bought without the standing")
        Check(PrintedSince(mark):find(("You can't buy %s: it is only sold to those with %s."):format(name, need), 1, true), name .. ": says why: " .. PrintedSince(mark))
        -- one point short, then enough, with each faction that will do
        for index = 2, #known.renown do
            local who = known.renown[index]
            local faction = SIDES[who] and R.FACTIONS[who][3] or who
            sheet.renown = { [faction] = known.renown[1] - 1 }
            Check(RPSheet:MountNotSold(name) ~= nil, name .. ": sold one point short with " .. faction)
            sheet.renown = { [faction] = known.renown[1] }
            Check(RPSheet:MountNotSold(name) == nil, name .. ": not sold with the standing with " .. faction)
        end
        why = nil
    else
        Eq(why, nil, name .. ": anyone may buy it")
    end
    if why then
        Gold(1000000)
        Check(RPSheet:BuyMount(name) == false and #sheet.mounts == 0 and RPSheet:Coins() == 100000000, name .. ": bought though " .. why)
    else
        Gold(0); RPSheet:AddCoins(known.cost - 1)
        Check(RPSheet:BuyMount(name) == false and #sheet.mounts == 0, name .. ": bought a copper short")
        RPSheet:AddCoins(1)
        Check(RPSheet:BuyMount(name) == true and #sheet.mounts == 1 and RPSheet:Coins() == 0, name .. ": bought for its price")
        -- the discount of a faction's merchants: only the everyday ones
        sheet.renown["Kirin Tor"] = 10
        RPSheet:SetShopFaction("Kirin Tor")
        local price, percent = RPSheet:MountBuyPrice(name)
        if R.DISCOUNT_RIDES[name] then
            Check(price == math.floor(known.cost * 0.9 + 0.5) and percent == 10, name .. ": 10% off")
        else
            Check(price == known.cost and percent == nil, name .. ": keeps its price")
        end
        RPSheet:SetShopFaction(nil)
    end
    FlushTimers()
end
Check(RPSheet:MountNotSold("Unicorn of Nowhere") == "it is not listed" and RPSheet:BuyMount("Unicorn of Nowhere") == false, "an unlisted mount can't be bought")
local own = RPSheet:AddMount("Unicorn of Nowhere")
Check(own.kind == "MOUNT" and own.size == "L" and own.cost == 0, "an unlisted one is added as an empty mount")
FlushTimers()

---------------------------------------------------------------------------
-- Riding every entry, for riders of each size
---------------------------------------------------------------------------
local RANK = { S = 1, M = 2, L = 3, H = 4 }
local function Expected(known, name, riderSize, saddle, renownMet)
    if known.kind == "COMPANION" then return "a companion creature is too small to ride" end
    if known.kind == "VEHICLE" then
        if (known.travel or "") == "" then return "an animal pulls it: ride or lead the animal" end
        return nil
    end
    if not known.thing and RANK[known.size or "L"] <= RANK[riderSize] then
        return ("a mount has to be at least one size larger than you, and it is %s"):format(R.MOUNT_SIZES[known.size or "L"]:lower())
    end
    if not known.thing and ((known.fly or 0) > 0 or (known.swim or 0) > 0) and not saddle then
        return "a mount that flies or swims needs an Exotic Saddle, and you have none"
    end
    if known.keep and not renownMet then return "it no longer obeys you: that takes renown " .. known.renown[1] .. " with " .. known.renown[2] end
end
local function Pace(known)
    local walk, fly, swim = known.speed or 0, known.fly or 0, known.swim or 0
    if fly > 0 then return fly, "fly" end
    if walk < 10 and swim > walk then return swim, "swim" end
    return walk, ""
end
local ridden, refused = 0, 0
for _, size in ipairs({ "S", "M", "L" }) do
    sheet = NewChar("WARRIOR", 5, { size = size })
    sheet.size = size -- no species is Large; a DM's ruling under Customize can make a character so
    Eq(RPSheet:Speed(), 30, "on foot")
    for _, saddle in ipairs({ false, true }) do
        if saddle then RPSheet:AddItem(R.EXOTIC_SADDLE) end
        for _, name in ipairs(names) do
            local known = R.MOUNTS[name]
            local label = ("%s rider, %s%s"):format(size, name, saddle and " with saddle" or "")
            sheet.mounts, sheet.renown = {}, {}
            local entry = RPSheet:AddMount(name)
            local want = Expected(known, name, size, saddle, false)
            Eq(RPSheet:MountRefusal(entry), want, label .. ": refusal")
            Run(label .. " lines", function()
                for _, line in ipairs(UI.MountLines(RPSheet, name, entry)) do
                    if type(line) ~= "string" or line == "" then error("a line is " .. tostring(line)) end
                end
                UI.MountLines(RPSheet, name)
            end)
            local sent, mark = #SENT, #PRINTED
            Run(label .. " get on", RPSheet.ToggleRiding, RPSheet, entry); FlushTimers()
            if want then
                refused = refused + 1
                Check(not entry.riding and #SENT == sent, label .. ": got on though refused")
                Check(PrintedSince(mark):find(("You can't get on %s: %s."):format(name, want), 1, true), label .. ": says why: " .. PrintedSince(mark))
                if known.keep then
                    sheet.renown[known.renown[2]] = known.renown[1]
                    Eq(RPSheet:MountRefusal(entry), Expected(known, name, size, saddle, true), label .. ": with the standing")
                    sheet.renown = {}
                end
            else
                ridden = ridden + 1
                Check(entry.riding and RPSheet:Riding() == entry, label .. ": not riding")
                local vehicle = known.kind == "VEHICLE"
                Check(SentSince(sent):find((vehicle and "gets aboard the " or "mounts the ") .. name, 1, true), label .. ": announced " .. SentSince(sent))
                if vehicle then
                    Check(RPSheet:RiddenMount() == nil and RPSheet:Speed() == 30, label .. ": aboard a vehicle the speed stays your own")
                    Eq(Explained(RPSheet.ExplainSpeed), 30, label .. ": explained")
                    Eq(UI.RidingMark(RPSheet), "", label .. ": no mark on the Speed row")
                else
                    local pace, mode = Pace(known)
                    if pace > 0 then
                        Eq(RPSheet:Speed(), pace, label .. ": speed in the saddle")
                        local shown, text = Explained(RPSheet.ExplainSpeed)
                        Eq(shown, pace, label .. ": explained speed")
                        Check(text:find("you are riding " .. name, 1, true) and text:find("On foot your speed is 30 ft", 1, true), label .. ": explanation: " .. text)
                        if mode == "fly" then Check(text:find("flying; it moves", 1, true), label .. ": says it flies: " .. text) end
                        if mode == "swim" then Check(text:find("swimming; it moves", 1, true), label .. ": says it swims: " .. text) end
                        Eq(UI.RidingMark(RPSheet), mode ~= "" and (" " .. mode) or "", label .. ": mark on the Speed row")
                        Check(UI.SpeedTip(RPSheet):find(name, 1, true), label .. ": the Speed row's tip names the mount")
                        Eq(RPSheet:Speed(true), 30, label .. ": on foot")
                        -- its other speeds count in place of your own
                        for _, kind in ipairs(R.MOVE_KINDS) do
                            local feet = known[kind] or 0
                            local wantMove = (feet > 0 and kind ~= mode) and feet or nil
                            Eq(RPSheet:MoveSpeed(kind), wantMove, label .. ": " .. kind .. " speed")
                            local got, said = Explained(RPSheet.ExplainMoveSpeed, kind)
                            if wantMove then Check(got == wantMove and said:find("you are riding " .. name, 1, true), label .. ": " .. kind .. " explained: " .. said)
                            else Check(said:find("You have no", 1, true), label .. ": no " .. kind .. " speed explained: " .. said) end
                        end
                    else
                        Check(RPSheet:RiddenMount() == nil and RPSheet:Speed() == 30, label .. ": a mount with no speed leaves yours")
                    end
                end
                sent = #SENT
                RPSheet:ToggleRiding(entry); FlushTimers()
                Check(not entry.riding and RPSheet:Riding() == nil and RPSheet:Speed() == 30, label .. ": got off")
                Check(SentSince(sent):find((vehicle and "gets out of the " or "dismounts from the ") .. name, 1, true), label .. ": announced " .. SentSince(sent))
            end
        end
    end
end
print("ridden", ridden, "refused", refused)

-- In the saddle: armor, load and conditions
sheet = NewChar("WARRIOR", 5, { scores = { STR = 10, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
local horse, pony, cart = RPSheet:AddMount("Riding Horse"), RPSheet:AddMount("Elephant"), RPSheet:AddMount("Cart")
RPSheet:ToggleRiding(horse)
local plate = RPSheet:AddItem("Plate Armor", 4)
RPSheet:SetEquipped(plate, true)
Check(RPSheet:Overloaded() and RPSheet:Speed(true) == 5 and RPSheet:Speed() == 60, "overloaded in plate: 5 on foot, 60 in the saddle")
Check(UI.SpeedTip(RPSheet):find("5 ft on foot", 1, true), "the tip gives the speed on foot: " .. UI.SpeedTip(RPSheet))
RPSheet:ToggleRiding(pony)
Check(pony.riding and not horse.riding and RPSheet:Speed() == 40, "getting on another gets off the first")
RPSheet:State().conditions.Restrained = true
Check(RPSheet:Speed() == 0 and Explained(RPSheet.ExplainSpeed) == 0 and UI.RidingMark(RPSheet) == "", "restrained in the saddle: 0")
RPSheet:ToggleRiding(pony)
Check(not pony.riding, "getting off is always allowed")
local mark = #PRINTED
RPSheet:ToggleRiding(horse)
Check(not horse.riding and PrintedSince(mark):find("You can't get on Riding Horse: you are Restrained and can't move.", 1, true), "restrained: can't get on: " .. PrintedSince(mark))
RPSheet:State().conditions.Restrained = nil
RPSheet:ToggleRiding(horse)
RPSheet:RemoveMount(horse)
Check(RPSheet:Riding() == nil and RPSheet:Speed() == 5, "a removed mount is no longer ridden")
Eq(ns.PullLimit(pony, cart), 1320 * 5 - 200, "an elephant before a cart")
Eq(ns.MountSpeeds(R.MOUNTS.Gryphon), "30 ft, fly 80 ft", "MountSpeeds")
Eq(ns.MountSpeeds(R.MOUNTS.Airship), "8 mph", "MountSpeeds of a ship")
Eq(ns.MountSpeeds(R.MOUNTS.Cart), "", "MountSpeeds of a cart")
FlushTimers()

---------------------------------------------------------------------------
-- Companion creatures
---------------------------------------------------------------------------
sheet = NewChar("WARRIOR", 5, { scores = { STR = 15, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
local cat, owl = RPSheet:AddMount("Beast companion"), RPSheet:AddMount("Flying companion")
horse = RPSheet:AddMount("Riding Horse")
local sent = #SENT
RPSheet:ToggleCompanion(cat)
Check(cat.called and RPSheet:Companion() == cat and SentSince(sent):find("calls Beast companion to their side", 1, true), "called: " .. SentSince(sent))
RPSheet:ToggleCompanion(owl)
Check(owl.called and not cat.called and RPSheet:Companion() == owl, "calling another sends the first away")
sent = #SENT
RPSheet:ToggleCompanion(owl)
Check(not owl.called and RPSheet:Companion() == nil and SentSince(sent):find("dismisses Flying companion", 1, true), "dismissed: " .. SentSince(sent))
sent = #SENT
RPSheet:ToggleCompanion(horse); RPSheet:TreatCompanion(horse)
Check(not horse.called and #SENT == sent, "a horse is not a companion")
RPSheet:ToggleRiding(horse); RPSheet:ToggleCompanion(cat)
Check(horse.riding and cat.called, "riding and a companion out go together")
RPSheet:ToggleRiding(horse)
Check(cat.called, "getting off leaves the companion out")
-- loyalty
Eq(cat.loyalty, 1, "starts at 1")
local function Treat(entry, rolled)
    local at = #PRINTED
    DICE[#DICE + 1] = rolled
    Run("treat", RPSheet.TreatCompanion, RPSheet, entry); FlushTimers(); RPSheet.busy = false
    Check(#DICE == 0, "treat: the die was not rolled")
    DICE = {}
    return PrintedSince(at)
end
local said = Treat(cat, 3)
Check(cat.loyalty == 4 and said:find("loyalty 1 + 3 (1d4) = 4", 1, true), "treated well: " .. said)
Check(ROLLED[#ROLLED].high == 4, "the die is a d4")
cat.loyalty = 8
said = Treat(cat, 2)
Check(cat.loyalty == 10 and said:find("It is loyal enough to give its gift", 1, true) and said:find(R.COMPANIONS.Beast.gift, 1, true), "reaching 10 says so: " .. said)
said = Treat(cat, 4)
Check(cat.loyalty == 12 and said:find("held at your Charisma score of 12", 1, true), "held at the Charisma score: " .. said)
mark = #PRINTED
local rolledAt = #ROLLED
RPSheet:TreatCompanion(cat); FlushTimers()
Check(#ROLLED == rolledAt and PrintedSince(mark):find("can't grow more loyal", 1, true), "at the cap nothing is rolled")
-- hurt
sent = #SENT
RPSheet:HurtCompanion(cat)
Check(not cat.called and cat.loyalty == 11 and SentSince(sent):find("loses Beast companion to the damage", 1, true), "hurt: gone and less loyal: " .. SentSince(sent))
mark = #PRINTED
RPSheet:HurtCompanion(cat)
Check(cat.loyalty == 11 and PrintedSince(mark):find("is not out", 1, true), "one that is not out can't be hurt")
owl.loyalty = 0
RPSheet:ToggleCompanion(owl); RPSheet:HurtCompanion(owl)
Eq(owl.loyalty, 0, "loyalty doesn't go below 0")
-- a higher Charisma starts higher
sheet.base.CHA = 18
Check(RPSheet:StartingLoyalty() == 4 and RPSheet:AddMount("Magic companion").loyalty == 4, "Charisma 18: starts at 4")
sheet.base.CHA = 6
Eq(RPSheet:StartingLoyalty(), 1, "never below 1")
sheet.base.CHA = 12
FlushTimers()

-- Each family's gift: only from a companion that is out and loyal
local function Gifts()
    local got = {}
    got.swim = RPSheet:MoveSpeed("swim")
    got.speed = RPSheet:Speed()
    got.handling, got.survival = RPSheet:SkillMod(Skill("Animal Handling")), RPSheet:SkillMod(Skill("Survival"))
    got.persuasion, got.arcana = RPSheet:SkillMod(Skill("Persuasion")), RPSheet:SkillMod(Skill("Arcana"))
    got.death = RPSheet:CompanionAdvantage("death save roll") and RPSheet:AdvantageFrom("death save roll") or false
    got.ward = RPSheet:CompanionWard("psychic") or false
    local _, asked = RPSheet:SaveAdvantages("WIS save")
    got.asked = {}
    for _, entry in ipairs(asked) do
        if entry.from:find("companion") then got.asked[#got.asked + 1] = entry.about end
    end
    got.asked = table.concat(got.asked, ", ")
    return got
end
sheet = NewChar("WARRIOR", 5, { scores = { STR = 15, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
for _, skill in ipairs({ "Animal Handling", "Survival", "Persuasion", "Arcana" }) do sheet.skills[skill] = 0 end
local plain = Gifts()
Check(plain.swim == nil and plain.speed == 30 and plain.death == false and plain.ward == false and plain.asked == "", "no gifts without a companion")
local prof = RPSheet:ProficiencyBonus()
local WANT = {
    Aquatic = { swim = 30 }, Beast = { handling = plain.handling + 2 * prof, survival = plain.survival + 2 * prof },
    Dragonkin = { asked = "being Frightened" }, Elemental = { asked = "Exhaustion" }, Flying = { speed = 35 },
    Humanoid = { persuasion = plain.persuasion + 2 * prof }, Magic = { arcana = plain.arcana + 2 * prof },
    Mechanical = { ward = 4 }, Undead = { death = "your companion" },
}
for _, family in ipairs(R.COMPANION_ORDER) do
    sheet.mounts = {}
    local entry = RPSheet:AddMount(family .. " companion")
    Eq(entry.family, family, family .. ": family")
    Check(WANT[family] ~= nil, family .. ": the test knows no gift for it")
    local function Same(label, got, want)
        for key, value in pairs(plain) do
            local expected = want[key]
            if expected == nil then expected = value end
            Eq(got[key], expected, ("%s companion, %s: %s"):format(family, label, key))
        end
    end
    entry.loyalty = R.LOYALTY_GIFT
    Same("loyal but not out", Gifts(), {})
    RPSheet:ToggleCompanion(entry)
    Same("loyal and out", Gifts(), WANT[family])
    Check(select(2, RPSheet:CompanionGift()) == entry, family .. ": CompanionGift names it")
    entry.loyalty = R.LOYALTY_GIFT - 1
    Same("out but not loyal", Gifts(), {})
    entry.loyalty = R.LOYALTY_GIFT
    -- what follows from the gift is explained
    if family == "Flying" then
        local shown, text = Explained(RPSheet.ExplainSpeed)
        Check(shown == 35 and text:find("flying companion", 1, true), "the flying companion's 5 feet are explained: " .. text)
    elseif family == "Aquatic" then
        local shown, text = Explained(RPSheet.ExplainMoveSpeed, "swim")
        Check(shown == 30 and text:find("Aquatic companion makes it equal to your walking speed", 1, true), "the swimming speed is explained: " .. text)
    elseif family == "Beast" then
        Run("explain Survival", RPSheet.ExplainSkill, RPSheet, Skill("Survival"))
    elseif family == "Mechanical" then
        Check(RPSheet:CompanionWard("fire") == nil and select(2, RPSheet:CompanionWard("psychic")) == entry, "the ward is against psychic damage only")
    elseif family == "Dragonkin" or family == "Elemental" then
        Check((RPSheet:SaveAdvantageText("WIS") or ""):find(family .. " companion", 1, true), family .. ": the save's tooltip names it")
    end
    Run(family .. " lines", UI.MountLines, RPSheet, entry.name, entry)
    FlushTimers()
end
-- a companion of no listed family gives nothing and doesn't break anything
sheet.mounts = {}
local odd = RPSheet:AddMount("Pet Rock")
odd.kind, odd.loyalty, odd.called = "COMPANION", 20, true
Check(RPSheet:CompanionGift() == nil and RPSheet:Companion() == odd, "a companion without a family has no gift")
Run("lines of a companion without a family", UI.MountLines, RPSheet, odd.name, odd)

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
sheet.mounts = {}
local a, b, c, d = RPSheet:AddMount("Riding Horse"), RPSheet:AddMount("Warhorse"), RPSheet:AddMount("Beast companion"), RPSheet:AddMount("Magic companion")
a.riding, b.riding, c.called, d.called = true, true, true, true
c.riding, a.called = true, true
a.kind, b.size, c.family, d.loyalty, a.speed, b.cost, b.capacity = "DRAGON", "XXL", "Robot", 99, -5, "12", 0 / 0
Run("NormalizeMounts", ns.NormalizeMounts, sheet)
Check(a.riding and not b.riding and not c.riding, "one mount ridden at most")
Check(c.called and not d.called and not a.called, "one companion out at most")
Check(a.kind == "MOUNT" and b.size == "L" and c.family == "" and d.loyalty == R.LOYALTY_MAX and a.speed == 0 and b.cost == 12 and b.capacity == 0, "odd values are put right")
sheet.mounts = nil
Check(type(RPSheet:Mounts()) == "table" and RPSheet:Riding() == nil and RPSheet:Companion() == nil and RPSheet:OwnedMount("x") == nil, "an older character without the list")
Run("NormalizeMounts on nothing", ns.NormalizeMounts, sheet)

Done("mounts")
