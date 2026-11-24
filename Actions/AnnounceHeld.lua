-- Announcements the game wouldn't let into chat. Some games (WoW Forever) let an addon
-- speak in chat only straight from a click (Core/Game.lua). A line made outside one -
-- the Constitution save after damage, which waits for the clicking to stop - is shown
-- to the player alone with a [Send it] link; clicking the link is a click, so the game
-- lets the line through then. Nothing is lost without a word.
local ADDON, ns = ...
local RPSheet = ns.addon

local LINK = "addon:rpsheet-send"
local held = {}    -- [number] = { parts = { chat lines }, chatType = "EMOTE" }
local count = 0
local sending, blocked = false, false

local function Send(part, chatType)
    sending, blocked = true, false
    local ok = pcall(C_ChatInfo.SendChatMessage or SendChatMessage, part, chatType)
    sending = false
    return ok and not blocked
end

-- Sends the parts in turn; the number of the first one the game refused, or nil.
local function SendParts(parts, chatType, from)
    for index = from or 1, #parts do
        if not Send(parts[index], chatType) then return index end
    end
end

local function Hold(parts, chatType, shown)
    count = count + 1
    held[count] = { parts = parts, chatType = chatType }
    RPSheet:Print(("%s |cff999999(only you see this: the game lets addons speak in chat only straight from a click)|r |H%s:%d|h|cff71d5ff[Send it]|r|h")
        :format(ns.LinkTerms(shown, ns.PlayerFullName()), LINK, count))
end

-- Runs `fn` for something that doesn't come from a click (a timer): where the game
-- needs one, its announcements are held for one at once instead of being refused.
function RPSheet:OutsideClick(fn, ...)
    self.outsideClick = true
    local ok, problem = pcall(fn, ...)
    self.outsideClick = nil
    if not ok then error(problem, 0) end
end

-- Puts the chat lines of one announcement out. `shown` is the whole line as the player
-- reads it, for when it is held.
function RPSheet:SendAnnouncement(parts, chatType, shown)
    if self.outsideClick and ns.Game.ChatNeedsClick() then
        Hold(parts, chatType, shown)
        return
    end
    local refused = SendParts(parts, chatType)
    if refused then
        ns.Game.ChatRefused()
        local rest = {}
        for index = refused, #parts do rest[#rest + 1] = parts[index] end
        Hold(rest, chatType, shown)
    end
end

-- The game tells every addon when it refused one of them; ours, while sending, is
-- the line just tried.
function ns.WatchRefusedChat(addon)
    local function Refused(_, name)
        if sending and name == ADDON then blocked = true end
    end
    addon:RegisterEvent("ADDON_ACTION_BLOCKED", Refused)
    addon:RegisterEvent("ADDON_ACTION_FORBIDDEN", Refused)
    hooksecurefunc("SetItemRef", function(link)
        local id = type(link) == "string" and tonumber(link:match("^" .. LINK:gsub("%-", "%%-") .. ":(%d+)$"))
        local line = id and held[id]
        if not line then return end
        local refused = SendParts(line.parts, line.chatType)
        if refused then
            RPSheet:Print("The game refused it again.")
        else
            held[id] = nil
        end
    end)
end
