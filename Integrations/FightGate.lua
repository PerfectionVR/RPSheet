-- Combat sessions, part 7: the sheet during a fight. While turns are being taken, an
-- attack, an ability or a spell is first held against what the turn allows
-- (FightTurn.lua) and refused with the reason; its cost is taken when its line is
-- announced, so something that was called off costs nothing. The line itself goes to
-- the session's owner, whose client announces it for everyone; rolls for initiative
-- and attack rolls travel with it as numbers.
--
-- This wraps RPSheet:Attack, :UnarmedAttack, :UseAbility, :CastSpell, :Announce and
-- :QueueBroadcast, and ns.RollText.Check: it loads after everything that defines or
-- wraps them.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local PENDING = 30 -- seconds an action that was let through waits for its line
local pending      -- what was let through last: { cost, name, slots, at }
local lastCheck    -- the d20 test in the line being made: { total, die, attack, initiative, label }

local function Slots(self)
    local sum = 0
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind == "slot" then sum = sum + tracker.get() end
    end
    return sum
end

-- True when the turn allows it; otherwise says why not.
local function Gate(self, cost, name, slot)
    pending = nil
    if not F.Running() then return true end
    local why = F.Why(cost, slot)
    if why then
        self:Print(("%s: %s"):format(name, why))
        return false
    end
    pending = { cost = cost, name = name, slots = Slots(self), at = GetTime() }
    return true
end

local Attack, UnarmedAttack, UseAbility, CastSpell = RPSheet.Attack, RPSheet.UnarmedAttack, RPSheet.UseAbility, RPSheet.CastSpell

function RPSheet:Attack(mode, answers)
    if not Gate(self, "ATTACK", "Attack") then return end
    return Attack(self, mode, answers)
end

function RPSheet:UnarmedAttack(mode, answers)
    if not Gate(self, "ATTACK", "Unarmed Strike") then return end
    return UnarmedAttack(self, mode, answers)
end

function RPSheet:UseAbility(ability, mode, answers)
    if not Gate(self, F.AbilityCost(ability), ability.name) then return end
    return UseAbility(self, ability, mode, answers)
end

function RPSheet:CastSpell(spell, mode, ritual, benefit, answers)
    local slot = spell.level > 0 and not ritual and spell.fromScroll == nil
    if not Gate(self, F.SpellCost(spell, ritual), spell.name, slot) then return end
    return CastSpell(self, spell, mode, ritual, benefit, answers)
end

-- One of the actions everyone has (Dash, Dodge, ...): nothing to roll, only said.
function F.TakeAction(name)
    if not Gate(RPSheet, "ACTION", name) then return end
    RPSheet:Announce(("takes the %s action."):format(ns.Mark(name)))
end

-- Who an attack is aimed at: the row picked in the combat window, or the player's
-- target in the game when that character is in the fight.
function F.Target()
    local session = F.session
    if F.target and session.members[F.target] then return F.target end
    local ok, key = pcall(ns.Game.UnitKey, "target")
    return ok and key and session.members[key] and key or nil
end

local Check = ns.RollText.Check
function ns.RollText.Check(label, d20, mod, note, extra)
    local plain = tostring(label):lower()
    lastCheck = {
        total = d20 + mod + (extra and extra.value or 0), die = d20,
        attack = plain:find("to hit", 1, true) ~= nil or plain:find("attack", 1, true) ~= nil,
        initiative = plain:find("initiative", 1, true) ~= nil,
        label = plain,
    }
    return Check(label, d20, mod, note, extra)
end

-- `speaker` is only given by the session itself: a combatant's name to say the line
-- for, "" for a line about the fight, true for this character outside the session.
local Announce = RPSheet.Announce
function RPSheet:Announce(text, speaker)
    if speaker ~= nil then return Announce(self, text, speaker ~= true and speaker or nil) end
    local check = lastCheck
    lastCheck = nil
    if not F.Mine() then return Announce(self, text) end
    if pending and F.Running() and GetTime() - pending.at < PENDING then
        F.Charge(pending.cost, pending.name, Slots(self) < pending.slots)
    end
    pending = nil
    local data = { text = text, target = F.Target() }
    if check then data.attack, data.total, data.die = check.attack, check.total, check.die end
    -- The saving throw the owner asked for: the owner's client says how it went.
    local owed = F.owedSave
    if check and owed and check.label:find(owed.stat:lower() .. " save", 1, true) then
        data.save, F.owedSave = owed.dc, nil
    end
    local owes = check and check.initiative and F.OwesInitiative()
    -- The owner can't be reached: the line is announced as outside a session.
    if not F.Request("A", data) then return Announce(self, text) end
    if ns.RestUndoExpire then ns.RestUndoExpire() end
    if owes then F.Request("R", { init = check.total, dex = self:Mod("DEX") }) end
    F.Changed()
end

-- Every refresh of the sheet ends here: the owner's list follows hit points and Armor Class.
local QueueBroadcast = RPSheet.QueueBroadcast
function RPSheet:QueueBroadcast(force)
    if F.session and not F.IsOwner() and not IsInGroup() then
        -- (this also runs when the group changes: Integrations/Sync.lua)
        self:Print("You are no longer in a group with the session's owner: the combat session is over for you.")
        F.Ended()
    elseif F.session then
        pcall(F.StatusChanged)
        F.Changed() -- slots and uses spent show in the combat window
    end
    return QueueBroadcast(self, force)
end
