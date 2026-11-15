-- A kind of artisan's tools a feature lets the character choose, as a pick list for
-- the level dialog (see Data/Picks.lua for the form): a Battle Master's Student of War.
-- `subclass` keeps the list to that subclass. It is `custom`: the pick is a tool
-- proficiency, not an ability, and Sheet/ToolPicks.lua grants it.
local _, ns = ...
local R = ns.Rules

local items, order = {}, {}
for _, name in ipairs(R.TOOL_ORDER) do
    local tool = R.TOOLS[name]
    if tool.kind == "AT" then
        items[name] = { desc = ("Proficiency with this kind of artisan's tools. A check with it uses %s."):format(R.STAT_NAMES[tool.stat]) }
        order[#order + 1] = name
    end
end

-- The key of the list, for the files that grant the pick.
R.TOOL_PICK_LIST = "studentTools"

-- A kind the character is already proficient with is greyed out (Sheet/ToolPicks.lua).
R.PICK_LISTS[R.TOOL_PICK_LIST] = {
    title = "Artisan's tools for Student of War", base = "Fighter", subclass = "Battle Master",
    custom = true,
    known = { { 3, 1 } },
    items = items, order = order,
}
R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = R.TOOL_PICK_LIST
