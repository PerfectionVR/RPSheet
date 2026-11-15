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

local MOON = "Circle of the Moon"

-- True for a spell the Circle of the Moon keeps prepared at the character's level in
-- that class. Another class's always-prepared spells are not the circle's.
local function CircleSpell(sheet, spell)
    local view = ns.SubclassView(sheet, MOON)
    if not view or not (spell.auto or ""):find("^prepared:") then return false end
    for _, feature in ipairs(R.SUBCLASS_FEATURES[MOON] or {}) do
        for _, step in ipairs(type(feature.prepared) == "table" and feature.prepared or {}) do
            if view.level >= step[1] then
                for name in step[2]:gmatch("[^,]+") do
                    if strtrim(name) == spell.name then return true end
                end
            end
        end
    end
    return false
end

-- Why a spell can't be cast in the form the character is in, or nil when it can.
-- No spells in a form, except a Circle of the Moon druid's own circle spells, and from
-- level 18 (Beast Spells) any spell without a priced or consumed component; one read
-- from a scroll needs no components at all (Actions/Scrolls.lua).
function RPSheet:FormBlocksSpell(spell)
    local form = self:Form()
    if not form then return end
    local sheet = self:Sheet()
    if CircleSpell(sheet, spell) then return end
    if ns.HasFeature(sheet, "Beast Spells") then
        -- The listed spells go by the component data; a spell of the player's own by its fields.
        if not spell.fromScroll and (R.SPELL_COMPONENTS[spell.name] or (spell.material or 0) > 0 or spell.consumed) then
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
        self:PopulateSoon() -- the sheet showed the form's numbers and attacks
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

-- The bonus the beast the character has become has in a skill by itself, or nil.
function RPSheet:FormSkillBonus(name)
    local form = self:Form()
    return form and form.skillBonus and form.skillBonus[name]
end

-- The bonus the beast has in a saving throw by itself, or nil when it isn't
-- proficient in it. The character is proficient in such a save while in the form.
function RPSheet:FormSaveBonus(stat)
    local form = self:Form()
    return form and form.saveBonus and form.saveBonus[stat]
end

-- The hit points of a Beast Master's companion, as a bar (data in Data/Pets.lua).
function ns.PetPools(sheet)
    local view = ns.SubclassView(sheet, "Beast Master") -- its level in that class counts
    if not view or view.level < 3 then return {} end
    return { { name = "Pet HP", max = R.PetHP(view, view.level) } }
end
