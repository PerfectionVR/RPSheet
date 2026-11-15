-- Sharing stats, part 3: receiving. What other players send is checked, made safe
-- (SyncPayload.lua) and kept for the session only; the Total RP 3 tooltip shows it.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local cache = {}     -- [Name-Realm] = the stats that player sent last
local newest = {}    -- [Name-Realm] = the stamp of the newest thing heard from them
local lastReply = {} -- [Name-Realm] = when they were last answered

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
    elseif (distribution == "PARTY" or distribution == "RAID") and S.SinceBroadcast() >= S.REPLY_COOLDOWN then
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
    if handler then handler(self, sender, distribution, data, extra) end
end
