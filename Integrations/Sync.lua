-- Shares stats between RP Sheet users, the way Total RP 3 shares profiles:
--  * hovering or targeting a player asks them (addon whisper) for their stats
--  * your own changes are pushed to your party or raid
--  * after a login or reload inside a group, the group is asked to send theirs again
-- Received stats are kept for the session only and shown in the TRP3 tooltip.
-- With "Share my stats" off none of this happens: nothing is sent, asked or taken in.
--
-- The work is in four files loaded before this one: SyncPayload.lua (what is sent, and
-- making safe what is received), SyncSend.lua, SyncReceive.lua and SyncTerms.lua. This
-- one switches it on at login.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local members = 0 -- size of the group at the last change to it

function RPSheet:EnableSync()
    self:RegisterComm(S.PREFIX)
    -- Unit queries can hit protected values in combat; a failed lookup is simply skipped.
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() pcall(S.QueryUnit, "mouseover") end)
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() pcall(S.QueryUnit, "target") end)
    -- This fires for much more than people joining (roles, subgroups, going offline).
    -- Someone who joined has nothing of ours yet; otherwise only a change is sent.
    self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        local count = GetNumGroupMembers()
        self:QueueBroadcast(count > members)
        members = count
    end)
    self:QueueBroadcast(true)
    C_Timer.After(S.BROADCAST_DELAY, S.AskGroup)
end
