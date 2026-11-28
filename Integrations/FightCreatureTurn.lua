-- Combat sessions, part 13: what a combatant from the creature list can do on its
-- turn (Data/Creatures.lua has what each of them may). It has one action: as many
-- attacks as its list entry says, or one of the saves it forces, which may catch
-- several combatants but each of them once. Some of those saves go along with the
-- attacks or take the place of some; some are a bonus action, one a turn; some come
-- back on a roll at the start of its turn once used, or have a number of uses a day.
-- Reactions, legendary actions and traits are not held against the turn. The owner
-- can give the combatant another action. Kept by the owner's client: the turn that
-- runs, and for the session what is used up.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local turn = {} -- the turn that runs: mark, attacks, action, multi, bonus, used, caught
local kept = {} -- the session: id, [key] = { spent = { [index] = true }, day = { [index] = uses } }

local function Kept(key)
    local id = F.session.id
    if kept.id ~= id then kept = { id = id } end
    kept[key] = kept[key] or { spent = {}, day = {} }
    return kept[key]
end

-- The turn's count for the combatant whose turn it is, or nil for anyone else.
local function Turn(key)
    local session = F.session
    if not session or session.phase ~= "RUN" or not key or key ~= session.turn then return nil end
    local mark = ("%s:%s:%d"):format(session.id, key, session.round)
    if turn.mark ~= mark then turn = { mark = mark, attacks = 0, used = {}, caught = {} } end
    return turn
end

-- How many attacks its action is.
function F.CreatureAttacks(key)
    local template = F.Template(F.session.members[key or ""])
    return template and template.attacksPerAction or 1
end

-- The attacks it has left this turn, or nil when it isn't its turn.
function F.CreatureAttacksLeft(key)
    local now = Turn(key)
    if not now then return nil end
    return now.action and 0 or math.max(0, F.CreatureAttacks(key) - now.attacks)
end

-- What sets a forced save apart from a plain action, in a few words, or "".
function F.ForceNote(force)
    local words = {}
    if force.kind == "bonus" then words[#words + 1] = "bonus action" end
    if force.kind == "reaction" then words[#words + 1] = "reaction" end
    if force.kind == "legendary" then words[#words + 1] = "legendary action" end
    if force.kind == "trait" then words[#words + 1] = "no action" end
    if force.with then words[#words + 1] = "with its attacks" end
    if force.swap then words[#words + 1] = force.swap == 1 and "instead of 1 attack" or ("instead of %d attacks"):format(force.swap) end
    if force.recharge then words[#words + 1] = force.recharge >= 6 and "recharge 6" or ("recharge %d-6"):format(force.recharge) end
    if force.perDay then words[#words + 1] = ("%d a day"):format(force.perDay) end
    return table.concat(words, ", ")
end

-- Why the combatant can't do this now, or nil. `kind` is "attack" or "force", `index`
-- its place in the template's list, `target` who a forced save would catch.
function F.CreatureWhy(kind, index, key, target)
    local now = Turn(key)
    if not now then return nil end
    local member = F.session.members[key]
    local template, name = F.Template(member), member.name
    if kind == "attack" then
        local attack = template.attacks[index]
        if attack and attack.legendary then return nil end
        if now.action then return ("%s used its action for %s this turn."):format(name, template.forces[now.action].name) end
        local most = template.attacksPerAction
        if now.attacks >= most then
            return most == 1 and ("%s has attacked this turn."):format(name) or ("%s has made its %d attacks this turn."):format(name, most)
        end
        return nil
    end
    local force = template.forces[index]
    if not force then return nil end
    if target and now.caught[index] and now.caught[index][target] then
        return ("%s is already caught in %s this turn."):format(F.session.members[target].name, force.name)
    end
    if now.used[index] then return nil end -- paid for this turn: it catches one more
    local mine = Kept(key)
    if force.recharge and mine.spent[index] then
        return ("%s is used up. It comes back on a %s on a d6, rolled when %s's turn starts."):format(force.name,
            force.recharge >= 6 and "6" or (force.recharge .. " or higher"), name)
    end
    if force.perDay and (mine.day[index] or 0) >= force.perDay then
        return ("%s has used %s as often as it can today."):format(name, force.name)
    end
    if force.kind == "bonus" then
        return now.bonus and ("%s has used its bonus action this turn."):format(name) or nil
    elseif force.kind ~= "action" then
        return nil
    end
    if now.action then return ("%s used its action for %s this turn."):format(name, template.forces[now.action].name) end
    if force.with then return nil end
    if force.swap then
        if template.attacksPerAction - now.attacks < force.swap then
            return ("%s has no attack left to give up for %s."):format(name, force.name)
        end
        return nil
    end
    if now.attacks > 0 or now.multi then return ("%s used its action to attack this turn."):format(name) end
    return nil
end

function F.CreatureSpent(kind, index, key, target)
    local now = Turn(key)
    if not now then return end
    local template = F.Template(F.session.members[key])
    if kind == "attack" then
        local attack = template.attacks[index]
        if not (attack and attack.legendary) then now.attacks = now.attacks + 1 end
        return
    end
    local force = template.forces[index]
    if target then
        now.caught[index] = now.caught[index] or {}
        now.caught[index][target] = true
    end
    if now.used[index] then return end
    now.used[index] = true
    local mine = Kept(key)
    if force.recharge then mine.spent[index] = true end
    if force.perDay then mine.day[index] = (mine.day[index] or 0) + 1 end
    if force.kind == "bonus" then
        now.bonus = index
    elseif force.kind == "action" then
        if force.with then
            now.multi = true
        elseif force.swap then
            now.multi, now.attacks = true, now.attacks + force.swap
        else
            now.action = index
        end
    end
end

-- The owner gives the combatant whose turn it is another action.
function F.CreatureAnotherAction()
    local now = F.IsOwner() and Turn(F.session.turn)
    if not now then return end
    now.attacks, now.action, now.multi = 0, nil, nil
    F.Changed()
end

-- A combatant's turn starts (FightOwner.lua): what it used up may come back.
function F.CreatureTurnStarts(key)
    local session = F.session
    local member = session and session.members[key or ""]
    local template = F.Template(member)
    if not template or not F.IsOwner() or kept.id ~= session.id or not kept[key] then return end
    local spent = kept[key].spent
    for index, force in ipairs(template.forces) do
        if spent[index] and force.recharge then
            local die = math.random(1, 6)
            if die >= force.recharge then
                spent[index] = nil
                F.Say(("rolls a %d: %s is back."):format(die, force.name), member)
            else
                F.Say(("rolls a %d: %s is not back yet."):format(die, force.name), member)
            end
        end
    end
end
