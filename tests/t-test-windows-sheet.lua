-- The sheet window, really built: every class at a few levels and some multiclass
-- characters; every tab; every row hovered (its tooltip must build and have a title)
-- and clicked with both mouse buttons, with Shift, Ctrl and Alt, and on its "[?]".
-- After every tab is filled its rows must not lie over each other, and rows that
-- share a line must stand on one line.
-- usage: run.sh t-test-windows-sheet.lua [quick]
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local LEVELS = ARG4 == "quick" and { 3, 12 } or { 1, 5, 11, 20 }
local TABS = { "Actions", "Checks", "Skills", "Traits", "Items", "Trade" }
local saved = RPSheet.db.char
local characters, tabsOpened = 0, 0

local function CloseExtras()
    for _, key in ipairs({ "itemWindow", "bookWindow", "preparedWindow", "fightWindow" }) do
        local window = RPSheet[key]
        if window and window.frame:IsShown() then window:Hide() end
    end
    if next(AceConfigDialog.OpenFrames) then AceConfigDialog:CloseAll() end
    ns.Wizard.draft = nil
    if not RPSheet.window.frame:IsShown() then RPSheet.window:Show() end
end

local function Rows() return RPSheet.body.children end

-- The rows above the tab buttons, and the rows below them.
local function Split()
    local top, below, seenTab = {}, {}, false
    for _, part in ipairs(Rows()) do
        if part.type == "RPSheetTab" then
            seenTab = true
        elseif seenTab then
            below[#below + 1] = part
        else
            top[#top + 1] = part
        end
    end
    return top, below
end

local function Outfit()
    for _, name in ipairs({ "Longsword", "Longbow", "Dagger", "Shield", "Chain Mail", "Rope", "Potion of Healing" }) do
        local item = RPSheet:AddItem(name, 1)
        if item then RPSheet:SetEquipped(item, true) end
    end
    RPSheet:AddCoins(12345)
    RPSheet:SheetChanged()
    F.Settle()
end

local function Walk(label, key)
    local options = { key = key, skip = { RPSheetTab = true }, after = CloseExtras, printed = PRINTED }
    for index, tab in ipairs(TABS) do
        saved.sheetTab = tab
        Try(label .. " tab " .. tab, function() RPSheet:Populate(); F.Settle() end)
        tabsOpened = tabsOpened + 1
        local where = ("%s tab %s"):format(label, tab)
        -- the open tab is the one asked for
        local open
        for _, part in ipairs(Rows()) do
            if part.type == "RPSheetTab" and part.open then open = part.text:GetText() end
        end
        if open ~= tab then Problem(where .. ": the open tab is " .. tostring(open)) end
        CheckOverlap(RPSheet.body, where)
        CheckFlowRows(RPSheet.body, where)
        -- the part above the tabs is the same on every tab: walked once
        if index == 1 then
            WalkRows(function() return (Split()) end, where .. " top", options)
        end
        WalkRows(function() local _, below = Split() return below end, where, options)
        -- the tab buttons themselves: hovered here, clicked below
        for _, part in ipairs(Rows()) do
            if part.type == "RPSheetTab" then HoverPart(where .. " tab button " .. tostring(part.text:GetText()), part) end
        end
    end
    -- clicking through the tab strip
    for _, tab in ipairs(TABS) do
        for _, part in ipairs(Rows()) do
            if part.type == "RPSheetTab" and part.text:GetText() == tab then
                ClickPart(label .. " click tab " .. tab, part, "LeftButton")
                break
            end
        end
        if saved.sheetTab ~= tab then Problem(label .. ": clicking the tab " .. tab .. " left " .. tostring(saved.sheetTab) .. " open") end
    end
    Try(label .. " delayed timers", F.Settle, true)
    Dismiss()
    CheckHidden(label)
    SmokeChecks(label)
end

local n = 0
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    for _, level in ipairs(LEVELS) do
        n = n + 1
        local subclass = class.subclasses[n % #class.subclasses + 1]
        local label = ("%s/%s L%d"):format(key, (level >= 3 or class.hero) and subclass or "", level)
        local sheet = Try(label .. " build", NewCharacter, key, subclass, nil, level, n)
        if sheet then
            Try(label .. " use", Use, sheet)
            Try(label .. " outfit", Outfit)
            local began = os.clock()
            -- a row that reads the same at a higher level of the class is clicked once
            Walk(label, key)
            characters = characters + 1
            if ARG5 == "progress" then print(("%s: %.1fs, %d clicks so far"):format(label, os.clock() - began, COUNT.clicks)) io.stdout:flush() end
        end
    end
end

-- Characters with two and three classes.
local MULTI = {
    { "WARRIOR", 5, { MAGE = 3 } }, { "PALADIN", 6, { WARLOCK = 2, ROGUE = 2 } }, { "DRUID", 4, { MONK = 4 } },
    { "PRIEST", 3, { SHAMAN = 3, HUNTER = 3 } }, { "ROGUE", 11, { MAGE = 9 } },
}
for index, entry in ipairs(MULTI) do
    local key, own, others = entry[1], entry[2], entry[3]
    if R.CLASSES[key] then
        local total, names = own, { key .. own }
        local sheet = Try("multiclass build", NewCharacter, key, nil, nil, own, index)
        sheet.classes = {}
        for other, level in pairs(others) do
            if R.CLASSES[other] then
                local class = R.CLASSES[other]
                sheet.classes[other] = { level = level, subclass = (level >= 3 or class.hero) and class.subclasses[1] or "", spec = class.specs[1],
                    skill = "", fightingStyle = "", fightingStyle2 = "" }
                total = total + level
                names[#names + 1] = other .. level
            end
        end
        sheet.level = total
        local label = "multi " .. table.concat(names, "+")
        Try(label .. " use", Use, sheet)
        Try(label .. " outfit", Outfit)
        Walk(label, label)
        characters = characters + 1
    end
end

-- At 0 hit points the death save row appears; a character without a class offers the wizard.
Try("down", function()
    Use(NewCharacter("WARRIOR", nil, nil, 5, 1))
    RPSheet:State().hp = 0
    RPSheet:SheetChanged()
    F.Settle()
    saved.sheetTab = "Actions"
    RPSheet:Populate()
    if not RPSheet.deathLabel then Problem("at 0 hit points the sheet shows no death save row") end
    WalkRows(function() return (Split()) end, "at 0 HP top", { after = CloseExtras, printed = PRINTED })
end)
-- With no weapon in hand the attack row is the Unarmed Strike; a right-click opens the Items tab.
Try("no weapon", function()
    local sheet = NewCharacter("WARRIOR", nil, nil, 5, 1)
    sheet.weapons = {}
    Use(sheet)
    saved.sheetTab = "Checks"
    RPSheet:Populate()
    local row
    for _, part in ipairs((Split())) do
        local text = part.label and part.label.GetText and part.label:GetText() or (part.GetText and part:GetText()) or ""
        if tostring(text):find("Unarmed Strike", 1, true) then row = part end
    end
    if not row then Problem("without a weapon the sheet shows no Unarmed Strike row") return end
    WalkRows(function() return (Split()) end, "no weapon top", { after = CloseExtras, printed = PRINTED })
    if saved.sheetTab ~= "Items" then Problem("a click on the row didn't open the Items tab: " .. tostring(saved.sheetTab)) end
end)
Try("no class", function()
    RPSheet:ReplaceSheet(ns.NewSheet())
    F.Settle()
    RPSheet:Populate()
    WalkRows(Rows, "no class", { skip = { RPSheetTab = true }, after = CloseExtras, printed = PRINTED })
end)

Finish("sheet", ("%d characters, %d tabs opened, %d rows hovered (%d tooltips), %d clicks, %d explanations"):format(
    characters, tabsOpened, COUNT.rows, COUNT.tips, COUNT.clicks, COUNT.explains))
