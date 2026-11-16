-- Wizard step 1, the class's skills: one checkbox per skill the class offers.
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard
local DraftClass = W.DraftClass

-- One checkbox per skill, shown for the skills the class offers. Once the class's
-- number of skills is picked the rest grey out, until one is unticked.
local skillArgs = {}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    local function Offered()
        for _, offered in ipairs(DraftClass() and DraftClass().skills or {}) do
            if offered == name then return true end
        end
        return false
    end
    skillArgs["skill" .. index] = {
        -- 1.5 units (255px) fits two per row in this window.
        type = "toggle", order = index, width = 1.5, name = name, desc = ns.Glossary[name],
        hidden = function() return not Offered() end,
        disabled = function()
            if W.draft.classSkills[name] then return false end
            -- Already given by the background, when one was chosen before coming back here.
            local background = R.BACKGROUNDS[W.draft.background]
            for _, skill in ipairs(background and background.skills or {}) do
                if skill == name then return true end
            end
            return W.SkillsPicked() >= DraftClass().skillCount
        end,
        get = function() return W.draft.classSkills[name] or false end,
        set = function(_, value) W.draft.classSkills[name] = value or nil end,
    }
end

W.classSkillArgs = skillArgs
