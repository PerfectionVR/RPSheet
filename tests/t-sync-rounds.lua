-- What lasts a number of rounds, in a combat session of two players: a spell that is
-- concentrated on, a spell of one round cast as a reaction, a feature switched on for
-- a time and one that lasts to the next turn. Each is counted in its owner's own
-- turns, ends by itself with a line from the session's owner, is forgotten when it
-- ends some other way, survives a reload, and is no longer counted after the fight.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local maren = world:AddClient({ name = "Maren" }):Login():OpenSheet()
local laura = world:AddClient({ name = "Laura" }):Login():OpenSheet()
world:Group({ maren, laura })
world:Advance(10)
maren:Build("SHAMAN", "", 5)
laura:Build("MAGE", "", 5)
for _, client in ipairs({ maren, laura }) do client.addon.db.profile.channel = "PARTY" end
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
local function Learn(client, name)
    local sheet, R = client.addon:Sheet(), client.ns.Rules
    local spell = CopyTable(R.SPELLS[name])
    spell.free = true
    sheet.spells[#sheet.spells + 1] = spell
    client.ns.Util.NormalizeList(sheet.spells, R.TEMPLATES.spell)
    for _, known in ipairs(sheet.spells) do
        if known.name == name then return known end
    end
end
local function Cast(client, spell)
    client.addon.busy = false
    client:Do(client.addon.CastSpell, client.addon, spell)
    world:Advance(3)
end
local function Use(client, name)
    for _, ability in ipairs(client.addon:Sheet().abilities) do
        if ability.name == name then
            client.addon.busy = false
            client:Do(client.addon.UseAbility, client.addon, ability)
            world:Advance(3)
            return true
        end
    end
    return false
end
local function Timer(client, name)
    for _, timer in ipairs(Fight(client).SyncTimers()) do
        if timer.name == name then return timer end
    end
end
local function PassiveOn(client, name)
    for _, passive in ipairs(client.addon:Sheet().passives) do
        if passive.name == name and passive.enabled then return true end
    end
    return false
end
local function EndTurn(client)
    client:Do(Fight(client).EndTurn)
    world:Advance(2)
end
local function Roll(client, value)
    client.rolls = { value }
    client:Do(Fight(client).RollInitiative)
    world:Advance(2)
end

local blur, shield = Learn(laura, "Blur"), Learn(laura, "Shield")

Section("the data", function()
    local R = laura.ns.Rules
    Eq(R.SPELL_ROUNDS["Blur"], 10, "a spell of a minute lasts ten rounds")
    Eq(R.SPELL_ROUNDS["Shield"], 1, "a spell of a round one")
    Eq(R.SPELL_ROUNDS["Shield of Faith"], 100, "ten minutes are a hundred")
    Eq(R.SPELL_ROUNDS["Fire Bolt"], nil, "a spell that is over at once has none")
    Eq(R.SPELL_ROUNDS["Mage Armor"], nil, "nor one that outlasts an hour")
    Eq(R.RoundsText(10), "10 rounds (1 minute)", "rounds are said with the time they come to")
    Eq(R.RoundsText(1), "1 round", "one round is one round")
end)

Section("outside a session nothing is counted", function()
    Cast(laura, blur)
    Check(laura.addon:State().conditions.Concentrating, "the spell is held")
    Eq(#Fight(laura).SyncTimers(), 0, "but no time runs")
    laura.addon:State().conditions.Concentrating = nil
end)

maren:Do(Fight(maren).Start)
world:Advance(2)
laura:Do(Fight(laura).Join)
world:Advance(2)
maren:Do(Fight(maren).CallInitiative)
world:Advance(2)
Roll(laura, 18)
Roll(maren, 10)

Section("a spell that is held", function()
    Check(Fight(laura).MyTurn(), "the mage has the first turn")
    Cast(laura, blur)
    local timer = Timer(laura, "Blur")
    Check(timer and timer.kind == "CONC" and timer.left == 10, "casting it in the fight starts its ten rounds")
    Eq(Fight(laura).TimerText(timer), "10 rounds left", "which the window says")
    EndTurn(laura)
    Eq(Timer(laura, "Blur").left, 10, "nothing goes by on someone else's turn")
end)

Section("features that are switched on", function()
    Check(Fight(maren).MyTurn(), "the shaman's turn")
    Check(Use(maren, "Rage"), "the shaman has a rage")
    Check(PassiveOn(maren, "Raging"), "which is switched on")
    local timer = Timer(maren, "Raging")
    Check(timer and timer.kind == "PASSIVE" and timer.left == 100, "its ten minutes are counted")
    Check(Use(maren, "Reckless Attack"), "and a reckless attack")
    Check(Timer(maren, "Reckless") and Timer(maren, "Reckless").left == 1, "lasts to the next turn")
    local printed = #maren.printed
    EndTurn(maren)
    Check(not Printed(maren, printed, "ends now unless"), "on the turn it starts a rage needs nothing more")
    Check(PassiveOn(maren, "Reckless"), "the reckless attack stays on over the others' turns")
end)

Section("a round goes by", function()
    local own = #laura.said
    Check(Fight(laura).MyTurn(), "the mage again")
    Eq(Timer(laura, "Blur").left, 9, "a round has gone by for the spell")
    EndTurn(laura)
    -- a reaction on the other's turn: until the caster's next turn
    Cast(laura, shield)
    local ac = laura.addon:AC()
    local timer = Timer(laura, "Shield")
    Check(timer and timer.kind == "SPELL" and timer.left == 1, "a spell cast as a reaction is counted too")
    Eq(Fight(laura).TimerText(timer), "ends when your next turn starts", "and the window says when it ends")
    -- the shaman's second turn: the reckless attack is over
    local said = #maren.said
    Check(not PassiveOn(maren, "Reckless"), "what lasts to the next turn is switched off when it starts")
    Check(SaidSince(maren, 0, "loses [Reckless Attack]: it has lasted its 1 round."), "and the session says so")
    Eq(Timer(maren, "Raging").left, 99, "the rage has 99 rounds left")
    local printed = #maren.printed
    EndTurn(maren)
    Check(Printed(maren, printed, "Rage ends now unless you attacked"), "a turn without an attack: the player is reminded what keeps a rage up")
    Check(PassiveOn(maren, "Raging"), "but it is theirs to end")
    -- the mage's third turn: the shield is gone
    Check(Fight(laura).MyTurn(), "the mage's third turn")
    Check(not Timer(laura, "Shield"), "the spell of one round is over")
    Eq(laura.addon:AC(), ac - 5, "and its Armor Class with it")
    Check(SaidSince(maren, said, "[Shield] ends: it has lasted its 1 round."), "the owner's game announces it")
    Eq(#laura.said, own, "not the player's own")
    Eq(Timer(laura, "Blur").left, 8, "the held spell goes on")
end)

Section("a reload", function()
    laura:Reload():OpenSheet()
    world:Advance(8)
    Check(Fight(laura).Mine(), "the player is back in the session")
    Eq(Timer(laura, "Blur") and Timer(laura, "Blur").left, 8, "and the spell's rounds are as they were")
    blur, shield = nil, nil
    for _, known in ipairs(laura.addon:Sheet().spells) do
        if known.name == "Blur" then blur = known end
    end
end)

Section("the time is up", function()
    local said = #maren.said
    for _ = 1, 7 do
        EndTurn(laura)
        maren.rolls = { 12, 4, 4, 11, 4, 4 }
        maren:Do(maren.addon.Attack, maren.addon, nil, {})
        world:Advance(2)
        EndTurn(maren)
    end
    Eq(Timer(laura, "Blur").left, 1, "after nine rounds the spell has one left")
    Check(laura.addon:State().conditions.Concentrating, "and is still held")
    local printed = #maren.printed
    EndTurn(laura)
    maren:Do(maren.addon.Attack, maren.addon, nil, {})
    world:Advance(2)
    EndTurn(maren)
    Check(not Printed(maren, printed, "Rage ends now unless"), "a turn with an attack keeps the rage up without a word")
    Check(not laura.addon:State().conditions.Concentrating, "with the tenth the concentration ends")
    Check(not Timer(laura, "Blur"), "and nothing is counted for it any more")
    Check(SaidSince(maren, said, "loses [Concentrating]: Blur has lasted its 10 rounds (1 minute)."), "the owner's game says why")
end)

Section("ended some other way", function()
    Check(Fight(laura).MyTurn(), "the mage's turn")
    Cast(laura, blur)
    Check(Timer(laura, "Blur"), "cast again, it is counted again")
    laura:Do(laura.addon.ToggleCondition, laura.addon, "Concentrating")
    world:Advance(2)
    Check(not Timer(laura, "Blur"), "letting the spell go by hand ends the count")
    -- from the window: ended early
    laura.addon:State().conditions.Concentrating = nil
    Fight(laura).used.action, Fight(laura).used.slot = nil, nil
    Cast(laura, blur)
    local said = #maren.said
    laura:Do(Fight(laura).EndTimer, "CONC", "Blur")
    world:Advance(2)
    Check(not laura.addon:State().conditions.Concentrating, "a click in the window ends the spell")
    Check(SaidSince(maren, said, "Blur was ended early"), "and that is announced")
end)

Section("after the fight", function()
    local printed = #maren.printed
    Check(Timer(maren, "Raging"), "the rage still runs")
    maren:Do(Fight(maren).End)
    world:Advance(2)
    Check(Printed(maren, printed, "1 of what you started is still running"), "its owner is told the time is theirs to keep again")
    Eq(maren.addon:State().fightTimers, nil, "and nothing is counted any more")
    Check(PassiveOn(maren, "Raging"), "the rage itself stays on")
    Eq(#Fight(maren).SyncTimers(), 0, "outside a session a switched-on feature starts no count")
end)

world:CheckClean("rounds")
Summary("t-sync-rounds")
