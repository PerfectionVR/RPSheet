-- Every number worked out from the saved sheet: scores, proficiency, hit points,
-- Armor Class, saving throws, skills and spellcasting.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

function RPSheet:ClassData()
    return R.CLASSES[self:Sheet().class]
end

function RPSheet:SpeciesData()
    return R.SPECIES[self:Sheet().species]
end

function RPSheet:Level()
    return self:Sheet().level
end

function RPSheet:ProficiencyBonus()
    return 2 + math.floor((self:Level() - 1) / 4)
end

---------------------------------------------------------------------------
-- Ability scores
---------------------------------------------------------------------------
-- Starting score, plus the background's points, plus points from level-ups.
function RPSheet:Score(stat)
    local sheet = self:Sheet()
    local score = (sheet.base[stat] or R.BASE_MIN) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
    -- A capstone feature can raise a score further, up to 25.
    local raised = sheet.featureScores and sheet.featureScores[stat]
    if raised then score = math.max(score, math.min(25, score + raised)) end
    return score
end

-- Modifier of an ability; an empty or unknown ability counts as +0.
function RPSheet:Mod(stat)
    if not R.STAT_NAMES[stat] then return 0 end
    return Util.ScoreMod(self:Score(stat))
end

function RPSheet:PointsSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + (R.COST[self:Sheet().base[stat]] or 0)
    end
    return total
end

function RPSheet:BonusSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + self:Sheet().bonus[stat]
    end
    return total
end

---------------------------------------------------------------------------
-- Passive effects
---------------------------------------------------------------------------
-- flat + times x source, where the source is an ability modifier, the level or the
-- proficiency bonus (see Rules.AMOUNT_SOURCES).
function RPSheet:Amount(flat, source, times)
    local value
    if source == "LEVEL" then
        value = self:Level()
    elseif source == "PROF" then
        value = self:ProficiencyBonus()
    else
        value = self:Mod(source)
    end
    return (flat or 0) + (times or 1) * value
end

function RPSheet:EffectValue(effect)
    return self:Amount(effect.flat, effect.stat, effect.times)
end

-- Total of every switched-on passive effect aimed at `target` (see Rules.EFFECT_TARGETS).
-- Exhaustion weighs on every d20 roll and on speed.
local D20_TARGETS = { ATTACK = true, SPELLATK = true, SAVES = true, CHECKS = true, INIT = true }

function RPSheet:Bonus(target)
    local total = 0
    local exhaustion = self:State().exhaustion or 0
    if D20_TARGETS[target] then
        total = -R.EXHAUSTION_D20 * exhaustion
    elseif target == "SPEED" then
        total = -R.EXHAUSTION_SPEED * exhaustion
    end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= "" then
            for _, effect in ipairs(passive.effects) do
                if effect.target == target then
                    total = total + self:EffectValue(effect)
                end
            end
        end
    end
    return total
end

-- e.g. "+3 +2x DEX to Armor Class (now +9)"
function RPSheet:EffectText(effect)
    local parts = {}
    if effect.flat ~= 0 then parts[#parts + 1] = Util.Signed(effect.flat) end
    if R.AMOUNT_SOURCES[effect.stat] and effect.stat ~= "" then
        parts[#parts + 1] = "+" .. (effect.times > 1 and (effect.times .. "x ") or "") .. (R.AMOUNT_SHORT[effect.stat] or effect.stat)
    end
    if #parts == 0 then parts[1] = "+0" end
    return ("%s to %s (now %s)"):format(
        table.concat(parts, " "), R.EFFECT_TARGETS[effect.target] or effect.target, Util.Signed(self:EffectValue(effect)))
end

---------------------------------------------------------------------------
-- Hit points and defense
---------------------------------------------------------------------------
-- Level 1 takes the full hit die; each later level takes the average, rounded up.
function RPSheet:MaxHP()
    local class = self:ClassData()
    local die = class and class.hitDie or R.DEFAULT_HIT_DIE
    local level = self:Level()
    local total = die + (level - 1) * (die / 2 + 1) + level * self:Mod("CON")
    return math.max(1, total + self:Bonus("HP") + self:Sheet().hpAdjust)
end

function RPSheet:AC()
    local sheet, class = self:Sheet(), self:ClassData()
    local armor = R.ARMOR[sheet.armor]
    local dex = self:Mod("DEX")
    if armor.dexCap then dex = math.min(dex, armor.dexCap) end
    local ac = armor.ac + dex
    if sheet.armor == "NONE" and class and class.unarmored then
        -- Unarmored Defense; a Monk's stops working with a shield.
        if class.unarmoredShield or not sheet.shield then
            ac = ac + self:Mod(class.unarmored)
        end
    end
    if sheet.shield then ac = ac + R.SHIELD_AC end
    return ac + self:Bonus("AC") + self:StyleAC()
end

function RPSheet:Initiative()
    return self:Mod("DEX") + self:Bonus("INIT")
end

function RPSheet:Speed()
    local species = self:SpeciesData()
    return (species and species.speed or 30) + self:Bonus("SPEED")
end

---------------------------------------------------------------------------
-- Checks, saving throws and skills
---------------------------------------------------------------------------
function RPSheet:CheckMod(stat)
    return self:Mod(stat) + self:Bonus("CHECKS")
end

function RPSheet:SaveMod(stat)
    local mod = self:Mod(stat) + self:Bonus("SAVES") + self:Bonus("SAVE:" .. stat)
    if self:Sheet().saves[stat] then mod = mod + self:ProficiencyBonus() end
    return mod
end

-- Ability modifier, proficiency (doubled for expertise) and passive effects.
function RPSheet:SkillMod(skill)
    local rank = self:Sheet().skills[skill.name] or 0
    return self:Mod(skill.stat) + rank * self:ProficiencyBonus()
        + self:Bonus("SKILL:" .. skill.name) + self:Bonus("SKILLS") + self:Bonus("CHECKS")
end

function RPSheet:PassivePerception()
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == "Perception" then return 10 + self:SkillMod(skill) end
    end
    return 10
end

---------------------------------------------------------------------------
-- Spellcasting
---------------------------------------------------------------------------
-- Spellcasting ability: the sheet's override, else the class's. Nil for non-casters.
function RPSheet:CastStat()
    local sheet, class = self:Sheet(), self:ClassData()
    if R.STAT_NAMES[sheet.castStat] then return sheet.castStat end
    return class and class.cast
end

function RPSheet:SpellDC()
    local stat = self:CastStat()
    return stat and (8 + self:ProficiencyBonus() + self:Mod(stat) + self:Bonus("SPELLDC"))
end

function RPSheet:SpellAttack()
    local stat = self:CastStat()
    return stat and (self:ProficiencyBonus() + self:Mod(stat) + self:Bonus("SPELLATK"))
end

-- Spell slots as { [spell level] = number }.
function RPSheet:SpellSlots()
    local class, level = self:ClassData(), self:Level()
    local slots = {}
    if not class or not class.caster then return slots end
    if class.caster == "FULL" then
        for spellLevel, count in ipairs(R.FULL_SLOTS[level]) do slots[spellLevel] = count end
    elseif class.caster == "HALF" then
        for spellLevel, count in ipairs(R.FULL_SLOTS[math.ceil(level / 2)]) do slots[spellLevel] = count end
    elseif class.caster == "PACT" then
        local pact = R.PACT_SLOTS[level]
        slots[pact[2]] = pact[1]
    end
    return slots
end

---------------------------------------------------------------------------
-- Origin
---------------------------------------------------------------------------
-- The chosen lineage's entry (see Data/Lineages.lua), or nil.
function RPSheet:LineageData()
    local sheet = self:Sheet()
    local _, option = R.Lineage(sheet.species, sheet.lineage)
    return option
end

-- Darkvision range in feet, or nil. A lineage can extend the species' range.
function RPSheet:Darkvision()
    local species, lineage = self:SpeciesData(), self:LineageData()
    return lineage and lineage.darkvision or species and species.darkvision
end

-- Languages the character knows, sorted.
function RPSheet:Languages()
    local known = {}
    for _, language in ipairs(R.ALL_LANGUAGES) do
        if self:Sheet().languages[language] then known[#known + 1] = language end
    end
    return known
end
