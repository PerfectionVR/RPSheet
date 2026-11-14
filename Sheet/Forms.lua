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

-- Why a spell can't be cast in the form the character is in, or nil when it can.
-- No spells in a form, except a Circle of the Moon druid's own circle spells, and from
-- level 18 (Beast Spells) any spell without a priced or consumed component.
function RPSheet:FormBlocksSpell(spell)
    local form = self:Form()
    if not form then return end
    local sheet = self:Sheet()
    if sheet.subclass == "Circle of the Moon" and (spell.auto or ""):find("^prepared:") then return end
    if ns.HasFeature(sheet, "Beast Spells") then
        if (spell.material or 0) > 0 or spell.consumed then
            return ("%s needs a component with a price, which can't be used in %s."):format(spell.name, form.beast and "a beast form" or form.name)
        end
        return
    end
    return ("You can't cast spells in %s. Leave the form first."):format(form.beast and "a beast form" or form.name)
end

-- Ends any form the character is in. Returns true if there was one.
function RPSheet:LeaveForms(reason)
    local left = false
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and R.FORMS[passive.name] then
            passive.enabled = false
            left = true
        end
    end
    if left then
        self:Announce(("returns to their own shape: %s."):format(reason))
        self:ClampState()
    end
    return left
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

-- The hit points of a Beast Master's companion, as a bar (data in Data/Pets.lua).
function ns.PetPools(sheet)
    if sheet.subclass ~= "Beast Master" or sheet.level < 3 then return {} end
    return { { name = "Pet HP", max = R.PetHP(sheet, sheet.level) } }
end
