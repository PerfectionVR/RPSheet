-- Sharing stats, part 1: what is sent, and making safe what comes back.
-- (Sending is in SyncSend.lua, the "Share my stats" switch in SyncSwitch.lua, receiving
-- in SyncReceive.lua, questions about a term in SyncTerms.lua; Sync.lua switches it all
-- on.)
local _, ns = ...
local RPSheet = ns.addon

local S = {}
ns.Sync = S

S.PREFIX = "RPSheet4" -- bumped whenever the shared data changes shape
-- Ours are a few hundred bytes. A longer one is not ours, and could unpack into
-- something huge, so it isn't unpacked at all.
S.MAX_MESSAGE = 1024
-- What others sent is dropped once nothing was heard from them for this many seconds
-- and they aren't in the group, looked at every PRUNE_EVERY seconds (SyncReceive.lua).
S.STALE = 1800
S.PRUNE_EVERY = 300

-- A unit's key ("Name-Realm" in retail, "Given Family" in Forever: Core/Game.lua).
function S.FullName(unit)
    return ns.Game.UnitKey(unit)
end

-- False while the game blocks addon messages (some encounters).
function S.CanSend()
    return not (C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown())
end

-- "Share my stats": off means nothing is sent, asked or taken in.
function S.Sharing()
    return RPSheet.db.profile.share and true or false
end

-- The addon channel that reaches the group, or nil outside one. In a dungeon finder,
-- raid finder or battleground group that is the instance's channel, which reaches
-- everyone in it (a party of friends queued together is part of that group too).
function S.GroupChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end
    return IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY"
end

-- The channels a group message of ours arrives on.
S.GROUP_CHANNELS = { PARTY = true, RAID = true, INSTANCE_CHAT = true }

-- [Name-Realm] = true for everyone else in the group (the instance group when there
-- is one, as the game's party and raid units are then its members).
function S.GroupNames()
    local names = {}
    if not IsInGroup() then return names end
    local raid = IsInRaid()
    for index = 1, raid and 40 or 4 do
        local name = S.FullName((raid and "raid" or "party") .. index)
        if name then names[name] = true end
    end
    return names
end

---------------------------------------------------------------------------
-- Our own stats, stamped
---------------------------------------------------------------------------
-- A whisper and a group message can overtake each other. Each snapshot carries a stamp
-- that only grows, also over a reload (it starts from the server's clock), so that a
-- receiver can tell the older from the newer. The stamp travels beside the stats, where
-- a version that doesn't know it never looks. The same stats keep the same stamp.
local lastBody, lastMessage
local stamp = 0

function S.NextStamp()
    local now = tonumber(GetServerTime and GetServerTime()) or 0
    stamp = math.max(now, stamp + 1)
    lastBody = nil -- whatever is sent next is newer than this
    return stamp
end

-- The packed message with the character's stats as they are now.
function S.StatMessage()
    local data = RPSheet:GetStatData()
    local body = ns.Codec.Pack("addon", "D", data)
    if body ~= lastBody then
        local now = S.NextStamp()
        lastBody, lastMessage = body, ns.Codec.Pack("addon", "D", data, now)
    end
    return lastMessage
end

---------------------------------------------------------------------------
-- What others send (everything from other players is treated as untrusted)
---------------------------------------------------------------------------
function S.Num(value)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.floor(math.max(-999, math.min(999, value)))
end

-- Plain text only: no colour/link escapes, no control or broken characters, limited length.
function S.Text(value, fallback, length)
    if type(value) ~= "string" then return fallback end
    return ns.Codec.Cut(ns.Codec.PlainText(value), length or 40)
end

-- A stamp as sent by a version that has them, or nil.
function S.Stamp(value)
    if type(value) ~= "number" or value ~= value then return end
    return value
end

function S.Sanitize(data)
    local Num, Text = S.Num, S.Text
    if type(data) ~= "table" or type(data.stats) ~= "table" then return end
    local clean = {
        summary = Text(data.summary, "", 160), -- four classes with their specs take that much
        ac = Num(data.ac),
        stats = {},
        trackers = {},
    }
    for i = 1, 6 do clean.stats[i] = Num(data.stats[i]) end
    if type(data.trackers) == "table" then
        for i = 1, 4 do
            local tracker = data.trackers[i]
            if type(tracker) == "table" then
                clean.trackers[#clean.trackers + 1] = { Text(tracker[1], "?"), Num(tracker[2]), Num(tracker[3]) }
            end
        end
    end
    if type(data.conditions) == "table" then
        clean.conditions = {}
        for i = 1, 16 do
            local name = Text(data.conditions[i])
            if name and name ~= "" then clean.conditions[#clean.conditions + 1] = name end
        end
    end
    if type(data.weapon) == "string" then
        clean.weapon = Text(data.weapon)
        clean.dice, clean.sides = Num(data.dice), Num(data.sides)
    end
    return clean
end
