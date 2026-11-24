-- Rule terms in chat that can be hovered and clicked.
--
-- The game doesn't let an addon send its own links through chat, so announcements
-- carry a term in plain square brackets, such as "[Vex]" or "attacks with [Rapier]".
-- Each player's own copy of the addon turns those into links when the line is shown.
-- Without the addon the brackets are simply text.
--
--   hover  what the term means, from the rules data everyone with the addon has
--   click  the maths behind it: your own at once, another player's by asking their
--          addon (see Integrations/Sync.lua)
--
-- A link reads  |Haddon:rpsheet:<player key>:<term>|h[term]|h (the key: Core/Game.lua). The "addon:" link
-- type is one the game leaves for addons to handle.
local _, ns = ...
local RPSheet = ns.addon

local LINK = "addon:rpsheet"
local COLOR = "|cff71d5ff"

-- Puts a term in the plain form that gets linked. Used when announcing.
function ns.Mark(term)
    return "[" .. term .. "]"
end

-- The player's key (Core/Game.lua), which links and shared stats are told apart by.
function ns.PlayerFullName()
    return ns.Game.UnitKey("player") or ""
end

-- (What a term means, for its tooltip: ns.TermInfo in Integrations/ChatTerms.lua.)

---------------------------------------------------------------------------
-- Turning marked terms into links
---------------------------------------------------------------------------
-- Lines the addon itself announces start with one of these after the character's name.
-- The rest of a line that took more than one message starts with the mark of that
-- (Actions/AnnounceSplit.lua).
local OURS = { "rolls %[", "attacks with %[", "uses %[", "casts %[", "is now %[", "is no longer %[", "%(continued%) " }

-- Links every marked term in `text` that the rules data knows; in a line that reads
-- like one of ours, the others too (a player's own ability can be asked about).
function ns.LinkTerms(text, sender)
    local ours = false
    for _, pattern in ipairs(OURS) do
        ours = ours or text:find(pattern) ~= nil
    end
    return (text:gsub("()%[([^%[%]|]+)%]", function(at, term)
        -- The name inside a link the game made (an item, a spell) is that link's.
        if text:sub(at - 2, at - 1) == "|h" then return end
        if ours or ns.TermInfo(term) then
            return ("|H%s:%s:%s|h%s[%s]|r|h"):format(LINK, sender, term, COLOR, term)
        end
    end))
end

-- Sender and term of one of our links, or nil.
local function ParseLink(link)
    if type(link) ~= "string" or link:sub(1, #LINK + 1) ~= LINK .. ":" then return end
    return link:sub(#LINK + 2):match("^([^:]+):(.+)$")
end

local function Filter(_, _, message, author, ...)
    -- In some places the game hides chat text from addons; such lines are left alone.
    if issecretvalue and (issecretvalue(message) or issecretvalue(author)) then return false end
    if type(message) ~= "string" or type(author) ~= "string" or not message:find("[", 1, true) then return false end
    local key = ns.Game.SenderKey(author)
    if not key then return false end
    local linked = ns.LinkTerms(message, key)
    if linked == message then return false end
    return false, linked, author, ...
end

---------------------------------------------------------------------------
-- Hovering and clicking
---------------------------------------------------------------------------
local function OnEnter(frame, link)
    local sender, term = ParseLink(link)
    if not term then return end
    local title, lines = ns.TermInfo(term)
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    GameTooltip:AddLine(title or term)
    for _, line in ipairs(lines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
    local mine = sender == ns.PlayerFullName()
    GameTooltip:AddLine(mine and "Click to see how your number is worked out."
        or ("Click to ask %s's sheet about it."):format(ns.Game.ShortName(sender)), 0.56, 0.56, 0.56, true)
    GameTooltip:Show()
    frame.rpSheetLinkTooltip = true
end

local function OnLeave(frame)
    if frame.rpSheetLinkTooltip then
        frame.rpSheetLinkTooltip = nil
        GameTooltip:Hide()
    end
end

-- Plain lines for a term nothing can be worked out for.
local function PrintInfo(term)
    local title, lines = ns.TermInfo(term)
    if title then RPSheet:Print(("%s: %s"):format(title, table.concat(lines, " "))) end
    return title ~= nil
end

local function OnClick(link)
    local sender, term = ParseLink(link)
    if not term or IsModifiedClick("CHATLINK") then return end
    if sender == ns.PlayerFullName() then
        local text = RPSheet:ExplainTerm(term)
        if text then RPSheet:Print(text) elseif not PrintInfo(term) then
            RPSheet:Print(("Nothing more is known about %s."):format(term))
        end
    elseif not RPSheet:RequestExplanation(sender, term) then
        -- Couldn't ask (another faction, or sharing is off): show what the rules say.
        if not PrintInfo(term) then RPSheet:Print(("Couldn't ask %s about %s."):format(ns.Game.ShortName(sender), term)) end
    end
end

function ns.EnableChatLinks()
    -- The game has moved this function; without either, the terms simply stay plain text.
    local addFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
    for _, event in ipairs({ "CHAT_MSG_EMOTE", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" }) do
        if addFilter then addFilter(event, Filter) end
    end
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then
            pcall(frame.HookScript, frame, "OnHyperlinkEnter", OnEnter)
            pcall(frame.HookScript, frame, "OnHyperlinkLeave", OnLeave)
        end
    end
    hooksecurefunc("SetItemRef", function(link) pcall(OnClick, link) end)
end
