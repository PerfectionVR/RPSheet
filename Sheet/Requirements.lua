-- What the rules allow a character: armor training, how many weapon masteries, how
-- many cantrips and prepared spells and of what level. The editor and the wizards
-- ask here before offering a choice.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

---------------------------------------------------------------------------
-- Armor training
---------------------------------------------------------------------------
-- Feats that add training, by passive name.
local TRAINING_FEATS = {
    ["Lightly Armored"] = { "light", "shield" },
    ["Moderately Armored"] = { "medium" },
    ["Heavily Armored"] = { "heavy" },
}

-- { light = true, medium = true, heavy = true, shield = true } for a class key and
-- the passives on a sheet (the list may be empty, as in the creation wizard).
function ns.ArmorTraining(classKey, passives)
    local training = {}
    local class = R.CLASSES[classKey]
    -- The class's training reads like "Light and medium armor, shields; simple weapons".
    local text = class and class.training:match("^[^;]*"):lower() or ""
    if text:find("all armor") then
        training.light, training.medium, training.heavy = true, true, true
    else
        training.light = text:find("light") ~= nil
        training.medium = text:find("medium") ~= nil
    end
    training.shield = text:find("shield") ~= nil
    for _, passive in ipairs(passives or {}) do
        for _, kind in ipairs(TRAINING_FEATS[passive.name] or {}) do training[kind] = true end
        -- A class option can bring training too (a Druid's Warden, a Priest's Protector).
        for _, kind in ipairs(passive.training or {}) do training[kind] = true end
    end
    return training
end

-- "light", "medium" or "heavy" for an armor key; nil for no armor.
function ns.ArmorKind(armorKey)
    local armor = R.ARMOR[armorKey]
    return armor and armor.name:match("%((%a+)%)")
end

-- Armor keys a character with this training can wear, in the usual order.
-- `current` is always included, so an existing choice stays visible.
function ns.ArmorChoices(training, current)
    local values, order = {}, {}
    for _, key in ipairs(R.ARMOR_ORDER) do
        local kind = ns.ArmorKind(key)
        if not kind or training[kind] or key == current then
            values[key] = R.ARMOR[key].name
            order[#order + 1] = key
        end
    end
    return values, order
end

-- The same for a whole character: the first class's training, and the smaller part a
-- class taken later adds (Data/Multiclass.lua).
function ns.SheetArmorTraining(sheet)
    local training = ns.ArmorTraining(sheet.class, sheet.passives)
    for _, key in ipairs(ns.ExtraClassKeys(sheet)) do
        local gained = R.MULTICLASS[R.CLASSES[key].base]
        for _, kind in ipairs(gained and gained.armor or {}) do training[kind] = true end
    end
    return training
end

function RPSheet:ArmorTraining()
    return ns.SheetArmorTraining(self:Sheet())
end

---------------------------------------------------------------------------
-- Weapon mastery
---------------------------------------------------------------------------
-- How many weapons the character can use the mastery of: what the class's feature
-- allows, and one for each feat that unlocks a kind of weapon (Weapon Master).
-- Our reading for several classes: each class's Weapon Mastery is a feature of its
-- own that lets the character pick so many kinds of weapon, and a class gives its
-- features at its own level. The multiclassing rules name the features that don't
-- add up (Extra Attack, the ways to work out Armor Class, Spellcasting) and Weapon
-- Mastery is not one of them, so the picks of the classes are added together.
function RPSheet:MasteryLimit()
    local class = self:ClassData()
    local _, fromFeats = ns.FeatMasteryWeapons(self:Sheet())
    if not class or not self:HasWeaponMastery() then return fromFeats end
    local total = 0
    for _, view in ipairs(ns.ClassViews(self:Sheet())) do
        local base = R.CLASSES[view.class].base
        total = total + (ns.FeatureKit.AtLevel(view.level, R.MASTERY_LIMITS[base] or {}) or 0)
    end
    return total + fromFeats
end

-- How many weapons have a mastery set. A companion's family picked for its strike
-- takes one of the picks too (Sheet/Pet.lua).
function RPSheet:MasteriesUsed()
    local used = self:PetMastery() and 1 or 0
    for _, weapon in ipairs(self:Sheet().weapons) do
        if R.MASTERIES[weapon.mastery] and not weapon.heal then used = used + 1 end
    end
    return used
end

-- Weapons whose mastery counts: the first ones in the list, up to the limit.
function RPSheet:MasteredWeapons()
    local counted, left = {}, self:MasteryLimit() - (self:PetMastery() and 1 or 0)
    for _, weapon in ipairs(self:Sheet().weapons) do
        if R.MASTERIES[weapon.mastery] and not weapon.heal and left > 0 then
            counted[weapon], left = true, left - 1
        end
    end
    return counted, left
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------
-- Cantrips known, spells prepared, and the highest spell level the character has
-- slots for. All zero for a class that doesn't cast.
-- With several classes each one has limits of its own, by its own level: `classKey`
-- asks for one class, and without it the classes are added up (the highest spell
-- level is then the highest any of them can prepare).
function RPSheet:SpellLimits(classKey)
    local sheet = self:Sheet()
    if ns.IsMulticlass(sheet) then
        local cantrips, prepared, highest = 0, 0, 0
        for _, view in ipairs(ns.ClassViews(sheet)) do
            local class = R.CLASSES[view.class]
            if class and class.caster and (not classKey or classKey == view.class) then
                cantrips = cantrips + (ns.FeatureKit.AtLevel(view.level, R.CANTRIPS_KNOWN[class.base] or {}) or 0)
                prepared = prepared + ((R.SPELLS_PREPARED[class.base] or {})[view.level] or 0)
                highest = math.max(highest, ns.ClassSpellLevel(class, view.level))
            end
        end
        return cantrips, prepared, highest
    end
    local class = self:ClassData()
    if not class or not class.caster then return 0, 0, 0 end
    local level = self:Level()
    local highest = 0
    for spellLevel in pairs(self:SpellSlots()) do highest = math.max(highest, spellLevel) end
    return ns.FeatureKit.AtLevel(level, R.CANTRIPS_KNOWN[class.base] or {}) or 0,
        (R.SPELLS_PREPARED[class.base] or {})[level] or 0,
        highest
end

-- How many cantrips and prepared spells are on the sheet. Spells marked as not
-- counting (always prepared, from a lineage or a feat) are left out; so is `except`.
-- `classKey` counts only the spells of one class of a character with several.
function RPSheet:SpellCounts(except, classKey)
    local cantrips, prepared = 0, 0
    local sheet = self:Sheet()
    for _, spell in ipairs(sheet.spells) do
        local counted = not classKey or ns.SpellClass(sheet, spell) == classKey
        if spell ~= except and not spell.free and spell.name ~= "" and counted then
            if spell.level == 0 then cantrips = cantrips + 1 else prepared = prepared + 1 end
        end
    end
    return cantrips, prepared
end

-- True if one more spell of this level would still fit.
function RPSheet:SpellFits(level, except, classKey)
    local maxCantrips, maxPrepared, highest = self:SpellLimits(classKey)
    local cantrips, prepared = self:SpellCounts(except, classKey)
    if level == 0 then return cantrips < maxCantrips end
    return level <= highest and prepared < maxPrepared
end
