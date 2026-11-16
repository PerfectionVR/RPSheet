-- Taking an amount of damage of a type, and healing by an amount.
-- Flat reductions come off first (wards, feats, traits), then a feature that halves
-- or cancels the damage, then resistance halves (rounded down), then vulnerability
-- doubles; immunity leaves nothing. Temporary hit points go before real ones.
-- Changing the HP bar by hand skips all of this and still works.
-- What the character's own features do is in Actions/DamageSteps.lua; what keeps
-- them up at 0 hit points, and damage while down, in Actions/DamageZero.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- What the damage comes to for this character, the steps that changed it in words,
-- and the features that took part (Actions/DamageSteps.lua; nil when immune).
-- `why` names what the reduction comes from, when that is worth saying; `how` is
-- what the player said about the damage (see RPSheet:DamageSteps).
function RPSheet:AdjustDamage(amount, damageType, reduction, why, how)
    local defenses, notes, final = self:Defenses(), {}, amount
    if damageType and defenses.immune[damageType] then
        return 0, { ("none of it gets through (immunity: %s)"):format(defenses.immune[damageType]) }
    end
    local steps, whys = self:DamageSteps(damageType, how), {}
    if why and why ~= "" then whys[1] = why end
    reduction = reduction or 0
    for _, step in ipairs(steps.flat) do
        reduction = reduction + step[1]
        whys[#whys + 1] = ("%s %d"):format(step[2], step[1])
    end
    if reduction > 0 then
        final = math.max(0, final - reduction)
        notes[#notes + 1] = ("reduced by %d to %d%s"):format(reduction, final, #whys > 0 and (" (" .. table.concat(whys, "; ") .. ")") or "")
    end
    if steps.none and final > 0 then
        final = 0
        notes[#notes + 1] = ("none of it (%s)"):format(steps.none)
    elseif steps.half and final > 0 then
        final = math.floor(final / 2)
        notes[#notes + 1] = ("halved to %d (%s)"):format(final, steps.half)
    end
    -- Resistance counts once, whether the character has it or a reaction gave it.
    local resisted = (damageType and defenses.resist[damageType]) or steps.resist
    if resisted and final > 0 then
        final = math.floor(final / 2)
        notes[#notes + 1] = ("halved to %d (resistance: %s)"):format(final, resisted)
    end
    if damageType and defenses.vulnerable[damageType] and final > 0 then
        final = final * 2
        notes[#notes + 1] = ("doubled to %d (vulnerability: %s)"):format(final, defenses.vulnerable[damageType])
    end
    return final, notes, steps
end

-- The hit points are changed and everything is said. `kept` is what the hit points
-- are instead of 0 (Death Ward, Relentless Rage), and `saved` says why.
local function Finish(self, d, kept, saved)
    local state, max = self:State(), self:MaxHP()
    local ending
    if d.wasDown then
        if d.left > 0 then ending = ns.HurtWhileDown(state, d.left, max, d.crit) end
    elseif kept then
        state.hp = kept
    else
        state.hp = math.max(0, d.before - d.left)
        if state.hp == 0 then
            self:ClearDeathSaves()
            ending = "Down at 0 HP"
            -- What is left over after reaching 0 kills outright if it is the maximum or more.
            if d.left - d.before >= max then
                state.deathFail = 3
                ending = "Dead: the damage left over is as much as their hit point maximum"
            end
        end
    end
    if saved then d.notes[#d.notes + 1] = saved end
    local text = ("takes %d %sdamage"):format(d.amount, d.damageType and (d.damageType .. " ") or "")
    if #d.notes > 0 then text = text .. ", " .. table.concat(d.notes, ", ") end
    text = ("%s: %d/%d HP"):format(text, state.hp or max, max)
    self:Announce(text .. (ending and (". " .. ending) or "") .. ".")

    -- The same as when hit points drop by hand: no spell or form survives 0 hit
    -- points, and other damage calls for a save to keep concentrating.
    if not d.wasDown and state.hp == 0 then
        self:EndConcentration("at 0 hit points")
        self:LeaveForms("at 0 hit points")
    elseif d.final > 0 and state.conditions.Concentrating then
        self:RollConcentration(d.final)
    end
    self:EndBondsAtZero() -- a Warding Bond the character cast (Actions/WardDamage.lua)
    self:QueueBroadcast()
    self:PopulateSoon()
end

-- Takes the damage once everything that comes off first is known. `ward` is what a
-- companion's gift rolled against it: { name, sides, rolled }; `why` says where a
-- `reduction` comes from; `crit` is true for a critical hit; `how`: RPSheet:DamageSteps.
local function Apply(self, amount, damageType, reduction, ward, why, crit, how)
    local state, max = self:State(), self:MaxHP()
    local final, notes, steps = self:AdjustDamage(amount, damageType, (reduction or 0) + (ward and ward.rolled or 0), why, how)
    if ward then table.insert(notes, 1, ("%s takes 1d%d = %d off"):format(ward.name, ward.sides, ward.rolled)) end
    if how and how.said then table.insert(notes, 1, how.said) end -- the roll it came from: a fall, a pool
    if steps then self:DamageStepsTaken(steps, how, damageType, final, notes) end

    local absorbed = math.min(state.tempHP or 0, final)
    if absorbed > 0 then
        state.tempHP = state.tempHP - absorbed
        notes[#notes + 1] = ("%d taken by temporary hit points"):format(absorbed)
    end
    local d = { amount = amount, damageType = damageType, final = final, notes = notes, crit = crit,
        left = final - absorbed, before = state.hp or max }
    d.wasDown = d.before <= 0
    -- Dropping to 0: a spell or a rage can still keep the character up.
    self:CatchAtZero(d.left, d.before, max, function(kept, saved) Finish(self, d, kept, saved) end)
end

-- `damageType` is one of Rules.DAMAGE_TYPES or nil for damage without a type;
-- `reduction` is taken off before anything else, and `why` says where it comes from.
-- `crit` is true when the hit was a critical one: the amount is typed as it was
-- rolled, so that only matters to a character at 0 hit points. `how` is what the
-- damage menu was told about the damage (Actions/DamageSteps.lua).
-- Actions/WardDamage.lua wraps this to roll the wards that take dice off the damage.
function RPSheet:TakeDamage(amount, damageType, reduction, why, crit, how)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        self:Print("Give the damage as a number above 0, for example /sheet damage 14 fire.")
        return
    end
    -- A loyal mechanical companion: a die comes off psychic damage each time. Nothing
    -- is rolled against damage the character is immune to.
    local sides, companion = self:CompanionWard(damageType)
    if not sides or self:Defenses().immune[damageType] then return Apply(self, amount, damageType, reduction, nil, why, crit, how) end
    if self.busy or self:IsRolling() then
        self:Print("Another roll is still going. Take the damage again when it is done.")
        return
    end
    self:Roll(sides, function(rolled)
        Apply(self, amount, damageType, reduction, { name = companion.name, sides = sides, rolled = rolled }, why, crit, how)
    end)
end

-- Regains hit points, up to the maximum. `from` names where they come from.
function RPSheet:Heal(amount, from)
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
    self:Announce(("regains %d hit points%s%s: %d/%d HP."):format(state.hp - before, from and (" (" .. from .. ")") or "",
        before <= 0 and " and is back up" or "", state.hp, max))
    self:QueueBroadcast()
    self:PopulateSoon()
end

-- "/sheet damage 14 fire", "/sheet damage 14", "/sheet damage 28 fire -5" (5 taken
-- off first, as by a ward), "/sheet damage 14 fire crit" (a critical hit, with the
-- word anywhere after the amount), "/sheet heal 8".
function RPSheet:DamageCommand(verb, rest)
    local amount = tonumber(rest:match("^(%d+)")) or 0
    if verb == "heal" then return self:Heal(amount) end
    local crit
    rest, crit = rest:gsub("%f[%a][Cc][Rr][Ii][Tt]%a*", "")
    local damageType = rest:match("^%d+%s+(%a+)")
    if damageType and not R.DAMAGE_TYPE[damageType] then
        self:Print(("\"%s\" is not a damage type. Use one of: %s."):format(damageType, table.concat(R.DAMAGE_TYPES, ", ")))
        return
    end
    self:TakeDamage(amount, damageType, tonumber(rest:match("%-%s*(%d+)%s*$")), nil, crit > 0)
end
