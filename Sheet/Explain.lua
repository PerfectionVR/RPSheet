-- Shows how a number on the sheet is worked out, as a line only the player sees.
-- e.g. "Rapier, to hit +5: Dexterity +3, proficiency +2."
-- Each Explain function mirrors the calculation next to it in Sheet/Derived.lua,
-- Sheet/Combat.lua or Actions/Weapons.lua: change them together.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

-- Explanations are printed for the player, or collected when another player asked
-- (see RPSheet:ExplainTerm).
local function Out(self, text)
    if self.explainCapture then
        self.explainCapture[#self.explainCapture + 1] = text
    else
        self:Print(text)
    end
end

-- A list of { label, value } that add up to a total.
local function Add(parts, label, value)
    if value and value ~= 0 then parts[#parts + 1] = { label, value } end
end

-- What switched-on passives and exhaustion add to `target` (see RPSheet:Bonus).
local D20_TARGETS = { ATTACK = true, SPELLATK = true, SAVES = true, CHECKS = true, INIT = true }
local function AddBonuses(self, parts, target)
    local exhaustion = self:State().exhaustion or 0
    if D20_TARGETS[target] then
        Add(parts, "exhaustion", -R.EXHAUSTION_D20 * exhaustion)
    elseif target == "SPEED" then
        Add(parts, "exhaustion", -R.EXHAUSTION_SPEED * exhaustion)
    end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= "" and not self:PassiveBlocked(passive) then
            for _, effect in ipairs(passive.effects) do
                if effect.target == target then Add(parts, passive.name, self:EffectValue(effect)) end
            end
        end
    end
end

-- "Dexterity +3, proficiency +2", or "nothing added" for an empty list.
local function Join(parts)
    local texts = {}
    for _, part in ipairs(parts) do texts[#texts + 1] = ("%s %s"):format(part[1], Util.Signed(part[2])) end
    return #texts > 0 and table.concat(texts, ", ") or "nothing added"
end

local function Total(parts)
    local total = 0
    for _, part in ipairs(parts) do total = total + part[2] end
    return total
end

-- The ability modifier always shows, even at +0.
local function Ability(self, parts, stat)
    parts[#parts + 1] = { R.STAT_NAMES[stat] or "no ability", self:Mod(stat) }
end

local function Show(self, what, parts, prefix)
    Out(self, ("%s %s%s|r: %s%s."):format(what, "|cffffd100", Util.Signed(Total(parts)), prefix or "", Join(parts)))
end

---------------------------------------------------------------------------
function RPSheet:ExplainCheck(stat)
    local parts = {}
    Ability(self, parts, stat)
    AddBonuses(self, parts, "CHECKS")
    Show(self, R.STAT_NAMES[stat] .. " check", parts)
end

function RPSheet:ExplainSave(stat)
    local parts = {}
    Ability(self, parts, stat)
    if self:Sheet().saves[stat] then Add(parts, "proficiency", self:ProficiencyBonus()) end
    AddBonuses(self, parts, "SAVES")
    AddBonuses(self, parts, "SAVE:" .. stat)
    Show(self, R.STAT_NAMES[stat] .. " saving throw", parts)
end

local function SkillParts(self, skill)
    local parts = {}
    Ability(self, parts, skill.stat)
    local rank = self:Sheet().skills[skill.name] or 0
    Add(parts, rank > 1 and "expertise" or "proficiency", rank * self:ProficiencyBonus())
    AddBonuses(self, parts, "SKILL:" .. skill.name)
    AddBonuses(self, parts, "SKILLS")
    AddBonuses(self, parts, "CHECKS")
    return parts
end

function RPSheet:ExplainSkill(skill)
    Show(self, skill.name, SkillParts(self, skill))
end

function RPSheet:ExplainPassivePerception()
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == "Perception" then
            local parts = SkillParts(self, skill)
            Out(self, ("Passive Perception |cffffd100%d|r: 10, %s."):format(10 + Total(parts), Join(parts)))
        end
    end
end

function RPSheet:ExplainInitiative()
    local parts = {}
    Ability(self, parts, "DEX")
    AddBonuses(self, parts, "INIT")
    Show(self, "Initiative", parts)
end

function RPSheet:ExplainSpeed()
    local stuck = self:Immobile()
    if stuck then
        Out(self, ("Speed |cffffd1000 ft|r: you are %s."):format(stuck))
        return
    end
    local species, form = self:SpeciesData(), self:Form()
    local parts = { { species and species.name or "base", species and species.speed or 30 } }
    if form then parts = { { form.name, form.speed } } end
    AddBonuses(self, parts, "SPEED")
    Add(parts, "armor too heavy for your Strength", -self:ArmorSpeedPenalty())
    Out(self, ("Speed |cffffd100%d ft|r: %s."):format(Total(parts), Join(parts)))
end

function RPSheet:ExplainAC()
    local sheet, class = self:Sheet(), self:ClassData()
    local form = self:Form()
    if form then
        local formParts = { { form.name, form.ac } }
        if form.acStat then Add(formParts, R.STAT_NAMES[form.acStat], self:Mod(form.acStat)) end
        if form.beast and sheet.subclass == "Circle of the Moon" then
            Add(formParts, "Circle Forms (at least 13 + Wisdom)", math.max(0, 13 + self:Mod("WIS") - form.ac))
        end
        AddBonuses(self, formParts, "AC")
        Out(self, ("Armor Class |cffffd100%d|r: %s. Armor and shield don't count in this form."):format(Total(formParts), Join(formParts)))
        return
    end
    local armor = R.ARMOR[sheet.armor]
    local parts = { { armor.name, armor.ac } }
    local dex = self:Mod("DEX")
    if armor.dexCap then
        Add(parts, ("Dexterity (at most +%d in this armor)"):format(armor.dexCap), math.min(dex, armor.dexCap))
    else
        Add(parts, "Dexterity", dex)
    end
    if sheet.armor == "NONE" and class and class.unarmored and (class.unarmoredShield or not sheet.shield) then
        Add(parts, "Unarmored Defense, " .. R.STAT_NAMES[class.unarmored], self:Mod(class.unarmored))
    end
    if sheet.shield then Add(parts, "shield", R.SHIELD_AC) end
    AddBonuses(self, parts, "AC")
    Add(parts, "Fighting Style", self:StyleAC())
    Out(self, ("Armor Class |cffffd100%d|r: %s."):format(Total(parts), Join(parts)))
end

function RPSheet:ExplainSpellDC()
    local stat = self:CastStat()
    if not stat then return end
    local parts = { { "base", 8 }, { "proficiency", self:ProficiencyBonus() } }
    Ability(self, parts, stat)
    AddBonuses(self, parts, "SPELLDC")
    Out(self, ("Spell save DC |cffffd100%d|r: %s."):format(Total(parts), Join(parts)))
end

local function SpellAttackParts(self)
    local parts = { { "proficiency", self:ProficiencyBonus() } }
    Ability(self, parts, self:CastStat())
    AddBonuses(self, parts, "SPELLATK")
    return parts
end

function RPSheet:ExplainSpellAttack()
    if self:CastStat() then Show(self, "Spell attack", SpellAttackParts(self)) end
end

function RPSheet:ExplainSpell(spell)
    local lines = {}
    if spell.kind == "ATTACK" then
        local parts = SpellAttackParts(self)
        lines[#lines + 1] = ("spell attack |cffffd100%s|r: %s"):format(Util.Signed(Total(parts)), Join(parts))
    elseif spell.kind == "SAVE" then
        lines[#lines + 1] = ("%s save against your spell save DC |cffffd100%d|r"):format(R.STAT_NAMES[spell.save] or spell.save, self:SpellDC() or 8)
    end
    if spell.count > 0 then
        local word, bonus = ns.DiceWord(spell.dice)
        local parts = {}
        if spell.addMod then Ability(self, parts, self:CastStat()) end
        if bonus then AddBonuses(self, parts, bonus) end
        lines[#lines + 1] = ("%s %dd%d %s: %s"):format(word, self:SpellDiceCount(spell), spell.sides, Util.Signed(Total(parts)), Join(parts))
    end
    if #lines == 0 then lines[1] = "nothing is rolled" end
    Out(self, ("%s: %s."):format(spell.name, table.concat(lines, "; ")))
end

function RPSheet:ExplainWeapon(weapon)
    local sheet = self:Sheet()
    if weapon.heal then
        local parts = {}
        Ability(self, parts, self:WeaponStat(weapon))
        AddBonuses(self, parts, "HEALING")
        Out(self, ("%s, healing %dd%d %s: %s."):format(weapon.name, weapon.dice, weapon.sides, Util.Signed(Total(parts)), Join(parts)))
        return
    end
    local hit, damage, notes = {}, {}, {}
    Ability(self, hit, self:WeaponStat(weapon))
    Ability(self, damage, self:WeaponStat(weapon))
    if weapon.proficient then Add(hit, "proficiency", self:ProficiencyBonus()) end
    AddBonuses(self, hit, "ATTACK")
    AddBonuses(self, damage, "DAMAGE")
    if self:WeaponStat(weapon) == "STR" then AddBonuses(self, damage, "STRDAMAGE") end
    -- Fighting Styles that fit this weapon (see RPSheet:WeaponStyle).
    local seen = {}
    for slot, field in ipairs(ns.STYLE_FIELDS) do
        local name = sheet[field]
        local style = R.FIGHTING_STYLES[name]
        if style and not seen[name] and ns.HasStyleSlot(sheet, slot) and ns.FitsStyle(weapon, style) then
            seen[name] = true
            Add(hit, name, style.attack)
            Add(damage, name, style.damage)
            if style.minDie then notes[#notes + 1] = ("%s: a damage die below %d counts as %d"):format(name, style.minDie, style.minDie) end
        end
    end
    local count, sides = self:WeaponDice(weapon)
    local data = ns.WeaponData(weapon)
    if data and data.versatile then
        notes[#notes + 1] = weapon.twoHands and "held in two hands for the larger die" or "held in one hand"
    end
    Out(self, ("%s, to hit |cffffd100%s|r: %s. %s %dd%d |cffffd100%s|r: %s.%s"):format(
        weapon.name, Util.Signed(Total(hit)), Join(hit),
        ns.DamageWord(weapon):gsub("^%l", string.upper), count, sides, Util.Signed(Total(damage)), Join(damage),
        #notes > 0 and (" " .. table.concat(notes, "; "):gsub("^%l", string.upper) .. ".") or ""))
end

---------------------------------------------------------------------------
-- By name, for a term clicked in chat (see Integrations/ChatLinks.lua)
---------------------------------------------------------------------------
local function Named(list, name)
    for _, entry in ipairs(list) do
        if entry.name == name then return entry end
    end
end

-- The explanation for a term as it stands on this character, as plain text, or nil
-- when there is nothing to work out for it.
function RPSheet:ExplainTerm(term)
    local sheet = self:Sheet()
    -- A companion's roll has its own numbers (Sheet/Pet.lua).
    local petText = self:ExplainPetTerm(term)
    if petText then return petText end
    self.explainCapture = {}
    local weapon, spell = Named(sheet.weapons, term), Named(sheet.spells, term)
    local stat, kind = term:match("^(%u%u%u) (%l+)$")
    if weapon then
        self:ExplainWeapon(weapon)
    elseif spell then
        self:ExplainSpell(spell)
    elseif stat and R.STAT_NAMES[stat] and kind == "check" then
        self:ExplainCheck(stat)
    elseif stat and R.STAT_NAMES[stat] and kind == "save" then
        self:ExplainSave(stat)
    elseif term == "initiative" then
        self:ExplainInitiative()
    elseif term == "spell attack" then
        self:ExplainSpellAttack()
    else
        for _, skill in ipairs(R.SKILLS) do
            if skill.name == term then self:ExplainSkill(skill) end
        end
    end
    local lines = self.explainCapture
    self.explainCapture = nil
    if #lines > 0 then return table.concat(lines, " ") end
    -- An ability or passive of the character's own: what it says on the sheet.
    local entry = Named(sheet.abilities, term) or Named(sheet.passives, term)
    if entry and entry.desc ~= "" then return ("%s: %s"):format(term, entry.desc) end
end
