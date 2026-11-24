-- Tells people what the character did, on the channel chosen in the settings.
local _, ns = ...
local RPSheet = ns.addon

ns.CHANNELS = { "EMOTE", "PARTY", "RAID", "SELF" }
ns.CHANNEL_LABEL = { EMOTE = "Emote", PARTY = "Party", RAID = "Raid", SELF = "Self only" }

local MAX_CHAT = 250 -- bytes of one chat message (the game takes 255)
local MAX_PARTS = 4  -- messages one announcement may take
local MAX_NAME = 60  -- bytes of the name in front of a party or raid line

-- A saved channel that is none of ours (the saved settings edited by hand) counts as
-- "Self only": nothing is sent anywhere, and the sheet says so.
local function Known(channel)
    return ns.CHANNEL_LABEL[channel] and channel or "SELF"
end

function ns.ChannelLabel(channel)
    return ns.CHANNEL_LABEL[Known(channel)]
end

-- The chat type that reaches the chosen group: in a dungeon finder, raid finder or
-- battleground group with no party or raid of your own, its instance chat. Nil when
-- there is no such group.
local function GroupChat(channel)
    local home, instance = LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE
    if channel == "PARTY" then
        if IsInGroup(home) then return "PARTY" end
        if IsInGroup(instance) then return "INSTANCE_CHAT" end
    elseif IsInRaid(home) then
        return "RAID"
    elseif IsInRaid(instance) then
        return "INSTANCE_CHAT"
    end
end

-- `text` reads as a continuation of the character's name: "rolls Stealth: 14 + 5 = 19".
-- `speaker` is for a combat session's owner (Integrations/FightGate.lua): the name of
-- the combatant the line is about, or "" for a line that needs no name in front.
function RPSheet:Announce(text, speaker)
    local channel = Known(self.db.profile.channel)
    -- A rest can be taken back until something else is announced (Actions/RestUndo.lua).
    if ns.RestUndoExpire then ns.RestUndoExpire() end
    -- Names the player typed (the character, a weapon, an ability) can hold what chat
    -- refuses and what would read as a colour or link code: line breaks become spaces,
    -- the rest is left out.
    text = ns.Codec.PlainText((text:gsub("%c+", " ")))
    local name = ns.Codec.PlainText(((speaker or self:GetCharacterName()):gsub("%c+", " ")))
    local named = name ~= "" and (name .. " ") or ""
    -- When the chosen channel can't be used the line is shown to the player alone, with
    -- the reason, so it is never mistaken for an announcement others saw.
    local why, chatType = nil, channel
    if channel == "PARTY" or channel == "RAID" then chatType = GroupChat(channel) end
    if not chatType then
        why = channel == "PARTY" and "you are not in a party" or "you are not in a raid"
    elseif channel ~= "SELF" and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        why = "the game blocks addon chat messages right now"
    end
    if why or channel == "SELF" then
        local line = named .. text
        if why then
            line = ("%s |cff999999(only you see this: %s)|r"):format(line, why)
        end
        self:Print(ns.LinkTerms(line, ns.PlayerFullName()))
        return
    end
    -- Emotes are already prefixed with the character's name by the game.
    local lead = ns.Codec.Cut(name, MAX_NAME) .. (name ~= "" and " " or "")
    if channel == "EMOTE" then lead = speaker and ("announces: " .. lead) or "" end
    -- A line too long for one message goes out as several (Actions/AnnounceSplit.lua),
    -- each starting with the name like the first.
    local parts = {}
    for _, part in ipairs(ns.SplitChat(text, MAX_CHAT - #lead, MAX_PARTS)) do
        parts[#parts + 1] = lead .. part
    end
    -- Sent, or held for a click when the game refuses it (Actions/AnnounceHeld.lua).
    self:SendAnnouncement(parts, chatType, named .. text)
end

-- Switches to the next announce channel.
function RPSheet:CycleChannel()
    local profile = self.db.profile
    local nextChannel = ns.CHANNELS[1] -- also from a saved value that is none of them
    for i, name in ipairs(ns.CHANNELS) do
        if name == profile.channel then nextChannel = ns.CHANNELS[i % #ns.CHANNELS + 1] end
    end
    profile.channel = nextChannel
    self:Refresh()
end
