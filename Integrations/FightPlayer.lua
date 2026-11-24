-- Combat sessions, part 4: a player's side (the owner is a player too). Joining and
-- leaving, picking a group, rolling initiative, ending the turn, and noticing what a
-- new copy of the session starts: the call for initiative, this character's turn.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local invited -- the id of the session this client was last told it can join

-- This character as the session lists it.
local function Describe()
    return {
        name = RPSheet:GetCharacterName(), ac = RPSheet:AC(), hp = RPSheet:State().hp or 0,
        max = RPSheet:MaxHP(), dex = RPSheet:Mod("DEX"),
    }
end

-- Called after the session changed, with what was known before (nil: nothing).
function F.Applied(before)
    local session = F.session
    local same = before and before.id == session.id
    F.joined = session.members[F.Me() or ""] ~= nil
    RPSheet.db.char.fightJoined = F.joined or nil -- asked for again after a reload (FightSend.lua)
    if F.Mine() then
        if session.phase == "ROLL" and not (same and before.phase == "ROLL") then
            RPSheet:Print("Roll initiative: the Initiative row of your sheet, or the button in the combat window.")
            F.ShowWindow()
        end
        local mine = session.phase == "RUN" and session.turn == F.Me()
        if mine and not (same and before.phase == "RUN" and before.turn == session.turn and before.round == session.round) then
            F.TurnStarts()
        end
    end
    F.Changed()
end

function F.Join()
    local session = F.session
    if not session then return end
    if not RPSheet:ClassData() then
        RPSheet:Print("There is no character to fight with yet. /sheet new makes one.")
        return
    end
    if not F.joined then F.KeepSnapshot() end
    F.lastStatus = nil
    if not F.Request("J", Describe()) then
        RPSheet:Print("The session's owner can't be reached: you are not in a group with them, or the game blocks addon messages right now.")
    end
    F.Changed()
end

function F.Leave()
    if not F.session then return end
    if F.IsOwner() then return F.End() end
    if F.joined then F.Send("L", {}) end
    F.Ended()
end

function F.SetMark(mark)
    if F.Mine() then F.Request("M", { mark = mark }) end
end

-- True when the session waits for this character's initiative.
function F.OwesInitiative()
    local mine = F.Mine()
    return mine ~= nil and not mine.init and F.session.phase ~= "LOBBY"
end

function F.RollInitiative()
    if not F.OwesInitiative() then return end
    RPSheet:RollCheck("initiative", RPSheet:Initiative(), ns.RollMode())
end

function F.EndTurn()
    if F.MyTurn() then F.Request("T", {}) end
end

-- The session is over for this client, or was left.
function F.Ended()
    local was = F.joined
    F.session, F.joined, F.target = nil, false, nil
    RPSheet.db.char.fightJoined = nil
    F.ResetTurn()
    if was then
        RPSheet:Print(F.HasSnapshot()
            and "The fight is over. The combat window lets you put your hit points, slots and resources back as they were before it."
            or "The fight is over.")
    end
    F.Changed()
end

-- Armor Class or hit points changed: the owner's list follows. Called with every
-- refresh of the sheet (FightGate.lua); only a change is sent.
function F.StatusChanged()
    if not F.Mine() then return end
    local now = Describe()
    local digest = ("%d/%d/%d"):format(now.ac, now.hp, now.max)
    if digest == F.lastStatus then return end
    F.lastStatus = digest
    F.Request("H", now)
end

---------------------------------------------------------------------------
-- What the owner sends
---------------------------------------------------------------------------
function F.player.S(sender, data)
    local session = F.CleanSession(data, sender)
    if not session then return end
    local known = F.session
    -- In a session already: only its own owner is listened to.
    if known and known.owner ~= sender and (F.joined or F.IsOwner()) then return end
    local before = known and known.id == session.id
        and { id = known.id, phase = known.phase, round = known.round, turn = known.turn } or nil
    local wasIn = F.joined and before ~= nil
    F.session = session
    F.joined = session.members[F.Me() or ""] ~= nil
    if wasIn and not F.joined then
        -- The owner's list no longer has this character.
        return F.Ended()
    end
    if not F.joined and invited ~= session.id then
        invited = session.id
        RPSheet:Print(("%s opened a combat session. |cffffd100/sheet combat|r opens the window to join it."):format(ns.Game.ShortName(sender)))
    end
    F.Applied(before)
end

function F.player.E(sender, data)
    local session = F.session
    if session and session.owner == sender and session.id == F.Text(data.id, 12) then F.Ended() end
end
