-- Fake WoW environment for loading the addon outside the game.
local ROOT = ARG1           -- worktree
local LIBS = ARG2           -- folder with Libs
unpack = unpack or table.unpack
STRICT_GLOBALS, TRACK_WRITES, CURRENT_FILE = false, false, false
LOG = { globalsRead = {}, globalsWritten = {}, errors = {} }

local stubMT = {}
local function Stub(name)
    return setmetatable({ __stub = name }, stubMT)
end
STUB = Stub
stubMT.__index = function(t, k)
    local s = Stub(rawget(t, "__stub") .. "." .. tostring(k)); rawset(t, k, s); return s
end
stubMT.__call = function(t, ...) return Stub(rawget(t, "__stub") .. "()") end
stubMT.__tostring = function(t) return "<stub " .. rawget(t, "__stub") .. ">" end
stubMT.__concat = function(a, b) return tostring(a) .. tostring(b) end
local function num(v) return type(v) == "number" and v or 0 end
stubMT.__add = function(a, b) return num(a) + num(b) end
stubMT.__sub = function(a, b) return num(a) - num(b) end
stubMT.__mul = function(a, b) return num(a) * num(b) end
stubMT.__div = function(a, b) return 0 end
stubMT.__unm = function() return 0 end
stubMT.__lt = function() return false end
stubMT.__le = function() return false end
function IsStub(v) return type(v) == "table" and getmetatable(v) == stubMT end

dofile(ARG3 .. "/strict.lua")
-- string helpers
strtrim = function(s, chars) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
string.trim = strtrim
strlenutf8 = function(s) return #tostring(s) end
strsplit = function(sep, s, limit)
    local out, start = {}, 1
    while true do
        local i = s:find(sep, start, true)
        if not i or (limit and #out + 1 >= limit) then out[#out + 1] = s:sub(start); break end
        out[#out + 1] = s:sub(start, i - 1); start = i + #sep
    end
    return unpack(out)
end
string.split = strsplit
strjoin = function(sep, ...) return table.concat({ ... }, sep) end
string.join = strjoin
strsub, strlen, strfind, strmatch, strlower, strupper, strrep, strbyte, strchar, gsub, format, gmatch =
    string.sub, string.len, string.find, string.match, string.lower, string.upper, string.rep, string.byte, string.char, string.gsub, string.format, string.gmatch
strconcat = function(...) return table.concat({ ... }) end
tinsert, tremove, tconcat, sort = table.insert, table.remove, table.concat, table.sort
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
table.wipe = wipe
tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
function CopyTable(t, shallow)
    local c = {}
    for k, v in pairs(t) do c[k] = (type(v) == "table" and not shallow) and CopyTable(v) or v end
    return c
end
function Mixin(o, ...) for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do o[k] = v end end return o end
function CreateFromMixins(...) return Mixin({}, ...) end
max, min, floor, ceil, abs, random = math.max, math.min, math.floor, math.ceil, math.abs, math.random
mod = math.fmod
function GetTime() return os.clock() end
time, date = os.time, os.date
function UnitName() return "Tester", nil end
function GetNormalizedRealmName() return "Realm" end
function GetRealmName() return "Realm" end
function InCombatLockdown() return false end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function geterrorhandler() return function(e) LOG.errors[#LOG.errors + 1] = tostring(e) end end
function securecallfunction(f, ...) return f(...) end
function hooksecurefunc() end
function issecurevariable() return true end
function GetLocale() return "enUS" end
function GetBuildInfo() return "12.0.0", "1", "x", 120000 end
function PlaySound() end
function IsInGroup() return false end
function IsInRaid() return false end
function IsInGuild() return false end
function GetCVar() return "1" end
function debugstack() return "" end
function debugprofilestop() return 0 end
function tostringall(...) local t = { ... } for i = 1, select("#", ...) do t[i] = tostring(t[i]) end return unpack(t, 1, select("#", ...)) end
CHAT = {}
function SendChatMessage(msg, kind) CHAT[#CHAT + 1] = msg end
TIMERS = {}
C_Timer = { After = function(sec, fn) TIMERS[#TIMERS + 1] = fn end, NewTimer = function(sec, fn) TIMERS[#TIMERS + 1] = fn return { Cancel = function() end } end,
    NewTicker = function() return { Cancel = function() end } end }
function FlushTimers()
    local n = 0
    while #TIMERS > 0 and n < 1000 do local fn = table.remove(TIMERS, 1); fn(); n = n + 1 end
end
bit = bit or require("bit")
StaticPopupDialogs = {}
SlashCmdList = {}
UISpecialFrames = {}
SOUNDKIT = setmetatable({}, { __index = function() return 1 end })
local NILS = { issecretvalue = true, TRP3_API = true, TRP3_Addon = true, ElvUI = true, AddOnSkins = true, LibStub = true, ChatThrottleLib = true,
    AceGUIWidgetLSMlists = true, LOCALE_koKR = true, LOCALE_zhCN = true, LOCALE_zhTW = true, LOCALE_ruRU = true }
setmetatable(_G, {
    __index = function(t, k)
        if NILS[k] then return nil end
        LOG.globalsRead[k] = (LOG.globalsRead[k] or 0) + 1
        if rawget(_G, "STRICT_GLOBALS") then return nil end
        local s = Stub(k); return s
    end,
    __newindex = function(t, k, v)
        if rawget(_G, "TRACK_WRITES") then LOG.globalsWritten[k] = rawget(_G, "CURRENT_FILE") or "?" end
        rawset(t, k, v)
    end,
})

-- real LibStub, CallbackHandler, AceConfigRegistry
local function loadReal(path, ...)
    local f, e = loadfile(LIBS .. "/" .. path)
    if not f then error(e) end
    return f(...)
end
loadReal("LibStub.lua")
loadReal("CallbackHandler-1.0.lua")
loadReal("AceConfigRegistry-3.0.lua")
local Registry = LibStub("AceConfigRegistry-3.0")
REGISTRY = Registry

local function fake(name, tbl) local lib = LibStub:NewLibrary(name, 1); for k, v in pairs(tbl) do lib[k] = v end return lib end
PRINTED, COMM = {}, {}
fake("AceAddon-3.0", { NewAddon = function(self, name, ...)
    local a = { name = name }
    function a:Print(...) PRINTED[#PRINTED + 1] = table.concat({ tostringall(...) }, " ") end
    function a:RegisterChatCommand() end
    function a:RegisterEvent() end
    function a:UnregisterEvent() end
    function a:RegisterComm() end
    function a:SendCommMessage(prefix, text, kind, target) COMM[#COMM + 1] = { prefix, text, kind, target } end
    function a:RegisterMessage() end
    function a:SendMessage() end
    ADDON_OBJ = a
    return a
end })
fake("AceConfig-3.0", { RegisterOptionsTable = function(self, app, options) Registry:RegisterOptionsTable(app, options) end })
OPENED = {}
fake("AceConfigDialog-3.0", {
    Open = function(self, app) OPENED[app] = true end, Close = function(self, app) OPENED[app] = nil end,
    SetDefaultSize = function() end, AddToBlizOptions = function() return Stub("blizpanel") end, SelectGroup = function() end,
    OpenFrames = {}, BlizOptions = {},
})
local function deep(t) return CopyTable(t) end
fake("AceDB-3.0", { New = function(self, name, defaults)
    local db = { global = {}, profile = {}, char = {} }
    for k, v in pairs(defaults.global or {}) do db.global[k] = type(v) == "table" and deep(v) or v end
    for k, v in pairs(defaults.profile or {}) do db.profile[k] = type(v) == "table" and deep(v) or v end
    for k, v in pairs(defaults.char or {}) do db.char[k] = type(v) == "table" and deep(v) or v end
    local star = defaults.global and defaults.global.sheets and defaults.global.sheets["*"]
    if star then
        db.global.sheets["*"] = nil
        setmetatable(db.global.sheets, { __index = function(t, k) local v = deep(star); rawset(t, k, v); return v end })
    end
    db.RegisterCallback = function() end
    function db:GetCurrentProfile() return "Default" end
    return db
end })
fake("AceDBOptions-3.0", { GetOptionsTable = function() return { type = "group", name = "Profiles", args = {} } end })
WIDGET_TYPES = {}
fake("AceGUI-3.0", {
    RegisterWidgetType = function(self, name, ctor, version) WIDGET_TYPES[name] = ctor end,
    RegisterAsWidget = function(self, w) return w end, RegisterAsContainer = function(self, w) return w end,
    GetWidgetVersion = function() return 0 end, GetNextWidgetNum = function() return 1 end,
    Create = function(self, kind) return Stub("AceGUI:" .. kind) end, Release = function() end,
    RegisterLayout = function() end, WidgetRegistry = {}, WidgetVersions = {}, LayoutRegistry = {},
})
fake("LibDBIcon-1.0", { Register = function() end, Show = function() end, Hide = function() end, Refresh = function() end })
fake("LibDataBroker-1.1", { NewDataObject = function(self, n, o) return o end })
do
    local lib = LibStub:NewLibrary("LibDeflate", 1)
    for _, name in ipairs({ "CompressDeflate", "DecompressDeflate", "EncodeForPrint", "DecodeForPrint", "EncodeForWoWAddonChannel", "DecodeForWoWAddonChannel" }) do
        lib[name] = function(self, s) return s end
    end
end
fake("LibSerialize", { Serialize = function(self, t) SER = t; return "SER" end, Deserialize = function(self, s) return true, SER end })
fake("LibSharedMedia-3.0", { Fetch = function() return "font" end, Register = function() end, HashTable = function() return {} end, List = function() return {} end,
    MediaType = { FONT = "font", STATUSBAR = "statusbar", BACKGROUND = "background", BORDER = "border", SOUND = "sound" }, RegisterCallback = function() end })

-- loading the addon
NS = {}
function LoadAddon(hook)
    local files = {}
    for line in io.lines(ROOT .. "/RPSheet.toc") do
        line = line:gsub("\r", "")
        if line:match("%.lua$") and not line:match("^Libs") and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
    end
    TRACK_WRITES = true
    for _, file in ipairs(files) do
        CURRENT_FILE = file
        local f, e = loadfile(ROOT .. "/" .. file)
        if not f then print("SYNTAX " .. file .. ": " .. e)
        else
            local ok, err = xpcall(function() f("RPSheet", NS) end, function(m) return debug.traceback(m, 2) end)
            if not ok then print("LOAD ERROR in " .. file .. ":\n  " .. tostring(err):gsub("\n", "\n  ")) end
        end
        if hook then hook(file) end
    end
    CURRENT_FILE = nil
    TRACK_WRITES = false
    -- Every number the addon keeps for the length of one rebuild of the sheet window is
    -- worked out again when it is asked for a second time, and must be the same
    -- (Sheet/PassCache.lua).
    NS.checkPass = true
    return files
end
