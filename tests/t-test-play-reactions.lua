-- The character's own features that change damage as it is taken, and what happens
-- at 0 hit points: Evasion, Uncanny Dodge, Superior Hunter's Defense, Heavy Armor
-- Master, Stagger and Sway, Nose for Trouble, falling (Bouncy, Slow Fall), Death Ward,
-- Relentless Rage; Indomitable Might on Strength rolls; healing received through "Heal".
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Give(name) table.insert(RPSheet:Sheet().passives, { name = name, desc = "", auto = "", enabled = true, effects = {} }) end
local function Row(menu, piece)
    for _, item in ipairs(menu and menu.items or {}) do
        if item.text:find(piece, 1, true) then return item end
    end
end
-- Opens the damage menu, ticks the boxes whose text holds the pieces, and takes
-- `amount` of `type` through the box (AskAmount is caught: the request is used at once).
local function Through(amount, typeLabel, ...)
    local keep, asked = RPSheet.AskAmount, nil
    RPSheet.AskAmount = function(_, request) asked = request end
    RPSheet:OpenDamageMenu({})
    for _, piece in ipairs({ ... }) do Click(MENU, piece) end
    Click(MENU, typeLabel)
    RPSheet.AskAmount = keep
    if asked then RPSheet:TakeDamage(amount, asked.damageType, nil, asked.ward, asked.crit, asked.how) end
    return asked
end

Section("Uncanny Dodge and Evasion", function()
    Build("ROGUE", "", 7)
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:OpenDamageMenu({})
    Check(Row(MENU, "Uncanny Dodge") and Row(MENU, "passed (Evasion"), "a Rogue 7 is offered Uncanny Dodge and Evasion")
    Through(9, "Slashing", "Uncanny Dodge")
    Eq(HP(), max - 4, "Uncanny Dodge halves 9 to 4")
    Said("halved to 4 (Uncanny Dodge)", "dodge note")
    Check(state.reactionUsed, "the reaction is spent")
    RPSheet:OpenDamageMenu({})
    Check(not Row(MENU, "Uncanny Dodge"), "no Uncanny Dodge while the reaction is spent")
    local back = Row(MENU, "Your reaction is back")
    if Check(back ~= nil, "a row says the reaction is back") then back.click() end
    Check(not state.reactionUsed, "the row gives it back")
    state.hp = max
    Through(20, "Fire", "passed (Evasion")
    Eq(HP(), max, "Evasion: a passed save takes nothing")
    Through(20, "Fire", "failed (Evasion")
    Eq(HP(), max - 10, "Evasion: a failed save takes half")
    Check(not state.reactionUsed, "Evasion is no reaction")
    -- incapacitated: neither
    state.conditions.Stunned = true
    RPSheet:OpenDamageMenu({})
    Check(not Row(MENU, "Uncanny Dodge") and not Row(MENU, "Evasion"), "nothing offered while stunned")
    state.conditions.Stunned = nil
    -- initiative and rests give the reaction back
    state.reactionUsed = true
    RPSheet:RollCheck("initiative", 0, nil, false, {})
    Check(not state.reactionUsed, "initiative gives the reaction back")
    state.reactionUsed = true
    RPSheet:ShortRest()
    Check(not state.reactionUsed, "a rest gives the reaction back")
    -- a Mage has none of it
    Build("MAGE", "", 5)
    RPSheet:OpenDamageMenu({})
    Check(not Row(MENU, "Uncanny Dodge") and not Row(MENU, "Evasion") and Row(MENU, "A fall"), "a Mage only gets the fall row")
end)

Section("Superior Hunter's Defense", function()
    Build("HUNTER", "Hunter", 15)
    local max = RPSheet:MaxHP()
    Through(10, "Fire", "Superior Hunter's Defense")
    Eq(HP(), max - 5, "resisted at once")
    local kept = Passive("Superior Hunter's Defense (fire)")
    Check(kept and kept.enabled, "a passive keeps the resistance for the turn")
    RPSheet:TakeDamage(10, "fire")
    Eq(HP(), max - 10, "more fire damage that turn is resisted")
    RPSheet:TakeDamage(10, "cold")
    Eq(HP(), max - 20, "other types are not")
    kept.enabled = false
    ns.ApplyWards(RPSheet:Sheet())
    Check(not Passive("Superior Hunter's Defense (fire)"), "clicked off, it goes")
end)

Section("Heavy Armor Master", function()
    Build("WARRIOR", "", 5)
    local sheet, max = RPSheet:Sheet(), RPSheet:MaxHP()
    Give("Heavy Armor Master")
    RPSheet:OpenDamageMenu({})
    Check(not Row(MENU, "Heavy Armor Master"), "not offered without heavy armor")
    sheet.armor = "CHAINMAIL"
    local pb = RPSheet:ProficiencyBonus()
    Through(10, "Slashing")
    Eq(HP(), max - 10 + pb, "an attack's slashing damage is reduced by the proficiency bonus")
    Said(("Heavy Armor Master %d"):format(pb), "the note names the feat")
    RPSheet:State().hp = max
    Through(10, "Slashing", "Hit by an attack")
    Eq(HP(), max - 10, "unticked: not from an attack")
    RPSheet:State().hp = max
    Through(10, "Fire")
    Eq(HP(), max - 10, "fire is not reduced")
end)

Section("Stagger and Sway", function()
    Build("MONK", "", 5, { base = { STR = 10, DEX = 16, CON = 14, INT = 10, WIS = 14, CHA = 10 } })
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    Give("Stagger and Sway")
    local dex = math.max(1, RPSheet:Mod("DEX"))
    RPSheet:TakeDamage(10, "slashing")
    Eq(HP(), max - 10 + dex, "reduced by the Dexterity modifier")
    Eq(state.delayedDice, 1, "a d6 in the pool")
    RPSheet:TakeDamage(5)
    RPSheet:TakeDamage(5)
    Eq(state.delayedDice, 3, "a d6 for each damage")
    local purify
    for _, extra in ipairs(RPSheet:DamageExtras()) do if extra.label:find("Purify") then purify = extra end end
    if Check(purify ~= nil, "a Purify row") then purify.run() end
    Eq(state.delayedDice or 0, math.max(0, 3 - RPSheet:Mod("WIS")), "Purify takes out the Wisdom modifier in dice")
    state.delayedDice = 2
    state.hp = max
    Rolls(4, 5)
    local take
    for _, extra in ipairs(RPSheet:DamageExtras()) do if extra.label:find("Delayed Reaction") then take = extra end end
    if Check(take ~= nil, "a row to take the pool") then take.run() end
    Eq(HP(), max - 9, "the pool's 2d6 = 9 force, not reduced")
    Check((state.delayedDice or 0) == 0, "the pool is empty and its damage added no die")
    Said("Delayed Reaction 2d6", "the roll is said")
end)

Section("Nose for Trouble", function()
    Build("MAGE", "", 5, { species = "VULPERA" })
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:TakeDamage(8)
    Eq(HP(), max - 8, "before initiative: nothing off")
    state.hp = max
    RPSheet:RollCheck("initiative", 0, nil, false, {})
    Check(state.noseReady, "initiative readies it")
    RPSheet:TakeDamage(8)
    Eq(HP(), max - 3, "the first damage loses the level (5)")
    RPSheet:TakeDamage(8)
    Eq(HP(), max - 11, "the second doesn't")
    -- the menu box, ticked by hand for initiative rolled elsewhere
    state.hp = max
    Through(8, "No type", "Nose for Trouble")
    Eq(HP(), max - 3, "ticked by hand")
end)

Section("falling", function()
    Build("MONK", "", 5, { species = "PANDAREN" })
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    Rolls(6, 6, 6, 6, 6, 6)
    RPSheet:Fall(60, false)
    Eq(HP(), max - 18, "6d6 = 36 bludgeoning from a fall, halved by Bouncy")
    Said("a fall of 60 feet 6d6", "the roll is said")
    Said("resistance: Bouncy", "Bouncy")
    Check(state.conditions.Prone, "lands Prone")
    state.hp, state.conditions.Prone = max, nil
    Rolls(6, 6, 6, 6, 6, 6)
    RPSheet:Fall(65, true)
    Eq(HP(), max - 5, "Slow Fall takes 25 off first: (36 - 25) halved is 5")
    Check(state.reactionUsed, "Slow Fall spends the reaction")
    local before = #PRINTED
    RPSheet:Fall(9)
    Check(AnyPrinted("less than 10 feet", before), "under 10 feet does nothing")
    -- 20d6 at most
    Build("MAGE", "", 5)
    local rolled = #ROLLED
    DEFAULT_ROLL = 1
    RPSheet:Fall(500)
    Eq(#ROLLED - rolled, 20, "20 dice at most")
    -- the menu row asks for the distance
    local keep, asked = RPSheet.AskAmount, nil
    RPSheet.AskAmount = function(_, request) asked = request end
    RPSheet:OpenDamageMenu({})
    Click(MENU, "A fall")
    RPSheet.AskAmount = keep
    Check(asked and asked.run, "A fall asks for the distance")
end)

Section("Death Ward", function()
    Build("PRIEST", "", 7)
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:StartWard("Death Ward", 1)
    Check(Passive("Death Ward (spell)") ~= nil, "the ward is on")
    RPSheet:TakeDamage(max + 5)
    Eq(HP(), 1, "1 hit point instead of 0")
    Check(not Passive("Death Ward (spell)"), "the spell ends")
    Said("Death Ward", "said")
    RPSheet:TakeDamage(5)
    Eq(HP(), 0, "the next time it's gone")
    -- massive damage: kept at 1 too
    state.hp = max
    RPSheet:ClearDeathSaves()
    RPSheet:StartWard("Death Ward", 1)
    RPSheet:TakeDamage(max * 3)
    Eq(HP(), 1, "even damage that would kill outright")
    Eq(state.deathFail, 0, "not dead")
end)

Section("Relentless Rage", function()
    Build("SHAMAN", "", 11)
    local state, max = RPSheet:State(), RPSheet:MaxHP()
    RPSheet:TakeDamage(max)
    Eq(HP(), 0, "not raging: down")
    state.hp = max
    RPSheet:ClearDeathSaves()
    Passive("Raging").enabled = true
    Rolls(20)
    RPSheet:TakeDamage(max)
    Eq(HP(), 22, "a passed save stands with twice the level")
    Said("against DC 10", "DC 10 first")
    Eq(RPSheet:RelentlessDC(), 15, "then 15")
    Rolls(1)
    RPSheet:TakeDamage(max)
    Eq(HP(), 0, "a failed save leaves 0")
    Said("fails", "said")
    RPSheet:ShortRest()
    Eq(RPSheet:RelentlessDC(), 10, "a rest sets it back to 10")
    -- damage that kills outright
    state.hp = 5
    RPSheet:ClearDeathSaves()
    Passive("Raging").enabled = true
    local rolled = #ROLLED
    RPSheet:TakeDamage(5 + max)
    Eq(#ROLLED, rolled, "no save against damage that kills outright")
    Eq(state.deathFail, 3, "dead")
end)

Section("Indomitable Might", function()
    Build("SHAMAN", "", 18, { base = { STR = 18, DEX = 14, CON = 14, INT = 10, WIS = 10, CHA = 10 } })
    local score = RPSheet:Score("STR")
    Rolls(2)
    RPSheet:RollCheck("STR save", RPSheet:SaveMod("STR"), nil, false, {})
    Said(("[counts as %d"):format(score), "a low Strength save counts as the score")
    Rolls(2)
    RPSheet:RollCheck("Athletics", 0, nil, false, {})
    Said("counts as", "Athletics is a Strength check")
    Rolls(2)
    RPSheet:RollCheck("DEX save", 0, nil, false, {})
    Check(not (SENT[#SENT] or ""):find("counts as", 1, true), "not for Dexterity")
    Rolls(20)
    RPSheet:RollCheck("STR check", 5, nil, false, {})
    Check(not (SENT[#SENT] or ""):find("counts as", 1, true), "not when the total is higher")
    Build("SHAMAN", "", 17)
    Rolls(1)
    RPSheet:RollCheck("STR save", 0, nil, false, {})
    Check(not (SENT[#SENT] or ""):find("counts as", 1, true), "not before level 18")
end)

Section("healing received", function()
    Build("PRIEST", "", 5)
    local state = RPSheet:State()
    state.hp = 1
    local cure = Learn("Cure Wounds")
    Rolls(3, 4)
    RPSheet:CastSpell(cure)
    Eq(HP(), 1, "casting doesn't heal the caster by itself")
    local last = RPSheet:LastHealing()
    Check(last and last.amount == 7 + RPSheet:Mod("WIS") and last.from == "Cure Wounds", "the roll is kept")
    RPSheet:OpenHealMenu({})
    Click(MENU, "Your own Cure Wounds")
    Eq(HP(), 1 + last.amount, "Heal takes the roll")
    Check(RPSheet:LastHealing() == nil, "once")
    -- someone else's spell: spell, slot, modifier
    state.hp = 1
    local keep, asked = RPSheet.AskAmount, nil
    RPSheet.AskAmount = function(_, request) asked = request end
    RPSheet:OpenHealMenu({})
    Click(MENU, "A healing spell someone else cast")
    Click(MENU, "Healing Word")
    Click(MENU, "2nd level slot: 4d4")
    RPSheet.AskAmount = keep
    Rolls(1, 2, 3, 4)
    if Check(asked and asked.run, "the caster's modifier is asked") then asked.run("3") end
    Eq(HP(), 1 + 10 + 3, "4d4 = 10, + 3")
    Said("Healing Word", "named")
    -- a spell without the modifier rolls at once
    state.hp = 1
    RPSheet:OpenHealMenu({})
    Click(MENU, "A healing spell someone else cast")
    Click(MENU, "Prayer of Healing")
    Rolls(2, 2, 2)
    Click(MENU, "3rd level slot: 3d8")
    Eq(HP(), 7, "3d8 = 6")
    -- the plain amount
    keep, asked = RPSheet.AskAmount, nil
    RPSheet.AskAmount = function(_, request) asked = request end
    RPSheet:OpenHealMenu({})
    Click(MENU, "Type the amount")
    RPSheet.AskAmount = keep
    Check(asked and asked.heal, "Type the amount asks as before")
end)

Summary("t-test-play-reactions")
