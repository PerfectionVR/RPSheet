-- Combat sessions, part 13: the fight's log, for the combat window to show. It holds
-- what the session's owner announced since this client knew of the session: on the
-- owner's client every line as it is said, on a player's client the owner's lines as
-- they arrive in chat. It is kept in memory only, and starts empty with each session.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local MAX = 60
F.log = {}
local logFor

-- Chat a session's owner can announce in.
local EVENTS = {
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_SAY", "CHAT_MSG_EMOTE",
}

function F.Log(text)
    local session = F.session
    if not session or type(text) ~= "string" or text == "" then return end
    if logFor ~= session.id then
        wipe(F.log)
        logFor = session.id
    end
    F.log[#F.log + 1] = text
    if #F.log > MAX then table.remove(F.log, 1) end
    if F.OnChange then F.OnChange() end
end

-- The log of the session this client knows of now (empty for another one).
function F.LogLines()
    if not F.session or logFor ~= F.session.id then wipe(F.log) end
    return F.log
end

-- A line as the window shows it: the marks as icons, and a colour for how it went.
local RED, GREEN = "|cffff7777", "|cff80ff80"
function F.LogText(text)
    local plain = text:gsub("|", "||")
    local lower = plain:lower()
    local color = ""
    if lower:find("misses", 1, true) or lower:find("fails", 1, true) or lower:find("no damage", 1, true) then
        color = ns.UI.GREY
    elseif lower:find("regains", 1, true) or lower:find("succeeds", 1, true) or lower:find("back up", 1, true) then
        color = GREEN
    elseif lower:find("hits ", 1, true) or lower:find("critical hit", 1, true) or lower:find("takes %d") or lower:find("drops to 0", 1, true) then
        color = RED
    elseif lower:find("'s turn", 1, true) or lower:find("^round %d") then
        color = ns.UI.ACCENT
    end
    for index, mark in ipairs(F.MARKS) do
        plain = plain:gsub(mark.code, function() return F.MarkIcon(index) end)
    end
    return color ~= "" and (color .. plain .. "|r") or plain
end

-- The owner's own lines: everything the session says goes out with a speaker.
local Announce = RPSheet.Announce
function RPSheet:Announce(text, speaker)
    if speaker ~= nil and F.session and F.IsOwner() and type(text) == "string" then
        local name = type(speaker) == "string" and speaker or ""
        F.Log(name ~= "" and (name .. " " .. text) or text)
    end
    return Announce(self, text, speaker)
end

-- A player's client: what the owner says in chat while the session runs.
local function Heard(_, text, sender)
    local session = F.session
    if not session or F.IsOwner() then return end
    if type(text) ~= "string" or type(sender) ~= "string" then return end
    if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
    local ok, key = pcall(ns.Game.SenderKey, sender)
    if ok and key == session.owner then F.Log(text) end
end

local EnableFight = RPSheet.EnableFight
function RPSheet:EnableFight()
    EnableFight(self)
    for _, event in ipairs(EVENTS) do
        pcall(self.RegisterEvent, self, event, Heard)
    end
end
