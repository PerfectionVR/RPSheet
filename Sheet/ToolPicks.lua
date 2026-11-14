-- The kind of artisan's tools picked for a feature in the level dialog (list in
-- Data/ToolPicks.lua): sheet.picks[<list>][<name>] = true. The pick is a tool
-- proficiency while the character has the feature (see RPSheet:ToolSource), so it
-- goes away by itself below the feature's level or with another subclass.
local _, ns = ...
local R = ns.Rules

local KEY = R.TOOL_PICK_LIST

-- "class" or "background" when one of those already names the tool, or nil.
function ns.ToolGranted(sheet, name)
    local class = R.CLASSES[sheet.class]
    for _, tool in ipairs(class and R.CLASS_TOOLS[class.base] or {}) do
        if tool == name then return "class" end
    end
    if R.BACKGROUND_TOOLS[sheet.background] == name then return "background" end
end

-- True if the tool is the one picked for a feature the character has.
function ns.ToolPicked(sheet, name)
    local picks = sheet.picks and sheet.picks[KEY]
    return picks ~= nil and picks[name] == true and R.PICK_LISTS[KEY].items[name] ~= nil
        and ns.PickLimit(KEY, sheet.class, sheet.level, sheet.subclass) > 0
end

-- A kind the character is proficient with from elsewhere can't be picked as well.
R.PICK_LISTS[KEY].blocked = function(sheet, name)
    if ns.ToolGranted(sheet, name) or (sheet.tools and sheet.tools[name]) then return "already proficient" end
end

-- Keeps the pick apart from the other sources of the same tool.
function ns.ApplyToolPicks(sheet)
    local picks = sheet.picks[KEY]
    if type(picks) ~= "table" or ns.PickLimit(KEY, sheet.class, sheet.level, sheet.subclass) == 0 then return end
    for name in pairs(picks) do
        if ns.ToolGranted(sheet, name) then
            -- The class or background gives it now: the pick is open again.
            picks[name] = nil
        else
            sheet.tools[name] = nil -- the pick stands in for a tick made by hand
        end
    end
end
