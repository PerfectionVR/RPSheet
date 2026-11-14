-- The form the character is in (data in Data/Forms.lua). Sheet/Derived.lua asks here
-- when it works out ability scores, Armor Class, speed and skills.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The form whose passive is switched on, or nil.
function RPSheet:Form()
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and R.FORMS[passive.name] then return R.FORMS[passive.name] end
    end
end

-- True if the form the character is in is proficient in the skill.
function RPSheet:FormSkill(name)
    local form = self:Form()
    if not form then return false end
    for _, skill in ipairs(form.skills) do
        if skill == name then return true end
    end
    return false
end
