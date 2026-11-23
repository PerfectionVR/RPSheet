-- Several players in one Lua state, for the t-sync-*.lua scripts.
--
-- The addon keeps its state in one addon object and one private table per load, so
-- each simulated player ("client") gets a globals table of its own: the libraries
-- and the addon's files are loaded once per client with setfenv. Unlike sim.lua the
-- libraries are the real ones (AceAddon, AceEvent, AceDB, AceConsole, AceComm with
-- ChatThrottleLib, LibSerialize, LibDeflate), so events, saved variables, slash
-- commands, message splitting and compression behave as in the game.
--
-- A World joins the clients: one clock, groups, and a fake addon channel and chat
-- with the game's limits (255 bytes, a prefix registered before it is heard, the
-- server's per-prefix throttle, whispers that don't cross factions).
--
--   local world = NewWorld()
--   local a = world:AddClient({ name = "Anna", realm = "Realm" }):Login()
--   world:Group({ a, b })          world:Advance(3)
--   a.addon, a.ns, a.env           the client's addon object, private table, globals
--   a.printed, a.chat, a.errors    lines printed to it, chat lines shown, Lua errors
--   world.wire                     every addon message that left a client
--
-- Total RP 3 is a stand-in written from its 3.5.5 source: the profile functions,
-- the tooltip builder and its events, as far as the addon reads them.
dofile(ARG3 .. "/env.lua")
local BASE = _G
local ROOT, HERE = ARG1, ARG3

CHECKS, FAILED = 0, 0
function Check(ok, text)
    CHECKS = CHECKS + 1
    if not ok then FAILED = FAILED + 1; print("PROBLEM: " .. tostring(text)) end
    return ok
end
function Eq(got, want, text)
    return Check(got == want, ("%s: got %s, expected %s"):format(text, tostring(got), tostring(want)))
end
function Section(label, fn)
    local ok, err = xpcall(fn, function(m) return debug.traceback(m, 2) end)
    if not ok then Check(false, "[" .. label .. "] error: " .. tostring(err):sub(1, 1200)) end
end
function Summary(name)
    print(("%s: %d checks, %d problems"):format(name, CHECKS, FAILED))
    io.stdout:flush()
end

---------------------------------------------------------------------------
-- Files
---------------------------------------------------------------------------
local function exists(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
local libRoot
do
    local roots = { ROOT .. "/Libs" }
    for path in tostring(rawget(BASE, "ACE_LIBS") or ""):gmatch("[^;]+") do roots[#roots + 1] = path end
    for _, candidate in ipairs(roots) do
        if exists(candidate .. "/AceComm-3.0/AceComm-3.0.lua") and exists(candidate .. "/LibDeflate/LibDeflate.lua") then
            libRoot = candidate
            break
        end
    end
    if not libRoot then error("t-sync-clients: no copy of the Ace3 libraries found (ACE_LIBS in tests/local.cfg)") end
end

local sources = {}
local function Source(path)
    if not sources[path] then
        local file = assert(io.open(path, "rb"))
        sources[path] = file:read("*a")
        file:close()
    end
    return sources[path]
end
local function Chunk(path, env)
    local chunk, problem = loadstring(Source(path), "@" .. path)
    if not chunk then error(problem) end
    return setfenv(chunk, env)
end

local LIB_FILES = {
    "LibStub/LibStub.lua", "CallbackHandler-1.0/CallbackHandler-1.0.lua",
    "AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua", "AceAddon-3.0/AceAddon-3.0.lua",
    "AceEvent-3.0/AceEvent-3.0.lua", "AceDB-3.0/AceDB-3.0.lua", "AceConsole-3.0/AceConsole-3.0.lua",
    "AceComm-3.0/ChatThrottleLib.lua", "AceComm-3.0/AceComm-3.0.lua", "AceDBOptions-3.0/AceDBOptions-3.0.lua",
    "LibSerialize/LibSerialize.lua", "LibDeflate/LibDeflate.lua",
}
local ADDON_FILES = {}
for line in io.lines(ROOT .. "/RPSheet.toc") do
    line = line:gsub("\r", "")
    if line:match("%.lua$") and not line:match("^Libs") and not line:match("^#") then
        ADDON_FILES[#ADDON_FILES + 1] = (line:gsub("\\", "/"))
    end
end

---------------------------------------------------------------------------
-- Frames: events and scripts are real, everything else is a stand-in
---------------------------------------------------------------------------
local Frame = {}
local frameMT = { __index = function(frame, key)
    if Frame[key] then return Frame[key] end
    if type(key) ~= "string" or not key:find("^%u") then return nil end -- only methods are stand-ins
    return function() return BASE.STUB("frame:" .. tostring(key) .. "()") end
end }
local function NewFrame(client, name)
    local frame = setmetatable({ events = {}, scripts = {}, shown = true, name = name, lines = {} }, frameMT)
    client.frames[#client.frames + 1] = frame
    if name then rawset(client.env, name, frame) end
    return frame
end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:UnregisterAllEvents() self.events = {} end
function Frame:IsEventRegistered(event) return self.events[event] == true end
function Frame:SetScript(kind, fn) self.scripts[kind] = fn end
function Frame:GetScript(kind) return self.scripts[kind] end
function Frame:HasScript() return true end
function Frame:HookScript(kind, fn)
    local old = self.scripts[kind]
    self.scripts[kind] = old and function(...) old(...) fn(...) end or fn
end
function Frame:Show() if not self.shown then self.shown = true; self:Run("OnShow") end end
function Frame:Hide() if self.shown then self.shown = false; self:Run("OnHide") end end
function Frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown end
function Frame:GetName() return self.name end
function Frame:AddMessage(text) self.lines[#self.lines + 1] = text end
function Frame:Run(kind, ...)
    local fn = self.scripts[kind]
    if fn then return fn(self, ...) end
end

---------------------------------------------------------------------------
-- The world
---------------------------------------------------------------------------
local World, Client = {}, {}
World.__index, Client.__index = World, Client
RESULT = { Success = 0, InvalidPrefix = 1, InvalidMessage = 2, AddonMessageThrottle = 3, InvalidChatType = 4,
    NotInGroup = 5, TargetRequired = 6, InvalidChannel = 7, ChannelThrottle = 8, GeneralError = 9, NotInGuild = 10 }
local THROTTLE_BURST = 10 -- the server lets ten messages per prefix through at once, then one a second

function NewWorld()
    return setmetatable({
        now = 1000, clients = {}, wire = {}, queue = {}, chatLog = {}, violations = {},
        latency = 0,           -- seconds a message is on its way
        bareSenders = false,   -- true: senders of the same realm arrive without "-Realm"
        regional = false,      -- true: WoW Forever's names, "Given Family" with no realm (set before AddClient)
        tamper = false,        -- function(message) -> list of messages to deliver in its place
    }, World)
end

function World:Violation(text)
    self.violations[#self.violations + 1] = text
    Check(false, "the game would refuse this: " .. text)
end

function World:AddClient(who)
    local client = setmetatable({
        world = self, name = who.name, realm = who.realm or "Realm", realmTitle = who.realmTitle,
        faction = who.faction or "Alliance", trp3 = who.trp3 or false, saved = who.saved,
        oldChatFilters = who.oldChatFilters or false, online = false, group = false, instance = false, units = {},
        lockdown = false, combat = false,
    }, Client)
    client.full = client.name .. "-" .. client.realm
    if self.regional then client.family = who.family or "Family"; client.full = client.name .. " " .. client.family end
    self.clients[#self.clients + 1] = client
    return client
end

function World:Find(full)
    for _, client in ipairs(self.clients) do
        if client.full == full and client.online then return client end
    end
end

-- Puts the clients in one party (or raid); with an empty list, see Client:LeaveGroup.
function World:Group(members, raid)
    local group = { members = {}, raid = raid or false }
    local touched = {}
    for _, client in ipairs(members) do
        if client.group then
            for _, other in ipairs(client.group.members) do touched[other] = true end
            client:Drop()
        end
        group.members[#group.members + 1] = client
        client.group = group
        touched[client] = true
    end
    for client in pairs(touched) do
        if client.online then client:Fire("GROUP_ROSTER_UPDATE") end
    end
    return group
end

-- Puts the clients in one dungeon finder, raid finder or battleground group: the game's
-- instance group, which a client has beside its own party or raid (`group`).
function World:Instance(members, raid)
    local group = { members = {}, raid = raid or false, instance = true }
    for _, client in ipairs(members) do
        if client.instance then client:LeaveInstance() end
        group.members[#group.members + 1] = client
        client.instance = group
    end
    for _, client in ipairs(members) do
        if client.online then client:Fire("GROUP_ROSTER_UPDATE") end
    end
    return group
end

function Client:LeaveInstance()
    local group = self.instance
    if not group then return end
    for i, member in ipairs(group.members) do
        if member == self then table.remove(group.members, i) break end
    end
    self.instance = false
    if self.online then self:Fire("GROUP_ROSTER_UPDATE") end
    for _, member in ipairs(group.members) do
        if member.online then member:Fire("GROUP_ROSTER_UPDATE") end
    end
end

-- Adds a client to the group another one is in.
function World:Join(client, with)
    local group = with.group or self:Group({ with })
    if client.group then client:LeaveGroup() end
    group.members[#group.members + 1] = client
    client.group = group
    for _, member in ipairs(group.members) do
        if member.online then member:Fire("GROUP_ROSTER_UPDATE") end
    end
end

function Client:Drop()
    local group = self.group
    if not group then return end
    for i, member in ipairs(group.members) do
        if member == self then table.remove(group.members, i) break end
    end
    self.group = false
    return group
end

function Client:LeaveGroup()
    local group = self:Drop()
    if not group then return end
    if self.online then self:Fire("GROUP_ROSTER_UPDATE") end
    if #group.members == 1 then -- a party of one is no party
        local last = group.members[1]
        last.group = false
        group.members = {}
        if last.online then last:Fire("GROUP_ROSTER_UPDATE") end
    else
        for _, member in ipairs(group.members) do
            if member.online then member:Fire("GROUP_ROSTER_UPDATE") end
        end
    end
end

-- Lets `seconds` pass in steps of a tenth: timers, messages on their way, OnUpdate.
function World:Advance(seconds)
    local steps = math.floor(seconds * 10 + 0.5)
    for _ = 1, math.max(steps, 1) do
        self.now = self.now + 0.1
        self:Deliver()
        for _, client in ipairs(self.clients) do
            if client.online then client:Tick(0.1) end
        end
    end
end

function World:Deliver()
    local due, later = {}, {}
    for _, message in ipairs(self.queue) do
        if message.at <= self.now + 1e-9 then due[#due + 1] = message else later[#later + 1] = message end
    end
    self.queue = later
    for _, message in ipairs(due) do
        if message.to.online then message.to:Fire(unpack(message.args, 1, message.n)) end
    end
end

local function Enqueue(world, to, ...)
    world.queue[#world.queue + 1] = { at = world.now + world.latency, to = to, args = { ... }, n = select("#", ...) }
end

-- The name a receiver sees a sender under.
local function SenderFor(world, from, to)
    if world.regional then return from.full end
    if world.bareSenders and from.realm == to.realm then return from.name end
    return from.full
end

local function Recipients(world, from, chatType, target)
    if chatType == "PARTY" or chatType == "RAID" or chatType == "INSTANCE_CHAT" then
        local group = chatType == "INSTANCE_CHAT" and from.instance or (chatType ~= "INSTANCE_CHAT" and from.group)
        if not group then return nil, RESULT.NotInGroup end
        local list = {}
        for _, member in ipairs(group.members) do
            if member.online then list[#list + 1] = member end
        end
        return list
    elseif chatType == "WHISPER" then
        if type(target) ~= "string" or target == "" then return nil, RESULT.TargetRequired end
        if not world.regional and not target:find("-", 1, true) then target = target .. "-" .. from.realm end
        local to = world:Find(target)
        if not to then
            from.system[#from.system + 1] = ("No player named '%s' is currently playing."):format(target)
            return {}
        end
        if to.faction ~= from.faction then return {} end -- lost without a word
        return { to }
    end
    return nil, RESULT.InvalidChatType
end

function World:SendAddon(from, prefix, text, chatType, target)
    if type(prefix) ~= "string" or #prefix > 16 or prefix == "" then
        self:Violation(from.full .. " sent an addon message with a bad prefix") return RESULT.InvalidPrefix
    end
    if type(text) ~= "string" or #text > 255 or text:find("%z") then
        self:Violation(("%s sent an addon message of %s bytes"):format(from.full, type(text) == "string" and #text or type(text)))
        return RESULT.InvalidMessage
    end
    if from.lockdown then self:Violation(from.full .. " sent an addon message while the game blocks them") return RESULT.GeneralError end
    local bucket = from.buckets[prefix] or { tokens = THROTTLE_BURST, at = self.now }
    from.buckets[prefix] = bucket
    bucket.tokens = math.min(THROTTLE_BURST, bucket.tokens + (self.now - bucket.at))
    bucket.at = self.now
    if bucket.tokens < 1 then
        from.throttled = from.throttled + 1
        return RESULT.AddonMessageThrottle
    end
    local list, problem = Recipients(self, from, chatType, target)
    if not list then
        from.refused[#from.refused + 1] = { prefix = prefix, chatType = chatType, result = problem }
        return problem
    end
    bucket.tokens = bucket.tokens - 1
    local sent = { from = from, prefix = prefix, text = text, chatType = chatType, target = target, at = self.now, bytes = #prefix + #text }
    self.wire[#self.wire + 1] = sent
    local copies = self.tamper and self.tamper(sent) or { sent }
    for _, message in ipairs(copies) do
        for _, to in ipairs(list) do
            if to.prefixes[message.prefix] then
                Enqueue(self, to, "CHAT_MSG_ADDON", message.prefix, message.text, chatType, SenderFor(self, message.from, to), "", 0, 0, "", 0)
            end
        end
    end
    return RESULT.Success
end

-- Messages and bytes that left `from` (or anyone) since wire index `since`.
function World:Traffic(from, since)
    local count, bytes = 0, 0
    for i = (since or 0) + 1, #self.wire do
        local sent = self.wire[i]
        if not from or sent.from == from then count, bytes = count + 1, bytes + sent.bytes end
    end
    return count, bytes
end

local function ValidUTF8(text)
    local i, n = 1, #text
    while i <= n do
        local c = text:byte(i)
        local more = (c < 0x80 and 0) or (c >= 0xC2 and c < 0xE0 and 1) or (c >= 0xE0 and c < 0xF0 and 2) or (c >= 0xF0 and c < 0xF5 and 3) or -1
        if more < 0 or i + more > n then return false end
        for j = i + 1, i + more do
            local d = text:byte(j)
            if d < 0x80 or d > 0xBF then return false end
        end
        i = i + more + 1
    end
    return true
end
VALID_UTF8 = ValidUTF8

local CHAT_EVENT = { EMOTE = "CHAT_MSG_EMOTE", PARTY = "CHAT_MSG_PARTY", RAID = "CHAT_MSG_RAID", INSTANCE_CHAT = "CHAT_MSG_INSTANCE_CHAT" }
function World:SendChat(from, text, chatType)
    local sent = { from = from, text = text, chatType = chatType, at = self.now }
    self.chatLog[#self.chatLog + 1] = sent
    from.said[#from.said + 1] = sent
    if type(text) ~= "string" then self:Violation("chat message is a " .. type(text)) return end
    if #text > 255 then self:Violation(("chat message of %d bytes: %s"):format(#text, text:sub(1, 60))) end
    if text == "" then self:Violation("empty chat message") end
    if text:find("|", 1, true) then self:Violation("chat message with a pipe: " .. text:sub(1, 120)) end
    if text:find("%c") then self:Violation("chat message with a control character: " .. text:sub(1, 120):gsub("%c", "?")) end
    if not ValidUTF8(text) then self:Violation("chat message that is not valid UTF-8: " .. text:sub(-40)) end
    if from.lockdown then self:Violation("chat message sent by an addon while the game blocks them") return end
    local event = CHAT_EVENT[chatType]
    if not event then self:Violation("chat message to " .. tostring(chatType)) return end
    local list
    if chatType == "EMOTE" then
        list = {}
        for _, client in ipairs(self.clients) do if client.online then list[#list + 1] = client end end
    elseif chatType == "INSTANCE_CHAT" then
        if not from.instance then self:Violation("instance chat by someone who is not in an instance group") return end
        list = from.instance.members
    else
        if not from.group or (chatType == "RAID" and not from.group.raid) then
            self:Violation(("chat message to %s by someone who is not in one"):format(chatType)) return
        end
        list = from.group.members
    end
    for _, to in ipairs(list) do
        if to.online then Enqueue(self, to, event, text, SenderFor(self, from, to), "", "", from.name, "", 0, 0, "", 0, 0) end
    end
end

---------------------------------------------------------------------------
-- A client: its globals
---------------------------------------------------------------------------
-- Names that must not fall through to the shared globals (a client that has no value
-- for one of these reads nil, as the game would give).
local PRIVATE = {}
for name in ("LibStub ChatThrottleLib RPSheetDB TRP3_API TRP3_Addon TRP3_CharacterTooltip AddOn_TotalRP3 ChatFrameUtil " ..
    "ChatFrame_AddMessageEventFilter issecretvalue hash_SlashCmdList SendChatMessage SendAddonMessage RegisterAddonMessagePrefix " ..
    "BNSendGameData C_BattleNet AceGUIWidgetLSMlists ElvUI AddOnSkins RegionalUniqueNamesEnabled"):gmatch("%S+") do PRIVATE[name] = true end

local function Resolve(client, unit)
    if unit == "player" then return client end
    if client.units[unit] then return client.units[unit] end
    local kind, index = tostring(unit):match("^(%a+)(%d+)$")
    local group = client.instance or client.group -- the game's units follow the instance group
    if group and (kind == "party" or kind == "raid") then
        local others = {}
        for _, member in ipairs(group.members) do
            if member ~= client or kind == "raid" then others[#others + 1] = member end
        end
        return others[tonumber(index)]
    end
end

local function BuildEnv(client)
    local world = client.world
    local env = {}
    env._G = env
    client.env = env
    client.unknown = {}
    setmetatable(env, { __index = function(_, key)
        if PRIVATE[key] or (type(key) == "string" and (key:find("^SLASH_") or key:find("^ChatFrame%d"))) then return nil end
        local value = rawget(BASE, key)
        if value == nil then
            value = BASE[key] -- a stand-in for a name the fake game doesn't know
            if value ~= nil then client.unknown[key] = true end
        end
        return value
    end })

    env.StaticPopupDialogs, env.SlashCmdList, env.UISpecialFrames = {}, {}, {}
    env.NUM_CHAT_WINDOWS = 2
    env.RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
    env.LE_PARTY_CATEGORY_HOME, env.LE_PARTY_CATEGORY_INSTANCE = 1, 2
    env.Enum = setmetatable({ SendAddonMessageResult = RESULT }, { __index = function(_, key) return BASE.Enum[key] end })

    function env.GetTime() return world.now end
    function env.GetServerTime() return 1700000000 + math.floor(world.now) end
    function env.GetFramerate() return 60 end
    function env.GetCurrentRegion() return 3 end
    function env.GetCurrentRegionName() return "EU" end
    function env.IsLoggedIn() return client.loggedIn end
    function env.InCombatLockdown() return client.combat end
    function env.geterrorhandler() return function(problem) client.errors[#client.errors + 1] = tostring(problem) end end
    function env.securecallfunction(fn, ...)
        local results = { xpcall(fn, function(m) return debug.traceback(tostring(m), 2) end, ...) }
        if not results[1] then client.errors[#client.errors + 1] = tostring(results[2]) return end
        return unpack(results, 2)
    end
    function env.hooksecurefunc(where, name, hook)
        if type(where) ~= "table" then where, name, hook = env, where, name end
        local original = where[name]
        if type(original) ~= "function" then return end -- something of the game's that isn't modelled here
        rawset(where, name, function(...)
            local results = { original(...) }
            hook(...)
            return unpack(results)
        end)
    end
    function env.SetItemRef() end
    function env.BNSendGameData() end
    function env.IsModifiedClick() return false end

    local timerSeq = 0
    local function After(seconds, fn)
        timerSeq = timerSeq + 1
        local timer = { due = world.now + (tonumber(seconds) or 0), fn = fn, seq = timerSeq }
        client.timers[#client.timers + 1] = timer
        return { Cancel = function() timer.cancelled = true end }
    end
    env.C_Timer = { After = function(seconds, fn) After(seconds, fn) end, NewTimer = After,
        NewTicker = function() return { Cancel = function() end } end }

    -- Units
    function env.UnitName(unit)
        local other = Resolve(client, unit)
        if not other then return nil end
        -- Forever: the given name, then the family name where retail gives the realm.
        if world.regional then return other.name, other.family end
        return other.name, other.realm ~= client.realm and other.realm or nil
    end
    env.UnitNameUnmodified = env.UnitName
    if world.regional then
        env.C_GameRules = { IsGameRuleActive = function() return false end }
        env.Enum = setmetatable({ GameRule = { RPRuleset = 1, PvPRuleset = 2, HardcoreRuleset = 3 } }, { __index = env.Enum })
    end
    function env.UnitFullName(unit)
        local other = Resolve(client, unit)
        if other then return other.name, world.regional and other.family or other.realm end
    end
    function env.UnitExists(unit) return Resolve(client, unit) ~= nil end
    function env.UnitIsPlayer(unit) return Resolve(client, unit) ~= nil end
    function env.UnitIsUnit(a, b) return Resolve(client, a) ~= nil and Resolve(client, a) == Resolve(client, b) end
    function env.UnitIsConnected(unit) local other = Resolve(client, unit) return other ~= nil and other.online end
    function env.UnitFactionGroup(unit) local other = Resolve(client, unit) return other and other.faction end
    function env.UnitClass() return "Warrior", "WARRIOR", 1 end
    function env.UnitRace() return "Human", "Human", 1 end
    function env.GetNormalizedRealmName() return client.realmKnown and client.realm or nil end
    function env.GetRealmName() return client.realmTitle or client.realm end
    if world.regional then env.RegionalUniqueNamesEnabled = function() return true end end
    function env.Ambiguate(name) -- "none": the realm goes when it is the player's own
        local short, realm = name:match("^([^-]+)-(.+)$")
        if short and realm == client.realm then return short end
        return name
    end
    -- The category: 1 the player's own group, 2 the instance group, none either one
    -- (and for the number of members, the instance group when there is one).
    local function Of(category)
        if category == 1 then return client.group end
        if category == 2 then return client.instance end
        return client.instance or client.group
    end
    function env.IsInGroup(category)
        if category == nil then return client.group ~= false or client.instance ~= false end
        return Of(category) ~= false
    end
    function env.IsInRaid(category)
        if category == nil then return (client.group and client.group.raid or client.instance and client.instance.raid) and true or false end
        local group = Of(category)
        return group ~= false and group.raid
    end
    function env.GetNumGroupMembers(category) local group = Of(category) return group and #group.members or 0 end

    -- Addon channel and chat
    env.C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix) client.prefixes[prefix] = true return true end,
        IsAddonMessagePrefixRegistered = function(prefix) return client.prefixes[prefix] == true end,
        SendAddonMessage = function(prefix, text, chatType, target) return world:SendAddon(client, prefix, text, chatType, target) end,
        SendAddonMessageLogged = function(prefix, text, chatType, target) return world:SendAddon(client, prefix, text, chatType, target) end,
        SendChatMessage = function(text, chatType) world:SendChat(client, text, chatType) end,
        InChatMessagingLockdown = function() return client.lockdown end,
    }
    local function AddFilter(event, filter)
        client.filters[event] = client.filters[event] or {}
        table.insert(client.filters[event], filter)
    end
    if client.oldChatFilters then env.ChatFrame_AddMessageEventFilter = AddFilter
    else env.ChatFrameUtil = { AddMessageEventFilter = AddFilter } end

    -- Dice: the next results are taken from client.rolls, else half the sides.
    function env.RandomRoll(low, high)
        local value = table.remove(client.rolls, 1) or math.ceil(high / 2)
        value = math.max(low, math.min(high, value))
        client:Fire("CHAT_MSG_SYSTEM", ("%s rolls %d (%d-%d)"):format(world.regional and client.full or client.name, value, low, high))
    end
    env.MenuUtil = { CreateContextMenu = function() end }
    function env.GameTooltip_SetTitle() end
    function env.GameTooltip_AddNormalLine() end

    function env.CreateFrame(_, name) return NewFrame(client, name) end
    env.UIParent = NewFrame(client, "UIParent")
    for index = 1, env.NUM_CHAT_WINDOWS do NewFrame(client, "ChatFrame" .. index) end
    env.DEFAULT_CHAT_FRAME = env.ChatFrame1
    client.printed = env.ChatFrame1.lines
    local tip = NewFrame(client, "GameTooltip")
    tip.shown = false
    function tip:SetOwner() self.lines = {} end
    function tip:ClearLines() self.lines = {} end
    function tip:AddLine(text) self.lines[#self.lines + 1] = text end
    return env
end

---------------------------------------------------------------------------
-- Total RP 3 (a stand-in after its 3.5.5 source)
---------------------------------------------------------------------------
local function InstallTRP3(client)
    local env, trp3 = client.env, client.trp3
    trp3.profiles = trp3.profiles or { p1 = { profileName = client.name .. "'s profile" } }
    trp3.current = trp3.current or "p1"
    if trp3.ready == nil then trp3.ready = true end
    local callbacks = {}
    local Addon = { Events = { REGISTER_PROFILES_LOADED = "REGISTER_PROFILES_LOADED", MOUSE_OVER_CHANGED = "MOUSE_OVER_CHANGED" } }
    function Addon:TriggerEvent(event, ...)
        for _, callback in ipairs(callbacks[event] or {}) do callback(event, ...) end
    end
    local API = { ui = { tooltip = {} }, globals = { player_id = client.full }, profile = {} }
    function API.RegisterCallback(registry, event, callback)
        if registry ~= Addon then error("RegisterCallback: not Total RP 3's registry") end
        callbacks[event] = callbacks[event] or {}
        table.insert(callbacks[event], callback)
    end
    function API.profile.getPlayerCurrentProfileID() return trp3.ready and trp3.current or nil end
    function API.profile.getPlayerCurrentProfile() return trp3.ready and trp3.profiles[trp3.current] or nil end
    function API.profile.selectProfile(id)
        assert(trp3.profiles[id], "Unknown profile id: " .. tostring(id))
        trp3.current, trp3.ready = id, true
        Addon:TriggerEvent(Addon.Events.REGISTER_PROFILES_LOADED, trp3.profiles[id])
    end
    env.AddOn_TotalRP3 = { Player = { GetCurrentUser = function()
        return { GetFirstName = function() return trp3.ready and trp3.profiles[trp3.current].firstName or nil end }
    end } }

    -- The tooltip: a builder whose prototype sits behind its metatable, as in TRP3.
    local tooltip = NewFrame(client, "TRP3_CharacterTooltip")
    tooltip.shown = false
    local Builder = {}
    function Builder:AddLine(text, color, _, wrap)
        if type(text) ~= "string" then error("AddLine: text is a " .. type(text)) end
        if type(color) ~= "table" then error("AddLine: no colour") end
        if self.lines == 0 then self.tooltip.lines = {} end
        if self.spaceBeforeNextLine and self.lines > 0 then
            self.tooltip.lines[#self.tooltip.lines + 1] = ""
            self.lines = self.lines + 1
        end
        self.spaceBeforeNextLine = false
        self.tooltip.lines[#self.tooltip.lines + 1] = text
        self.lines = self.lines + 1
    end
    function Builder:AddSpace() self.spaceBeforeNextLine = true end
    function Builder:Build() self.tooltip:Show(); self.lines = 0 end
    local builderMT = { __index = Builder }
    local made = 0
    function API.ui.tooltip.createTooltipBuilder(owner)
        made = made + 1
        -- trp3.shape: a Total RP 3 that is built differently from the one the addon knows.
        if trp3.shape == "throws" and made > 1 then error("createTooltipBuilder changed") end
        if trp3.shape == "flat" then -- the methods on the builder itself, no prototype behind it
            local flat = { tooltip = owner, lines = 0, spaceBeforeNextLine = false }
            for key, value in pairs(Builder) do flat[key] = value end
            return flat
        end
        return setmetatable({ tooltip = owner, lines = 0, spaceBeforeNextLine = false }, builderMT)
    end
    trp3.Builder = Builder
    local colors = { MAIN = { "main" }, SECONDARY = { "secondary" }, TITLE = { "title" } }
    function API.ui.tooltip.getTooltipTextColors() return colors end
    function API.ui.tooltip.getSubLineFontSize() return 12 end
    function API.ui.tooltip.getSmallLineFontSize() return 10 end
    local builder = API.ui.tooltip.createTooltipBuilder(tooltip)
    -- The blocks of the character tooltip: name, details, "currently", OOC, the rest.
    local function show(unit, targetID, targetMode)
        tooltip:Hide()
        if not targetID then return end
        tooltip.target, tooltip.targetType, tooltip.targetMode = targetID, unit, targetMode
        builder:AddLine(targetID:match("^[^-]+"), colors.MAIN, 16)
        builder:AddSpace()
        builder:AddLine("Realm: " .. targetID:match("-(.+)$"), colors.MAIN, 12)
        builder:AddSpace()
        builder:AddLine("Currently", colors.MAIN, 12)
        builder:AddSpace()
        if trp3.shape ~= "short" then -- "short": a tooltip with fewer blocks than the addon counts on
            builder:AddLine("OOC", colors.MAIN, 12)
            builder:AddSpace()
            builder:AddLine("Pronouns: they", colors.MAIN, 12)
            builder:AddSpace()
        end
        builder:AddLine("Click for the profile", colors.MAIN, 10)
        builder:Build()
    end
    API.RegisterCallback(Addon, Addon.Events.MOUSE_OVER_CHANGED, function(_, targetID, targetMode, unit) show(unit, targetID, targetMode) end)
    trp3.show, trp3.API = show, API
    if trp3.shape == "bare" then API.ui = nil end -- no tooltip part at all
    env.TRP3_API, env.TRP3_Addon = API, Addon
end

---------------------------------------------------------------------------
-- A client: logging in and out
---------------------------------------------------------------------------
local function Deep(value, path, seen)
    local kind = type(value)
    if kind ~= "table" then
        if kind == "function" or kind == "userdata" or kind == "thread" then Check(false, "saved data holds a " .. kind .. " at " .. path) return nil end
        return value
    end
    if BASE.IsStub(value) then Check(false, "saved data holds a stand-in at " .. path) return nil end
    seen = seen or {}
    if seen[value] then Check(false, "saved data holds a table twice at " .. path) return nil end
    seen[value] = true
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Deep(inner, path .. "." .. tostring(key), seen) end
    seen[value] = nil
    return copy
end

local function FakeLibs(client)
    local LibStub = client.env.LibStub
    local function fake(name, members)
        local lib = LibStub:NewLibrary(name, 1)
        for key, value in pairs(members) do lib[key] = value end
        return lib
    end
    local Registry = LibStub("AceConfigRegistry-3.0")
    fake("AceConfig-3.0", { RegisterOptionsTable = function(_, app, options) Registry:RegisterOptionsTable(app, options) end })
    fake("AceConfigDialog-3.0", {
        Open = function(_, app) client.opened[app] = true end, Close = function(_, app) client.opened[app] = nil end,
        SetDefaultSize = function() end, AddToBlizOptions = function() return BASE.STUB("blizpanel") end, SelectGroup = function() end,
        OpenFrames = {}, BlizOptions = {},
    })
    fake("AceGUI-3.0", {
        RegisterWidgetType = function() end, RegisterAsWidget = function(_, w) return w end, RegisterAsContainer = function(_, w) return w end,
        GetWidgetVersion = function() return 0 end, GetNextWidgetNum = function() return 1 end,
        Create = function(_, kind) return BASE.STUB("AceGUI:" .. kind) end, Release = function() end,
        RegisterLayout = function() end, WidgetRegistry = {}, WidgetVersions = {}, LayoutRegistry = {},
    })
    fake("LibDBIcon-1.0", { Register = function() end, Show = function() end, Hide = function() end, Refresh = function() end })
    fake("LibDataBroker-1.1", { NewDataObject = function(_, _, object) return object end })
    fake("LibSharedMedia-3.0", { Fetch = function() return "font" end, Register = function() end, HashTable = function() return {} end,
        List = function() return {} end, RegisterCallback = function() end,
        MediaType = { FONT = "font", STATUSBAR = "statusbar", BACKGROUND = "background", BORDER = "border", SOUND = "sound" } })
end

-- Loads the libraries and the addon and logs the character in. opts.realmLate: the
-- realm's name isn't known until Client:RealmKnown() (as for a moment after login).
function Client:Login(opts)
    opts = opts or {}
    self.frames, self.timers, self.filters, self.prefixes, self.buckets = {}, {}, {}, {}, {}
    self.errors, self.chat, self.system, self.said, self.refused, self.opened, self.rolls = {}, {}, {}, {}, {}, {}, {}
    self.throttled, self.loggedIn, self.realmKnown = 0, false, not opts.realmLate
    self.env = BuildEnv(self)
    self.env.RPSheetDB = self.saved
    if self.trp3 then InstallTRP3(self) end
    for _, path in ipairs(LIB_FILES) do
        Chunk(libRoot .. "/" .. path, self.env)(path, {})
    end
    FakeLibs(self)
    self.ns = {}
    for _, file in ipairs(ADDON_FILES) do
        local ok, problem = xpcall(function() Chunk(ROOT .. "/" .. file, self.env)("RPSheet", self.ns) end,
            function(m) return debug.traceback(m, 2) end)
        if not ok then Check(false, ("%s: load error in %s: %s"):format(self.full, file, tostring(problem):sub(1, 600))) end
    end
    self.addon = self.ns.addon
    self.online = true
    self:Fire("ADDON_LOADED", "RPSheet")
    -- Nothing is drawn here: the sheet window is left out, as in sim.lua, ...
    self.addon.BuildWindow = function() end
    self.addon.BuildMinimapIcon = function() end
    self.loggedIn = true
    self:Fire("PLAYER_LOGIN")
    self:Fire("PLAYER_ENTERING_WORLD", true, false)
    -- ... but the addon is told it has one that is closed, so that Refresh takes the
    -- path it takes in the game when the sheet is hidden (which ends in a broadcast).
    if not opts.noWindow then
        self.addon.window = setmetatable({ frame = { IsShown = function() return false end } },
            { __index = function() return function() end end })
        self.addon.body = BASE.STUB("body")
        self.addon.channelLabel = BASE.STUB("channelLabel")
        self.addon.populateSkipped = true
    end
    return self
end

function Client:RealmKnown() self.realmKnown = true end

-- The sheet window open: every rebuild of its rows ends in a Refresh, and what a
-- Refresh does towards other players is asking for a broadcast. (The rows themselves
-- can't be made here.)
function Client:OpenSheet()
    local addon = self.addon
    local populate = addon.Populate
    addon.Populate = function(this) populate(this); this:QueueBroadcast() end
    addon.Refresh = function(this) this:QueueBroadcast() end
    return self
end

-- A player without the addon: online, but nothing is loaded and nothing is heard.
function Client:Bare()
    self.frames, self.timers, self.filters, self.prefixes, self.buckets = {}, {}, {}, {}, {}
    self.errors, self.chat, self.system, self.said, self.refused, self.opened, self.rolls = {}, {}, {}, {}, {}, {}, {}
    self.throttled, self.online, self.unknown = 0, true, {}
    return self
end

-- Logs out; what the game would write to disk is kept for the next login.
function Client:Logout()
    self:Fire("PLAYER_LOGOUT")
    self.online, self.loggedIn = false, false
    self.saved = Deep(rawget(self.env, "RPSheetDB"), "RPSheetDB")
    for _, other in ipairs(self.world.clients) do
        for unit, who in pairs(other.units) do if who == self then other.units[unit] = nil end end
    end
    return self.saved
end

function Client:Reload(opts)
    self:Logout()
    return self:Login(opts)
end

-- An event of the game, to every frame of this client that listens for it.
function Client:Fire(event, ...)
    if event:find("^CHAT_MSG_") and event ~= "CHAT_MSG_ADDON" and event ~= "CHAT_MSG_SYSTEM" then self:ShowChat(event, ...) end
    for _, frame in ipairs(self.frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            local ok, problem = xpcall(frame.scripts.OnEvent, function(m) return debug.traceback(tostring(m), 2) end, frame, event, ...)
            if not ok then self.errors[#self.errors + 1] = tostring(problem) end
        end
    end
end

-- A chat line goes through the filters addons registered, then into the chat frame.
function Client:ShowChat(event, text, author, ...)
    local rest = { ... }
    for _, filter in ipairs(self.filters[event] or {}) do
        local results = { xpcall(filter, function(m) return debug.traceback(tostring(m), 2) end, self.env.ChatFrame1, event, text, author, unpack(rest) ) }
        if not results[1] then self.errors[#self.errors + 1] = tostring(results[2])
        elseif results[2] == true then return
        elseif results[3] ~= nil then text, author = results[3], results[4] end
    end
    self.chat[#self.chat + 1] = { event = event, text = text, author = author }
end

function Client:Tick(elapsed)
    local now = self.world.now
    table.sort(self.timers, function(a, b) if a.due ~= b.due then return a.due < b.due end return a.seq < b.seq end)
    local guard = 0
    while self.timers[1] and self.timers[1].due <= now + 1e-9 and guard < 1000 do
        local timer = table.remove(self.timers, 1)
        guard = guard + 1
        if not timer.cancelled then
            local ok, problem = xpcall(timer.fn, function(m) return debug.traceback(tostring(m), 2) end)
            if not ok then self.errors[#self.errors + 1] = tostring(problem) end
        end
    end
    for _, frame in ipairs(self.frames) do
        if frame.shown and frame.scripts.OnUpdate then
            local ok, problem = xpcall(frame.scripts.OnUpdate, function(m) return debug.traceback(tostring(m), 2) end, frame, elapsed)
            if not ok then self.errors[#self.errors + 1] = tostring(problem) end
        end
    end
end

---------------------------------------------------------------------------
-- A client: what the player does
---------------------------------------------------------------------------
-- Runs a function the way the game runs a click: an error goes to the error handler.
function Client:Do(fn, ...)
    local results = { xpcall(fn, function(m) return debug.traceback(tostring(m), 2) end, ...) }
    if not results[1] then self.errors[#self.errors + 1] = tostring(results[2]) return end
    return unpack(results, 2)
end

-- Types a slash command, e.g. client:Slash("/sheet damage 5 fire").
function Client:Slash(line)
    local command, rest = line:match("^(/%S+)%s*(.*)$")
    for name, handler in pairs(self.env.SlashCmdList) do
        local index = 1
        while rawget(self.env, "SLASH_" .. name .. index) do
            if rawget(self.env, "SLASH_" .. name .. index) == command:lower() then
                self:Do(handler, rest, self.env.ChatFrame1.editBox)
                return true
            end
            index = index + 1
        end
    end
    return false
end

-- Moves the mouse over another client's character (or away, with nil). `quiet` only
-- has Total RP 3 show its tooltip: the addon isn't told, so it asks nothing.
function Client:Hover(other, quiet)
    self.units.mouseover = other
    if not other then
        if self.trp3 then self.env.TRP3_CharacterTooltip:Hide() end
        return
    end
    if not quiet then self:Fire("UPDATE_MOUSEOVER_UNIT") end
    if self.trp3 then
        self:Do(function() self.env.TRP3_Addon:TriggerEvent("MOUSE_OVER_CHANGED", other.full, "CHARACTER", "mouseover") end)
    end
end

function Client:Target(other)
    self.units.target = other
    self:Fire("PLAYER_TARGET_CHANGED")
end

-- The lines of the Total RP 3 tooltip that is showing, or nil.
function Client:Tooltip()
    local tooltip = rawget(self.env, "TRP3_CharacterTooltip")
    if tooltip and tooltip.shown then return tooltip.lines end
end

-- The "Stats" section of that tooltip: the lines after its title up to the next gap.
function Client:TooltipStats()
    local lines, out = self:Tooltip(), nil
    for _, line in ipairs(lines or {}) do
        if out then
            if line == "" then break end
            out[#out + 1] = line
        elseif line == "Stats" then
            out = {}
        end
    end
    return out
end

-- The links of a chat line: { link, text } pairs.
function Links(text)
    local list = {}
    for link, label in text:gmatch("|H(.-)|h(.-)|h") do list[#list + 1] = { link = link, text = label } end
    return list
end
function Client:ClickLink(link) self:Do(self.env.SetItemRef, link, "", "LeftButton", self.env.ChatFrame1) end
function Client:HoverLink(link)
    self:Do(function() self.env.ChatFrame1:Run("OnHyperlinkEnter", link, "") end)
    return self.env.GameTooltip.lines
end

-- A character on this client's sheet, as Build in t-test-play-lib.lua makes one.
function Client:Build(key, subclass, level, opts)
    opts = opts or {}
    local ns, R, addon = self.ns, self.ns.Rules, self.addon
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    local class = R.CLASSES[key]
    sheet.class, sheet.subclass, sheet.level = key, subclass or "", level
    sheet.spec = opts.spec or class.specs[1] or ""
    sheet.species = opts.species or "HUMAN"
    if not R.SPECIES[sheet.species] then sheet.species = R.SPECIES_ORDER[1] end
    sheet.background = opts.background or R.BACKGROUND_ORDER[1]
    sheet.allegiance = R.ALLEGIANCE_ORDER[1]
    sheet.lineage, sheet.alignment = opts.lineage or "", opts.alignment or ""
    sheet.base = opts.base or { STR = 14, DEX = 14, CON = 14, INT = 14, WIS = 14, CHA = 14 }
    for index = 1, class.skillCount do sheet.skills[class.skills[index]] = 1 end
    for _, extra in ipairs(opts.extras or {}) do
        sheet.classes[extra.class] = { level = extra.level, subclass = extra.subclass or "", spec = R.CLASSES[extra.class].specs[1] or "", skill = "" }
    end
    if opts.setup then opts.setup(sheet) end
    ns.ApplyGrants(sheet)
    addon:ReplaceSheet(sheet)
    addon.busy, addon.rollMode, addon.rollModeLocked, addon.castLevel = false, nil, false, nil
    return addon:Sheet()
end

-- No client may have raised a Lua error or read a global the fake game lacks in a
-- way that matters; call at the end of a script.
function World:CheckClean(label)
    for _, client in ipairs(self.clients) do
        for index, problem in ipairs(client.errors or {}) do
            if index <= 3 then Check(false, ("[%s] %s raised an error: %s"):format(label, client.full, problem:sub(1, 900))) end
        end
        client.errors = {}
    end
end

-- Text that came from another player and is shown as it is: no escape codes, no
-- control characters, not endless.
function Plain(text, limit)
    return type(text) == "string" and not text:find("|", 1, true) and not text:find("%c") and #text <= (limit or 200) and ValidUTF8(text)
end

-- Run by itself (run-all.sh does), this file only says that it is a library.
if not rawget(BASE, "SYNC_SCRIPT") then print("t-sync-clients: a library for the t-sync-*.lua scripts, 0 checks, 0 problems") end
