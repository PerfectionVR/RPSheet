-- WoW Forever: names are "Given Family", unique in the region, with no realm. Two
-- players share a given name. Rolls are read back from the game's roll line, stats
-- are shared and kept apart, and chat links name the right player. Then the same
-- names layer (Core/Game.lua) in retail, and a roll line in a translation that
-- numbers its fields.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
world.regional = true
local sara = world:AddClient({ name = "Sara", family = "Panthera" }):Login():OpenSheet()
local other = world:AddClient({ name = "Sara", family = "Brightwood" }):Login():OpenSheet()
world:Advance(10)
sara:Build("WARRIOR", "", 5)
other:Build("MAGE", "", 3)
world:Advance(3)

Section("names", function()
    local Game = sara.ns.Game
    Check(Game.RegionalNames(), "the game has region-wide names")
    Eq(Game.UnitKey("player"), "Sara Panthera", "the player's key is the whole name")
    Eq(sara.ns.PlayerFullName(), "Sara Panthera", "and links carry it")
    Eq(Game.SenderKey("Sara Brightwood"), "Sara Brightwood", "a sender is taken as it comes")
    Check(Game.IsPlayer("Sara Panthera") and not Game.IsPlayer("Sara Brightwood") and not Game.IsPlayer("Sara"),
        "only the whole name is the player")
    Eq(Game.ShortName("Sara Brightwood"), "Sara Brightwood", "both parts are shown")
    Eq(Game.CharacterKey(), "char:Sara Panthera", "a sheet without Total RP 3 is saved under the whole name")
end)

Section("rolling", function()
    local addon = sara.addon
    addon.db.profile.channel = "EMOTE"
    sara.rolls = { 2 }
    local before = #sara.said
    sara:Do(addon.RollCheck, addon, "STR check", 2)
    world:Advance(4)
    local line = sara.said[before + 1] and sara.said[before + 1].text or ""
    Check(line:find("2 + 2 = 4", 1, true), "the roll the game made is announced: " .. line)
    for _, printed in ipairs(sara.printed) do
        Check(not printed:find("Couldn't read the roll", 1, true), "the roll line is read")
    end
    -- the other Sara's roll is not taken for ours
    local got
    local randomRoll = sara.env.RandomRoll
    sara.env.RandomRoll = function() end -- (the lines are sent by hand below)
    sara:Do(addon.Roll, addon, 20, function(value) got = value end)
    sara.env.RandomRoll = randomRoll
    sara:Fire("CHAT_MSG_SYSTEM", "Sara Brightwood rolls 17 (1-20)")
    Eq(got, nil, "another player's roll with the same given name is passed by")
    sara:Fire("CHAT_MSG_SYSTEM", "Sara Panthera rolls 9 (1-20)")
    Eq(got, 9, "the player's own is taken")
end)

Section("sharing stats", function()
    world:Group({ sara, other })
    world:Advance(5)
    local theirs = sara.addon:GetCachedStats("Sara Brightwood")
    local mine = other.addon:GetCachedStats("Sara Panthera")
    Check(theirs and mine, "each has the other's stats under the whole name")
    Eq(sara.addon:GetCachedStats("Sara Panthera"), nil, "nobody keeps their own stats as someone else's")
    Eq(#sara.refused + #other.refused, 0, "nothing the game refuses")
end)

Section("chat links", function()
    sara:ShowChat("CHAT_MSG_PARTY", "I am [Prone]", "Sara Brightwood")
    local shown = sara.chat[#sara.chat].text
    Check(shown:find("rpsheet:Sara Brightwood:Prone", 1, true), "the link names the sender: " .. shown)
    local before = #world.wire
    sara:ClickLink("addon:rpsheet:Sara Brightwood:Prone")
    world:Advance(2)
    local asked = false
    for i = before + 1, #world.wire do
        if world.wire[i].from == sara and world.wire[i].target == "Sara Brightwood" then asked = true end
    end
    Check(asked, "a click asks that player's sheet")
end)

world:CheckClean("forever")
Eq(#world.violations, 0, "lines the game would have refused, in all")

-- Retail: "Name-Realm", and the realm added to a sender from the same realm.
local retail = NewWorld()
local anna = retail:AddClient({ name = "Anna" }):Login():OpenSheet()
retail:Advance(5)

Section("retail names", function()
    local Game = anna.ns.Game
    Check(not Game.RegionalNames(), "no region-wide names")
    Eq(Game.UnitKey("player"), "Anna-Realm", "the key carries the realm")
    Eq(Game.SenderKey("Bert"), "Bert-Realm", "a sender from the same realm gets it added")
    Eq(Game.SenderKey("Bert-Elsewhere"), "Bert-Elsewhere", "another realm's is kept")
    Eq(Game.ShortName("Bert-Elsewhere"), "Bert", "and shown without it")
    Check(Game.IsPlayer("Anna") and Game.IsPlayer("Anna-Realm") and not Game.IsPlayer("Anna-Elsewhere"), "the player, with or without the realm")
    Eq(Game.CharacterKey(), "char:Anna-Realm", "the save key is the one it always was")
end)

Section("a translation that numbers its fields", function()
    local env = anna.env
    local saved = env.RANDOM_ROLL_RESULT
    env.RANDOM_ROLL_RESULT = "%1$s würfelt. Ergebnis: %2$d (%3$d-%4$d)"
    -- the pattern is made on first use; load the file again to use the new string
    local chunk = assert(loadfile(ARG1 .. "/Core/Game.lua"))
    local ns = {}
    setfenv(chunk, env)
    chunk("RPSheet", ns)
    local name, roll, low, high = ns.Game.ParseRoll("Anna würfelt. Ergebnis: 14 (1-20)")
    Eq(("%s %s %s %s"):format(tostring(name), tostring(roll), tostring(low), tostring(high)), "Anna 14 1 20", "the fields are read")
    Eq(ns.Game.ParseRoll("Anna says hello"), nil, "another line is not a roll")
    env.RANDOM_ROLL_RESULT = saved
end)

retail:CheckClean("retail")
Summary("t-sync-forever")
