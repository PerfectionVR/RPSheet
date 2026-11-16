-- Sharing stats, part 3: the "Share my stats" switch, by its tick box or by a switch of
-- settings profile. Off: everyone who has our stats is told to drop them, and what was
-- received is forgotten. On: the group gets the stats and is asked for theirs.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local sharing -- the switch as it was last seen, to tell when a profile changes it

-- Tells the group, and the players outside it who were whispered our stats, to drop
-- what they have of us. Versions that don't know this message ignore it and keep their
-- copy until they reload. Whispers go only to those whispered recently enough that
-- they still keep our stats (SyncReceive.lua): the others have dropped them already.
function S.SendClear()
    local channel = S.GroupChannel()
    local others = S.Whispered(S.STALE + S.PRUNE_EVERY)
    if not channel and #others == 0 then return end
    if not S.CanSend() then S.Hold("clear") return end
    local message = ns.Codec.Pack("addon", "C", S.NextStamp())
    if channel then S.Send(message, channel) end
    for _, name in ipairs(others) do S.Send(message, "WHISPER", name) end
end

-- Acts on a change of the switch. The saved setting already holds the new value.
local function Switched(on)
    sharing = on
    S.Reset()
    if on then
        RPSheet:QueueBroadcast(true)
        C_Timer.After(S.BROADCAST_DELAY, S.AskGroup)
    else
        S.Forget()
        S.SendClear()
    end
end

-- The tick box (and "/sheet" commands that set it).
function RPSheet:SetSharing(on)
    on = on and true or false
    local was = S.Sharing()
    self.db.profile.share = on
    if on ~= was then Switched(on) else sharing = on end
end

-- A settings profile was switched to, copied over this one or reset: "Share my stats"
-- may be different now.
function S.ProfileChanged()
    local now = S.Sharing()
    if sharing ~= nil and now ~= sharing then Switched(now) end
    sharing = now
end

function S.EnableSwitch()
    sharing = S.Sharing()
    for _, event in ipairs({ "OnProfileChanged", "OnProfileCopied", "OnProfileReset" }) do
        RPSheet.db.RegisterCallback(S, event, S.ProfileChanged)
    end
end
