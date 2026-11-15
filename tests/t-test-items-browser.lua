-- The item browser's sources as data: the inventory, the stable, the crafting window
-- with its Scrolls tab, and the wizard's closet. For every tab the entries, marks and
-- lines are built, and the buttons a source adds are captured and clicked.
dofile(ARG3 .. "/t-test-items-lib.lua")
local UI = ns.UI

-- Capture what a source adds instead of making widgets.
local BUTTONS, LABELS = {}, {}
UI.AddItemButton = function(card, width, text, enabled, onClick)
    BUTTONS[#BUTTONS + 1] = { text = text, enabled = enabled and true or false, click = onClick, width = width }
    if type(text) ~= "string" or text == "" then Problem("a button's text is " .. tostring(text)) end
    if type(onClick) ~= "function" then Problem("button " .. tostring(text) .. " has no click function") end
    if type(width) ~= "number" then Problem("button " .. tostring(text) .. " has no width") end
end
local RealAddLabel = UI.AddLabel
UI.AddLabel = function(parent, width, text, onClick, tipTitle, tipBody, explain)
    LABELS[#LABELS + 1] = { text = text, click = onClick, tipTitle = tipTitle, tipBody = tipBody }
    return RealAddLabel(parent, width, text, onClick, tipTitle, tipBody, explain)
end
-- The sources are local to their files: catch them as they are shown.
local RealShow = RPSheet.ShowItemBrowser
local caught, caughtTab
RPSheet.ShowItemBrowser = function(self, wanted, tab) caught, caughtTab = wanted, tab end
local function Source(open, ...)
    caught = nil
    Run("open a browser", open, ...)
    return caught
end
local populates = 0
local RealPopulate = RPSheet.Populate
RPSheet.Populate = function(self, ...) populates = populates + 1; return RealPopulate(self, ...) end

local function Strings(label, list)
    if not Check(type(list) == "table", label .. " is " .. type(list)) then return "" end
    for _, line in ipairs(list) do
        Check(type(line) == "string" and line ~= "", label .. ": a line is " .. tostring(line))
        if type(line) == "string" then Check(not line:find("<stub") and not line:find("%f[%a]nil%f[%A]"), label .. ": " .. line) end
    end
    return table.concat(list, "\n")
end
-- A tab's entries, the way UI/ItemBrowser.lua gathers them.
local function Entries(source, tab)
    if tab == source.first then return source.own(RPSheet) end
    if source.list then return source.list(RPSheet, tab) end
    local entries = {}
    for _, name in ipairs(source.names and source.names(tab.kind) or R.ITEM_NAMES[tab.kind] or {}) do
        entries[#entries + 1] = { name = name, item = source.find(RPSheet, name) }
    end
    return entries
end
local function Tabs(source)
    local tabs = { source.first }
    for _, tab in ipairs(type(source.kinds) == "function" and source.kinds(RPSheet) or source.kinds) do tabs[#tabs + 1] = tab end
    return tabs
end
-- One block: marks, lines, notes and buttons. Returns the buttons by their text.
local function Card(source, entry, first, label)
    label = label .. " / " .. tostring(entry.name)
    local marks = Run(label .. " marks", source.marks, RPSheet, entry)
    Strings(label .. " marks", marks)
    local lines
    if source.lines then lines = Run(label .. " lines", source.lines, RPSheet, entry)
    else lines = Run(label .. " lines", UI.ItemLines, RPSheet, entry.name, entry.item, source.class(RPSheet)) end
    local text = Strings(label .. " lines", lines)
    Check(text ~= "", label .. ": a block that says nothing")
    if source.notes then Strings(label .. " notes", Run(label .. " notes", source.notes, RPSheet, entry)) end
    BUTTONS = {}
    Run(label .. " buttons", source.buttons, RPSheet, {}, entry, first)
    local byText, widths = {}, 0
    for _, button in ipairs(BUTTONS) do byText[button.text] = button; widths = widths + button.width end
    Check(#BUTTONS > 0, label .. ": no buttons")
    return byText, marks or {}, text, BUTTONS
end
-- Everything a source shows, without clicking: title, standing line, every tab.
local function Walk(source, label)
    Check(type(Run(label .. " title", source.title, RPSheet)) == "string", label .. ": title")
    local standing = Run(label .. " standing", source.standing, RPSheet)
    Check(type(standing) == "string" and not standing:find("<stub"), label .. ": standing line is " .. tostring(standing))
    if source.top then Run(label .. " top", source.top, RPSheet, STUB("body")) end
    Check(type(source.empty) == "string" and type(source.first.name) == "string", label .. ": empty text and first tab")
    local count = 0
    for _, tab in ipairs(Tabs(source)) do
        Check(type(tab.name) == "string" and tab.name ~= "", label .. ": a tab without a name")
        local entries = Run(label .. " " .. tab.name .. " entries", Entries, source, tab) or {}
        for _, entry in ipairs(entries) do
            Card(source, entry, tab == source.first, label .. " " .. tab.name)
            count = count + 1
        end
    end
    return count
end
local function Click(button, label)
    if not Check(button ~= nil, label .. ": no such button") then return end
    Run(label, button.click)
    FlushTimers()
end
local function Find(entries, name)
    for _, entry in ipairs(entries) do
        if entry.name == name then return entry end
    end
end
local function TabNamed(source, name)
    for _, tab in ipairs(Tabs(source)) do
        if tab.name == name then return tab end
    end
end

---------------------------------------------------------------------------
-- The inventory
---------------------------------------------------------------------------
local sheet = NewChar("WARRIOR", 5)
local purse = RPSheet:Purse()
local function Gold(gp) purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0 end
local SHEET = Source(RPSheet.ToggleItemBrowser, RPSheet)
if Check(SHEET ~= nil, "the inventory's source") then
    -- every kind of the catalogue has a tab
    local tabbed = {}
    local makesTab
    for _, tab in ipairs(SHEET.kinds) do
        if tab.makes then makesTab = tab else
            tabbed[tab.kind] = true
            Check(R.ITEM_NAMES[tab.kind] ~= nil and #R.ITEM_NAMES[tab.kind] > 0, "inventory tab " .. tab.name .. " lists nothing (" .. tostring(tab.kind) .. ")")
        end
    end
    Check(makesTab ~= nil and makesTab.name == "Makes", "the inventory has a Makes tab")
    for _, kind in ipairs(R.ITEM_KINDS) do Check(tabbed[kind], "no inventory tab for " .. kind) end
    Eq(#SHEET.own(RPSheet), 0, "nothing carried")
    Gold(0)
    local shown = Walk(SHEET, "inventory (poor)")
    print("inventory blocks", shown)
    -- a listed item: Add, Buy, Remove
    local weapons = TabNamed(SHEET, "Weapons")
    local entry = Find(Entries(SHEET, weapons), "Longsword")
    local buttons, marks = Card(SHEET, entry, false, "inventory")
    Check(buttons.Add and buttons.Add.enabled, "Add is on")
    Check(buttons["Buy  15 gp"] and not buttons["Buy  15 gp"].enabled, "Buy is off without the money")
    Check(buttons.Remove and not buttons.Remove.enabled, "Remove is off while none is carried")
    Eq(#marks, 0, "no marks on what isn't carried")
    Click(buttons.Add, "Add a longsword")
    local sword = RPSheet:CarriedItem("Longsword")
    Check(sword and sword.qty == 1, "Add added one")
    entry = Find(Entries(SHEET, weapons), "Longsword")
    buttons, marks = Card(SHEET, entry, false, "inventory")
    Eq(table.concat(marks, ", "), "you have 1", "marks of a carried item")
    Check(buttons.Remove.enabled, "Remove is on now")
    Gold(20)
    buttons = Card(SHEET, entry, false, "inventory")
    Check(buttons["Buy  15 gp"].enabled, "Buy is on with the money")
    Click(buttons["Buy  15 gp"], "Buy a longsword")
    Check(sword.qty == 2 and RPSheet:Coins() == 500, "Buy paid and added")
    Click(buttons["Buy  15 gp"], "Buy without the money")
    Check(sword.qty == 2 and RPSheet:Coins() == 500, "a stale Buy button can't overspend")
    Click(buttons.Remove, "Remove one")
    Eq(sword.qty, 1, "Remove took one")
    -- an item without a price: Buy is off and says so
    R.ITEMS["Priceless Test Relic"] = { kind = "Magic items", cost = 0, weight = 1, rarity = "Artifact", desc = "A thing for the test.", effects = {} }
    Gold(100000)
    buttons = Card(SHEET, { name = "Priceless Test Relic" }, false, "inventory")
    Check(buttons["No price"] and not buttons["No price"].enabled, "an unpriced item's Buy button is off and reads No price")
    Click(buttons["No price"], "click No price anyway")
    Check(RPSheet:CarriedItem("Priceless Test Relic") == nil and RPSheet:Coins() == 10000000, "and clicking it buys nothing")
    R.ITEMS["Priceless Test Relic"] = nil
    -- every listed item's Buy button agrees with the price and the purse
    Gold(50)
    for _, tab in ipairs(SHEET.kinds) do
        for _, each in ipairs(not tab.makes and Entries(SHEET, tab) or {}) do
            local price = R.ITEMS[each.name].cost
            local _, _, _, list = Card(SHEET, each, false, "inventory " .. tab.name)
            Check(#list == 3 and list[1].text == "Add" and list[3].text == "Remove", each.name .. ": buttons are Add, Buy, Remove")
            -- An artifact has no price: its button reads so and is off (checked above).
            Eq(list[2].text, price > 0 and ("Buy  " .. ns.CoinText(price)) or "No price", each.name .. ": Buy label")
            Eq(list[2].enabled, price > 0 and price <= 5000, each.name .. ": Buy enabled")
        end
    end
    -- the Carried tab: Equip, Add one, Attune, Remove
    local own = SHEET.own(RPSheet)
    Eq(#own, 1, "one entry carried")
    buttons = Card(SHEET, own[1], true, "carried")
    Check(buttons.Equip and buttons["Add one"] and buttons.Remove and buttons.Remove.enabled, "a carried plain item: Equip, Add one, Remove")
    Check(buttons["Sell  7 gp 5 sp"] and buttons["Sell  7 gp 5 sp"].enabled, "and Sell at half its price")
    Click(buttons.Equip, "Equip the longsword")
    Check(sword.equipped and #ns.ReadyWeapons(sheet) == 1, "Equip readied it")
    buttons, marks = Card(SHEET, own[1], true, "carried")
    Check(buttons["Put away"] ~= nil and table.concat(marks, ", ") == "you have 1, equipped", "now Put away, marked equipped")
    Click(buttons["Put away"], "Put the longsword away")
    Check(not sword.equipped and #ns.ReadyWeapons(sheet) == 0, "Put away stowed it")
    Click(buttons["Add one"], "Add one")
    Eq(sword.qty, 2, "Add one")
    Click(buttons.Remove, "Remove"); Click(buttons.Remove, "Remove")
    Eq(#sheet.items, 0, "removed to the last")
    -- attunement
    local rings = {}
    for index, name in ipairs({ "Ring of Protection", "Cloak of Protection", "Gauntlets of Ogre Power", "Headband of Intellect" }) do
        rings[index] = RPSheet:AddItem(name)
    end
    own = SHEET.own(RPSheet)
    buttons, marks = Card(SHEET, own[1], true, "carried")
    Check(buttons.Attune and not buttons["Add one"] and table.concat(marks, ", ") == "you have 1, not attuned", "an item to attune: Attune, marked not attuned")
    FlushTimers()
    populates = 0
    Click(buttons.Attune, "Attune")
    Check(rings[1].attuned, "Attune attuned it")
    Eq(populates, 1, "Attune rebuilds the sheet once")
    buttons, marks = Card(SHEET, own[1], true, "carried")
    Check(buttons["End attunement"] and table.concat(marks, ", ") == "you have 1, attuned", "now End attunement, marked attuned")
    for index = 2, 3 do Click(Card(SHEET, own[index], true, "carried").Attune, "Attune " .. index) end
    local mark = #PRINTED
    Click(Card(SHEET, own[4], true, "carried").Attune, "Attune a fourth")
    Check(not rings[4].attuned and PrintedSince(mark):find("already attuned"), "the fourth is refused")
    Check(SHEET.standing(RPSheet):find("Attuned |c%x+3 of 3"), "the standing line counts them: " .. SHEET.standing(RPSheet))
    Click(Card(SHEET, own[1], true, "carried")["End attunement"], "End attunement")
    Check(not rings[1].attuned, "ended")
    populates = 0
    Click(Card(SHEET, own[1], true, "carried").Equip, "Equip a ring")
    Check(rings[1].equipped and populates == 1, "Equip rebuilds the sheet once (" .. populates .. ")")
    populates = 0
    Click(Card(SHEET, own[1], true, "carried").Remove, "Remove a ring")
    Check(#sheet.items == 3 and populates == 1, "Remove rebuilds the sheet once (" .. populates .. ")")
    -- the shop line
    LABELS = {}
    SHEET.top(RPSheet, STUB("body"))
    Eq(#LABELS, 0, "no Buying from line without a discount")
    sheet.renown["Kirin Tor"], sheet.renown["Argent Dawn"] = 10, 25
    SHEET.top(RPSheet, STUB("body"))
    if Check(#LABELS == 1 and LABELS[1].text:find("nobody in particular") and type(LABELS[1].tipBody) == "string", "the Buying from line shows") then
        Check(LABELS[1].tipBody:find("Argent Dawn 15%%, Kirin Tor 10%%") , "the tip lists the discounts: " .. LABELS[1].tipBody)
        Run("click Buying from", LABELS[1].click, "LeftButton"); FlushTimers()
        Eq(RPSheet:ShopFaction(), "Argent Dawn", "a click picks the first faction")
        LABELS = {}; SHEET.top(RPSheet, STUB("body"))
        Check(LABELS[1].text:find("Argent Dawn %(15%% off%)"), "the line names it: " .. LABELS[1].text)
        entry = Find(Entries(SHEET, weapons), "Longsword")
        Check(Card(SHEET, entry, false, "inventory")["Buy  12 gp 7 sp 5 cp (-15%)"], "the Buy button shows the discount")
        Run("click Buying from", LABELS[1].click, "LeftButton"); FlushTimers()
        Eq(RPSheet:ShopFaction(), "Kirin Tor", "the next click the second")
        LABELS = {}; SHEET.top(RPSheet, STUB("body"))
        Run("click Buying from", LABELS[1].click, "LeftButton"); FlushTimers()
        Eq(RPSheet:ShopFaction(), nil, "then nobody again")
        LABELS = {}; SHEET.top(RPSheet, STUB("body"))
        Run("right-click Buying from", LABELS[1].click, "RightButton"); FlushTimers()
        Eq(RPSheet:ShopFaction(), "Kirin Tor", "a right-click goes backwards")
        RPSheet:SetShopFaction(nil)
    end
    sheet.renown["Kirin Tor"], sheet.renown["Argent Dawn"] = nil, nil
    Check(SHEET.options == nil and type(ns.OpenInventoryOptions) == "function", "the inventory's cog opens Customize > Inventory")
    OPENED.RPSheet = nil
    Run("OpenInventoryOptions", ns.OpenInventoryOptions)
    Check(OPENED.RPSheet, "it opens the settings")
end

---------------------------------------------------------------------------
-- The stable
---------------------------------------------------------------------------
sheet = NewChar("WARRIOR", 5)
purse = RPSheet:Purse()
local STABLE = Source(RPSheet.ToggleMountBrowser, RPSheet)
if Check(STABLE ~= nil, "the stable's source") then
    local listed = {}
    for _, tab in ipairs(STABLE.kinds) do
        local names = STABLE.names(tab.kind)
        if Check(type(names) == "table" and #names > 0, "stable tab " .. tab.name .. " lists nothing (" .. tostring(tab.kind) .. ")") then
            for _, name in ipairs(names) do
                Check(R.MOUNTS[name] ~= nil, "stable tab " .. tab.name .. " lists " .. name .. ", which is not in the catalogue")
                Check(not listed[name], name .. " is in two stable tabs")
                listed[name] = true
            end
        end
    end
    for name in pairs(R.MOUNTS) do Check(listed[name], name .. " is in no tab of the stable") end
    Gold(0)
    print("stable blocks", Walk(STABLE, "stable (poor)"))
    Gold(1000000)
    -- every listed one: Add and Buy
    for _, tab in ipairs(STABLE.kinds) do
        for _, entry in ipairs(Entries(STABLE, tab)) do
            local name, known = entry.name, R.MOUNTS[entry.name]
            local _, _, _, list = Card(STABLE, entry, false, "stable " .. tab.name)
            if Check(#list == 2 and list[1].text == "Add" and list[1].enabled, name .. ": Add and a Buy button") then
                local why = RPSheet:MountNotSold(name)
                Eq(list[2].enabled, why == nil, name .. ": Buy enabled (" .. tostring(why) .. ")")
                if known.unsold then Eq(list[2].text, "Not for sale", name .. ": label")
                elseif (known.cost or 0) <= 0 then Eq(list[2].text, "No price", name .. ": label")
                else Eq(list[2].text, "Buy  " .. ns.CoinText(known.cost), name .. ": label") end
                local before, coins = #sheet.mounts, RPSheet:Coins()
                Click(list[2], "Buy " .. name)
                if why then
                    Check(#sheet.mounts == before and RPSheet:Coins() == coins, name .. ": bought though " .. why)
                else
                    Check(#sheet.mounts == before + 1 and RPSheet:Coins() == coins - known.cost, name .. ": Buy paid and added")
                end
                before = #sheet.mounts
                Click(list[1], "Add " .. name)
                Check(#sheet.mounts == before + 1 and sheet.mounts[#sheet.mounts].name == name, name .. ": Add added")
                Eq(table.concat(select(2, Card(STABLE, { name = name, item = STABLE.find(RPSheet, name) }, false, "stable")), ", "), "owned", name .. ": marked owned")
            end
        end
    end
    -- the Owned tab: every owned one's buttons
    RPSheet:AddItem(R.EXOTIC_SADDLE)
    local owned = STABLE.own(RPSheet)
    Check(#owned == #sheet.mounts and #owned > 0, "everything owned is listed")
    for _, entry in ipairs(owned) do
        local item = entry.item
        local buttons, marks, _, list = Card(STABLE, entry, true, "owned")
        -- An animal and a drawn vehicle have a button for the harness between the two.
        local harness = ns.CanPull(item) or ns.IsDrawn(item)
        Check(#list == (harness and 3 or 2) and list[#list].text == "Remove" and list[#list].enabled, entry.name .. ": the last button is Remove")
        if harness then
            Check(list[2].text == "Harness" and list[2].enabled, entry.name .. ": Harness")
            Click(list[2], "Harness " .. entry.name)
            Check(item.hitched, entry.name .. ": in harness")
            buttons, marks = Card(STABLE, entry, true, "owned")
            Check(buttons.Unharness and table.concat(marks, ", ") == "owned, in harness", entry.name .. ": now Unharness, marked in harness")
            Click(buttons.Unharness, "Unharness " .. entry.name)
            Check(not item.hitched, entry.name .. ": out of harness")
        end
        if item.kind == "COMPANION" then
            Check(list[1].text == "Call" and list[1].enabled, entry.name .. ": Call")
            Click(list[1], "Call " .. entry.name)
            Check(item.called and RPSheet:Companion() == item, entry.name .. ": called")
            buttons, marks = Card(STABLE, entry, true, "owned")
            Check(buttons.Dismiss and table.concat(marks, ", ") == "owned, out", entry.name .. ": now Dismiss, marked out")
            Check(STABLE.standing(RPSheet):find("Companion out |c%x+" .. entry.name:gsub("%p", "%%%0")), "the standing line names the companion")
            Click(buttons.Dismiss, "Dismiss " .. entry.name)
            Check(not item.called, entry.name .. ": dismissed")
        else
            local refusal = RPSheet:MountRefusal(item)
            Eq(list[1].text, item.kind == "VEHICLE" and "Get aboard" or "Ride", entry.name .. ": first button")
            Eq(list[1].enabled, refusal == nil, entry.name .. ": Ride enabled (" .. tostring(refusal) .. ")")
            Click(list[1], "Ride " .. entry.name)
            Eq(item.riding, refusal == nil, entry.name .. ": riding after the click")
            if item.riding then
                buttons, marks = Card(STABLE, entry, true, "owned")
                Check(buttons["Get off"] and buttons["Get off"].enabled, entry.name .. ": now Get off")
                Eq(table.concat(marks, ", "), "owned, " .. (item.kind == "VEHICLE" and "aboard" or "riding"), entry.name .. ": marks")
                Check(STABLE.standing(RPSheet):find("On |c%x+" .. entry.name:gsub("%p", "%%%0")), "the standing line names the mount")
                Click(buttons["Get off"], "Get off " .. entry.name)
                Check(not item.riding, entry.name .. ": got off")
            end
        end
    end
    -- Remove
    local first = owned[1]
    local before = #sheet.mounts
    populates = 0
    Click(Card(STABLE, first, true, "owned").Remove, "Remove " .. first.name)
    Check(#sheet.mounts == before - 1 and populates == 1, "Remove took it off the list and rebuilt once (" .. populates .. ")")
    -- the cog
    OPENED.RPSheet = nil
    Run("stable options", STABLE.options)
    Check(OPENED.RPSheet, "the stable's cog opens the settings")
    -- a discount on an everyday mount
    sheet.renown["Kirin Tor"] = 10
    RPSheet:SetShopFaction("Kirin Tor")
    local horse = Card(STABLE, { name = "Riding Horse" }, false, "stable")
    Check(horse["Buy  67 gp 5 sp (-10%)"] ~= nil, "a riding horse at 10% off")
    RPSheet:SetShopFaction(nil)
end

---------------------------------------------------------------------------
-- Crafting
---------------------------------------------------------------------------
sheet = NewChar("MAGE", 9)
purse = RPSheet:Purse()
local CRAFT = Source(RPSheet.ShowCrafting, RPSheet)
if Check(CRAFT ~= nil, "the crafting source") then
    Gold(0)
    for name in pairs(sheet.tools) do sheet.tools[name] = nil end
    local tabs = CRAFT.kinds(RPSheet)
    -- a Mage has Arcana or not; without tools only the Scrolls tab can be there
    for _, tab in ipairs(tabs) do Check(tab.scribe, "a tab without the tools: " .. tab.name) end
    Walk(CRAFT, "crafting (no tools)")
    -- proficient with every tool, carrying them all
    for _, name in ipairs(R.TOOL_ORDER) do
        sheet.tools[name] = true
        if R.ITEMS[name] then RPSheet:AddItem(name) end
    end
    sheet.skills.Arcana = 1
    -- a few spells on the list: the first of each level up to 3 that asks for no component
    local names = {}
    for name in pairs(R.SPELLS) do names[#names + 1] = name end
    table.sort(names)
    for level = 0, 3 do
        for _, name in ipairs(names) do
            if R.SPELLS[name].level == level and not RPSheet:MissingComponents(R.SPELLS[name]) then
                sheet.spells[#sheet.spells + 1] = CopyTable(R.SPELLS[name])
                break
            end
        end
    end
    tabs = CRAFT.kinds(RPSheet)
    local makers = 0
    for _, key in ipairs(R.PROFESSION_ORDER) do
        if R.PROFESSIONS[key].kind == "make" then makers = makers + 1 end
    end
    Eq(#tabs, makers + 1, "a tab per making profession and Scrolls")
    for _, each in ipairs(CRAFT.own(RPSheet)) do
        Check(not each.scribe and ns.CraftCost(each.name) == 0, each.name .. " can be made without money though it costs something")
    end
    print("crafting blocks (poor)", Walk(CRAFT, "crafting (poor)"))
    Gold(10000000)
    local materials = RPSheet:Trade().materials
    local blocks = Walk(CRAFT, "crafting (rich)")
    print("crafting blocks (rich)", blocks)
    -- buttons of one recipe
    local smithing = TabNamed(CRAFT, "Smithing")
    local entry = Find(Entries(CRAFT, smithing), "Longsword")
    local buttons, marks, text, list = Card(CRAFT, entry, false, "crafting")
    Check(#list == 1 and buttons["Make  7 gp 5 sp"] and buttons["Make  7 gp 5 sp"].enabled, "a basic recipe without materials: Make alone")
    Eq(table.concat(marks, ", "), "blacksmithing, apprentice", "its marks")
    populates = 0
    Click(buttons["Make  7 gp 5 sp"], "Make a longsword")
    Check(RPSheet:CarriedItem("Longsword") and RPSheet:Coins() == 10000000 * 100 - 750, "Make paid and added")
    Eq(populates, 1, "Make rebuilds the sheet once")
    Eq(table.concat(CRAFT.marks(RPSheet, entry), ", "), "blacksmithing, apprentice, you have 1", "marked as carried")
    materials.ore = 500
    buttons, marks, text, list = Card(CRAFT, entry, false, "crafting")
    Check(#list == 2 and buttons["Coins only"] and buttons["Coins only"].enabled, "with ore: Coins only too")
    local coins = RPSheet:Coins()
    Click(buttons["Coins only"], "Coins only")
    Check(materials.ore == 500 and RPSheet:Coins() == coins - 750, "Coins only left the ore alone")
    Click(buttons["Make  7 gp 5 sp"], "Make with ore")
    Check(materials.ore == 0 and RPSheet:Coins() == coins - 750 - 250, "Make used the ore first")
    -- a recipe that has to be learned
    local learned
    for _, tab in ipairs(tabs) do
        for _, each in ipairs(not tab.scribe and Entries(CRAFT, tab) or {}) do
            if not each.recipe.basic and each.recipe.level <= RPSheet:ProfessionLevel() and not learned then learned = each end
        end
    end
    if Check(learned ~= nil, "a recipe to learn within reach") then
        buttons = Card(CRAFT, learned, false, "crafting")
        local make
        for label, button in pairs(buttons) do if label:find("^Make") then make = button end end
        Check(make and not make.enabled and buttons["Learned it"], learned.name .. ": Make off, Learned it offered")
        Check(table.concat(CRAFT.notes(RPSheet, learned), "\n"):find("you haven't learned it"), "the note says why")
        Click(buttons["Learned it"], "Learned it")
        Check(RPSheet:RecipeKnown(learned.recipe), "learned")
        buttons = Card(CRAFT, learned, false, "crafting")
        for label, button in pairs(buttons) do if label:find("^Make") then make = button end end
        Check(make.enabled and buttons["Forget recipe"], "now Make is on and Forget recipe offered")
        Click(buttons["Forget recipe"], "Forget recipe")
        Check(not RPSheet:RecipeKnown(learned.recipe), "forgotten")
    end
    -- a vehicle
    local trike = Find(Entries(CRAFT, TabNamed(CRAFT, "Engineering")), "Goblin Trike")
    if Check(trike ~= nil, "the trike is an engineering recipe") then
        buttons = Card(CRAFT, trike, false, "crafting")
        for label, button in pairs(buttons) do
            if label:find("^Make") then Click(button, "Make a trike") end
        end
        Check(RPSheet:OwnedMount("Goblin Trike") ~= nil and RPSheet:CarriedItem("Goblin Trike") == nil, "a built vehicle goes to the stable")
        Check(table.concat(CRAFT.marks(RPSheet, trike), ", "):find("you own one"), "marked as owned")
    end
    -- the Can make tab lists exactly what CanCraft allows
    local can = CRAFT.own(RPSheet)
    for _, each in ipairs(can) do
        if each.scribe then Check(RPSheet:CanScribe(each.spell), each.name .. " listed though it can't be scribed")
        else Check(RPSheet:CanCraft(each.profession, each.recipe), each.name .. " listed though it can't be made") end
    end
    Check(#can > 0, "something can be made with money")
    -- Scrolls
    local scrolls = TabNamed(CRAFT, "Scrolls")
    local spells = Entries(CRAFT, scrolls)
    Check(#spells > 0, "a Mage has spells to scribe")
    local done = 0
    for _, each in ipairs(spells) do
        buttons, marks, text, list = Card(CRAFT, each, false, "scrolls")
        local can, why = RPSheet:CanScribe(each.spell)
        Eq(list[1].enabled, can == true, each.name .. ": Scribe enabled (" .. tostring(why) .. ")")
        Check(list[1].text == "Scribe  " .. ns.CoinText((ns.ScribeCost(each.spell.level))), each.name .. ": label " .. list[1].text)
        if can and done < 3 then
            done = done + 1
            coins = RPSheet:Coins()
            Click(list[1], "Scribe " .. each.name)
            local scroll = RPSheet:CarriedItem(each.name)
            Check(scroll and scroll.scribed and RPSheet:Coins() == coins - ns.ScribeCost(each.spell.level), each.name .. ": scribed and paid")
            Check(table.concat(CRAFT.marks(RPSheet, each), ", "):find("you have 1"), each.name .. ": marked")
            -- the scroll's own card in the inventory
            if scroll then Strings(each.name .. " card", UI.ItemLines(RPSheet, scroll.name, scroll)) end
        end
    end
    Check(done > 0, "no scroll could be scribed")
    materials.herbs = 100000
    buttons, marks, text, list = Card(CRAFT, spells[1], false, "scrolls")
    Check(#list == 2 and list[2].text == "Coins only", "with herbs: Coins only on the Scrolls tab")
    coins = RPSheet:Coins()
    Click(list[2], "Scribe for coins only")
    Check(materials.herbs == 100000 and RPSheet:Coins() < coins, "Coins only left the herbs alone")
    Click(list[1], "Scribe with herbs")
    Check(materials.herbs < 100000, "Scribe used the herbs")
    OPENED.RPSheet = nil
    Run("crafting options", CRAFT.options)
    Check(OPENED.RPSheet, "the crafting cog opens the settings")
    -- opened on a profession's tab
    caughtTab = nil
    RPSheet:ShowCrafting(R.PROFESSIONS.alchemy)
    Check(caughtTab == R.PROFESSIONS.alchemy.tab, "ShowCrafting opens on the profession's tab")
end

---------------------------------------------------------------------------
-- The wizard's closet
---------------------------------------------------------------------------
Run("open the wizard", ns.OpenWizard); FlushTimers()
local draft = W.draft
if Check(draft ~= nil, "the wizard has a draft") then
    draft.class = "PRIEST"
    local CLOSET = Source(W.OpenCloset)
    if Check(CLOSET ~= nil, "the closet's source") then
        Check(CLOSET.gone() == false, "the closet is there while the wizard is")
        local tabbed = {}
        for _, tab in ipairs(CLOSET.kinds) do tabbed[tab.kind] = true end
        for _, kind in ipairs(R.CLOSET_KINDS) do Check(tabbed[kind], "no closet tab for " .. kind) end
        for kind in pairs(tabbed) do Check(tContains(R.CLOSET_KINDS, kind), "closet tab " .. kind .. " is not a drawer") end
        print("closet blocks", Walk(CLOSET, "closet"))
        Eq(#CLOSET.own(), 0, "nothing taken")
        -- every item: Take, Put back, Equip
        for _, tab in ipairs(CLOSET.kinds) do
            for _, entry in ipairs(Entries(CLOSET, tab)) do
                local name = entry.name
                Check(entry.item == nil, name .. ": the closet finds nothing carried")
                local buttons, marks, _, list = Card(CLOSET, entry, false, "closet " .. tab.name)
                local wearable = R.ARMOR_ITEMS[name] ~= nil or name == "Shield" or R.WEAPONS[name] ~= nil
                Check(#list == 3 and list[1].text == "Take" and list[1].enabled and list[2].text == "Put back" and not list[2].enabled, name .. ": Take on, Put back off")
                Eq(list[3].text, wearable and "Equip" or "Can't be equipped", name .. ": third button")
                Eq(list[3].enabled, wearable, name .. ": Equip enabled")
                Click(list[1], "Take " .. name)
                Eq(draft.closet[name], 1, name .. ": taken")
                buttons, marks, _, list = Card(CLOSET, entry, false, "closet " .. tab.name)
                Check(list[1].text == "Take another" and list[2].enabled and table.concat(marks, ", ") == "taken 1", name .. ": Take another, Put back on, marked")
                Click(list[1], "Take another " .. name)
                Eq(draft.closet[name], 2, name .. ": two taken")
                if wearable then
                    Click(list[3], "Equip " .. name)
                    Check(draft.worn[name] == true, name .. ": equipped")
                    buttons, marks, _, list = Card(CLOSET, entry, false, "closet " .. tab.name)
                    Check(list[3].text == "Put away" and table.concat(marks, ", ") == "taken 2, equipped", name .. ": Put away, marked equipped")
                    Click(list[3], "Put away " .. name)
                    Check(draft.worn[name] == nil, name .. ": put away")
                end
                Click(list[2], "Put back " .. name); Click(list[2], "Put back " .. name)
                Check(draft.closet[name] == nil, name .. ": put back")
                Click(list[2], "Put back " .. name)
                Check(draft.closet[name] == nil, name .. ": putting back nothing")
            end
        end
        -- Equip takes it first; one suit at a time; putting back takes it off
        local function Buttons(name) return select(4, Card(CLOSET, { name = name }, false, "closet")) end
        Click(Buttons("Chain Mail")[3], "Equip chain mail")
        Check(draft.closet["Chain Mail"] == 1 and draft.worn["Chain Mail"], "Equip takes the item first")
        Click(Buttons("Leather Armor")[3], "Equip leather")
        Check(draft.worn["Leather Armor"] and not draft.worn["Chain Mail"] and draft.closet["Chain Mail"] == 1, "one suit at a time")
        Click(Buttons("Shield")[3], "Equip shield")
        Click(Buttons("Mace")[3], "Equip mace")
        Check(draft.worn.Shield and draft.worn.Mace and draft.worn["Leather Armor"], "shield and mace next to the armor")
        local own = CLOSET.own()
        Eq(#own, 4, "four things taken")
        for _, entry in ipairs(own) do Card(CLOSET, entry, true, "taken") end
        local standing = CLOSET.standing()
        Check(standing:find("worth |c%x+" .. ns.CoinText(7500 + 1000 + 1000 + 500):gsub("%p", "%%%0")), "the standing line adds up: " .. standing)
        Click(Buttons("Leather Armor")[2], "Put leather back")
        Check(draft.worn["Leather Armor"] == nil, "putting the last one back takes it off")
        -- the cog must not open the active character's inventory page
        OPENED.RPSheet = nil
        Check(type(CLOSET.options) == "function", "the closet has a cog function of its own")
        if CLOSET.options then Run("closet cog", CLOSET.options) end
        Check(not OPENED.RPSheet, "the closet's cog opens Customize > Inventory of the active character")
        -- gone with the wizard
        local kept = W.draft
        W.draft = nil
        Check(CLOSET.gone() == true, "no draft: the closet is gone")
        W.draft = kept
        Run("CloseCloset", W.CloseCloset)
    end
end

---------------------------------------------------------------------------
-- The real window, made of stubs: every source shown and filled without an error
---------------------------------------------------------------------------
RPSheet.ShowItemBrowser = RealShow
RPSheet.Populate = RealPopulate
NewChar("WARRIOR", 5)
RPSheet:AddItem("Longsword"); RPSheet:AddMount("Riding Horse")
Run("show the inventory", RPSheet.ToggleItemBrowser, RPSheet); FlushTimers()
Run("fill it", RPSheet.PopulateItemBrowser, RPSheet)
-- the search, over the tab and over everything, through the window's own state
local state = UI.ItemBrowserState
state.search = "healing"
Run("fill it searching", RPSheet.PopulateItemBrowser, RPSheet)
state.everywhere = true
Run("fill it searching everything", RPSheet.PopulateItemBrowser, RPSheet)
state.search = ""
Run("fill it with everything", RPSheet.PopulateItemBrowser, RPSheet)
state.everywhere = false
Run("show the stable", RPSheet.ToggleMountBrowser, RPSheet); FlushTimers()
Run("fill it", RPSheet.PopulateItemBrowser, RPSheet)
Run("show crafting", RPSheet.ShowCrafting, RPSheet); FlushTimers()
Run("show crafting on a tab", RPSheet.ShowCrafting, RPSheet, R.PROFESSIONS.alchemy); FlushTimers()
Run("show the closet", W.OpenCloset); FlushTimers()
Run("fill it", RPSheet.PopulateItemBrowser, RPSheet)
Run("closet changed", W.ClosetChanged); FlushTimers()

Done("browser")
