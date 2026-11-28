-- Combat sessions, part 13: what a combatant from the creature list can do on its
-- turn. It has one action: its attacks (one, or MULTI of them when it attacks more
-- than once a turn), or one of the saves it forces, which may catch several
-- combatants but each of them once. The owner can give it another action, for what a
-- creature does beyond its action. Kept by the owner's client for the turn that runs.
local _, ns = ...
local F = ns.Fight

local MULTI = 2 -- attacks of a creature that attacks more than once a turn

local state = {}

-- The turn's count for the combatant whose turn it is, or nil for anyone else.
local function Turn(key)
    local session = F.session
    if not session or session.phase ~= "RUN" or not key or key ~= session.turn then return nil end
    local mark = ("%s:%s:%d"):format(session.id, key, session.round)
    if state.mark ~= mark then state = { mark = mark, attacks = 0, caught = {} } end
    return state
end

-- How many attacks its action is.
function F.CreatureAttacks(key)
    local template = F.Template(F.session.members[key or ""])
    return template and template.multi and MULTI or 1
end

-- The attacks it has left this turn, or nil when it isn't its turn.
function F.CreatureAttacksLeft(key)
    local turn = Turn(key)
    if not turn then return nil end
    return turn.force and 0 or math.max(0, F.CreatureAttacks(key) - turn.attacks)
end

-- Why the combatant can't do this now, or nil. `kind` is "attack" or "force", `index`
-- the force's place in its list, `target` who it would catch.
function F.CreatureWhy(kind, index, key, target)
    local turn = Turn(key)
    if not turn then return nil end
    local name = F.session.members[key].name
    if kind == "attack" then
        if turn.force then return ("%s used its action for something else this turn."):format(name) end
        local most = F.CreatureAttacks(key)
        if turn.attacks >= most then
            return most == 1 and ("%s has attacked this turn."):format(name) or ("%s has made its %d attacks this turn."):format(name, most)
        end
    else
        if turn.attacks > 0 then return ("%s used its action to attack this turn."):format(name) end
        if turn.force and turn.force ~= index then return ("%s used its action for something else this turn."):format(name) end
        if target and turn.caught[target] then return ("%s is already caught in it this turn."):format(F.session.members[target].name) end
    end
    return nil
end

function F.CreatureSpent(kind, index, key, target)
    local turn = Turn(key)
    if not turn then return end
    if kind == "attack" then
        turn.attacks = turn.attacks + 1
    else
        turn.force = index
        if target then turn.caught[target] = true end
    end
end

-- The owner gives the combatant whose turn it is another action.
function F.CreatureAnotherAction()
    local session = F.session
    if not F.IsOwner() or not Turn(session.turn) then return end
    state = { mark = state.mark, attacks = 0, caught = {} }
    F.Changed()
end
