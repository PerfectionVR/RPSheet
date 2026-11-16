-- Sharing stats, part 4: receiving. What other players send is checked, made safe
-- (SyncPayload.lua) and kept for the session only, and only while they are around:
-- in the group, or heard from in the last half hour. The Total RP 3 tooltip shows it.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local cache = {}     -- [Name-Realm] = the stats that player sent last
local newest = {}    -- [Name-Realm] = the stamp of the newest thing heard from them
local lastReply = {} -- [Name-Realm] = when they were last answered
local heard = {}     -- [Name-Realm] = when anything was last heard from them

function RPSheet:GetCachedStats(fullName)
    return cache[fullName]
end

-- Drops everything received so far (sharing was switched off).
function S.Forget()
    local names = {}
    for name in pairs(cache) do names[#names + 1] = name end
    for _, name in ipairs(names) do
        cache[name] = nil
        ns.RefreshTRP3Tooltip(name)
    end
end

-- Drops the stats of players who are not in the group and weren't heard from for a
-- while (they left, or walked past once), and the notes kept about them. Someone who
-- is hovered again is simply asked again.
function S.ForgetOld()
    local now, group = GetTime(), S.GroupNames()
    for name, at in pairs(heard) do
        if now - at > S.STALE and not group[name] then
            heard[name], newest[name] = nil, nil
            if cache[name] then
                cache[name] = nil
                ns.RefreshTRP3Tooltip(name)
            end
        end
    end
    for name, at in pairs(lastReply) do
        if now - at >= S.REPLY_COOLDOWN then lastReply[name] = nil end
    end
    S.ForgetQueries()
    S.ForgetExplained()
end

-- False for a message older than one already heard from the same player. One without
-- a stamp comes from a version that has none, and counts as before.
local function Newer(sender, stamp)
    stamp = S.Stamp(stamp)
    if not stamp then return true end
    if newest[sender] and stamp < newest[sender] then return false end
    newest[sender] = stamp
    return true
end

-- One function per kind of message: handler(addon, sender, distribution, ...). The
-- term questions add theirs in SyncTerms.lua.
S.handlers = {}

-- "Send me your stats."
function S.handlers.Q(self, sender, distribution)
    local now = GetTime()
    if distribution == "WHISPER" then
        if now - (lastReply[sender] or -S.REPLY_COOLDOWN) >= S.REPLY_COOLDOWN then
            lastReply[sender] = now
            self:SendStats("WHISPER", sender)
        end
    elseif S.GROUP_CHANNELS[distribution] and S.SinceBroadcast() >= S.REPLY_COOLDOWN then
        -- A group member came back from a reload (see S.AskGroup).
        self:QueueBroadcast(true)
    end
end

-- Someone's stats.
function S.handlers.D(_, sender, _, data, stamp)
    local clean = S.Sanitize(data)
    if clean and Newer(sender, stamp) then
        cache[sender] = clean
        ns.RefreshTRP3Tooltip(sender)
    end
end

-- "Drop what you have of me": they switched sharing off.
function S.handlers.C(_, sender, _, stamp)
    if Newer(sender, stamp) and cache[sender] then
        cache[sender] = nil
        ns.RefreshTRP3Tooltip(sender)
    end
end

function RPSheet:OnCommReceived(_, message, distribution, sender)
    if not S.Sharing() then return end
    if type(sender) ~= "string" or (issecretvalue and issecretvalue(sender)) or sender == "" then return end
    if type(message) ~= "string" or #message > S.MAX_MESSAGE then return end
    if not sender:find("-", 1, true) then
        -- The realm isn't known for a moment after login: then there is no name to keep
        -- anything under, and the message is dropped.
        local realm = GetNormalizedRealmName()
        if not realm then return end
        sender = sender .. "-" .. realm
    end
    if sender == S.FullName("player") then return end

    local ok, kind, data, extra = ns.Codec.Unpack("addon", message)
    if not ok or type(kind) ~= "string" then return end
    local handler = S.handlers[kind]
    if handler then
        heard[sender] = GetTime()
        handler(self, sender, distribution, data, extra)
    end
end
