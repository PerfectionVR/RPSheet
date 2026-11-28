-- Combat sessions, part 12: combatants made from a creature template
-- (Data/Creatures.lua). Such a combatant knows its attacks, the saves it forces, its
-- own saving throw bonuses and what damage it shrugs off, so the owner clicks instead
-- of typing: an attack rolls to hit against the picked row and, on a hit, its damage,
-- which the target takes; a forced save is asked of the picked row and its damage
-- follows the result. The dice are rolled by the owner's client, like every roll of a
-- combatant without a sheet (FightCreatures.lua).
--   member.template = the template's name
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local F = ns.Fight

F.pendingSaves = {} -- [player key] = { dc, list, half, name }: damage that waits for a save

-- The template a combatant was made from, or nil.
function F.Template(member)
    return member and member.npc and member.template and R.CREATURES[member.template] or nil
end

local function Signed(value)
    return ("%s %d"):format(value < 0 and "-" or "+", math.abs(value))
end

-- Rolls damage: { { amount, type }, ... } with one entry per damage type.
local function RollParts(parts, crit)
    local list, at = {}, {}
    for _, part in ipairs(parts) do
        local amount = part.flat
        for _ = 1, part.count * (crit and 2 or 1) do amount = amount + math.random(1, part.sides) end
        local key = part.type or ""
        if at[key] then
            list[at[key]].amount = list[at[key]].amount + amount
        else
            list[#list + 1] = { amount = amount, type = part.type }
            at[key] = #list
        end
    end
    return list
end

local function ListText(list)
    local words = {}
    for _, entry in ipairs(list) do
        words[#words + 1] = entry.type and ("%d %s"):format(entry.amount, entry.type) or tostring(entry.amount)
    end
    return table.concat(words, " + ")
end

local function Halved(list)
    local half = {}
    for _, entry in ipairs(list) do
        if entry.amount >= 2 then half[#half + 1] = { amount = math.floor(entry.amount / 2), type = entry.type } end
    end
    return half
end

-- What a templated combatant takes of typed damage: nothing when immune, half when
-- resistant, double when vulnerable. Returns the amount and a word for the reason.
function F.AdjustDamage(member, amount, kind)
    local template = F.Template(member)
    if not template or not kind then return amount end
    if template.immune[kind] then return 0, "immune" end
    if template.resist[kind] then amount = math.floor(amount / 2) end
    if template.vulnerable[kind] then amount = amount * 2 end
    return amount, (template.resist[kind] and "resisted") or (template.vulnerable[kind] and "vulnerable") or nil
end

-- Deals rolled damage to a combatant: a player's sheet takes it part by part, one of
-- the owner's loses the hit points here.
function F.Hurt(key, list)
    local member = F.session.members[key]
    if not member or #list == 0 then return end
    if not member.npc then
        if not F.Tell("D", { to = key, parts = list }) then RPSheet:Print("The damage could not be sent.") end
        return
    end
    local total, notes = 0, {}
    for _, entry in ipairs(list) do
        local amount, note = F.AdjustDamage(member, entry.amount, entry.type)
        total = total + amount
        if note then notes[#notes + 1] = ("%s %s"):format(entry.type, note) end
    end
    F.ChangeCreatureHP(key, total, nil, #notes > 0 and table.concat(notes, ", ") or nil)
end

-- Who the combatant `key` acts on: the picked one, or, when no one else is picked,
-- the only other combatant still standing.
function F.CreatureTarget(key)
    local session = F.session
    if F.target and F.target ~= key and session.members[F.target] then return F.target end
    local only
    for other, member in pairs(session.members) do
        if other ~= key and member.hp > 0 then
            if only then return nil end
            only = other
        end
    end
    return only
end

-- One of a templated combatant's attacks, at the picked combatant. `key` is the
-- attacker (the turn's holder when left out).
function F.CreatureStrike(index, key)
    local session = F.session
    if not F.IsOwner() then return end
    key = key or session.turn
    local member = session.members[key or ""]
    local template = F.Template(member)
    local attack = template and template.attacks[index]
    if not attack then return end
    local why = F.CreatureWhy("attack", index, key)
    if why then return RPSheet:Print(why) end
    F.CreatureSpent("attack", index, key)
    local die = math.random(1, 20)
    local total = die + attack.hit
    local text = ("attacks with %s: %d %s = %d"):format(attack.name, die, Signed(attack.hit), total)
    local targetKey = F.CreatureTarget(key)
    local target = targetKey and session.members[targetKey]
    local outcome
    if target then text, outcome = F.HitText(text, target, total, die) end
    if outcome == "miss" or #attack.parts == 0 then
        F.Say(text, member)
        return F.Changed()
    end
    local list = RollParts(attack.parts, die == 20)
    F.Say(target and ("%s for %s damage"):format(text, ListText(list)) or ("%s, for %s damage"):format(text, ListText(list)), member)
    if target then F.Hurt(targetKey, list) end
end

-- One of the saves a templated combatant forces, on the picked row. The damage is
-- rolled once a turn, so everyone caught in the same breath takes the same.
local rolled = {}
function F.CreatureForce(index, key)
    local session = F.session
    if not F.IsOwner() then return end
    key = key or session.turn
    local member = session.members[key or ""]
    local template = F.Template(member)
    local force = template and template.forces[index]
    if not force then return end
    local targetKey = F.CreatureTarget(key)
    local target = targetKey and session.members[targetKey]
    if not target then
        RPSheet:Print(("Click the health bar of who has to save against %s first."):format(force.name))
        return
    end
    local why = F.CreatureWhy("force", index, key, targetKey)
    if why then return RPSheet:Print(why) end
    F.CreatureSpent("force", index, key, targetKey)
    local mark = ("%s:%s:%d:%d:%s"):format(session.id, key, index, session.round, tostring(session.turn))
    if rolled.mark ~= mark then rolled.mark, rolled.list = mark, RollParts(force.parts) end
    local list = rolled.list
    local stat = R.STAT_NAMES[force.stat]
    if target.npc then
        local theirs = F.Template(target)
        local bonus = theirs and theirs.saves[force.stat] or 0
        local die = math.random(1, 20)
        local passed = die + bonus >= force.dc
        F.Say(("uses %s: %s rolls a %s save: %d %s = %d - %s against DC %d"):format(force.name, target.name, force.stat, die, Signed(bonus),
            die + bonus, passed and "succeeds" or "fails", force.dc), member)
        if not passed then F.Hurt(targetKey, list) elseif force.half then F.Hurt(targetKey, Halved(list)) end
        return
    end
    F.Say(("uses %s: %s makes a %s saving throw, DC %d."):format(force.name, target.name, stat, force.dc), member)
    F.pendingSaves[targetKey] = { dc = force.dc, list = list, half = force.half, name = force.name }
    if not F.Tell("V", { to = targetKey, stat = force.stat, dc = force.dc }) then RPSheet:Print("The request could not be sent.") end
end

-- A saving throw the owner asked for came back (FightOwner.lua): damage that waited
-- for it is dealt.
function F.SaveResolved(key, passed, dc)
    local pending = F.pendingSaves[key]
    if not pending or pending.dc ~= dc then return end
    F.pendingSaves[key] = nil
    local list = (not passed and pending.list) or (pending.half and Halved(pending.list)) or {}
    local member = F.session.members[key]
    if #list == 0 then
        if #pending.list > 0 then F.Say(("takes no damage from %s."):format(pending.name), member) end
        return
    end
    F.Say(("takes %s damage from %s%s."):format(ListText(list), pending.name, passed and " (half)" or ""), member)
    F.Hurt(key, list)
end

-- A template's numbers in a few lines, for a tooltip.
function F.CreatureSummary(template)
    local lines = {
        ("%s %s, challenge %s."):format(template.size, template.kind, template.cr),
        ("Armor Class %d, %d hit points, initiative %s."):format(template.ac, template.hp, (Signed(template.init):gsub(" ", ""))),
    }
    local saves = {}
    for _, stat in ipairs(R.STATS) do
        saves[#saves + 1] = ("%s %s"):format(stat, (Signed(template.saves[stat]):gsub(" ", "")))
    end
    lines[#lines + 1] = "Saves: " .. table.concat(saves, ", ") .. "."
    for _, field in ipairs({ { "resist", "Resists" }, { "immune", "Immune to" }, { "vulnerable", "Vulnerable to" } }) do
        local kinds = {}
        for _, kind in ipairs(R.DAMAGE_TYPES) do
            if template[field[1]][kind] then kinds[#kinds + 1] = kind end
        end
        if #kinds > 0 then lines[#lines + 1] = ("%s %s."):format(field[2], table.concat(kinds, ", ")) end
    end
    if #template.conditionImmune > 0 then lines[#lines + 1] = ("Can't be %s."):format(table.concat(template.conditionImmune, ", ")) end
    for _, attack in ipairs(template.attacks) do
        lines[#lines + 1] = ("%s: %s to hit%s."):format(attack.name, (Signed(attack.hit):gsub(" ", "")),
            #attack.parts > 0 and (", " .. R.DamagePartsText(attack.parts)) or "")
    end
    for _, force in ipairs(template.forces) do
        local note = F.ForceNote(force)
        lines[#lines + 1] = ("%s: %s save, DC %d%s%s%s."):format(force.name, force.stat, force.dc,
            #force.parts > 0 and (", " .. R.DamagePartsText(force.parts)) or "", force.half and ", half on a success" or "",
            note ~= "" and ("; " .. note) or "")
    end
    if template.attacksPerAction > 1 then lines[#lines + 1] = ("Its action is %d attacks."):format(template.attacksPerAction) end
    return table.concat(lines, "\n")
end

-- The templates whose name has `filter` in it, in the order of the list.
function F.CreatureMatches(filter)
    filter = tostring(filter or ""):lower()
    local names = {}
    for _, name in ipairs(R.CREATURE_ORDER) do
        if filter == "" or name:lower():find(filter, 1, true) then names[#names + 1] = name end
    end
    return names
end
