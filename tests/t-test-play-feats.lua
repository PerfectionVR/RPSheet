-- Feats the sheet applies by itself: Medium Armor Master's Armor Class, the bars and
-- rows of Data/FeatUses.lua (Lucky, Mage Slayer, Arathi Heritage's wait of 1d4 long
-- rests, Boon of Recovery, Boon of Fate on initiative, Chef, Defensive Duelist's
-- Parrying, Polearm Master), what feats do to weapon damage (Great Weapon Master,
-- Savage Attacker, Piercer, Fists of Fury, Boon of Irresistible Offense), the Unarmed
-- Strike row, and what they do to spell dice (Elemental Adept, Clearcasting, Healer,
-- Boon of Spell Recall).
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Feat(name)
    return { name = name, desc = "", auto = "", enabled = true, effects = {} }
end
-- A character with these feats on the sheet, as the player would add them.
local function WithFeats(class, level, feats, opts)
    opts = opts or {}
    local setup = opts.setup
    opts.setup = function(sheet)
        for _, name in ipairs(feats) do sheet.passives[#sheet.passives + 1] = Feat(name) end
        if setup then setup(sheet) end
    end
    return Build(class, opts.subclass or "", level, opts)
end
local function Weapon(name)
    local sheet = RPSheet:Sheet()
    wipe(sheet.weapons)
    sheet.weapons[1] = ns.NewBasicWeapon(name, function(stat) return RPSheet:Mod(stat) end, true, false)
    RPSheet:State().weapon = 1
    return sheet.weapons[1]
end

Section("Medium Armor Master", function()
    local sheet = WithFeats("WARRIOR", 4, {}, { base = { STR = 14, DEX = 16, CON = 14, INT = 10, WIS = 10, CHA = 10 } })
    sheet.armor = "BREASTPLATE"
    local without = RPSheet:AC()
    sheet.passives[#sheet.passives + 1] = Feat("Medium Armor Master")
    Eq(RPSheet:AC(), without + 1, "Dexterity 16 in a breastplate adds 3, not 2")
    sheet.base.DEX = 15
    Eq(RPSheet:AC(), without - 0, "with Dexterity 15 the limit stays at 2 (and the modifier is +2)")
    sheet.base.DEX = 18
    sheet.armor = "PLATE"
    local plate = RPSheet:AC()
    Eq(plate, R.ARMOR.PLATE.ac + RPSheet:Bonus("AC") + RPSheet:StyleAC() + RPSheet:WornBonus(), "heavy armor still adds no Dexterity")
    sheet.armor = "HALFPLATE"
    Eq(RPSheet:ArmorDexCap(R.ARMOR.HALFPLATE), 3, "half plate allows 3 with the feat")
    local before = #PRINTED
    RPSheet:ExplainAC()
    Check(AnyPrinted("at most +3 in this armor, Medium Armor Master", before), "the explanation names the feat")
end)

Section("Lucky, Mage Slayer and Boon of Fate", function()
    WithFeats("WARRIOR", 5, { "Lucky", "Mage Slayer", "Boon of Fate" })
    local luck = Tracker("Luck Points")
    Check(luck and luck.max == RPSheet:ProficiencyBonus(), "Lucky has a bar of luck points equal to the proficiency bonus")
    RPSheet:UseAbility(Ability("Luck Points"))
    Eq(Tracker("Luck Points").get(), luck.max - 1, "a click spends a luck point")
    Eq(RPSheet.rollMode, "ADV", "and sets the next roll to advantage")
    local guarded = Tracker("Guarded Mind")
    Check(guarded and guarded.max == 1 and guarded.short == "ALL", "Guarded Mind: once per short or long rest")
    RPSheet:UseAbility(Ability("Guarded Mind"))
    Eq(Tracker("Guarded Mind").get(), 0, "spent")
    RPSheet:ShortRest()
    Eq(Tracker("Guarded Mind").get(), 1, "a short rest brings it back")
    Check(Tracker("Luck Points").get() < Tracker("Luck Points").max, "but not the luck points")
    -- Boon of Fate: 2d4, back when initiative is rolled
    Rolls(3, 4)
    RPSheet:UseAbility(Ability("Improve Fate"))
    Said("2d4", "Improve Fate rolls 2d4")
    Eq(Tracker("Improve Fate").get(), 0, "Improve Fate is spent")
    RPSheet.rollMode = nil
    RPSheet:RollCheck("initiative", RPSheet:Initiative(), nil)
    Eq(Tracker("Improve Fate").get(), 1, "rolling initiative gives it back")
end)

Section("Arathi Heritage comes back after 1d4 long rests", function()
    WithFeats("WARRIOR", 3, { "Arathi Heritage" }, { species = "HUMAN" })
    local use = Tracker("Lethargy Resilience")
    Check(use and use.max == 1, "Lethargy Resilience has one use")
    RPSheet:UseAbility(Ability("Lethargy Resilience"))
    Eq(Tracker("Lethargy Resilience").get(), 0, "spent")
    Rolls(3) -- the d4: three long rests
    RPSheet:LongRest()
    Eq(Tracker("Lethargy Resilience").get(), 0, "after the first of three long rests it is still spent")
    RPSheet:LongRest()
    Eq(Tracker("Lethargy Resilience").get(), 0, "after the second too")
    RPSheet:LongRest()
    Eq(Tracker("Lethargy Resilience").get(), 1, "after the third it is back")
    RPSheet:UseAbility(Ability("Lethargy Resilience"))
    Rolls(1)
    RPSheet:LongRest()
    Eq(Tracker("Lethargy Resilience").get(), 1, "a 1 on the d4: back after one long rest")
end)

Section("Boon of Recovery, Chef, Defensive Duelist, Polearm Master, Charger", function()
    WithFeats("WARRIOR", 19, { "Boon of Recovery", "Chef", "Defensive Duelist", "Polearm Master", "Charger" })
    local state = RPSheet:State()
    state.hp = 0
    RPSheet:UseAbility(Ability("Last Stand"))
    Eq(HP(), 1 + math.floor(RPSheet:MaxHP() / 2), "Last Stand: 1 hit point plus half the maximum")
    Eq(Tracker("Last Stand").get(), 0, "once per long rest")
    Eq(Tracker("Recover Vitality").max, 10, "a pool of ten d10s")
    local hp = HP()
    Rolls(7)
    RPSheet:UseAbility(Ability("Recover Vitality"))
    Eq(HP(), hp + 7, "a die of the pool heals")
    Eq(Tracker("Recover Vitality").get(), 9, "and is spent")
    -- Chef: treats and the short-rest meal
    Eq(Tracker("Bolstering Treats").max, RPSheet:ProficiencyBonus(), "treats equal to the proficiency bonus")
    state.tempHP = 0
    RPSheet:UseAbility(Ability("Bolstering Treats"))
    Eq(state.tempHP, RPSheet:ProficiencyBonus(), "a treat gives temporary hit points equal to the proficiency bonus")
    state.hp = 10
    RPSheet:ShortRest()
    Rolls(4, 6)
    RPSheet:SpendHitDie()
    Eq(HP(), 10 + 4 + RPSheet:Mod("CON") + 6, "the first Hit Die after the short rest heals 1d8 more")
    Said("Chef", "the meal is named")
    state.hp = 10
    Rolls(4, 6)
    RPSheet:SpendHitDie()
    Eq(HP(), 10 + 4 + RPSheet:Mod("CON"), "only once")
    -- Parry
    local ac = RPSheet:AC()
    RPSheet:UseAbility(Ability("Parry"))
    Check(Passive("Parrying") and Passive("Parrying").enabled, "Parry switches Parrying on")
    Eq(RPSheet:AC(), ac + RPSheet:ProficiencyBonus(), "Parrying adds the proficiency bonus to Armor Class")
    RPSheet:ShortRest()
    Check(not Passive("Parrying").enabled, "a rest ends it")
    -- Pole Strike and Charge Attack
    local pole = Ability("Pole Strike")
    Check(pole and pole.actions[1].type == "ROLL" and pole.actions[2].sides == 4, "Pole Strike rolls an attack and a d4")
    Rolls(10, 3)
    RPSheet:UseAbility(pole)
    Said("1d4", "the butt strike rolls a d4")
    Check(Ability("Charge Attack") and Ability("Charge Attack").actions[1].sides == 8, "Charge Attack rolls a d8")
    -- the feat gone, the rows go
    local sheet = RPSheet:Sheet()
    for index = #sheet.passives, 1, -1 do
        if sheet.passives[index].name == "Polearm Master" then table.remove(sheet.passives, index) end
    end
    ns.ApplyFeatSpells(sheet)
    Check(not Ability("Pole Strike"), "without the feat Pole Strike goes")
end)

Section("weapon damage feats", function()
    WithFeats("WARRIOR", 5, { "Great Weapon Master", "Savage Attacker" })
    Weapon("Greatsword")
    local mod = RPSheet:Mod("STR") + RPSheet:DamageBonus("STR")
    -- d20 15, damage 2 + 3, again 6 + 6: the second pair is kept, + proficiency bonus
    Rolls(15, 2, 3, 6, 6)
    RPSheet:Attack(nil, {})
    Said("12 kept over 5", "Savage Attacker keeps the better roll")
    Said("Great Weapon Master", "Great Weapon Master is named")
    Said(("= %d"):format(12 + mod + RPSheet:ProficiencyBonus() + select(2, RPSheet:WeaponStyle(RPSheet:GetWeapon()))), "the heavy weapon adds the proficiency bonus")
    -- not heavy: no bonus
    Weapon("Longsword")
    Rolls(15, 4, 1)
    RPSheet:Attack(nil, {})
    Check(not (SENT[#SENT]):find("Great Weapon Master", 1, true), "a longsword isn't heavy")
    -- Piercer: the low die is rerolled; a critical hit rolls one die more
    WithFeats("WARRIOR", 5, { "Piercer" })
    Weapon("Rapier")
    Rolls(15, 1, 7)
    RPSheet:Attack(nil, {})
    Said("a 1 rerolled as 7, Piercer", "Piercer rerolls a low die")
    local rolled = #ROLLED
    Rolls(20, 8, 8, 8)
    RPSheet:Attack(nil, {})
    Eq(#ROLLED - rolled, 4, "a critical hit with a rapier rolls the d20 and three d8s")
    -- Fists of Fury with a light weapon
    WithFeats("MONK", 5, { "Fists of Fury" })
    Weapon("Dagger")
    Rolls(15, 1)
    RPSheet:Attack(nil, {})
    Said("counted as 2, Fists of Fury", "a 1 counts as 2 with a light weapon")
    -- Boon of Irresistible Offense on a natural 20
    WithFeats("WARRIOR", 19, { "Boon of Irresistible Offense" }, { base = { STR = 18, DEX = 12, CON = 14, INT = 10, WIS = 10, CHA = 10 } })
    Weapon("Longsword")
    Rolls(20, 4, 4)
    RPSheet:Attack(nil, {})
    Said(("+%d [Boon of Irresistible Offense] (your Strength)"):format(RPSheet:Score("STR")), "a natural 20 adds the Strength score")
end)

Section("the Unarmed Strike row", function()
    WithFeats("WARRIOR", 1, { "Tavern Brawler" })
    local strike = Ability("Unarmed Strike")
    Check(strike and strike.actions[2].sides == 4 and strike.actions[2].reroll == 1, "Tavern Brawler: 1d4 + Strength, 1s rerolled")
    Rolls(12, 1, 3)
    RPSheet:UseAbility(strike)
    Said("a 1 rerolled as 3, Tavern Brawler", "the 1 is rerolled")
    -- Unarmed Fighting: two rows; the blessing adds 1
    WithFeats("WARRIOR", 1, { "Unarmed Fighting", "Strike of the Earth-Warder" })
    strike = Ability("Unarmed Strike")
    local free = Ability("Unarmed Strike, hands free")
    Check(strike and strike.actions[2].sides == 6 and free and free.actions[2].sides == 8, "Unarmed Fighting: a d6, and a d8 with hands free")
    Eq(strike.actions[1].rollFlat, 1, "the blessing adds 1 to hit")
    Eq(strike.actions[2].flat, 1, "and 1 to damage")
    -- without any of them no row; a Monk's own strike takes the blessing
    Build("WARRIOR", "", 1)
    Check(not Ability("Unarmed Strike"), "no row without a feat, style or blessing")
    WithFeats("MONK", 1, { "Strike of the Earth-Warder" })
    local monk = Ability("Unarmed Strike")
    Check(monk and (monk.auto or ""):find("^class:") and monk.actions[1].rollFlat == 1 and monk.actions[2].flat == 1, "the Monk's strike gets +1")
    ns.ApplyFeatSpells(RPSheet:Sheet())
    Eq(Ability("Unarmed Strike").actions[2].flat, 1, "only once, however often the upkeep runs")
    -- With no weapon in hand the attack is the plain Unarmed Strike: Strength 16 (+3)
    -- and proficiency +2 to hit, 1 + 3 damage; a natural 20 deals the same.
    Build("WARRIOR", "", 1, { base = { STR = 16, DEX = 12, CON = 14, INT = 10, WIS = 10, CHA = 10 } })
    wipe(RPSheet:Sheet().weapons)
    local mod = RPSheet:Mod("STR")
    Eq(RPSheet:UnarmedText(), ("+%d to hit, %d bludgeoning damage"):format(mod + 2, 1 + mod), "the row's numbers")
    Rolls(14)
    RPSheet:Attack(nil, {})
    Said(("attacks with [Unarmed Strike] - to hit: 14 + %d = %d, %d bludgeoning damage"):format(mod + 2, 14 + mod + 2, 1 + mod), "the attack without a weapon")
    Rolls(20)
    RPSheet:UnarmedAttack(nil, {})
    Said("(a critical hit: no die to double)", "a natural 20")
    -- a feat's own row takes over
    WithFeats("WARRIOR", 1, { "Tavern Brawler" })
    wipe(RPSheet:Sheet().weapons)
    Check(RPSheet:HasUnarmedRow(), "with Tavern Brawler the sheet's own row is used")
end)

Section("spell dice", function()
    local sheet = WithFeats("MAGE", 5, { "Clearcasting", "Healer" })
    Learn("Magic Missile")
    Rolls(1, 1, 1)
    RPSheet:CastSpell(Spell("Magic Missile"))
    Said("3 low dice counted as 2, Clearcasting", "Clearcasting: force dice of 1 count as 2")
    Learn("Cure Wounds")
    Rolls(1, 5, 4)
    RPSheet:CastSpell(Spell("Cure Wounds"))
    Said("a 1 rerolled as 4, Healer", "Healer rerolls a 1 on healing dice")
    -- Elemental Adept for fire
    sheet = WithFeats("MAGE", 5, {})
    sheet.passives[#sheet.passives + 1] = { name = "Elemental Adept", desc = "", auto = "", enabled = true, effects = {} }
    sheet.featChoices["own:Elemental Adept"] = { feat = "Elemental Adept", picks = { damage = { "Fire" } } }
    Learn("Fire Bolt")
    Rolls(15, 1, 1)
    RPSheet:CastSpell(Spell("Fire Bolt"), nil, nil, nil, {})
    Said("counted as 2, Elemental Adept", "Elemental Adept: fire dice of 1 count as 2")
    -- Boon of Spell Recall
    WithFeats("MAGE", 19, { "Boon of Spell Recall" })
    Learn("Magic Missile")
    local slot = Slot(1)
    local before = slot.get()
    Rolls(2, 2, 2, 1) -- three darts, then the d4 shows the slot's level
    RPSheet:CastSpell(Spell("Magic Missile"))
    Eq(Slot(1).get(), before, "a d4 that shows the slot's level gives it back")
    Rolls(2, 2, 2, 3)
    RPSheet:CastSpell(Spell("Magic Missile"))
    Eq(Slot(1).get(), before - 1, "another number spends it")
end)

Summary("t-test-play-feats")
