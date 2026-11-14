-- Shares stats between RP Sheet users, the way Total RP 3 shares profiles:
--  * hovering or targeting a player asks them (addon whisper) for their stats
--  * your own changes are pushed to your party or raid
-- Received stats are kept for the session only and shown in the TRP3 tooltip.
local ADDON, ns = ...
local RPSheet = ns.addon

local PREFIX = "RPSheet4" -- bumped whenever the shared data changes shape
local QUERY_COOLDOWN = 30   -- seconds before asking the same player again
local REPLY_COOLDOWN = 5    -- seconds before answering the same player again
local BROADCAST_DELAY = 2   -- groups several quick changes into one message

local cache, lastQuery, lastReply = {}, {}, {}
local broadcastQueued = false

local function FullName(unit)
    local name, realm = UnitName(unit)
    if not name or (issecretvalue and issecretvalue(name)) then return end
    if not realm or realm == "" then realm = GetNormalizedRealmName() end
    return realm and (name .. "-" .. realm)
end

local function CanSend()
    return not (C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown())
end

function RPSheet:GetCachedStats(fullName)
    return cache[fullName]
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------
function RPSheet:SendStats(distribution, target)
    if not self.db.profile.share or not CanSend() then return end
    self:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "D", self:GetStatData()), distribution, target)
end

function RPSheet:BroadcastToGroup()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end
    self:SendStats(IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY")
end

function RPSheet:QueueBroadcast()
    if broadcastQueued then return end
    broadcastQueued = true
    C_Timer.After(BROADCAST_DELAY, function()
        broadcastQueued = false
        self:BroadcastToGroup()
    end)
end

local function QueryUnit(unit)
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") or not UnitIsConnected(unit) then return end
    -- Addon whispers can't cross factions; group members are covered by broadcasts.
    if UnitFactionGroup(unit) ~= UnitFactionGroup("player") then return end
    local fullName = FullName(unit)
    if not fullName or not CanSend() then return end
    local now = GetTime()
    if now - (lastQuery[fullName] or -QUERY_COOLDOWN) < QUERY_COOLDOWN then return end
    lastQuery[fullName] = now
    RPSheet:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "Q"), "WHISPER", fullName)
end

---------------------------------------------------------------------------
-- Receiving (everything from other players is treated as untrusted)
---------------------------------------------------------------------------
local function Num(value)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.floor(math.max(-999, math.min(999, value)))
end

-- Plain text only: no colour/link escapes, no control characters, limited length.
local function Text(value, fallback, length)
    if type(value) ~= "string" then return fallback end
    return (value:gsub("[|%c]", "")):sub(1, length or 40)
end

local function Sanitize(data)
    if type(data) ~= "table" or type(data.stats) ~= "table" then return end
    local clean = {
        summary = Text(data.summary, "", 100),
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

function RPSheet:OnCommReceived(_, message, distribution, sender)
    if type(sender) ~= "string" or (issecretvalue and issecretvalue(sender)) then return end
    if not sender:find("-", 1, true) then
        sender = sender .. "-" .. GetNormalizedRealmName()
    end
    if sender == FullName("player") then return end

    local ok, kind, data = ns.Codec.Unpack("addon", message)
    if not ok then return end

    if kind == "Q" then
        local now = GetTime()
        if distribution == "WHISPER" and now - (lastReply[sender] or -REPLY_COOLDOWN) >= REPLY_COOLDOWN then
            lastReply[sender] = now
            self:SendStats("WHISPER", sender)
        end
    elseif kind == "D" then
        local clean = Sanitize(data)
        if clean then
            cache[sender] = clean
            ns.RefreshTRP3Tooltip(sender)
        end
    end
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
function RPSheet:EnableSync()
    self:RegisterComm(PREFIX)
    -- Unit queries can hit protected values in combat; a failed lookup is simply skipped.
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() pcall(QueryUnit, "mouseover") end)
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() pcall(QueryUnit, "target") end)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "QueueBroadcast")
    self:QueueBroadcast()
end
