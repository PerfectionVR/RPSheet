-- Tools the character chooses, as pick lists for the level dialog (see Data/Picks.lua
-- for the form):
--   studentTools  a kind of artisan's tools for a Battle Master's Student of War
--                 (`subclass` keeps the list to that subclass)
--   monkTools     the kind of artisan's tools or the musical instrument a Monk is
--                 trained with from its first level. `firstClass`: a class taken
--                 after the first doesn't bring it (Sheet/ClassViews.lua).
-- They are `custom`: a pick is a tool proficiency, not an ability, and
-- Sheet/ToolPicks.lua grants it.
local _, ns = ...
local R = ns.Rules

-- The tools of the given kinds as a list's items and order.
local function Tools(kinds, what)
    local items, order = {}, {}
    for _, name in ipairs(R.TOOL_ORDER) do
        local tool = R.TOOLS[name]
        if kinds[tool.kind] then
            items[name] = { desc = ("Proficiency with this %s. A check with it uses %s."):format(what[tool.kind], R.STAT_NAMES[tool.stat]) }
            order[#order + 1] = name
        end
    end
    return items, order
end
local WHAT = { AT = "kind of artisan's tools", INS = "musical instrument" }

-- The keys of the lists, for the files that grant the picks.
R.TOOL_PICK_LIST = "studentTools"
R.MONK_TOOL_LIST = "monkTools"
R.TOOL_PICK_LISTS = { R.TOOL_PICK_LIST, R.MONK_TOOL_LIST }

-- A kind the character is already proficient with is greyed out (Sheet/ToolPicks.lua).
local items, order = Tools({ AT = true }, WHAT)
R.PICK_LISTS[R.TOOL_PICK_LIST] = {
    title = "Artisan's tools for Student of War", base = "Fighter", subclass = "Battle Master",
    custom = true, what = "kind of tools",
    known = { { 3, 1 } },
    items = items, order = order,
}
items, order = Tools({ AT = true, INS = true }, WHAT)
R.PICK_LISTS[R.MONK_TOOL_LIST] = {
    title = "Monk's tool: artisan's tools or an instrument", base = "Monk", firstClass = true,
    custom = true, what = "tool",
    known = { { 1, 1 } },
    items = items, order = order,
}
for _, key in ipairs(R.TOOL_PICK_LISTS) do R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = key end
