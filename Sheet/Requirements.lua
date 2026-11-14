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

function RPSheet:ArmorTraining()
    return ns.ArmorTraining(self:Sheet().class, self:Sheet().passives)
end

---------------------------------------------------------------------------
-- Weapon mastery
---------------------------------------------------------------------------
-- How many weapons the character can use the mastery of.
function RPSheet:MasteryLimit()
    local class = self:ClassData()
    if not class or not self:HasWeaponMastery() then return 0 end
    return ns.FeatureKit.AtLevel(self:Level(), R.MASTERY_LIMITS[class.base] or {}) or 0
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
function RPSheet:SpellLimits()
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
function RPSheet:SpellCounts(except)
    local cantrips, prepared = 0, 0
    for _, spell in ipairs(self:Sheet().spells) do
        if spell ~= except and not spell.free and spell.name ~= "" then
            if spell.level == 0 then cantrips = cantrips + 1 else prepared = prepared + 1 end
        end
    end
    return cantrips, prepared
end

-- True if one more spell of this level would still fit.
function RPSheet:SpellFits(level, except)
    local maxCantrips, maxPrepared, highest = self:SpellLimits()
    local cantrips, prepared = self:SpellCounts(except)
    if level == 0 then return cantrips < maxCantrips end
    return level <= highest and prepared < maxPrepared
end
