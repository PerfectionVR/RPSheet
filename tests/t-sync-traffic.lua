-- How much the addon sends: a play session of three players is counted in messages
-- and bytes; changes made in quick succession go out as one message, clicks that
-- change nothing others see send nothing, and the largest sheet still fits one message.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local players = {
    world:AddClient({ name = "Anna" }):Login():OpenSheet(),
    world:AddClient({ name = "Bert", trp3 = {} }):Login():OpenSheet(),
    world:AddClient({ name = "Cara", trp3 = {} }):Login():OpenSheet(),
}
local anna, bert, cara = players[1], players[2], players[3]
world:Advance(10)
anna:Build("WARRIOR", "", 5); bert:Build("MAGE", "", 5); cara:Build("ROGUE", "", 5)

-- How often each client asks for a broadcast.
local asked = {}
for _, client in ipairs(players) do
    asked[client] = 0
    local queue = client.addon.QueueBroadcast
    client.addon.QueueBroadcast = function(self, ...) asked[client] = asked[client] + 1 return queue(self, ...) end
end
local function Named(list, name) for _, entry in ipairs(list) do if entry.name == name then return entry end end end

-- What a player clicks during play, in turn. The second value says whether the click
-- changes something the others are shown.
local clicks = {
    { "a skill check", false, function(c) c.addon:RollCheck("Stealth", 5) end },
    { "another tab of the sheet", false, function(c) c.addon:PopulateSoon() end },
    { "the next roll's mode", false, function(c) c.addon:CycleRollMode() end },
    { "an attack", false, function(c) c.addon:Attack() end },
    { "takes damage", true, function(c) c.addon:TakeDamage(2) end },
    { "a saving throw", false, function(c) c.addon:RollCheck("DEX save", 3, nil, false) end },
    { "a condition on", true, function(c) c.addon:ToggleCondition("Prone") end },
    { "the announce channel", false, function(c) c.addon:CycleChannel(); c.addon.db.profile.channel = "EMOTE" end },
    { "is healed", true, function(c) c.addon:Heal(2) end },
    { "initiative", false, function(c) c.addon:RollCheck("initiative", 2) end },
    { "a condition off", true, function(c) c.addon:ToggleCondition("Prone") end },
    { "locks the window", false, function(c) c.addon:Refresh() end },
}

Section("a session of half an hour", function()
    world:Group(players)
    world:Advance(5)
    local start, startTime = #world.wire, world.now
    local changes = {}
    for _, client in ipairs(players) do asked[client], changes[client] = 0, 0 end
    local turn = 0
    for second = 1, 1800 do
        if second % 6 == 0 then -- each of the three clicks something every 6 seconds
            turn = turn + 1
            for index, client in ipairs(players) do
                local click = clicks[(turn + index * 5) % #clicks + 1]
                client:Do(click[3], client)
                if click[2] then changes[client] = changes[client] + 1 end
            end
        end
        world:Advance(1)
    end
    world:Advance(5)
    world:CheckClean("session")
    local total, totalBytes = world:Traffic(nil, start)
    print(("  30 minutes, 3 players, %d clicks each: %d addon messages, %d bytes in all (%.1f bytes a second)"):format(
        turn, total, totalBytes, totalBytes / (world.now - startTime)))
    for _, client in ipairs(players) do
        local count, bytes = world:Traffic(client, start)
        print(("    %s: asked for a broadcast %d times, sent %d messages, %d bytes; %d of the clicks changed what others see"):format(
            client.name, asked[client], count, bytes, changes[client]))
        Check(asked[client] >= turn, client.name .. ": every click asks for a broadcast (" .. asked[client] .. ")")
        Check(count <= changes[client], ("%s: %d messages for %d changes"):format(client.name, count, changes[client]))
        Check(count >= changes[client] * 0.9, ("%s: only %d messages for %d changes that are 6 seconds apart"):format(client.name, count, changes[client]))
        Eq(client.throttled, 0, client.name .. ": messages the game throttled")
        Eq(#client.refused, 0, client.name .. ": messages the game refused")
    end
    local largest, last = 0, {}
    for i = start + 1, #world.wire do
        local sent = world.wire[i]
        largest = math.max(largest, #sent.text)
        Check(not sent.text:find("^[%z\1-\9]"), "a message in parts during play")
        if last[sent.from] then Check(sent.at - last[sent.from] >= 1.9, ("%s sent two messages %.1f s apart"):format(sent.from.name, sent.at - last[sent.from])) end
        last[sent.from] = sent.at
    end
    print(("    the largest message was %d bytes"):format(largest))
    -- everyone ends with everyone's current numbers
    for _, from in ipairs(players) do
        for _, to in ipairs(players) do
            if from ~= to then
                local copy = to.addon:GetCachedStats(from.full)
                Eq(copy and table.concat(to.addon:GetStatLines(copy), "/"), table.concat(from.addon:GetStatLines(from.addon:GetStatData()), "/"),
                    ("at the end %s's copy of %s"):format(to.name, from.name))
            end
        end
    end
end)

Section("a burst of clicks", function()
    world:Advance(5)
    local start = #world.wire
    asked[anna] = 0
    anna.addon:TakeDamage(40)
    world:Advance(3)
    start, asked[anna] = #world.wire, 0
    for _ = 1, 50 do -- a fight in fast forward: 4 changes every fifth of a second
        anna.addon:Heal(2); anna.addon:TakeDamage(2); anna.addon:Heal(1)
        anna.addon:Refresh()
        world:Advance(0.2)
    end
    world:Advance(3)
    local count, bytes = world:Traffic(anna, start)
    print(("  200 changes in 10 seconds: asked %d times, %d messages, %d bytes"):format(asked[anna], count, bytes))
    Check(count <= 6, "200 changes in 10 seconds are at most 6 messages, got " .. count)
    Check(count >= 1, "and at least one")
    local copy = bert.addon:GetCachedStats(anna.full)
    Eq(copy and copy.trackers[1][2], anna.addon:State().hp, "the last value is the one that arrived")
    Eq(anna.throttled, 0, "throttled")
end)

Section("clicks that change nothing", function()
    world:Advance(5)
    local start = #world.wire
    for _ = 1, 40 do
        anna.addon:CycleRollMode(); anna.addon:PopulateSoon(); anna.addon:Refresh()
        world:Advance(3)
    end
    Eq(world:Traffic(anna, start), 0, "messages for 120 clicks that change nothing others see")
    -- the same value back and forth within the two seconds is no change either
    anna.addon:ToggleCondition("Prone"); anna.addon:ToggleCondition("Prone")
    world:Advance(3)
    Eq(world:Traffic(anna, start), 0, "a change undone before it was sent")
end)

Section("a restless raid", function()
    -- The roster event fires for roles, subgroups, people going offline and coming
    -- back: none of that makes anyone send again. Someone joining does, once each.
    world:Advance(5)
    local start = #world.wire
    for _ = 1, 30 do
        for _, client in ipairs(players) do client:Fire("GROUP_ROSTER_UPDATE") end
        world:Advance(3)
    end
    Eq(world:Traffic(nil, start), 0, "messages for 30 roster events without anyone joining")
    local dora = world:AddClient({ name = "Dora" }):Login():OpenSheet()
    dora:Build("PRIEST", "", 2)
    world:Advance(5)
    start = #world.wire
    world:Join(dora, anna)
    world:Advance(3)
    Eq(world:Traffic(nil, start), 4, "messages when a fourth joins (one each)")
    for _, client in ipairs(players) do
        Check(dora.addon:GetCachedStats(client.full) ~= nil, "the newcomer has " .. client.name .. "'s stats")
        Check(client.addon:GetCachedStats(dora.full) ~= nil, client.name .. " has the newcomer's")
    end
    dora:LeaveGroup()
    world:Advance(3)
    Eq(world:Traffic(nil, start), 4, "nothing more when someone leaves")
    dora:Logout()
end)

Section("the largest sheet", function()
    local R = anna.ns.Rules
    local sheet = anna:Build("HUNTER", "", 20, { spec = "Beast Mastery", alignment = "Chaotic Neutral", lineage = "",
        extras = { { class = "SHAMAN", level = 5 }, { class = "PALADIN", level = 5 }, { class = "WARLOCK", level = 5 } },
        base = { STR = 20, DEX = 20, CON = 20, INT = 20, WIS = 20, CHA = 20 } })
    local long = ("W"):rep(60)
    table.insert(sheet.resources, 1, { name = long .. "1", max = 999, reset = "long" })
    table.insert(sheet.resources, 1, { name = long .. "2", max = 999, reset = "long" })
    table.insert(sheet.resources, 1, { name = long .. "3", max = 999, reset = "long" })
    sheet.weapons[1] = sheet.weapons[1] or CopyTable(R.TEMPLATES.weapon)
    sheet.weapons[1].name = "\195\132" .. long
    anna.addon:State().weapon = 1
    anna.addon:SheetChanged()
    for _, condition in ipairs(R.CONDITIONS) do anna.addon:State().conditions[condition.name] = true end
    anna.addon:State().exhaustion = 5
    local data = anna.addon:GetStatData()
    local packed = anna.ns.Codec.Pack("addon", "D", data)
    print(("  the largest sheet: summary of %d letters, %d trackers, %d conditions: %d bytes"):format(#data.summary, #data.trackers, #(data.conditions or {}), #packed))
    Check(#packed <= 1024, "the largest sheet is under the size a receiver accepts: " .. #packed)
    Check(#data.summary <= 160, ("the longest summary (%d letters) is within what a receiver keeps: %s"):format(#data.summary, data.summary))
    local start = #world.wire
    anna.addon:QueueBroadcast()
    world:Advance(5)
    local count, bytes = world:Traffic(anna, start)
    print(("    sent as %d message(s), %d bytes"):format(count, bytes))
    local copy = bert.addon:GetCachedStats(anna.full)
    if Check(copy ~= nil, "it arrives") then
        Eq(copy.summary, data.summary, "the summary arrives whole")
        Eq(#(copy.conditions or {}), #data.conditions, "every condition arrives")
        Eq(#copy.trackers, #data.trackers, "the trackers arrive")
        for _, line in ipairs(bert.addon:GetStatLines(copy)) do Check(Plain(line, 400), "not plain: " .. line) end
        Check(VALID_UTF8(copy.weapon) and #copy.weapon <= 40, "a long weapon name is cut between characters")
    end
end)

Section("right after login", function()
    -- The comm library holds back for five seconds after a login; what is queued then
    -- still goes out, and the one who logged in hears the others.
    cara:Reload():OpenSheet()
    local start = #world.wire
    world:Advance(12)
    Check(world:Traffic(cara, start) >= 2, "the client back from a reload sent its stats and its question")
    Check(cara.addon:GetCachedStats(anna.full) and cara.addon:GetCachedStats(bert.full), "and has the others' stats")
    Check(world:Traffic(nil, start) <= 5, "a reload costs the group at most five messages, got " .. world:Traffic(nil, start))
end)

world:CheckClean("traffic")
Summary("t-sync-traffic")
