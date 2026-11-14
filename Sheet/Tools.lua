-- Tool proficiencies (data in Data/Tools.lua). A character is proficient with the
-- tools its class and background name, the kind picked for a feature in the level
-- dialog (Sheet/ToolPicks.lua), plus those ticked by hand in sheet.tools[<name>] = true.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Where the proficiency with a tool comes from: "class", "background", "feature" (picked
-- in the level dialog), "feat" (picked for a feat there), "chosen" (ticked by hand), or nil.
function RPSheet:ToolSource(name)
    local sheet = self:Sheet()
    local granted = ns.ToolGranted(sheet, name)
    if granted then return granted end
    if ns.ToolPicked(sheet, name) then return "feature" end
    if ns.FeatTool(sheet, name) then return "feat" end
    if sheet.tools[name] then return "chosen" end
end

-- The tools the character is proficient with, in the order of the data.
function RPSheet:Tools()
    local list = {}
    for _, name in ipairs(R.TOOL_ORDER) do
        if self:ToolSource(name) then list[#list + 1] = R.TOOLS[name] end
    end
    return list
end

-- A check with a tool the character is proficient with: the tool's usual ability,
-- the proficiency bonus, and what applies to every ability check.
function RPSheet:ToolMod(tool)
    return self:Mod(tool.stat) + self:ProficiencyBonus() + self:Bonus("CHECKS")
end
