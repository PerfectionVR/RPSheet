-- The numbers of a Beast Master's companion: its own modifiers, its strike, and
-- whether the strike uses the family's mastery (data in Data/Pets.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

function RPSheet:HasPet()
    local sheet = self:Sheet()
    return sheet.subclass == "Beast Master" and sheet.level >= 3
end

-- The family in lower case for announcements ("wolf"), or nil when none is picked.
function RPSheet:PetWord()
    local pet = R.Pet(self:Sheet())
    return pet and pet.name:lower()
end

-- Modifier of one of the companion's own ability scores.
function RPSheet:PetMod(stat)
    return Util.ScoreMod(R.PetBlock(self:Sheet()).scores[stat])
end

-- What the companion adds to an ability check or saving throw: its bond adds its
-- master's proficiency bonus to every one of them.
function RPSheet:PetRollMod(stat)
    return self:PetMod(stat) + self:ProficiencyBonus()
end

-- The strike's attack bonus (the master's spell attack modifier) and what is added
-- to its damage die.
function RPSheet:PetStrikeMods()
    local wisdom = self:Mod("WIS")
    return self:SpellAttack() or (self:ProficiencyBonus() + wisdom), R.PetBlock(self:Sheet()).flat + wisdom
end

-- The save DC a creature grappled by the strike escapes against.
function RPSheet:PetGrappleDC()
    return self:SpellDC() or (8 + self:ProficiencyBonus() + self:Mod("WIS"))
end

---------------------------------------------------------------------------
-- The strike's mastery
---------------------------------------------------------------------------
-- The mastery the strike uses right now, or nil. The family has to be one of the
-- character's Weapon Mastery picks, so it counts toward that limit
-- (see RPSheet:MasteriesUsed).
function RPSheet:PetMastery()
    local sheet = self:Sheet()
    local pet = R.Pet(sheet)
    if pet and sheet.petMastery and self:HasPet() and self:HasWeaponMastery() then
        return pet.mastery, R.MASTERIES[pet.mastery]
    end
end

-- What is said about the mastery when the companion strikes.
function RPSheet:PetMasteryNote()
    local name, mastery = self:PetMastery()
    if not name then return end
    -- Graze goes by the modifier in the attack roll: the master's Wisdom.
    local note = R.PET_MASTERY_NOTES[name] or mastery.note:format(math.max(0, self:Mod("WIS")))
    return ("%s %s"):format(note, ns.Mark(name))
end

-- Makes the family one of the Weapon Mastery picks, or takes it off again. A pick is
-- only given when one is free. Returns true when something changed.
function RPSheet:TogglePetMastery()
    local sheet = self:Sheet()
    if sheet.petMastery then
        sheet.petMastery = false
        return true
    end
    if not R.Pet(sheet) then
        self:Print("Pick your companion's family first.")
        return false
    end
    if not self:HasWeaponMastery() then
        self:Print("You need the Weapon Mastery feature to use the mastery of your companion's strike.")
        return false
    end
    local used, limit = self:MasteriesUsed(), self:MasteryLimit()
    if used >= limit then
        self:Print(("All %d of your Weapon Mastery picks are on weapons. Take the mastery off a weapon under Customize, Weapons, then pick your companion's family."):format(limit))
        return false
    end
    sheet.petMastery = true
    return true
end

---------------------------------------------------------------------------
-- How a number is worked out
---------------------------------------------------------------------------
-- For a term such as "companion STR save", as announced by RPSheet:PetCheck.
-- Nil for any other term.
function RPSheet:ExplainPetTerm(term)
    local stat, kind = term:match("^companion (%u%u%u) (%l+)$")
    if not stat or not R.STAT_NAMES[stat] or not self:HasPet() then return end
    return ("Companion's %s %s |cffffd100%s|r: its %s %s, your proficiency bonus %s."):format(
        R.STAT_NAMES[stat], kind == "save" and "saving throw" or "check", Util.Signed(self:PetRollMod(stat)),
        R.STAT_NAMES[stat], Util.Signed(self:PetMod(stat)), Util.Signed(self:ProficiencyBonus()))
end
