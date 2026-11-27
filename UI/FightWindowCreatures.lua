-- The combat window's parts for creature templates (Integrations/FightStatBlocks.lua):
-- the list the owner adds a creature from, sorted into groups (Data/CreatureGroups.lua)
-- behind a strip of tabs, and on such a creature's turn its attacks and the saves it
-- forces.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local F = ns.Fight

local SHOWN = 40 -- creatures at a time when a typed name narrows the whole list

local function AddCreature(body, name)
    local template = R.CREATURES[name]
    UI.AddButton(body, 0.5, ("%s  %sCR %s|r"):format(name, UI.GREY, template.cr), function() F.AddCreature(name) end, name,
        ("AC %d, %d hit points.\n%s\n\nClick to put one into the fight. Click again for another: they are numbered."):format(
            template.ac, template.hp, F.CreatureSummary(template)), "row")
end

-- The list to add from, in place of the rest of the window. Returns true when shown.
function UI.AddCreaturePicker(self, body)
    if not F.picking or not F.IsOwner() then
        F.picking = nil
        return false
    end
    local filter = F.pickFilter or ""
    UI.AddHeading(body, "Add a creature")
    UI.AddButton(body, 0.5, "Back to the fight", function()
        F.picking = nil
        F.Changed()
    end, "Back", "Closes the list.", "picked")
    UI.AddButton(body, 0.5, ("Name has: %s"):format(filter ~= "" and filter or "anything"), function()
        ns.AskFightText("Show the creatures whose name has", filter, function(text)
            F.pickFilter = text
            F.Changed()
        end)
    end, "Filter", "Type part of a name to look through every group at once.", filter ~= "" and "picked" or "on")
    -- who is in the fight already
    local there = {}
    for _, key in ipairs(F.Roster()) do
        local member = F.session.members[key]
        if member.npc then there[#there + 1] = member.name end
    end
    if #there > 0 then UI.AddLabel(body, 1, ("%sIn the fight: %s|r"):format(UI.GREY, table.concat(there, ", "))) end

    if filter ~= "" then
        local names = F.CreatureMatches(filter)
        UI.AddButton(body, 0.5, "Show all of them", function()
            F.pickFilter = nil
            F.Changed()
        end, "Show all", "Takes the typed name off and goes back to the groups.")
        UI.AddLabel(body, 1, #names == 0 and (UI.GREY .. "No creature's name has that in it.|r") or ("%d with that in their name:"):format(#names))
        for index, name in ipairs(names) do
            if index > SHOWN then
                UI.AddLabel(body, 1, ("%s%d more: type more of the name.|r"):format(UI.GREY, #names - SHOWN))
                break
            end
            AddCreature(body, name)
        end
        return true
    end

    -- sorted: a tab for each way of sorting, a button for each group, then the group
    local by, tabs = F.pickBy, {}
    for _, grouping in ipairs(R.CREATURE_GROUPINGS) do
        tabs[#tabs + 1] = { name = grouping.name, tip = grouping.tip, key = grouping.key }
        by = by or grouping.key
    end
    local open
    for _, tab in ipairs(tabs) do
        if tab.key == by then open = tab.name end
    end
    UI.AddLabel(body, 1, " ")
    UI.AddTabStrip(body, tabs, open, function(name)
        for _, tab in ipairs(tabs) do
            if tab.name == name then F.pickBy, F.pickGroup = tab.key, nil end
        end
        F.Changed()
    end)
    local groups = R.CreatureGroups(by)
    local picked = groups[1]
    for _, group in ipairs(groups) do
        if group.name == F.pickGroup then picked = group end
    end
    for _, group in ipairs(groups) do
        UI.AddButton(body, #groups > 4 and 0.333 or 0.5, ("%s  %s%d|r"):format(group.name, UI.GREY, #group.list), function()
            F.pickGroup = group.name
            F.Changed()
        end, group.name, ("%d creatures."):format(#group.list), group == picked and "picked" or "on")
    end
    UI.AddHeading(body, picked.name)
    for _, name in ipairs(picked.list) do AddCreature(body, name) end
    return true
end

-- On the turn of a creature made from a template: what it can roll.
function UI.AddCreatureTurn(body, member)
    local template = F.Template(member)
    if not template then return false end
    local targetKey = F.CreatureTarget(F.session.turn)
    local target = targetKey and F.session.members[targetKey]
    UI.AddLabel(body, 1, ("%s%s|r %s%s%s|r"):format(UI.ACCENT, member.name, UI.GREY,
        target and ("at " .. target.name) or "at no one: click a health bar above to aim",
        template.multi and ". It attacks more than once a turn" or ""), nil, member.name, F.CreatureSummary(template))
    for index, attack in ipairs(template.attacks) do
        UI.AddButton(body, 1, ("%s  %s%+d to hit%s|r"):format(attack.name, UI.GREY, attack.hit,
            #attack.parts > 0 and (", " .. R.DamagePartsText(attack.parts)) or ""), function() F.CreatureStrike(index) end, attack.name,
            "Your game rolls the attack. It is held against the picked combatant's Armor Class, and on a hit the damage is rolled and they take it: a player on their own sheet, with their resistances. A natural 20 doubles the dice. With only one opponent in the fight it is aimed at them without a click; with no one to aim at, the roll and its damage are only announced.")
    end
    for index, force in ipairs(template.forces) do
        UI.AddButton(body, 1, ("%s  %s%s save, DC %d%s|r"):format(force.name, UI.GREY, force.stat, force.dc,
            #force.parts > 0 and (", " .. R.DamagePartsText(force.parts)) or ""), function() F.CreatureForce(index) end, force.name,
            ("The picked combatant makes a %s saving throw against DC %d: a player on their own sheet, one of yours by your game.%s Click once for each combatant it catches: the damage is rolled once a turn."):format(
                R.STAT_NAMES[force.stat], force.dc,
                #force.parts > 0 and (force.half and " On a failure they take the damage, on a success half of it." or " On a failure they take the damage.") or " What a failure does is yours to say."))
    end
    return true
end
