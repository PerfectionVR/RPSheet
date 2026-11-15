-- How the spell save DC, the spell attack and one spell's rolls are worked out
-- (mirrors Sheet/DerivedSpells.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util
local Out = ns.ExplainKit.Out
local AddBonuses = ns.ExplainKit.AddBonuses
local Join = ns.ExplainKit.Join
local Total = ns.ExplainKit.Total
local Ability = ns.ExplainKit.Ability
local Show = ns.ExplainKit.Show

function RPSheet:ExplainSpellDC()
    local stat = self:CastStat()
    if not stat then return end
    local parts = { { "base", 8 }, { "proficiency", self:ProficiencyBonus() } }
    Ability(self, parts, stat)
    AddBonuses(self, parts, "SPELLDC")
    Out(self, ("Spell save DC |cffffd100%d|r: %s."):format(Total(parts), Join(parts)))
end

local function SpellAttackParts(self, spell)
    local parts = { { "proficiency", self:ProficiencyBonus() } }
    Ability(self, parts, self:CastStat(spell))
    AddBonuses(self, parts, "SPELLATK")
    return parts
end

function RPSheet:ExplainSpellAttack()
    if self:CastStat() then Show(self, "Spell attack", SpellAttackParts(self)) end
end

function RPSheet:ExplainSpell(spell)
    local lines = {}
    if spell.kind == "ATTACK" then
        local parts = SpellAttackParts(self, spell)
        lines[#lines + 1] = ("spell attack |cffffd100%s|r: %s"):format(Util.Signed(Total(parts)), Join(parts))
    elseif spell.kind == "SAVE" then
        lines[#lines + 1] = ("%s save against your spell save DC |cffffd100%d|r"):format(R.STAT_NAMES[spell.save] or spell.save, self:SpellDC(spell) or 8)
    end
    if spell.count > 0 then
        local word, bonus = ns.DiceWord(spell.dice)
        local parts = {}
        if spell.addMod then Ability(self, parts, self:CastStat(spell)) end
        if bonus then AddBonuses(self, parts, bonus) end
        lines[#lines + 1] = ("%s %dd%d %s: %s"):format(word, self:SpellDiceCount(spell), spell.sides, Util.Signed(Total(parts)), Join(parts))
    end
    if #lines == 0 then lines[1] = "nothing is rolled" end
    Out(self, ("%s: %s."):format(spell.name, table.concat(lines, "; ")))
end
