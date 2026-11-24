-- Combat sessions, part 2: sending and receiving. Messages go to the group (party or
-- raid) on a prefix of their own. A player's requests are handled by the owner's
-- client only; what the owner sends is taken by everyone in the group.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight
local S = ns.Sync

F.owner = {}  -- [kind] = handler(sender, data): requests, handled by the session's owner
F.player = {} -- [kind] = handler(sender, data): what the owner sends

-- To the group. False when there is none, or the game blocks addon messages now.
function F.Send(kind, data)
    local channel = S.GroupChannel()
    if not channel or not S.CanSend() then return false end
    RPSheet:SendCommMessage(F.PREFIX, ns.Codec.Pack("addon", kind, data), channel)
    return true
end

-- A request to the session's owner; the owner's own are handled on the spot.
function F.Request(kind, data)
    if F.IsOwner() then
        F.owner[kind](F.Me(), data or {})
        return true
    end
    return F.Send(kind, data or {})
end

function RPSheet:OnFightComm(_, message, distribution, sender)
    if not S.GROUP_CHANNELS[distribution] then return end
    if type(sender) ~= "string" or (issecretvalue and issecretvalue(sender)) or sender == "" then return end
    if type(message) ~= "string" or #message > F.MAX_MESSAGE then return end
    sender = ns.Game.SenderKey(sender)
    if not sender or sender == F.Me() then return end
    local ok, kind, data = ns.Codec.Unpack("addon", message)
    if not ok or type(kind) ~= "string" or type(data) ~= "table" then return end
    local handler = (F.IsOwner() and F.owner[kind]) or F.player[kind]
    -- What follows is not a click of this player's: a chat line it leads to may have to
    -- wait for one (Actions/AnnounceHeld.lua).
    if handler then self:OutsideClick(handler, sender, data) end
end

function RPSheet:EnableFight()
    self:RegisterComm(F.PREFIX, "OnFightComm")
    -- After a reload in the middle of a session: its owner carries on with it, and a
    -- player asks where it stands. Otherwise nothing is sent.
    C_Timer.After(3, function()
        if F.RestoreOwned() then return end
        if self.db.char.fightJoined then
            self.db.char.fightJoined = nil
            F.Send("Q", {})
        end
    end)
end
