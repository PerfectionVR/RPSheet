-- The item browser's Makes tab (buying a magic make, with a faction's discount), its
-- Sell button, and its search: by description and kind words, over one tab and over
-- every tab of a source at once, with the pages that go with it.
dofile(ARG3 .. "/t-test-items-lib.lua")
local UI = ns.UI
local Search, Pages = UI.ItemSearch, UI.ItemPages

-- Capture what a source adds instead of making widgets.
local BUTTONS = {}
UI.AddItemButton = function(_, width, text, enabled, onClick)
    BUTTONS[#BUTTONS + 1] = { text = text, enabled = enabled and true or false, click = onClick, width = width }
end
-- The sources are local to their files: catch them as they are shown.
local RealShow = RPSheet.ShowItemBrowser
local caught
RPSheet.ShowItemBrowser = function(_, wanted) caught = wanted end
local function Source(open, ...)
    caught = nil
    Run("open a browser", open, ...)
    return caught
end
local function Card(source, entry, first)
    BUTTONS = {}
    Run(entry.name .. " buttons", source.buttons, RPSheet, {}, entry, first)
    local byText, widths = {}, 0
    for _, button in ipairs(BUTTONS) do byText[button.text] = button; widths = widths + button.width end
    return byText, BUTTONS, widths
end
local function Click(button, label)
    if not Check(button ~= nil, label .. ": no such button") then return end
    Run(label, button.click)
    FlushTimers()
end
local function Named(entries, name)
    for _, entry in ipairs(entries) do
        if entry.name == name then return entry end
    end
end
local function Names(entries)
    local names = {}
    for _, entry in ipairs(entries) do names[entry.name] = (names[entry.name] or 0) + 1 end
    return names
end
local function TabNamed(source, name)
    for _, tab in ipairs(Search.Tabs(RPSheet, source)) do
        if tab.name == name then return tab end
    end
end

local sheet = NewChar("WARRIOR", 5)
local purse = RPSheet:Purse()
local function Gold(gp) purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0 end
local SHEET = Source(RPSheet.ToggleItemBrowser, RPSheet)

---------------------------------------------------------------------------
-- The Makes tab
---------------------------------------------------------------------------
local makesTab = TabNamed(SHEET, "Makes")
local makes = Search.TabEntries(RPSheet, SHEET, makesTab)
local count = 0
for _, key in ipairs(R.ITEM_VARIANTS) do count = count + #ns.VariantBases(R.ITEM_VARIANT[key]) end
Eq(#makes, count, "one block for every make of every plain item")
Check(#makes > 1000, "and there are many: " .. #makes)
local seen = {}
for _, entry in ipairs(makes) do
    Check(not seen[entry.name], entry.name .. " is listed twice")
    seen[entry.name] = true
    Check(entry.variant and R.VariantFits(entry.variant, entry.base) and entry.item == nil, entry.name .. ": make, plain item, nothing carried")
end
-- a block: what a new one would be, and Add, Buy, Remove
local tongue = Named(makes, "Flame Tongue Longsword")
if Check(tongue ~= nil, "a Flame Tongue Longsword is listed") then
    local text = table.concat(Run("lines", SHEET.lines, RPSheet, tongue), "\n")
    Check(text:find("Counts as: Longsword", 1, true) and text:find("Magic item, rare, requires attunement", 1, true) and text:find("2d6 more fire damage", 1, true)
        and text:find("4015 gp", 1, true), "its block: " .. text)
    Gold(0)
    local buttons, list, widths = Card(SHEET, tongue, false)
    Check(#list == 3 and list[1].text == "Add" and list[2].text == "Buy  4015 gp" and list[3].text == "Remove", "Add, Buy with the price, Remove")
    Check(widths <= 1.0001, "the buttons fit a row")
    Check(buttons.Add.enabled and not buttons["Buy  4015 gp"].enabled and not buttons.Remove.enabled, "poor: only Add is on")
    Click(buttons["Buy  4015 gp"], "Buy without the money")
    Eq(#sheet.items, 0, "nothing bought without the money")
    Gold(5000)
    buttons = Card(SHEET, tongue, false)
    Check(buttons["Buy  4015 gp"].enabled, "rich: Buy is on")
    Click(buttons["Buy  4015 gp"], "Buy")
    Check(#sheet.items == 1 and sheet.items[1].name == "Flame Tongue Longsword" and sheet.items[1].variant == "Flame Tongue" and RPSheet:Coins() == 98500,
        "Buy paid 4015 gp and added it")
    -- now it is carried: the block describes that one, and Remove is on
    tongue = Named(Search.TabEntries(RPSheet, SHEET, makesTab), "Flame Tongue Longsword")
    Check(tongue.item == sheet.items[1] and table.concat(SHEET.marks(RPSheet, tongue), ", ") == "you have 1, not attuned", "the carried one is found")
    buttons = Card(SHEET, tongue, false)
    Click(buttons.Add, "Add another")
    Check(#sheet.items == 2 and RPSheet:Coins() == 98500, "Add adds one for nothing, an entry of its own")
    Click(buttons.Remove, "Remove")
    Eq(#sheet.items, 1, "Remove takes the carried one")
end
-- a faction's discount reaches the makes, up to the rarity the standing covers
sheet.renown["Kirin Tor"] = 10 -- Honored: 10% off, up to uncommon
RPSheet:SetShopFaction("Kirin Tor")
Gold(100000)
local function Price(key, base) return (RPSheet:VariantBuyPrice(key, base)) end
Eq(Price("weapon1", "Longsword"), math.floor((40000 + 1500) * 0.9 + 0.5), "uncommon +1 longsword: 10% off")
Eq(select(2, RPSheet:VariantBuyPrice("weapon1", "Longsword")), 10, "and says the percent")
Eq(Price("Flame Tongue", "Longsword"), 401500, "a rare make is beyond Honored")
Eq(Price("mithral", "Chain Mail"), math.floor((40000 + 7500) * 0.9 + 0.5), "mithral chain mail: 10% off")
Eq(Price("ammo1", "Arrow"), math.floor((20000 + 5) * 0.9 + 0.5), "a +1 arrow: half an uncommon item's worth, 10% off")
Eq(Price("mithral", "Leather Armor"), 0, "what doesn't go together has no price")
local plus = Named(makes, "Longsword +1")
local label = "Buy  373 gp 5 sp (-10%)"
local buttons = Card(SHEET, plus, false)
if Check(buttons[label] and buttons[label].enabled, "the Buy button shows the discounted price") then
    local before, mark = RPSheet:Coins(), #PRINTED
    Click(buttons[label], "Buy at a discount")
    Eq(before - RPSheet:Coins(), 37350, "and that is what is paid")
    Check(PrintedSince(mark):find("10% off with Kirin Tor", 1, true), "the note says whose discount: " .. PrintedSince(mark))
    Check(RPSheet:CarriedItem("Longsword +1") and RPSheet:CarriedItem("Longsword +1").cost == 41500, "the item keeps its full worth")
end
sheet.renown["Kirin Tor"] = 50 -- Exalted: 25% off, up to very rare
Eq(Price("Flame Tongue", "Longsword"), math.floor(401500 * 0.75 + 0.5), "Exalted: a rare make at 25% off")
Eq(Price("armor3", "Plate Armor"), 20000000 + 150000, "a legendary one never")
RPSheet:SetShopFaction(nil)
sheet.renown["Kirin Tor"] = nil
-- magic ammunition bought twice is one entry of two
for index = #sheet.items, 1, -1 do table.remove(sheet.items, index) end
Gold(100000)
Check(RPSheet:BuyVariantItem("ammo1", "Arrow") and RPSheet:BuyVariantItem("ammo1", "Arrow"), "two +1 arrows bought")
Check(#sheet.items == 1 and sheet.items[1].qty == 2 and sheet.items[1].name == "Arrow +1", "one entry of two")

---------------------------------------------------------------------------
-- Selling from the Carried tab
---------------------------------------------------------------------------
for index = #sheet.items, 1, -1 do table.remove(sheet.items, index) end
Gold(0)
local sword, potion = RPSheet:AddItem("Longsword", 2), RPSheet:AddItem("Potion of Healing", 3)
local ring, gem = RPSheet:AddItem("Ring of Protection"), RPSheet:AddItem("Diamond (50 gp)")
local candle = RPSheet:AddItem("Candle")
local own = SHEET.own(RPSheet)
Eq(#own, 5, "five entries carried")
local list, widths
buttons, list, widths = Card(SHEET, own[1], true)
Check(#list == 4 and list[1].text == "Equip" and list[2].text == "Add one" and list[3].text == "Sell  7 gp 5 sp" and list[4].text == "Remove",
    "a carried item: Equip, Add one, Sell, Remove")
Eq(widths, 2, "two rows of two")
Eq(ns.SellPrice(sword), 750, "a longsword sells for half")
Click(list[3], "Sell a longsword")
Check(sword.qty == 1 and RPSheet:Coins() == 750, "one sold, 7 gp 5 sp gained")
Click(list[3], "Sell the other")
Check(#sheet.items == 4 and RPSheet:Coins() == 1500, "the last one takes the entry with it")
Click(list[3], "Sell a third")
Check(RPSheet:Coins() == 1500, "a stale Sell button sells nothing")
-- a magic item: half its price too
Eq(ns.SellPrice(ring), R.ITEMS["Ring of Protection"].cost / 2, "a magic ring sells for half")
Eq(ns.SellPrice(potion), 2500, "a potion of healing for 25 gp")
-- a gem keeps its worth
if Check(gem.cost == 5000, "the diamond is worth 50 gp: " .. tostring(gem.cost)) then
    local price, full = ns.SellPrice(gem)
    Check(price == 5000 and full == true, "a gem sells for its full worth")
    Eq(ns.SellLabel(gem), "Sell  50 gp", "and the button says so")
end
-- a relic an archaeologist assembled
local relic = RPSheet:AddItem("Relic (50 gp)")
relic.cost = 5000
Eq(ns.SellPrice(relic), 5000, "a relic sells for its full worth")
-- too cheap to halve, and no price at all
Eq(candle.cost, 1, "a candle costs a copper")
buttons, list = Card(SHEET, Named(SHEET.own(RPSheet), "Candle"), true)
Check(list[3].text == "No resale" and not list[3].enabled, "a candle has no resale")
Check(not RPSheet:SellItem(candle) and candle.qty == 1, "and selling it does nothing")
local own1 = RPSheet:AddItem("Grandmother's Locket")
Check(ns.SellPrice(own1) == 0 and ns.SellLabel(own1) == "No resale", "an item without a price has no resale")
Check(SHEET.standing(RPSheet):find("sells for half its price", 1, true), "the standing line says what selling gives")
-- the Customize page sells the same way
ns.RebuildOptions()
local REGISTRY = LibStub("AceConfigRegistry-3.0")
local options = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
local function Page(item)
    for key, page in pairs(options.args.customize.args.items.args) do
        if type(page) == "table" and page.type == "group" and page.args and page.args.sell then
            local info = { "customize", "items", key, "name", option = page.args.name }
            if page.args.name.get(info) == item.name then return page.args end
        end
    end
end
local page = Page(ring)
if Check(page ~= nil, "the ring has a page under Customize") then
    local before = RPSheet:Coins()
    Check(page.sell.desc():find("half its price", 1, true) and page.sell.desc():find(ns.CoinText(ns.SellPrice(ring)), 1, true), "Sell one says what it gives: " .. page.sell.desc())
    Check(page.sell.disabled() == false, "Sell one is on")
    Run("Sell one", page.sell.func, { "sell", option = page.sell })
    Eq(RPSheet:Coins() - before, R.ITEMS["Ring of Protection"].cost / 2, "Sell one gives half")
    Check(RPSheet:CarriedItem("Ring of Protection") == nil, "and the ring is gone")
end
page = Page(gem)
if Check(page ~= nil, "the diamond has a page") then
    Check(page.sell.desc():find("its full worth: 50 gp", 1, true), "a gem's Sell one says full worth: " .. page.sell.desc())
end
page = Page(candle)
if Check(page ~= nil, "the candle has a page") then Check(page.sell.disabled() == true, "a candle's Sell one is off") end
-- mounts: no resale is offered, and the stable says so
local STABLE = Source(RPSheet.ToggleMountBrowser, RPSheet)
local horse = RPSheet:AddMount("Riding Horse")
buttons, list = Card(STABLE, { name = horse.name, item = horse }, true)
for _, button in ipairs(list) do Check(not button.text:find("Sell"), "the stable offers a sale: " .. button.text) end
Check(STABLE.standing(RPSheet):find("No rule names a price for selling a mount", 1, true), "the stable says why there is no Sell")

---------------------------------------------------------------------------
-- The search
---------------------------------------------------------------------------
for index = #sheet.items, 1, -1 do table.remove(sheet.items, index) end
local magicTab, weaponsTab, armorTab = TabNamed(SHEET, "Magic"), TabNamed(SHEET, "Weapons"), TabNamed(SHEET, "Armor")
local function Find(tab, search, everywhere) return Search.Find(RPSheet, SHEET, tab, search, everywhere) end
-- a name still finds
local found = Names(Find(magicTab, "ring of protection"))
Check(found["Ring of Protection"] == 1, "a name finds its item")
-- a word of the description
found = Names(Find(magicTab, "healing"))
Check(found["Potion of Healing"] and found["Keoghtom's Ointment"] == nil or found["Potion of Healing"], "healing finds the potion")
local byText = 0
for name in pairs(found) do
    if not name:lower():find("healing", 1, true) then byText = byText + 1 end
end
Check(byText > 0, "healing also finds items that only say it in their description")
found = Names(Find(magicTab, "fire"))
Check(found["Flame Tongue"] and found["Efreeti Chain"] and found["Necklace of Fireballs"], "fire finds by description and by name")
-- kind words: attunement, rarity
local attuned = Find(magicTab, "attunement")
local wanted = 0
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    if R.ITEMS[name].attune then wanted = wanted + 1 end
end
Check(#attuned >= wanted and #attuned < #R.ITEM_NAMES["Magic items"], ("attunement finds the %d items that need it: %d"):format(wanted, #attuned))
for _, entry in ipairs(Find(magicTab, "legendary attunement")) do
    local item = R.ITEMS[entry.name]
    Check((item.rarity == "Legendary" or item.desc:lower():find("legendary")) and (item.attune or item.desc:lower():find("attunement")), entry.name .. ": found by 'legendary attunement'")
end
Check(#Find(magicTab, "legendary attunement") > 5, "several words must all be found")
-- weapons: properties, category, mastery
found = Names(Find(weaponsTab, "finesse"))
Check(found.Rapier and found.Dagger and found.Shortsword and not found.Longsword and not found.Maul, "finesse finds the finesse weapons")
found = Names(Find(weaponsTab, "martial"))
Check(found.Longsword and found.Longbow and not found.Dagger and not found.Club and not found["Arrows (20)"], "martial finds the martial weapons")
found = Names(Find(weaponsTab, "simple"))
Check(found.Dagger and found.Club and not found.Longsword, "simple the simple ones")
found = Names(Find(weaponsTab, "vex"))
Check(found.Rapier and found.Shortsword and not found.Longsword, "a mastery finds its weapons")
found = Names(Find(armorTab, "heavy"))
Check(found["Plate Armor"] and found["Chain Mail"] and not found["Leather Armor"] and not found.Shield, "heavy finds the heavy armor")
-- nothing
Eq(#Find(magicTab, "xyzzy"), 0, "nonsense finds nothing")
Eq(#Find(magicTab, ""), #R.ITEM_NAMES["Magic items"], "an empty search shows the whole tab")
-- the search is over small letters, as the box hands it over, and ignores colours
Check(#Find(weaponsTab, "not proficient") == 0, "what the block says about this character is not searched")
-- makes
found = Names(Find(makesTab, "flame tongue"))
Check(found["Flame Tongue Longsword"] and found["Flame Tongue Club"] and not found["Flame Tongue Longbow"], "a make is found by its name")
found = Names(Find(makesTab, "mithral"))
Check(found["Mithral Chain Mail"] and not found["Mithral Leather Armor"], "mithral finds its suits")
found = Names(Find(makesTab, "resist poison"))
Check(found["Armor of Poison Resistance (Plate)"], "a make is found by what it does")
found = Names(Find(makesTab, "finesse legendary"))
Check(found["Vorpal Scimitar"] and not found["Vorpal Greatsword"], "and by its plain weapon's properties with its rarity")

-- every tab at once
local everything = Find(SHEET.first, "", true)
local total = #makes
for _, tab in ipairs(SHEET.kinds) do
    if not tab.makes then total = total + #R.ITEM_NAMES[tab.kind] end
end
Eq(#everything, total, "everything: every listed item and every make (nothing is carried)")
for _, entry in ipairs(everything) do
    if not Check(entry.fromTab ~= nil and entry.fromTab ~= SHEET.first, entry.name .. ": no tab it is from") then break end
end
found = Find(SHEET.first, "fire", true)
local tabsFound = {}
for _, entry in ipairs(found) do tabsFound[entry.fromTab.name] = true end
Check(tabsFound.Magic and tabsFound.Gear and tabsFound.Makes, "fire is found in Magic, in Gear (alchemist's fire) and among the makes")
Check(Names(found)["Flame Tongue"] == 1 and Names(found)["Alchemist's Fire"] == 1 and Names(found)["Flame Tongue Mace"] == 1, "each once")
-- a carried item is found in Carried and under its own tab, with each tab's buttons
local carried = RPSheet:AddItem("Potion of Healing")
found = Find(SHEET.first, "potion of healing", true)
local fromCarried, fromMagic
for _, entry in ipairs(found) do
    if entry.name == "Potion of Healing" and entry.fromTab == SHEET.first then fromCarried = entry end
    if entry.name == "Potion of Healing" and entry.fromTab == magicTab then fromMagic = entry end
end
if Check(fromCarried and fromMagic, "the carried potion is found in both tabs") then
    Check(fromCarried.item == carried and fromMagic.item == carried, "both know the carried one")
    buttons = Card(SHEET, fromCarried, fromCarried.fromTab == SHEET.first)
    Check(buttons.Equip and buttons["Sell  25 gp"], "the Carried one has Carried's buttons")
    buttons = Card(SHEET, fromMagic, fromMagic.fromTab == SHEET.first)
    Check(buttons.Add and buttons["Buy  50 gp"], "the listed one has the list's buttons")
end
-- the other sources
local horseFound = Names(Search.Find(RPSheet, STABLE, STABLE.first, "fly", true))
Check(horseFound.Gryphon and horseFound["Wind Rider"] and not horseFound["Riding Horse"], "the stable: fly finds the flyers")
Check(Names(Search.Find(RPSheet, STABLE, TabNamed(STABLE, "Mounts"), "dwarves"))["Giant Goat"], "the stable: a word of the note")
sheet.tools["Smith's Tools"], sheet.tools["Herbalism Kit"] = true, true
RPSheet:AddItem("Smith's Tools"); RPSheet:AddItem("Herbalism Kit")
local CRAFT = Source(RPSheet.ShowCrafting, RPSheet)
if Check(CRAFT ~= nil and CRAFT.ownListed, "the crafting window's first tab repeats the others") then
    local all = Search.Find(RPSheet, CRAFT, CRAFT.first, "", true)
    local recipes = #R.RECIPES.blacksmithing + #R.RECIPES.alchemy
    Check(#all >= recipes, ("crafting: everything is every recipe of every tab, not Can make again (%d of %d)"):format(#all, recipes))
    for _, entry in ipairs(all) do
        if not Check(entry.fromTab ~= CRAFT.first, "Can make is left out of everything") then break end
    end
    found = Names(Search.Find(RPSheet, CRAFT, CRAFT.first, "healing", true))
    Check(found["Potion of Healing"] == 1, "crafting: healing finds the potion's recipe once")
    Check(#Search.Find(RPSheet, CRAFT, CRAFT.first, "blacksmithing", true) == #R.RECIPES.blacksmithing, "crafting: a profession's name finds its recipes")
end

---------------------------------------------------------------------------
-- Pages over everything
---------------------------------------------------------------------------
local first, last = Pages.Range(#everything, SHEET, Search.ALL, "")
Check(first == 1 and last == 24, "everything starts at its first page")
Pages.Turn(1)
first, last = Pages.Range(#everything, SHEET, Search.ALL, "")
Check(first == 25 and last == 48, "and turns")
first = Pages.Range(#makes, SHEET, makesTab, "")
Eq(first, 1, "a tab is another list: back to its first page")
first = Pages.Range(#everything, SHEET, Search.ALL, "healing")
Eq(first, 1, "a new search too")

-- The real window, made of stubs: the search box's state drives what is shown.
RPSheet.ShowItemBrowser = RealShow
local state = UI.ItemBrowserState
Run("show the inventory", RPSheet.ToggleItemBrowser, RPSheet); FlushTimers()
Check(state.everywhere == false and state.search == "", "a browser opens on one tab, not searching")
state.search, state.everywhere = "fire", true
Run("fill it", RPSheet.PopulateItemBrowser, RPSheet)
Run("show the stable", RPSheet.ToggleMountBrowser, RPSheet); FlushTimers()
Check(state.everywhere == false and state.search == "", "another source starts afresh")

Done("search")
