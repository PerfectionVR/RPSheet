-- Taking damage and healing: resistance, vulnerability, immunity, temporary hit
-- points, dropping to 0, damage while down, concentration saves, the companion die,
-- rolled wards (Resistance, Time Dilation) and both sides of Warding Bond.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Mage(opts) return Build("MAGE", "", 5, opts) end
local function Give(fields)
    local passive = { name = fields.name or "Test defense", desc = "", auto = "test", enabled = true, effects = {} }
    for k, v in pairs(fields) do passive[k] = v end
    table.insert(RPSheet:Sheet().passives, passive)
    return passive
end
local function Companion(family, loyalty)
    local entry = RPSheet:AddMount(family .. " companion")
    entry.called, entry.loyalty = true, loyalty or 10
    return entry
end

Section("plain damage and types", function()
    Mage()
    local max = RPSheet:MaxHP()
    RPSheet:TakeDamage(5, "fire")
    Eq(HP(), max - 5, "5 fire damage")
    Said(("takes 5 fire damage: %d/%d HP."):format(max - 5, max), "plain damage line")
    RPSheet:TakeDamage(3)
    Eq(HP(), max - 8, "3 damage without a type")
    Said("takes 3 damage:", "untyped line")
    Give({ resist = { "fire" }, vulnerable = { "cold" }, immune = { "poison" } })
    RPSheet:State().hp = max
    RPSheet:TakeDamage(9, "fire")
    Eq(HP(), max - 4, "9 fire, resisted, is 4")
    Said("halved to 4 (resistance: Test defense)", "resistance note")
    RPSheet:State().hp = max
    RPSheet:TakeDamage(5, "cold")
    Eq(HP(), max - 10, "5 cold, vulnerable, is 10")
    Said("doubled to 10 (vulnerability: Test defense)", "vulnerability note")
    RPSheet:State().hp = max
    RPSheet:TakeDamage(50, "poison")
    Eq(HP(), max, "poison, immune")
    Said("none of it gets through (immunity: Test defense)", "immunity note")
    -- 1 damage resisted is 0
    RPSheet:TakeDamage(1, "fire")
    Eq(HP(), max, "1 fire resisted is nothing")
    -- both on one type: halve, then double
    Give({ name = "Both", resist = { "acid" }, vulnerable = { "acid" } })
    RPSheet:TakeDamage(9, "acid")
    Eq(HP(), max - 8, "9 acid, resisted and vulnerable, is 8")
    -- the slash command: 28 fire with 5 off first: 23 halved is 11
    RPSheet:State().hp = max
    RPSheet:DamageCommand("damage", "28 fire -5")
    Eq(HP(), max - 11, "28 fire -5 resisted")
    Said("reduced by 5 to 23", "reduction note")
    local before = #PRINTED
    RPSheet:DamageCommand("damage", "14 bogus")
    Eq(HP(), max - 11, "an unknown type takes nothing")
    Check(AnyPrinted("is not a damage type", before), "an unknown damage type is refused with a line")
    RPSheet:DamageCommand("damage", "0")
    Printed("Give the damage as a number above 0", "damage 0")
    RPSheet:DamageCommand("heal", "5")
    Eq(HP(), max - 6, "heal 5")
    Said("regains 5 hit points:", "heal line")
    RPSheet:Heal(500)
    Eq(HP(), max, "healing stops at the maximum")
    Said("regains 6 hit points", "heal says what was really regained")
end)

Section("temporary hit points", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    state.tempHP = 5
    RPSheet:TakeDamage(8)
    Eq(state.tempHP, 0, "temp HP used up")
    Eq(HP(), max - 3, "what temp HP left over")
    Said("5 taken by temporary hit points", "temp HP note")
    state.tempHP = 10
    RPSheet:TakeDamage(4)
    Eq(state.tempHP, 6, "temp HP partly used")
    Eq(HP(), max - 3, "hp untouched behind temp HP")
    -- healing leaves temporary hit points alone
    RPSheet:Heal(2)
    Eq(state.tempHP, 6, "healing leaves temp HP")
end)

Section("dropping to 0 and damage while down", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    state.conditions.Concentrating = true
    state.deathFail = 1
    local sent = #SENT
    RPSheet:TakeDamage(max + 3)
    Eq(HP(), 0, "down")
    Eq(state.deathFail, 0, "death saves start clean")
    Check(AnySaid("Down at 0 HP", sent), "says down at 0")
    Check(state.conditions.Concentrating == nil, "concentration ends at 0")
    Check(AnySaid("at 0 hit points", sent), "says why concentration ended")
    Check(not RPSheet:IsRolling() and #ROLLED == 0, "no concentration save at 0")
    -- damage while down: one failure
    RPSheet:TakeDamage(3)
    Eq(state.deathFail, 1, "damage while down is a failed death save")
    Said("A failed death save: 0 passed, 1 failed", "failed save line")
    -- resisted to nothing: no failure
    Give({ immune = { "poison" } })
    RPSheet:TakeDamage(9, "poison")
    Eq(state.deathFail, 1, "damage that doesn't get through is no failure")
    -- stable, then hurt: the count starts over with one failure
    state.deathPass, state.deathFail = 3, 0
    RPSheet:TakeDamage(1)
    Eq(state.deathPass, 0, "no longer stable")
    Eq(state.deathFail, 1, "one failure after being stable")
    RPSheet:TakeDamage(1); RPSheet:TakeDamage(1)
    Eq(state.deathFail, 3, "three failures")
    Said("A third failed death save: dead", "dead line")
    local before = #PRINTED
    RPSheet:Heal(5)
    Eq(HP(), 0, "the dead don't heal")
    Check(AnyPrinted("is dead", before), "healing the dead is refused with a line")
    RPSheet:TakeDamage(1)
    Said("Already dead", "already dead")
    -- back from 0 by healing
    state.deathFail, state.deathPass = 2, 1
    RPSheet:Heal(4)
    Eq(HP(), 4, "healed from 0")
    Eq(state.deathFail + state.deathPass, 0, "death saves cleared by healing")
    Said("and is back up", "back up line")
    -- massive damage: what is left after 0 is the maximum or more
    RPSheet:TakeDamage(4 + max)
    Eq(state.deathFail, 3, "massive damage kills")
    Said("Dead: the damage left over", "massive damage line")
    state.hp, state.deathFail = 4, 0
    RPSheet:TakeDamage(3 + max)
    Eq(state.deathFail, 0, "one short of massive damage only downs")
    -- while down, a hit of the maximum kills
    RPSheet:TakeDamage(max)
    Eq(state.deathFail, 3, "a hit of the maximum while down kills")
    -- temp HP stands before death
    state.hp, state.deathFail, state.tempHP = 0, 0, 5
    RPSheet:TakeDamage(5)
    Eq(state.deathFail, 0, "temp HP takes a hit while down")
end)

Section("concentration saves", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    local mod = RPSheet:SaveMod("CON")
    state.conditions.Concentrating = true
    Rolls(10 - mod) -- just enough for DC 10
    RPSheet:TakeDamage(4)
    Check(state.conditions.Concentrating, "DC 10 met keeps the spell")
    Said("DC 10: keeps the spell", "kept line")
    Rolls(10 - mod - 1)
    RPSheet:TakeDamage(4)
    Check(not state.conditions.Concentrating, "DC 10 missed loses the spell")
    Said("DC 10: loses the spell", "lost line")
    state.hp = max
    state.conditions.Concentrating = true
    Rolls(20)
    RPSheet:TakeDamage(25)
    Said("DC 12:", "DC is half the damage")
    -- the DC goes by what got through
    Give({ resist = { "fire" } })
    state.hp = max
    Rolls(20)
    RPSheet:TakeDamage(30, "fire")
    Said("took 15 damage while concentrating", "the save is for the damage taken")
    Said("DC 10:", "DC from the halved damage")
    -- all of it taken by temp HP still calls for a save
    state.tempHP = 10
    local rolled = #ROLLED
    Rolls(20)
    RPSheet:TakeDamage(6)
    Eq(#ROLLED, rolled + 1, "damage soaked by temp HP still tests concentration")
    -- nothing through: no save
    Give({ name = "Immune", immune = { "poison" } })
    rolled = #ROLLED
    RPSheet:TakeDamage(6, "poison")
    Eq(#ROLLED, rolled, "no save when nothing gets through")
    -- War Caster: advantage
    Give({ name = "War Caster" })
    Check(RPSheet:ConcentrationAdvantage() == "War Caster", "War Caster gives advantage on the save")
    rolled = #ROLLED
    Rolls(1, 20)
    state.hp = max
    RPSheet:TakeDamage(4)
    Eq(#ROLLED, rolled + 2, "two d20s with War Caster")
    Check(state.conditions.Concentrating, "the higher die keeps it")
    Said("[advantage: 1, 20]", "advantage note")
    -- by hand: the HP bar's clicks add up and wait
    state.hp = max
    table.remove(RPSheet:Sheet().passives) -- War Caster off again
    RPSheet:DamageTaken(10); RPSheet:DamageTaken(14)
    Rolls(2)
    FlushTimers()
    Said("took 24 damage while concentrating", "clicked damage adds up")
    Said("DC 12: loses the spell", "clicked damage, failed")
    -- incapacitated ends it
    state.conditions.Concentrating = true
    RPSheet:ToggleCondition("Stunned")
    Check(not state.conditions.Concentrating, "stunned ends concentration")
    local before = #PRINTED
    RPSheet:ToggleCondition("Concentrating")
    Check(not state.conditions.Concentrating, "can't concentrate while stunned")
    Check(AnyPrinted("can't concentrate", before), "says so")
end)

Section("companion die", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    local entry = Companion("Mechanical", 10)
    Rolls(3)
    RPSheet:TakeDamage(6, "psychic")
    Eq(HP(), max - 3, "1d4 = 3 off psychic damage")
    Said("takes 1d4 = 3 off", "companion note")
    local rolled = #ROLLED
    RPSheet:TakeDamage(6, "fire")
    Eq(#ROLLED, rolled, "no die against other damage")
    entry.loyalty = 9
    RPSheet:TakeDamage(2, "psychic")
    Eq(#ROLLED, rolled, "no die below the loyalty for a gift")
    entry.loyalty = 10
    Give({ immune = { "psychic" } })
    RPSheet:TakeDamage(2, "psychic")
    Eq(#ROLLED, rolled, "no die against damage the character is immune to")
    -- the die is larger than the damage
    table.remove(RPSheet:Sheet().passives)
    state.hp = max
    Rolls(4)
    RPSheet:TakeDamage(2, "psychic")
    Eq(HP(), max, "the die can take all of it")
end)

Section("Resistance (rolled ward)", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    local fire
    for index, option in ipairs(R.SPELL_WARDS["Resistance"]) do if option.label == "fire" then fire = index end end
    RPSheet:StartWard("Resistance", fire)
    Rolls(2)
    RPSheet:TakeDamage(5, "fire")
    Eq(HP(), max - 3, "1d4 = 2 off fire")
    Said("Resistance 1d4: 2, once a turn", "ward note")
    local rolled = #ROLLED
    RPSheet:TakeDamage(5, "cold")
    Eq(#ROLLED, rolled, "the ward is for one type")
    RPSheet:TakeDamage(5, "fire", nil, false)
    Eq(#ROLLED, rolled, "ward = false rolls nothing")
    Eq(HP(), max - 13, "full damage without the ward")
    -- before resistance: (9 - 2) halved is 3
    Give({ resist = { "fire" } })
    state.hp = max
    Rolls(2)
    RPSheet:TakeDamage(9, "fire")
    Eq(HP(), max - 3, "the dice come off before resistance halves")
    -- the menu row to take it without the ward
    local found
    for _, extra in ipairs(RPSheet:DamageExtras()) do
        if extra.request and extra.request.ward == false and extra.request.damageType == "fire" then found = extra end
    end
    Check(found ~= nil, "the damage menu has a row for fire without the ward")
    -- concentration: the ward goes with it
    state.conditions.Concentrating = true
    RPSheet:ToggleCondition("Concentrating")
    Check(not Passive("Resistance (fire)"), "the ward ends with concentration")
end)

Section("Time Dilation", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:StartWard("Time Dilation", 1)
    local ward = Passive("Time Dilation (spell)")
    Check(ward ~= nil, "Time Dilation's passive is on the sheet")
    Rolls(5, 5, 5, 5)
    RPSheet:TakeDamage(30)
    Eq(HP(), max - 10, "4d8 = 20 off")
    Eq(ward and ward.owed, 4, "four dice owed")
    Check(Passive("Time Dilation (spell)") ~= nil, "the ward stays while it is owed for")
    local rolled = #ROLLED
    RPSheet:TakeDamage(2)
    Eq(#ROLLED, rolled, "it works once")
    local row
    for _, extra in ipairs(RPSheet:DamageExtras()) do if extra.run then row = extra end end
    Check(row ~= nil and row.label:find("4 to go") ~= nil, "the damage menu has the row to pay")
    state.hp, state.tempHP = max, 7
    state.conditions.Concentrating = true
    for turn = 1, 4 do
        Rolls(3)
        for _, extra in ipairs(RPSheet:DamageExtras()) do if extra.run then extra.run() end end
    end
    Eq(HP(), max - 12, "four times 3 lost")
    Eq(state.tempHP, 7, "temp HP doesn't take it")
    Check(state.conditions.Concentrating, "it is no damage: concentration untested")
    Said("the last of it", "last payment")
    Check(not Passive("Time Dilation (spell)"), "the ward is gone once paid")
    -- paying it down to 0
    RPSheet:StartWard("Time Dilation", 1)
    Rolls(1, 1, 1, 1)
    RPSheet:TakeDamage(5)
    state.hp, state.tempHP = 2, 0
    Rolls(8)
    local sent = #SENT
    RPSheet:PayWardDebt(Passive("Time Dilation (spell)"))
    Eq(HP(), 0, "the debt can drop you")
    Check(AnySaid("Down at 0 HP.", sent), "down by debt is said")
    Check(not state.conditions.Concentrating, "concentration ends at 0")
end)

Section("Warding Bond", function()
    Mage()
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:StartWard("Warding Bond", 1)
    local row
    for _, extra in ipairs(RPSheet:DamageExtras()) do if extra.label:find("Warding Bond") then row = extra end end
    Check(row and row.request and row.request.prompt and not row.request.damageType, "the caster's row takes untyped damage")
    Give({ resist = { "fire" } })
    RPSheet:TakeDamage(9) -- what the guarded one took: untyped
    Eq(HP(), max - 9, "the caster takes the same amount")
    Check(Passive("Warding Bond (you guard)") ~= nil, "the bond holds above 0")
    local before = #PRINTED
    RPSheet:TakeDamage(max)
    Check(not Passive("Warding Bond (you guard)"), "the bond ends at 0")
    Check(AnyPrinted("Warding Bond ends", before), "says the bond ended")

    -- with a ward that rolls
    RPSheet:ClearDeathSaves()
    state.hp = 3
    RPSheet:StartWard("Warding Bond", 1)
    RPSheet:StartWard("Time Dilation", 1)
    Rolls(1, 1, 1, 1)
    RPSheet:TakeDamage(20)
    Eq(HP(), 0, "down through the ward")
    Check(not Passive("Warding Bond (you guard)"), "the bond ends at 0 after a rolled ward")

    -- with the companion's die still on its way through chat
    state.hp = 3
    RPSheet:ClearDeathSaves()
    for at = #RPSheet:Sheet().passives, 1, -1 do
        if (RPSheet:Sheet().passives[at].auto or ""):find("^ward:") then table.remove(RPSheet:Sheet().passives, at) end
    end
    RPSheet:StartWard("Warding Bond", 1)
    Companion("Mechanical", 10)
    HOLD_ROLLS = true
    RPSheet:TakeDamage(20, "psychic")
    Eq(HP(), 3, "nothing taken while the die is in the air")
    Rolls(1)
    LandRolls()
    HOLD_ROLLS = false
    Eq(HP(), 0, "down once the die has landed")
    Check(not Passive("Warding Bond (you guard)"), "the bond ends at 0 when the companion's die was rolled in chat")

    -- the guarded side
    Mage()
    max = RPSheet:MaxHP()
    local ac, save = RPSheet:AC(), RPSheet:SaveMod("DEX")
    RPSheet:StartWard("Warding Bond", 2, true)
    Eq(RPSheet:AC(), ac + 1, "+1 Armor Class while guarded")
    Eq(RPSheet:SaveMod("DEX"), save + 1, "+1 to saves while guarded")
    RPSheet:TakeDamage(9, "fire")
    Eq(HP(), max - 4, "resistance to all damage while guarded")
    -- both sides can be on at once (two bonds)
    RPSheet:StartWard("Warding Bond", 1)
    Check(Passive("Warding Bond (you guard)") and Passive("Warding Bond (on you)"), "both sides of a bond stand side by side")
    -- a short rest of an hour ends the caster's bond; the guarded side is switched off and kept
    RPSheet:ShortRest()
    Check(not Passive("Warding Bond (you guard)"), "a short rest ends the bond")
    local kept = Passive("Warding Bond (on you)")
    Check(kept and not kept.enabled, "the guarded side stays, switched off")
    Eq(RPSheet:AC(), ac, "AC back to normal")
end)

Section("Petrified", function()
    Mage()
    local max = RPSheet:MaxHP()
    RPSheet:ToggleCondition("Petrified")
    RPSheet:TakeDamage(9, "fire")
    Eq(HP(), max - 4, "petrified resists all damage")
    Said("resistance: Petrified", "source named")
end)

Summary("t-test-play-damage")
