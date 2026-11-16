-- Wizard step 2, the species traits that ask for a choice: a skill, a tool or an
-- origin feat.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard
local GOLD = Opt.GOLD

-- What the draft can pick for a species trait: skills its class and background don't
-- already give, or origin feats other than the background's.
local function DraftTraitOptions(name)
    local draft, trait, names = W.draft, R.TRAITS[name], {}
    local background = R.BACKGROUNDS[draft.background]
    if trait.choice == "SKILL" then
        local taken = {}
        for skill, picked in pairs(draft.classSkills) do taken[skill] = picked end
        for _, skill in ipairs(background and background.skills or {}) do taken[skill] = true end
        for other, choice in pairs(draft.traitChoices) do
            if other ~= name then taken[choice] = true end
        end
        for _, row in ipairs(W.Extras()) do taken[row.skill] = true end -- a later class's one skill
        local pool = trait.options
        if not pool then
            pool = {}
            for _, skill in ipairs(R.SKILLS) do pool[#pool + 1] = skill.name end
        end
        for _, skill in ipairs(pool) do
            if not taken[skill] then names[#names + 1] = skill end
        end
    elseif trait.choice == "TOOL" then
        -- Any tool but the trait's other pick.
        local other = draft.traitChoices[trait.more or trait.of or ""]
        for _, tool in ipairs(R.TOOL_ORDER) do
            if tool ~= other then names[#names + 1] = tool end
        end
    else
        for _, feat in ipairs(R.FEAT_NAMES.GENERAL) do
            local data = R.FEATS[feat]
            local allowed = not data.needSpecies or data.needSpecies == draft.species
            if data.kind == "ORIGIN" and allowed and (data.repeatable or not (background and background.feat == feat)) then
                names[#names + 1] = feat
            end
        end
    end
    return names
end
-- The step check asks whether a pick still stands (Wizard/Draft.lua).
function W.TraitOptions(name) return DraftTraitOptions(name) end

local function DraftTraitPicker(name, order)
    return {
        type = "select", order = order,
        name = function() return ns.TraitChoiceLabel(name) end,
        desc = function()
            if R.TRAITS[name].choice ~= "FEAT" then return ns.Glossary[R.TRAITS[name].of or name] end
            local lines = { ns.Glossary[name] or "" }
            for _, feat in ipairs(DraftTraitOptions(name)) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, feat, R.FEATS[feat].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function()
            for _, trait in ipairs(W.draft and ns.TraitChoices(W.draft) or {}) do
                if trait == name then return false end
            end
            return true
        end,
        values = function() return (Opt.ListMap(DraftTraitOptions(name))) end,
        sorting = function() return (select(2, Opt.ListMap(DraftTraitOptions(name)))) end,
        get = function() return W.draft.traitChoices[name] end,
        set = function(_, value)
            local choices, trait = W.draft.traitChoices, R.TRAITS[name]
            choices[name] = value
            -- The same tool picked for the other half of the trait: that one is asked again.
            local other = trait.more or trait.of
            if other and choices[other] == value then choices[other] = nil end
        end,
    }
end

W.DraftTraitPicker = DraftTraitPicker
