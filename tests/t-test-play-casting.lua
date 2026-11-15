-- Casting from the sheet: slots and the "Cast at" row, slot growth, rituals,
-- concentration, protective spells cast on yourself and how they end, growing spells
-- and Metamorphosis.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local function Carry(name, qty) return RPSheet:AddItem(name, qty or 1) end

Section("slots and Cast at", function()
    Build("MAGE", "", 5)
    local s1, s2, s3 = Slot(1), Slot(2), Slot(3)
    Check(s1 and s2 and s3 and not Slot(4), "a level 5 Mage has slots of levels 1 to 3")
    local bolt, missile, ray, ball = Learn("Fire Bolt"), Learn("Magic Missile"), Learn("Scorching Ray"), Learn("Fireball")
    -- a cantrip: no slot, two dice at level 5
    local at = #ROLLED
    Rolls(12, 4, 6)
    RPSheet:CastSpell(bolt)
    Eq(Dice(at), "20,10,10", "Fire Bolt at level 5: a d20 and 2d10")
    Eq(s1.get(), 4, "a cantrip spends nothing")
    Said(("casts [Fire Bolt] - spell attack: 12 + %d = %d, damage 2d10: (4 + 6) = 10"):format(RPSheet:SpellAttack(), 12 + RPSheet:SpellAttack()), "cantrip line")
    at = #ROLLED
    Rolls(20)
    RPSheet:CastSpell(bolt)
    Eq(Dice(at), "20,10,10,10,10", "a natural 20 doubles the dice")
    Said("critical damage 4d10", "critical line")
    -- a levelled spell: the lowest slot
    at = #ROLLED
    Rolls(1, 2, 3)
    RPSheet:CastSpell(missile)
    Eq(s1.get(), 3, "Magic Missile spends a 1st-level slot")
    Eq(Dice(at), "4,4,4", "three darts")
    Said("casts [Magic Missile] (1st-level slot) - damage 3d4 + 3: (1 + 2 + 3) + 3 = 9", "missile line")
    -- Cast at: 2nd, 3rd, back to lowest
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, 2, "Cast at: 2nd")
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, 3, "Cast at: 3rd")
    RPSheet:CycleCastLevel(); Eq(RPSheet.castLevel, nil, "Cast at: back to the lowest")
    RPSheet:CycleCastLevel()
    at = #ROLLED
    RPSheet:CastSpell(missile)
    Eq(s2.get(), 2, "cast at 2nd spends a 2nd-level slot")
    Eq(s1.get(), 3, "and no 1st-level one")
    Eq(Dice(at), "4,4,4,4", "four darts with a 2nd-level slot")
    Said("(2nd-level slot) - damage 4d4 + 4", "one more for each dart")
    Eq(RPSheet.castLevel, nil, "Cast at goes back after one spell")
    -- a cantrip leaves Cast at alone? it has no slot, the row is for the next spell with one
    -- several rays, more with a higher slot
    at = #ROLLED
    RPSheet:CastSpell(ray)
    Eq(Dice(at), "20,6,6,20,6,6,20,6,6", "Scorching Ray: three attacks of 2d6")
    Said("attack 3:", "each ray is named")
    RPSheet.castLevel = 3
    at = #ROLLED
    RPSheet:CastSpell(ray)
    Eq(Dice(at), "20,6,6,20,6,6,20,6,6,20,6,6", "four rays with a 3rd-level slot")
    Eq(s3.get(), 1, "a 3rd-level slot spent")
    -- a save spell
    at = #ROLLED
    RPSheet:CastSpell(ball)
    Eq(Dice(at), "6,6,6,6,6,6,6,6", "Fireball: 8d6")
    Said(("Dexterity save DC %d"):format(RPSheet:SpellDC()), "the save and its DC")
    Eq(s3.get(), 0, "the last 3rd-level slot")
    -- none left of that level or higher
    local before, sent = #PRINTED, #SENT
    RPSheet:CastSpell(ball)
    Check(AnyPrinted("No spell slot of 3rd level or higher left for Fireball", before), "no slot: a line says so")
    Eq(#SENT, sent, "and nothing is announced")
    -- the lowest slot left that fits
    s1.set(0)
    at = #ROLLED
    RPSheet:CastSpell(missile)
    Eq(s2.get(), 0, "with no 1st-level slot a 2nd-level one pays")
    Eq(Dice(at), "4,4,4,4", "and the spell grows with it")
    -- Cast at a level with nothing left
    RPSheet.castLevel = 3
    before = #PRINTED
    RPSheet:CastSpell(missile)
    Check(AnyPrinted("No spell slot of 3rd level or higher left", before), "Cast at with no slot of that level left")
    RPSheet.castLevel = nil
    -- busy: nothing
    RPSheet.busy = true
    sent = #SENT
    RPSheet:CastSpell(bolt)
    Eq(#SENT, sent, "nothing is cast while another roll is going")
    RPSheet.busy = false
    -- a long rest gives everything back
    RPSheet:LongRest()
    Check(s1.get() == 4 and s2.get() == 3 and s3.get() == 2, "a long rest restores the slots")
end)

Section("slot growth, second rolls, concentration, rituals", function()
    Build("MAGE", "", 9)
    local knife, curse, detect, image, hold = Learn("Ice Knife"), Learn("Bestow Curse"), Learn("Detect Magic"), Learn("Major Image"), Learn("Hold Person")
    local state = RPSheet:State()
    -- a second roll of its own
    local at = #ROLLED
    RPSheet:CastSpell(knife)
    Eq(Dice(at), "20,10,6,6", "Ice Knife: the attack, 1d10, then 2d6 for the burst")
    Said("cold damage in the burst 2d6", "second roll named")
    RPSheet.castLevel = 3
    at = #ROLLED
    Rolls(20)
    RPSheet:CastSpell(knife)
    Eq(Dice(at), "20,10,10,6,6,6,6", "at 3rd level the burst has 4d6; a critical hit doubles only the first roll")
    -- what is only stated
    RPSheet:CastSpell(hold)
    Check(state.conditions.Concentrating, "Hold Person: concentrating")
    Said("concentrating", "says concentrating")
    Check(not (SENT[#SENT]):find("targets"), "no targets note at the spell's own level")
    RPSheet.castLevel = 4
    RPSheet:CastSpell(hold)
    Said("targets: 3", "two more targets with a slot two levels higher")
    Said("concentrating on it now, the earlier spell ends", "a second concentration spell replaces the first")
    -- no concentration from a slot level on
    state.conditions.Concentrating = nil
    RPSheet:CastSpell(curse)
    Check(state.conditions.Concentrating, "Bestow Curse at 3rd level needs concentration")
    state.conditions.Concentrating = nil
    RPSheet.castLevel = 5
    RPSheet:CastSpell(curse)
    Check(not state.conditions.Concentrating, "Bestow Curse at 5th level needs none")
    -- rituals
    Check(detect.ritual, "Detect Magic is a ritual")
    local s1 = Slot(1)
    local left = s1.get()
    RPSheet:CastSpell(detect, nil, true)
    Eq(s1.get(), left, "a ritual spends no slot")
    Said("casts [Detect Magic] (as a ritual, no slot) - concentrating", "ritual line")
    RPSheet:CastSpell(detect)
    Eq(s1.get(), left - 1, "cast the usual way it spends one")
    left = s1.get()
    RPSheet:CastSpell(knife, nil, true)
    Eq(s1.get(), left, "a spell that is no ritual is not cast by a right-click")
    Printed("is not a ritual", "and a line says what a right-click is for")
    -- the tooltip lines
    local lines = RPSheet:SlotGrowthHelp(knife)
    Check(#lines > 0 and table.concat(lines, " "):find("It also rolls 2d6"), "the tooltip tells of the second roll")
    Eq(#RPSheet:SlotGrowthHelp(Learn("Fire Bolt")), 0, "no slot lines for a cantrip")
end)

Section("protective spells cast on yourself", function()
    Build("MAGE", "", 9)
    local state = RPSheet:State()
    local stone, energy, shield, bond, mind = Learn("Stoneskin"), Learn("Protection from Energy"), Learn("Fire Shield"), Learn("Warding Bond"), Learn("Hold Person")
    Carry("Diamond dust (100 gp)", 3)
    local s4 = Slot(4)
    local left = s4.get()
    -- the question comes first; nothing is spent until it is answered
    local sent = #SENT
    RPSheet:CastSpell(stone)
    Check(MENU and MENU.title == "Stoneskin: who is it for?", "Stoneskin asks who it is for")
    Eq(MENU and #MENU.items, 2, "yourself or someone else")
    Eq(s4.get(), left, "no slot spent before the answer")
    Eq(#SENT, sent, "nothing announced before the answer")
    Eq(RPSheet:CarriedItem("Diamond dust (100 gp)").qty, 3, "no component used before the answer")
    Click(MENU, "Someone else")
    Eq(s4.get(), left - 1, "cast on someone else: the slot is spent")
    Check(not Passive("Stoneskin (spell)"), "and no ward is switched on")
    Check(state.conditions.Concentrating, "concentrating all the same")
    Eq(RPSheet:CarriedItem("Diamond dust (100 gp)").qty, 2, "the component is used up")
    RPSheet:CastSpell(stone)
    Click(MENU, "Yourself")
    local ward = Passive("Stoneskin (spell)")
    Check(ward and ward.enabled, "cast on yourself: the ward is on")
    Said("resistance to bludgeoning, piercing, slashing damage while it lasts", "the announcement says what it gives")
    Check(RPSheet:Defenses().resist.slashing ~= nil, "slashing damage is resisted")
    local max = RPSheet:MaxHP()
    state.conditions.Concentrating = nil -- (so the damage rolls no save here)
    RPSheet:TakeDamage(9, "slashing")
    Eq(HP(), max - 4, "Take damage halves it")
    state.conditions.Concentrating = true

    -- a choice of options
    RPSheet:CastSpell(energy)
    Check(MENU and MENU.title == "Protection from Energy: who is it for?", "Protection from Energy asks")
    Eq(MENU and #MENU.items, 6, "five kinds and someone else")
    Check(Passive("Stoneskin (spell)") ~= nil, "the earlier ward holds while the menu is open")
    Click(MENU, "Yourself: fire")
    Check(Passive("Protection from Energy (fire)") ~= nil, "the fire option's ward is on")
    Check(not Passive("Stoneskin (spell)"), "the earlier concentration spell's ward ended")
    Said("concentrating on it now, the earlier spell ends", "says the earlier spell ends")
    -- another option of the same spell replaces the first
    RPSheet:CastSpell(energy)
    Click(MENU, "Yourself: cold")
    Check(Passive("Protection from Energy (cold)") and not Passive("Protection from Energy (fire)"), "another option replaces the first")
    -- a concentration spell that is no ward ends it
    RPSheet:CastSpell(mind)
    Check(not Passive("Protection from Energy (cold)"), "a new concentration spell ends the ward")
    -- always on the caster, with a choice
    RPSheet:CastSpell(shield)
    Check(MENU and MENU.title == "Fire Shield: which one?", "Fire Shield asks which one")
    Eq(MENU and #MENU.items, 2, "two shields, no one else")
    Click(MENU, "Chill shield")
    Check(Passive("Fire Shield (chill shield)") ~= nil and RPSheet:Defenses().resist.fire ~= nil, "the chill shield resists fire")
    -- it needs no concentration: unticking Concentrating leaves it
    RPSheet:ToggleCondition("Concentrating")
    Check(Passive("Fire Shield (chill shield)") ~= nil, "a ward without concentration stays when concentration ends")
    -- the caster's side of a bond, without a question
    Carry("Platinum ring (50 gp)", 2)
    MENU = false
    RPSheet:CastSpell(bond)
    Check(not MENU, "Warding Bond asks nothing")
    Check(Passive("Warding Bond (you guard)") ~= nil, "the caster's side is on")
    Eq(RPSheet:CarriedItem("Platinum ring (50 gp)").qty, 2, "the rings are kept")

    -- ending by a click, then upkeep clears it
    local fire = Passive("Fire Shield (chill shield)")
    fire.enabled = false
    RPSheet:SheetChanged()
    ns.ApplyClassFeatures(RPSheet:Sheet())
    Check(not Passive("Fire Shield (chill shield)"), "a ward clicked off is cleared away")
    -- rests: an hour ends Warding Bond; 8 hours end Wind Walk; a day-long one stays
    RPSheet:StartWard("Wind Walk", 1); RPSheet:StartWard("Mind Blank", 1); RPSheet:StartWard("Aura of Life", 1)
    state.conditions.Concentrating = true
    RPSheet:ShortRest()
    Check(not Passive("Warding Bond (you guard)"), "a short rest ends an hour-long ward")
    Check(not Passive("Aura of Life (spell)"), "and one of under an hour")
    Check(Passive("Wind Walk (as a cloud)") and Passive("Mind Blank (spell)"), "longer ones stay")
    RPSheet:StartWard("Stoneskin", 1)
    RPSheet:StartWard("Protection from Energy", 1, true)
    RPSheet:LongRest()
    Check(not Passive("Wind Walk (as a cloud)"), "a long rest ends an 8-hour ward")
    Check(Passive("Mind Blank (spell)") ~= nil, "a 24-hour ward outlasts a long rest")
    Check(not Passive("Stoneskin (spell)") and not Passive("Protection from Energy (acid)"), "and nothing short stays")
    Check(not state.conditions.Concentrating, "a long rest ends concentration")
    -- someone else's spell doesn't hang on your concentration
    RPSheet:StartWard("Stoneskin", 1, true)
    state.conditions.Concentrating = true
    RPSheet:ToggleCondition("Concentrating")
    Check(Passive("Stoneskin (spell)") ~= nil, "another caster's ward stays when your concentration ends")
    -- without the game's menu
    local keep = MenuUtil
    MenuUtil = false
    local before = #PRINTED
    left = s4.get()
    RPSheet:CastSpell(stone)
    MenuUtil = keep
    Eq(s4.get(), left - 1, "without a menu the spell is still cast")
    Check(AnyPrinted("If Stoneskin is on you, add its protection as a passive of your own", before), "and a line says how to add the protection")
end)

Section("a menu that is not answered ends nothing", function()
    -- A concentration spell whose components are needed for each target: test data,
    -- since no listed spell is both.
    Build("MAGE", "", 9)
    local state = RPSheet:State()
    local bless = Learn("Bless")
    local keepParts, keepRule = R.SPELL_COMPONENTS["Bless"], R.COMPONENT_TARGETS["Bless"]
    R.SPELL_COMPONENTS["Bless"] = { { item = "Pearl (100 gp)", cost = 10000, consumed = false, qty = 1, each = "target", accept = { Pearl = true } } }
    R.COMPONENT_TARGETS["Bless"] = { max = 3 }
    Carry("Pearl (100 gp)", 3)
    RPSheet:StartWard("Stoneskin", 1)
    state.conditions.Concentrating = true
    RPSheet:CastSpell(bless)
    Check(MENU and MENU.title == "Bless: how many targets?", "the test spell asks how many")
    Check(Passive("Stoneskin (spell)") ~= nil, "the old spell's ward holds while the question is open")
    if MENU then Click(MENU, "2") end
    Check(not Passive("Stoneskin (spell)"), "and ends once the new spell is cast")
    Said("for 2 targets", "the casting names the number")
    R.SPELL_COMPONENTS["Bless"], R.COMPONENT_TARGETS["Bless"] = keepParts, keepRule
end)

Section("growing spell", function()
    Build("WARLOCK", "", 5)
    local curse = Learn("Curse of Agony")
    local slot
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then slot = tracker end end
    local left = slot.get()
    local at = #ROLLED
    RPSheet:CastSpell(curse)
    Eq(slot.get(), left - 1, "casting it spends a slot")
    Eq(Dice(at), "4", "the first die is a d4")
    Eq(RPSheet:GrowingSides(curse), 6, "the next turn rolls a d6")
    Check(RPSheet:SpellText(curse):find("running, next 1d6"), "the row says it is running")
    local sizes = { 6, 8, 10, 12, 12 }
    for _, sides in ipairs(sizes) do
        at = #ROLLED
        RPSheet:CastSpell(curse)
        Eq(Dice(at), tostring(sides), "the die grows to a d" .. sides)
    end
    Eq(slot.get(), left - 1, "the later turns spend nothing")
    Said("[Curse of Agony] grows after a failed save - damage 1d12", "grow line")
    Said("Constitution save DC", "with the save")
    -- a right-click ends it
    RPSheet:CastSpell(curse, nil, true)
    Said("[Curse of Agony] ends.", "end line")
    Eq(RPSheet:GrowingSides(curse), nil, "no longer running")
    RPSheet:CastSpell(curse)
    Eq(slot.get(), left - 2, "cast anew it spends a slot again")
    RPSheet:LongRest()
    Eq(RPSheet:GrowingSides(curse), nil, "a long rest ends it")
end)

Section("Metamorphosis", function()
    Build("DEMONHUNTER", "Demon Hunter", 9)
    local state = RPSheet:State()
    local meta = Spell("Metamorphosis") or Learn("Metamorphosis")
    local names = R.METAMORPHOSIS.order
    for _, name in ipairs(names) do
        local passive = Passive(name)
        Check(passive and not passive.enabled, name .. " is on the sheet, switched off")
    end
    local slot = Slot(3)
    if not Check(slot ~= nil, "a level 9 Demon Hunter has 3rd-level slots") then return end
    local left, ac, max = slot.get(), RPSheet:AC(), RPSheet:MaxHP()
    state.hp = max - 10
    RPSheet:CastSpell(meta)
    Check(MENU and MENU.title == "Metamorphosis: choose a benefit", "the spell asks for a benefit")
    Eq(MENU and #MENU.items, 3, "three benefits")
    Eq(slot.get(), left, "nothing spent before the pick")
    Click(MENU, "Vengeance")
    Eq(slot.get(), left - 1, "the slot is spent with the pick")
    Eq(RPSheet:AC(), ac + 2, "Vengeance: +2 Armor Class")
    Eq(RPSheet:MaxHP(), max + 5, "5 more maximum hit points")
    Eq(HP(), max - 5, "and 5 more current ones")
    Said("casts [Metamorphosis] (3rd-level slot) - +2 Armor Class and 5 more hit points", "the announcement")
    -- the same again: nothing twice
    RPSheet:CastSpell(meta); Click(MENU, "Vengeance")
    Eq(HP(), max - 5, "the same benefit again gives no more hit points")
    -- another benefit ends this one
    state.hp = max + 5
    slot.set(slot.max)
    RPSheet:CastSpell(meta); Click(MENU, "Havoc")
    Check(not Passive(names[3]).enabled and Passive(names[2]).enabled, "Havoc ends Vengeance")
    Eq(RPSheet:MaxHP(), max, "the maximum is back")
    Eq(HP(), max, "and current hit points come back inside it")
    local sword = Carry("Longsword"); RPSheet:SetEquipped(sword, true); RPSheet:SheetChanged()
    local at = #ROLLED
    Rolls(10)
    RPSheet:Attack()
    Eq(Dice(at), "20,8,6", "Havoc: a melee hit rolls 1d6 more")
    Said("fire damage 1d6", "as fire damage")
    at = #ROLLED
    Rolls(20)
    RPSheet:Attack()
    Eq(Dice(at), "20,8,8,6,6", "doubled on a critical hit")
    -- Devourer: low force dice
    slot.set(slot.max)
    RPSheet:CastSpell(meta); Click(MENU, "Devourer")
    Eq(RPSheet:FeatureFlag("forceMin"), 3, "Devourer raises force dice to 3")
    local missile = Learn("Magic Missile")
    Rolls(1, 2, 4)
    RPSheet:CastSpell(missile)
    Said("damage 3d4 + 3: (3 + 3 + 4) + 3 = 13 [2 low dice raised to 3]", "force dice of 1 and 2 count as 3")
    local bolt = Learn("Fire Bolt")
    Rolls(10, 1)
    RPSheet:CastSpell(bolt)
    Check(not SENT[#SENT]:find("raised"), "fire dice are left alone")
    -- a rest ends the benefit
    RPSheet:ShortRest()
    Check(not Passive(names[1]).enabled, "a short rest ends the benefit")
    RPSheet:CastSpell(meta); Click(MENU, "Vengeance")
    state.hp = RPSheet:MaxHP()
    RPSheet:LongRest()
    Check(not Passive(names[3]).enabled, "a long rest ends the benefit")
    Eq(HP(), max, "hit points are back to the usual maximum")
    -- Metamorphosis needs no concentration: a ward that does stays
    RPSheet:StartWard("Stoneskin", 1)
    state.conditions.Concentrating = true
    RPSheet:CastSpell(meta); Click(MENU, "Havoc")
    Check(Passive("Stoneskin (spell)") ~= nil and state.conditions.Concentrating, "Metamorphosis leaves a concentration spell running")
    -- by a click on the passive: one at a time, hit points given
    local keep = MenuUtil
    MenuUtil = false
    local before = #PRINTED
    slot.set(slot.max)
    left = slot.get()
    RPSheet:CastSpell(meta)
    MenuUtil = keep
    Eq(slot.get(), left - 1, "without a menu the spell is still cast")
    Check(AnyPrinted("Switch on the benefit of Metamorphosis yourself", before), "and a line says to switch the benefit on")
    local vengeance = Passive(names[3])
    state.hp = 10
    vengeance.enabled = true
    RPSheet:PassiveSwitchedOn(vengeance)
    Check(not Passive(names[2]).enabled, "switching one on by hand ends the other")
    Eq(HP(), 15, "and gives the hit points")
end)

Section("dice still in the air", function()
    Build("MAGE", "", 5)
    local state = RPSheet:State()
    local ball, bolt = Learn("Fireball"), Learn("Fire Bolt")
    local s3 = Slot(3)
    HOLD_ROLLS = true
    local sent = #SENT
    RPSheet:CastSpell(ball)
    Check(RPSheet.busy and RPSheet:IsRolling(), "the sheet waits for the first die")
    Eq(s3.get(), s3.max, "nothing is spent while the dice are rolling")
    -- everything else waits
    RPSheet:CastSpell(bolt)
    RPSheet:RollCheck("Athletics", 1)
    local before = #PRINTED
    RPSheet:StartWard("Time Dilation", 1)
    RPSheet:TakeDamage(5)
    Check(AnyPrinted("Another roll is still going", before), "damage with a ward's dice says to try again")
    Eq(HP(), RPSheet:MaxHP(), "and takes nothing")
    Eq(#HELD, 1, "only the one die was asked for")
    LandRolls()
    HOLD_ROLLS = false
    Eq(#SENT, sent + 1, "one spell is announced once its dice have landed")
    Eq(s3.get(), s3.max - 1, "and its slot is spent then")
    Check(not RPSheet.busy, "the sheet is free again")
    -- a roll that never comes back: nothing spent, nothing announced, the sheet is free again
    HOLD_ROLLS = true
    sent = #SENT
    RPSheet:CastSpell(ball)
    before = #PRINTED
    FlushTimers()
    Check(AnyPrinted("Couldn't read the roll result from chat", before), "a lost roll is given up with a line")
    Check(not RPSheet.busy and not RPSheet:IsRolling(), "and the sheet is free again")
    Eq(s3.get(), s3.max - 1, "the slot is kept")
    HELD = {}
    HOLD_ROLLS = false
    -- someone else's roll, or another die, is not taken for ours
    HOLD_ROLLS = true
    RPSheet:CastSpell(ball)
    RPSheet:CHAT_MSG_SYSTEM(nil, "Someone rolls 3 (1-6)")
    RPSheet:CHAT_MSG_SYSTEM(nil, "Tester rolls 3 (1-20)")
    RPSheet:CHAT_MSG_SYSTEM(nil, "Tester rolls 3 (2-6)")
    Check(RPSheet:IsRolling(), "other rolls in chat are not taken for the one awaited")
    HOLD_ROLLS = false
    HELD = {}
    RPSheet:CHAT_MSG_SYSTEM(nil, "Tester rolls 2 (1-6)") -- the first die; the others land by themselves now
    Said("damage 8d6: (2 + 3 + 3 + 3 + 3 + 3 + 3 + 3) = 23", "the player's own roll of the right die is")
    Check(not state.conditions.Concentrating, "Fireball needs no concentration")
end)

Summary("t-test-play-casting")
