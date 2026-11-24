-- Combat sessions, part 6: what a turn allows. On your turn: one action, one bonus
-- action when something gives you one, and only one spell that spends a slot. The
-- Attack action is as many attacks as Extra Attack gives. A reaction can be taken on
-- anyone's turn and comes back at the start of your own. What costs nothing of these
-- (a passive's roll, a feature that takes no action) is never held back.
--
-- Costs: "ACTION", "ATTACK" (one attack of the Attack action), "BONUS", "REACTION",
-- "LONG" (longer than a turn: not in a fight) and "FREE".
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight

local used = {} -- this turn: action, bonus, slot, attacked, attacks (left of the Attack action)
F.used = used

function F.ResetTurn()
    wipe(used)
end

-- How many attacks the Attack action is, by the Extra Attack feature's own words.
function F.AttacksPerAction()
    for _, passive in ipairs(RPSheet:Sheet().passives) do
        if passive.name == "Extra Attack" and passive.enabled then
            local desc = type(passive.desc) == "string" and passive.desc or ""
            return (desc:find("four times") and 4) or (desc:find("three times") and 3) or 2
        end
    end
    return 1
end

-- What an ability costs, read from how its description starts ("Bonus action: ...").
function F.AbilityCost(ability)
    local desc = (type(ability.desc) == "string" and ability.desc or ""):lower()
    if desc:find("^bonus action") then return "BONUS" end
    if desc:find("^reaction") then return "REACTION" end
    if desc:find("^magic action") or desc:find("^action") then return "ACTION" end
    for _, step in ipairs(ability.actions or {}) do
        if step.kind == "ATTACK" then return "ATTACK" end
    end
    return "FREE"
end

function F.SpellCost(spell, ritual)
    if ritual then return "LONG" end -- a ritual takes ten minutes more
    local time = spell.time or "ACTION"
    return (time == "BONUS" or time == "REACTION" or time == "LONG") and time or "ACTION"
end

-- Why something of that cost can't be done right now, or nil when it can. `slot` is
-- true for a spell that spends a spell slot.
function F.Why(cost, slot)
    if not F.Running() then return nil end
    if cost == "LONG" then return "It takes longer than a turn." end
    if cost == "FREE" then return nil end
    if cost == "REACTION" then
        return RPSheet:State().reactionUsed and "You have used your reaction. It comes back at the start of your turn." or nil
    end
    if not F.MyTurn() then
        local holder = F.session.members[F.session.turn or ""]
        return holder and ("It is %s's turn."):format(holder.name) or "It is not your turn."
    end
    if slot and used.slot then return "You have spent a spell slot this turn already: one spell with a slot per turn." end
    if cost == "BONUS" then return used.bonus and "You have used your bonus action this turn." or nil end
    if cost == "ATTACK" and (used.attacks or 0) > 0 then return nil end
    if used.action then
        if cost == "ATTACK" and used.attacked then return "You have made every attack of your Attack action." end
        return "You have used your action this turn."
    end
    return nil
end

-- Takes the cost of something that went through. `slotSpent`: it spent a spell slot.
function F.Charge(cost, name, slotSpent)
    if cost == "REACTION" then
        RPSheet:State().reactionUsed = true
    elseif cost == "BONUS" then
        used.bonus = true
    elseif cost == "ACTION" then
        used.action = true
    elseif cost == "ATTACK" then
        if (used.attacks or 0) > 0 then
            used.attacks = used.attacks - 1
        else
            used.action, used.attacked, used.attacks = true, true, F.AttacksPerAction() - 1
        end
    end
    if slotSpent then used.slot = true end
    -- One more action this turn.
    if name == "Action Surge" then used.action, used.attacked, used.attacks = false, false, 0 end
end

-- This character's turn begins.
function F.TurnStarts()
    F.ResetTurn()
    RPSheet:State().reactionUsed = nil
    RPSheet:Print(("Your turn (round %d): an action, a bonus action if something gives you one, and your reaction is back."):format(F.session.round))
    if RPSheet:IsDown() then RPSheet:Print("You are at 0 hit points: roll a death save.") end
    if PlaySound then pcall(PlaySound, 8960) end
    RPSheet:PopulateSoon()
    F.ShowWindow()
end

-- "Action used, 1 attack left, bonus action free, reaction free"
function F.TurnText()
    local parts = {}
    if used.action and (used.attacks or 0) > 0 then
        parts[#parts + 1] = ("action used, %d more %s"):format(used.attacks, used.attacks == 1 and "attack" or "attacks")
    else
        parts[#parts + 1] = used.action and "action used" or "action free"
    end
    parts[#parts + 1] = used.bonus and "bonus action used" or "bonus action free"
    parts[#parts + 1] = RPSheet:State().reactionUsed and "reaction used" or "reaction free"
    if used.slot then parts[#parts + 1] = "spell slot spent" end
    return table.concat(parts, ", ")
end
