-- The small windows and popups: the damage menu (every row) and the amount box, the
-- heal box, the coin box, the condition menu, the spellbook window with the cantrip
-- exchange, and the window for changing prepared spells. Amounts are typed and
-- accepted the way a player does it, and the result on the sheet is checked.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local saved = RPSheet.db.char
local stats = { menuRows = 0, popups = 0, conditions = 0, bookRows = 0, preparedRows = 0 }
local function Check(what, ok) if not ok then Problem(what) end end

-- The row of the sheet whose text starts with `text`.
local function Row(text)
    for _, part in ipairs(RPSheet.body.children) do
        if F.Plain(PartText(part)):find(text, 1, true) == 1 then return part end
    end
end
local function Tab(name)
    saved.sheetTab = name
    RPSheet:Populate()
    F.Settle()
end
local function HP() return RPSheet:State().hp or RPSheet:MaxHP() end
local function FullHP()
    local state = RPSheet:State()
    state.hp, state.tempHP = RPSheet:MaxHP(), 0
    RPSheet:ClearDeathSaves()
    RPSheet.busy = false
    RPSheet:SheetChanged()
    F.Settle(true)
end

---------------------------------------------------------------------------
-- Damage and healing
---------------------------------------------------------------------------
Try("damage", function()
    local sheet = NewCharacter("WARRIOR", nil, nil, 9, 1)
    sheet.base.CON = 16
    Use(sheet)
    -- resistances of every kind, from a passive
    local passives = RPSheet:Sheet().passives
    passives[#passives + 1] = { name = "Test hide", desc = "", enabled = true, effects = {},
        resist = { "fire" }, immune = { "poison" }, vulnerable = { "cold" } }
    FullHP()
    local defenses = RPSheet:Defenses()
    Check("the test passive gives no resistance", defenses.resist.fire and defenses.immune.poison and defenses.vulnerable.cold)
    local max = RPSheet:MaxHP()
    Check("a level 9 warrior has " .. max .. " hit points", max > 60)
    Tab("Actions")

    -- the menu: a title, every damage type, "No type"
    local row = Row("Take damage")
    Check("no Take damage row", row ~= nil)
    ClickPart("Take damage", row, "LeftButton")
    Check("clicking Take damage opens no menu", F.menu ~= nil)
    Check("the menu belongs to another frame", F.menu.owner == row.frame)
    local titles = F.MenuTitles()
    Check("the damage menu has no title", #titles == 1 and titles[1] == "Take damage of which type?")
    local labels = {}
    for _, item in ipairs(F.MenuRows()) do labels[#labels + 1] = F.Plain(item.text) end
    Check(("the damage menu has %d rows for %d damage types"):format(#labels, #R.DAMAGE_TYPES), #labels == #R.DAMAGE_TYPES + 2 + #RPSheet:DamageExtras())
    local text = table.concat(labels, "|")
    Check("the menu doesn't say fire is resisted: " .. text, text:find("Fire (resisted)", 1, true))
    Check("the menu doesn't say poison is immune", text:find("Poison (immune)", 1, true))
    Check("the menu doesn't say cold is vulnerable", text:find("Cold (vulnerable)", 1, true))
    Check("the menu has no row without a type", labels[#R.DAMAGE_TYPES + 1] == "No type")
    Check("the menu has no row for a fall", labels[#R.DAMAGE_TYPES + 2] == "A fall")

    -- every row: the box asks, 10 is typed and accepted
    for index, label in ipairs(labels) do
        FullHP()
        Tab("Actions")
        ClickPart("Take damage", Row("Take damage"), "LeftButton")
        local item = F.MenuRows()[index]
        Try("menu row " .. label, F.MenuClick, item)
        stats.menuRows = stats.menuRows + 1
        local kind = R.DAMAGE_TYPES[index]
        if not F.popup then
            Problem("the damage menu row " .. label .. " opens no box")
        else
            stats.popups = stats.popups + 1
            local question = F.PopupText() or ""
            CheckText("damage box " .. label, question)
            if kind then Check("the box for " .. kind .. " doesn't name it: " .. question, question:find(kind .. " damage", 1, true)) end
            Check("the box isn't empty when it opens", F.popup.EditBox:GetText() == "")
            Check("the box doesn't take the keyboard", F.popup.EditBox:HasFocus())
            Try("type 10 for " .. label, F.PopupType, "10")
            Try("accept " .. label, F.PopupAccept)
            F.Settle()
            Check("the box stays open after Accept", F.popup == nil)
            local lost = max - HP()
            local wanted = (kind == "fire" and 5) or (kind == "poison" and 0) or (kind == "cold" and 20) or 10
            -- a fall of 10 feet is 1d6
            if label == "A fall" then wanted = (lost >= 1 and lost <= 6) and lost or "1 to 6" end
            if lost ~= wanted then Problem(("10 %s damage took %d hit points, not %d"):format(tostring(kind or label), lost, wanted)) end
        end
        CheckHidden("damage row " .. label)
    end

    -- the box: Enter accepts, only four digits fit, letters count as nothing
    local function Ask(kind)
        FullHP()
        Tab("Actions")
        ClickPart("Take damage", Row("Take damage"), "LeftButton")
        F.MenuClick(kind)
        stats.popups = stats.popups + 1
    end
    Ask("Slashing")
    F.PopupType("7", true)
    F.Settle()
    Check("Enter in the box doesn't deal the damage", max - HP() == 7 and F.popup == nil)
    Ask("Slashing")
    F.PopupType("12 points")
    F.PopupAccept()
    F.Settle()
    Check("'12 points' isn't read as 12", max - HP() == 12)
    Ask("Slashing")
    F.PopupType("lots")
    local printed = #PRINTED
    F.PopupAccept()
    F.Settle()
    Check("letters in the box changed the hit points", HP() == max)
    Check("letters in the box give no hint", #PRINTED > printed)
    Ask("Slashing")
    F.PopupAccept()
    F.Settle()
    Check("an empty box changed the hit points", HP() == max)
    Ask("Slashing")
    F.PopupType("5")
    F.PopupEscape()
    F.Settle()
    Check("Escape dealt the damage", HP() == max and F.popup == nil)
    Ask("Slashing")
    F.PopupType("5")
    F.PopupCancel()
    F.Settle()
    Check("Cancel dealt the damage", HP() == max and F.popup == nil)
    Ask("Slashing")
    F.PopupType("123456")
    Check("the box takes more than four digits", F.popup.EditBox:GetText() == "1234")
    F.PopupAccept()
    F.Settle()
    Check("1234 damage leaves hit points", HP() == 0)
    CheckText("death save row", RPSheet.deathLabel and RPSheet.deathLabel:GetText() or "nil")
    Check("at 0 hit points the sheet shows no death save row", RPSheet.deathLabel ~= nil)

    -- temporary hit points go first
    FullHP()
    RPSheet:State().tempHP = 5
    Tab("Actions")
    ClickPart("Take damage", Row("Take damage"), "LeftButton")
    F.MenuClick("No type")
    F.PopupType("7", true)
    F.Settle()
    Check(("7 damage with 5 temporary hit points: %d lost, %d temporary left"):format(max - HP(), RPSheet:State().tempHP), max - HP() == 2 and RPSheet:State().tempHP == 0)

    -- healing: the box, stops at the maximum
    RPSheet:State().hp = 10
    Tab("Actions")
    ClickPart("Heal", Row("Heal"), "LeftButton")
    Check("clicking Heal opens no menu", F.menu ~= nil)
    F.MenuClick("Type the amount")
    Check("clicking Heal opens no box", F.popup ~= nil)
    Check("the heal box asks: " .. tostring(F.PopupText()), (F.PopupText() or ""):find("regain", 1, true))
    F.PopupType("8", true)
    F.Settle()
    Check("healing 8 from 10 gives " .. HP(), HP() == 18)
    ClickPart("Heal", Row("Heal"), "LeftButton")
    F.MenuClick("Type the amount")
    F.PopupType("9999")
    F.PopupAccept()
    F.Settle()
    Check("healing goes past the maximum", HP() == max)
    ClickPart("Heal", Row("Heal"), "LeftButton")
    F.MenuClick("Type the amount")
    F.PopupType("-3")
    F.PopupAccept()
    F.Settle()
    Check("a healing of -3 changed the hit points", HP() == max)

    -- the same by slash command
    RPSheet:SlashCommand("damage 14 fire")
    F.Settle()
    Check("/sheet damage 14 fire took " .. (max - HP()), max - HP() == 7)
    RPSheet:SlashCommand("heal 3")
    F.Settle()
    Check("/sheet heal 3", max - HP() == 4)
    RPSheet:SlashCommand("damage")
    RPSheet:SlashCommand("damage x")
    RPSheet:SlashCommand("heal")
    F.Settle()
    Check("a slash command without an amount changed the hit points", max - HP() == 4)
    FullHP()
end)

-- Every protective spell the sheet knows, each of its options switched on in turn:
-- the menu grows rows for the ones that roll dice or guard someone; each is clicked,
-- and damage of a type the spell takes dice off is taken through the box.
Try("damage menu extras", function()
    Use(NewCharacter("PRIEST", nil, nil, 13, 1))
    local spells = {}
    for spell in pairs(R.SPELL_WARDS) do spells[#spells + 1] = spell end
    table.sort(spells)
    local wards, extraRows = 0, 0
    for _, spell in ipairs(spells) do
        for index, option in ipairs(R.SPELL_WARDS[spell]) do
            local label = ("%s option %d"):format(spell, index)
            RPSheet:EndWards()
            FullHP()
            Try(label .. " start", function() RPSheet:StartWard(spell, index) end)
            RPSheet:SheetChanged()
            F.Settle(true)
            wards = wards + 1
            local extras = #RPSheet:DamageExtras()
            local function Menu()
                RPSheet.busy = false
                Tab("Actions")
                ClickPart(label .. " Take damage", Row("Take damage"), "LeftButton")
                return F.MenuRows()
            end
            local function Answer(what)
                if F.popup then
                    CheckText(what .. " box", F.PopupText())
                    Try(what .. " type", F.PopupType, "9")
                    Try(what .. " accept", F.PopupAccept)
                end
                Try(what .. " settle", F.Settle, true)
                CheckHidden(what)
                Dismiss()
            end
            local rows = Menu()
            Check(label .. ": the menu has " .. #rows .. " rows", #rows == #R.DAMAGE_TYPES + 2 + extras)
            for at = #R.DAMAGE_TYPES + 3, #rows do
                local item = Menu()[at]
                if item then
                    extraRows = extraRows + 1
                    stats.menuRows = stats.menuRows + 1
                    CheckText(label .. " damage menu", item.text)
                    Try(label .. " menu row " .. F.Plain(item.text), F.MenuClick, item)
                    Answer(label .. " row " .. F.Plain(item.text))
                end
            end
            -- damage the spell works against, through the ordinary rows
            local kinds = option.reduce or option.resist or option.immune or {}
            for at = 1, math.min(2, #kinds) do
                local kind = kinds[at]
                Menu()
                local before = HP()
                Try(label .. " " .. kind, F.MenuClick, kind:sub(1, 1):upper() .. kind:sub(2))
                Answer(label .. " " .. kind)
                stats.menuRows = stats.menuRows + 1
                if HP() > before then Problem(label .. ": taking " .. kind .. " damage raised the hit points") end
            end
            HoverPart(label .. " defenses", Row("Take damage"))
            WalkRows(function() return RPSheet.body.children end, label, { key = "wards", skip = { RPSheetTab = true }, variants = 2,
                after = function() F.menu = nil end, printed = PRINTED })
        end
    end
    RPSheet:EndWards()
    Check("no protective spell added a row to the damage menu", extraRows > 0)
    stats.wards = wards
    SmokeChecks("after the protective spells")
end)

---------------------------------------------------------------------------
-- Coins
---------------------------------------------------------------------------
Try("coins", function()
    Use(NewCharacter("ROGUE", nil, nil, 4, 2))
    Tab("Items")
    local function Coins() return RPSheet:Coins() end
    local function Box(spend, text, enter)
        Tab("Items")
        local row = Row("Coins")
        Check("no Coins row on the Items tab", row ~= nil)
        ClickPart("Coins", row, spend and "RightButton" or "LeftButton")
        if not F.popup then Problem("clicking Coins opens no box") return end
        stats.popups = stats.popups + 1
        local question = F.PopupText() or ""
        CheckText("coin box", question)
        Check("the coin box asks the wrong thing: " .. question, question:find(spend and "^Spend how much" or "^Add how much") ~= nil)
        Check("the coin box isn't empty when it opens", F.popup.EditBox:GetText() == "")
        F.PopupType(text, enter)
        if not enter then F.PopupAccept() end
        F.Settle()
        Check("the coin box stays open", F.popup == nil)
        CheckHidden("coin box " .. text)
    end
    local start = Coins()
    Box(false, "5 gp 3 sp")
    Check(("adding 5 gp 3 sp gave %d copper"):format(Coins() - start), Coins() - start == 530)
    Box(false, "7", true)
    Check(("adding 7 gave %d copper, not 7 gp"):format(Coins() - start), Coins() - start == 530 + 700)
    Box(true, "2 gp", true)
    Check(("spending 2 gp left %d copper more than at the start"):format(Coins() - start), Coins() - start == 530 + 700 - 200)
    local before, printed = Coins(), #PRINTED
    Box(false, "a pile")
    Check("'a pile' changed the purse", Coins() == before)
    Check("'a pile' gives no hint", #PRINTED > printed)
    printed = #PRINTED
    Box(true, "99999 gp")
    Check("spending more than there is changed the purse", Coins() == before)
    Check("spending more than there is gives no hint", #PRINTED > printed)
    Box(false, "")
    Check("an empty coin box changed the purse", Coins() == before)
    Box(false, "20 gp")
    before = Coins()
    Box(true, "1 pp 1 ep 1 sp 1 cp", true)
    Check(("spending 1 pp 1 ep 1 sp 1 cp took %d copper"):format(before - Coins()), before - Coins() == 1000 + 50 + 10 + 1)
    -- the row shows the purse
    Tab("Items")
    CheckText("coins row", PartText(Row("Coins")))
    -- cancelled
    before = Coins()
    ClickPart("Coins", Row("Coins"), "LeftButton")
    F.PopupType("50 gp")
    F.PopupEscape()
    F.Settle()
    Check("Escape added the coins", Coins() == before and F.popup == nil)
end)

---------------------------------------------------------------------------
-- Conditions
---------------------------------------------------------------------------
Try("conditions", function()
    Use(NewCharacter("MONK", nil, nil, 6, 3))
    Tab("Actions")
    local state = RPSheet:State()
    ClickPart("Conditions", Row("Conditions"), "LeftButton")
    Check("clicking Conditions opens no menu", F.menu ~= nil)
    local titles = F.MenuTitles()
    Check("the condition menu has no title", #titles == 1 and titles[1] == "Conditions")
    local rows = F.MenuRows()
    Check(("the condition menu has %d rows for %d conditions"):format(#rows, #R.CONDITIONS), #rows == #R.CONDITIONS)
    for index, condition in ipairs(R.CONDITIONS) do
        local item = rows[index]
        stats.conditions = stats.conditions + 1
        Check("row " .. index .. " of the condition menu is " .. tostring(item.text), item.text == condition.name and item.kind == "checkbox")
        -- its tooltip
        Check("the condition " .. condition.name .. " has no tooltip", Try("hover " .. condition.name, F.MenuHover, item))
        local lines = F.TooltipLines()
        Check("tooltip of " .. condition.name, lines and lines[1].text == condition.name and lines[2] and lines[2].text ~= "")
        GameTooltip:Hide()
        -- ticking and unticking
        Check(condition.name .. " is ticked at the start", item.isSelected() == false)
        Try("tick " .. condition.name, F.MenuClick, item)
        Check("ticking " .. condition.name .. " doesn't set it", state.conditions[condition.name] == true and item.isSelected() == true)
        Check("the menu closed on a tick", F.menu ~= nil)
        F.Settle()
        local shown = F.Plain(PartText(Row("Conditions")))
        Check("the sheet doesn't show " .. condition.name .. ": " .. shown, shown:find(condition.name, 1, true))
        HoverPart("conditions row with " .. condition.name, Row("Conditions"))
        SmokeChecks("under " .. condition.name)
        Try("untick " .. condition.name, F.MenuClick, item)
        Check("unticking " .. condition.name .. " doesn't clear it", not state.conditions[condition.name] and item.isSelected() == false)
        F.Settle()
        CheckHidden("condition " .. condition.name)
    end
    -- all at once
    for _, item in ipairs(rows) do F.MenuClick(item) end
    F.Settle()
    SmokeChecks("under every condition")
    Tab("Actions")
    WalkRows(function() return RPSheet.body.children end, "under every condition", { skip = { RPSheetTab = true }, variants = 2, after = function() F.menu = nil end, printed = PRINTED })
    for _, item in ipairs(rows) do
        if item.isSelected() then F.MenuClick(item) end
    end
    F.Settle()
    Check("conditions are left over", #RPSheet:Conditions() == 0)
    -- exhaustion: left adds, right takes away, never below 0
    Tab("Actions")
    ClickPart("Exhaustion", Row("Exhaustion"), "LeftButton")
    ClickPart("Exhaustion", Row("Exhaustion"), "LeftButton")
    Check("two clicks give exhaustion " .. RPSheet:Exhaustion(), RPSheet:Exhaustion() == 2)
    for _ = 1, 4 do ClickPart("Exhaustion", Row("Exhaustion"), "RightButton") end
    Check("exhaustion goes below 0", RPSheet:Exhaustion() == 0)
end)

---------------------------------------------------------------------------
-- The spellbook window and the cantrip exchange
---------------------------------------------------------------------------
local function BookRows() return RPSheet.bookBody.children end
local function BookRow(text)
    for _, part in ipairs(BookRows()) do
        if F.Plain(PartText(part)):find(text, 1, true) == 1 then return part end
    end
end

Try("spellbook", function()
    Use(NewCharacter("MAGE", nil, nil, 9, 2))
    local sheet = RPSheet:Sheet()
    Check("the mage has no spellbook", ns.HasSpellbook(sheet) and #ns.SpellbookNames(sheet) >= 6)
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    RPSheet:ToggleSpellbook()
    F.Settle()
    local window = RPSheet.bookWindow
    Check("the spellbook doesn't open", window and window.frame:IsShown())
    Check("the spellbook's title", window.titleText:GetText() == RPSheet:GetCharacterName() .. " - Spellbook")
    CheckOverlap(RPSheet.bookBody, "spellbook")
    local names = ns.SpellbookNames(sheet)
    for _, name in ipairs(names) do
        Check("the spellbook has no row for " .. name, BookRow(name) ~= nil)
    end
    local count = F.Plain(PartText(BookRows()[1]))
    local _, limit = RPSheet:SpellLimits(ns.BookClass(sheet))
    local _, prepared = RPSheet:SpellCounts(nil, ns.BookClass(sheet))
    Check("the spellbook's first line: " .. count, count == ("Prepared %d of %d, from %d spells in the book."):format(prepared, limit, #names))

    -- right-click prepares and puts away
    local changed = 0
    for _, name in ipairs(names) do
        local was = RPSheet:PreparedSpell(name) ~= nil
        local printed = #PRINTED
        ClickPart("spellbook right-click " .. name, BookRow(name), "RightButton")
        stats.bookRows = stats.bookRows + 1
        local now = RPSheet:PreparedSpell(name) ~= nil
        if now ~= was then
            changed = changed + 1
            local text = F.Plain(PartText(BookRow(name)))
            Check(name .. " is " .. (now and "prepared" or "put away") .. " but its row says: " .. text, (text:find("not prepared", 1, true) == nil) == now)
        elseif #PRINTED == printed then
            Problem("right-clicking " .. name .. " in the spellbook neither changed it nor said why")
        end
    end
    Check("right-clicking the spellbook's spells changed none of them", changed > 0)
    local _, preparedNow = RPSheet:SpellCounts(nil, ns.BookClass(sheet))
    Check("more spells are prepared than allowed: " .. preparedNow .. " of " .. limit, preparedNow <= limit)
    count = F.Plain(PartText(BookRows()[1]))
    Check("the spellbook's count doesn't follow: " .. count, count:find(("^Prepared %d of %d"):format(preparedNow, limit)) ~= nil)

    -- the cantrip exchange, in the time after a long rest
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    local known, offered = RPSheet:BookCantrips()
    Check("the mage knows no cantrips", #known >= 3)
    Check("cantrips are on offer before one is given up", #offered == 0)
    local given = known[1]
    ClickPart("give up " .. given, BookRow(given), "RightButton")
    known, offered = RPSheet:BookCantrips()
    Check("giving up a cantrip offers none in its place", #offered > 0)
    -- the one given up may be on offer too, to take it back; another one is taken
    local taken = offered[1] ~= given and offered[1] or offered[2]
    local function Offer(name)
        for _, part in ipairs(BookRows()) do
            if F.Plain(PartText(part)) == name .. "  can be learned" then return part end
        end
    end
    local offer = Offer(taken)
    Check("no row for the offered cantrip " .. tostring(taken), offer ~= nil)
    HoverPart("offered cantrip", offer)
    local printed = #PRINTED
    ClickPart("left-click the offered " .. taken, offer, "LeftButton")
    Check("left-clicking an offered cantrip says nothing", #PRINTED > printed)
    ClickPart("learn " .. taken, Offer(taken), "RightButton")
    known, offered = RPSheet:BookCantrips()
    local has, still = false, false
    for _, name in ipairs(known) do
        if name == taken then has = true end
        if name == given then still = true end
    end
    Check(("after the exchange %s is known: %s, %s is known: %s"):format(taken, tostring(has), given, tostring(still)), has and not still)
    Check("cantrips stay on offer after the exchange", #offered == 0)
    CheckText("cantrip status", RPSheet:CantripStatus())
    -- a second exchange in the same rest is refused, with a word why
    printed = #PRINTED
    ClickPart("second exchange", BookRow(known[1] == taken and known[2] or known[1]), "RightButton")
    local _, again = RPSheet:BookCantrips()
    Check("a second cantrip can be exchanged in one rest", #again == 0 or #PRINTED > printed)
    F.Settle(true)

    -- every row: hovered and clicked every way
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    WalkRows(BookRows, "spellbook", { printed = PRINTED, after = function() RPSheet.busy = false end })
    stats.bookRows = stats.bookRows + #BookRows()
    CheckOverlap(RPSheet.bookBody, "spellbook after the clicks")

    -- its own title buttons
    F.Click(window.lockButton)
    Check("the padlock doesn't lock the spellbook", window.locked == true)
    F.Click(window.lockButton)
    F.Click(window.minimizeButton)
    Check("minus doesn't minimize the spellbook", window.minimized == true)
    F.Click(window.minimizeButton)
    F.Click(window.editButton)
    F.Settle()
    Check("the spellbook's cog doesn't open the settings", AceConfigDialog.OpenFrames.RPSheet ~= nil)
    local status = AceConfigDialog:GetStatusTable("RPSheet", { "customize" })
    Check("the spellbook's cog doesn't open the Spellbook page: " .. tostring(status.groups and status.groups.selected), status.groups and status.groups.selected == "spellbook")
    AceConfigDialog:CloseAll()
    F.Settle()
    for width = 340, 700, 60 do
        window.frame:SetWidth(width)
        F.Settle()
        F.Fire(window.sizer, "OnMouseUp", "LeftButton")
        F.Settle()
        CheckOverlap(RPSheet.bookBody, "spellbook at width " .. width)
    end

    -- another character: the open window follows
    Use(NewCharacter("WARRIOR", nil, nil, 5, 1))
    Check("the spellbook of a warrior: " .. F.Plain(PartText(BookRows()[1])), F.Plain(PartText(BookRows()[1])) == "This character keeps no spellbook.")
    RPSheet:ToggleSpellbook()
    Check("the spellbook doesn't close", not window.frame:IsShown())
    -- a multiclass mage: the book's spells are prepared as the mage's
    local multi = NewCharacter("WARRIOR", nil, nil, 3, 1)
    multi.classes = { MAGE = { level = 5, subclass = R.CLASSES.MAGE.subclasses[1], spec = R.CLASSES.MAGE.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" } }
    multi.level = 8
    Use(multi)
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    RPSheet:ToggleSpellbook()
    F.Settle()
    Check("a warrior with mage levels has no spellbook rows", #BookRows() > 5)
    WalkRows(BookRows, "spellbook of a warrior/mage", { printed = PRINTED, variants = 2, after = function() RPSheet.busy = false end })
    RPSheet:ToggleSpellbook()
end)

---------------------------------------------------------------------------
-- The window for changing prepared spells
---------------------------------------------------------------------------
local function PreparedRows() return RPSheet.preparedBody.children end

local function PreparedRun(label, sheet)
    Use(sheet)
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    if not (RPSheet.preparedWindow and RPSheet.preparedWindow.frame:IsShown()) then RPSheet:TogglePreparedWindow() end
    F.Settle()
    local window = RPSheet.preparedWindow
    Check(label .. ": the window doesn't open", window and window.frame:IsShown())
    Check(label .. ": title", window.titleText:GetText() == RPSheet:GetCharacterName() .. " - Prepared spells")
    CheckOverlap(RPSheet.preparedBody, label)
    local entries = ns.RestPreparers(RPSheet:Sheet())
    if #entries == 0 then
        Check(label .. ": says " .. F.Plain(PartText(PreparedRows()[1])), F.Plain(PartText(PreparedRows()[1])):find("doesn't change prepared spells", 1, true))
        return
    end
    -- right-click every spell once: it changes, or a word says why not
    for at, entry in ipairs(entries) do
        local picks = RPSheet:Sheet().picks[entry.key] or {}
        local changed, refused = 0, 0
        for _, name in ipairs(ns.PreparedChoices(RPSheet:Sheet(), entry)) do
            -- two classes can list the same spell: this class's row is the one after
            -- the rows of the classes before it
            local skip = 0
            for earlier = 1, at - 1 do
                for _, other in ipairs(ns.PreparedChoices(RPSheet:Sheet(), entries[earlier])) do
                    if other == name then skip = skip + 1 end
                end
            end
            local row
            for _, part in ipairs(PreparedRows()) do
                local text = F.Plain(PartText(part))
                if text:find(name .. "  ", 1, true) == 1 and part.events.OnClick then
                    if skip == 0 then row = part break end
                    skip = skip - 1
                end
            end
            if not row then
                Problem(label .. ": no row for " .. name)
            else
                local was, printed = picks[name] == true, #PRINTED
                ClickPart(label .. " right-click " .. name, row, "RightButton")
                stats.preparedRows = stats.preparedRows + 1
                picks = RPSheet:Sheet().picks[entry.key] or {}
                if (picks[name] == true) ~= was then
                    changed = changed + 1
                elseif #PRINTED > printed then
                    refused = refused + 1
                else
                    Problem(label .. ": right-clicking " .. name .. " neither changed it nor said why")
                end
            end
        end
        Check(("%s: %s changed nothing (%d refused)"):format(label, entry.class, refused), changed > 0)
        local limit = ns.PickLimit(entry.key, entry.view.class, entry.view.level)
        Check(("%s: %s has %d prepared of %d"):format(label, entry.class, ns.PicksKnown(RPSheet:Sheet(), entry.key), limit), ns.PicksKnown(RPSheet:Sheet(), entry.key) <= limit)
    end
    RPSheet:LongRest()
    F.Settle(true)
    RPSheet.busy = false
    WalkRows(PreparedRows, label, { printed = PRINTED, variants = 4, after = function() RPSheet.busy = false end })
    CheckOverlap(RPSheet.preparedBody, label .. " after the clicks")
    SmokeChecks(label)
end

Try("prepared priest", PreparedRun, "prepared priest 5", NewCharacter("PRIEST", nil, nil, 5, 1))
Try("prepared druid", PreparedRun, "prepared druid 9", NewCharacter("DRUID", nil, nil, 9, 2))
Try("prepared paladin", PreparedRun, "prepared paladin 5", NewCharacter("PALADIN", nil, nil, 5, 3))
Try("prepared hunter", PreparedRun, "prepared hunter 5", NewCharacter("HUNTER", nil, nil, 5, 4))
Try("prepared warlock", PreparedRun, "prepared warlock 5", NewCharacter("WARLOCK", nil, nil, 5, 5))
Try("prepared warrior", PreparedRun, "prepared warrior 5", NewCharacter("WARRIOR", nil, nil, 5, 6))
Try("prepared two classes", function()
    local sheet = NewCharacter("PRIEST", nil, nil, 4, 1)
    sheet.classes = { DRUID = { level = 4, subclass = R.CLASSES.DRUID.subclasses[1], spec = R.CLASSES.DRUID.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" } }
    sheet.level = 8
    PreparedRun("prepared priest 4 / druid 4", sheet)
    local headings = 0
    for _, part in ipairs(PreparedRows()) do
        local text = F.Plain(PartText(part))
        if text:find("^\n" .. R.CLASSES.PRIEST.name:upper()) or text:find("^\n" .. R.CLASSES.DRUID.name:upper()) then headings = headings + 1 end
    end
    Check("with two classes that prepare, their names aren't above their spells", headings >= 2)
end)
Try("prepared window buttons", function()
    local window = RPSheet.preparedWindow
    F.Click(window.lockButton)
    Check("the padlock doesn't lock the prepared window", window.locked == true)
    F.Click(window.lockButton)
    F.Click(window.minimizeButton)
    Check("minus doesn't minimize the prepared window", window.minimized == true)
    F.Click(window.minimizeButton)
    F.Click(window.editButton)
    F.Settle()
    local status = AceConfigDialog:GetStatusTable("RPSheet", { "customize" })
    Check("the prepared window's cog doesn't open the Spells page: " .. tostring(status.groups and status.groups.selected), status.groups and status.groups.selected == "spells")
    AceConfigDialog:CloseAll()
    F.Settle()
    RPSheet:TogglePreparedWindow()
    Check("the prepared window doesn't close", not window.frame:IsShown())
end)

---------------------------------------------------------------------------
-- The popup's text box, however the game lets it be reached (Actions/PopupBox.lua)
---------------------------------------------------------------------------
Try("popup box routes", function()
    Use(NewCharacter("ROGUE", nil, nil, 4, 6))
    local function Dialog(how, name)
        local dialog = CreateFrame("Frame", name, UIParent)
        local holder = how == "nested" and CreateFrame("Frame", nil, dialog) or dialog
        local box = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
        if how == "method" then function dialog:GetEditBox() return box end end
        if how == "broken" then function dialog:GetEditBox() return nil end end -- a method that answers nothing
        if how == "EditBox" then dialog.EditBox = box end
        if how == "editBox" then dialog.editBox = box end
        if how == "global" then _G[name .. "EditBox"] = box end
        return dialog, box
    end
    local hows = { "method", "broken", "EditBox", "editBox", "global", "child", "nested" }
    for index, how in ipairs(hows) do
        local dialog, box = Dialog(how, how == "global" and "RPSheetTestPopup" .. index or nil)
        Check("the popup's box isn't found when it is reached by " .. how, ns.PopupEditBox(dialog) == box)
        -- and the coin box reads it: 3 gp added
        local before = RPSheet:Coins()
        box:SetText("3 gp")
        dialog.data = {}
        Try("coin box by " .. how, StaticPopupDialogs.RPSHEET_COINS.OnAccept, dialog, dialog.data)
        Check(("the coin box reached by %s added %d copper, not 300"):format(how, RPSheet:Coins() - before), RPSheet:Coins() - before == 300)
        -- and the damage box: 2 damage taken
        FullHP()
        box:SetText("2")
        dialog.data = {}
        Try("damage box by " .. how, StaticPopupDialogs.RPSHEET_DAMAGE_AMOUNT.OnAccept, dialog, dialog.data)
        Check(("the damage box reached by %s took %d hit points, not 2"):format(how, RPSheet:MaxHP() - HP()), RPSheet:MaxHP() - HP() == 2)
    end
    Check("a popup without a box gives a box", ns.PopupEditBox(CreateFrame("Frame", nil, UIParent)) == nil)
    Check("nothing gives a box", ns.PopupEditBox(nil) == nil)
end)

---------------------------------------------------------------------------
-- A right-click on a roll's row explains the number and rolls nothing
---------------------------------------------------------------------------
Try("right-click on rolls", function()
    Use(NewCharacter("PRIEST", nil, nil, 5, 7))
    RPSheet:Sheet().tools["Thieves' Tools"] = true
    RPSheet:SheetChanged()
    local rolls, roll = 0, RandomRoll
    RandomRoll = function(...) rolls = rolls + 1 return roll(...) end
    local found = {}
    local STARTS = { "STR ", "DEX\n", "Athletics", "Initiative", "Spell attack", "Thieves' Tools" }
    for _, tab in ipairs({ "Checks", "Skills" }) do
        Tab(tab)
        for _, start in ipairs(STARTS) do
            local row = Row(start)
            if row and not found[start] then
                found[start] = true
                local before, printed = rolls, #PRINTED
                ClickPart("right-click " .. start, row, "RightButton")
                Check(start .. ": a right-click rolled", rolls == before)
                Check(start .. ": a right-click explained nothing", #PRINTED > printed)
                local lines = HoverPart("hover " .. start, row) or {}
                local tip = lines[#lines] and F.Plain(lines[#lines].text) or ""
                Check(start .. ": the tooltip doesn't say what a right-click does", tip:find("Right%-click") ~= nil)
                before = rolls
                ClickPart("left-click " .. start, row, "LeftButton")
                -- (a save may first ask what it is against)
                Check(start .. ": a left-click doesn't roll", rolls > before or F.popup ~= nil or F.menu ~= nil)
                Dismiss()
            end
        end
    end
    RandomRoll = roll
    for _, start in ipairs(STARTS) do Check("no row starting " .. start, found[start]) end
end)

Finish("popups", ("%d damage menu rows (%d protective spell options), %d boxes typed into, %d conditions ticked, %d spellbook rows, %d prepared rows"):format(
    stats.menuRows, stats.wards or 0, stats.popups, stats.conditions, stats.bookRows, stats.preparedRows))
