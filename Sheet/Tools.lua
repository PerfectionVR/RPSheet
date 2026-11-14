-- Tool proficiencies (data in Data/Tools.lua). A character is proficient with the
-- tools its class and background name, plus those ticked by hand in
-- sheet.tools[<name>] = true.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Where the proficiency with a tool comes from: "class", "background", "chosen", or nil.
function RPSheet:ToolSource(name)
    local sheet, class = self:Sheet(), self:ClassData()
    for _, tool in ipairs(class and R.CLASS_TOOLS[class.base] or {}) do
        if tool == name then return "class" end
    end
    if R.BACKGROUND_TOOLS[sheet.background] == name then return "background" end
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
