-- Combat sessions, part 11: what the owner does to a combatant, and handing the
-- session on. The owner picks a row of the combat window (F.target) and then:
--   * asks for a saving throw: the player is told, rolls it on their own sheet, and
--     the owner's client says whether it meets the DC;
--   * deals damage or heals: the player's own sheet takes it, with its resistances
--     and everything else "Take damage" does;
--   * hands the session to another player, whose client then keeps and announces it.
-- For a combatant the owner runs these happen here at once (FightCreatures.lua).
--
-- Messages, from the owner to the group, each naming who it is for (`to`):
--   V { to, stat, dc }     roll this saving throw
--   D { to, amount, type } take this damage      D { to, amount, heal = true }
--   O { id, to }           the session is yours
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local F = ns.Fight

-- To one combatant's client; the owner's own character is told on the spot.
local function Tell(kind, data)
    if data.to == F.Me() then
        F.player[kind](F.Me(), data)
        return true
    end
    return F.Send(kind, data)
end

-- The row the owner picked, or nil after saying that one is needed.
local function Picked()
    local session = F.session
    if not F.IsOwner() then return end
    local key = F.target
    local member = key and session.members[key]
    if not member then
        RPSheet:Print("Click a combatant's row in the combat window first.")
        return
    end
    return key, member
end

local function Stat(word)
    word = tostring(word or ""):upper()
    for _, stat in ipairs(R.STATS) do
        if word == stat or word == R.STAT_NAMES[stat]:upper() then return stat end
    end
end

-- "DEX 15": a saving throw from the picked combatant. For one the owner runs a bonus
-- can follow ("DEX 15 +2").
function F.AskSave(text)
    local key, member = Picked()
    if not key then return end
    local word, dc, bonus = tostring(text or ""):match("^%s*(%a+)[%s,]+(%d+)[%s,]*([+-]?%d*)%s*$")
    local stat = Stat(word)
    dc = F.Num(tonumber(dc), 1, 40, nil)
    if not stat or not dc then
        RPSheet:Print("Give the ability and the DC: DEX 15. For a combatant you run, its bonus too: DEX 15 +2")
        return
    end
    if member.npc then return F.CreatureSave(key, stat, dc, F.Num(tonumber(bonus) or 0, -10, 30, 0)) end
    F.Say(("makes a %s saving throw, DC %d."):format(R.STAT_NAMES[stat], dc), member)
    if not Tell("V", { to = key, stat = stat, dc = dc }) then RPSheet:Print("The request could not be sent.") end
end

-- "12 fire": damage to the picked combatant.
function F.DealDamage(text)
    local key, member = Picked()
    if not key then return end
    local amount, word = tostring(text or ""):lower():match("^%s*(%d+)%s*(%a*)%s*$")
    amount = F.Num(tonumber(amount), 1, 9999, nil)
    if not amount or (word ~= "" and not R.DAMAGE_TYPE[word]) then
        RPSheet:Print(("Give the amount, and the damage type if it has one: 12 fire. The types: %s."):format(table.concat(R.DAMAGE_TYPES, ", ")))
        return
    end
    if word == "" then word = nil end
    if member.npc then return F.ChangeCreatureHP(key, amount, word) end
    if not Tell("D", { to = key, amount = amount, type = word }) then RPSheet:Print("The damage could not be sent.") end
end

-- "8": hit points back for the picked combatant.
function F.HealTarget(text)
    local key, member = Picked()
    if not key then return end
    local amount = F.Num(tonumber(tostring(text or ""):match("%d+")), 1, 9999, nil)
    if not amount then
        RPSheet:Print("Give the hit points as a number: 8")
        return
    end
    if member.npc then return F.ChangeCreatureHP(key, -amount) end
    if not Tell("D", { to = key, amount = amount, heal = true }) then RPSheet:Print("The healing could not be sent.") end
end

-- The picked player owns the session from now on.
function F.HandOver()
    local key, member = Picked()
    if not key then return end
    if member.npc or key == F.Me() then
        RPSheet:Print("Pick another player's row to hand the session to.")
        return
    end
    local session = F.session
    F.Say(("The combat session is now %s's."):format(member.name))
    -- The session as it stands goes first, so the new owner starts from the same.
    F.Send("S", session)
    if not F.Send("O", { id = session.id, to = key }) then
        RPSheet:Print("The session could not be handed over.")
        return
    end
    session.owner = key
    RPSheet.db.char.fightOwned = nil
    F.target = nil
    F.Changed()
end

---------------------------------------------------------------------------
-- A player's side
---------------------------------------------------------------------------
-- True when it comes from the owner of the session this character is in, for it.
local function ForMe(sender, data)
    return F.Mine() ~= nil and F.session.owner == sender and data.to == F.Me()
end

function F.player.V(sender, data)
    if not ForMe(sender, data) then return end
    local stat, dc = Stat(data.stat), F.Num(data.dc, 1, 40, nil)
    if not stat or not dc then return end
    F.owedSave = { stat = stat, dc = dc }
    RPSheet:Print(("Make a %s saving throw, DC %d: its row on your sheet, or the button in the combat window."):format(R.STAT_NAMES[stat], dc))
    F.ShowWindow()
    F.Changed()
end

-- Rolls the saving throw that was asked for.
function F.RollOwedSave()
    local owed = F.owedSave
    if not owed then return end
    RPSheet:RollCheck(owed.stat .. " save", RPSheet:SaveMod(owed.stat), ns.RollMode())
end

function F.player.D(sender, data)
    if not ForMe(sender, data) then return end
    local amount = F.Num(data.amount, 1, 9999, nil)
    if not amount then return end
    local owner = F.session.members[sender]
    if data.heal == true then
        RPSheet:Print(("%s gives you %d hit points back."):format(owner and owner.name or "The session's owner", amount))
        return RPSheet:Heal(amount)
    end
    local kind = type(data.type) == "string" and R.DAMAGE_TYPE[data.type] and data.type or nil
    RPSheet:Print(("%s deals you %d %sdamage."):format(owner and owner.name or "The session's owner", amount, kind and (kind .. " ") or ""))
    RPSheet:TakeDamage(amount, kind)
end

-- The session has a new owner. Everyone follows; the new owner's client takes it up.
function F.player.O(sender, data)
    local session = F.session
    if not session or session.owner ~= sender or session.id ~= F.Text(data.id, 12) then return end
    local to = type(data.to) == "string" and session.members[data.to] and not session.members[data.to].npc and data.to
    if not to then return end
    session.owner = to
    if to == F.Me() then
        RPSheet:Print("The combat session is yours now: the combat window has the owner's buttons.")
        F.Rebroadcast()
        F.ShowWindow()
    end
    F.Changed()
end
