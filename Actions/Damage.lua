-- Taking an amount of damage of a type, and healing by an amount.
-- A flat reduction comes off first, then resistance halves (rounded down), then
-- vulnerability doubles; immunity leaves nothing. Temporary hit points go before real
-- ones. Changing the HP bar by hand skips all of this and still works.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- What the damage comes to for this character, and the steps that changed it in words.
function RPSheet:AdjustDamage(amount, damageType, reduction)
    local defenses, notes, final = self:Defenses(), {}, amount
    if damageType and defenses.immune[damageType] then
        return 0, { ("none of it gets through (immunity: %s)"):format(defenses.immune[damageType]) }
    end
    if (reduction or 0) > 0 then
        final = math.max(0, final - reduction)
        notes[#notes + 1] = ("reduced by %d to %d"):format(reduction, final)
    end
    if damageType and defenses.resist[damageType] and final > 0 then
        final = math.floor(final / 2)
        notes[#notes + 1] = ("halved to %d (resistance: %s)"):format(final, defenses.resist[damageType])
    end
    if damageType and defenses.vulnerable[damageType] and final > 0 then
        final = final * 2
        notes[#notes + 1] = ("doubled to %d (vulnerability: %s)"):format(final, defenses.vulnerable[damageType])
    end
    return final, notes
end

-- Damage to a character already at 0 hit points: a failed death save, or death when
-- it is as much as the hit point maximum. Returns the words for the announcement.
local function HurtWhileDown(state, damage, max)
    if (state.deathFail or 0) >= 3 then return "Already dead" end
    if damage >= max then
        state.deathFail = 3
        return "Dead: that is as much as their hit point maximum"
    end
    if (state.deathPass or 0) >= 3 then state.deathPass, state.deathFail = 0, 0 end -- no longer stable
    state.deathFail = math.min(3, (state.deathFail or 0) + 1)
    if state.deathFail >= 3 then return "A third failed death save: dead" end
    return ("A failed death save: %d passed, %d failed"):format(state.deathPass or 0, state.deathFail)
end

-- `damageType` is one of Rules.DAMAGE_TYPES or nil for damage without a type;
-- `reduction` is taken off before anything else.
function RPSheet:TakeDamage(amount, damageType, reduction)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        self:Print("Give the damage as a number above 0, for example /sheet damage 14 fire.")
        return
    end
    local state, max = self:State(), self:MaxHP()
    local final, notes = self:AdjustDamage(amount, damageType, reduction)

    local absorbed = math.min(state.tempHP or 0, final)
    if absorbed > 0 then
        state.tempHP = state.tempHP - absorbed
        notes[#notes + 1] = ("%d taken by temporary hit points"):format(absorbed)
    end
    local left, before = final - absorbed, state.hp or max
    local wasDown, ending = before <= 0, nil
    if wasDown then
        if left > 0 then ending = HurtWhileDown(state, left, max) end
    else
        state.hp = math.max(0, before - left)
        if state.hp == 0 then
            self:ClearDeathSaves()
            ending = "Down at 0 HP"
            -- What is left over after reaching 0 kills outright if it is the maximum or more.
            if left - before >= max then
                state.deathFail = 3
                ending = "Dead: the damage left over is as much as their hit point maximum"
            end
        end
    end

    local text = ("takes %d %sdamage"):format(amount, damageType and (damageType .. " ") or "")
    if #notes > 0 then text = text .. ", " .. table.concat(notes, ", ") end
    text = ("%s: %d/%d HP"):format(text, state.hp or max, max)
    self:Announce(text .. (ending and (". " .. ending) or "") .. ".")

    -- The same as when hit points drop by hand: no spell or form survives 0 hit
    -- points, and other damage calls for a save to keep concentrating.
    if not wasDown and state.hp == 0 then
        self:EndConcentration("at 0 hit points")
        self:LeaveForms("at 0 hit points")
    elseif final > 0 and state.conditions.Concentrating then
        self:RollConcentration(final)
    end
    self:QueueBroadcast()
    self:PopulateSoon()
end

-- Regains hit points, up to the maximum.
function RPSheet:Heal(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        self:Print("Give the healing as a number above 0, for example /sheet heal 8.")
        return
    end
    local state, max = self:State(), self:MaxHP()
    local before = state.hp or max
    if before <= 0 and (state.deathFail or 0) >= 3 then
        self:Print("Your character is dead and can't regain hit points. If they are brought back, set the HP bar by hand.")
        return
    end
    state.hp = math.min(max, before + amount)
    if before <= 0 then self:ClearDeathSaves() end
    self:Announce(("regains %d hit points%s: %d/%d HP."):format(state.hp - before, before <= 0 and " and is back up" or "", state.hp, max))
    self:QueueBroadcast()
    self:PopulateSoon()
end

-- "/sheet damage 14 fire", "/sheet damage 14", "/sheet damage 28 fire -5" (5 taken
-- off first, as by a ward), "/sheet heal 8".
function RPSheet:DamageCommand(verb, rest)
    local amount = tonumber(rest:match("^(%d+)")) or 0
    if verb == "heal" then return self:Heal(amount) end
    local damageType = rest:match("^%d+%s+(%a+)")
    if damageType and not R.DAMAGE_TYPE[damageType] then
        self:Print(("\"%s\" is not a damage type. Use one of: %s."):format(damageType, table.concat(R.DAMAGE_TYPES, ", ")))
        return
    end
    self:TakeDamage(amount, damageType, tonumber(rest:match("%-%s*(%d+)%s*$")))
end
