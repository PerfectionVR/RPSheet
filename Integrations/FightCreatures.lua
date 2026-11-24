-- Combat sessions, part 10: combatants the owner runs. A creature, or a player without
-- the addon, is a row of the session like any other, with a name, an Armor Class, hit
-- points and an initiative bonus the owner types. It has no sheet: the owner's client
-- rolls its d20s itself (they are not /roll rolls), keeps its hit points, and moves
-- its turn on. One at 0 hit points is passed over in the order.
--   member.npc = true, under the key "npc:<number>"; member.dex is its initiative bonus
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

F.MAX_CREATURES = 20

local function Signed(value)
    return ("%s %d"):format(value < 0 and "-" or "+", math.abs(value))
end

-- "Gnoll 13 22 +1": name, Armor Class, hit points, initiative bonus (0 when left out).
function F.ParseCreature(text)
    local name, ac, hp, bonus = tostring(text or ""):match("^%s*(.-)[%s,]+(%d+)[%s,]+(%d+)[%s,]*([+-]?%d*)%s*$")
    name = F.Text(name, 30)
    if not name or name == "" then return end
    return { name = name, ac = F.Num(tonumber(ac), 0, 60, 10), hp = F.Num(tonumber(hp), 1, 9999, 1),
        dex = F.Num(tonumber(bonus) or 0, -5, 15, 0) }
end

-- Rolls initiative for a creature that has none yet.
function F.RollCreatureInitiative(key)
    local session = F.session
    local member = session and session.members[key]
    if not member or not member.npc or member.init or session.phase == "LOBBY" then return end
    local die = math.random(1, 20)
    F.Say(("rolls initiative: %d %s = %d"):format(die, Signed(member.dex), die + member.dex), member)
    F.owner.R(key, { init = die + member.dex, dex = member.dex })
end

function F.AddCreature(text)
    local session = F.session
    if not F.IsOwner() then return end
    local made = F.ParseCreature(text)
    if not made then
        RPSheet:Print("Give a name, an Armor Class and hit points, and an initiative bonus if it has one: Gnoll 13 22 +1")
        return
    end
    local count, creatures, taken = 0, 0, {}
    for _, member in pairs(session.members) do
        count, taken[member.name] = count + 1, true
        if member.npc then creatures = creatures + 1 end
    end
    if count >= F.MAX_MEMBERS or creatures >= F.MAX_CREATURES then
        RPSheet:Print("The session is full.")
        return
    end
    -- Two of a kind are told apart by a number.
    local name, number = made.name, 1
    while taken[name] do
        number = number + 1
        name = ("%s %d"):format(made.name, number)
    end
    local index = 1
    while session.members["npc:" .. index] do index = index + 1 end
    local key = "npc:" .. index
    local before = F.Before()
    session.members[key] = { name = name, mark = 0, ac = made.ac, hp = made.hp, max = made.hp, dex = made.dex, npc = true }
    F.Say(session.phase == "RUN" and "joins the fight." or "joins the combat session.", session.members[key])
    F.Rebroadcast(before)
    F.RollCreatureInitiative(key)
    return key
end

-- Takes a combatant the owner runs out of the session.
function F.RemoveCreature(key)
    local member = F.IsOwner() and F.session.members[key]
    if not member or not member.npc then return end
    if F.target == key then F.target = nil end
    F.owner.L(key)
end

-- An attack roll for the creature whose turn it is (or `key`), at the owner's target.
function F.CreatureAttack(text, key)
    local session = F.session
    if not F.IsOwner() then return end
    key = key or session.turn
    local member = session.members[key or ""]
    if not member or not member.npc then return end
    local bonus = tonumber((tostring(text or ""):gsub("%s+", ""))) or 0
    bonus = F.Num(bonus, -10, 30, 0)
    local die = math.random(1, 20)
    F.owner.A(key, {
        text = ("attacks: %d %s = %d"):format(die, Signed(bonus), die + bonus),
        target = F.target, attack = true, total = die + bonus, die = die,
    })
end

-- Hit points of a creature changed by the owner: damage (positive) or healing.
function F.ChangeCreatureHP(key, amount, word)
    local member = F.session.members[key]
    local before, was = F.Before(), member.hp
    member.hp = math.max(0, math.min(member.max, member.hp - amount))
    if amount > 0 then
        F.Say(("takes %d %sdamage."):format(amount, word and (word .. " ") or ""), member)
    else
        F.Say(("regains %d hit points."):format(member.hp - was), member)
    end
    if was > 0 and member.hp == 0 then
        F.Say("drops to 0 hit points.", member)
    elseif was == 0 and member.hp > 0 then
        F.Say(("is back up with %d hit points."):format(member.hp), member)
    end
    F.Rebroadcast(before)
end

-- A creature's saving throw, rolled here with the bonus the owner typed.
function F.CreatureSave(key, stat, dc, bonus)
    local member = F.session.members[key]
    local die = math.random(1, 20)
    local total = die + bonus
    F.Say(("rolls a %s save: %d %s = %d - %s against DC %d"):format(stat, die, Signed(bonus), total,
        total >= dc and "succeeds" or "fails", dc), member)
end
