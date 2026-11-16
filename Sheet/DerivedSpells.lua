-- Numbers worked out from the saved sheet: spellcasting ability, save DC, attack and slots.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Spellcasting ability: the sheet's override, else the class's. Nil for non-casters.
-- A `spell` a feat put on the list uses the ability that goes with the feat
-- (Sheet/FeatSpells.lua), whatever the class; one a species or lineage put there, the
-- ability chosen for it (Sheet/LineageSpells.lua). With several classes a spell is cast
-- with the ability of the class it belongs to (spell.class, Sheet/ClassSpells.lua);
-- the override is for the first class's spells and those that name no class.
function RPSheet:CastStat(spell)
    local sheet, class = self:Sheet(), self:ClassData()
    local own = spell and (ns.FeatSpellStat(sheet, spell) or ns.SpeciesSpellStat(sheet, spell))
    if own then return own end
    local key = ns.SpellClass(sheet, spell)
    if key and key ~= sheet.class and spell and spell.class == key then return R.CLASSES[key].cast end
    if R.STAT_NAMES[sheet.castStat] then return sheet.castStat end
    if class and class.cast then return class.cast end
    return key and R.CLASSES[key].cast
end

function RPSheet:SpellDC(spell)
    local stat = self:CastStat(spell)
    return stat and (8 + self:ProficiencyBonus() + self:Mod(stat) + self:Bonus("SPELLDC"))
end

function RPSheet:SpellAttack(spell)
    local stat = self:CastStat(spell)
    return stat and (self:ProficiencyBonus() + self:Mod(stat) + self:Bonus("SPELLATK"))
end

-- Spell slots as { [spell level] = number }: the class's own, or the slots the
-- character's spellcasting classes share (Sheet/MulticlassSlots.lua). Pact Magic slots
-- kept beside those are RPSheet:PactSlots().
function RPSheet:SpellSlots()
    return (ns.SheetSlots(self:Sheet()))
end
