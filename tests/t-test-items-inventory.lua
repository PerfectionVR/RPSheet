-- The inventory: adding and stacking, buying with and without a faction's discount,
-- selling, using up, dropping, weight and the overloaded speed, attunement, effects
-- that add, set or multiply, and swimming, climbing and flying speeds.
dofile(ARG3 .. "/t-test-items-lib.lua")
local sheet = NewChar("WARRIOR", 1)
local purse = RPSheet:Purse()
local function Gold(gp) purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0 end
local function Count(name)
    local entries, total = 0, 0
    for _, item in ipairs(sheet.items) do
        if item.name == name then entries, total = entries + 1, total + item.qty end
    end
    return entries, total
end
local function Clear()
    for index = #sheet.items, 1, -1 do RPSheet:SetEquipped(sheet.items[index], false); table.remove(sheet.items, index) end
    sheet.armor, sheet.shield = "NONE", false
    for index = #sheet.weapons, 1, -1 do table.remove(sheet.weapons, index) end
end
local function Effect(target, flat, mode) return { target = target, flat = flat, stat = "", times = 1, mode = mode or "" } end
local function Own(name, effects, attune)
    local item = RPSheet:AddItem(name, 1)
    item.magic, item.attune, item.effects = true, attune == true, effects
    return item
end
-- The number an explanation prints, "Speed |cffffd10030 ft|r: ..."
local function Explained(fn, ...)
    local mark = #PRINTED
    Run("explain", fn, RPSheet, ...)
    local text = PrintedSince(mark)
    return tonumber(text:match("|cffffd100(%-?%d+)")), text
end

---------------------------------------------------------------------------
-- Adding and stacking
---------------------------------------------------------------------------
local torch = RPSheet:AddItem("Torch", 3)
Eq(torch.qty, 3, "three torches"); Eq(torch.cost, 1, "torch price"); Eq(torch.weight, 1, "torch weight")
Check(RPSheet:AddItem("Torch") == torch and torch.qty == 4, "plain gear stacks")
RPSheet:AddItem("Torch", 0); Eq(torch.qty, 5, "a quantity of 0 adds one")
RPSheet:AddItem("Torch", 2.7); Eq(torch.qty, 7, "a fraction is floored")
local ring1, ring2 = RPSheet:AddItem("Ring of Protection"), RPSheet:AddItem("Ring of Protection")
Check(ring1 ~= ring2 and Count("Ring of Protection") == 2, "magic items are entries of their own")
Check(ring1.magic and ring1.rarity == "Rare" and ring1.attune and #ring1.effects == 2 and ring1.cost > 0, "a magic item is filled in from the catalogue")
Check(ring1.effects ~= R.ITEMS["Ring of Protection"].effects and ring1.effects[1] ~= R.ITEMS["Ring of Protection"].effects[1], "effects are copies")
local thing = RPSheet:AddItem("Grandmother's Locket")
Check(thing.cost == 0 and thing.weight == 0 and not thing.magic and thing.qty == 1, "an unlisted item is empty")
Check(RPSheet:CarriedItem("Torch") == torch and RPSheet:CarriedItem("Nothing") == nil, "CarriedItem")

---------------------------------------------------------------------------
-- Buying
---------------------------------------------------------------------------
Clear(); Gold(20)
Eq(ns.ItemPrice("Longsword", 1), 1500, "Longsword price")
Eq(ns.ItemPrice("Longsword", 3), 4500, "three longswords")
Check(RPSheet:BuyItem("Longsword") == true and RPSheet:Coins() == 500 and Count("Longsword") == 1, "bought a longsword")
local mark = #PRINTED
Check(RPSheet:BuyItem("Longsword") == false and RPSheet:Coins() == 500 and select(2, Count("Longsword")) == 1, "can't afford a second")
Check(PrintedSince(mark):find("You can't afford 15 gp (Longsword): you have 5 gp.", 1, true), "refusal names the item: " .. PrintedSince(mark))
Gold(1)
mark = #PRINTED
Check(RPSheet:BuyItem("Torch", 5) and select(2, Count("Torch")) == 5 and RPSheet:Coins() == 95, "five torches for 5 cp")
Check(PrintedSince(mark):find("(Torch x5)", 1, true), "the note says how many")

-- No listed price: refused, never free.
local unpriced
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    if R.ITEMS[name].cost == 0 then unpriced = unpriced or name end
end
for _, kind in ipairs(R.ITEM_KINDS) do
    for _, name in ipairs(R.ITEM_NAMES[kind]) do
        local known = R.ITEMS[name]
        Check(type(known.cost) == "number" and known.cost >= 0 and known.cost == math.floor(known.cost), name .. ": price is " .. tostring(known.cost))
        Check(type(known.weight) == "number" and known.weight >= 0, name .. ": weight is " .. tostring(known.weight))
        if known.cost == 0 and known.rarity ~= "Artifact" then Problem(name .. " (" .. kind .. ") has no price") end
    end
end
-- The catalogue prices everything, so one without a price is made up for the test.
R.ITEMS["Priceless Test Relic"] = { kind = "Magic items", cost = 0, weight = 1, rarity = "Artifact", desc = "", effects = {} }
unpriced = unpriced or "Priceless Test Relic"
if Check(unpriced ~= nil, "no item without a price to try") then
    Gold(100)
    mark = #PRINTED
    Check(RPSheet:BuyItem(unpriced) == false and Count(unpriced) == 0 and RPSheet:Coins() == 10000, "an item with no listed price (" .. unpriced .. ") must not be bought for nothing")
    Check(PrintedSince(mark) ~= "", "refusing an unpriced item says why")
    Eq(ns.BuyLabel(RPSheet:ItemBuyPrice(unpriced, 1)), "No price", "label of an unpriced item")
end
Check(RPSheet:BuyItem("No Such Thing") == false and Count("No Such Thing") == 0, "an unlisted item must not be bought for nothing")
R.ITEMS["Priceless Test Relic"] = nil

-- A faction's discount
Clear(); Gold(100000)
Check(#ns.ShopFactions(sheet) == 0 and RPSheet:ShopFaction() == nil, "no discounts to start with")
RPSheet:SetShopFaction("Kirin Tor")
Check(RPSheet:ShopFaction() == nil and RPSheet:ItemBuyPrice("Longsword", 1) == 1500, "a faction below Honored gives nothing")
sheet.renown["Kirin Tor"] = 10
local price, percent, faction = RPSheet:ItemBuyPrice("Longsword", 1)
Check(price == 1350 and percent == 10 and faction == "Kirin Tor", ("Honored: 10%% off, got %s %s %s"):format(tostring(price), tostring(percent), tostring(faction)))
Eq(ns.BuyLabel(price, percent), "Buy  13 gp 5 sp (-10%)", "Buy label with a discount")
Eq(ns.BuyLabel(1500), "Buy  15 gp", "Buy label without")
local function Priced(rarity)
    for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
        if R.ITEMS[name].rarity == rarity and R.ITEMS[name].cost > 0 then return name end
    end
end
local COVERED = { [10] = { Common = true, Uncommon = true }, [25] = { Common = true, Uncommon = true, Rare = true },
    [50] = { Common = true, Uncommon = true, Rare = true, ["Very rare"] = true } }
local PERCENT = { [10] = 10, [25] = 15, [50] = 25 }
for _, score in ipairs({ 10, 25, 50 }) do
    sheet.renown["Kirin Tor"] = score
    for _, rarity in ipairs({ "Common", "Uncommon", "Rare", "Very rare", "Legendary" }) do
        local name = Priced(rarity)
        if Check(name ~= nil, "no priced " .. rarity .. " item") then
            local full = R.ITEMS[name].cost
            local got, off = RPSheet:ItemBuyPrice(name, 1)
            if COVERED[score][rarity] then
                Check(got == math.floor(full * (100 - PERCENT[score]) / 100 + 0.5) and off == PERCENT[score], ("renown %d, %s %s: %s"):format(score, rarity, name, tostring(got)))
            else
                Check(got == full and off == nil, ("renown %d should not cover %s (%s)"):format(score, rarity, name))
            end
        end
    end
    Eq(RPSheet:ItemBuyPrice("Longsword", 2), math.floor(3000 * (100 - PERCENT[score]) / 100 + 0.5), "two longswords at renown " .. score)
end
sheet.renown["Kirin Tor"] = 10
local component = R.ITEM_NAMES["Spell components"][1]
Check(select(2, RPSheet:ItemBuyPrice(component, 1)) == nil and RPSheet:ItemBuyPrice(component, 1) == R.ITEMS[component].cost, "a spell component keeps its price")
Check(R.ITEMS.Fuel ~= nil and select(2, RPSheet:ItemBuyPrice("Fuel", 1)) == nil, "fuel keeps its price")
local cheap, cheapOff = RPSheet:ItemBuyPrice("Torch", 1)
Check(cheap == 1 and cheapOff == nil, "a torch at 1 cp has nothing to take off, and no discount is claimed")
Eq(RPSheet:ItemBuyPrice("Torch", 10), 9, "ten torches do")
Gold(20)
mark = #PRINTED
Check(RPSheet:BuyItem("Longsword") and RPSheet:Coins() == 650, "bought at the discount")
Check(PrintedSince(mark):find("(Longsword, 10% off with Kirin Tor)", 1, true), "the note names the discount: " .. PrintedSince(mark))
RPSheet:SetShopFaction(nil)
Eq(RPSheet:ItemBuyPrice("Longsword", 1), 1500, "nobody in particular: full price")
sheet.renown["Kirin Tor"] = nil

---------------------------------------------------------------------------
-- Using up and dropping
---------------------------------------------------------------------------
Clear()
torch = RPSheet:AddItem("Torch", 2)
local sent = #SENT
RPSheet:UseItem(torch)
Check(torch.qty == 1 and SentSince(sent):find("uses [Torch]", 1, true), "using a torch: " .. SentSince(sent))
RPSheet:UseItem(torch)
Check(Count("Torch") == 0, "the last one takes the entry off the list")
RPSheet:UseItem(torch)
Eq(torch.qty, 0, "using nothing does nothing")
local suit = RPSheet:AddItem("Leather Armor", 1)
RPSheet:SetEquipped(suit, true)
Eq(sheet.armor, "LEATHER", "leather on")
RPSheet:UseItem(suit)
Check(sheet.armor == "NONE" and #sheet.items == 0, "used-up armor comes off")
suit = RPSheet:AddItem("Leather Armor", 2)
RPSheet:SetEquipped(suit, true)
RPSheet:DropItem(suit)
Check(suit.qty == 1 and sheet.armor == "LEATHER", "dropping one of two keeps it on")
RPSheet:DropItem(suit)
Check(sheet.armor == "NONE" and #sheet.items == 0, "dropping the last takes the armor off")
local shield = RPSheet:AddItem("Shield", 1)
RPSheet:SetEquipped(shield, true)
RPSheet:DropItem(shield)
Check(sheet.shield == false, "a dropped shield is lowered")
local sword = RPSheet:AddItem("Longsword", 1)
RPSheet:SetEquipped(sword, true)
Eq(#ns.ReadyWeapons(sheet), 1, "longsword readied")
RPSheet:DropItem(sword)
Eq(#ns.ReadyWeapons(sheet), 0, "a dropped weapon is put away")

-- the sheet's own click: equip or put away
sword = RPSheet:AddItem("Longsword", 1)
Run("ToggleEquipped", RPSheet.ToggleEquipped, RPSheet, sword); FlushTimers()
Check(sword.equipped and #ns.ReadyWeapons(sheet) == 1, "a click on the sheet equips")
Run("ToggleEquipped", RPSheet.ToggleEquipped, RPSheet, sword); FlushTimers()
Check(not sword.equipped and #ns.ReadyWeapons(sheet) == 0, "and a second puts away")

---------------------------------------------------------------------------
-- Weight
---------------------------------------------------------------------------
Clear(); Gold(0)
Eq(RPSheet:CarryCapacity(), 225, "Strength 15, Medium: 225 lb.")
sheet.size = "L"; Eq(RPSheet:CarryCapacity(), 450, "Large carries double")
sheet.size = "S"; Eq(RPSheet:CarryCapacity(), 225, "Small carries the same")
sheet.size = nil; Eq(RPSheet:CarryCapacity(), 225, "no size counts as Medium")
sheet.size = "M"
Eq(RPSheet:CarriedWeight(), 0, "nothing carried")
local plate = RPSheet:AddItem("Plate Armor", 3)
Eq(RPSheet:CarriedWeight(), 195, "three suits of plate")
Check(not RPSheet:Overloaded() and RPSheet:Speed() == 30, "under the limit")
purse.cp = 1500 -- 30 lb. of copper: exactly 225
Check(RPSheet:CarriedWeight() == 225 and not RPSheet:Overloaded(), "exactly at the limit is fine")
purse.cp = 1550
Check(RPSheet:Overloaded() and RPSheet:Speed() == R.OVERLOADED_SPEED, "over the limit: speed 5")
local shown, text = Explained(RPSheet.ExplainSpeed)
Check(shown == 5 and text:find("226.0 lb.", 1, true) and text:find("225 lb.", 1, true), "the explanation says so: " .. text)
purse.cp = 0
plate.qty = 4
Check(RPSheet:Overloaded(), "four suits are too many")
-- An item that sets Strength raises what can be carried.
local gauntlets = RPSheet:AddItem("Gauntlets of Ogre Power")
gauntlets.equipped, gauntlets.attuned = true, true
Eq(RPSheet:Score("STR"), 19, "gauntlets set Strength to 19")
Check(RPSheet:CarryCapacity() == 285 and not RPSheet:Overloaded(), "and the capacity follows")
gauntlets.attuned = false
Check(RPSheet:Score("STR") == 15 and RPSheet:Overloaded(), "not attuned: back to 15")

---------------------------------------------------------------------------
-- Attunement
---------------------------------------------------------------------------
Clear()
local attuneNames = { "Ring of Protection", "Cloak of Protection", "Gauntlets of Ogre Power", "Headband of Intellect" }
local magic = {}
for index, name in ipairs(attuneNames) do magic[index] = RPSheet:AddItem(name) end
for index = 1, 3 do RPSheet:ToggleAttuned(magic[index]) end
Eq(#RPSheet:AttunedItems(), 3, "attuned to three")
mark = #PRINTED
RPSheet:ToggleAttuned(magic[4])
Check(not magic[4].attuned and #RPSheet:AttunedItems() == 3 and PrintedSince(mark):find("already attuned to 3 items"), "a fourth is refused")
RPSheet:ToggleAttuned(magic[1])
Check(not magic[1].attuned, "ending an attunement")
RPSheet:ToggleAttuned(magic[4])
Check(magic[4].attuned and #RPSheet:AttunedItems() == 3, "and then the fourth")
torch = RPSheet:AddItem("Torch")
RPSheet:ToggleAttuned(torch)
Check(not torch.attuned, "an item that asks no attunement can't be attuned")
FlushTimers()

---------------------------------------------------------------------------
-- Effects that add: only while equipped and attuned
---------------------------------------------------------------------------
Clear()
local baseAC, baseSave = RPSheet:AC(), RPSheet:SaveMod("WIS")
local cloak = RPSheet:AddItem("Cloak of Protection")
for _, case in ipairs({ { false, false, 0 }, { true, false, 0 }, { false, true, 0 }, { true, true, 1 } }) do
    cloak.equipped, cloak.attuned = case[1], case[2]
    local label = ("cloak equipped %s attuned %s"):format(tostring(case[1]), tostring(case[2]))
    Eq(RPSheet:AC(), baseAC + case[3], label .. ": AC")
    Eq(RPSheet:SaveMod("WIS"), baseSave + case[3], label .. ": saves")
    Eq(RPSheet:ItemBonus("AC"), case[3], label .. ": ItemBonus")
    Eq(Explained(RPSheet.ExplainAC), baseAC + case[3], label .. ": explained AC")
    local active, why = RPSheet:ItemActive(cloak)
    Check(active == (case[3] == 1) and (active or why == (case[1] and "not attuned" or "not equipped")), label .. ": ItemActive says " .. tostring(why))
end
local second = RPSheet:AddItem("Ring of Protection")
second.equipped, second.attuned = true, true
Eq(RPSheet:AC(), baseAC + 2, "cloak and ring add up")
-- Bracers: only without armor and shield
Clear()
local bracers = RPSheet:AddItem("Bracers of Defense")
bracers.equipped, bracers.attuned = true, true
Eq(bracers.limit, "UNARMORED", "bracers carry their limit")
Eq(RPSheet:AC(), baseAC + 2, "bracers unarmored")
suit = RPSheet:AddItem("Leather Armor")
RPSheet:SetEquipped(suit, true)
Eq(RPSheet:AC(), 11 + 2, "bracers stop in armor")
Eq(select(2, RPSheet:ItemActive(bracers)), "you have armor on", "and say why")
RPSheet:SetEquipped(suit, false)
shield = RPSheet:AddItem("Shield")
RPSheet:SetEquipped(shield, true)
Eq(RPSheet:AC(), baseAC + 2, "bracers stop behind a shield")
Eq(select(2, RPSheet:ItemActive(bracers)), "you have a shield on", "and say why")
-- A nameless item never counts
Clear()
local blank = Own("", { Effect("AC", 5) })
blank.equipped = true
Eq(RPSheet:AC(), baseAC, "a nameless item counts for nothing")

---------------------------------------------------------------------------
-- Effects that set or multiply
---------------------------------------------------------------------------
Clear()
local belt = RPSheet:AddItem("Belt of Hill Giant Strength")
belt.equipped, belt.attuned = true, true
Eq(RPSheet:Score("STR"), 21, "belt sets Strength to 21")
Eq(RPSheet:Mod("STR"), 5, "and the modifier follows")
local from, floor = RPSheet:ScoreSetBy("STR")
Check(from == "Belt of Hill Giant Strength" and floor == 21, "ScoreSetBy names the belt")
gauntlets = RPSheet:AddItem("Gauntlets of Ogre Power")
gauntlets.equipped, gauntlets.attuned = true, true
Eq(RPSheet:Score("STR"), 21, "of two, the higher counts")
sheet.base.STR = 22
Check(RPSheet:Score("STR") == 22 and RPSheet:ScoreSetBy("STR") == nil, "an own score that is higher stays")
sheet.base.STR = 15
belt.equipped = false
Eq(RPSheet:Score("STR"), 19, "belt off: the gauntlets' 19")
Eq(RPSheet:Score("DEX"), 14, "other scores untouched")
local headband = RPSheet:AddItem("Headband of Intellect")
headband.equipped, headband.attuned = true, true
Eq(RPSheet:Score("INT"), 19, "headband sets Intelligence")
-- every catalogue item that sets a score does so
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    for _, effect in ipairs(R.ITEMS[name].effects or {}) do
        if ns.IsScoreTarget(effect.target) then
            Clear()
            local item = RPSheet:AddItem(name)
            item.equipped, item.attuned = true, true
            local stat = effect.target:sub(7)
            Eq(RPSheet:Score(stat), math.max(effect.flat, sheet.base[stat] + (sheet.bonus[stat] or 0)), name .. " sets " .. stat)
        end
    end
end

-- Speed
Clear()
Eq(RPSheet:Speed(), 30, "speed 30")
local boots = RPSheet:AddItem("Boots of Striding and Springing")
boots.equipped, boots.attuned = true, true
Eq(RPSheet:Speed(), 30, "boots that set 30 change nothing at 30")
local runners = Own("Runner's Sandals", { Effect("SPEED", 40, "MIN") })
runners.equipped = true
Eq(RPSheet:Speed(), 40, "an item sets the speed to 40")
Eq(Explained(RPSheet.ExplainSpeed), 40, "explained")
local plus = Own("Lucky Laces", { Effect("SPEED", 10) })
plus.equipped = true
Eq(RPSheet:Speed(), 50, "what adds is added to the set speed")
local double = Own("Hasty Greaves", { Effect("SPEED", 2, "TIMES") })
double.equipped = true
Eq(RPSheet:Speed(), 100, "and the outcome is doubled")
shown, text = Explained(RPSheet.ExplainSpeed)
Check(shown == 100 and text:find("Runner's Sandals") and text:find("Hasty Greaves") and text:find("Lucky Laces"), "the explanation adds up to 100: " .. text)
local triple = Own("Hastier Greaves", { Effect("SPEED", 3, "TIMES") })
triple.equipped = true
Eq(RPSheet:Speed(), 150, "multipliers don't pile up: the largest counts")
Eq(Explained(RPSheet.ExplainSpeed), 150, "explained")
local silly = Own("Typo Greaves", { Effect("SPEED", 500, "TIMES") })
silly.equipped = true
Eq(RPSheet:Speed(), 50 * R.MAX_MULTIPLIER, "a multiplier is held to the limit")
silly.equipped, triple.equipped = false, false
RPSheet:State().conditions.Grappled = true
Check(RPSheet:Speed() == 0 and Explained(RPSheet.ExplainSpeed) == 0, "grappled: 0")
RPSheet:State().conditions.Grappled = nil
plate = RPSheet:AddItem("Plate Armor", 5)
Check(RPSheet:Overloaded() and RPSheet:Speed() == 5 and Explained(RPSheet.ExplainSpeed) == 5, "overloaded holds even a doubled speed to 5")
RPSheet:DropItem(plate); plate.qty = 1; RPSheet:DropItem(plate)
-- heavy armor without the Strength costs 10 feet; the multiplier comes after
Clear()
sheet.base.STR = 10
plate = RPSheet:AddItem("Plate Armor")
RPSheet:SetEquipped(plate, true)
Eq(RPSheet:Speed(), 20, "plate without Strength 15: speed 20")
Eq(Explained(RPSheet.ExplainSpeed), 20, "explained")
double = Own("Hasty Greaves", { Effect("SPEED", 2, "TIMES") })
double.equipped = true
Eq(RPSheet:Speed(), 40, "doubled after the armor's 10 feet")
Eq(Explained(RPSheet.ExplainSpeed), 40, "explained")
sheet.base.STR = 15

-- EffectText of every catalogue effect
for _, kind in ipairs(R.ITEM_KINDS) do
    for _, name in ipairs(R.ITEM_NAMES[kind]) do
        for _, effect in ipairs(R.ITEMS[name].effects or {}) do
            local words = Run(name .. " effect text", RPSheet.EffectText, RPSheet, effect)
            Check(type(words) == "string" and words ~= "", name .. ": effect text is " .. tostring(words))
            Check(R.EFFECT_TARGETS[effect.target] ~= nil, name .. ": unknown effect target " .. tostring(effect.target))
            Check(R.EFFECT_MODES[effect.mode or ""] ~= nil, name .. ": unknown effect mode " .. tostring(effect.mode))
            if (effect.mode or "") ~= "" then Check(ns.EffectMode(effect) == effect.mode, name .. ": mode " .. effect.mode .. " doesn't go with " .. effect.target) end
        end
    end
end

---------------------------------------------------------------------------
-- Swimming, climbing, flying
---------------------------------------------------------------------------
Clear()
for _, kind in ipairs(R.MOVE_KINDS) do
    Eq(RPSheet:MoveSpeed(kind), nil, "no " .. kind .. " speed to start with")
    mark = #PRINTED
    Run("explain no " .. kind, RPSheet.ExplainMoveSpeed, RPSheet, kind)
    Check(PrintedSince(mark):find("You have no " .. R.MOVE_NOUNS[kind] .. " speed."), "says there is none")
end
local swimRing = RPSheet:AddItem("Ring of Swimming")
Eq(RPSheet:MoveSpeed("swim"), nil, "ring not worn")
swimRing.equipped = true
Eq(RPSheet:MoveSpeed("swim"), 40, "ring of swimming: 40")
shown, text = Explained(RPSheet.ExplainMoveSpeed, "swim")
Check(shown == 40 and text:find("Ring of Swimming gives 40 ft"), "explained: " .. text)
local manta = RPSheet:AddItem("Cloak of the Manta Ray")
manta.equipped = true
Eq(RPSheet:MoveSpeed("swim"), 40, "manta cloak not attuned")
manta.attuned = true
Eq(RPSheet:MoveSpeed("swim"), 60, "manta cloak: 60, the higher")
local fins = Own("Fins", { Effect("SWIM", 10) })
fins.equipped = true
Eq(RPSheet:MoveSpeed("swim"), 70, "an effect that adds to swimming")
Eq(Explained(RPSheet.ExplainMoveSpeed, "swim"), 70, "explained")
Eq(RPSheet:MoveSpeed("climb"), nil, "still no climbing")
local slippers = RPSheet:AddItem("Slippers of Spider Climbing")
slippers.equipped, slippers.attuned = true, true
Eq(RPSheet:MoveSpeed("climb"), 30, "slippers: climbing at walking speed")
shown, text = Explained(RPSheet.ExplainMoveSpeed, "climb")
Check(shown == 30 and text:find("equal to your walking speed, 30 ft"), "explained: " .. text)
plus = Own("Lucky Laces", { Effect("SPEED", 10) })
plus.equipped = true
Eq(RPSheet:MoveSpeed("climb"), 40, "and it follows the walking speed")
local claws = Own("Climbing Claws", { Effect("CLIMB", 20, "MIN") })
claws.equipped = true
Eq(RPSheet:MoveSpeed("climb"), 40, "a lower set speed loses to the walking speed")
claws.effects[1].flat = 55
Eq(RPSheet:MoveSpeed("climb"), 55, "a higher one wins")
local wings = Own("Paper Wings", { Effect("FLY", 0, "WALK") })
wings.equipped = true
Eq(RPSheet:MoveSpeed("fly"), 40, "flying at walking speed")
Check(RPSheet:EffectText(wings.effects[1]):find("equal to your walking speed"), "its effect text says so")
RPSheet:State().conditions.Restrained = true
for _, kind in ipairs(R.MOVE_KINDS) do
    Check(RPSheet:MoveSpeed(kind) == 0 and Explained(RPSheet.ExplainMoveSpeed, kind) == 0, kind .. " is 0 while restrained")
end
RPSheet:State().conditions.Restrained = nil
-- a feat or feature by name
Clear()
for name, grant in pairs(R.MOVE_GRANTS) do
    local passive = CopyTable(R.TEMPLATES.passive)
    passive.name, passive.enabled = name, true
    sheet.passives[#sheet.passives + 1] = passive
    for _, kind in ipairs(R.MOVE_KINDS) do
        Eq(RPSheet:MoveSpeed(kind), grant[kind] and 30 or nil, name .. " " .. kind)
        Run(name .. " explain " .. kind, RPSheet.ExplainMoveSpeed, RPSheet, kind)
    end
    passive.enabled = false
    Eq(RPSheet:MoveSpeed("swim"), nil, name .. " switched off")
    table.remove(sheet.passives)
end
-- a loyal aquatic companion
local fish = RPSheet:AddMount("Aquatic Companion")
if fish.kind ~= "COMPANION" then fish.kind, fish.family = "COMPANION", "Aquatic" end
fish.family, fish.loyalty, fish.called = "Aquatic", R.LOYALTY_GIFT, true
Eq(RPSheet:MoveSpeed("swim"), 30, "a loyal aquatic companion gives a swimming speed")
shown, text = Explained(RPSheet.ExplainMoveSpeed, "swim")
Check(shown == 30 and text:find(fish.name, 1, true), "explained: " .. text)
fish.loyalty = R.LOYALTY_GIFT - 1
Eq(RPSheet:MoveSpeed("swim"), nil, "not loyal enough: none")
RPSheet:RemoveMount(fish)

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
Clear()
local odd = RPSheet:AddItem("Odd Thing")
odd.weight, odd.qty, odd.cost, odd.rarity, odd.limit, odd.base, odd.bonus, odd.variant, odd.scribed = "2.5", -3, 1e12, "Shiny", "NEVER", "Banana", 9, "gold", 1
odd.effects = { Effect("AC", 1), Effect("NOPE", 1), { target = "SPEED", flat = 2, stat = "", times = 1, mode = "ODD" } }
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(odd.weight == 2.5 and odd.qty == 0 and odd.cost == 99999999 and odd.rarity == "" and odd.limit == "" and odd.base == "" and odd.bonus == 3
    and odd.variant == "" and odd.scribed == false, "odd values are put right")
Check(#odd.effects == 2 and odd.effects[2].mode == "", "an unknown target goes, an unknown mode adds")

---------------------------------------------------------------------------
-- Selling and deleting on the Customize page
---------------------------------------------------------------------------
Clear(); Gold(0)
sword = RPSheet:AddItem("Longsword", 2)
ns.RebuildOptions()
local options = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
local pages = options.args.customize.args.items.args
local page = pages.item1
if Check(page ~= nil and page.args.sell ~= nil, "the item has a page with Sell one") then
    Run("sell one", page.args.sell.func, { "sell", option = page.args.sell })
    Check(sword.qty == 1 and RPSheet:Coins() == 750, "selling gives back half")
    Check(type(page.args.sell.desc()) == "string" and page.args.sell.hidden() == false, "sell button reads well")
end
Done("inventory")
