-- The item browser, really built, on each of its sources: the inventory, the stable,
-- crafting (with the Scrolls tab) and the wizard's starting closet. Every tab is
-- opened, paged forward and back and searched; the buttons of the first blocks of
-- every tab are clicked and their effect checked; the window is locked, minimized and
-- resized, and the layout of tabs, blocks and button rows is checked at every width.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local stats = { tabs = 0, pages = 0, searches = 0, buttons = 0, blocks = 0, widths = 0 }
local function Check(what, ok) if not ok then Problem(what) end end

local function Body() return RPSheet.itemBody end
local function Of(kind)
    local list = {}
    for _, part in ipairs(Body().children) do
        if part.type == kind then list[#list + 1] = part end
    end
    return list
end
local function Tabs() return Of("RPSheetTab") end
local function Cards() return Of("InlineGroup") end
local function Shown() return RPSheet.itemWindow and RPSheet.itemWindow.frame:IsShown() end

-- The "Showing a-b of n" line, or nil when everything fits on one page.
local function Showing()
    for _, part in ipairs(Of("InteractiveLabel")) do
        local from, to, total = F.Plain(PartText(part)):match("^Showing (%d+)%-(%d+) of (%d+)$")
        if from then return tonumber(from), tonumber(to), tonumber(total) end
    end
end
local function PageButton(text)
    for _, part in ipairs(Of("Button")) do
        if part.text:GetText() == text then return part end
    end
end
local function OpenTabName()
    for _, tab in ipairs(Tabs()) do
        if tab.open then return tab.text:GetText() end
    end
end
local function ClickTab(name)
    for _, tab in ipairs(Tabs()) do
        if tab.text:GetText() == name then
            ClickPart("tab " .. name, tab, "LeftButton")
            return true
        end
    end
    return false
end
local function Search(text)
    local box = Of("EditBox")[1]
    if not box then Problem("no search box") return end
    Try("search " .. text, F.Type, box.editbox, text, true)
    F.Settle()
    CheckHidden("search " .. text)
    stats.searches = stats.searches + 1
end
-- The name of a block: its title without the words in brackets after it.
local function CardName(card)
    local title = F.Plain(card.titletext:GetText() or "")
    return (title:gsub("  %(.*%)$", ""))
end
local function CardButtons(card)
    local list = {}
    for _, part in ipairs(card.children) do
        if part.type == "Button" then list[#list + 1] = part end
    end
    return list
end
local function FindCard(name)
    for _, card in ipairs(Cards()) do
        if CardName(card) == name then return card end
    end
end

-- What every view of the window must hold to.
local function CheckView(where, firstText)
    local body = Body()
    local cards = Cards()
    stats.blocks = stats.blocks + #cards
    Check(where .. ": " .. #cards .. " blocks on one page", #cards <= 24)
    local tabs = Tabs()
    for index = 2, #tabs do
        if not SameRow(tabs[1], tabs[index]) then Problem(where .. ": the tab " .. tostring(tabs[index].text:GetText()) .. " wrapped") break end
    end
    local open = 0
    for _, tab in ipairs(tabs) do if tab.open then open = open + 1 end end
    -- While every tab is searched at once, no single tab is the open one.
    Check(where .. ": " .. open .. " tabs are marked open", open == (ns.UI.ItemBrowserState.everywhere and 0 or 1))
    CheckFlowRows(body, where)
    CheckOverlap(body, where)
    local edge = body.content:GetLeft() + body.content:GetWidth()
    for _, part in ipairs(body.children) do
        CheckText(where, PartText(part))
        if part.frame:GetRight() > edge + 0.5 then Problem(where .. ": '" .. F.Plain(PartText(part)):sub(1, 30) .. "' runs past the window's edge") break end
        if part.type == "InteractiveLabel" and part.events.OnEnter then HoverPart(where .. " row", part) end
    end
    for _, card in ipairs(cards) do
        local name = CardName(card)
        Check(where .. ": a block without a title", name ~= "")
        CheckText(where .. " block " .. name, card.titletext:GetText())
        local buttons = CardButtons(card)
        Check(where .. ": the block " .. name .. " has no buttons", #buttons > 0)
        -- buttons whose shares add up to a row stand on one row
        CheckFlowRows(card, where .. " block " .. name)
        for _, part in ipairs(card.children) do
            local text = PartText(part)
            CheckText(where .. " block " .. name, text)
            if part.type == "InteractiveLabel" and not F.Plain(text):match("%S") then Problem(where .. ": the block " .. name .. " says nothing") end
            if part.type == "Button" and (part.text:GetText() or "") == "" then Problem(where .. ": the block " .. name .. " has a button without text") end
        end
        -- the block is as tall as what is in it
        local low = card.frame:GetBottom()
        for _, part in ipairs(card.children) do
            if part.frame:GetBottom() and part.frame:GetBottom() < low - 0.5 then
                Problem(where .. ": the block " .. name .. " is shorter than what is in it")
                break
            end
        end
    end
    -- an empty view says so, and an empty tab doesn't say what the first tab says
    if #cards == 0 then
        local said
        for _, part in ipairs(Of("InteractiveLabel")) do
            local text = F.Plain(PartText(part))
            if text:find("^Nothing") or text:find("nothing") then said = text end
        end
        Check(where .. ": an empty view says nothing about it", said ~= nil)
        if said and firstText and OpenTabName() ~= Tabs()[1].text:GetText() and said == firstText then
            Problem(where .. ": the empty tab " .. tostring(OpenTabName()) .. " shows the first tab's text: " .. said:sub(1, 60))
        end
    end
end

-- Pages forward to the end and back to the start.
local function PageThrough(where)
    local from, to, total = Showing()
    if not from then return end
    Check(where .. ": doesn't start on the first page", from == 1 and to == 24)
    Check(where .. ": Previous can be clicked on the first page", not PageButton("Previous").frame:IsEnabled())
    local guard = 0
    while PageButton("Next") and PageButton("Next").frame:IsEnabled() and guard < 60 do
        guard = guard + 1
        ClickPart(where .. " Next", PageButton("Next"), "LeftButton")
        stats.pages = stats.pages + 1
        if ARG4 == "progress" then print(("%.1fs next %s"):format(os.clock(), tostring(Showing()))) io.stdout:flush() end
        local nextFrom, nextTo, nextTotal = Showing()
        if nextFrom ~= to + 1 or nextTotal ~= total or nextTo ~= math.min(total, nextFrom + 23) then
            Problem(("%s: after %d-%d of %d, Next shows %s-%s of %s"):format(where, from, to, total, tostring(nextFrom), tostring(nextTo), tostring(nextTotal)))
            return
        end
        Check(where .. ": a turned page isn't read from its top", (Body().status or Body().localstatus).scrollvalue == 0)
        Check(where .. ": page with " .. #Cards() .. " blocks for " .. nextFrom .. "-" .. nextTo, #Cards() == nextTo - nextFrom + 1)
        from, to = nextFrom, nextTo
        CheckView(where .. " page from " .. from)
    end
    Check(where .. ": the last page ends at " .. tostring(to) .. " of " .. total, to == total)
    while PageButton("Previous") and PageButton("Previous").frame:IsEnabled() and guard < 120 do
        guard = guard + 1
        ClickPart(where .. " Previous", PageButton("Previous"), "LeftButton")
        stats.pages = stats.pages + 1
    end
    Check(where .. ": Previous doesn't lead back to the first page", Showing() == 1)
end

-- Clicks every button of the first blocks. `effect(name, text, before)` checks what a
-- button did; `snapshot(name)` is what it compares.
local function ClickButtons(where, count, snapshot, effect)
    local names = {}
    for index, card in ipairs(Cards()) do
        if index > count then break end
        names[#names + 1] = CardName(card)
    end
    for _, name in ipairs(names) do
        for index = 1, 4 do
            local card = FindCard(name)
            local button = card and CardButtons(card)[index]
            if not button then break end
            local text = button.text:GetText()
            if button.frame:IsEnabled() then
                local before = snapshot and snapshot(name)
                local pageBefore = Showing()
                ClickPart(("%s block %s button %s"):format(where, name, tostring(text)), button, "LeftButton")
                stats.buttons = stats.buttons + 1
                if ARG4 == "progress" then print(("%.1fs %s: %s on %s, %d timers"):format(os.clock(), where, tostring(text), name, #F.timers)) io.stdout:flush() end
                if effect then Try(where .. " effect of " .. tostring(text), effect, name, text, before) end
                local pageNow = Showing()
                if pageBefore and pageNow and pageNow ~= pageBefore then
                    Problem(("%s: the button %s of %s turned the page from %d to %d"):format(where, tostring(text), name, pageBefore, pageNow))
                end
            else
                -- a greyed button does nothing
                local printed = #PRINTED
                F.Fire(button.frame, "OnClick", "LeftButton")
                F.Click(button.frame)
            end
        end
    end
end

local function Resize(where)
    local window = RPSheet.itemWindow
    local minWidth = window.frame:GetResizeBounds()
    for width = minWidth, 900, 40 do
        F.Fire(window.sizer, "OnMouseDown", "LeftButton")
        window.frame:SetWidth(width)
        F.Settle()
        F.Fire(window.sizer, "OnMouseUp", "LeftButton")
        F.Settle()
        stats.widths = stats.widths + 1
        if ARG4 == "progress" then print(("%.1fs %s width %d"):format(os.clock(), where, width)) io.stdout:flush() end
        CheckView(("%s at width %d"):format(where, width))
    end
    window.frame:SetWidth(560)
    F.Fire(window.sizer, "OnMouseUp", "LeftButton")
    F.Settle()
end

-- Every tab of the open source: looked at, paged, searched.
local function WalkTabs(where, firstText, each)
    local names = {}
    for _, tab in ipairs(Tabs()) do names[#names + 1] = tab.text:GetText() end
    Check(where .. ": no tabs", #names > 1)
    for _, name in ipairs(names) do
        Check(where .. ": the tab " .. name .. " is gone", ClickTab(name))
        Check(where .. ": clicking the tab " .. name .. " opened " .. tostring(OpenTabName()), OpenTabName() == name)
        stats.tabs = stats.tabs + 1
        local label = where .. " tab " .. name
        if ARG4 == "progress" then print(("%.1fs %s"):format(os.clock(), label)) io.stdout:flush() end
        CheckView(label, firstText)
        PageThrough(label)
        -- a search that finds some, one that finds none, and back to everything
        local first = Cards()[1]
        if first then
            local word = CardName(first):match("%a%a%a+") or CardName(first)
            local all = #Cards()
            Search(word:upper())
            Check(label .. ": searching " .. word .. " finds nothing", #Cards() > 0)
            -- The search also looks at descriptions, so other blocks may show; the one
            -- the word was taken from must be among those found, and they are fewer
            -- than the whole tab or as many.
            local byName = false
            for _, card in ipairs(Cards()) do
                if CardName(card):lower():find(word:lower(), 1, true) then byName = true end
            end
            local _, _, found = Showing()
            Check(label .. ": the search for " .. word .. " doesn't show a block of that name", byName or (found or 0) > 24)
            Check(label .. ": the search for " .. word .. " shows more than the tab holds", #Cards() <= all)
            CheckView(label .. " search " .. word, firstText)
            Search("zzqq")
            local said
            for _, part in ipairs(Of("InteractiveLabel")) do
                if F.Plain(PartText(part)) == "Nothing here matches your search." then said = true end
            end
            Check(label .. ": a search without a match doesn't say so", said and #Cards() == 0)
            Search("   ")
            Check(label .. ": clearing the search doesn't bring everything back", #Cards() == all)
        end
        if each then each(name, label) end
    end
end

---------------------------------------------------------------------------
-- A character with money, renown (so the "Buying from" line shows) and every tool
---------------------------------------------------------------------------
local sheet = NewCharacter("MAGE", nil, nil, 9, 2)
sheet.skills.Arcana = 1
for _, name in ipairs(R.TOOL_ORDER) do sheet.tools[name] = true end
for index, faction in ipairs(R.ALL_FACTIONS) do
    if index <= 3 then sheet.renown[faction] = 12 * index end
end
Use(sheet)
RPSheet:AddCoins(5000000)
for _, name in ipairs(R.TOOL_ORDER) do
    if R.ITEMS[name] then RPSheet:AddItem(name, 1) end
end
RPSheet:SheetChanged()
F.Settle(true)

---------------------------------------------------------------------------
-- Inventory
---------------------------------------------------------------------------
Try("inventory", function()
    -- an empty inventory first
    local items = RPSheet:Sheet().items
    local kept = {}
    for index, item in ipairs(items) do kept[index] = item end
    wipe(items)
    RPSheet:ToggleItemBrowser()
    F.Settle()
    Check("the item browser doesn't open", Shown())
    Check("its title", RPSheet.itemWindow.titleText:GetText() == RPSheet:GetCharacterName() .. " - Items")
    local empty
    for _, part in ipairs(Of("InteractiveLabel")) do
        if F.Plain(PartText(part)):find("^You carry nothing") then empty = F.Plain(PartText(part)) end
    end
    Check("an empty inventory doesn't say so", empty ~= nil)
    CheckView("empty inventory")
    for index, item in ipairs(kept) do items[index] = item end
    RPSheet:SheetChanged()
    F.Settle()
    Check("the open browser doesn't follow the sheet", #Cards() == math.min(24, #kept))

    -- the line saying whose merchant is selling: through every choice and back
    local function ShopRow()
        for _, part in ipairs(Of("InteractiveLabel")) do
            if F.Plain(PartText(part)):find("^Buying from") then return part end
        end
    end
    Check("no Buying from line for a character with renown", ShopRow() ~= nil)
    local seen = {}
    for _ = 1, 5 do
        seen[F.Plain(PartText(ShopRow()))] = true
        ClickPart("Buying from", ShopRow(), "LeftButton")
    end
    for _ = 1, 3 do ClickPart("Buying from (right)", ShopRow(), "RightButton") end
    local count = 0
    for _ in pairs(seen) do count = count + 1 end
    local wanted = #ns.ShopFactions(RPSheet:Sheet()) + 1
    Check(("the Buying from line went through %d choices, not %d"):format(count, wanted), count == math.min(5, wanted))
    Check("a discount isn't shown on the line", F.Plain(PartText(ShopRow())):find("%% off") ~= nil or RPSheet:ShopFaction() == nil)

    local function Snapshot(name)
        local item = RPSheet:CarriedItem(name)
        -- magic items are kept one by one, the rest in piles
        local qty = 0
        for _, other in ipairs(RPSheet:Sheet().items) do
            if other.name == name then qty = qty + other.qty end
        end
        return { qty = qty, equipped = item and item.equipped or false, attuned = item and item.attuned or false, coins = RPSheet:Coins() }
    end
    local function Effect(name, text, before)
        local now = Snapshot(name)
        local what = ("%s on %s: quantity %d to %d, coins %d to %d"):format(tostring(text), name, before.qty, now.qty, before.coins, now.coins)
        if text == "Add" or text == "Add one" then
            Check(what, now.qty == before.qty + 1 and now.coins == before.coins)
        elseif text == "Remove" then
            Check(what, now.qty < before.qty and now.coins == before.coins)
        elseif text == "Equip" then
            Check(what .. ", not equipped", now.equipped or #PRINTED > 0)
        elseif text == "Put away" then
            Check(what .. ", still equipped", not now.equipped)
        elseif text == "Attune" or text == "End attunement" then
            Check(what .. ", attunement unchanged", now.attuned ~= before.attuned or #PRINTED > 0)
        elseif tostring(text):find("^Buy") then
            Check(what, now.qty == before.qty + 1 and now.coins < before.coins)
        elseif tostring(text):find("^Sell") then
            Check(what, now.qty == before.qty - 1 and now.coins > before.coins)
        else
            Problem("a button the test doesn't know: " .. tostring(text))
        end
    end
    WalkTabs("inventory", empty, function(name, label)
        ClickButtons(label, 3, Snapshot, Effect)
        -- a button on a later page leaves the page where it was
        if Showing() and PageButton("Next").frame:IsEnabled() then
            ClickPart(label .. " Next", PageButton("Next"), "LeftButton")
            ClickButtons(label .. " page 2", 1, Snapshot, Effect)
            Check(label .. ": a button on page 2 went back to page 1", Showing() == 25)
        end
    end)
    -- the search over every tab: the button next to the box switches it on and off
    local function ModeButton() return PageButton("Search everything") or PageButton("This tab only") end
    ClickTab("Magic")
    local inTab = select(3, Showing())
    Check("no Search everything button", PageButton("Search everything") ~= nil)
    ClickPart("Search everything", PageButton("Search everything"), "LeftButton")
    Check("Search everything doesn't switch", PageButton("This tab only") ~= nil and OpenTabName() == nil)
    local everything = select(3, Showing())
    Check(("everything (%s) is not more than one tab (%s)"):format(tostring(everything), tostring(inTab)), (everything or 0) > (inTab or 0) + 1000)
    for turn = 1, 3 do
        ClickPart("everything Next", PageButton("Next"), "LeftButton")
        Check("everything: page " .. turn + 1 .. " starts at " .. tostring(Showing()), Showing() == turn * 24 + 1)
        CheckView("inventory, everything page " .. turn + 1)
    end
    RPSheet:AddItem("Potion of Healing")
    RPSheet:SheetChanged()
    F.Settle()
    Search("potion of healing")
    Check("a new search of everything doesn't start at its first page", (Showing() or 1) == 1)
    local tabsSeen = {}
    for _, card in ipairs(Cards()) do
        local title = F.Plain(card.titletext:GetText() or "")
        tabsSeen[title:match("%((%a+)") or "?"] = true
    end
    Check("a search of everything doesn't say which tab a block is from", tabsSeen.Magic and tabsSeen.Carried)
    ClickButtons("inventory, everything searched", 4, Snapshot, Effect)
    Search("zzqq")
    Check("a search of everything without a match shows blocks", #Cards() == 0)
    Search("")
    ClickPart("This tab only", PageButton("This tab only"), "LeftButton")
    Check("This tab only doesn't go back to the tab", PageButton("Search everything") ~= nil and OpenTabName() == "Magic" and select(3, Showing()) == inTab)
    ClickPart("Search everything", ModeButton(), "LeftButton")
    ClickTab("Armor")
    Check("clicking a tab doesn't leave the search of everything", PageButton("Search everything") ~= nil and OpenTabName() == "Armor")
    ClickTab("Carried")
    Check("Carried shows what was added", #Cards() > 3)
    ClickButtons("inventory tab Carried again", 4, Snapshot, Effect)
    Resize("inventory")
    ClickTab("Magic")
    Resize("inventory tab Magic")

    -- the window's own buttons
    local window = RPSheet.itemWindow
    F.Click(window.lockButton)
    Check("the padlock doesn't lock the item browser", window.locked == true and not window.sizer:IsShown())
    F.Click(window.lockButton)
    Check("the padlock doesn't unlock the item browser", window.locked == false and window.sizer:IsShown())
    F.Click(window.minimizeButton)
    F.MoveMouse(nil)
    F.Update(0.5)
    Check("the item browser doesn't fold", window.collapsed == true)
    RPSheet:SheetChanged() -- filled while folded
    F.Settle()
    F.MoveMouse(window.frame)
    F.Update(0.02)
    F.Settle()
    Check("the item browser doesn't open again", window.collapsed == false and #Cards() > 0)
    F.Click(window.minimizeButton)
    Check("the item browser stays minimized", window.minimized == false)
    CheckView("inventory after folding")
    F.Click(window.editButton)
    F.Settle()
    local dialog = AceConfigDialog.OpenFrames.RPSheet
    Check("the cog doesn't open the settings", dialog ~= nil)
    local status = AceConfigDialog:GetStatusTable("RPSheet")
    Check("the cog doesn't open the Customize tab", status.groups and status.groups.selected == "customize")
    AceConfigDialog:CloseAll()
    F.Settle()

    -- asking for it again closes it; OpenItemBrowser never does
    RPSheet:ToggleItemBrowser()
    Check("asking for the open browser again doesn't close it", not Shown())
    RPSheet:ToggleItemBrowser()
    F.Settle()
    Check("the browser doesn't reopen", Shown() and #Cards() > 0)
end)

---------------------------------------------------------------------------
-- Stable
---------------------------------------------------------------------------
Try("stable", function()
    RPSheet:ToggleMountBrowser()
    F.Settle()
    Check("the stable doesn't open over the item browser", Shown() and RPSheet.itemWindow.titleText:GetText():find("Stable"))
    local empty
    for _, part in ipairs(Of("InteractiveLabel")) do
        local text = F.Plain(PartText(part))
        if #Cards() == 0 and text:find("%S") and not text:find("^Buying") and not text:find("^Money") and not text:find("^Search") then empty = empty or text end
    end
    local function Snapshot(name)
        return { owned = RPSheet:OwnedMount(name) ~= nil, count = #RPSheet:Sheet().mounts, coins = RPSheet:Coins() }
    end
    local function Effect(name, text, before)
        local now = Snapshot(name)
        local what = ("%s on %s: mounts %d to %d, coins %d to %d"):format(tostring(text), name, before.count, now.count, before.coins, now.coins)
        if tostring(text):find("^Buy") then
            Check(what, (now.count == before.count + 1 and now.coins < before.coins) or #PRINTED > 0)
        elseif text == "Add" then
            Check(what, now.count == before.count + 1 and now.coins == before.coins)
        elseif text == "Remove" then
            Check(what, now.count == before.count - 1)
        end
    end
    WalkTabs("stable", nil, function(name, label) ClickButtons(label, 3, Snapshot, Effect) end)
    ClickTab(Tabs()[1].text:GetText())
    Check("the stable's first tab doesn't show what was added", #Cards() > 0)
    ClickButtons("stable first tab", 6, Snapshot, Effect)
    Resize("stable")
    F.Click(RPSheet.itemWindow.editButton)
    F.Settle()
    Check("the stable's cog doesn't open the settings", AceConfigDialog.OpenFrames.RPSheet ~= nil)
    AceConfigDialog:CloseAll()
    F.Settle()
end)

---------------------------------------------------------------------------
-- Crafting, with the Scrolls tab
---------------------------------------------------------------------------
Try("crafting", function()
    RPSheet:AddMaterials("herbs", 500000)
    RPSheet:AddMaterials("ore", 500000)
    RPSheet:AddMaterials("cloth", 500000)
    RPSheet:AddMaterials("leather", 500000)
    RPSheet:ShowCrafting()
    F.Settle()
    Check("the crafting window doesn't open", Shown() and RPSheet.itemWindow.titleText:GetText():find("Crafting"))
    local names = {}
    for _, tab in ipairs(Tabs()) do names[tab.text:GetText()] = true end
    Check("crafting has no Scrolls tab for a caster with Arcana", names.Scrolls)
    Check("crafting has " .. #Tabs() .. " tabs for a character with every tool", #Tabs() >= 5)
    local function Snapshot(name)
        local item = RPSheet:CarriedItem(name)
        return { qty = item and item.qty or 0, coins = RPSheet:Coins(), printed = #PRINTED }
    end
    local function Effect(name, text, before)
        local now = Snapshot(name)
        -- making takes coins or materials and adds the thing, or says why not
        Check(("%s on %s did nothing at all"):format(tostring(text), name), now.qty > before.qty or now.coins ~= before.coins or now.printed > before.printed)
    end
    WalkTabs("crafting", nil, function(name, label) ClickButtons(label, 3, Snapshot, Effect) end)
    -- opened on a profession's tab from the sheet
    local profession = RPSheet:Professions("make")[1]
    RPSheet:ShowCrafting(profession)
    F.Settle()
    Check("ShowCrafting(profession) doesn't open its tab", OpenTabName() == profession.tab.name)
    Check("ShowCrafting closed the window", Shown())
    Resize("crafting")
    F.Click(RPSheet.itemWindow.editButton)
    F.Settle()
    Check("crafting's cog doesn't open the settings", AceConfigDialog.OpenFrames.RPSheet ~= nil)
    AceConfigDialog:CloseAll()
    F.Settle()
end)

-- A character who may scribe but has no spell to put on a scroll: the Scrolls tab is
-- empty and must say so in its own words, not in those of the first tab.
Try("empty scrolls tab", function()
    local fighter = NewCharacter("WARRIOR", nil, nil, 2, 1)
    fighter.skills.Arcana = 1
    Use(fighter)
    Check("this character has spells to scribe", #RPSheet:ScribeSpells() == 0 and RPSheet:ScribeWays() ~= nil)
    RPSheet:ShowCrafting()
    F.Settle()
    local firstText
    for _, part in ipairs(Of("InteractiveLabel")) do
        local text = F.Plain(PartText(part))
        if text:find("^Nothing you can make") then firstText = text end
    end
    Check("the first crafting tab doesn't say that nothing can be made", firstText ~= nil)
    Check("no Scrolls tab", ClickTab("Scrolls"))
    CheckView("crafting, empty Scrolls tab", firstText)
    Search("fire")
    CheckView("crafting, empty Scrolls tab searched", firstText)
    Search("")
    RPSheet.itemWindow:Hide()
end)

---------------------------------------------------------------------------
-- The wizard's starting closet
---------------------------------------------------------------------------
Try("closet", function()
    Use(sheet)
    ns.OpenWizard()
    F.Settle()
    Check("the wizard doesn't open", AceConfigDialog.OpenFrames.RPSheetWizard ~= nil and W.draft ~= nil)
    W.draft.class, W.draft.species, W.draft.background = "WARRIOR", R.SPECIES_ORDER[1], R.BACKGROUND_ORDER[1]
    W.draft.base.STR = 15
    W.OpenCloset()
    F.Settle()
    Check("the closet doesn't open", Shown() and RPSheet.itemWindow.titleText:GetText() == "Starting gear")
    local empty
    for _, part in ipairs(Of("InteractiveLabel")) do
        if F.Plain(PartText(part)):find("^Nothing taken yet") then empty = F.Plain(PartText(part)) end
    end
    Check("an empty closet doesn't say so", empty ~= nil)
    local function Snapshot(name)
        return { count = W.draft.closet[name] or 0, worn = W.draft.worn[name] == true }
    end
    local function Effect(name, text, before)
        local now = Snapshot(name)
        local what = ("%s on %s: taken %d to %d"):format(tostring(text), name, before.count, now.count)
        if text == "Take" or text == "Take another" then
            Check(what, now.count == before.count + 1)
        elseif text == "Put back" then
            Check(what, now.count == before.count - 1 and (now.count > 0 or not now.worn))
        elseif text == "Equip" then
            Check(what .. ", not worn", now.worn and now.count >= 1)
        elseif text == "Put away" then
            Check(what .. ", still worn", not now.worn)
        else
            Problem("a closet button the test doesn't know: " .. tostring(text))
        end
    end
    WalkTabs("closet", empty, function(name, label)
        if name ~= "Taken" then ClickButtons(label, 3, Snapshot, Effect) end
    end)
    -- take a few, then the Taken tab lists them and its buttons work
    ClickTab("Weapons")
    for _, card in ipairs(Cards()) do
        if #Cards() > 0 and CardName(card) then W.TakeItem(CardName(card), 1) end
        if (W.ClosetTotals()) > 0 and next(W.draft.closet) and #W.Taken("Weapons and ammunition") >= 3 then break end
    end
    W.ClosetChanged()
    F.Settle()
    ClickTab("Taken")
    Check("the Taken tab doesn't list what was taken", #Cards() >= 3)
    local standing = F.Plain(PartText(Body().children[1]))
    Check("the closet's top line doesn't count what was taken: " .. standing:sub(1, 60), standing:find("^Taken: worth") and not standing:find("worth 0 cp"))
    ClickButtons("closet tab Taken", 3, Snapshot, Effect)
    Resize("closet")
    -- the wizard's own page follows
    CheckHidden("closet")
    -- the wizard is given up: the closet goes with it
    W.draft = nil
    RPSheet:PopulateItemBrowser()
    F.Settle()
    Check("the closet stays open after the wizard is gone", not Shown())
    AceConfigDialog:CloseAll()
    F.Settle()
    -- and the inventory can be opened again afterwards
    RPSheet:ToggleItemBrowser()
    F.Settle()
    Check("the item browser doesn't open after the closet", Shown() and RPSheet.itemWindow.titleText:GetText():find("Items"))
    RPSheet.itemWindow:Hide()
end)

SmokeChecks("after the browser tests")
Finish("browser", ("%d tabs, %d page turns, %d searches, %d block buttons clicked, %d blocks checked, %d widths"):format(
    stats.tabs, stats.pages, stats.searches, stats.buttons, stats.blocks, stats.widths))
