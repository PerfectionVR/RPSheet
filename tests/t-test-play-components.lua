-- Spell components with a price: missing, carried, used up, one worth more, a
-- weapon, coins, ammunition, once per target, and the switch that waives the check.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Carry(name, qty) return RPSheet:AddItem(name, qty or 1) end
local function Qty(name)
    local total = 0
    for _, item in ipairs(RPSheet:Sheet().items) do if item.name == name then total = total + item.qty end end
    return total
end
local function Refill()
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then tracker.set(tracker.max) end end
end
-- Casts and says whether the spell went off (something was announced).
local function Cast(spell, ...)
    local sent = #SENT
    RPSheet:CastSpell(spell, ...)
    return #SENT > sent
end

Section("missing, carried, used up, worth more", function()
    Build("PRIEST", "", 9)
    local sheet = RPSheet:Sheet()
    local revivify, orb, lore, bond = Learn("Revivify"), Learn("Chromatic Orb"), Learn("Legend Lore"), Learn("Warding Bond")
    local s3 = Slot(3)
    local left = s3.get()
    local before = #PRINTED
    Check(not Cast(revivify), "Revivify without a diamond isn't cast")
    Check(AnyPrinted("Revivify needs something you don't have: Diamond (300 gp).", before), "the line names what is missing")
    Check(AnyPrinted("one worth more will do", before), "and says one worth more will do")
    Eq(s3.get(), left, "no slot spent")
    -- one that is worth too little
    Carry("Diamond (50 gp)")
    Check(not Cast(revivify), "a diamond worth too little won't do")
    -- one that is worth more
    Carry("Diamond (500 gp)")
    Check(Cast(revivify), "a diamond worth more will do")
    Said("uses up Diamond (500 gp)", "the casting names what it used")
    Eq(Qty("Diamond (500 gp)"), 0, "it is gone")
    Eq(Qty("Diamond (50 gp)"), 1, "the cheap one is kept")
    Eq(s3.get(), left - 1, "the slot is spent")
    -- the listed one goes before a dearer one; of others the cheapest that is worth enough
    Carry("Diamond (1000 gp)"); Carry("Diamond (500 gp)"); Carry("Diamond (300 gp)")
    Cast(revivify)
    Eq(Qty("Diamond (300 gp)"), 0, "the listed diamond is used first")
    Cast(revivify)
    Eq(Qty("Diamond (500 gp)"), 0, "then the cheapest that is worth enough")
    Eq(Qty("Diamond (1000 gp)"), 1, "the dearest is kept")
    -- a component that is kept
    Check(Cast(orb), "Chromatic Orb with a 50 gp diamond")
    Eq(Qty("Diamond (50 gp)"), 1, "which is kept")
    Check(not SENT[#SENT]:find("uses up"), "nothing is said to be used up")
    -- several of one, and two parts
    Carry("Ivory strip (50 gp)", 3); Carry("Incense (250 gp)")
    before = #PRINTED
    Check(not Cast(lore), "Legend Lore with three of four ivory strips isn't cast")
    Check(AnyPrinted("4 x Ivory strip (50 gp)", before), "the line says four are needed")
    Eq(Qty("Incense (250 gp)"), 1, "the other part is not used up by a casting that failed")
    Carry("Ivory strip (50 gp)", 1)
    Check(Cast(lore), "with four it is cast")
    Eq(Qty("Ivory strip (50 gp)"), 4, "the strips are kept")
    Eq(Qty("Incense (250 gp)"), 0, "the incense is used up")
    Carry("Platinum ring (50 gp)", 1)
    Check(not Cast(bond), "Warding Bond with one ring of two isn't cast")
    -- a ritual needs its components too
    local identify = Learn("Identify")
    Check(identify.ritual, "Identify is a ritual")
    Check(not Cast(identify, nil, true), "a ritual without its component isn't cast")
    Carry("Pearl (100 gp)")
    Check(Cast(identify, nil, true), "with the pearl it is")
    Eq(Qty("Pearl (100 gp)"), 1, "the pearl is kept")
    -- an accepted other thing
    local bless = Learn("Bless")
    Check(not Cast(bless), "Bless without a holy symbol isn't cast")
    Carry("Emblem")
    Check(Cast(bless), "an emblem serves as the holy symbol")
    -- the tooltip
    local lines = table.concat(RPSheet:ComponentHelp(revivify), "\n")
    Check(lines:find("Needs Diamond %(300 gp%), used up by the casting") and lines:find("You carry 1"), "the tooltip counts what is carried (the 1000 gp diamond)")
    Eq(#RPSheet:ComponentHelp(Learn("Cure Wounds")), 0, "no lines for a spell without a priced component")

    -- the waive switch
    sheet.componentsWaived = true
    for _, item in ipairs({ "Diamond (1000 gp)" }) do while Qty(item) > 0 do RPSheet:DropItem(RPSheet:CarriedItem(item)) end end
    Refill()
    Check(Cast(revivify), "with the check switched off the spell is cast without a diamond")
    Check(not SENT[#SENT]:find("uses up"), "and uses nothing up")
    Check(table.concat(RPSheet:ComponentHelp(revivify), "\n"):find("Components are not checked"), "the tooltip says the check is off")
    sheet.componentsWaived = false
end)

Section("weapon and coins", function()
    Build("HUNTER", "", 9)
    local sheet = RPSheet:Sheet()
    local strike, wind, barrage = Learn("True Strike"), Learn("Steel Wind Strike"), Learn("Conjure Barrage")
    local thoughts, repose = Learn("Detect Thoughts"), Learn("Gentle Repose")
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then tracker.set(tracker.max) end end
    sheet.componentsWaived = false
    Eq(#ns.ReadyWeapons(sheet), 0, "no weapon ready to begin with")
    local before = #PRINTED
    Check(not Cast(strike), "True Strike without a weapon isn't cast")
    Check(AnyPrinted("a weapon you are proficient with worth at least 1 cp", before), "the line says what weapon")
    Check(AnyPrinted("Ready such a weapon first", before), "and how to get one ready")
    local bow = Carry("Longbow"); RPSheet:SetEquipped(bow, true); RPSheet:SheetChanged()
    Check(Cast(strike), "True Strike with a longbow ready")
    Check(Cast(barrage), "Conjure Barrage with any weapon")
    -- Steel Wind Strike is 5th level: checked without casting
    Check(RPSheet:MissingComponents(wind) ~= nil, "a ranged weapon is no melee weapon")
    RPSheet:SetEquipped(bow, false)
    local sword = Carry("Longsword"); RPSheet:SetEquipped(sword, true); RPSheet:SheetChanged()
    Eq(RPSheet:MissingComponents(wind), nil, "a longsword serves Steel Wind Strike")
    Check(table.concat(RPSheet:ComponentHelp(wind), "\n"):find("Your Longsword will do"), "the tooltip names the weapon")
    -- a thrown weapon in the pack will do
    RPSheet:SetEquipped(sword, false); RPSheet:SheetChanged()
    RPSheet:DropItem(sword); RPSheet:DropItem(bow)
    Check(RPSheet:MissingComponents(strike) ~= nil, "nothing ready and nothing thrown")
    Carry("Dagger")
    Eq(RPSheet:MissingComponents(strike), nil, "a dagger in the pack serves (it can be thrown)")
    -- a weapon of the player's own: needs a worth
    RPSheet:DropItem(RPSheet:CarriedItem("Dagger"))
    local own = CopyTable(R.TEMPLATES.weapon)
    own.name = "Claws"
    table.insert(sheet.weapons, own)
    RPSheet:SheetChanged()
    Check(RPSheet:MissingComponents(strike) ~= nil, "a weapon of your own without a worth is no component")
    own.cost = 5
    Eq(RPSheet:MissingComponents(strike), nil, "with a worth it is")
    Check(RPSheet:MissingComponents(wind) ~= nil, "but 5 cp is short of the 1 sp Steel Wind Strike asks for")
    own.cost, own.ranged = 10, true
    Check(RPSheet:MissingComponents(wind) ~= nil, "and a ranged one is no melee weapon")

    -- coins
    for key in pairs(sheet.coins) do sheet.coins[key] = 0 end
    before = #PRINTED
    Check(not Cast(repose), "Gentle Repose without 2 cp isn't cast")
    Check(AnyPrinted("Gentle Repose needs something you don't have: 2 cp", before), "the line names the coins")
    sheet.coins.cp = 1
    Check(not Cast(repose), "1 cp is not enough")
    Check(Cast(thoughts), "Detect Thoughts with 1 cp")
    Eq(RPSheet:Coins(), 1, "its coin is kept")
    sheet.coins.sp = 1
    Check(Cast(repose), "Gentle Repose with 11 cp")
    Eq(RPSheet:Coins(), 9, "2 cp are used up")
    Said("uses up 2 cp", "and the casting says so")
    Check(Cast(repose, nil, true) and RPSheet:Coins() == 7, "as a ritual it uses them up too")
end)

Section("ammunition", function()
    Build("HUNTER", "", 9)
    local cordon = Learn("Cordon of Arrows")
    local before = #PRINTED
    Check(not Cast(cordon), "Cordon of Arrows without ammunition isn't cast")
    Check(AnyPrinted("4 arrows or bolts", before), "the line asks for four")
    Carry("Arrows (20)")
    Check(Cast(cordon), "with a bundle it is cast")
    Said("uses up 4 arrows or bolts", "the casting says what it used")
    Eq(Qty("Arrows (20)"), 0, "the bundle is opened")
    Eq(Qty("Arrow"), 16, "sixteen loose arrows are left")
    Refill()
    Cast(cordon)
    Eq(Qty("Arrow"), 12, "loose pieces go next")
    -- loose pieces first, then a bundle
    while Qty("Arrow") > 3 do RPSheet:DropItem(RPSheet:CarriedItem("Arrow")) end
    Carry("Bolts (20)", 2)
    Refill()
    Cast(cordon)
    Eq(Qty("Arrow"), 0, "the three loose arrows go first")
    Eq(Qty("Bolts (20)"), 1, "one bundle of bolts is opened")
    Eq(Qty("Bolt"), 19, "and one bolt taken from it")
    -- magic ammunition doesn't count
    while Qty("Bolt") > 0 do RPSheet:DropItem(RPSheet:CarriedItem("Bolt")) end
    RPSheet:DropItem(RPSheet:CarriedItem("Bolts (20)"))
    local magic = Carry("Arrows (20)")
    magic.magic = true
    Check(RPSheet:MissingComponents(cordon) ~= nil, "magic ammunition is not counted")
    Eq(RPSheet:AmmoCount(R.SPELL_COMPONENTS["Cordon of Arrows"][1]), 0, "none counted")
    -- a higher slot plants two more for each level above 2nd, as many as are carried
    RPSheet:DropItem(magic)
    Carry("Arrows (20)")
    Refill()
    RPSheet.castLevel = 3
    Check(Cast(cordon), "cast with a 3rd-level slot")
    Said("uses up 6 arrows or bolts", "a 3rd-level slot plants six")
    Eq(Qty("Arrow"), 14, "fourteen are left")
    while Qty("Arrow") > 5 do RPSheet:DropItem(RPSheet:CarriedItem("Arrow")) end
    Refill()
    RPSheet.castLevel = 3
    Check(Cast(cordon), "five pieces are enough for a 3rd-level slot")
    Said("uses up 5 arrows or bolts", "it plants the five there are")
end)

Section("once for each target", function()
    Build("MAGE", "", 17)
    local sheet = RPSheet:Sheet()
    local undead, astral = Learn("Create Undead"), Learn("Astral Projection")
    local s6, s7 = Slot(6), Slot(7)
    local before = #PRINTED
    Check(not Cast(undead), "Create Undead without an onyx isn't cast")
    Check(AnyPrinted("Black onyx (150 gp)", before), "the line names the onyx")
    Carry("Black onyx (150 gp)", 2)
    MENU = false
    local left = s6.get()
    Check(not Cast(undead), "it asks first")
    Check(MENU and MENU.title == "Create Undead: how many corpses?", "how many corpses")
    Eq(MENU and #MENU.items, 3, "up to three with a 6th-level slot")
    Check(MENU and MENU.items[3].text:find("too few components"), "the third is marked as too many for two stones")
    before = #PRINTED
    Click(MENU, "3")
    Eq(s6.get(), left, "three with two stones: not cast")
    Check(AnyPrinted("for 3 targets", before) or AnyPrinted("3 x Black onyx", before), "and a line says three are needed")
    Click(MENU, "2")
    Eq(s6.get(), left - 1, "two: cast")
    Said("for 2 corpses", "the casting names the number")
    Eq(Qty("Black onyx (150 gp)"), 2, "the stones are kept")
    Refill()
    Click(MENU, "1")
    Said("for 1 corpse", "one corpse, not corpses")
    Refill()
    -- a higher slot: one more
    RPSheet.castLevel = 7
    Cast(undead)
    Eq(MENU and #MENU.items, 4, "four with a 7th-level slot")
    Carry("Black onyx (150 gp)", 2)
    left = s7.get()
    Click(MENU, "4")
    Eq(s7.get(), left - 1, "cast at 7th level for four")
    Said("for 4 corpses", "four corpses")
    -- used up once for each target
    Carry("Jacinth (1000 gp)", 3); Carry("Silver bar (100 gp)", 2)
    MENU = false
    Cast(astral)
    Check(MENU and MENU.title == "Astral Projection: how many targets?", "how many targets")
    Eq(MENU and #MENU.items, 9, "up to nine")
    local s9 = Slot(9)
    left = s9.get()
    Click(MENU, "3")
    Eq(s9.get(), left, "three with two silver bars: not cast")
    Click(MENU, "2")
    Eq(s9.get(), left - 1, "two: cast")
    Eq(Qty("Jacinth (1000 gp)"), 1, "two jacinths used up")
    Eq(Qty("Silver bar (100 gp)"), 0, "two silver bars used up")
    Said("for 2 targets", "the casting names the number")
    -- the check switched off: no question
    sheet.componentsWaived = true
    Refill()
    MENU = false
    Check(Cast(undead), "with the check off it is cast at once")
    Check(not MENU, "without a question")
    sheet.componentsWaived = false
    -- without the game's menu: checked for one
    local keep = MenuUtil
    MenuUtil = false
    before = #PRINTED
    Check(Cast(undead), "without a menu it is cast, checked for one")
    MenuUtil = keep
    Check(AnyPrinted("Create Undead is checked for one corpse", before), "and a line says so")
end)

Summary("t-test-play-components")
