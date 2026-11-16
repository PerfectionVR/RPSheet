-- The tools picked in the level dialog (lists in Data/ToolPicks.lua): a Battle
-- Master's artisan's tools, a Monk's artisan's tools or instrument.
-- sheet.picks[<list>][<name>] = true. A pick is a tool proficiency while the list
-- is the character's (see RPSheet:ToolSource), so it goes away by itself below the
-- feature's level, with another subclass or with another class.
local _, ns = ...
local R = ns.Rules

local LISTS = R.TOOL_PICK_LISTS

-- "class" or "background" when one of those already names the tool, or nil.
function ns.ToolGranted(sheet, name)
    sheet = sheet.viewOf or sheet -- the whole character, when asked about one class of it
    local class = R.CLASSES[sheet.class]
    for _, tool in ipairs(class and R.CLASS_TOOLS[class.base] or {}) do
        if tool == name then return "class" end
    end
    -- A class taken after the first brings only the tools named for that (Data/Multiclass.lua).
    for _, key in ipairs(ns.ExtraClassKeys(sheet)) do
        local gained = R.MULTICLASS[R.CLASSES[key].base]
        for _, tool in ipairs(gained and gained.tools or {}) do
            if tool == name then return "class" end
        end
    end
    if R.BACKGROUND_TOOLS[sheet.background] == name then return "background" end
    -- A class or subclass feature that names it (Assassin's Tools, Implements of Mercy).
    for _, passive in ipairs(sheet.passives or {}) do
        for _, tool in ipairs((passive.auto or "") ~= "" and passive.tools or {}) do
            if tool == name then return "class" end
        end
    end
end

-- True if the tool is picked in one list (a key) the character has.
local function PickedIn(sheet, key, name)
    local picks = sheet.picks and sheet.picks[key]
    return type(picks) == "table" and picks[name] == true and R.PICK_LISTS[key].items[name] ~= nil
        and ns.SheetPickLimit(sheet, key) > 0
end

-- True if the tool is one picked in the level dialog, for a feature or for the class.
function ns.ToolPicked(sheet, name)
    for _, key in ipairs(LISTS) do
        if PickedIn(sheet, key, name) then return true end
    end
    return false
end

-- True if the character is proficient with a tool, wherever that comes from: what
-- RPSheet:ToolSource says of the active character, for any sheet.
function ns.SheetToolProficient(sheet, name)
    return ns.ToolGranted(sheet, name) ~= nil or ns.ToolPicked(sheet, name) or ns.FeatTool(sheet, name)
        or ns.FeatToolPicked(sheet, name) or ns.RenownTool(sheet, name) or ns.TraitTool(sheet, name)
        or (sheet.tools ~= nil and sheet.tools[name] == true)
end

-- A kind the character is proficient with from elsewhere can't be picked as well.
for _, key in ipairs(LISTS) do
    R.PICK_LISTS[key].blocked = function(sheet, name)
        if ns.ToolGranted(sheet, name) or (sheet.tools and sheet.tools[name]) then return "already proficient" end
        local whole = sheet.viewOf or sheet -- the other list may be another class's
        for _, other in ipairs(LISTS) do
            if other ~= key and PickedIn(whole, other, name) then return "already proficient" end
        end
        if ns.FeatTool(sheet, name) or ns.FeatToolPicked(sheet, name) or ns.RenownTool(sheet, name) or ns.TraitTool(whole, name) then return "already proficient" end
    end
end

-- A Monk made before its tool was a pick ticked it by hand under Customize (or chose
-- it with the starting gear): the first such tick becomes the pick, so nothing is
-- asked again.
local function AdoptTick(sheet, key)
    local list, picks = R.PICK_LISTS[key], sheet.picks[key]
    if not list.firstClass or next(picks) ~= nil then return end
    for _, name in ipairs(list.order) do
        if sheet.tools[name] and not ns.ToolGranted(sheet, name) then
            picks[name] = true
            return
        end
    end
end

-- Keeps the picks apart from the other sources of the same tool.
function ns.ApplyToolPicks(sheet)
    for _, key in ipairs(LISTS) do
        if ns.SheetPickLimit(sheet, key) > 0 then
            if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
            AdoptTick(sheet, key)
            for name in pairs(sheet.picks[key]) do
                if ns.ToolGranted(sheet, name) then
                    -- The class or background gives it now: the pick is open again.
                    sheet.picks[key][name] = nil
                else
                    sheet.tools[name] = nil -- the pick stands in for a tick made by hand
                end
            end
        end
    end
end
