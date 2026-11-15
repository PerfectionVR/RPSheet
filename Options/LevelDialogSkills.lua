-- The level dialog: skills and tools from feats, and expertise.
local _, ns = ...
local R = ns.Rules
local L = ns.LevelDialog
local args = L.args

-- Skills from feats: one checkbox per skill the character isn't proficient in yet.
args.featSkills = {
    type = "group", inline = true, order = 13.4, args = {},
    name = function()
        local title = L.draft and ns.FeatToolLimit(L.Sheet()) > 0 and "Skills and tools from your feats" or "Skills from your feats"
        return ("%s (%d of %d chosen)"):format(title, L.draft and L.FeatSkillsPicked() or 0, L.FeatSkillLimit())
    end,
    hidden = function() return L.FeatSkillLimit() == 0 end,
}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    args.featSkills.args["skill" .. index] = {
        type = "toggle", order = index, width = 1, name = name,
        desc = "Proficiency in this skill, from a feat such as Skilled or Skill Expert.",
        hidden = function()
            local sheet = L.Sheet()
            -- Shown when picked, or when the skill isn't proficient from somewhere else.
            return not L.draft.featSkills[name] and (sheet.skills[name] or 0) > 0 and not sheet.featSkillGranted[name]
        end,
        disabled = function() return not L.draft.featSkills[name] and L.FeatSkillsPicked() >= L.FeatSkillLimit() end,
        get = function() return L.draft.featSkills[name] or false end,
        set = function(_, value) L.draft.featSkills[name] = value or nil end,
    }
end

-- A feat that offers skills or tools (Skilled) lists the tools under the skills: the
-- ones the character isn't proficient with from somewhere else.
args.featSkills.args.toolHead = {
    type = "header", order = 100, name = "Or tools",
    hidden = function() return not L.draft or ns.FeatToolLimit(L.Sheet()) == 0 end,
}
for index, name in ipairs(R.TOOL_ORDER) do
    args.featSkills.args["tool" .. index] = {
        type = "toggle", order = 100 + index, width = 1, name = name,
        desc = ("Proficiency with this tool in place of a skill, from the Skilled feat. %s; checks with it normally use %s."):format(
            R.TOOL_KINDS[R.TOOLS[name].kind] or "Tool", R.STAT_NAMES[R.TOOLS[name].stat] or "an ability"),
        hidden = function()
            if not L.draft or ns.FeatToolLimit(L.Sheet()) == 0 then return true end
            return not L.draft.featTools[name] and ns.FeatToolTaken(L.Sheet(), name)
        end,
        disabled = function()
            if L.draft.featTools[name] then return false end
            return L.FeatSkillsPicked() >= L.FeatSkillLimit() or L.FeatToolsPicked() >= ns.FeatToolLimit(L.Sheet())
        end,
        get = function() return L.draft.featTools[name] or false end,
        set = function(_, value) L.draft.featTools[name] = value or nil end,
    }
end

-- Expertise: one checkbox per skill the character is proficient in.
args.expertise = {
    type = "group", inline = true, order = 13.5, args = {},
    name = function() return ("Expertise (%d of %d chosen)"):format(L.draft and L.ExpertisePicked() or 0, (L.ExpertiseLimit())) end,
    hidden = function() return L.ExpertiseLimit() == 0 end,
}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    args.expertise.args["skill" .. index] = {
        type = "toggle", order = index, width = 1, name = name,
        desc = "Your proficiency bonus is added twice for this skill. Only skills you are proficient in can be picked.",
        hidden = function()
            local _, allowed = L.ExpertiseLimit()
            return (allowed ~= nil and not allowed[name]) or (not L.draft.expertise[name] and (L.Sheet().skills[name] or 0) == 0)
        end,
        disabled = function() return not L.draft.expertise[name] and L.ExpertisePicked() >= L.ExpertiseLimit() end,
        get = function() return L.draft.expertise[name] or false end,
        set = function(_, value) L.draft.expertise[name] = value or nil end,
    }
end
