-- Tools picked in place of skills for a feat that offers either (Skilled):
-- sheet.featTools[<tool>] = true. They come out of the same picks as the feat's
-- skills (sheet.featSkills, Sheet/Expertise.lua): skills and tools together make up
-- ns.FeatSkillLimit, and no more of them are tools than the feats allow.
-- The pick itself is the proficiency (see RPSheet:ToolSource).
local _, ns = ...
local R = ns.Rules

-- How many of the feats' skill picks may be tools. A feat taken twice counts twice.
function ns.FeatToolLimit(sheet)
    local total = 0
    for _, passive in ipairs(sheet.passives or {}) do
        local feat = R.FEATS[passive.name]
        if feat and feat.toolPicks then total = total + feat.toolPicks end
    end
    return total
end

function ns.FeatToolsKnown(sheet)
    local count = 0
    for name in pairs(sheet.featTools or {}) do
        if R.TOOLS[name] then count = count + 1 end
    end
    return count
end

-- True if the tool is one picked for such a feat.
function ns.FeatToolPicked(sheet, name)
    return type(sheet.featTools) == "table" and sheet.featTools[name] == true
        and R.TOOLS[name] ~= nil and ns.FeatToolLimit(sheet) > 0
end

-- True if the character is proficient with the tool from somewhere else already, so
-- picking it would give nothing. A tick made by hand doesn't count: the pick replaces it.
function ns.FeatToolTaken(sheet, name)
    return ns.ToolGranted(sheet, name) ~= nil or ns.ToolPicked(sheet, name) or ns.FeatTool(sheet, name)
        or ns.RenownTool(sheet, name) == true
end

-- Sheet upkeep (see Sheet/ClassFeatures.lua): drops the picks no feat allows any more
-- and those another source gives now, so the level dialog asks again.
function ns.ApplyFeatTools(sheet)
    if type(sheet.featTools) ~= "table" then sheet.featTools = {} end
    if ns.FeatToolLimit(sheet) == 0 then wipe(sheet.featTools) end
    for name in pairs(sheet.featTools) do
        if not R.TOOLS[name] or ns.FeatToolTaken(sheet, name) then
            sheet.featTools[name] = nil
        else
            sheet.tools[name] = nil -- the pick stands in for a tick made by hand
        end
    end
end
