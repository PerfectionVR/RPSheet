-- The level dialog: what still has to be chosen before the level can be taken or the
-- choice saved.
local _, ns = ...
local R = ns.Rules
local Levels = ns.Levels
local L = ns.LevelDialog

function L.Problem()
    -- A class the character doesn't have yet has to be open to it.
    local block = L.draft.newClass and ns.MulticlassBlock(L.Sheet(), L.draft.class)
    if block then return ("You can't take a level of %s: %s."):format(L.DraftClass().name, block) end
    if #L.NewClassSkills() > 0 and L.draft.skill == "" then return "Choose the skill your new class gives you." end
    local featSkills = L.FeatSkillLimit()
    if featSkills > 0 and L.FeatSkillsPicked() ~= featSkills then
        return ("Choose %d skills or tools for your feats (%d chosen)."):format(featSkills, L.FeatSkillsPicked())
    end
    local expertise = L.ExpertiseLimit()
    if expertise > 0 and L.ExpertisePicked() ~= expertise then
        return ("Choose %d skills for expertise (%d chosen)."):format(expertise, L.ExpertisePicked())
    end
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit = L.PickLimit(key)
        if limit > 0 and L.PicksChosen(key) ~= limit then
            return ("Choose %d %s (%d chosen)."):format(limit, R.PICK_LISTS[key].title, L.PicksChosen(key))
        end
    end
    for _, feature in ipairs(L.OptionFeatures()) do
        if (L.draft.options[feature.name] or "") == "" then return ("Choose an option for %s."):format(feature.name) end
    end
    local limit = L.ManeuverLimit()
    if limit > 0 and L.ManeuversPicked() ~= limit then
        return ("Choose %d maneuvers (%d chosen)."):format(limit, L.ManeuversPicked())
    end
    for _, feature in ipairs(L.SkillFeatures()) do
        if (L.draft.featureSkills[feature] or "") == "" then return ("Choose a skill for %s."):format(feature) end
    end
    if L.AsksSubclass() and L.draft.taking and L.draft.subclass == "" then return "Choose a subclass: it is part of this level." end
    if L.StyleSlot() and L.draft.style == "" then return "Choose a Fighting Style: it is part of this level." end
    local problem = L.draft.kind and Levels.Problem(L.Sheet(), L.draft.level, L.draft.record)
    if problem then return problem end
    -- Last: the feat has to be settled before its own choices are.
    local _, store, instances, level = L.FeatChoiceContext()
    return (select(3, ns.FeatChoiceProgress(store, instances, level)))
end
