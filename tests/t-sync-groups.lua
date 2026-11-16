-- Dungeon finder groups and how long others' stats are kept: in an instance group the
-- stats, the question after a reload and the announcements go over the instance's
-- channel; the stats of a player who is not in the group and wasn't heard from for half
-- an hour are dropped, a group member's are kept.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login():OpenSheet()
local bert = world:AddClient({ name = "Bert", trp3 = {} }):Login():OpenSheet()
local cara = world:AddClient({ name = "Cara" }):Login():OpenSheet()
world:Advance(10)
anna:Build("WARRIOR", "", 5)
bert:Build("MAGE", "", 3)
cara:Build("ROGUE", "", 4)
world:Advance(3)

local function Has(of, at) return at.addon:GetCachedStats(of.full) end
local function HP(of, at)
    local copy = Has(of, at)
    return copy and copy.trackers[1] and copy.trackers[1][2]
end
-- "kind:chatType" of what `from` sent since wire index `since`.
local function Kinds(from, since)
    local list = {}
    for i = since + 1, #world.wire do
        local sent = world.wire[i]
        if sent.from == from then
            local _, kind = from.ns.Codec.Unpack("addon", sent.text)
            list[#list + 1] = tostring(kind) .. ":" .. sent.chatType
        end
    end
    return table.concat(list, " ")
end

Section("a dungeon finder group", function()
    local before = #world.wire
    world:Instance({ anna, bert, cara })
    world:Advance(3)
    Eq(Kinds(anna, before), "D:INSTANCE_CHAT", "the stats go over the instance's channel")
    Check(Has(anna, bert) and Has(anna, cara) and Has(bert, anna) and Has(cara, anna), "everyone has everyone's stats")
    Eq(#anna.refused + #bert.refused + #cara.refused, 0, "nothing the game refuses")
    -- a change
    anna.addon:TakeDamage(4)
    world:Advance(3)
    Eq(HP(anna, bert), anna.addon:State().hp, "a change reaches the group")
    -- a reload asks the group over the same channel, and they answer
    world:Advance(10) -- (a group member who just sent their stats doesn't send them again at once)
    before = #world.wire
    bert:Reload():OpenSheet()
    world:Advance(6)
    Check(Kinds(bert, before):find("Q:INSTANCE_CHAT", 1, true), "the question after a reload: " .. Kinds(bert, before))
    Check(Has(anna, bert) and Has(cara, bert), "and the group answered")
    -- a raid finder group is the same channel
    before = #world.wire
    world:Instance({ anna, bert, cara }, true)
    anna.addon:TakeDamage(1)
    world:Advance(3)
    Eq(Kinds(anna, before), "D:INSTANCE_CHAT", "a raid finder group too")
    Eq(HP(anna, cara), anna.addon:State().hp, "and it arrives")
end)

Section("a party of friends in a dungeon finder group", function()
    -- the friends' own party is part of the instance group: one message reaches all
    world:Group({ anna, bert })
    world:Advance(3)
    local before = #world.wire
    anna.addon:TakeDamage(1)
    world:Advance(3)
    Eq(Kinds(anna, before), "D:INSTANCE_CHAT", "the instance channel, not the party's")
    Eq(HP(anna, cara), anna.addon:State().hp, "Cara, who is not in the party, has it")
    -- leaving the instance group: back to the party
    anna:LeaveInstance(); bert:LeaveInstance(); cara:LeaveInstance()
    world:Advance(3)
    before = #world.wire
    anna.addon:TakeDamage(1)
    world:Advance(3)
    Eq(Kinds(anna, before), "D:PARTY", "out of the instance the party's channel")
end)

Section("announcements in a dungeon finder group", function()
    anna:LeaveGroup()
    world:Instance({ anna, bert, cara })
    world:Advance(3)
    local addon = anna.addon
    for _, channel in ipairs({ "PARTY", "RAID" }) do
        -- "Raid" is for a raid finder group (in a dungeon finder party it isn't sent)
        if channel == "RAID" then world:Instance({ anna, bert, cara }, true) world:Advance(3) end
        addon.db.profile.channel = channel
        local said, printed = #anna.said, #anna.printed
        addon:RollCheck("Stealth", 5)
        world:Advance(1)
        local last = anna.said[#anna.said]
        if Check(#anna.said == said + 1 and last.chatType == "INSTANCE_CHAT", channel .. ": the roll goes to the instance chat") then
            local seen = bert.chat[#bert.chat]
            Check(seen and seen.event == "CHAT_MSG_INSTANCE_CHAT" and Links(seen.text)[1] ~= nil,
                channel .. ": Bert reads it with the term linked: " .. tostring(seen and seen.text))
        end
        Eq(#anna.printed, printed, channel .. ": nothing is shown to Anna alone")
        if channel == "PARTY" then
            -- with a party of one's own, the party chat
            world:Group({ anna, cara })
            world:Advance(1)
            addon:RollCheck("Stealth", 5)
            world:Advance(1)
            Eq(anna.said[#anna.said].chatType, "PARTY", "with a party of one's own: the party chat")
            anna:LeaveGroup()
            world:Advance(1)
            local printed = #anna.printed
            addon.db.profile.channel = "RAID"
            addon:RollCheck("Stealth", 5)
            world:Advance(1)
            Check(anna.printed[printed + 1] and anna.printed[printed + 1]:find("you are not in a raid", 1, true),
                "in a dungeon finder party \"Raid\" is shown to the player alone")
        end
    end
    -- outside every group: shown to the player alone, as before
    anna:LeaveInstance()
    world:Advance(1)
    local said, printed = #anna.said, #anna.printed
    addon:RollCheck("Stealth", 5)
    world:Advance(1)
    Eq(#anna.said, said, "alone nothing is sent")
    Check(anna.printed[printed + 1] and anna.printed[printed + 1]:find("you are not in a raid", 1, true), "and the player is told why")
    addon.db.profile.channel = "EMOTE"
    Eq(#world.violations, 0, "lines the game would have refused")
    bert:LeaveInstance(); cara:LeaveInstance()
    world:Advance(3)
end)

Section("stats of players who are gone", function()
    -- Dora walks past and is hovered once; Bert is in Anna's party
    local dora = world:AddClient({ name = "Dora" }):Login():OpenSheet()
    world:Advance(5)
    dora:Build("PRIEST", "", 2)
    world:Group({ anna, bert })
    world:Advance(40)
    anna:Hover(dora)
    world:Advance(2)
    anna:Hover(nil)
    Check(Has(dora, anna) and Has(bert, anna), "Anna has Dora's and Bert's stats")
    -- twenty minutes later nothing has gone
    world:Advance(1200)
    Check(Has(dora, anna) and Has(bert, anna), "after twenty minutes both are kept")
    -- after more than half an hour without a word Dora's are dropped, Bert's kept
    world:Advance(1200)
    Eq(Has(dora, anna), nil, "Dora's stats are dropped after half an hour unheard")
    Check(Has(bert, anna), "a party member's are kept, also when nothing changed")
    -- hovering her again asks again
    local before = #world.wire
    anna:Hover(dora)
    world:Advance(2)
    anna:Hover(nil)
    Check(Kinds(anna, before):find("Q:WHISPER", 1, true) and Has(dora, anna), "hovered again, she is asked and her stats come back")
    -- someone heard from now and then is kept: Dora changes something every ten minutes
    -- and is hovered each time (the answer is what is heard)
    for _ = 1, 4 do
        world:Advance(600)
        anna:Hover(dora)
        world:Advance(2)
        anna:Hover(nil)
    end
    Check(Has(dora, anna), "a player who answers now and then is kept")
    -- a party member who leaves is dropped half an hour after the last word
    bert:LeaveGroup()
    world:Advance(2400)
    Eq(Has(bert, anna), nil, "a former party member's stats are dropped in time")
    dora:Logout()
end)

world:CheckClean("groups")
Summary("t-sync-groups")
