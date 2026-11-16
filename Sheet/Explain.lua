-- The explanation of a term by name, for a term clicked in chat (see
-- Integrations/ChatLinks.lua). The explanations themselves are in Sheet/Explain*.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

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
