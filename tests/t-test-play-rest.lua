-- Short and long rests, hit dice, abilities that recover or make spell slots, costs
-- that can be taken back, and a Warlock with another spellcasting class.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local BROADCASTS = 0
local Queue = RPSheet.QueueBroadcast
function RPSheet:QueueBroadcast() BROADCASTS = BROADCASTS + 1; return Queue(self) end

Section("rests", function()
    local sheet = Build("WARRIOR", "Champion", 8, { extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    local wind, surge, recovery = Tracker("Second Wind"), Tracker("Action Surge"), Tracker("Arcane Recovery")
    local d10, d6, s1, s2 = Tracker("Hit Dice (d10)"), Tracker("Hit Dice (d6)"), Slot(1), Slot(2)
    if not Check(wind and surge and recovery and d10 and d6 and s1 and s2, "the trackers of a Warrior 5 / Mage 3") then return end
    -- spend everything
    wind.set(0); surge.set(0); recovery.set(0); d10.set(1); d6.set(0); s1.set(0); s2.set(0)
    state.hp, state.tempHP, state.exhaustion = 7, 6, 2
    state.conditions.Concentrating, state.conditions.Poisoned = true, true
    state.deathPass, state.deathFail = 2, 1
    state.prepareClosed, state.prepareSwap, state.cantripSwap, state.petMasteryChanged = true, true, true, true
    state.freeUsed["Something"] = true
    RPSheet.refunds = { ["Tactical Mind"] = { costs = {}, why = "x", sheet = RPSheet.sheetKey } }
    RPSheet:StartWard("Protection from Poison", 1); RPSheet:StartWard("Heroes' Feast", 1)
    local was = BROADCASTS
    RPSheet:ShortRest()
    Eq(wind.get(), 1, "a short rest gives one Second Wind back")
    Eq(surge.get(), 1, "and Action Surge")
    Eq(recovery.get(), 0, "not Arcane Recovery")
    Check(s1.get() == 0 and s2.get() == 0, "nor spell slots")
    Check(d10.get() == 1 and d6.get() == 0, "nor hit dice")
    Eq(HP(), 7, "nor hit points")
    Eq(state.tempHP, 6, "temporary hit points stay")
    Eq(state.exhaustion, 2, "exhaustion stays")
    Check(state.conditions.Poisoned, "conditions stay")
    Check(not Passive("Protection from Poison (spell)") and Passive("Heroes' Feast (spell)"), "an hour-long ward ends, a day-long one stays")
    Check(RPSheet.refunds == nil, "an older cost can't be taken back after a rest")
    Said("finishes a short rest (regains Second Wind, Action Surge).", "the short rest's line")
    Check(BROADCASTS > was, "a short rest tells the group")
    -- nothing to regain
    RPSheet:ShortRest()
    Said("finishes a short rest (regains Second Wind).", "a second short rest gives another Second Wind")
    wind.set(wind.max)
    RPSheet:ShortRest()
    Said("finishes a short rest.", "with nothing to regain it says only that")

    was = BROADCASTS
    RPSheet:LongRest()
    Eq(HP(), max, "a long rest restores hit points")
    Check(d10.get() == d10.max and d6.get() == d6.max, "and all hit dice")
    Check(s1.get() == s1.max and s2.get() == s2.max, "and spell slots")
    Check(wind.get() == wind.max and surge.get() == 1 and recovery.get() == 1, "and resources")
    Eq(state.tempHP, 0, "temporary hit points end")
    Eq(state.exhaustion, 1, "one level of exhaustion goes")
    Check(not state.conditions.Concentrating, "concentration ends")
    Check(state.conditions.Poisoned, "other conditions stay")
    Eq(state.deathPass + state.deathFail, 0, "death saves are cleared")
    Check(not state.prepareClosed and not state.prepareSwap and not state.cantripSwap and not state.petMasteryChanged, "the once-a-rest changes are open again")
    Check(next(state.freeUsed) == nil, "free first uses are back")
    Check(Passive("Heroes' Feast (spell)") ~= nil, "a day-long ward outlasts the rest")
    Said("finishes a long rest.", "the long rest's line")
    Check(BROADCASTS > was, "a long rest tells the group")
    -- a human wakes up inspired
    Check(Passive("Resourceful") ~= nil, "a human has Resourceful")
    Check(state.inspiration == true, "and wakes up with Heroic Inspiration")
    -- a long rest while dead at 0? hit points come back only for the living: the sheet leaves that to the table
end)

Section("hit dice", function()
    local sheet = Build("WARRIOR", "Champion", 8, { extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    local con = RPSheet:Mod("CON")
    local d10, d6 = Tracker("Hit Dice (d10)"), Tracker("Hit Dice (d6)")
    state.hp = 10
    local at, was = #ROLLED, BROADCASTS
    Rolls(4)
    RPSheet:SpendHitDie()
    Eq(Dice(at), "10", "without a bar named the first pool is used")
    Eq(d10.get(), d10.max - 1, "one die spent")
    Eq(HP(), 10 + 4 + con, "healed by the die and Constitution")
    Said(("spends a hit die - healing 1d10 + %d: 4 + %d = %d (now %d/%d HP)"):format(con, con, 4 + con, 14 + con, max), "the line")
    Check(BROADCASTS > was, "spending a hit die tells the group")
    at = #ROLLED
    Rolls(6)
    RPSheet:SpendHitDie(Tracker("Hit Dice (d6)"))
    Eq(Dice(at), "6", "the d6 pool rolls a d6")
    Eq(d6.get(), d6.max - 1, "and spends its own die")
    -- never above the maximum
    state.hp = max - 1
    RPSheet:SpendHitDie()
    Eq(HP(), max, "healing stops at the maximum")
    -- none left
    d10.set(0)
    local before = #PRINTED
    at = #ROLLED
    RPSheet:SpendHitDie()
    Eq(#ROLLED, at, "no die without a hit die left")
    Check(AnyPrinted("No hit dice left", before), "a line says so")
    -- back from 0: death saves cleared
    state.hp, state.deathFail = 0, 2
    RPSheet:SpendHitDie(Tracker("Hit Dice (d6)"))
    Eq(state.deathFail, 0, "death saves are cleared")
    -- a low Constitution still heals 1
    Build("MAGE", "", 3, { base = { STR = 8, DEX = 8, CON = 3, INT = 15, WIS = 8, CHA = 8 } })
    state = RPSheet:State()
    if RPSheet:Mod("CON") <= -2 then
        state.hp = 1
        Rolls(1)
        RPSheet:SpendHitDie()
        Eq(HP(), 2, "a hit die heals at least 1")
    end
    -- a troll's hit dice heal their maximum
    Build("WARRIOR", "", 3, { species = "TROLL" })
    state = RPSheet:State()
    if Check(RPSheet:TraitValue("hitDieMax") == true, "a troll has Troll Healing") then
        state.hp = 1
        Rolls(2)
        RPSheet:SpendHitDie()
        Eq(HP(), 1 + 10 + RPSheet:Mod("CON"), "a troll's hit die counts as its maximum")
    end
end)

Section("recovering and making slots", function()
    -- Arcane Recovery: half the Mage level rounded up, highest spent slots first, none above 5th
    Build("MAGE", "", 5)
    local s1, s2, s3 = Slot(1), Slot(2), Slot(3)
    local recover = Ability("Arcane Recovery")
    local before = #PRINTED
    RPSheet:UseAbility(recover)
    Check(AnyPrinted("No spent spell slot of 5th level or lower to recover", before), "nothing spent: nothing to recover")
    Eq(Tracker("Arcane Recovery").get(), 1, "and the use is kept")
    s1.set(0); s2.set(0); s3.set(0)
    RPSheet:UseAbility(recover)
    Eq(s3.get(), 1, "a budget of 3 brings back one 3rd-level slot")
    Check(s2.get() == 0 and s1.get() == 0, "and nothing else")
    Said("uses [Arcane Recovery] (1 Arcane Recovery) - recovers 1 3rd-level slot", "the line")
    Eq(Tracker("Arcane Recovery").get(), 0, "the use is spent")
    before = #PRINTED
    RPSheet:UseAbility(recover)
    Check(AnyPrinted("Not enough Arcane Recovery", before), "once per long rest")
    Tracker("Arcane Recovery").set(1)
    s3.set(s3.max)
    RPSheet:UseAbility(recover)
    Check(s2.get() == 1 and s1.get() == 1, "with the 3rd-level slots full: a 2nd and a 1st")
    -- level 12: budget 6, a 6th-level slot never comes back
    Build("MAGE", "", 12)
    for level = 1, 6 do Slot(level).set(0) end
    RPSheet:UseAbility(Ability("Arcane Recovery"))
    Eq(Slot(6).get(), 0, "no 6th-level slot comes back")
    Check(Slot(5).get() == 1 and Slot(1).get() == 1, "a 5th and a 1st for a budget of 6")
    -- a Land druid's goes by the druid level, a Mage's by the Mage level
    Build("DRUID", "Circle of the Land", 9, { extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
    for level = 1, 5 do Slot(level).set(0) end
    RPSheet:UseAbility(Ability("Natural Recovery: slots"))
    Eq(Slot(3).get(), 1, "Natural Recovery with 6 druid levels: budget 3")
    Check(Slot(5).get() == 0 and Slot(4).get() == 0, "nothing higher")
    RPSheet:UseAbility(Ability("Arcane Recovery"))
    Eq(Slot(2).get(), 1, "Arcane Recovery with 3 Mage levels: budget 2")

    -- Font of Magic
    Build("EVOKER", "Draconic Sorcery", 5)
    local points = Tracker("Sorcery Points")
    s1, s2, s3 = Slot(1), Slot(2), Slot(3)
    local toPoints, fromPoints = Ability("Font of Magic: slot to points"), Ability("Font of Magic: points to slot")
    before = #PRINTED
    RPSheet:UseAbility(toPoints)
    Check(AnyPrinted("Your Sorcery Points are full", before), "full points: no slot is turned")
    Eq(s1.get(), s1.max, "and none is spent")
    points.set(0)
    RPSheet:UseAbility(toPoints)
    Check(s1.get() == s1.max - 1 and points.get() == 1, "the lowest slot becomes 1 point")
    RPSheet.castLevel = 3
    RPSheet:UseAbility(toPoints)
    Check(s3.get() == s3.max - 1 and points.get() == 4, "Cast at 3rd: a 3rd-level slot becomes 3 points")
    Eq(RPSheet.castLevel, nil, "Cast at goes back")
    -- points to slot: 2 for a 1st
    RPSheet:UseAbility(fromPoints)
    Check(s1.get() == s1.max and points.get() == 2, "2 points make a 1st-level slot")
    -- above the usual number
    RPSheet:UseAbility(fromPoints)
    Eq(Slot(1).get(), s1.max + 1, "a made slot can go above the usual number")
    Said("above the usual", "and the line says so")
    Eq(points.get(), 0, "the points are spent")
    before = #PRINTED
    RPSheet:UseAbility(fromPoints)
    Check(AnyPrinted("costs 2 Sorcery Points (0 left)", before), "not enough points")
    points.set(5)
    RPSheet.castLevel = 3
    RPSheet:UseAbility(fromPoints)
    Check(Slot(3).get() == s3.max and points.get() == 0, "5 points make a 3rd-level slot")
    -- the extra slot can be cast with, and is gone after a long rest
    local missile = Learn("Magic Missile")
    RPSheet:CastSpell(missile)
    Eq(Slot(1).get(), s1.max, "the extra slot is spent like any other")
    Slot(1).set(s1.max + 1) -- can't be set above
    Eq(Slot(1).get(), s1.max, "a slot bar doesn't go above the usual number by itself")
    RPSheet:State().slots[1] = s1.max + 1
    RPSheet:LongRest()
    Eq(Slot(1).get(), s1.max, "a long rest brings the slots back to the usual number")
    Eq(Slot(1).max, s1.max, "and the bar's size")
end)

Section("costs that can be taken back", function()
    Build("WARRIOR", "", 5)
    local wind, mind = Tracker("Second Wind"), Ability("Tactical Mind")
    if not Check(mind ~= nil, "a level 5 Warrior has Tactical Mind") then return end
    local left = wind.get()
    local before = #PRINTED
    RPSheet:UseAbility(mind)
    Eq(wind.get(), left - 1, "the use is spent")
    Check(AnyPrinted("Tactical Mind: if the check still failed", before), "the offer to take it back is printed")
    Check(RPSheet:TakeBack("Tactical Mind"), "it can be taken back")
    Eq(wind.get(), left, "the use is back")
    Said("keeps 1 Second Wind: the check still failed, so Tactical Mind costs nothing.", "the line")
    Check(not RPSheet:TakeBack("Tactical Mind"), "only once")
    Eq(wind.get(), left, "nothing more comes back")
    -- a new use settles the one before
    RPSheet:UseAbility(mind); RPSheet:UseAbility(mind)
    Check(RPSheet:TakeBack("Tactical Mind") and wind.get() == left - 1, "of two uses only the last can be taken back")
    -- a rest settles it
    RPSheet:UseAbility(mind)
    RPSheet:ShortRest()
    Check(not RPSheet:TakeBack("Tactical Mind"), "nothing to take back after a rest")
    -- another character's
    RPSheet:UseAbility(mind)
    RPSheet.refunds["Tactical Mind"].sheet = "someone else"
    Check(not RPSheet:TakeBack("Tactical Mind"), "another character's cost is not taken back")
    -- an ability without such a cost offers nothing
    before = #PRINTED
    RPSheet:UseAbility(Ability("Second Wind"))
    Check(not AnyPrinted("take back", before), "Second Wind offers nothing")
    Check(not RPSheet:TakeBack("Second Wind"), "and has nothing to take back")

    -- the first use after a long rest is free
    Build("ROGUE", "Soulknife", 5)
    local dice = Tracker("Psionic Energy Dice")
    local free
    for _, ability in ipairs(RPSheet:Sheet().abilities) do
        for _, action in ipairs(ability.actions) do if action.firstFree then free = ability end end
    end
    if Check(free ~= nil, "a Soulknife has an ability whose first use is free") then
        left = dice.get()
        RPSheet:UseAbility(free)
        Eq(dice.get(), left, "the first use costs nothing")
        Said("free, the first use since a long rest", "and says so")
        RPSheet:UseAbility(free)
        Eq(dice.get(), left - 1, "the second one costs a die")
        RPSheet:ShortRest()
        RPSheet:UseAbility(free)
        Eq(dice.get(), left - 1, "a short rest gives a die back but not the free use")
        RPSheet:LongRest()
        left = dice.get()
        RPSheet:UseAbility(free)
        Eq(dice.get(), left, "free again after a long rest")
    end
end)

Section("a Warlock with another spellcasting class", function()
    local sheet = Build("WARLOCK", "Fiend Patron", 8, { extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
    local s1, s2, pact = Slot(1), Slot(2), Slot(3, true)
    if not Check(s1 and s2 and pact and not Slot(3), "shared slots of levels 1 and 2 and two Pact slots of 3rd level") then return end
    Check(s1.max == 4 and s2.max == 2 and pact.max == 2, "their numbers (a Mage 3's and a Warlock 5's)")
    local missile, ball, hex = Learn("Magic Missile", "MAGE"), Learn("Fireball", "WARLOCK"), Learn("Hex", "WARLOCK")
    -- the lowest slot that fits pays, whichever kind
    RPSheet:CastSpell(missile)
    Eq(s1.get(), 3, "a 1st-level spell takes a shared 1st-level slot")
    RPSheet:CastSpell(hex)
    Eq(s1.get(), 2, "a Warlock's 1st-level spell too")
    local at = #ROLLED
    RPSheet:CastSpell(ball)
    Eq(pact.get(), 1, "a 3rd-level spell takes a Pact slot")
    Said("casts [Fireball] (Pact slot (3rd level))", "the line names the Pact slot")
    -- a Mage spell with a Pact slot, by Cast at
    RPSheet.castLevel = 3
    at = #ROLLED
    RPSheet:CastSpell(missile)
    Eq(pact.get(), 0, "Cast at 3rd: a Mage's spell with a Pact slot")
    Eq(Dice(at), "4,4,4,4,4", "five darts")
    -- nothing of 3rd level left
    local before = #PRINTED
    RPSheet:CastSpell(ball)
    Check(AnyPrinted("No spell slot of 3rd level or higher left for Fireball", before), "no 3rd-level slot left")
    -- the shared slots used up: a 1st-level spell takes a Pact slot
    pact.set(1); s1.set(0); s2.set(0)
    RPSheet:CastSpell(hex)
    Eq(pact.get(), 0, "with the shared slots spent a Pact slot pays")
    -- each class casts with its own ability
    Eq(RPSheet:CastStat(ball), "CHA", "a Warlock spell goes by Charisma")
    Eq(RPSheet:CastStat(missile), "INT", "a Mage spell by Intelligence")
    -- rests
    RPSheet:ShortRest()
    Eq(pact.get(), 2, "a short rest restores the Pact slots")
    Check(s1.get() == 0 and s2.get() == 0, "and not the shared ones")
    Said("Pact slot (3rd level)", "the short rest names them")
    -- Arcane Recovery leaves the Pact slots out
    pact.set(0)
    RPSheet:UseAbility(Ability("Arcane Recovery"))
    Eq(pact.get(), 0, "Arcane Recovery doesn't touch Pact slots")
    Eq(s2.get(), 1, "it recovers a shared 2nd-level slot (budget 2)")
    -- Magical Cunning: half the Pact slots, rounded up, and no shared slot
    pact.set(0); s1.set(0); s2.set(0)
    local cunning = Ability("Magical Cunning")
    if Check(cunning ~= nil, "a Warlock 5 has Magical Cunning") then
        RPSheet:UseAbility(cunning)
        Eq(pact.get(), 1, "Magical Cunning restores one of two Pact slots")
        Check(s1.get() == 0 and s2.get() == 0, "and no shared slot")
    end
    RPSheet:LongRest()
    Check(pact.get() == 2 and s1.get() == 4 and s2.get() == 2, "a long rest restores both kinds")
    -- Cast at cycles through both kinds' levels
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, 2, "Cast at: 2nd")
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, 3, "Cast at: 3rd, the Pact slots' level")
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, nil, "and back")

    -- a Warlock alone: its slots are the only ones and come back on a short rest
    Build("WARLOCK", "Fiend Patron", 5)
    local own = Slot(3)
    Check(own and own.max == 2 and not Slot(1) and not Slot(3, true), "a Warlock 5 alone has two 3rd-level slots")
    hex = Learn("Hex")
    RPSheet:CastSpell(hex)
    Eq(own.get(), 1, "a 1st-level spell takes a 3rd-level slot")
    own.set(0)
    RPSheet:UseAbility(Ability("Magical Cunning"))
    Eq(own.get(), 1, "Magical Cunning restores one of two slots")
    RPSheet:ShortRest()
    Eq(own.get(), 2, "back on a short rest")
    -- with a Mage who has 3rd-level slots of the shared kind: still the Pact slots
    Build("WARLOCK", "Fiend Patron", 10, { extras = { { class = "MAGE", level = 5, subclass = "Evoker" } } })
    local shared, pacts = Slot(3), Slot(3, true)
    if Check(shared and pacts, "a Warlock 5 / Mage 5 has 3rd-level slots of both kinds") then
        shared.set(0); pacts.set(0)
        RPSheet:UseAbility(Ability("Magical Cunning"))
        Eq(pacts.get(), 1, "Magical Cunning restores a Pact slot")
        Eq(shared.get(), 0, "not a shared slot of the same level")
        -- a spell takes the shared slot first, then the Pact slot of the same level
        shared.set(1)
        local ball = Learn("Fireball", "MAGE")
        RPSheet:CastSpell(ball)
        Check(shared.get() == 0 and pacts.get() == 1, "a 3rd-level spell takes the shared slot first")
        RPSheet:CastSpell(ball)
        Eq(pacts.get(), 0, "then the Pact slot")
    end
end)

Section("Unarmored Defense of two classes", function()
    local scores = { STR = 10, DEX = 14, CON = 18, INT = 8, WIS = 12, CHA = 8 }
    -- a Monk first: Wisdom, though the Shaman's Constitution would be better
    local sheet = Build("MONK", "", 4, { base = scores, extras = { { class = "SHAMAN", level = 1 } } })
    local dex, wis, con = RPSheet:Mod("DEX"), RPSheet:Mod("WIS"), RPSheet:Mod("CON")
    Check(con > wis, "Constitution is the higher one")
    Eq(RPSheet:AC(), 10 + dex + wis, "a Monk who became a Shaman keeps the Monk's Unarmored Defense")
    sheet.shield = true
    Eq(RPSheet:AC(), 10 + dex + R.SHIELD_AC, "with a shield the Monk's doesn't work, and there is no second one")
    -- a Shaman first: Constitution, with a shield too
    sheet = Build("SHAMAN", "", 4, { base = scores, extras = { { class = "MONK", level = 1 } } })
    dex, wis, con = RPSheet:Mod("DEX"), RPSheet:Mod("WIS"), RPSheet:Mod("CON")
    Eq(RPSheet:AC(), 10 + dex + con, "a Shaman who became a Monk keeps the Shaman's")
    sheet.shield = true
    Eq(RPSheet:AC(), 10 + dex + con + R.SHIELD_AC, "which works with a shield")
    -- one class
    Build("MONK", "", 4, { base = scores })
    Eq(RPSheet:AC(), 10 + RPSheet:Mod("DEX") + RPSheet:Mod("WIS"), "a Monk alone")
    Build("MAGE", "", 4, { base = scores, extras = { { class = "MONK", level = 1 } } })
    Eq(RPSheet:AC(), 10 + RPSheet:Mod("DEX") + RPSheet:Mod("WIS"), "a Mage who became a Monk gains it")
end)

Section("an ability paid with a spell slot", function()
    Build("PALADIN", "", 9, { extras = { { class = "WARLOCK", level = 3, subclass = "Fiend Patron" } } })
    local smite = Ability("Divine Smite")
    local s1, s2, pact = Slot(1), Slot(2), Slot(2, true)
    if not Check(smite and s1 and s2 and pact, "a Paladin 6 / Warlock 3 has Divine Smite, shared slots and 2nd-level Pact slots") then return end
    -- The smite asks whether the target is a fiend or an undead (Actions/PaladinFlows.lua).
    local function Use()
        RPSheet:UseAbility(smite)
        Click(MENU, "No")
    end
    local at = #ROLLED
    Use()
    Eq(Dice(at), "8,8", "Divine Smite with a 1st-level slot: 2d8")
    Eq(s1.get(), s1.max - 1, "a 1st-level slot is spent")
    Said("uses [Divine Smite] (1 1st-level slot)", "the line names the slot")
    RPSheet.castLevel = 2
    at = #ROLLED
    Use()
    Eq(Dice(at), "8,8,8", "Cast at 2nd: one die more")
    Eq(s2.get(), s2.max - 1, "a 2nd-level slot is spent")
    Eq(RPSheet.castLevel, nil, "Cast at goes back")
    -- the lowest slot left pays, a Pact slot too
    s1.set(0)
    at = #ROLLED
    Use()
    Eq(Dice(at), "8,8,8", "with no 1st-level slot a 2nd-level one pays and adds its die")
    s2.set(0)
    Use()
    Eq(pact.get(), pact.max - 1, "with the shared slots spent a Pact slot pays")
    pact.set(0)
    local before, sent = #PRINTED, #SENT
    Use()
    Eq(#SENT, sent, "with no slot at all nothing happens")
    Check(AnyPrinted("Not enough 1st-level slot for Divine Smite", before), "and a line says so")
end)

Summary("t-test-play-rest")
