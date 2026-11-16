-- The sheet's skills and tool proficiencies, each a check to click; a right-click
-- shows how the number is worked out (UI.AddRollLabel).
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

function UI.SkillSection(self, body)
    local ranks = self:Sheet().skills
    UI.AddHeading(body, "Skills")
    for _, skill in ipairs(R.SKILLS) do
        local mod = self:SkillMod(skill)
        local rank = ranks[skill.name] or 0
        local name = rank > 0 and (UI.ACCENT .. skill.name .. (rank > 1 and "*" or "") .. "|r") or skill.name
        UI.AddRollLabel(body, 0.5, ("%s %s%s|r"):format(name, UI.GREY, Signed(mod)),
            function() self:RollCheck(skill.name, mod, ns.RollMode()) end,
            skill.name,
            function()
                return ("%s\n\n%s (%s), %s\n\n%s"):format(
                    ns.Glossary[skill.name], R.STAT_NAMES[skill.stat], Signed(mod), R.PROFICIENCY_NAMES[rank]:lower(), ns.ROLL_MODE_HELP)
            end,
            function() self:ExplainSkill(skill) end)
    end
end

-- The tools the character is proficient with, each a check to click.
function UI.ToolSection(self, body)
    local tools = self:Tools()
    if #tools == 0 then return end
    UI.AddHeading(body, "Tools")
    for _, tool in ipairs(tools) do
        local mod = self:ToolMod(tool)
        UI.AddRollLabel(body, 0.5, ("%s%s|r %s%s|r"):format(UI.ACCENT, tool.name, UI.GREY, Signed(mod)),
            function() self:RollCheck(tool.name, mod, ns.RollMode()) end,
            tool.name,
            function()
                return ("%s. A check with it uses %s and your proficiency bonus (%s). The DM can ask for another ability.\n\n%s"):format(
                    R.TOOL_KINDS[tool.kind], R.STAT_NAMES[tool.stat], Signed(mod), ns.ROLL_MODE_HELP)
            end,
            function() self:ExplainTool(tool) end)
    end
end
