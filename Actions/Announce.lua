-- Tells people what the character did, on the channel chosen in the settings.
local _, ns = ...
local RPSheet = ns.addon

ns.CHANNELS = { "EMOTE", "PARTY", "RAID", "SELF" }
ns.CHANNEL_LABEL = { EMOTE = "Emote", PARTY = "Party", RAID = "Raid", SELF = "Self only" }

-- `text` reads as a continuation of the character's name: "rolls Stealth: 14 + 5 = 19".
function RPSheet:Announce(text)
    local channel = self.db.profile.channel
    if not ns.CHANNEL_LABEL[channel] then channel = "SELF" end -- a saved value that is none of ours
    -- Names the player typed (the character, a weapon, an ability) can hold what chat
    -- refuses and what would read as a colour or link code: line breaks become spaces,
    -- the rest is left out.
    text = ns.Codec.PlainText((text:gsub("%c+", " ")))
    local name = ns.Codec.PlainText((self:GetCharacterName():gsub("%c+", " ")))
    -- When the chosen channel can't be used the line is shown to the player alone, with
    -- the reason, so it is never mistaken for an announcement others saw.
    local why
    if channel == "PARTY" and not IsInGroup() then
        why = "you are not in a party"
    elseif channel == "RAID" and not IsInRaid() then
        why = "you are not in a raid"
    elseif channel ~= "SELF" and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        why = "the game blocks addon chat messages right now"
    end
    if why or channel == "SELF" then
        local line = name .. " " .. text
        if why then
            line = ("%s |cff999999(only you see this: %s)|r"):format(line, why)
        end
        self:Print(ns.LinkTerms(line, ns.PlayerFullName()))
        return
    end
    -- Emotes are already prefixed with the character's name by the game.
    local msg = channel == "EMOTE" and text or (name .. " " .. text)
    if #msg > 250 then msg = ns.Codec.Cut(msg, 247) .. "..." end -- (never half an accented letter)
    local send = C_ChatInfo.SendChatMessage or SendChatMessage
    send(msg, channel)
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
