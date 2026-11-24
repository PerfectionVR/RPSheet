-- Turn-based combat sessions, part 1: what a session is, shared by the other parts.
--
-- One player starts a session and owns it. The owner's copy of the session is the
-- truth: the others send requests ("I join", "I rolled 17", "I end my turn") and the
-- owner's client applies them and sends the whole session back. Every player rolls
-- for their own character; the owner's client announces what comes of it.
--
--   Fight.lua          the session table, making safe what is received, small queries
--   FightSend.lua      sending and receiving
--   FightOwner.lua     the owner's side: joining, initiative order, turns, announcing
--   FightPlayer.lua    a player's side: joining, rolling, the turn starting
--   FightSnapshot.lua  the character's play state kept from before the fight
--   FightTurn.lua      what a turn allows: action, bonus action, reaction
--   FightGate.lua      attacks, abilities and spells asked for during a fight
--   FightActions.lua   what the window offers on a turn
--   FightTimers.lua    what lasts a number of rounds
--   FightCreatures.lua combatants the owner runs
--   FightOwnerTools.lua  saves and damage the owner asks for, handing the session on
--   UI/FightWindow*.lua  the window
local _, ns = ...

local F = {}
ns.Fight = F

F.PREFIX = "RPSheetF2" -- bumped whenever the messages change shape
F.MAX_MESSAGE = 4096
F.MAX_MEMBERS = 40

-- The groups a player can join: the game's eight target marks. `code` is what chat
-- turns into the icon.
F.MARKS = {
    { name = "Star", code = "{star}" }, { name = "Circle", code = "{circle}" },
    { name = "Diamond", code = "{diamond}" }, { name = "Triangle", code = "{triangle}" },
    { name = "Moon", code = "{moon}" }, { name = "Square", code = "{square}" },
    { name = "Cross", code = "{cross}" }, { name = "Skull", code = "{skull}" },
}

-- The mark's icon for a window's text.
function F.MarkIcon(mark)
    if not F.MARKS[mark] then return "" end
    return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0|t "):format(mark)
end

F.session = nil -- the session this client knows of: its own, one it joined, or one it was told about
F.joined = false -- true once this client's character is in it

local function Num(value, low, high, fallback)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.max(low, math.min(high, math.floor(value)))
end

local function Text(value, length)
    if type(value) ~= "string" then return "" end
    return ns.Codec.Cut(ns.Codec.PlainText((value:gsub("%c+", " "))), length)
end
F.Num, F.Text = Num, Text

-- A combatant as another client described it, made safe: numbers held to what a
-- character can have, text without colour codes or links.
function F.CleanMember(data)
    if type(data) ~= "table" then return end
    local name = Text(data.name, 40)
    if name == "" then return end
    return {
        name = name,
        mark = Num(data.mark, 0, #F.MARKS, 0),
        init = Num(data.init, -20, 99, nil),
        dex = Num(data.dex, -5, 15, 0),
        ac = Num(data.ac, 0, 60, 10),
        hp = Num(data.hp, 0, 9999, 0),
        max = Num(data.max, 1, 9999, 1),
        npc = data.npc == true or nil, -- run by the session's owner (FightCreatures.lua)
    }
end

-- A whole session as its owner sent it, made safe. Nil when it isn't one.
function F.CleanSession(data, owner)
    if type(data) ~= "table" or type(data.members) ~= "table" then return end
    local id = Text(data.id, 12)
    if id == "" then return end
    local session = {
        id = id, owner = owner,
        phase = (data.phase == "ROLL" or data.phase == "RUN") and data.phase or "LOBBY",
        round = Num(data.round, 0, 9999, 0),
        members = {}, order = {},
    }
    local count = 0
    for key, member in pairs(data.members) do
        local clean = type(key) == "string" and #key <= 80 and count < F.MAX_MEMBERS and F.CleanMember(member)
        if clean then
            session.members[key] = clean
            count = count + 1
        end
    end
    for _, key in ipairs(type(data.order) == "table" and data.order or {}) do
        if session.members[key] and #session.order < F.MAX_MEMBERS then session.order[#session.order + 1] = key end
    end
    if type(data.turn) == "string" and session.members[data.turn] then session.turn = data.turn end
    return session
end

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------
function F.Me()
    return ns.Game.UnitKey("player")
end

function F.IsOwner()
    return F.session ~= nil and F.session.owner == F.Me()
end

-- This client's own combatant, or nil.
function F.Mine()
    return F.joined and F.session and F.session.members[F.Me() or ""] or nil
end

-- True while turns are being taken and this client's character takes part.
function F.Running()
    return F.Mine() ~= nil and F.session.phase == "RUN"
end

function F.MyTurn()
    return F.Running() and F.session.turn == F.Me()
end

-- "{skull} Laura" for chat, or just the name without a group.
function F.ChatName(member)
    local mark = F.MARKS[member.mark]
    return mark and (mark.code .. " " .. member.name) or member.name
end

-- The members in the order they act; those who haven't rolled yet come last, by name.
function F.Roster()
    local session, list, seen = F.session, {}, {}
    if not session then return list end
    for _, key in ipairs(session.order) do
        list[#list + 1], seen[key] = key, true
    end
    local rest = {}
    for key in pairs(session.members) do
        if not seen[key] then rest[#rest + 1] = key end
    end
    table.sort(rest)
    for _, key in ipairs(rest) do list[#list + 1] = key end
    return list
end

-- Called whenever the session changed; the window hooks in here (UI/FightWindow.lua).
function F.Changed()
    if F.OnChange then F.OnChange() end
end
