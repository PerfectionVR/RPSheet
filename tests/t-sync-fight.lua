-- Turn-based combat sessions with four players: one starts a session and owns it, two
-- join and pick a group, initiative is rolled by each for their own character, the
-- turns go round, the owner's game announces what the others' rolls come to, a turn
-- allows one action and one bonus action, a fourth player joins while the turns run,
-- and at the end the state from before the fight can be put back.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local maren = world:AddClient({ name = "Maren" }):Login():OpenSheet()
local laura = world:AddClient({ name = "Laura" }):Login():OpenSheet()
local thok = world:AddClient({ name = "Thok" }):Login():OpenSheet()
local nia = world:AddClient({ name = "Nia" }):Login():OpenSheet()
world:Group({ maren, laura, thok, nia })
world:Advance(10)
maren:Build("WARRIOR", "", 5)
laura:Build("MAGE", "", 5)
thok:Build("ROGUE", "", 3)
nia:Build("PRIEST", "", 3)
for _, client in ipairs({ maren, laura, thok, nia }) do client.addon.db.profile.channel = "PARTY" end
world:Advance(5)

local function Fight(client) return client.ns.Fight end
local function LastSaid(client) return client.said[#client.said] and client.said[#client.said].text or "" end
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

Section("starting and joining", function()
    local printed = #laura.printed
    maren:Do(Fight(maren).Start)
    world:Advance(2)
    local F = Fight(maren)
    Check(F.session and F.IsOwner() and F.Mine(), "the one who starts owns the session and is in it")
    Check(SaidSince(maren, 0, "opens a combat session"), "and says so")
    Check(Printed(laura, printed, "opened a combat session"), "the others are told they can join")
    Check(Fight(laura).session and not Fight(laura).Mine(), "they know of it without being in it")
    laura.addon:State().hp = laura.addon:MaxHP() - 3
    laura:Do(Fight(laura).Join)
    thok:Do(Fight(thok).Join)
    world:Advance(2)
    Check(Fight(laura).Mine() and Fight(thok).Mine(), "joining puts them in it")
    Eq(F.session.members[laura.full].hp, laura.addon:MaxHP() - 3, "with the hit points they have")
    Check(Fight(laura).HasSnapshot(), "and their state from before the fight is kept")
    Check(SaidSince(maren, 0, "Laura joins the combat session"), "the owner's game announces who joins")
    Eq(#laura.said, 0, "a player's game announces nothing itself")
end)

Section("groups", function()
    laura:Do(Fight(laura).SetMark, 8)
    thok:Do(Fight(thok).SetMark, 8)
    maren:Do(Fight(maren).SetMark, 4)
    world:Advance(2)
    Eq(Fight(thok).session.members[laura.full].mark, 8, "everyone sees the group someone picked")
    Eq(Fight(laura).session.members[maren.full].mark, 4, "the owner's too")
    Eq(Fight(maren).ChatName(Fight(maren).session.members[laura.full]), "{skull} Laura", "the mark stands in front of the name in chat")
end)

Section("initiative", function()
    local printed = #thok.printed
    maren:Do(Fight(maren).CallInitiative)
    world:Advance(2)
    Eq(Fight(laura).session.phase, "ROLL", "the call reaches everyone")
    Check(Printed(thok, printed, "Roll initiative"), "and they are told to roll")
    Check(Fight(thok).OwesInitiative(), "the session waits for each roll")
    Roll(thok, 5)
    Eq(Fight(maren).session.phase, "ROLL", "one roll doesn't start the turns")
    Check(SaidSince(maren, 0, "Thok rolls [initiative]"), "the owner's game announces the roll with the group's mark")
    Roll(laura, 18)
    Roll(maren, 10)
    local session = Fight(thok).session
    Eq(session.phase, "RUN", "the turns start when all have rolled")
    Eq(session.order[1], laura.full, "the highest total goes first")
    Eq(session.order[3], thok.full, "the lowest last")
    Eq(session.turn, laura.full, "and has the first turn")
    Check(SaidSince(maren, 0, "Round 1. {skull} Laura's turn."), "which the owner's game announces")
    Check(not Fight(thok).OwesInitiative(), "nobody owes a roll any more")
end)

Section("a turn", function()
    local F = Fight(laura)
    Check(F.MyTurn() and not Fight(thok).MyTurn(), "it is one player's turn")
    -- out of turn: refused, with the reason
    local printed = #thok.printed
    local saidBefore = #maren.said
    thok:Do(thok.addon.Attack, thok.addon, nil, {})
    world:Advance(2)
    Check(Printed(thok, printed, "It is Laura's turn."), "an attack out of turn is refused with the reason")
    Eq(#maren.said, saidBefore, "and nothing is announced")
    -- on the turn: the attack goes through the owner, who says whether it hits
    F.target = thok.full
    laura.rolls = { 15, 3, 3, 3 }
    laura:Do(laura.addon.Attack, laura.addon, nil, {})
    world:Advance(3)
    local line = SaidSince(maren, saidBefore, "Laura attacks") or ""
    local ac = thok.addon:AC()
    Check(line:find("hits Thok (AC " .. ac .. ")", 1, true) or line:find("misses Thok (AC " .. ac .. ")", 1, true),
        "the owner's game says whether the attack hits: " .. line)
    Check(F.used.action, "the attack took the action")
    printed = #laura.printed
    laura:Do(laura.addon.Attack, laura.addon, nil, {})
    Check(Printed(laura, printed, "every attack of your Attack action"), "a second attack isn't allowed without Extra Attack")
    -- the window's list greys the action out and says why
    local dash
    for _, entry in ipairs(F.Actions()) do
        if entry.name == "Dash" then dash = entry end
    end
    Check(dash and dash.why == "You have used your action this turn.", "the list says why an action can't be taken")
    laura:Do(F.EndTurn)
    world:Advance(2)
    Eq(Fight(thok).session.turn, maren.full, "ending the turn gives it to the next")
    Check(not next(F.used) or not F.MyTurn(), "the turn is over")
end)

Section("extra attack, and the round going round", function()
    local F = Fight(maren)
    Eq(F.AttacksPerAction(), 2, "a level 5 Warrior attacks twice")
    maren.rolls = { 12, 4, 4, 11, 4, 4 }
    maren:Do(maren.addon.Attack, maren.addon, nil, {})
    world:Advance(2)
    Eq(F.Why("ATTACK"), nil, "after one attack another is allowed")
    maren:Do(maren.addon.Attack, maren.addon, nil, {})
    world:Advance(2)
    Check(F.Why("ATTACK") ~= nil, "after two there is none left")
    -- off turn only reactions and free things are offered
    for _, entry in ipairs(Fight(laura).Actions()) do
        Check(entry.cost == "REACTION" or entry.cost == "FREE", "off turn the list has no " .. entry.name)
    end
    maren:Do(F.EndTurn)
    world:Advance(2)
    Eq(F.session.turn, thok.full, "the third in the order")
    thok:Do(Fight(thok).EndTurn)
    world:Advance(2)
    Eq(F.session.round, 2, "after the last a new round starts")
    Eq(F.session.turn, laura.full, "with the first again")
    Check(SaidSince(maren, 0, "Round 2. {skull} Laura's turn."), "announced")
    Check(not Fight(laura).used.action, "a new turn has its action again")
end)

Section("joining while the turns run", function()
    nia:Do(Fight(nia).Join)
    world:Advance(2)
    Check(Fight(nia).Mine() and Fight(nia).OwesInitiative(), "the newcomer is in and owes initiative")
    Check(SaidSince(maren, 0, "Nia joins the fight and rolls initiative."), "announced")
    Eq(#Fight(maren).session.order, 3, "until the roll the order is unchanged")
    Roll(nia, 12) -- between Laura and Maren
    local order = Fight(laura).session.order
    Eq(#order, 4, "the roll puts her in the order")
    Check(order[1] == laura.full and order[2] == nia.full, "at the place her total gives")
    Eq(Fight(laura).session.turn, laura.full, "the turn that is running stays")
    laura:Do(Fight(laura).EndTurn)
    world:Advance(2)
    Eq(Fight(maren).session.turn, nia.full, "and she acts when her place comes up")
end)

Section("a reload in the middle", function()
    laura:Reload():OpenSheet()
    world:Advance(8)
    Check(Fight(laura).Mine(), "a player who reloads is back in the session")
    Eq(Fight(laura).session and Fight(laura).session.turn, nia.full, "and knows whose turn it is")
    Check(Fight(laura).HasSnapshot(), "the state from before the fight is still kept")
    maren:Reload():OpenSheet()
    maren.addon.db.profile.channel = "PARTY"
    world:Advance(8)
    Check(Fight(maren).IsOwner() and Fight(maren).Mine(), "the owner who reloads still owns the session")
    Eq(Fight(maren).session.turn, nia.full, "at the same turn")
    Eq(Fight(maren).session.round, 2, "in the same round")
    Eq(#Fight(thok).session.order, 4, "and the others still have everyone")
end)

Section("hit points, leaving and the end", function()
    local said = #maren.said
    thok:Do(function()
        thok.addon:State().hp = 0
        thok.addon:Refresh()
    end)
    world:Advance(4)
    Eq(Fight(laura).session.members[thok.full].hp, 0, "everyone sees a combatant's hit points")
    Check(SaidSince(maren, said, "Thok drops to 0 hit points."), "the owner's game announces who goes down")
    -- the one whose turn it is leaves: the turn moves on
    nia:Do(Fight(nia).Leave)
    world:Advance(2)
    Check(not Fight(maren).session.members[nia.full], "someone who leaves is off the list")
    Eq(Fight(maren).session.turn, maren.full, "and their turn goes to the next")
    Check(not Fight(nia).joined, "they are out")
    -- the owner's own lines outside the session's routing still work
    maren:Do(Fight(maren).End)
    world:Advance(2)
    Check(SaidSince(maren, said, "The fight is over after 2 rounds."), "the end is announced")
    Check(not Fight(laura).session and not Fight(thok).session, "the session is over for everyone")
    -- the state from before the fight
    Check(Fight(thok).HasSnapshot(), "the state from before the fight is still kept")
    thok:Do(Fight(thok).RestoreSnapshot)
    Eq(thok.addon:State().hp, thok.addon:MaxHP(), "putting it back restores the hit points")
    Check(not Fight(thok).HasSnapshot(), "once")
    laura:Do(Fight(laura).DropSnapshot)
    Check(not Fight(laura).HasSnapshot(), "or the outcome is kept")
    -- after the session lines are announced by each player again
    local before = #laura.said
    laura:Do(laura.addon.RollCheck, laura.addon, "INT check", 1)
    world:Advance(2)
    Check(#laura.said > before, "outside a session a player's game announces its own rolls")
end)

Section("nonsense from the wire", function()
    local F = Fight(maren)
    Eq(F.CleanSession({ id = "x", members = { [("k"):rep(200)] = { name = "Long" }, ok = { name = "|cffff0000Red|r", hp = 1e9, mark = 99 } } }, "o").members.ok.name,
        "cffff0000Redr", "colour codes are taken out of a name")
    local clean = F.CleanSession({ id = "x", members = { ok = { name = "A", hp = 1e9, mark = 99, init = "7" } }, order = { "ok", "ghost" }, turn = "ghost" }, "o")
    Eq(clean.members.ok.hp, 9999, "numbers are held to what a character can have")
    Eq(clean.members.ok.mark, #F.MARKS, "a group is one of the marks")
    Eq(clean.members.ok.init, nil, "text is no initiative")
    Eq(#clean.order, 1, "the order only names who is in it")
    Eq(clean.turn, nil, "and so does the turn")
    Eq(F.CleanSession({ id = "x" }, "o"), nil, "a session without members is none")
end)

world:CheckClean("fight")
Summary("t-sync-fight")
