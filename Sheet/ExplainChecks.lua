-- How a check, saving throw, skill, Passive Perception or initiative is worked out
-- (mirrors Sheet/DerivedChecks.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util
local Out = ns.ExplainKit.Out
local Add = ns.ExplainKit.Add
local AddBonuses = ns.ExplainKit.AddBonuses
local Join = ns.ExplainKit.Join
local Total = ns.ExplainKit.Total
local Ability = ns.ExplainKit.Ability
local Show = ns.ExplainKit.Show

function RPSheet:ExplainCheck(stat)
    local parts = {}
    Ability(self, parts, stat)
    AddBonuses(self, parts, "CHECKS")
    Show(self, R.STAT_NAMES[stat] .. " check", parts)
end

function RPSheet:ExplainSave(stat)
    local parts = {}
    Ability(self, parts, stat)
    local listed, form = self:FormSaveBonus(stat), self:Form()
    if self:Sheet().saves[stat] then
        Add(parts, "proficiency", self:ProficiencyBonus())
    elseif listed then
        Add(parts, ("proficiency (%s)"):format(form.name), self:ProficiencyBonus())
    end
    AddBonuses(self, parts, "SAVES")
    AddBonuses(self, parts, "SAVE:" .. stat)
    -- The beast's own bonus replaces all of it when it is higher (see SaveMod).
    if listed and listed > Total(parts) then
        parts = { { ("the %s's own bonus, higher than yours (%s)"):format(form.name:lower(), Util.Signed(Total(parts))), listed } }
    end
    Show(self, R.STAT_NAMES[stat] .. " saving throw", parts)
end

local function SkillParts(self, skill)
    local parts = {}
    Ability(self, parts, skill.stat)
    local rank = self:Sheet().skills[skill.name] or 0
    local form = self:Form()
    local gift = self:CompanionSkillRank(skill.name)
    if gift > rank then
        Add(parts, "expertise from your companion", gift * self:ProficiencyBonus())
    elseif rank == 0 and self:FormSkill(skill.name) then
        Add(parts, ("proficiency (%s)"):format(form.name), self:ProficiencyBonus())
    else
        Add(parts, rank > 1 and "expertise" or "proficiency", rank * self:ProficiencyBonus())
    end
    AddBonuses(self, parts, "SKILL:" .. skill.name)
    AddBonuses(self, parts, "SKILLS")
    AddBonuses(self, parts, "CHECKS")
    -- The beast's own bonus replaces all of it when it is higher (see SkillMod).
    local listed = self:FormSkillBonus(skill.name)
    if listed and listed > Total(parts) then
        return { { ("the %s's own bonus, higher than yours (%s)"):format(form.name:lower(), Util.Signed(Total(parts))), listed } }
    end
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
