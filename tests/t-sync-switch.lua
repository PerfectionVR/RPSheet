-- The "Share my stats" switch works both ways (nothing sent, asked or taken in; the
-- group drops its copy at once), what couldn't be sent while the game blocked addon
-- messages is sent afterwards, and an older message never replaces a newer one.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna", trp3 = {} }):Login():OpenSheet()
local bert = world:AddClient({ name = "Bert", trp3 = {} }):Login():OpenSheet()
local cara = world:AddClient({ name = "Cara" }):Login():OpenSheet()
world:Advance(10)
anna:Build("WARRIOR", "", 5)
bert:Build("MAGE", "", 3)
cara:Build("ROGUE", "", 4)

local function Has(of, at) return at.addon:GetCachedStats(of.full) end
local function HP(of, at)
    local copy = Has(of, at)
    return copy and copy.trackers[1] and copy.trackers[1][2]
end
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
-- A message put on `to`'s line as if `from` had sent it.
local function Deliver(from, to, text, chatType)
    to:Fire("CHAT_MSG_ADDON", "RPSheet4", text, chatType or "WHISPER", from.full, "", 0, 0, "", 0)
end

Section("switched off", function()
    world:Group({ anna, bert, cara })
    world:Advance(4)
    Check(Has(anna, bert) and Has(anna, cara) and Has(bert, anna) and Has(cara, anna), "the party has each other's stats")
    bert:Hover(anna, true)
    Check(bert:TooltipStats() ~= nil, "Bert's tooltip of Anna has the Stats section")

    local before = #world.wire
    anna:Do(anna.addon.SetSharing, anna.addon, false)
    Eq(anna.addon.db.profile.share, false, "the setting")
    world:Advance(1)
    Eq(Kinds(anna, before), "C:PARTY", "switching off sends the party one clear message")
    Eq(Has(anna, bert), nil, "Bert dropped Anna's stats at once")
    Eq(Has(anna, cara), nil, "and so did Cara")
    Eq(bert:TooltipStats(), nil, "the open tooltip lost its Stats section")
    Check(bert:Tooltip() ~= nil, "Total RP 3's own tooltip still shows")
    bert:Hover(nil)
    Eq(Has(bert, anna), nil, "Anna keeps nothing of the others either")

    -- off: nothing sent, nobody asked, nothing taken in
    before = #world.wire
    anna.addon:TakeDamage(3)
    anna:Hover(bert); anna:Target(cara)
    bert.addon:TakeDamage(2)
    world:Advance(6)
    Eq(world:Traffic(anna, before), 0, "with sharing off nothing leaves, also no question on hover or target")
    Eq(Has(bert, anna), nil, "and what the party sends is not taken in")
    Eq(anna:TooltipStats(), nil, "so the tooltip of another player has no Stats section")
    anna:Hover(nil); anna:Target(nil)
    world:Advance(31)
    before = #world.wire
    bert:Hover(anna)
    world:Advance(3)
    Eq(world:Traffic(anna, before), 0, "a question is not answered")
    bert:Hover(nil)
    -- a reload in the group asks nobody
    anna:Reload():OpenSheet()
    before = #world.wire
    world:Advance(8)
    Eq(world:Traffic(anna, before), 0, "after a reload with sharing off the group isn't asked")
    Eq(Has(anna, bert), nil, "Bert still has nothing of Anna")
    -- switching it off twice says it once
    before = #world.wire
    anna:Do(anna.addon.SetSharing, anna.addon, false)
    world:Advance(3)
    Eq(world:Traffic(anna, before), 0, "off when it is off sends nothing")
end)

Section("switched on again", function()
    local before = #world.wire
    anna:Do(anna.addon.SetSharing, anna.addon, true)
    world:Advance(8)
    Check(Has(anna, bert) and Has(anna, cara), "the party has Anna's stats again")
    Eq(HP(anna, bert), anna.addon:State().hp, "as they are now")
    Check(Has(bert, anna) and Has(cara, anna), "and Anna was sent theirs without hovering")
    Check(Kinds(anna, before):find("D:PARTY", 1, true) and Kinds(anna, before):find("Q:PARTY", 1, true), "one broadcast and one question: " .. Kinds(anna, before))
    Check(world:Traffic(nil, before) <= 4, "at most one message each and the question, got " .. world:Traffic(nil, before))
    -- alone: switching off has nobody to tell
    anna:LeaveGroup()
    world:Advance(3)
    before = #world.wire
    anna:Do(anna.addon.SetSharing, anna.addon, false)
    anna:Do(anna.addon.SetSharing, anna.addon, true)
    world:Advance(5)
    Eq(world:Traffic(anna, before), 0, "outside a group the switch sends nothing")
    Eq(#anna.refused, 0, "and nothing the game refuses")
    world:Group({ anna, bert, cara })
    world:Advance(4)
end)

Section("an old version in the party", function()
    -- its stats have no stamp: taken as before, every time
    local Pack = bert.ns.Codec.Pack
    local data = bert.addon:GetStatData()
    data.trackers[1][2] = 3
    Deliver(bert, anna, Pack("addon", "D", data), "PARTY")
    Eq(HP(bert, anna), 3, "stats without a stamp are taken")
    bert.addon:TakeDamage(1)
    world:Advance(3)
    Eq(HP(bert, anna), bert.addon:State().hp, "then stamped ones")
    data.trackers[1][2] = 4
    Deliver(bert, anna, Pack("addon", "D", data), "PARTY")
    Eq(HP(bert, anna), 4, "and unstamped ones again")
    -- what it reads of ours is where it always was
    local sent
    for i = #world.wire, 1, -1 do
        if world.wire[i].from == anna and not sent then sent = world.wire[i] end
    end
    local ok, kind, stats = anna.ns.Codec.Unpack("addon", sent.text)
    Check(ok and kind == "D" and type(stats) == "table" and type(stats.stats) == "table" and stats.seq == nil, "our stats are packed where an old version looks for them")
    -- and a message it doesn't know changes nothing for us
    Deliver(bert, anna, Pack("addon", "Z", { 1 }, 2), "PARTY")
    Deliver(bert, anna, Pack("addon", "C"), "PARTY")
    Eq(Has(bert, anna), nil, "a clear without a stamp clears")
    bert.addon:Heal(1)
    world:Advance(3)
    Check(Has(bert, anna), "the next stats are taken again")
end)

Section("messages that cross", function()
    -- Anna's whispered answer is still on its way when her newer party message arrives
    local function Last(from, chatType)
        for i = #world.wire, 1, -1 do
            if world.wire[i].from == from and (not chatType or world.wire[i].chatType == chatType) then return world.wire[i] end
        end
    end
    anna.addon:State().hp = 30
    anna.addon:QueueBroadcast()
    world:Advance(3)
    local older = Last(anna, "PARTY")
    Eq(HP(anna, bert), 30, "the first value arrived")
    anna.addon:State().hp = 20
    anna.addon:QueueBroadcast()
    world:Advance(3)
    Eq(HP(anna, bert), 20, "the second value arrived")
    Check(older.text ~= Last(anna, "PARTY").text, "they are two messages")
    Deliver(anna, bert, older.text, "WHISPER")
    Eq(HP(anna, bert), 20, "the older message arriving late doesn't replace the newer")
    Deliver(anna, bert, Last(anna, "PARTY").text, "WHISPER")
    Eq(HP(anna, bert), 20, "the same message twice changes nothing")
    -- a clear and stats that cross
    local before = #world.wire
    anna:Do(anna.addon.SetSharing, anna.addon, false)
    world:Advance(1)
    Eq(Has(anna, bert), nil, "cleared")
    Deliver(anna, bert, older.text, "WHISPER")
    Eq(Has(anna, bert), nil, "stats from before the clear arriving after it are not taken")
    local clear = Last(anna, "PARTY")
    anna:Do(anna.addon.SetSharing, anna.addon, true)
    world:Advance(4)
    Check(Has(anna, bert), "sharing again")
    Deliver(anna, bert, clear.text, "PARTY")
    Check(Has(anna, bert), "the old clear arriving late clears nothing")
    Check(before < #world.wire, "messages were sent")
    -- a reload doesn't start the stamps over
    anna:Reload():OpenSheet()
    world:Advance(8)
    anna.addon:State().hp = 11
    anna.addon:QueueBroadcast()
    world:Advance(3)
    Eq(HP(anna, bert), 11, "after Anna's reload her new stats are still the newer ones")
    -- stamps that are no numbers, or odd ones, raise nothing
    local Pack = anna.ns.Codec.Pack
    for _, odd in ipairs({ "x", {}, true, -1, 0 / 0, 1e300 }) do
        Deliver(cara, bert, Pack("addon", "D", cara.addon:GetStatData(), odd), "PARTY")
        Deliver(cara, bert, Pack("addon", "C", odd), "PARTY")
    end
end)

Section("the game blocks addon messages for a while", function()
    world:Advance(10)
    local before = #world.wire
    anna.lockdown = true
    anna.addon:State().hp = 9
    anna.addon:QueueBroadcast()
    world:Advance(20)
    Eq(world:Traffic(anna, before), 0, "nothing is sent while the game blocks it")
    Check(HP(anna, bert) ~= 9, "so the party has the old value")
    anna.lockdown = false
    world:Advance(7)
    Eq(Kinds(anna, before), "D:PARTY", "when it ends the stats are sent once, without a new change")
    Eq(HP(anna, bert), 9, "and the party has the new value")
    world:Advance(30)
    Eq(world:Traffic(anna, before), 1, "and not again")
    -- nothing changed during the block: nothing to catch up on
    before = #world.wire
    anna.lockdown = true
    anna.addon:QueueBroadcast()
    world:Advance(10)
    anna.lockdown = false
    world:Advance(10)
    Eq(world:Traffic(anna, before), 0, "a block during which nothing changed sends nothing afterwards")
    -- switched off during the block: the clear follows
    before = #world.wire
    anna.lockdown = true
    anna:Do(anna.addon.SetSharing, anna.addon, false)
    world:Advance(8)
    Eq(world:Traffic(anna, before), 0, "no clear while blocked")
    anna.lockdown = false
    world:Advance(7)
    Eq(Kinds(anna, before), "C:PARTY", "the clear is sent afterwards")
    Eq(Has(anna, bert), nil, "and the party dropped the copy")
    anna:Do(anna.addon.SetSharing, anna.addon, true)
    world:Advance(5)
    -- a login during the block: the group is asked afterwards
    anna.lockdown = true
    anna:Reload():OpenSheet()
    before = #world.wire
    world:Advance(8)
    Eq(world:Traffic(anna, before), 0, "a reload while blocked sends nothing")
    Eq(Has(bert, anna), nil, "and has nothing of the group")
    anna.lockdown = false
    world:Advance(12)
    Check(Has(bert, anna) and Has(cara, anna), "afterwards the group was asked and answered")
    Check(Has(anna, bert), "and has Anna's stats")
end)

world:CheckClean("switch")
Summary("t-sync-switch")
