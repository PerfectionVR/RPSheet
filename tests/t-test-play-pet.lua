-- The Beast Master's companion: its strike in every form (plain, charge, cleave,
-- twice), what a hit does on top, its checks and saves, its hit points, the strike's
-- mastery, and a companion whose master has another spellcasting class.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local SCORES = { STR = 10, DEX = 16, CON = 14, INT = 10, WIS = 16, CHA = 8 }
local function Hunter(level, family, opts)
    opts = opts or {}
    opts.base = opts.base or SCORES
    opts.setup = function(sheet) sheet.featureOptions[R.PET_FEATURE] = family end
    return Build("HUNTER", "Beast Master", level, opts)
end
local function Family(block, mastery)
    for name, pet in pairs(R.PET_FAMILIES) do
        if pet.block == block and (not mastery or pet.mastery == mastery) then return name end
    end
end

Section("a beast of the land", function()
    local sheet = Hunter(5, "Bear")
    Check(RPSheet:HasPet(), "a level 5 Beast Master has a companion")
    Eq(RPSheet:PetWord(), "bear", "its family in words")
    local wis, prof = RPSheet:Mod("WIS"), RPSheet:ProficiencyBonus()
    local hp = Tracker("Pet HP")
    Eq(hp and hp.max, 5 + 5 * 5, "hit points: 5 and 5 a level")
    Eq(RPSheet:PetAC(), 13 + wis, "Armor Class 13 + Wisdom")
    local toHit, flat = RPSheet:PetStrikeMods()
    Eq(toHit, prof + wis, "the strike uses the master's spell attack modifier")
    Eq(flat, 2 + wis, "damage: 2 + Wisdom")
    -- plain
    local at = #ROLLED
    Rolls(10, 5)
    RPSheet:PetStrike()
    Eq(Dice(at), "20,8", "a d20 and a d8")
    Said(("uses [Beast's Strike] (bear) - to hit: 10 + %d = %d, damage 1d8 + %d: 5 + %d = %d"):format(toHit, 10 + toHit, flat, flat, 5 + flat), "the strike's line")
    Check(not SENT[#SENT]:find("Prone"), "no rider without a charge")
    -- a natural 20
    at = #ROLLED
    Rolls(20)
    RPSheet:PetStrike()
    Eq(Dice(at), "20,8,8", "a natural 20 doubles the die")
    Said("critical damage 2d8", "critical line")
    -- charge
    at = #ROLLED
    Rolls(10, 5, 3)
    RPSheet:PetStrike(nil, "charge")
    Eq(Dice(at), "20,8,6", "a charge adds a d6")
    Said("(bear, after a charge)", "says it was a charge")
    Said("charge 1d6: 3 = 3. On a hit: [Prone] if Large or smaller", "the charge's die and what it does")
    at = #ROLLED
    Rolls(20)
    RPSheet:PetStrike(nil, "charge")
    Eq(Dice(at), "20,8,8,6,6", "a critical charge doubles both")
    -- advantage
    at = #ROLLED
    RPSheet:PetStrike("ADV")
    Eq(Dice(at), "20,20,8", "advantage rolls two d20s")
    -- the abilities on the sheet go the same way
    at = #ROLLED
    Rolls(10, 5)
    RPSheet:UseAbility(Ability("Beast's Strike"))
    Eq(Dice(at), "20,8", "the ability rolls the same")
    Said("uses [Beast's Strike] (bear) - to hit: 10 +", "and says the same")
    at = #ROLLED
    RPSheet:UseAbility(Ability("Beast's Strike: charge"))
    Eq(Dice(at), "20,8,6", "the charge ability rolls the charge")
    -- the master's conditions don't touch the companion
    RPSheet:State().conditions.Poisoned = true
    at = #ROLLED
    RPSheet:PetStrike()
    Eq(Dice(at), "20,8", "a poisoned master's companion strikes normally")
    RPSheet:State().conditions.Poisoned = nil
    -- checks and saves: its own modifier and the master's proficiency bonus
    Rolls(7)
    RPSheet:PetCheck("STR", "save")
    Said(("rolls [companion STR save] (bear): 7 + %d = %d"):format(2 + prof, 9 + prof), "a save of the companion")
    Rolls(7)
    RPSheet:PetCheck("INT", "check")
    Said(("rolls [companion INT check] (bear): 7 + %d = %d"):format(prof - 1, 6 + prof), "a check of the companion")
    Check(RPSheet:ExplainPetTerm("companion STR save") ~= nil, "the term can be explained")
    -- a Tenacity pet has more hit points from level 6
    Hunter(6, "Bear")
    Eq(Tracker("Pet HP").max, 5 + 5 * 6 + 6, "a Tenacity pet at level 6")
    Eq(RPSheet:MaxHP(), ns.DiceHitPoints(RPSheet:Sheet()) + 6 * RPSheet:OwnMod("CON") + 6, "and its master has more too")
    -- below level 3: none
    Hunter(2, "Bear")
    Check(not RPSheet:HasPet() and not Tracker("Pet HP"), "no companion below level 3")
end)

Section("sea and sky", function()
    local sea = Family("Sea")
    Hunter(5, sea)
    local at = #ROLLED
    RPSheet:PetStrike(nil, "charge")
    Eq(Dice(at), "", "a beast of the sea has no charge: a right-click strikes nothing")
    Printed("Your companion has no charge", "and a line says what a right-click is for")
    Rolls(10, 3)
    RPSheet:PetStrike()
    Eq(Dice(at), "20,6", "a beast of the sea has a d6")
    Said(("On a hit: [Grappled], escape DC %d"):format(RPSheet:SpellDC()), "its hit grapples, against the master's spell save DC")
    Check(not Ability("Beast's Strike: charge"), "no charge ability for a beast of the sea")
    Eq(Tracker("Pet HP").max, 5 + 5 * 5 + 0, "hit points of a beast of the sea")
    local sky = Family("Sky")
    Hunter(5, sky)
    at = #ROLLED
    RPSheet:PetStrike()
    Eq(Dice(at), "20,4", "a beast of the sky has a d4")
    local _, flat = RPSheet:PetStrikeMods()
    Eq(flat, 3 + RPSheet:Mod("WIS"), "and 3 + Wisdom")
    Eq(Tracker("Pet HP").max, 4 + 4 * 5, "hit points of a beast of the sky")
end)

Section("mastery, cleave and striking twice", function()
    local cleaver = Family("Land", "Cleave")
    local sheet = Hunter(11, cleaver)
    local state = RPSheet:State()
    Check(RPSheet:HasWeaponMastery(), "a Hunter has Weapon Mastery")
    Eq(RPSheet:PetMastery(), nil, "no mastery until the family is picked")
    local before = #PRINTED
    local sent = #SENT
    RPSheet:PetStrike(nil, "cleave")
    Eq(#SENT, sent, "no cleave without the mastery")
    Check(AnyPrinted("doesn't have the Cleave mastery", before), "a line says so")
    Check(RPSheet:TogglePetMastery(), "the family becomes a mastery pick")
    Eq(RPSheet:PetMastery(), "Cleave", "the strike has Cleave")
    before = #PRINTED
    Check(not RPSheet:TogglePetMastery(), "it can't be changed again before a long rest")
    Check(AnyPrinted("already changed this Weapon Mastery pick", before), "a line says so")
    RPSheet:LongRest()
    Check(RPSheet:TogglePetMastery() and not sheet.petMastery, "after a long rest it can be taken off")
    RPSheet:LongRest()
    RPSheet:TogglePetMastery()
    -- the strike names the mastery
    Rolls(10, 4)
    RPSheet:PetStrike()
    Said("[Cleave]", "the strike names its mastery")
    -- the cleave: no Wisdom in the damage
    local at = #ROLLED
    Rolls(10, 4)
    RPSheet:PetStrike(nil, "cleave")
    Eq(Dice(at), "20,8", "the cleave is one more strike")
    Said("cleaving) - ", "says it is the cleave")
    Said("damage 1d8 + 2: 4 + 2 = 6", "without the Wisdom modifier")
    Check(not SENT[#SENT]:find("%[Cleave%]"), "and doesn't cleave again")
    -- twice (Bestial Fury)
    Check(Passive("Bestial Fury") ~= nil, "a level 11 Beast Master has Bestial Fury")
    at, sent = #ROLLED, #SENT
    RPSheet:PetStrike(nil, "charge", true)
    Eq(Dice(at), "20,8,6,20,8", "two strikes; the charge counts for the first")
    Eq(#SENT, sent + 2, "two lines")
    Check(SENT[#SENT - 1]:find("after a charge") and not SENT[#SENT]:find("charge"), "only the first is a charge")
    -- no free pick
    local limit = RPSheet:MasteryLimit()
    sheet.petMastery = false
    state.petMasteryChanged = nil
    for index = 1, limit do
        local weapon = CopyTable(R.TEMPLATES.weapon)
        weapon.name, weapon.base, weapon.mastery = "Test " .. index, "Longsword", "Sap"
        table.insert(sheet.weapons, weapon)
    end
    if RPSheet:MasteriesUsed() >= limit then
        before = #PRINTED
        Check(not RPSheet:TogglePetMastery(), "no pick left for the companion")
        Check(AnyPrinted("Weapon Mastery picks are on weapons", before), "a line says so")
    else
        Check(false, ("the test could not use up the mastery picks (%d of %d)"):format(RPSheet:MasteriesUsed(), limit))
    end
end)

Section("a master with another spellcasting class", function()
    -- A Mage first, then a Hunter: the companion goes by Wisdom, the Hunter's ability.
    local sheet = Build("MAGE", "Evoker", 8, { base = { STR = 8, DEX = 14, CON = 14, INT = 18, WIS = 12, CHA = 8 },
        extras = { { class = "HUNTER", level = 3, subclass = "Beast Master" } },
        setup = function(sheet) sheet.featureOptions[R.PET_FEATURE] = Family("Sea") end })
    Check(RPSheet:HasPet(), "a Mage 5 / Beast Master 3 has a companion")
    local wis, int, prof = RPSheet:Mod("WIS"), RPSheet:Mod("INT"), RPSheet:ProficiencyBonus()
    Check(int > wis, "Intelligence is the higher one")
    Eq(RPSheet:SpellAttack(), prof + int, "the character's own spell attack goes by Intelligence")
    local toHit = RPSheet:PetStrikeMods()
    Eq(toHit, prof + wis, "the companion's strike goes by Wisdom")
    Eq(RPSheet:PetGrappleDC(), 8 + prof + wis, "and so does the DC to escape its grapple")
    Eq(Tracker("Pet HP").max, 5 + 5 * 3, "its hit points go by the Hunter level")
    -- the other way round: unchanged
    Build("HUNTER", "Beast Master", 8, { base = { STR = 8, DEX = 14, CON = 14, INT = 18, WIS = 12, CHA = 8 },
        extras = { { class = "MAGE", level = 3, subclass = "Evoker" } },
        setup = function(sheet) sheet.featureOptions[R.PET_FEATURE] = Family("Sea") end })
    toHit = RPSheet:PetStrikeMods()
    Eq(toHit, RPSheet:ProficiencyBonus() + RPSheet:Mod("WIS"), "a Hunter first: Wisdom as before")
end)

Summary("t-test-play-pet")
