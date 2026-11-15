-- What the sheet asks before a d20 and what it adds to one: an ability's own save or
-- check goes by the same rules as the sheet's rows; "don't ask again"; whom a
-- Grappled character attacks and whether a Frightened one sees what it fears;
-- advantages that only count for a while (Holy Nimbus) or for some spells (Extended
-- Spell); and the one-off bonus or penalty of the "Next roll" rows.
dofile(ARG3 .. "/t-test-play-lib.lua")
local Kit = ns.FeatureKit

-- Runs fn and returns how many d20s it rolled.
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
-- An ability of the player's own with these steps.
local function Own(name, ...)
    local sheet = RPSheet:Sheet()
    sheet.abilities[#sheet.abilities + 1] = { name = name, desc = "", actions = { ... } }
    ns.Util.NormalizeList(sheet.abilities, R.TEMPLATES.ability)
    return Ability(name)
end
local function Sword()
    local item = RPSheet:AddItem("Longsword", 1)
    RPSheet:SetEquipped(item, true)
    RPSheet:SheetChanged()
end
local function Only(...)
    local on = RPSheet:State().conditions
    for name in pairs(on) do on[name] = nil end
    for _, name in ipairs({ ... }) do on[name] = true end
end

Section("an ability's own save and check go by the roll rules", function()
    Build("WARRIOR", "", 5, { species = "ELF" })
    local save = Own("Shake it off", Kit.Roll("SAVE", "WIS", false))
    local left = #SENT
    Eq(D20s(function() RPSheet:UseAbility(save) end), 0, "an elf's Wisdom save from an ability asks first")
    Check(MENU and MENU.title == "WIS save: what is it against?", "with the save's own question")
    Check(not RPSheet.busy, "and the sheet is not left busy while the menu is open")
    Eq(#SENT, left, "nothing is announced yet")
    Rolls(4, 16)
    Eq(D20s(function() Click(MENU, "being Charmed") end), 2, "against being Charmed: advantage")
    Said("saving throw (WIS) against being Charmed: 16 [advantage: 4, 16]", "the line says what it is against")
    Eq(D20s(function() RPSheet:UseAbility(save) Click(MENU, "Something else") end), 1, "something else: one die")
    -- conditions: disadvantage, and a save that fails by itself
    local dex = Own("Dive", Kit.Roll("SAVE", "DEX", false))
    Only("Restrained")
    MENU = false
    Eq(D20s(function() RPSheet:UseAbility(dex) end), 0, "Restrained: an elf's Dexterity save still asks")
    Eq(D20s(function() Click(MENU, "Something else") end), 2, "and rolls with disadvantage")
    Only("Paralyzed")
    MENU = false
    Eq(D20s(function() RPSheet:UseAbility(dex) end), 0, "Paralyzed: the save rolls nothing")
    Check(not MENU, "and asks nothing")
    Said("saving throw (DEX): fails without a roll ([Paralyzed])", "it fails without a roll")
    local check = Own("Heave", Kit.Roll("CHECK", "STR", false))
    Only("Poisoned")
    Eq(D20s(function() RPSheet:UseAbility(check) end), 2, "Poisoned: an ability's check has disadvantage")
    Eq(D20s(function() RPSheet:UseAbility(check, "ADV") end), 1, "which advantage cancels")
    Only()
    Eq(D20s(function() RPSheet:UseAbility(check) end), 1, "and without a condition it is a plain roll")
    -- a check of an ability goes by the features that give advantage on it too
    table.insert(RPSheet:Sheet().passives, { name = "Strong back", desc = "", auto = "test", enabled = true, effects = {}, advantage = { "STR check" } })
    Eq(D20s(function() RPSheet:UseAbility(check) end), 2, "a feature's advantage on Strength checks counts for the ability")
end)

Section("don't ask again", function()
    Build("WARRIOR", "", 5, { species = "ELF" })
    local mod = RPSheet:SaveMod("WIS")
    RPSheet:RollCheck("WIS save", mod)
    if not Check(MENU and MENU.items[#MENU.items].text == "Don't ask again for this character", "the menu's last row stops the question") then return end
    local before = #PRINTED
    Eq(D20s(function() Click(MENU, "Don't ask again") end), 1, "it rolls the save plainly")
    Check(RPSheet:RollQuiet("about"), "and remembers the choice for this character")
    Check(AnyPrinted("Customize > Proficiencies turns the question back on", before), "a line says where to turn it back on")
    Check(AnyPrinted("You have advantage on this save if it is against being Charmed (Fey Ancestry): Shift-click", before), "and the reminder comes with the roll")
    MENU, before = false, #PRINTED
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 1, "the next save rolls at once")
    Check(not MENU, "without a menu")
    Check(AnyPrinted("Shift-click to roll it that way", before), "with the one-line reminder")
    before = #PRINTED
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod, "ADV") end), 2, "Shift rolls it with advantage")
    Eq(#PRINTED, before, "and then there is nothing to remind of")
    Check(RPSheet:SaveAdvantageText("WIS"):find("Advantage against being Charmed (Fey Ancestry): Shift-click when it applies.", 1, true), "the tooltip still lists it, and says how")
    -- the switch under Customize
    local args = ns.Opt.custom.proficiencies.args
    if Check(args.askabout and args.askGrappled and args.askFrightened, "Customize > Proficiencies has a switch for each question") then
        Eq(args.askabout.get(), false, "the switch shows it is off")
        args.askabout.set(nil, true)
        Check(not RPSheet:RollQuiet("about"), "ticking it turns the question back on")
        MENU = false
        Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 0, "and the save asks again")
        Check(MENU and MENU.title == "WIS save: what is it against?", "with its menu")
        Check(RPSheet:SaveAdvantageText("WIS"):find("the sheet asks when you roll", 1, true), "the tooltip follows")
    end
    -- it is this character's own choice
    RPSheet:SetRollQuiet("about", true)
    Build("WARRIOR", "", 5, { species = "ELF" })
    Check(not RPSheet:RollQuiet("about"), "a new character in its place asks again")
    Check(RPSheet:State().quiet == nil, "(as an old saved one does: the field isn't there)")
end)

Section("Grappled and Frightened", function()
    Build("WARRIOR", "", 5)
    Sword()
    Only("Grappled")
    local left = #SENT
    Eq(D20s(function() RPSheet:Attack() end), 0, "Grappled: an attack asks first")
    Check(MENU and MENU.title == "Grappled: whom do you attack?", "whom it is against")
    Eq(#SENT, left, "nothing rolled or announced yet")
    Eq(D20s(function() Click(MENU, "Your grappler") end), 1, "against the grappler: a plain roll")
    Eq(D20s(function() Click(MENU, "Someone else") end), 2, "against someone else: disadvantage")
    Said("[disadvantage:", "the line shows it")
    -- advantage chosen: the answer still decides
    MENU = false
    Eq(D20s(function() RPSheet:Attack("ADV") end), 0, "with advantage chosen it still asks")
    Eq(D20s(function() Click(MENU, "Your grappler") end), 2, "the grappler: advantage")
    Eq(D20s(function() Click(MENU, "Someone else") end), 1, "someone else: the two cancel out")
    -- when the answer changes nothing, there is no question
    MENU = false
    Eq(D20s(function() RPSheet:Attack("DIS") end), 2, "with disadvantage chosen there is nothing to ask")
    Check(not MENU, "no menu")
    Only("Grappled", "Poisoned")
    Eq(D20s(function() RPSheet:Attack() end), 2, "nor when another condition gives disadvantage anyway")
    Check(not MENU, "no menu then either")
    -- a check and a save are not the grapple's business
    Only("Grappled")
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5) end), 1, "a Grappled character's check rolls at once")
    Eq(D20s(function() RPSheet:RollCheck("WIS save", 1) end), 1, "and so does its save")
    Check(not MENU, "without a menu")

    -- Frightened: attacks and checks
    Only("Frightened")
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5) end), 0, "Frightened: a check asks first")
    Check(MENU and MENU.title == "Frightened: is the source of your fear in sight?", "whether the source is in sight")
    Eq(D20s(function() Click(MENU, "Not in sight") end), 1, "out of sight: a plain roll")
    Eq(D20s(function() Click(MENU, "Its source is in sight") end), 2, "in sight: disadvantage")
    MENU = false
    Eq(D20s(function() RPSheet:RollCheck("initiative", 2) end), 0, "initiative is a check: it asks")
    Check(MENU ~= false, "with the menu")
    MENU = false
    Eq(D20s(function() RPSheet:Attack() end), 0, "an attack asks too")
    Eq(D20s(function() Click(MENU, "Not in sight") end), 1, "and rolls plainly out of sight")
    MENU = false
    Eq(D20s(function() RPSheet:RollCheck("WIS save", 1) end), 1, "a save is not asked about")
    Check(not MENU, "no menu for the save")

    -- both: one question after the other, the second only when it still matters
    Only("Grappled", "Frightened")
    RPSheet:Attack()
    Check(MENU and MENU.title:find("Grappled"), "both: the grapple comes first")
    local first = MENU
    Eq(D20s(function() Click(first, "Someone else") end), 2, "someone else settles it: disadvantage, no second question")
    Check(MENU == first, "no second menu")
    Eq(D20s(function() Click(first, "Your grappler") end), 0, "the grappler: the fear is asked next")
    Check(MENU ~= first and MENU.title:find("Frightened"), "with its own menu")
    Eq(D20s(function() Click(MENU, "Not in sight") end), 1, "neither applies: a plain roll")

    -- an ability's attack, and a spell's, ask before anything is spent
    Only("Grappled")
    local strike = Own("Shield bash", Kit.Spend("Second Wind"), Kit.Roll("ATTACK", "STR"), Kit.Dice(1, 4))
    local uses = Tracker("Second Wind")
    local had = uses.get()
    MENU = false
    Eq(D20s(function() RPSheet:UseAbility(strike) end), 0, "an ability's attack asks first")
    Eq(uses.get(), had, "with nothing spent")
    Check(not RPSheet.busy, "and the sheet free")
    Eq(D20s(function() Click(MENU, "Someone else") end), 2, "then rolls with disadvantage")
    Eq(uses.get(), had - 1, "and spends its use")
    Build("MAGE", "", 5)
    Only("Grappled")
    local bolt = Learn("Fire Bolt")
    MENU = false
    Eq(D20s(function() RPSheet:CastSpell(bolt) end), 0, "a spell attack asks first")
    Check(MENU and MENU.title:find("Grappled") and not RPSheet.busy, "with the menu, the sheet free")
    Eq(D20s(function() Click(MENU, "Your grappler") end), 1, "then casts")
    Said("casts [Fire Bolt]", "the casting is announced")
    Eq(D20s(function() RPSheet:RollCheck("spell attack", 5) end), 0, "the spell attack row asks as well")

    -- don't ask again: the cautious answer, said with the roll
    Build("WARRIOR", "", 5)
    Sword()
    Only("Grappled")
    RPSheet:Attack()
    local before = #PRINTED
    Eq(D20s(function() Click(MENU, "Don't ask again") end), 2, "don't ask again: disadvantage")
    Check(AnyPrinted("Grappled: rolled with disadvantage, as against anyone but your grappler", before), "and a line says what was assumed")
    MENU, before = false, #PRINTED
    Eq(D20s(function() RPSheet:Attack() end), 2, "the next attack rolls at once, with disadvantage")
    Check(not MENU and AnyPrinted("Shift-click an attack on the grappler", before), "with the reminder")
    Eq(D20s(function() RPSheet:Attack("ADV") end), 1, "Shift cancels it out, for an attack on the grappler")
    Only("Frightened")
    Eq(D20s(function() RPSheet:Attack() end), 0, "the other question is still asked")
    Eq(D20s(function() Click(MENU, "Don't ask again") end), 2, "until it is stopped too: disadvantage")
    Check(RPSheet:RollQuiet("Frightened") and RPSheet:RollQuiet("Grappled") and not RPSheet:RollQuiet("about"), "each question is stopped by itself")
    -- without the game's menu: the same as not asking
    RPSheet:SetRollQuiet("Grappled", false)
    Only("Grappled")
    local keep = MenuUtil
    MenuUtil = false
    before = #PRINTED
    Eq(D20s(function() RPSheet:Attack() end), 2, "without a menu: disadvantage")
    Check(AnyPrinted("Grappled: rolled with disadvantage", before), "and the line")
    MenuUtil = keep
end)

Section("Holy Nimbus and Extended Spell", function()
    Build("PALADIN", "Oath of Devotion", 20)
    local nimbus, uses = Ability("Holy Nimbus"), Tracker("Holy Nimbus")
    if Check(nimbus and uses, "a level 20 Oath of Devotion paladin has Holy Nimbus and its use") then
        local mod = RPSheet:SaveMod("WIS")
        MENU = false
        Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 1, "before it is used a save asks nothing")
        Check(not MENU, "no menu")
        RPSheet:UseAbility(nimbus)
        Eq(uses.get(), 0, "its use is spent")
        Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 0, "once it is used a save asks")
        Check(MENU and MENU.title == "WIS save: what is it against?", "what it is against")
        Rolls(3, 15)
        Eq(D20s(function() Click(MENU, "Against a fiend or an undead") end), 2, "a fiend or an undead: advantage")
        Said("rolls [WIS save] against a fiend or an undead: 15 [advantage: 3, 15]", "the line says so")
        Check(RPSheet:SaveAdvantageText("DEX"):find("Advantage against a fiend or an undead (Holy Nimbus)", 1, true), "every save's tooltip names it")
        RPSheet:LongRest()
        MENU = false
        Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 1, "after a long rest it is off again")
        Check(not MENU, "no menu")
    end

    -- Extended Spell: the save to keep a spell
    Build("EVOKER", "", 5, { setup = function(sheet) sheet.picks.metamagic = { ["Extended Spell"] = true } end })
    local state = RPSheet:State()
    state.conditions.Concentrating = true
    MENU = false
    Eq(D20s(function() RPSheet:TakeDamage(4) end), 0, "with Extended Spell the save to keep a spell asks first")
    Check(MENU and MENU.title == "Took 4 damage: which spell are you holding?", "which spell it is")
    Check(not RPSheet.busy, "the sheet is free meanwhile")
    Rolls(2, 19)
    Eq(D20s(function() Click(MENU, "A spell you extended") end), 2, "one that was extended: advantage")
    Said("keeps the spell", "and it is kept")
    Eq(D20s(function() Click(MENU, "Another spell") end), 1, "another spell: a plain save")
    Check(RPSheet:SaveAdvantageText("CON"):find("Advantage to keep concentrating on a spell you extended (Extended Spell)", 1, true), "the Constitution save's tooltip names it")
    local always, asked = RPSheet:SaveAdvantages("CON save")
    Eq(#always + #asked, 0, "it is no advantage on other Constitution saves")
    -- advantage that is there anyway: nothing to ask
    table.insert(RPSheet:Sheet().passives, { name = "War Caster", desc = "", auto = "test", enabled = true, effects = {} })
    state.conditions.Concentrating = true
    MENU = false
    Eq(D20s(function() RPSheet:TakeDamage(4) end), 2, "with War Caster the save has advantage without asking")
    Check(not MENU, "no menu")
    table.remove(RPSheet:Sheet().passives)
    -- without the option: no question
    Build("EVOKER", "", 5)
    RPSheet:State().conditions.Concentrating = true
    MENU = false
    Eq(D20s(function() RPSheet:TakeDamage(4) end), 1, "without Extended Spell the save rolls at once")
    Check(not MENU, "no menu")
end)

Section("a bonus or penalty to the next roll", function()
    Build("WARRIOR", "", 5)
    RPSheet:SetRollBonusDie(1)
    Check(RPSheet.rollBonusDie and RPSheet.rollBonusDie.sides == 4, "a click sets a d4")
    local at = #ROLLED
    Rolls(10, 3)
    RPSheet:RollCheck("Athletics", 5)
    Eq(Dice(at), "20,4", "the d4 is rolled after the d20")
    Said("rolls [Athletics]: 10 + 5 + 3 [1d4] = 18", "and shown in the line")
    Eq(RPSheet.rollBonusDie, nil, "it is used up by the roll")
    at = #ROLLED
    RPSheet:RollCheck("Athletics", 5)
    Eq(Dice(at), "20", "the next roll has none")
    -- a die taken off
    RPSheet:SetRollBonusDie(-1)
    Rolls(10, 2)
    RPSheet:RollCheck("Athletics", 5)
    Said("rolls [Athletics]: 10 + 5 - 2 [-1d4] = 13", "a die taken off")
    -- a larger die, and the click that switches it off
    RPSheet:SetRollBonusDie(1, true)
    Eq(RPSheet.rollBonusDie.sides, 4, "a right-click from nothing starts at a d4")
    RPSheet:SetRollBonusDie(1, true); RPSheet:SetRollBonusDie(1, true)
    Eq(RPSheet.rollBonusDie.sides, 8, "and grows to a d8")
    RPSheet:SetRollBonusDie(-1)
    Check(RPSheet.rollBonusDie.sign == -1 and RPSheet.rollBonusDie.sides == 4, "the other row takes over")
    RPSheet:SetRollBonusDie(-1)
    Eq(RPSheet.rollBonusDie, nil, "a second click switches it off")
    -- a number, alone and with a die
    RPSheet:ChangeRollBonusFlat(1); RPSheet:ChangeRollBonusFlat(1)
    Rolls(10)
    RPSheet:RollCheck("DEX save", 3)
    Said("rolls [DEX save]: 10 + 3 + 2 [next roll +2] = 15", "a number added")
    Eq(RPSheet.rollBonusFlat, 0, "used up as well")
    RPSheet:ChangeRollBonusFlat(-1); RPSheet:SetRollBonusDie(1)
    Rolls(10, 4)
    RPSheet:RollCheck("Athletics", 5)
    Said("rolls [Athletics]: 10 + 5 + 3 [1d4 -1] = 18", "a die and a number together")
    -- kept for every roll
    RPSheet:SetRollBonusDie(1); RPSheet:LockRollBonus()
    Rolls(10, 1); RPSheet:RollCheck("Athletics", 5)
    Rolls(10, 2); RPSheet:RollCheck("Athletics", 5)
    Said("10 + 5 + 2 [1d4] = 17", "kept: it counts for the second roll too")
    Check(RPSheet.rollBonusDie ~= nil and RPSheet.rollBonusLocked, "and stays")
    RPSheet:SetRollBonusDie(1)
    Check(not RPSheet.rollBonusLocked, "switching it off ends the keeping")
    -- an attack, an ability and a spell attack take it; a natural 20 goes by the die
    Sword()
    RPSheet:SetRollBonusDie(1)
    at = #ROLLED
    Rolls(20, 4)
    RPSheet:Attack()
    Eq(Dice(at), "20,4,8,8", "an attack: d20, the bonus die, then the damage, doubled on a natural 20")
    Check((SENT[#SENT] or ""):find("+ 4 [1d4]", 1, true) and (SENT[#SENT] or ""):find("NATURAL 20", 1, true), "in its line")
    local strike = Own("Shield bash", Kit.Roll("ATTACK", "STR"), Kit.Roll("ATTACK", "STR"))
    RPSheet:SetRollBonusDie(1)
    at = #ROLLED
    RPSheet:UseAbility(strike)
    Eq(Dice(at), "20,4,20", "an ability's first d20 takes it, its second has none")
    -- rolls that are not the row's leave it
    RPSheet:SetRollBonusDie(1)
    local state = RPSheet:State()
    state.hp = 0
    RPSheet:RollDeathSave()
    Check(RPSheet.rollBonusDie ~= nil, "a death save leaves it")
    state.hp, state.conditions.Concentrating = 20, true
    RPSheet:TakeDamage(2)
    Check(RPSheet.rollBonusDie ~= nil, "and so does the save to keep a spell")
    RPSheet:UseAbility(Ability("Second Wind"))
    Check(RPSheet.rollBonusDie ~= nil, "and an ability that rolls no d20")
    RPSheet:SetRollBonusDie(1)

    -- the rows: built once by the top part, and showing what is set
    local UI = ns.UI
    local rows, keepLabel, keepHeading = {}, UI.AddLabel, UI.AddHeading
    UI.AddLabel = function(_, _, text, onClick, title, tip)
        local row = { text = text, click = onClick, title = title, tip = tip }
        function row:SetText(new) self.text = new end
        rows[#rows + 1] = row
        return row
    end
    UI.AddHeading = function() end
    local ok, err = pcall(function()
        RPSheet.window, RPSheet.channelLabel = RPSheet.window or {}, RPSheet.channelLabel or {}
        UI.NextRollSection(RPSheet, {})
        Eq(#rows, 3, "three rows: a die added, a die taken off, a number")
        Check(rows[1].text:find("+d4", 1, true) and rows[2].text:find("-d4", 1, true) and rows[3].text:find("+N", 1, true), "showing what a click gives")
        rows[1].click("LeftButton")
        Check(RPSheet.rollBonusDie and rows[1].text:find("80ff80+d4", 1, true), "a click on the first sets the d4 and lights the row")
        rows[1].click("RightButton")
        Check(rows[1].text:find("+d6", 1, true), "a right-click grows the die")
        rows[3].click("LeftButton"); rows[3].click("RightButton"); rows[3].click("RightButton")
        Check(RPSheet.rollBonusFlat == -1 and rows[3].text:find("-1", 1, true), "the number goes up and down")
        local keepShift = IsShiftKeyDown
        IsShiftKeyDown = function() return true end
        rows[2].click("LeftButton")
        IsShiftKeyDown = keepShift
        Check(RPSheet.rollBonusLocked and rows[1].text:find("every roll", 1, true), "a Shift-click keeps it for every roll")
        Rolls(10, 5)
        RPSheet:RollCheck("Athletics", 5)
        Said("10 + 5 + 4 [1d6 -1] = 19", "the roll takes what the rows show")
        rows[1].click("LeftButton"); rows[3].click("LeftButton")
        Check(not RPSheet.rollBonusDie and RPSheet.rollBonusFlat == 0 and not RPSheet.rollBonusLocked, "all off again")
        for _, row in ipairs(rows) do
            Check(type(row.title) == "string" and type(row.tip) == "string" and #row.tip > 20, "the row has a tooltip: " .. tostring(row.title))
        end
    end)
    UI.AddLabel, UI.AddHeading = keepLabel, keepHeading
    if type(RPSheet.window) == "table" and not RPSheet.window.frame then RPSheet.window, RPSheet.channelLabel, RPSheet.rollBonusLabels = nil, nil, nil end
    Check(ok, "the rows are built without an error: " .. tostring(err))
end)

Summary("t-test-play-questions")
