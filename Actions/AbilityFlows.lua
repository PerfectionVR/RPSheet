-- Class features that ask something before they are used: how many points of a pool,
-- which rune, whether a use is free. A flow is found by the ability's name in
-- ns.ABILITY_FLOWS (filled by the files after this one). It asks with a menu or a box,
-- then uses a copy of the ability with the steps the answer gives; the copy carries
-- `asked`, so it goes straight through.
local _, ns = ...

ns.ABILITY_FLOWS = {}

-- Called first by RPSheet:UseAbility: true when a flow took the click over.
function ns.AbilityFlow(self, ability, mode)
    if ability.asked or (ability.auto or "") == "" then return false end -- the player's own abilities are left alone
    local flow = ns.ABILITY_FLOWS[ability.name]
    if not flow then return false end
    return flow(self, ability, mode) == true
end

-- Uses a copy of `ability` with other steps; `extra` fields are put on the copy.
function ns.UseAsked(self, ability, mode, actions, extra)
    local copy = { asked = true, actions = actions }
    for key, value in pairs(extra or {}) do copy[key] = value end
    self:UseAbility(setmetatable(copy, { __index = ability }), mode)
end

-- A menu at the cursor: `choices` is a list of { text, function }. Without the game's
-- menus the first choice is taken.
function ns.FlowMenu(title, choices)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return choices[1][2]() end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(title)
        for _, choice in ipairs(choices) do root:CreateButton(choice[1], choice[2]) end
    end)
end

-- True if a switched-on passive of that name is on the sheet.
function ns.PassiveOn(sheet, name)
    for _, passive in ipairs(sheet.passives or {}) do
        if passive.enabled and passive.name == name then return true end
    end
    return false
end
