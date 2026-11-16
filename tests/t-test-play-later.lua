-- Spells rolled again after their casting (Data/SpellLater.lua): Hex and Divine Favor
-- roll their extra die on later clicks without a slot, attacks and areas on later
-- turns, rolls on the right-click menu, and how a running spell ends.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end

Section("Hex: one casting, the extra die on each hit", function()
    Build("WARLOCK", "", 5)
    local hex = Learn("Hex")
    local pact = RPSheet:PactSlots()
    local slot
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then slot = tracker end end
    local before = slot.get()
    local at = #ROLLED
    RPSheet:CastSpell(hex)
    Eq(slot.get(), before - 1, "casting Hex spends a slot")
    Eq(Dice(at), "", "casting rolls no dice: they come on a hit")
    Said("click it for a hit on the cursed creature", "the casting says how the dice are rolled")
    Check(RPSheet:SpellLaterRunning(hex), "Hex is running")
    Check(RPSheet:State().conditions.Concentrating, "and concentrating")
    Check((RPSheet:SpellText(hex) .. (RPSheet:SpellLaterRowNote(hex) or "")):find("running", 1, true) ~= nil, "the row says it runs")
    at = #ROLLED
    Rolls(5)
    RPSheet:CastSpell(hex)
    Eq(slot.get(), before - 1, "a second click spends no slot")
    Eq(Dice(at), "6", "it rolls the d6")
    Said("[Hex], a hit on the cursed creature - necrotic damage 1d6: 5 = 5", "the extra die is announced")
    Check(RPSheet:State().conditions.Concentrating, "concentration holds")
    -- right-click: the menu; End it
    RPSheet:CastSpell(hex, nil, true)
    Check(MENU and MENU.title == "Hex: running", "a right-click opens the menu")
    Click(MENU, "End it")
    Check(not RPSheet:SpellLaterRunning(hex), "ended by hand")
    -- concentration ending ends it
    RPSheet:CastSpell(hex)
    Check(RPSheet:SpellLaterRunning(hex), "cast again")
    RPSheet:ToggleCondition("Concentrating")
    Check(not RPSheet:SpellLaterRunning(hex), "losing concentration ends it")
end)

Section("Divine Favor and Hunter's Mark", function()
    Build("PALADIN", "", 5)
    local favor = Learn("Divine Favor")
    local at = #ROLLED
    RPSheet:CastSpell(favor)
    Eq(Dice(at), "", "Divine Favor rolls nothing when cast")
    Check(not RPSheet:State().conditions.Concentrating, "and needs no concentration")
    Rolls(3)
    RPSheet:CastSpell(favor)
    Said("[Divine Favor], a weapon hit - radiant damage 1d4: 3 = 3", "the extra d4 on a hit")
    -- a rest that outlasts it ends it
    RPSheet:EndWards(1)
    Check(not RPSheet:SpellLaterRunning(favor), "a short rest ends a spell of a minute")
    Build("HUNTER", "", 20)
    local mark = Learn("Hunter's Mark")
    Slot(1).set(1)
    RPSheet:CastSpell(mark)
    at = #ROLLED
    RPSheet:CastSpell(mark)
    Eq(Dice(at), "10", "Foe Slayer makes the mark's die a d10")
end)

Section("attacks and areas on later turns", function()
    Build("PRIEST", "", 5)
    local weapon = Learn("Spiritual Weapon")
    local slot = Slot(2)
    local before = slot.get()
    RPSheet:CastSpell(weapon)
    Eq(slot.get(), before - 1, "Spiritual Weapon spends a slot")
    local at = #ROLLED
    Rolls(15, 4)
    RPSheet:CastSpell(weapon)
    Eq(slot.get(), before - 1, "the later attack spends none")
    Eq(Dice(at), "20,8", "an attack roll and the d8")
    Said("another attack (a bonus action) - spell attack: 15", "the attack is announced")
    -- with a 3rd-level slot the later roll keeps the slot's extra die
    RPSheet.castLevel = 3
    local guardians = Learn("Spirit Guardians")
    RPSheet:CastSpell(guardians)
    Check(not RPSheet:SpellLaterRunning(weapon), "a new concentration spell ends the old one")
    at = #ROLLED
    RPSheet:CastSpell(guardians)
    Eq(Dice(at), "8,8,8", "Spirit Guardians later: 3d8 at 3rd level")
    Said("Wisdom save DC", "with its save")
end)

Section("Vampiric Touch heals half; right-click rolls of instant spells", function()
    Build("MAGE", "", 5)
    local touch = Learn("Vampiric Touch")
    Rolls(15, 6, 6, 6)
    RPSheet:CastSpell(touch)
    RPSheet:State().hp = 10
    RPSheet:CastSpell(touch, nil, true)
    Click(MENU, "You regain half")
    Eq(HP(), 19, "half of 18 damage is regained")
    local arrow = Learn("Melf's Acid Arrow")
    RPSheet:EndSpellsLater()
    Rolls(15, 1, 1, 1, 1)
    RPSheet:CastSpell(arrow)
    Check(not RPSheet:SpellLaterRunning(arrow), "an instant spell doesn't run")
    local at = #ROLLED
    RPSheet:CastSpell(arrow, nil, true)
    Click(MENU, "The end of the target's next turn")
    Eq(Dice(at), "4,4", "the acid's later 2d4")
    -- Wish: the stress counts once per level of the spell cast
    local wish = Learn("Wish")
    at = #ROLLED
    RPSheet:CastSpell(wish, nil, true)
    Click(MENU, "(3rd level)")
    Eq(Dice(at), "10,10,10", "a 3rd-level spell after Wish: 3d10")
end)

Section("a sequence and a growing bead", function()
    Build("MAGE", "", 17)
    local ball = Learn("Delayed Blast Fireball")
    local at = #ROLLED
    RPSheet:CastSpell(ball)
    Eq(Dice(at), "", "the bead doesn't burst when cast")
    RPSheet:CastSpell(ball)
    RPSheet:CastSpell(ball)
    Said("now 14d6", "two turns: two more dice")
    RPSheet:CastSpell(ball, nil, true)
    at = #ROLLED
    Click(MENU, "The bead explodes")
    Eq(#ROLLED - at, 14, "it bursts with 14d6")
    Check(not RPSheet:SpellLaterRunning(ball), "and the spell is over")
    local storm = Learn("Storm of Vengeance")
    RPSheet:CastSpell(storm)
    at = #ROLLED
    RPSheet:CastSpell(storm)
    Eq(Dice(at), "6,6,6,6", "second turn: acid 4d6")
    at = #ROLLED
    RPSheet:CastSpell(storm)
    Eq(#ROLLED - at, 10, "third turn: 10d6 lightning")
end)

Summary("t-test-play-later")
