-- Combat sessions, part 9: how long things last. The sheet keeps no clock; while the
-- turns of a session are taken, what a character started is counted down in that
-- character's own turns, a round each. What is counted:
--   * a spell cast during the fight that lasts an hour or less (Data/SpellDurations.lua):
--     one that is concentrated on ends the concentration when its time is up, another
--     ends its protection (Sheet/Wards.lua) and its later rolls (Actions/SpellLater.lua);
--   * a class feature, trait or feat that is switched on for a time (Data/Lasting.lua).
-- Something of N rounds ends when the Nth of the character's turns after it starts
-- (for a few, when that turn ends). Whatever ended some other way is forgotten here;
-- when the session is over nothing is counted any more and what still runs is the
-- player's to end, as outside a session.
--   state.fightTimers = { { kind = "CONC" | "SPELL" | "PASSIVE", name, left, total, toEnd, fresh, shown }, ... }
--   state.fightTicked = the turn that was counted last, "<session>:<round>"
--
-- This wraps RPSheet:SpellWasCast (Actions/Spells.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local F = ns.Fight

local function List()
    local state = RPSheet:State()
    if type(state.fightTimers) ~= "table" then state.fightTimers = {} end
    return state.fightTimers
end

-- The switched-on passives a feature of that name put there.
local function LastingOn(name)
    local found = {}
    for _, passive in ipairs(RPSheet:Sheet().passives) do
        if passive.enabled and passive.name == name and (passive.auto or "") ~= "" then found[#found + 1] = passive end
    end
    return found
end

-- This character's own wards of a spell (not what someone else cast on it).
local function OwnWards(spell, each)
    local passives, any = RPSheet:Sheet().passives, false
    for at = #passives, 1, -1 do
        local _, option, of = R.WardOf(passives[at].auto)
        if option and of == spell and not passives[at].byOther and passives[at].enabled then
            any = true
            if each then each(passives, at, option) end
        end
    end
    return any
end

-- True while the sheet shows that spell as running.
local function Showing(spell)
    local runs = RPSheet:State().spellLater
    return (type(runs) == "table" and runs[spell] ~= nil) or OwnWards(spell)
end

local function Find(kind, name)
    for at, timer in ipairs(List()) do
        if timer.kind == kind and timer.name == name then return timer, at end
    end
end

-- Forgets what ended some other way, and starts counting the features that were
-- switched on since the last look. Returns what is counted.
function F.SyncTimers()
    if not RPSheet:ClassData() then return {} end
    local list, state = List(), RPSheet:State()
    for at = #list, 1, -1 do
        local timer = list[at]
        local gone
        if timer.kind == "CONC" then
            gone = not state.conditions.Concentrating
        elseif timer.kind == "PASSIVE" then
            gone = #LastingOn(timer.name) == 0
        else
            local showing = Showing(timer.name)
            gone = timer.shown and not showing
            timer.shown = timer.shown or showing or nil
        end
        if gone then table.remove(list, at) end
    end
    if F.Running() then
        for _, passive in ipairs(RPSheet:Sheet().passives) do
            local lasting = passive.enabled and (passive.auto or "") ~= "" and R.LASTING[passive.name]
            if lasting and lasting.rounds and not Find("PASSIVE", passive.name) then
                list[#list + 1] = { kind = "PASSIVE", name = passive.name, left = lasting.rounds, total = lasting.rounds,
                    toEnd = lasting.toEnd, fresh = true }
            end
        end
    end
    return list
end

-- A spell was cast: while turns are taken, its time starts.
local SpellWasCast = RPSheet.SpellWasCast
function RPSheet:SpellWasCast(spell, concentrating)
    SpellWasCast(self, spell, concentrating)
    if not F.Running() then return end
    local list = List()
    for at = #list, 1, -1 do
        -- A new casting starts the spell's time again, and only one spell is held at a time.
        if (list[at].kind ~= "PASSIVE" and list[at].name == spell.name) or (concentrating and list[at].kind == "CONC") then
            table.remove(list, at)
        end
    end
    local rounds = R.SPELL_ROUNDS[spell.name]
    if not rounds then return end
    list[#list + 1] = { kind = concentrating and "CONC" or "SPELL", name = spell.name, left = rounds, total = rounds }
    F.Changed()
end

-- Ends what a timer counted. `why` closes the announcement.
local function End(timer, why)
    local self = RPSheet
    local _, at = Find(timer.kind, timer.name)
    if at then table.remove(List(), at) end
    if timer.kind == "CONC" then
        return self:EndConcentration(("%s %s"):format(timer.name, why))
    elseif timer.kind == "PASSIVE" then
        for _, passive in ipairs(LastingOn(timer.name)) do passive.enabled = false end
        self:Announce(("loses %s: it %s."):format(ns.Mark(R.LASTING[timer.name].label), why))
    else
        OwnWards(timer.name, function(passives, index, option)
            -- Protection put there by hand is switched off and stays for the next time.
            if option.byHand then passives[index].enabled = false else table.remove(passives, index) end
        end)
        local runs = self:State().spellLater
        if type(runs) == "table" then runs[timer.name] = nil end
        self:Announce(("%s ends: it %s."):format(ns.Mark(timer.name), why))
    end
    self:ClampState()
    self:QueueBroadcast()
    self:PopulateSoon()
end

local function Lasted(timer)
    return ("has lasted its %s"):format(R.RoundsText(timer.total))
end

-- Ends by hand what the combat window lists as running.
function F.EndTimer(kind, name)
    local timer = Find(kind, name)
    if timer then End(timer, "was ended early") end
end

-- This character's turn starts: a round has gone by for everything that runs.
function F.TickTurnStart()
    -- Once a turn: after a reload on this character's turn the same turn starts again.
    local state, mark = RPSheet:State(), ("%s:%d"):format(F.session.id, F.session.round)
    if state.fightTicked == mark then return end
    state.fightTicked = mark
    local over = {}
    for _, timer in ipairs(F.SyncTimers()) do
        timer.left, timer.fresh = timer.left - 1, nil
        if timer.left <= 0 and not timer.toEnd then over[#over + 1] = timer end
    end
    for _, timer in ipairs(over) do End(timer, Lasted(timer)) end
end

-- This character's turn is over.
function F.TurnEnds()
    local self = RPSheet
    if not self:ClassData() then return end
    local over, persistent = {}, false
    for _, ability in ipairs(self:Sheet().abilities) do
        if ability.name == "Persistent Rage" and (ability.auto or "") ~= "" then persistent = true end
    end
    for _, timer in ipairs(F.SyncTimers()) do
        if timer.toEnd and timer.left <= 0 then over[#over + 1] = timer end
        local lasting = timer.kind == "PASSIVE" and R.LASTING[timer.name]
        -- A rage goes on only when something was done for it this turn.
        if lasting and lasting.upkeep and not timer.fresh and not F.used.attacked and not persistent then
            self:Print(("%s ends now unless you attacked, forced a saving throw or spent a bonus action to keep it up this turn. If it is over, click %s off."):format(
                lasting.label, timer.name))
        end
    end
    for _, timer in ipairs(over) do End(timer, Lasted(timer)) end
    -- Hit points a spell lent are paid back at the end of each turn (Actions/WardDamage.lua).
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and (passive.owed or 0) > 0 then
            self:Print(("%s: you lose hit points now, at the end of your turn. \"Take damage\" has the row for it."):format(passive.name))
        end
    end
end

-- The session is over for this character: nothing is counted any more.
function F.DropTimers()
    if not RPSheet:ClassData() then return end
    local state = RPSheet:State()
    local running = type(state.fightTimers) == "table" and #F.SyncTimers() or 0
    state.fightTimers, state.fightTicked = nil, nil
    if running > 0 then
        RPSheet:Print(("%d of what you started is still running. Outside a fight its time is yours to keep: end it on the sheet when it is over."):format(running))
    end
end

-- "7 rounds left", for the combat window.
function F.TimerText(timer)
    if timer.left <= 0 then return "ends with this turn" end
    if timer.left == 1 then return timer.toEnd and "to the end of your next turn" or "ends when your next turn starts" end
    return ("%d rounds left"):format(timer.left)
end
