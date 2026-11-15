-- Numbers worked out from the saved sheet: checks, saving throws and skills.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

function RPSheet:CheckMod(stat)
    return self:Mod(stat) + self:Bonus("CHECKS")
end

function RPSheet:SaveMod(stat)
    local mod = self:Mod(stat) + self:Bonus("SAVES") + self:Bonus("SAVE:" .. stat)
    -- A beast form adds the saves the beast is proficient in, and its own bonus is
    -- used where it is the higher one.
    local listed = self:FormSaveBonus(stat)
    if self:Sheet().saves[stat] or listed then mod = mod + self:ProficiencyBonus() end
    return math.max(mod, listed or mod)
end

-- Ability modifier, proficiency (doubled for expertise) and passive effects.
function RPSheet:SkillMod(skill)
    local rank = self:Sheet().skills[skill.name] or 0
    if rank == 0 and self:FormSkill(skill.name) then rank = 1 end
    rank = math.max(rank, self:CompanionSkillRank(skill.name)) -- a loyal companion's gift
    local own = self:Mod(skill.stat) + rank * self:ProficiencyBonus()
        + self:Bonus("SKILL:" .. skill.name) + self:Bonus("SKILLS") + self:Bonus("CHECKS")
    -- In a beast form the beast's own bonus is used where it is the higher one.
    return math.max(own, self:FormSkillBonus(skill.name) or own)
end

function RPSheet:PassivePerception()
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == "Perception" then return 10 + self:SkillMod(skill) end
    end
    return 10
end
