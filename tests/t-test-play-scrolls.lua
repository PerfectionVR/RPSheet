-- Spell scrolls: scribing (who may, what it costs, components, stacking) and reading
-- with every branch of the rule (not a listed spell, not on the reader's list, within
-- reach, beyond it with the check passed and failed, found against scribed, a form).
dofile(ARG3 .. "/t-test-play-lib.lua")

local P = R.SCROLL_PREFIX
local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local function Qty(name)
    local total = 0
    for _, item in ipairs(RPSheet:Sheet().items) do if item.name == name then total = total + item.qty end end
    return total
end
-- A scroll someone else wrote, in the pack.
local function Found(spell, qty)
    local item = RPSheet:AddItem(P .. spell, qty or 1)
    item.scribed = nil
    return item
end
local function Gold(amount)
    local coins = RPSheet:Sheet().coins
    for key in pairs(coins) do coins[key] = 0 end
    coins.gp = amount
end

Section("scribing", function()
    local sheet = Build("MAGE", "", 7, { skills = { "Arcana" } })
    local missile, stone, bolt = Learn("Magic Missile"), Learn("Stoneskin"), Learn("Fire Bolt")
    Check((sheet.skills.Arcana or 0) >= 1, "the Mage is proficient in Arcana")
    local ways = RPSheet:ScribeWays()
    Check(ways and ways.arcana, "Arcana opens scribing")
    local list = RPSheet:ScribeSpells()
    Check(#list >= 3 and list[1].level <= list[#list].level, "the spells that can be scribed, lowest level first")
    -- costs: 15 gp and a day for a cantrip, 25 gp and a day for 1st, 1,000 gp and 10 days for 4th
    local cost, days = ns.ScribeCost(0); Check(cost == 1500 and days == 1, "a cantrip: 15 gp, 1 day")
    cost, days = ns.ScribeCost(1); Check(cost == 2500 and days == 1, "1st level: 25 gp, 1 day")
    cost, days = ns.ScribeCost(4); Check(cost == 100000 and days == 10, "4th level: 1,000 gp, 10 days")
    cost, days = ns.ScribeCost(9); Check(cost == 5000000 and days == 120, "9th level: 50,000 gp, 120 days")
    -- no money
    Gold(24)
    local can, why = RPSheet:CanScribe(missile)
    Check(not can and why:find("can't pay"), "24 gp is short of a 1st-level scroll")
    local before = #PRINTED
    Check(not RPSheet:Scribe(missile), "and none is made")
    Check(AnyPrinted("You can't scribe Magic Missile: you can't pay for the inks and parchment.", before), "a line says why")
    Gold(60)
    Check(RPSheet:Scribe(missile), "with the money it is made")
    Eq(RPSheet:Coins(), 3500, "25 gp are paid")
    local item = RPSheet:CarriedItem(P .. "Magic Missile")
    Check(item and item.scribed and item.magic and item.qty == 1, "the scroll is in the pack, marked as written by you")
    Eq(item and item.rarity, "Common", "a 1st-level scroll is common")
    Eq(item and item.cost, 5000, "worth twice what it cost")
    Said("scribes [Spell Scroll: Magic Missile] (1 day of work).", "the announcement")
    Check(RPSheet:Scribe(missile) and item.qty == 2, "a second one stacks")
    -- a cantrip
    Check(not RPSheet:CanScribe(bolt), "10 gp left: not enough for a cantrip")
    Gold(15)
    Check(RPSheet:Scribe(bolt) and RPSheet:Coins() == 0, "a cantrip costs 15 gp")
    -- components: needed, and used up when the spell uses them up
    Gold(2000)
    can, why = RPSheet:CanScribe(stone)
    Check(not can and why:find("component"), "Stoneskin can't be scribed without its diamond dust")
    RPSheet:AddItem("Diamond dust (100 gp)", 1)
    Check(RPSheet:Scribe(stone), "with it, it can")
    Eq(Qty("Diamond dust (100 gp)"), 0, "the dust is used up")
    Eq(RPSheet:Coins(), 100000, "1,000 gp are paid")
    Eq(RPSheet:CarriedItem(P .. "Stoneskin").rarity, "Rare", "a 4th-level scroll is rare")
    Said("(10 days of work)", "ten days")
    -- a found scroll of the same spell stays apart
    Found("Magic Missile")
    Gold(100)
    RPSheet:Scribe(missile)
    local scribed, found = 0, 0
    for _, entry in ipairs(sheet.items) do
        if entry.name == P .. "Magic Missile" then
            if entry.scribed then scribed = scribed + entry.qty else found = found + entry.qty end
        end
    end
    Check(scribed == 3 and found == 1, "a scroll you wrote doesn't stack with one you found")

    -- without Arcana or a scribe's tools
    Build("PRIEST", "", 5, { background = "CRIMINAL" })
    sheet = RPSheet:Sheet()
    sheet.skills.Arcana = nil
    local bless = Learn("Bless")
    Gold(100)
    if not RPSheet:ScribeWays() then
        can, why = RPSheet:CanScribe(bless)
        Check(not can and why:find("you need proficiency in Arcana or with"), "without Arcana or tools: not at all")
        before = #PRINTED
        RPSheet:Scribe(bless)
        Check(AnyPrinted("You can't scribe Bless: you need proficiency in Arcana", before), "a line says why")
        -- a scribe's tools alone: the tool at hand, and the skill sets the rarity
        sheet.tools["Calligrapher's Supplies"] = true
        ways = RPSheet:ScribeWays()
        if Check(ways and ways.scribe and not ways.arcana, "proficiency with calligrapher's supplies opens it") then
            can, why = RPSheet:CanScribe(bless)
            if not can and why and not why:find("component") then
                Check(true, "the tool has to be at hand")
                RPSheet:AddItem("Calligrapher's Supplies", 1)
            end
            RPSheet:AddItem("Emblem", 1)
            can, why = RPSheet:CanScribe(bless)
            Check(can, "with the tool carried a common scroll can be scribed" .. (why and (": " .. why) or ""))
            -- rare needs more skill than a level 5 character has (proficiency bonus +3)
            local raise = Learn("Death Ward")
            can, why = RPSheet:CanScribe(raise)
            Check(not can and why:find("skill"), "a rare scroll takes more skill without Arcana")
            -- herbs pay
            sheet.materials = sheet.materials or {}
            RPSheet:Trade().materials.herbs = 2000
            Gold(10)
            Check(RPSheet:Scribe(bless), "herbs gathered pay for the scroll")
            Eq(RPSheet:Trade().materials.herbs, 0, "the herbs are used first")
            Eq(RPSheet:Coins(), 500, "and coins make up the rest")
            Check(not RPSheet:CanScribe(bless, true), "with coins only it can't be paid now")
        end
    else
        Check(false, "the test's priest was meant to have no way to scribe")
    end
end)

Section("reading: who can", function()
    local sheet = Build("MAGE", "", 5)
    local state = RPSheet:State()
    local s1, s3 = Slot(1), Slot(3)
    -- not a scroll
    Check(not RPSheet:ReadScroll(RPSheet:AddItem("Torch", 1)), "a torch is no scroll")
    -- a spell the lists don't know: announced with the scroll's numbers, and used up
    local odd = Found("Summon Teacup")
    RPSheet:UseItem(odd)
    Said("reads [Spell Scroll: Summon Teacup] (save DC 13, spell attack +5).", "an unknown spell is only announced")
    Eq(Qty(P .. "Summon Teacup"), 0, "and the scroll is used up")
    -- not on the reader's list
    local cure = Found("Cure Wounds")
    local before, sent = #PRINTED, #SENT
    RPSheet:UseItem(cure)
    Eq(#SENT, sent, "a Mage can't read Cure Wounds")
    Check(AnyPrinted("Cure Wounds is not on your spell list", before), "a line says why")
    Eq(Qty(P .. "Cure Wounds"), 1, "the scroll is kept")
    Check(table.concat(RPSheet:ScrollHelp(cure), "\n"):find("not on your spell list"), "the tooltip says so too")
    -- within reach: no slot, the found scroll's numbers
    local ball = Found("Fireball", 2)
    local at = #ROLLED
    RPSheet:UseItem(ball)
    Eq(Dice(at), "6,6,6,6,6,6,6,6", "Fireball from a scroll: 8d6")
    Said("Dexterity save DC 15", "a found 3rd-level scroll has DC 15")
    Check(SENT[#SENT]:find("%[Fireball%]"), "the spell is named as itself: " .. SENT[#SENT])
    Check(SENT[#SENT]:find("scroll"), "and the line says it came from a scroll")
    Eq(s3.get(), s3.max, "no slot is spent")
    Eq(Qty(P .. "Fireball"), 1, "one of two scrolls is used up")
    -- a scribed one casts with the reader's own numbers
    ball.scribed = true
    RPSheet:UseItem(ball)
    Said(("Dexterity save DC %d"):format(RPSheet:SpellDC()), "a scroll you wrote has your own DC")
    Eq(Qty(P .. "Fireball"), 0, "the last one is gone")
    -- an attack spell from a found scroll: +5 for a cantrip, and it grows with the reader
    local bolt = Found("Fire Bolt")
    at = #ROLLED
    Rolls(10)
    RPSheet:UseItem(bolt)
    Eq(Dice(at), "20,10,10", "a scroll's cantrip grows with the reader's level")
    Said("spell attack: 10 + 5 = 15", "a found cantrip scroll attacks with +5")
    -- by-name facts hold for the scroll's copy: Magic Missile adds 1 for each dart
    local missile = Found("Magic Missile")
    Rolls(1, 1, 1)
    RPSheet:UseItem(missile)
    Said("3d4 + 3: (1 + 1 + 1) + 3 = 6", "Magic Missile from a scroll adds its 3")
    Eq(s1.get(), s1.max, "no 1st-level slot is spent")
    -- no components: Stoneskin without diamond dust, and its ward is switched on
    Build("MAGE", "", 7)
    state = RPSheet:State()
    local stone = Found("Stoneskin")
    MENU = false
    RPSheet:UseItem(stone)
    if Check(MENU and MENU.title == "Stoneskin: who is it for?", "a Stoneskin scroll asks who it is for") then
        Eq(Qty(P .. "Stoneskin"), 1, "the scroll is kept while the question is open")
        Click(MENU, "Yourself")
    end
    Check(Passive("Stoneskin (spell)") ~= nil, "a Stoneskin scroll read on yourself switches its ward on")
    Check(state.conditions.Concentrating, "and its reader concentrates on it")
    Eq(Qty(P .. "Stoneskin"), 0, "the scroll is used up")
    Eq(Slot(4).get(), Slot(4).max, "without a slot")
    -- the scroll goes when the spell is cast, not before: dice still in the air
    ball = Found("Fireball")
    HOLD_ROLLS = true
    RPSheet:UseItem(ball)
    Eq(Qty(P .. "Fireball"), 1, "the scroll is still there while the dice are rolling")
    local second = Found("Fire Bolt")
    sent = #SENT
    RPSheet:UseItem(second)
    Eq(Qty(P .. "Fire Bolt"), 1, "a second scroll can't be read meanwhile, and is kept")
    LandRolls()
    HOLD_ROLLS = false
    Eq(Qty(P .. "Fireball"), 0, "and gone once the spell is cast")
    Check(#SENT > sent, "the spell was announced")
    -- in a beast form: kept
    RPSheet:DropItem(second)
    Build("DRUID", "Circle of the Land", 5, { setup = function(s) s.picks.forms = { Wolf = true } end })
    local wave = Found("Thunderwave")
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    before = #PRINTED
    RPSheet:UseItem(wave)
    Check(AnyPrinted("You can't cast spells in a beast form", before), "no scroll is read in a beast form")
    Eq(Qty(P .. "Thunderwave"), 1, "and it is kept")
end)

Section("reading: beyond your own casting", function()
    local sheet = Build("MAGE", "", 5, { base = { STR = 8, DEX = 14, CON = 14, INT = 16, WIS = 10, CHA = 8 } })
    local int = RPSheet:CheckMod("INT")
    local cone = Found("Cone of Cold", 3) -- 5th level; a level 5 Mage reaches 3rd
    Check(table.concat(RPSheet:ScrollHelp(cone), "\n"):find("Intelligence check against DC 15"), "the tooltip tells of the check")
    -- failed: the scroll is lost, nothing is cast
    local at, sent = #ROLLED, #SENT
    Rolls(15 - int - 1)
    RPSheet:UseItem(cone)
    Eq(Dice(at), "20", "only the check is rolled")
    Eq(#SENT, sent + 1, "and only the check is announced")
    Said("against DC 15 - the writing fades and the scroll is lost.", "the failed check's line")
    Eq(Qty(P .. "Cone of Cold"), 2, "the scroll is lost")
    -- passed: the spell is cast with the scroll's numbers
    at, sent = #ROLLED, #SENT
    Rolls(15 - int)
    RPSheet:UseItem(cone)
    Eq(Dice(at), "20,8,8,8,8,8,8,8,8", "the check, then 8d8")
    Check(AnySaid("against DC 15 - the spell holds.", sent), "the passed check's line")
    Said("Constitution save DC 17", "a found 5th-level scroll has DC 17")
    Eq(Qty(P .. "Cone of Cold"), 1, "one scroll used up")
    -- the Next roll row is the check's
    RPSheet.rollMode = "ADV"
    at = #ROLLED
    Rolls(1, 20)
    RPSheet:UseItem(cone)
    Eq(Dice(at):sub(1, 5), "20,20", "the row's advantage goes to the check")
    Eq(RPSheet.rollMode, nil, "and is used up")
    Eq(Qty(P .. "Cone of Cold"), 0, "the last scroll is gone")
    -- exhaustion weighs on the check
    cone = Found("Cone of Cold")
    RPSheet:State().exhaustion = 1
    Rolls(15 - int + 1)
    RPSheet:UseItem(cone)
    Check(AnySaid("the writing fades", #SENT - 1), "a level of exhaustion makes the same roll fail")
    RPSheet:State().exhaustion = 0
end)

Section("reading: several classes and prepared spells", function()
    -- A Warlock 5 / Mage 3: Fireball is a Mage spell of 3rd level; the Mage part reaches
    -- 2nd, but a Fiend's Warlock keeps it prepared, and the Warlock reaches 3rd.
    local sheet = Build("WARLOCK", "Fiend Patron", 8, { base = { STR = 8, DEX = 14, CON = 14, INT = 12, WIS = 10, CHA = 18 },
        extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
    local key, reach = ns.ScrollReader(sheet, "Magic Missile")
    Check(key == "MAGE" and reach == 2, "Magic Missile is read as a Mage, who reaches 2nd level")
    key, reach = ns.ScrollReader(sheet, "Hex")
    Check(key == "WARLOCK" and reach == 3, "Hex as a Warlock, who reaches 3rd")
    key, reach = ns.ScrollReader(sheet, "Charm Person")
    Check(key == "WARLOCK" and reach == 3, "a spell on both lists goes to the class that reaches higher")
    Eq(ns.ScrollReader(sheet, "Cure Wounds"), nil, "Cure Wounds is on neither list")
    -- read as the class it belongs to: a scribed scroll uses that class's ability
    local missile = RPSheet:AddItem(P .. "Magic Missile", 1); missile.scribed = true
    local ray = RPSheet:AddItem(P .. "Ray of Sickness", 1); ray.scribed = true
    Rolls(10)
    RPSheet:UseItem(ray)
    Said(("spell attack: 10 + %d"):format(RPSheet:ProficiencyBonus() + RPSheet:Mod("INT")), "a Mage's spell from your own scroll attacks with Intelligence")
    -- a Mage's 3rd-level spell is beyond the Mage part: a check with Intelligence
    local ball = Found("Lightning Bolt")
    local help = table.concat(RPSheet:ScrollHelp(ball), "\n")
    Check(help:find("Intelligence check against DC 13"), "Lightning Bolt takes an Intelligence check: " .. help)
    -- a spell a feature keeps prepared is your own, whatever list it is from
    if Check(ns.AlwaysPrepared(sheet)["Fireball"], "a Fiend's Warlock keeps Fireball prepared") then
        key, reach = ns.ScrollReader(sheet, "Fireball")
        Check(key ~= nil, "so a Fireball scroll can be read")
    end
end)

Summary("t-test-play-scrolls")
