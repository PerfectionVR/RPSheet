-- What a combat session's owner does beyond calling the turns, with three players:
-- adds combatants of their own, which roll initiative and take turns; rolls their
-- attacks; asks a player for a saving throw and says how it went; deals damage and
-- heals, which the target's own sheet applies; and hands the session to another
-- player, whose game then keeps and announces it.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local maren = world:AddClient({ name = "Maren" }):Login():OpenSheet()
local laura = world:AddClient({ name = "Laura" }):Login():OpenSheet()
local thok = world:AddClient({ name = "Thok" }):Login():OpenSheet()
world:Group({ maren, laura, thok })
world:Advance(10)
maren:Build("WARRIOR", "", 5)
laura:Build("MAGE", "", 5)
thok:Build("ROGUE", "", 3)
for _, client in ipairs({ maren, laura, thok }) do client.addon.db.profile.channel = "PARTY" end
world:Advance(5)

local function Fight(client) return client.ns.Fight end
local function SaidSince(client, from, needle)
    for index = from + 1, #client.said do
        if client.said[index].text:find(needle, 1, true) then return client.said[index].text end
    end
end
local function Printed(client, from, needle)
    for index = from + 1, #client.printed do
        if tostring(client.printed[index]):find(needle, 1, true) then return true end
    end
    return false
end
local function Roll(client, value)
    client.rolls = { value }
    client:Do(Fight(client).RollInitiative)
    world:Advance(2)
end
local function Key(client, name)
    for key, member in pairs(Fight(client).session.members) do
        if member.name == name then return key, member end
    end
end

maren:Do(Fight(maren).Start)
world:Advance(2)
laura:Do(Fight(laura).Join)
thok:Do(Fight(thok).Join)
world:Advance(2)

Section("combatants the owner runs", function()
    local F = Fight(maren)
    Eq(F.ParseCreature("Gnoll 13 22 +1").dex, 1, "a line of text gives the initiative bonus")
    Eq(F.ParseCreature("Dire Wolf, 14, 37").name, "Dire Wolf", "a name of several words, with commas")
    Eq(F.ParseCreature("Gnoll"), nil, "a name alone is not enough")
    local printed = #maren.printed
    maren:Do(F.AddCreature, "nothing")
    Check(Printed(maren, printed, "Give a name, an Armor Class and hit points"), "which the owner is told")
    maren:Do(F.AddCreature, "Gnoll 13 22 +1")
    maren:Do(F.AddCreature, "Gnoll 13 22 +1")
    world:Advance(2)
    local key, gnoll = Key(laura, "Gnoll")
    Check(gnoll and gnoll.npc and gnoll.ac == 13 and gnoll.hp == 22, "everyone sees the new combatant with its numbers")
    Check(Key(thok, "Gnoll 2"), "a second of the same name is told apart")
    Check(SaidSince(maren, 0, "Gnoll joins the combat session."), "the owner's game announces it")
    laura:Do(Fight(laura).AddCreature, "Wolf 12 11")
    world:Advance(2)
    Check(not Key(maren, "Wolf"), "only the owner adds combatants")
    maren:Do(F.RemoveCreature, (Key(maren, "Gnoll 2")))
    world:Advance(2)
    Check(not Key(thok, "Gnoll 2"), "and takes them out again")
    Check(key ~= nil and F.session.members[key].init == nil, "before the call it has no initiative")
end)

Section("initiative", function()
    local said = #maren.said
    maren:Do(Fight(maren).CallInitiative)
    world:Advance(2)
    local _, gnoll = Key(laura, "Gnoll")
    Check(gnoll.init and gnoll.init >= 2 and gnoll.init <= 21, "the owner's game rolls for its combatant at once")
    Check(SaidSince(maren, said, "Gnoll rolls initiative:"), "and says what it rolled")
    Eq(Fight(laura).session.phase, "ROLL", "the players still have to roll")
    Roll(laura, 20)
    Roll(thok, 19)
    Roll(maren, 18)
    Eq(Fight(thok).session.phase, "RUN", "then the turns start")
    Eq(#Fight(thok).session.order, 4, "with four in the order")
    -- a newcomer while the turns run rolls at once too
    maren:Do(Fight(maren).AddCreature, "Wolf 12 11 +2")
    world:Advance(2)
    local _, wolf = Key(thok, "Wolf")
    Check(wolf and wolf.init, "one added while the turns run has its place straight away")
    Eq(#Fight(thok).session.order, 5, "in the order")
end)

-- Moves the turn on until it is that combatant's.
local function TurnTo(name)
    local F = Fight(maren)
    for _ = 1, 12 do
        local holder = F.session.members[F.session.turn]
        if holder.name == name then return true end
        maren:Do(F.NextTurn)
        world:Advance(2)
    end
    return false
end

Section("a turn of the owner's combatant", function()
    local F = Fight(maren)
    Check(TurnTo("Gnoll"), "the turn comes to it")
    Check(not Fight(laura).MyTurn() and not Fight(thok).MyTurn() and not F.MyTurn(), "it is nobody else's turn")
    F.target = thok.full
    local said = #maren.said
    maren:Do(F.CreatureAttack, "+5")
    world:Advance(2)
    local line = SaidSince(maren, said, "Gnoll attacks:") or ""
    Check(line:find("Thok", 1, true) and (line:find("hits", 1, true) or line:find("misses", 1, true) or line:find("critical", 1, true)),
        "its attack is rolled by the owner's game, against the picked row's Armor Class: " .. line)
    laura:Do(Fight(laura).CreatureAttack, "+5", (Key(laura, "Gnoll")))
    world:Advance(2)
    Check(not SaidSince(laura, 0, "Gnoll attacks"), "a player can't roll for it")
end)

Section("damage and healing", function()
    local F = Fight(maren)
    local hp, max = thok.addon:State().hp, thok.addon:MaxHP()
    F.target = thok.full
    local printed = #thok.printed
    maren:Do(F.DealDamage, "5 fire")
    world:Advance(3)
    Eq(thok.addon:State().hp, (hp or max) - 5, "damage the owner deals is taken by the target's own sheet")
    Check(Printed(thok, printed, "Maren deals you 5 fire damage."), "who is told where it comes from")
    Eq(F.session.members[thok.full].hp, max - 5, "and the session's list follows")
    Eq(laura.addon:State().hp or laura.addon:MaxHP(), laura.addon:MaxHP(), "nobody else takes it")
    maren:Do(F.HealTarget, "3")
    world:Advance(3)
    Eq(thok.addon:State().hp, max - 2, "healing comes back the same way")
    printed = #maren.printed
    maren:Do(F.DealDamage, "5 sharp")
    Check(Printed(maren, printed, "Give the amount"), "a damage type that is none is refused")
    -- a combatant of the owner's: its hit points are kept here
    local key = Key(maren, "Gnoll")
    F.target = key
    local said = #maren.said
    maren:Do(F.DealDamage, "20 slashing")
    world:Advance(2)
    Eq(Fight(laura).session.members[key].hp, 2, "damage to the owner's combatant comes off its hit points")
    Check(SaidSince(maren, said, "Gnoll takes 20 slashing damage."), "and is announced")
    maren:Do(F.DealDamage, "9")
    world:Advance(2)
    Eq(Fight(laura).session.members[key].hp, 0, "never below 0")
    Check(SaidSince(maren, said, "Gnoll drops to 0 hit points."), "dropping to 0 is said")
    -- a player can't do any of it
    local before = laura.addon:State().hp
    Fight(thok).target = laura.full
    thok:Do(Fight(thok).DealDamage, "9")
    world:Advance(2)
    Eq(laura.addon:State().hp, before, "a player deals no damage this way")
    -- nor does a forged message from one
    thok:Do(Fight(thok).Send, "D", { to = laura.full, amount = 9 })
    world:Advance(2)
    Eq(laura.addon:State().hp, before, "and a message that claims to be the owner's is not believed")
end)

Section("a combatant at 0 is passed over", function()
    local F = Fight(maren)
    local seen = {}
    for _ = 1, 8 do
        maren:Do(F.NextTurn)
        world:Advance(2)
        seen[F.session.members[F.session.turn].name] = true
    end
    Check(not seen["Gnoll"], "its turn doesn't come up any more")
    Check(seen["Wolf"] and seen["Laura"], "the others' turns do")
end)

Section("a saving throw", function()
    local F = Fight(maren)
    F.target = laura.full
    local printed, said = #laura.printed, #maren.said
    maren:Do(F.AskSave, "dex 12")
    world:Advance(2)
    Check(SaidSince(maren, said, "Laura makes a Dexterity saving throw, DC 12."), "the owner's game says who has to roll what")
    Check(Printed(laura, printed, "Make a Dexterity saving throw, DC 12"), "the player is told")
    Check(Fight(laura).owedSave and Fight(laura).owedSave.dc == 12, "and the window offers it")
    Eq(Fight(thok).owedSave, nil, "nobody else")
    laura.rolls = { 3 }
    laura.addon.busy = false
    laura:Do(function()
        laura.addon:RollCheck("DEX save", laura.addon:SaveMod("DEX"), nil, false, {})
    end)
    world:Advance(3)
    local total = 3 + laura.addon:SaveMod("DEX")
    local line = SaidSince(maren, said, "DEX save") or ""
    Check(line:find((total >= 12 and "succeeds" or "fails") .. " against DC 12", 1, true), "the owner's game says how the roll went: " .. line)
    Eq(Fight(laura).owedSave, nil, "the save is no longer owed")
    said = #maren.said
    laura.rolls = { 19 }
    laura:Do(function()
        laura.addon:RollCheck("DEX save", laura.addon:SaveMod("DEX"), nil, false, {})
    end)
    world:Advance(3)
    Check(not (SaidSince(maren, said, "DEX save") or ""):find("against DC", 1, true), "a save nobody asked for is only announced")
    -- the owner's own combatant
    F.target = Key(maren, "Wolf")
    said = #maren.said
    maren:Do(F.AskSave, "CON 10 +1")
    world:Advance(2)
    local wolf = SaidSince(maren, said, "Wolf rolls a CON save:") or ""
    Check(wolf:find("against DC 10", 1, true), "is rolled by the owner's game: " .. wolf)
    printed = #maren.printed
    maren:Do(F.AskSave, "luck 10")
    Check(Printed(maren, printed, "Give the ability and the DC"), "an ability that is none is refused")
end)

Section("handing the session over", function()
    local F = Fight(maren)
    local round, turn = F.session.round, F.session.turn
    F.target = Key(maren, "Wolf")
    local printed = #maren.printed
    maren:Do(F.HandOver)
    Check(Printed(maren, printed, "Pick another player's row"), "it can't go to a combatant without a player")
    F.target = laura.full
    printed = #laura.printed
    local said = #laura.said
    maren:Do(F.HandOver)
    world:Advance(3)
    Check(Fight(laura).IsOwner(), "the picked player owns the session")
    Check(not F.IsOwner() and F.Mine(), "the one who had it is a player in it now")
    Eq(Fight(thok).session.owner, laura.full, "everyone follows the new owner")
    Check(Printed(laura, printed, "The combat session is yours now"), "who is told")
    Eq(Fight(laura).session.round, round, "the round carries on")
    Eq(Fight(thok).session.turn, turn, "and so does the turn")
    Check(Key(laura, "Wolf"), "the combatants without a player go with the session")
    -- the new owner runs it
    laura:Do(Fight(laura).NextTurn)
    world:Advance(2)
    Check(SaidSince(laura, said, "'s turn."), "the new owner's game announces the turns")
    Check(Fight(maren).session.turn == Fight(laura).session.turn, "which the old owner follows")
    local before = #maren.said
    maren:Do(F.NextTurn)
    world:Advance(2)
    Eq(#maren.said, before, "the old owner's buttons do nothing any more")
    Fight(laura).target = maren.full
    local hp = maren.addon:State().hp or maren.addon:MaxHP()
    laura:Do(Fight(laura).DealDamage, "4")
    world:Advance(3)
    Eq(maren.addon:State().hp, hp - 4, "the new owner's damage is taken")
    -- a reload of the new owner keeps it
    laura:Reload():OpenSheet()
    world:Advance(8)
    Check(Fight(laura).IsOwner() and Key(laura, "Wolf"), "after a reload the new owner still has the session")
    laura:Do(Fight(laura).End)
    world:Advance(2)
    Check(not Fight(maren).session and not Fight(thok).session, "and ends it for everyone")
end)

world:CheckClean("owner")
Summary("t-sync-owner")
