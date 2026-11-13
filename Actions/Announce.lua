-- Tells people what the character did, on the channel chosen in the settings.
local _, ns = ...
local RPSheet = ns.addon

ns.CHANNELS = { "EMOTE", "PARTY", "RAID", "SELF" }
ns.CHANNEL_LABEL = { EMOTE = "Emote", PARTY = "Party", RAID = "Raid", SELF = "Self only" }

-- `text` reads as a continuation of the character's name: "rolls Stealth: 14 + 5 = 19".
function RPSheet:Announce(text)
    local channel = self.db.profile.channel
    if (channel == "PARTY" and not IsInGroup()) or (channel == "RAID" and not IsInRaid()) then
        channel = "SELF"
    end
    if channel ~= "SELF" and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        channel = "SELF"
    end
    if channel == "SELF" then
        self:Print(self:GetCharacterName() .. " " .. text)
        return
    end
    -- Emotes are already prefixed with the character's name by the game.
    local msg = channel == "EMOTE" and text or (self:GetCharacterName() .. " " .. text)
    if #msg > 250 then msg = msg:sub(1, 247) .. "..." end
    local send = C_ChatInfo.SendChatMessage or SendChatMessage
    send(msg, channel)
end

-- Switches to the next announce channel.
function RPSheet:CycleChannel()
    local profile = self.db.profile
    for i, name in ipairs(ns.CHANNELS) do
        if name == profile.channel then
            profile.channel = ns.CHANNELS[i % #ns.CHANNELS + 1]
            break
        end
    end
    self:Refresh()
end
