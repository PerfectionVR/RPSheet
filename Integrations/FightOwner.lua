-- Combat sessions, part 3: the owner's side. The owner's client keeps the session,
-- applies what the players ask for, puts everyone in initiative order, moves the turn
-- on, and announces what happens. Players roll for themselves; only the result arrives.
--
-- Initiative: everyone rolls when the owner calls for it, and the order stays the same
-- every round. Ties go to the higher Dexterity modifier, then by name. Someone who
-- joins while turns are being taken rolls initiative too and takes that place in the
-- order: they act when it next comes up.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

-- A line about one combatant ("{skull} Laura drops to 0 hit points."), or about the
-- fight itself without a name in front.
local function Say(text, member)
    RPSheet:Announce(text, member and F.ChatName(member) or "")
end

-- What this client knew before a change, to tell what the change started.
local function Before()
    local session = F.session
    return session and { id = session.id, phase = session.phase, round = session.round, turn = session.turn }
end

-- Sends the session to everyone and keeps it over a reload.
local function Broadcast(before)
    local session = F.session
    RPSheet.db.char.fightOwned = session
    F.Send("S", session)
    F.Applied(before)
end

local function Sort(session)
    local keys = {}
    for key, member in pairs(session.members) do
        if member.init then keys[#keys + 1] = key end
    end
    table.sort(keys, function(a, b)
        local one, two = session.members[a], session.members[b]
        if one.init ~= two.init then return one.init > two.init end
        if one.dex ~= two.dex then return one.dex > two.dex end
        return a < b
    end)
    session.order = keys
end

local function TurnLine(session, newRound)
    local line = ("%s's turn."):format(F.ChatName(session.members[session.turn]))
    if newRound then line = ("Round %d. %s"):format(session.round, line) end
    return line
end

local function StartTurns(session)
    session.phase, session.round, session.turn = "RUN", 1, session.order[1]
    Say(TurnLine(session, true))
end

-- The turn goes to the next in the order; after the last one a new round starts.
-- `from` is the place in the order to carry on at, when the turn's holder has left.
local function Advance(from)
    local session = F.session
    if #session.order == 0 then
        session.turn = nil
        return
    end
    local index = from
    if not index then
        index = 0
        for place, key in ipairs(session.order) do
            if key == session.turn then index = place end
        end
        index = index + 1
    end
    local newRound = index > #session.order
    if newRound then
        index, session.round = 1, session.round + 1
    end
    session.turn = session.order[index]
    Say(TurnLine(session, newRound))
end

---------------------------------------------------------------------------
-- What the owner does
---------------------------------------------------------------------------
function F.Start()
    if F.session and (F.joined or F.IsOwner()) then
        RPSheet:Print("You are in a combat session already.")
        return
    end
    local me = F.Me()
    if not me then return end
    F.session = { id = ("%06x"):format(math.random(0, 0xffffff)), owner = me, phase = "LOBBY", round = 0, members = {}, order = {} }
    RPSheet:Announce("opens a combat session. With RP Sheet, /sheet combat joins it.", true)
    F.Join()
end

-- "Roll initiative": everyone rolls, and the turns start when all have.
function F.CallInitiative()
    if not F.IsOwner() then return end
    local before, session = Before(), F.session
    session.phase, session.round, session.turn, session.order = "ROLL", 0, nil, {}
    for _, member in pairs(session.members) do member.init = nil end
    Say("Roll initiative!")
    Broadcast(before)
end

-- Starts the turns with those who have rolled; the others take their place when they do.
function F.Begin()
    local session = F.session
    if not F.IsOwner() or session.phase ~= "ROLL" then return end
    if #session.order == 0 then
        RPSheet:Print("Nobody has rolled initiative yet.")
        return
    end
    local before = Before()
    StartTurns(session)
    Broadcast(before)
end

function F.NextTurn()
    if not F.IsOwner() or F.session.phase ~= "RUN" then return end
    local before = Before()
    Advance()
    Broadcast(before)
end

function F.End()
    if not F.IsOwner() then return end
    local rounds = F.session.round
    Say(rounds > 0 and ("The fight is over after %d %s."):format(rounds, rounds == 1 and "round" or "rounds") or "The combat session is closed.")
    F.Send("E", { id = F.session.id })
    RPSheet.db.char.fightOwned = nil
    F.Ended()
end

-- After a reload the owner carries on with the session it had.
function F.RestoreOwned()
    local kept = RPSheet.db.char.fightOwned
    local session = type(kept) == "table" and F.Me() and F.CleanSession(kept, F.Me())
    RPSheet.db.char.fightOwned = nil
    if not session then return false end
    F.session, F.joined = session, session.members[F.Me()] ~= nil
    Broadcast()
    return true
end

---------------------------------------------------------------------------
-- What the players ask for
---------------------------------------------------------------------------
function F.owner.J(sender, data)
    local session, clean = F.session, F.CleanMember(data)
    if not clean then return end
    local before, member = Before(), session.members[sender]
    if member then
        -- Back after a reload: the place in the order and the group are kept.
        member.name, member.ac, member.hp, member.max, member.dex = clean.name, clean.ac, clean.hp, clean.max, clean.dex
    else
        local count = 0
        for _ in pairs(session.members) do count = count + 1 end
        if count >= F.MAX_MEMBERS then return end
        clean.init = nil
        session.members[sender] = clean
        Say(session.phase == "RUN" and "joins the fight and rolls initiative." or "joins the combat session.", clean)
    end
    Broadcast(before)
end

function F.owner.L(sender)
    local session = F.session
    local member = session.members[sender]
    if not member then return end
    local before, place = Before(), nil
    for index, key in ipairs(session.order) do
        if key == sender then place = index end
    end
    Say("leaves the fight.", member)
    session.members[sender] = nil
    if place then table.remove(session.order, place) end
    if session.turn == sender then
        session.turn = nil
        if session.phase == "RUN" then Advance(place) end
    end
    Broadcast(before)
end

-- A group picked: one of the eight marks, or 0 for none.
function F.owner.M(sender, data)
    local member = F.session.members[sender]
    if not member then return end
    local before = Before()
    member.mark = F.Num(data.mark, 0, #F.MARKS, 0)
    Broadcast(before)
end

-- An initiative total.
function F.owner.R(sender, data)
    local session = F.session
    local member = session.members[sender]
    local init = F.Num(data.init, -20, 99, nil)
    if not member or not init or session.phase == "LOBBY" or member.init then return end
    local before = Before()
    member.init, member.dex = init, F.Num(data.dex, -5, 15, 0)
    Sort(session)
    if session.phase == "ROLL" then
        local waiting = false
        for _, other in pairs(session.members) do waiting = waiting or not other.init end
        if not waiting then StartTurns(session) end
    end
    Broadcast(before)
end

-- Something a player's character did, in the words their sheet made for it. With an
-- attack roll at someone in the fight, the owner's client says whether it hits.
function F.owner.A(sender, data)
    local session = F.session
    local member = session.members[sender]
    local text = F.Text(data.text, 900)
    if not member or text == "" then return end
    local target = type(data.target) == "string" and data.target ~= sender and session.members[data.target]
    local total, die = F.Num(data.total, -50, 200, nil), F.Num(data.die, 1, 20, nil)
    if target and data.attack == true and total and die then
        if die == 1 then
            text = ("%s - a natural 1 misses %s"):format(text, target.name)
        elseif die == 20 then
            text = ("%s - a critical hit on %s"):format(text, target.name)
        elseif total >= target.ac then
            text = ("%s - hits %s (AC %d)"):format(text, target.name, target.ac)
        else
            text = ("%s - misses %s (AC %d)"):format(text, target.name, target.ac)
        end
    end
    Say(text, member)
end

function F.owner.T(sender)
    local session = F.session
    if session.phase ~= "RUN" or session.turn ~= sender then return end
    local before = Before()
    Advance()
    Broadcast(before)
end

-- A combatant's Armor Class and hit points as they are now.
function F.owner.H(sender, data)
    local member = F.session.members[sender]
    if not member then return end
    local before, was = Before(), member.hp
    member.ac = F.Num(data.ac, 0, 60, member.ac)
    member.max = F.Num(data.max, 1, 9999, member.max)
    member.hp = F.Num(data.hp, 0, 9999, member.hp)
    if was > 0 and member.hp == 0 then
        Say("drops to 0 hit points.", member)
    elseif was == 0 and member.hp > 0 then
        Say(("is back up with %d hit points."):format(member.hp), member)
    end
    Broadcast(before)
end

-- "Where does the session stand?" (someone logged in or reloaded)
function F.owner.Q()
    F.Send("S", F.session)
end
