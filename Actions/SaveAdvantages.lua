-- Asking what a saving throw is against. Some advantages only count against one thing
-- (being charmed, a spell), which the sheet can't know. So when a save is rolled by a
-- character that has such an advantage, a small menu lists what it has and rolls with
-- advantage when the player picks one. Rolling with advantage already skips the menu.
local _, ns = ...
local RPSheet = ns.addon

-- Opens the menu for the save and returns true; false when there is nothing to ask,
-- and the roll goes on as it is (RPSheet:RollCheck in Actions/Dice.lua).
function RPSheet:AskSaveAbout(label, mod, mode)
    if mode == "ADV" then return false end
    local _, asked = self:SaveAdvantages(label)
    if #asked == 0 or self:ResolveMode(label, mode) == "ADV" then return false end
    -- One line for each thing a save can be against, with everything that gives it.
    local order, sources = {}, {}
    for _, entry in ipairs(asked) do
        if not sources[entry.about] then
            sources[entry.about] = {}
            order[#order + 1] = entry.about
        end
        table.insert(sources[entry.about], entry.from)
    end
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        local parts = {}
        for _, about in ipairs(order) do parts[#parts + 1] = ("%s (%s)"):format(about, table.concat(sources[about], ", ")) end
        self:Print(("You have advantage on this save if it is against %s: Shift-click to roll it that way."):format(table.concat(parts, "; ")))
        return false
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(("%s: what is it against?"):format(label))
        for _, about in ipairs(order) do
            local from = table.concat(sources[about], ", ")
            local button = root:CreateButton(("Against %s |cff909090(advantage)|r"):format(about),
                function() self:RollCheck(label, mod, mode, about) end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, "Advantage")
                GameTooltip_AddNormalLine(tooltip, ("From %s. Disadvantage from anything else cancels it out."):format(from), true)
            end)
        end
        root:CreateButton("Something else", function() self:RollCheck(label, mod, mode, false) end)
    end)
    return true
end
