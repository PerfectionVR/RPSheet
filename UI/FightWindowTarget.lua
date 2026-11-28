-- The combat window's target row, above the tabs: one button for everyone else in the
-- fight. The one that is picked is who this character's attacks are aimed at, so the
-- session can say whether an attack roll hits (Integrations/FightGate.lua, F.Target).
-- An attack that is clicked with no one picked first asks here who it is for.
local _, ns = ...
local UI = ns.UI
local F = ns.Fight

-- Everyone in the fight but this character, in the order of the roster.
function F.Others()
    local list, me = {}, F.Me()
    for _, key in ipairs(F.Roster()) do
        if key ~= me then list[#list + 1] = key end
    end
    return list
end

-- Who this character's attacks are aimed at: never itself.
local function Aimed()
    local key = F.Target()
    return key ~= F.Me() and key or nil
end

-- Runs an action of the combat window (Integrations/FightActions.lua). An attack with
-- no target is held until one is picked in the target row.
function F.Act(entry)
    if entry.section == "Attack" and not Aimed() and #F.Others() > 0 then
        F.aiming = { name = entry.name, run = entry.run }
        F.Changed()
        return
    end
    F.aiming = nil
    entry.run()
end

-- The attack that waited for a target goes on, at `key` or at no one in the fight.
local function Loose(key)
    local held = F.aiming
    F.aiming = nil
    F.target = key
    if held then held.run() end
    F.Changed()
end

function UI.AddFightTarget(self, body, session)
    if not F.Running() then
        F.aiming = nil
        return
    end
    local others = F.Others()
    if #others == 0 then
        F.aiming = nil
        return
    end
    local aimed, held = Aimed(), F.aiming
    if held then
        UI.AddLabel(body, 1, ("%sWho is %s for?|r"):format(UI.MARK, held.name))
    else
        UI.AddLabel(body, 1, aimed and ("Target: %s%s|r"):format(UI.ACCENT, session.members[aimed].name)
            or (UI.GREY .. "Target: no one. Pick who your attacks are for.|r"), nil, "Target",
            "Your attacks are aimed at whoever is picked here, and the session says whether an attack roll hits. With no one picked an attack asks first.")
    end
    local width = #others == 1 and 1 or (#others == 2 and 0.5 or 0.333)
    for _, key in ipairs(others) do
        local member = session.members[key]
        local text = F.MarkIcon(member.mark) .. member.name .. (member.hp <= 0 and (UI.GREY .. " (down)|r") or "")
        UI.AddButton(body, width, text, function()
            if F.aiming then
                Loose(key)
            else
                F.target = aimed ~= key and key or nil
                F.Changed()
            end
        end, member.name, held and ("%s is aimed at %s."):format(held.name, member.name)
            or ("Aim your attacks at %s. Click again to aim at no one."):format(member.name), key == aimed and "picked" or "on")
    end
    if held then
        UI.AddButton(body, 0.5, "No one in the fight", function() Loose(nil) end, "No one in the fight",
            ("%s is rolled without a target: the session doesn't say whether it hits."):format(held.name))
        UI.AddButton(body, 0.5, "Call it off", function()
            F.aiming = nil
            F.Changed()
        end, "Call it off", "Nothing is rolled and nothing is spent.")
    end
end
