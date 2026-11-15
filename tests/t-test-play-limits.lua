-- Limits the sheet holds to in play: a critical hit at 0 hit points, a right-click
-- that never does the left-click's job, a beast's actions that recharge or are there
-- once a day, a growing spell and a priced component read from a scroll, and what a
-- character that is incapacitated can't do.
dofile(ARG3 .. "/t-test-play-lib.lua")

local P = R.SCROLL_PREFIX
local function D20s(fn)
    local before = #ROLLED
    fn()
    local count = 0
    for i = before + 1, #ROLLED do if ROLLED[i].sides == 20 then count = count + 1 end end
    return count
end
local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local function Druid(subclass, level, forms)
    return Build("DRUID", subclass, level, { base = { STR = 8, DEX = 12, CON = 14, INT = 10, WIS = 16, CHA = 10 },
        setup = function(sheet)
            sheet.picks.forms = {}
            for _, name in ipairs(forms) do sheet.picks.forms[name] = true end
        end })
end
local function Found(spell)
    local item = RPSheet:AddItem(P .. spell, 1)
    item.scribed = nil
    return item
end
local function Qty(name)
    local total = 0
    for _, item in ipairs(RPSheet:Sheet().items) do if item.name == name then total = total + item.qty end end
    return total
end
-- The rows a section of the sheet makes, without a window: { text, click, title, tip }.
local function Rows(section)
    local UI = ns.UI
    local rows, keepLabel, keepHeading, keepLevel = {}, UI.AddLabel, UI.AddHeading, RPSheet.AddLevelLabel
    UI.AddLabel = function(_, _, text, onClick, title, tip)
        local row = { text = text, click = onClick, title = title, tip = tip }
        function row:SetText(new) self.text = new end
        rows[#rows + 1] = row
        return row
    end
    UI.AddHeading = function() end
    RPSheet.AddLevelLabel = function() end
    local ok, err = pcall(section, RPSheet, {})
    UI.AddLabel, UI.AddHeading, RPSheet.AddLevelLabel = keepLabel, keepHeading, keepLevel
    Check(ok, "the section is built without an error: " .. tostring(err))
    return rows
end
local function Row(rows, piece)
    for _, row in ipairs(rows) do
        if row.text:find(piece, 1, true) then return row end
    end
    Check(false, "no row with \"" .. piece .. "\"")
end

Section("a critical hit at 0 hit points", function()
    Build("WARRIOR", "", 5)
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    state.hp = 0
    RPSheet:TakeDamage(3, nil, nil, nil, true)
    Eq(state.deathFail, 2, "a critical hit at 0 hit points is two failed death saves")
    Said("A critical hit, two failed death saves: 0 passed, 2 failed", "and the line says so")
    RPSheet:TakeDamage(3, nil, nil, nil, true)
    Eq(state.deathFail, 3, "never more than three")
    Said("A critical hit, two failed death saves: dead", "dead")
    RPSheet:ClearDeathSaves()
    RPSheet:TakeDamage(3)
    Eq(state.deathFail, 1, "a plain hit is still one")
    RPSheet:TakeDamage(3, "fire", nil, nil, true)
    Eq(state.deathFail, 3, "one and two make three")
    Said("A critical hit, two failed death saves: dead", "the third failure kills")
    -- stable, then hit by a critical: the count starts over with two
    state.deathPass, state.deathFail = 3, 0
    RPSheet:TakeDamage(1, nil, nil, nil, true)
    Check(state.deathPass == 0 and state.deathFail == 2, "a stable character hit by a critical starts over with two failures")
    -- as much as the hit point maximum still kills outright
    RPSheet:ClearDeathSaves()
    RPSheet:TakeDamage(max, nil, nil, nil, true)
    Said("Dead: that is as much as their hit point maximum", "massive damage kills, critical or not")
    -- on its feet a critical hit changes nothing: the amount is typed as rolled
    RPSheet:ClearDeathSaves()
    state.hp = max
    RPSheet:TakeDamage(4, nil, nil, nil, true)
    Check(HP() == max - 4 and state.deathFail == 0, "a critical hit on a character that is up is plain damage")
    -- the slash command
    state.hp = 0
    RPSheet:DamageCommand("damage", "3 crit")
    Eq(state.deathFail, 2, "/sheet damage 3 crit")
    RPSheet:ClearDeathSaves()
    RPSheet:DamageCommand("damage", "3 fire critical")
    Eq(state.deathFail, 2, "/sheet damage 3 fire critical")
    Said("takes 3 fire damage", "the type is still read")
    RPSheet:ClearDeathSaves()
    RPSheet:DamageCommand("damage", "3 CRIT cold")
    Eq(state.deathFail, 2, "the word can come before the type")
    Said("takes 3 cold damage", "which is still read")
    RPSheet:ClearDeathSaves()
    RPSheet:DamageCommand("damage", "3 fire")
    Eq(state.deathFail, 1, "without the word: one")
    local before = #PRINTED
    RPSheet:DamageCommand("damage", "3 critters")
    Eq(state.deathFail, 3, "(any word starting with crit counts)")
    RPSheet:ClearDeathSaves()

    -- the menu: a box to tick, only while down
    local asked
    local keep = RPSheet.AskAmount
    RPSheet.AskAmount = function(_, request) asked = request end
    RPSheet:OpenDamageMenu({})
    if Check(MENU and MENU.items[1].text == "It was a critical hit" and MENU.items[1].checked, "down: the menu starts with a box for a critical hit") then
        Click(MENU, "Fire")
        Check(asked and asked.damageType == "fire" and not asked.crit, "unticked: a plain hit")
        Click(MENU, "It was a critical hit")
        Check(MENU.items[1].checked(), "a click ticks it")
        Click(MENU, "Fire")
        Check(asked and asked.crit == true, "ticked: the request says critical")
        Click(MENU, "No type")
        Check(asked and asked.crit == true and asked.damageType == nil, "for damage without a type too")
    end
    state.hp = max
    RPSheet:OpenDamageMenu({})
    Check(MENU and MENU.items[1].text ~= "It was a critical hit", "up: no such box")
    RPSheet.AskAmount = keep
    -- through the wards: a rolled ward passes the word on
    state.hp = 0
    table.insert(RPSheet:Sheet().passives, { name = "Resistance", desc = "", auto = "ward:Resistance:fire", enabled = true, effects = {} })
    if R.WardOf("ward:Resistance:fire") then
        Rolls(1)
        RPSheet:TakeDamage(6, "fire", nil, nil, true)
        Eq(state.deathFail, 2, "a critical hit through a rolled ward is still two")
    end
end)

Section("a right-click never does the left-click's job", function()
    Build("WARRIOR", "", 5)
    local wind = Tracker("Second Wind")
    local rows = Rows(ns.UI.AbilitySection)
    local row = Row(rows, "Second Wind")
    if row then
        local had, before, sent = wind.get(), #PRINTED, #SENT
        row.click("RightButton")
        Eq(wind.get(), had, "a right-click on an ability with nothing to take back doesn't use it")
        Eq(#SENT, sent, "nothing is announced")
        Check(AnyPrinted("Nothing to take back for Second Wind", before), "a line says what a right-click is for")
        row.click("LeftButton")
        Eq(wind.get(), had - 1, "a left-click uses it")
    end
    -- one with a cost to take back still takes it back
    local mind = Ability("Tactical Mind")
    row = Row(rows, "Tactical Mind")
    if Check(mind and row, "a Warrior has Tactical Mind") then
        local had = wind.get()
        row.click("LeftButton")
        Eq(wind.get(), had - 1, "Tactical Mind spends a Second Wind")
        row.click("RightButton")
        Eq(wind.get(), had, "a right-click takes it back")
        local before = #PRINTED
        row.click("RightButton")
        Eq(wind.get(), had, "a second right-click does nothing")
        Check(AnyPrinted("Nothing to take back", before), "and says so")
    end

    -- spells
    Build("MAGE", "", 5)
    local bolt, missile, detect = Learn("Fire Bolt"), Learn("Magic Missile"), Learn("Detect Magic")
    local s1 = Slot(1)
    rows = Rows(ns.UI.SpellSection)
    local left, sent, before = s1.get(), #SENT, #PRINTED
    Row(rows, "Magic Missile").click("RightButton")
    Eq(s1.get(), left, "a right-click on a spell that is no ritual spends no slot")
    Eq(#SENT, sent, "and casts nothing")
    Check(AnyPrinted("Magic Missile is not a ritual", before), "a line says what a right-click is for")
    Eq(D20s(function() Row(rows, "Fire Bolt").click("RightButton") end), 0, "nor does it cast a cantrip")
    Row(rows, "Detect Magic").click("RightButton")
    Eq(s1.get(), left, "a ritual is cast without a slot")
    Said("(as a ritual, no slot)", "as a ritual")
    Row(rows, "Magic Missile").click("LeftButton")
    Eq(s1.get(), left - 1, "a left-click casts with a slot")
end)

Section("beast actions with a limit", function()
    Druid("Circle of the Moon", 9, { "Giant Hyena", "Ape", "Giant Spider", "Octopus", "Giant Toad" })
    local state = RPSheet:State()
    local bite, rampage = Ability("Giant Hyena: Bite"), Ability("Giant Hyena: Bite (Rampage)")
    if Check(bite and rampage, "the hyena has a bite and a rampage row") then
        Eq(RPSheet:BeastUseText(bite), nil, "the plain bite has no limit")
        Eq(RPSheet:BeastUseText(rampage), "1/1 a day", "the rampage is counted")
        Check(rampage.desc:find("Once a day: a long rest brings it back", 1, true), "its tooltip says so")
        Eq(D20s(function() RPSheet:UseAbility(rampage) end), 1, "the first rampage goes through")
        Eq(RPSheet:BeastUseText(rampage), "0/1 a day", "and is used up")
        local before = #PRINTED
        Eq(D20s(function() RPSheet:UseAbility(rampage) end), 0, "a second one is refused")
        Check(AnyPrinted("Giant Hyena: Bite (Rampage) is used up for today", before), "with a line saying why")
        Eq(D20s(function() RPSheet:UseAbility(bite) end), 1, "the plain bite is still there")
        Check(not RPSheet:RollBeastRecharge(rampage), "a right-click has no recharge to roll for it")
        RPSheet:ShortRest()
        Eq(RPSheet:BeastUseText(rampage), "0/1 a day", "a short rest doesn't bring it back")
        RPSheet:LongRest()
        Eq(RPSheet:BeastUseText(rampage), "1/1 a day", "a long rest does")
    end
    -- a recharge on a 6
    local rock = Ability("Ape: Rock")
    if Check(rock, "the ape has its rock") then
        Eq(RPSheet:BeastUseText(rock), "ready", "the rock is ready")
        Check(rock.desc:find("comes back on a 6 on a d6", 1, true), "its tooltip names the recharge")
        local before, rolled = #PRINTED, #ROLLED
        Check(RPSheet:RollBeastRecharge(rock) and #ROLLED == rolled and AnyPrinted("is ready: there is nothing to roll for", before), "a right-click on a ready row rolls nothing")
        RPSheet:UseAbility(rock)
        Eq(RPSheet:BeastUseText(rock), "used, recharges on a 6", "thrown: used")
        Eq(D20s(function() RPSheet:UseAbility(rock) end), 0, "it can't be thrown again")
        local at = #ROLLED
        Rolls(5)
        Check(RPSheet:RollBeastRecharge(rock), "a right-click rolls for it")
        Eq(Dice(at), "6", "a d6")
        Said("rolls to recharge [Ape: Rock]: 5 - not yet.", "a 5 is not enough")
        Eq(RPSheet:BeastUseText(rock), "used, recharges on a 6", "still used")
        Rolls(6)
        RPSheet:RollBeastRecharge(rock)
        Said("rolls to recharge [Ape: Rock]: 6 - it is back.", "a 6 brings it back")
        Eq(D20s(function() RPSheet:UseAbility(rock) end), 1, "and it can be thrown again")
        RPSheet:ShortRest()
        Eq(RPSheet:BeastUseText(rock), "ready", "a short rest brings a recharging action back")
    end
    -- a recharge on a 5 or 6
    local web = Ability("Giant Spider: Web")
    if Check(web, "the spider has its web") then
        RPSheet:UseAbility(web)
        Eq(RPSheet:BeastUseText(web), "used, recharges on 5 or higher", "the web recharges on a 5 or 6")
        Rolls(4); RPSheet:RollBeastRecharge(web)
        Eq(RPSheet:BeastUseText(web), "used, recharges on 5 or higher", "a 4 is not enough")
        Rolls(5); RPSheet:RollBeastRecharge(web)
        Eq(RPSheet:BeastUseText(web), "ready", "a 5 is")
    end
    -- the row on the sheet
    RPSheet:UseAbility(rock)
    local rows = Rows(ns.UI.AbilitySection)
    local row = Row(rows, "Ape: Rock")
    if row then
        Check(row.text:find("used, recharges on a 6", 1, true), "the row shows what is left")
        Rolls(6)
        row.click("RightButton")
        Eq(RPSheet:BeastUseText(rock), "ready", "a right-click on the row rolls the recharge")
    end
    -- an action that is no attack: the ink
    local ink = Ability("Octopus: Ink Cloud")
    if Check(ink, "the octopus has a row for its ink") then
        Eq(RPSheet:BeastUseText(ink), "1/1 a day", "once a day")
        RPSheet:UseAbility(ink)
        Said("uses [Octopus: Ink Cloud]. Ink fills a 5-foot cube around them", "it says what the ink does")
        Eq(D20s(function() RPSheet:UseAbility(ink) end) + (RPSheet:BeastUseText(ink) == "0/1 a day" and 0 or 1), 0, "and is used up")
    end
    for name, feet in pairs({ ["Giant Octopus"] = 10, ["Giant Squid"] = 15 }) do
        local extra = R.BEASTS[name].extras and R.BEASTS[name].extras[1]
        Check(extra and extra.day and extra[2]:find(feet .. "-foot cube", 1, true), name .. " has its ink, a " .. feet .. "-foot cube")
    end
    -- Swallow says what it does
    local swallow = Ability("Giant Toad: Swallow")
    if Check(swallow, "the toad can swallow") then
        local at = #ROLLED
        RPSheet:UseAbility(swallow)
        Eq(Dice(at), "6,6,6", "3d6")
        Said("The swallowed creature is [Blinded] and [Restrained], and takes this at the end of each of your turns", "with its rider")
    end
    Check(R.BEASTS["Giant Frog"].attacks[2].rider:find("spat out {Prone}", 1, true), "the frog's swallow has a rider too")
    -- an old saved character has no such field
    state.beastUsed = nil
    Eq(RPSheet:BeastUseText(rock), "ready", "a character saved before this counts from nothing")
end)

Section("scrolls: a growing spell and a priced component", function()
    Build("WARLOCK", "", 5, { base = { STR = 10, DEX = 12, CON = 14, INT = 10, WIS = 10, CHA = 18 } })
    local own = Learn("Curse of Agony")
    local scroll = Found("Curse of Agony")
    local dc = R.SCROLL_FOUND[R.SPELLS["Curse of Agony"].level][1]
    Check(dc ~= RPSheet:SpellDC(own), "(the found scroll's DC differs from the warlock's own)")
    local slot
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then slot = tracker end end
    local left = slot.get()
    RPSheet:UseItem(scroll)
    Said("casts [Curse of Agony] (from a scroll)", "the scroll is read")
    Eq(Qty(P .. "Curse of Agony"), 0, "and gone")
    Eq(RPSheet:GrowingSides(own), nil, "the character's own spell is not running because of the scroll")
    local runs = RPSheet:ScrollRuns()
    if not Eq(#runs, 1, "the scroll's spell is running by itself") then return end
    Eq(RPSheet:GrowingSides(runs[1]), 6, "its next turn rolls a d6")
    Check(runs[1].fromScroll == nil, "the copy doesn't hold on to the scroll")
    -- the own spell is cast with a slot beside it
    local at = #ROLLED
    RPSheet:CastSpell(own)
    Eq(slot.get(), left - 1, "casting the own spell spends a slot")
    Eq(Dice(at), "4", "and starts at a d4")
    Eq(RPSheet:GrowingSides(runs[1]), 6, "the scroll's is where it was")
    -- its row on the sheet
    local rows = Rows(ns.UI.SpellSection)
    local row = Row(rows, "Curse of Agony (from a scroll)")
    if row then
        Check(row.text:find("running, next 1d6", 1, true) and row.text:find("DC " .. dc, 1, true), "the row shows the next die and the scroll's DC")
        at = #ROLLED
        row.click("LeftButton")
        Eq(Dice(at), "6", "a left-click rolls its next turn")
        Said(("save DC %d"):format(dc), "against the scroll's DC")
        Eq(slot.get(), left - 1, "without a slot")
        Eq(RPSheet:GrowingSides(own), 6, "and the own spell is not moved on by it")
        row.click("RightButton")
        Said("[Curse of Agony] ends.", "a right-click ends it")
        Eq(#RPSheet:ScrollRuns(), 0, "its row goes")
        Eq(RPSheet:GrowingSides(own), 6, "the own spell runs on")
    end
    RPSheet:UseItem(Found("Curse of Agony"))
    Eq(#RPSheet:ScrollRuns(), 1, "read again")
    RPSheet:LongRest()
    Eq(#RPSheet:ScrollRuns(), 0, "a long rest ends it")
    -- a reader who doesn't have the spell: the row is all there is
    Build("WARLOCK", "", 5)
    RPSheet:UseItem(Found("Curse of Agony"))
    rows = Rows(ns.UI.SpellSection)
    Check(Row(rows, "Curse of Agony (from a scroll)") ~= nil, "a reader without the spell gets the row too")

    -- Beast Spells: a scroll needs no component
    Druid("Circle of the Land", 18, { "Wolf" })
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    Check(RPSheet:Form() ~= nil and ns.HasFeature(RPSheet:Sheet(), "Beast Spells"), "a level 18 druid in a form")
    local stone = Learn("Stoneskin")
    Check(RPSheet:FormBlocksSpell(stone) ~= nil, "its own Stoneskin needs the diamond dust: not in a form")
    local sent = #SENT
    MENU = false
    RPSheet:UseItem(Found("Stoneskin"))
    if MENU and MENU.title == "Stoneskin: who is it for?" then MENU.items[1].click() end -- (the spell's own question)
    Check(AnySaid("casts [Stoneskin] (from a scroll)", sent), "a scroll of it can be read in the form")
    Eq(Qty(P .. "Stoneskin"), 0, "and is used up")
    -- without Beast Spells a form still reads nothing
    Druid("Circle of the Land", 8, { "Wolf" })
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    local before = #PRINTED
    RPSheet:UseItem(Found("Thunderwave"))
    Check(AnyPrinted("You can't cast spells in a beast form", before) and Qty(P .. "Thunderwave") == 1, "below level 18 a scroll is refused in a form and kept")
end)

Section("incapacitated", function()
    Build("WARRIOR", "", 5)
    local item = RPSheet:AddItem("Longsword", 1); RPSheet:SetEquipped(item, true); RPSheet:SheetChanged()
    local state, wind = RPSheet:State(), Tracker("Second Wind")
    for _, name in ipairs({ "Incapacitated", "Paralyzed", "Petrified", "Stunned", "Unconscious" }) do
        for other in pairs(state.conditions) do state.conditions[other] = nil end
        state.conditions[name] = true
        local before, sent, had = #PRINTED, #SENT, wind.get()
        Eq(D20s(function() RPSheet:Attack() end), 0, name .. ": no attack")
        Check(AnyPrinted(("You can't attack while %s: no actions, bonus actions or reactions."):format(name:lower()), before), name .. ": a line says why")
        before = #PRINTED
        RPSheet:UseAbility(Ability("Second Wind"))
        Eq(wind.get(), had, name .. ": no ability")
        Check(AnyPrinted("You can't use Second Wind while " .. name:lower(), before), name .. ": and why")
        Eq(#SENT, sent, name .. ": nothing announced")
    end
    for other in pairs(state.conditions) do state.conditions[other] = nil end
    state.conditions.Stunned = true
    -- saving throws and death saves still roll; an ability that is only a save too
    Eq(D20s(function() RPSheet:RollCheck("WIS save", 1) end), 1, "a saving throw still rolls")
    Eq(D20s(function() RPSheet:RollCheck("DEX save", 1) end), 0, "(a Dexterity save fails by itself)")
    state.hp = 0
    Eq(D20s(function() RPSheet:RollDeathSave() end), 1, "a death save still rolls")
    state.hp = RPSheet:MaxHP()
    RPSheet:ClearDeathSaves()
    local sheet = RPSheet:Sheet()
    sheet.abilities[#sheet.abilities + 1] = { name = "Hold on", desc = "", actions = { ns.FeatureKit.Roll("SAVE", "CON", false) } }
    ns.Util.NormalizeList(sheet.abilities, R.TEMPLATES.ability)
    Eq(D20s(function() RPSheet:UseAbility(Ability("Hold on")) end), 1, "an ability that only rolls the character's own save still rolls")
    state.conditions.Stunned = nil
    Eq(D20s(function() RPSheet:Attack() end), 1, "with the condition gone the attack is back")

    -- spells and scrolls
    Build("MAGE", "", 5)
    state = RPSheet:State()
    local missile, s1 = Learn("Magic Missile"), Slot(1)
    local scroll = RPSheet:AddItem(P .. "Magic Missile", 1)
    state.conditions.Paralyzed = true
    local left, before = s1.get(), #PRINTED
    RPSheet:CastSpell(missile)
    Eq(s1.get(), left, "no spell while paralyzed")
    Check(AnyPrinted("You can't cast Magic Missile while paralyzed", before), "and a line says why")
    before = #PRINTED
    RPSheet:UseItem(scroll)
    Check(Qty(P .. "Magic Missile") == 1 and AnyPrinted("You can't read a scroll while paralyzed", before), "a scroll is not read, and kept")
    state.conditions.Paralyzed = nil
    RPSheet:CastSpell(missile)
    Eq(s1.get(), left - 1, "afterwards the spell is cast")

    -- what lasts until the character is incapacitated ends when the condition is ticked
    Build("SHAMAN", "", 5)
    local rage = Ability("Rage")
    if Check(rage and Passive("Raging"), "a Shaman rages") then
        RPSheet:UseAbility(rage)
        Check(Passive("Raging").enabled, "raging")
        RPSheet:ToggleCondition("Poisoned")
        Check(Passive("Raging").enabled, "a condition that doesn't incapacitate leaves the rage")
        local sent = #SENT
        RPSheet:ToggleCondition("Stunned")
        Check(not Passive("Raging").enabled, "Stunned ends the rage")
        Check(AnySaid("loses Rage: stunned.", sent), "and it is announced")
        RPSheet:ToggleCondition("Stunned")
        Check(not Passive("Raging").enabled, "coming to doesn't bring it back")
    end
    Build("SHAMAN", "", 15)
    if Check(Ability("Persistent Rage"), "at level 15 the rage is persistent") then
        RPSheet:UseAbility(Ability("Rage"))
        RPSheet:ToggleCondition("Stunned")
        Check(Passive("Raging").enabled, "a persistent rage outlasts being stunned")
        RPSheet:ToggleCondition("Stunned")
        RPSheet:ToggleCondition("Unconscious")
        Check(not Passive("Raging").enabled, "but not being knocked out")
    end
    Build("MONK", "", 18)
    local defense = Ability("Superior Defense")
    if Check(defense and Passive("Superior Defense active"), "a level 18 Monk has Superior Defense") then
        RPSheet:UseAbility(defense)
        Check(Passive("Superior Defense active").enabled, "it is on")
        local sent = #SENT
        RPSheet:ToggleCondition("Incapacitated")
        Check(not Passive("Superior Defense active").enabled and AnySaid("loses Superior Defense: incapacitated.", sent), "Incapacitated ends it, and says so")
    end
    Druid("Circle of the Stars", 14, {})
    local stars = Passive("Full of Stars")
    if Check(stars and Ability("Starry Form"), "a level 14 Stars druid has Starry Form") then
        RPSheet:UseAbility(Ability("Starry Form"))
        Passive("Dragon").enabled = true
        Check(stars.enabled, "the form is on")
        local sent = #SENT
        RPSheet:ToggleCondition("Paralyzed")
        Check(not stars.enabled and not Passive("Dragon").enabled, "Paralyzed ends the starry form and its constellation")
        Check(AnySaid("loses Starry Form: paralyzed.", sent), "named once")
    end
    -- a passive of the player's own with such a name is left alone
    Build("WARRIOR", "", 5)
    table.insert(RPSheet:Sheet().passives, { name = "Raging", desc = "", auto = "", enabled = true, effects = {} })
    RPSheet:ToggleCondition("Stunned")
    Check(Passive("Raging").enabled, "a passive of the player's own is not the sheet's to end")
end)

Summary("t-test-play-limits")
