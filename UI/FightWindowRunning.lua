-- The combat window's list of what this character has running and how many rounds
-- each has left (Integrations/FightTimers.lua). A click ends one early.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local F = ns.Fight

local KIND = {
    CONC = "a spell you concentrate on. When its time is up your concentration ends, and with it what hung on the spell",
    SPELL = "a spell you cast. When its time is up it ends, with the protection and the later rolls it gave you",
    PASSIVE = "switched on for a time. When its time is up it is switched off",
}

function UI.AddFightRunning(self, body)
    local timers = F.SyncTimers()
    if #timers == 0 then return end
    UI.AddHeading(body, "Running")
    for _, timer in ipairs(timers) do
        local kind, name = timer.kind, timer.name
        local label = kind == "PASSIVE" and R.LASTING[name].label or name
        UI.AddLabel(body, 1, ("%s%s  %s%s|r"):format(label, kind == "CONC" and (UI.GREY .. " (concentration)|r") or "", UI.GREY, F.TimerText(timer)),
            function() F.EndTimer(kind, name) end, label,
            ("%s: %s. It lasts %s, counted in your own turns: a round has gone by each time your turn starts.\nClick to end it now."):format(
                label, KIND[kind], R.RoundsText(timer.total)))
    end
end
