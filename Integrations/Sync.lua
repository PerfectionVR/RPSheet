-- Shares stats between RP Sheet users, the way Total RP 3 shares profiles:
--  * hovering or targeting a player asks them (addon whisper) for their stats
--  * your own changes are pushed to your party or raid
--  * after a login or reload inside a group, the group is asked to send theirs again
-- Received stats are kept for the session only and shown in the TRP3 tooltip.
local ADDON, ns = ...
local RPSheet = ns.addon

local PREFIX = "RPSheet4" -- bumped whenever the shared data changes shape
local QUERY_COOLDOWN = 30   -- seconds before asking the same player again
local REPLY_COOLDOWN = 5    -- seconds before answering the same player again
local BROADCAST_DELAY = 2   -- groups several quick changes into one message

local EXPLAIN_COOLDOWN = 1  -- seconds before explaining to the same player again
local ASK_TIMEOUT = 5       -- seconds an explanation is waited for
-- Ours are a few hundred bytes. A longer one is not ours, and could unpack into
-- something huge, so it isn't unpacked at all.
local MAX_MESSAGE = 1024

local cache, lastQuery, lastReply = {}, {}, {}
local lastExplain, asked = {}, {} -- per player: last answer given, and the question we asked
local broadcastQueued, broadcastForced = false, false
local lastSent, lastChannel       -- what the group was sent last, so the same isn't sent twice
local lastBroadcast = -REPLY_COOLDOWN
local members = 0                 -- size of the group at the last change to it

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
local function GroupChannel()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end
    return IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY"
end

function RPSheet:SendStats(distribution, target)
    if not self.db.profile.share or not CanSend() then return end
    self:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "D", self:GetStatData()), distribution, target)
end

-- `force` sends even when nothing changed since the last time: someone new listens.
function RPSheet:BroadcastToGroup(force)
    local channel = GroupChannel()
    if not channel then lastSent = nil return end
    if not self.db.profile.share or not CanSend() then return end
    local packed = ns.Codec.Pack("addon", "D", self:GetStatData())
    -- Most clicks on the sheet change nothing others see (a tab, the next roll's mode).
    if packed == lastSent and channel == lastChannel and not force then return end
    lastSent, lastChannel, lastBroadcast = packed, channel, GetTime()
    self:SendCommMessage(PREFIX, packed, channel)
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
local function AskGroup()
    local channel = GroupChannel()
    if not channel or not CanSend() then return end
    RPSheet:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "Q"), channel)
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

-- Asks another player's addon how one of their numbers is worked out (a term clicked
-- in chat). Returns false when the question can't be sent.
function RPSheet:RequestExplanation(fullName, term)
    if not self.db.profile.share or not CanSend() then return false end
    local question = { term = term }
    asked[fullName] = question
    self:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "E", term), "WHISPER", fullName)
    local name = fullName:match("^[^-]+")
    self:Print(("Asking %s's sheet about %s..."):format(name, term))
    -- No answer comes from the other faction, from someone who has sharing off or who
    -- has left: say so instead of leaving the player waiting.
    C_Timer.After(ASK_TIMEOUT, function()
        if asked[fullName] ~= question then return end
        asked[fullName] = nil
        self:Print(("%s's sheet didn't answer."):format(name))
    end)
    return true
end

---------------------------------------------------------------------------
-- Receiving (everything from other players is treated as untrusted)
---------------------------------------------------------------------------
local function Num(value)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.floor(math.max(-999, math.min(999, value)))
end

-- Plain text only: no colour/link escapes, no control or broken characters, limited length.
local function Text(value, fallback, length)
    if type(value) ~= "string" then return fallback end
    return ns.Codec.Cut(ns.Codec.PlainText(value), length or 40)
end

local function Sanitize(data)
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

function RPSheet:OnCommReceived(_, message, distribution, sender)
    if type(sender) ~= "string" or (issecretvalue and issecretvalue(sender)) or sender == "" then return end
    if type(message) ~= "string" or #message > MAX_MESSAGE then return end
    if not sender:find("-", 1, true) then
        -- The realm isn't known for a moment after login: then there is no name to keep
        -- anything under, and the message is dropped.
        local realm = GetNormalizedRealmName()
        if not realm then return end
        sender = sender .. "-" .. realm
    end
    if sender == FullName("player") then return end

    local ok, kind, data, extra = ns.Codec.Unpack("addon", message)
    if not ok then return end

    if kind == "Q" then
        local now = GetTime()
        if distribution == "WHISPER" then
            if now - (lastReply[sender] or -REPLY_COOLDOWN) >= REPLY_COOLDOWN then
                lastReply[sender] = now
                self:SendStats("WHISPER", sender)
            end
        elseif (distribution == "PARTY" or distribution == "RAID") and now - lastBroadcast >= REPLY_COOLDOWN then
            -- A group member came back from a reload (see AskGroup).
            self:QueueBroadcast(true)
        end
    elseif kind == "D" then
        local clean = Sanitize(data)
        if clean then
            cache[sender] = clean
            ns.RefreshTRP3Tooltip(sender)
        end
    elseif kind == "E" then
        -- Someone clicked one of our terms in chat and asks how it is worked out.
        local now = GetTime()
        local term = Text(data, nil, 60)
        if term and distribution == "WHISPER" and self.db.profile.share and CanSend()
            and now - (lastExplain[sender] or -EXPLAIN_COOLDOWN) >= EXPLAIN_COOLDOWN then
            lastExplain[sender] = now
            -- The term is whatever the other player sent: an error stays here.
            local ok, text = pcall(self.ExplainTerm, self, term)
            if not ok or type(text) ~= "string" then text, self.explainCapture = "", nil end
            -- Colour codes can't travel; the receiver strips them anyway, and keeps no
            -- more than this.
            text = ns.Codec.Cut(ns.Codec.PlainText(text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")), 500)
            self:SendCommMessage(PREFIX, ns.Codec.Pack("addon", "X", term, text), "WHISPER", sender)
        end
    elseif kind == "X" then
        -- The answer to a question we asked. Anything else is ignored.
        local term, text = Text(data, nil, 60), Text(extra, "", 500)
        if term and asked[sender] and asked[sender].term == term then
            asked[sender] = nil
            local name = sender:match("^[^-]+")
            if text ~= "" then
                self:Print(("%s - %s"):format(name, text))
            else
                self:Print(("%s's sheet has nothing to work out for %s."):format(name, term))
            end
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
    -- This fires for much more than people joining (roles, subgroups, going offline).
    -- Someone who joined has nothing of ours yet; otherwise only a change is sent.
    self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        local count = GetNumGroupMembers()
        self:QueueBroadcast(count > members)
        members = count
    end)
    self:QueueBroadcast(true)
    C_Timer.After(BROADCAST_DELAY, AskGroup)
end
