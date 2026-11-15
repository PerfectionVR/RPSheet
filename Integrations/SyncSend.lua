-- Sharing stats, part 2: sending. Your own changes go to your party or raid, a little
-- after the change and only when something others see is different; hovering or
-- targeting a player asks them; and what couldn't be sent while the game blocked addon
-- messages is sent once it lets them through again.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local QUERY_COOLDOWN = 30   -- seconds before asking the same player again
local BROADCAST_DELAY = 2   -- groups several quick changes into one message
local RETRY = 5             -- seconds between looks at whether messages get through again
S.REPLY_COOLDOWN = 5        -- seconds before answering the same player again
S.BROADCAST_DELAY = BROADCAST_DELAY

local lastQuery = {}
local broadcastQueued, broadcastForced = false, false
local lastSent, lastChannel       -- what the group was sent last, so the same isn't sent twice
local lastBroadcast = -S.REPLY_COOLDOWN
local held = false                -- the game blocks messages, and something waits for it
local askOwed, clearOwed = false, false

local function GroupChannel()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end
    return IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY"
end

local function Send(message, distribution, target)
    RPSheet:SendCommMessage(S.PREFIX, message, distribution, target)
end

-- Seconds since the group was last sent our stats.
function S.SinceBroadcast()
    return GetTime() - lastBroadcast
end

local Hold

-- An answer to one player who asked.
function RPSheet:SendStats(distribution, target)
    if not S.Sharing() or not S.CanSend() then return end
    Send(S.StatMessage(), distribution, target)
end

-- `force` sends even when nothing changed since the last time: someone new listens.
function RPSheet:BroadcastToGroup(force)
    local channel = GroupChannel()
    if not channel then lastSent = nil return end
    if not S.Sharing() then return end
    local packed = S.StatMessage()
    -- Most clicks on the sheet change nothing others see (a tab, the next roll's mode).
    if packed == lastSent and channel == lastChannel and not force then return end
    if not S.CanSend() then Hold() return end
    lastSent, lastChannel, lastBroadcast = packed, channel, GetTime()
    Send(packed, channel)
end

function RPSheet:QueueBroadcast(force)
    broadcastForced = broadcastForced or force == true
    if broadcastQueued then return end
    broadcastQueued = true
    C_Timer.After(BROADCAST_DELAY, function()
        local forced = broadcastForced
        broadcastQueued, broadcastForced = false, false
        self:BroadcastToGroup(forced)
    end)
end

-- After a login or reload inside a group what the others sent is gone, and they don't
-- know: ask them all at once. (Members of the other faction can't be asked by whisper.)
function S.AskGroup()
    local channel = GroupChannel()
    if not channel or not S.Sharing() then return end
    if not S.CanSend() then askOwed = true; Hold() return end
    Send(ns.Codec.Pack("addon", "Q"), channel)
end

-- Tells the group to drop what it has of us. Versions that don't know this message
-- ignore it and keep their copy until they reload.
local function SendClear()
    local channel = GroupChannel()
    if not channel then return end
    if not S.CanSend() then clearOwed = true; Hold() return end
    Send(ns.Codec.Pack("addon", "C", S.NextStamp()), channel)
end

-- The game blocks addon messages for a while (some encounters) and doesn't say when it
-- stops: look again every few seconds while something waits, then send it once.
function Hold()
    if held then return end
    held = true
    local function Look()
        if not S.CanSend() then C_Timer.After(RETRY, Look) return end
        local ask, clear = askOwed, clearOwed
        held, askOwed, clearOwed = false, false, false
        if S.Sharing() then
            if ask then S.AskGroup() end
            RPSheet:BroadcastToGroup(true)
        elseif clear then
            SendClear()
        end
    end
    C_Timer.After(RETRY, Look)
end

-- The "Share my stats" switch. Off: the group drops its copy at once and what was
-- received is forgotten. On: the group gets the stats and is asked for theirs.
function RPSheet:SetSharing(on)
    on = on and true or false
    local was = S.Sharing()
    self.db.profile.share = on
    if on == was then return end
    lastSent, clearOwed = nil, false
    if on then
        self:QueueBroadcast(true)
        C_Timer.After(BROADCAST_DELAY, S.AskGroup)
    else
        S.Forget()
        SendClear()
    end
end

function S.QueryUnit(unit)
    if not S.Sharing() then return end
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") or not UnitIsConnected(unit) then return end
    -- Addon whispers can't cross factions; group members are covered by broadcasts.
    if UnitFactionGroup(unit) ~= UnitFactionGroup("player") then return end
    local fullName = S.FullName(unit)
    if not fullName or not S.CanSend() then return end
    local now = GetTime()
    if now - (lastQuery[fullName] or -QUERY_COOLDOWN) < QUERY_COOLDOWN then return end
    lastQuery[fullName] = now
    Send(ns.Codec.Pack("addon", "Q"), "WHISPER", fullName)
end
