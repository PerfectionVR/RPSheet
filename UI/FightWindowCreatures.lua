-- The combat window's rows for creature templates (Integrations/FightStatBlocks.lua):
-- the list the owner adds a creature from, and on such a creature's turn its attacks
-- and the saves it forces.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local F = ns.Fight

local SHOWN = 40 -- rows of the list at a time; the filter narrows it

-- The list to add from, in place of the rest of the window. Returns true when shown.
function UI.AddCreaturePicker(self, body)
    if not F.picking or not F.IsOwner() then
        F.picking = nil
        return false
    end
    local filter = F.pickFilter or ""
    local names = F.CreatureMatches(filter)
    UI.AddHeading(body, "Add a creature")
    UI.AddLabel(body, 1, UI.ACCENT .. "Back to the fight|r", function()
        F.picking = nil
        F.Changed()
    end, "Back", "Closes the list.")
    UI.AddLabel(body, 1, ("Name has: %s%s|r"):format(UI.ACCENT, filter ~= "" and filter or "anything"), function()
        ns.AskFightText("Show the creatures whose name has", filter, function(text)
            F.pickFilter = text
            F.Changed()
        end)
    end, "Filter", "Type part of a name to narrow the list.")
    if filter ~= "" then
        UI.AddLabel(body, 1, UI.ACCENT .. "Show all of them|r", function()
            F.pickFilter = nil
            F.Changed()
        end, "Show all", "Takes the filter off.")
    end
    if #names == 0 then UI.AddLabel(body, 1, UI.GREY .. "No creature's name has that in it.|r") end
    for index, name in ipairs(names) do
        if index > SHOWN then
            UI.AddLabel(body, 1, ("%s%d more: narrow the list with the filter.|r"):format(UI.GREY, #names - SHOWN))
            break
        end
        local template = R.CREATURES[name]
        UI.AddLabel(body, 1, ("%s  %sCR %s  AC %d  HP %d|r"):format(name, UI.GREY, template.cr, template.ac, template.hp), function()
            F.AddCreature(name)
        end, name, F.CreatureSummary(template) .. "\n\nClick to put one into the fight. Click again for another: they are numbered.")
    end
    return true
end

-- On the turn of a creature made from a template: what it can roll.
function UI.AddCreatureTurn(body, member)
    local template = F.Template(member)
    if not template then return false end
    local target = F.target and F.session.members[F.target]
    local at = target and target ~= member and (" at " .. target.name) or ""
    UI.AddLabel(body, 1, ("%s%s|r%s"):format(UI.ACCENT, member.name, template.multi and (UI.GREY .. "  attacks more than once a turn|r") or ""), nil,
        member.name, F.CreatureSummary(template))
    for index, attack in ipairs(template.attacks) do
        UI.AddLabel(body, 1, ("%s%s|r  %s%+d%s%s|r"):format(UI.ACCENT, attack.name, UI.GREY, attack.hit,
            #attack.parts > 0 and (", " .. R.DamagePartsText(attack.parts)) or "", at), function() F.CreatureStrike(index) end, attack.name,
            "Your game rolls the attack. With a combatant's row picked it is held against their Armor Class, and on a hit the damage is rolled and they take it: a player on their own sheet, with their resistances. A natural 20 doubles the dice. With no row picked, the roll and its damage are only announced.")
    end
    for index, force in ipairs(template.forces) do
        UI.AddLabel(body, 1, ("%s%s|r  %s%s save, DC %d%s%s|r"):format(UI.ACCENT, force.name, UI.GREY, force.stat, force.dc,
            #force.parts > 0 and (", " .. R.DamagePartsText(force.parts)) or "", at), function() F.CreatureForce(index) end, force.name,
            ("The picked combatant makes a %s saving throw against DC %d: a player on their own sheet, one of yours by your game.%s Click once for each combatant it catches: the damage is rolled once a turn."):format(
                R.STAT_NAMES[force.stat], force.dc,
                #force.parts > 0 and (force.half and " On a failure they take the damage, on a success half of it." or " On a failure they take the damage.") or " What a failure does is yours to say."))
    end
    return true
end
