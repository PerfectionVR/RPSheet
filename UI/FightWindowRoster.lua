-- The combat window's top: who is in the fight, in initiative order, each with a
-- health bar that is clicked to pick them; the fight's log (Integrations/FightLog.lua);
-- and this character's own line: hit points, Armor Class, and what is left of its turn.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight

local RED = "|cffff5555"

function UI.AddFightRoster(self, body, session)
    local target = F.joined and F.Target()
    for _, key in ipairs(F.Roster()) do
        local member = session.members[key]
        local init = member.init and ("%d"):format(member.init) or "-"
        local down = member.hp <= 0
        local name = member.name
        if key == target then name = RED .. name .. "|r" elseif down then name = UI.GREY .. name .. "|r" end
        local notes = { "init " .. init, "AC " .. member.ac }
        if key == target then notes[#notes + 1] = RED .. "target|r" .. UI.GREY end
        if down then notes[#notes + 1] = "down" end
        UI.AddLabel(body, 0.56, ("%s%s%s  %s%s|r"):format(session.turn == key and (UI.MARK .. "> |r") or "", F.MarkIcon(member.mark), name,
            UI.GREY, table.concat(notes, ", ")), nil, member.name,
            ("Initiative %s, Armor Class %d, %d of %d hit points.%s%s"):format(member.init and init or "not rolled yet", member.ac, member.hp, member.max,
                member.npc and "\nRun by the session's owner." or "", session.turn == key and "\nIt is their turn." or ""))
        local bar = UI.AddBar(body, UI.HealthColor(member.hp, member.max), function()
            F.target = F.target ~= key and key or nil
            F.Changed()
        end, member.name, ("Click to pick %s: your attacks are aimed at them, as with the target buttons of your combat window. Click again to pick no one.%s"):format(
            member.name, F.IsOwner() and "\nAs the session's owner you also pick here who a saving throw, damage or healing is for, and who a creature of yours attacks." or ""))
        bar:SetRelativeWidth(0.43)
        bar:SetValue(member.hp, member.max)
        bar:SetText(("%d/%d"):format(member.hp, member.max))
    end
end

-- The log, in a part of its own that scrolls: every line this client has, the last
-- one at the bottom. One piece of text, so a long fight is still one row.
function UI.AddFightLog(self, body)
    local lines = F.LogLines()
    if #lines == 0 then return end
    local shown = {}
    for index, line in ipairs(lines) do shown[index] = F.LogText(line) end
    UI.AddLabel(body, 1, table.concat(shown, "\n"))
end

local FREE, USED = { 0.18, 0.75, 0.18 }, { 0.35, 0.35, 0.35 }

local function Slot(name, used)
    local color = used and USED or FREE
    return ("%s %s%s|r"):format(UI.Pip(color[1], color[2], color[3]), used and UI.GREY or "", name)
end

-- This character's own line, under the roster.
function UI.AddFightStatus(self, body)
    local me = F.Mine()
    if not me then return end
    local text = ("HP %d/%d  AC %d"):format(me.hp, me.max, me.ac)
    if F.Running() then
        local used = F.used
        text = ("%s    %s  %s  %s"):format(text, Slot("Action", used.action and (used.attacks or 0) <= 0), Slot("Bonus", used.bonus),
            Slot("Reaction", RPSheet:State().reactionUsed))
    end
    UI.AddLabel(body, 1, text, nil, "Your turn", F.Running()
        and ("%s.\nA turn is one action, one bonus action when something gives you one, and your movement. Your reaction comes back when your turn starts and can be used on anyone's turn. Only one spell a turn can spend a spell slot."):format(
            (F.TurnText():gsub("^%l", string.upper)))
        or "Your hit points and Armor Class as the session has them.")
end
