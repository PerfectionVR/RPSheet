-- Class features that add to the spells the sheet casts (Actions/Spells.lua):
--   Potent Spellcasting   Wisdom modifier on the damage of Cleric or Druid cantrips
--   Elemental Affinity    Charisma modifier on one damage roll of a spell of its type
--   Empowered Evocation   Intelligence modifier on one damage roll of a Mage evocation
--   Disciple of Life      2 + the slot's level on a slotted spell's healing
-- and casting Hunter's Mark from the spell list switches on the class's passive of
-- the same name. What features do to the dice themselves is in Actions/FeatureDice.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The option picked for a choice the character has, or nil. A choice that is made
-- shows as "<feature>: <option>" (Sheet/ClassFeatures.lua).
local function Option(sheet, feature)
    local picked = (sheet.featureOptions or {})[feature]
    if picked and ns.HasFeature(sheet, feature .. ": " .. picked) then return picked end
end

-- True if the spell is one of the class's own (a PHB class name such as "Cleric"),
-- cast as that class rather than through a feat or species trait.
local function OwnSpell(self, sheet, spell, base)
    if ns.FeatSpellStat(sheet, spell) or ns.SpeciesSpellStat(sheet, spell) then return false end
    local class = R.CLASSES[ns.SpellClass(sheet, spell) or ""]
    if not class or class.base ~= base then return false end
    for _, name in ipairs(R.SPELL_LISTS[base] or {}) do
        if name == spell.name then return true end
    end
    return false
end

-- Potent Spellcasting: a Cleric's (Blessed Strikes) or a Druid's (Elemental Fury).
local POTENT = { Cleric = "Blessed Strikes", Druid = "Elemental Fury" }

-- What class features add to a spell's dice: `every` to each damage roll, `once` to
-- the first only, and a note naming them. `slot` is the slot spent, if any.
function RPSheet:SpellFeatureBonus(spell, slot)
    local sheet = self:Sheet()
    local every, once, names = 0, 0, {}
    if spell.dice == "DAMAGE" or spell.dice == "DRAIN" then
        if spell.level == 0 and not spell.addMod then
            for base, feature in pairs(POTENT) do
                if Option(sheet, feature) == "Potent Spellcasting" and OwnSpell(self, sheet, spell, base) then
                    every = every + self:Mod("WIS")
                    names[#names + 1] = "Potent Spellcasting"
                    break
                end
            end
        end
        local affinity = Option(sheet, "Elemental Affinity")
        if affinity and ns.SpellDamageType(spell) == affinity:lower() then
            once = once + self:Mod("CHA")
            names[#names + 1] = "Elemental Affinity"
        end
        if ns.HasFeature(sheet, "Empowered Evocation") and R.EVOCATION[spell.name] and OwnSpell(self, sheet, spell, "Wizard") then
            once = once + self:Mod("INT")
            names[#names + 1] = "Empowered Evocation"
        end
    elseif (spell.dice == "HEALING" or spell.dice == "SELFHEAL") and slot and ns.HasFeature(sheet, "Disciple of Life") then
        once = once + 2 + slot.level
        names[#names + 1] = "Disciple of Life"
    end
    return every, once, #names > 0 and ("with " .. table.concat(names, ", ")) or nil
end

-- Called once a spell is cast. Returns a note for the announcement, or nil.
function RPSheet:SpellCastFeatures(spell)
    if spell.name ~= "Hunter's Mark" then return end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.name == "Hunter's Mark" and (passive.auto or "") ~= "" then
            if passive.enabled then return end
            passive.enabled = true
            self:PopulateSoon()
            return "Hunter's Mark switched on"
        end
    end
end
