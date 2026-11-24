-- The combat window while turns are taken: whose turn it is, what this character has
-- used of its turn, and what it can do now (Integrations/FightActions.lua). Something
-- the character has but can't use at the moment is grey, and its tooltip and a click
-- say why.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight

local RED = "|cffff5555"

local function AddAction(self, body, entry)
    local cost = entry.costLabel and (" (%s)"):format(entry.costLabel) or ""
    local info = entry.info ~= "" and ("  " .. entry.info) or ""
    if entry.why then
        UI.AddLabel(body, 1, ("%s%s%s%s|r"):format(UI.GREY, entry.name, cost, info), function()
            self:Print(("%s: %s"):format(entry.name, entry.why))
        end, entry.name, ("%sNot now: %s|r\n\n%s"):format(RED, entry.why, entry.tip or ""))
    else
        UI.AddLabel(body, 1, ("%s%s%s%s|r"):format(entry.name, UI.GREY, cost, info), function() entry.run() end,
            entry.name, (entry.tip or "") .. "\n" .. ns.ROLL_MODE_HELP)
    end
end

function UI.AddFightTurn(self, body)
    local session = F.session
    local mine = F.MyTurn()
    local holder = session.members[session.turn or ""]
    UI.AddHeading(body, mine and "Your turn" or (holder and (holder.name .. "'s turn") or "Between turns"))
    if mine then
        UI.AddLabel(body, 1, UI.GREY .. F.TurnText() .. "|r", nil, "Your turn",
            "A turn is one action, one bonus action when something gives you one, and your movement. Your reaction comes back when your turn starts and can be used on anyone's turn. Only one spell a turn can spend a spell slot.")
    else
        UI.AddLabel(body, 1, UI.GREY .. "Until your turn you can take a reaction, and do what takes no action.|r")
    end
    local section
    for _, entry in ipairs(F.Actions()) do
        if entry.section ~= section then
            section = entry.section
            UI.AddLabel(body, 1, UI.ACCENT .. section .. "|r")
        end
        AddAction(self, body, entry)
    end
    if mine then
        UI.AddLabel(body, 1, "\n" .. UI.ACCENT .. "End turn|r", function() F.EndTurn() end, "End turn", "The turn goes to the next in the order.")
    end
end
