-- Using an ability: a list of steps carried out in order (see Rules.ACTIONS).
-- Costs are checked first, then the rolls happen one after another, then resources
-- and passives are updated and one line is announced.
-- The parts are in Actions/AbilityCosts.lua and Actions/AbilitySteps.lua.
local _, ns = ...
local RPSheet = ns.addon
local RollText = ns.RollText
local CollectCosts = ns.AbilityKit.CollectCosts
local RollStep = ns.AbilityKit.RollStep
local ApplyChanges = ns.AbilityKit.ApplyChanges
local RollLabel = ns.AbilityKit.RollLabel

-- `mode` is "ADV" or "DIS" to roll the ability's d20s with advantage or disadvantage.
-- `answers` is what the player was asked about its rolls, by their label; without
-- it the sheet asks first when it needs to, before anything is spent.
function RPSheet:UseAbility(ability, mode, answers)
    -- One thing at a time: a roll that is still waiting for its result would be dropped.
    if self.busy or self:IsRolling() then return end
    -- A companion's strike rolls with its own numbers and riders (Actions/Pet.lua).
    if ns.PetAbility(self, ability, mode) then return end
    -- No actions while incapacitated; a saving throw of the character's own still rolls.
    if not ns.AbilityKit.OwnSaveOnly(ability) and self:CantAct("use " .. ability.name) then return end
    -- A beast's action that is used up until it recharges or a rest (Actions/BeastUses.lua).
    if self:BeastUseSpent(ability) then return end
    -- A Metamagic reroll needs a spell just cast (Actions/SpellFeats.lua): nothing is spent without one.
    if not self:CanReroll(ability) then return end

    local costs, costTexts = CollectCosts(self, ability)
    if not costs then return end
    if not answers then
        return ns.AbilityKit.AskRolls(self, ability, mode, function(found) self:UseAbility(ability, mode, found) end)
    end
    -- Steps that change spell slots are checked before anything is spent.
    local slotPlans = {}
    for _, action in ipairs(ability.actions) do
        if action.type == "SLOTS" then
            local plan = ns.PlanSlotAction(self, action, ability)
            if not plan then return end
            slotPlans[#slotPlans + 1] = plan
        end
    end

    local parts, index = {}, 0
    self.busy = true

    -- An ability with an attack roll is an attack of its own: its damage gets the
    -- passive damage bonus, and a natural 20 doubles its damage dice. Dice without an
    -- attack roll (Sneak Attack, a smite) are extra damage on top of a hit that already
    -- had the bonus. Each bonus is added once per use, however many dice steps there are.
    local isAttack, critical, bonusUsed, attackStat = false, false, {}, nil
    for _, action in ipairs(ability.actions) do
        if action.type == "ROLL" and (action.kind == "ATTACK" or action.kind == "SPELL") then
            isAttack = true
            if action.kind == "ATTACK" then attackStat = action.stat end
        end
    end
    local function PassiveBonus(target)
        if not target or bonusUsed[target] or (target == "DAMAGE" and not isAttack) then return 0 end
        bonusUsed[target] = true
        if target == "DAMAGE" then return self:DamageBonus(attackStat) end
        return self:Bonus(target)
    end

    local function finish()
        local switched = ApplyChanges(self, ability, costs)
        self:TakeBeastUse(ability)
        if costs.slotLevel then self.castLevel = nil end
        for _, plan in ipairs(slotPlans) do
            plan.apply()
            parts[#parts + 1] = plan.text
        end
        local text = "uses " .. ns.Mark(ability.name)
        if #costTexts > 0 then text = text .. " (" .. table.concat(costTexts, ", ") .. ")" end
        if #parts > 0 then text = text .. " - " .. table.concat(parts, ", ") end
        -- A beast form's attack says what else a hit does (Sheet/BeastForms.lua).
        local rider = ns.BeastRider(ability)
        if rider then text = text .. ". " .. rider end
        self.busy = false
        self:Announce(text)
        self:OfferRefund(ability, costs)
        if switched then
            self:ClampState()
            self:Populate()
        else
            self:Refresh()
        end
    end

    local function step()
        index = index + 1
        local action = ability.actions[index]
        if not action then return finish() end

        if action.type == "ROLL" then
            local label, mod = RollStep(self, action)
            -- The roll goes by the same rules as the sheet's own rows: what conditions
            -- and features do to an attack, a check or a saving throw of that ability.
            local rollMode, known, also = mode, RollLabel(action)
            local told = known and answers[known]
            if known then
                local failed = self:AutoFail(known)
                if failed then
                    parts[#parts + 1] = ("%s: fails without a roll (%s)"):format(label, ns.Mark(failed))
                    return step()
                end
                rollMode = self:ResolveMode(known, mode, also, nil, told or nil)
            end
            if told and told.about then label = ("%s against %s"):format(label, told.about) end
            self:RollTest(rollMode, function(d20, note, extra)
                -- A widened critical range is for weapon and unarmed attacks, not spells.
                if (action.kind == "ATTACK" and d20 >= self:CritFrom()) or (action.kind == "SPELL" and d20 == 20) then critical = true end
                parts[#parts + 1] = RollText.Check(label, d20, mod, note, extra)
                step()
            end)
        elseif action.type == "DICE" then
            local word, bonus = ns.DiceWord(action.dice)
            -- Some dice count once per level of the slot the ability spent.
            -- Without a slot of its own the ability goes by the "Cast at" row.
            local times = action.perSlot and (costs.slotLevel or self.castLevel or 1) or 1
            -- Dice that grow with each use since a long rest; the first use rolls none.
            local count = action.count
            if (action.strain or "") ~= "" then
                local tracker = self:FindTracker(action.strain)
                local used = tracker and (tracker.max - tracker.get()) or 0
                if used == 0 then
                    parts[#parts + 1] = "the first use costs nothing"
                    return step()
                end
                count = count + used - 1
            end
            local mod = self:Amount((action.flat or 0) * times, action.stat, 1) + PassiveBonus(bonus)
            local doubled = critical and word == "damage"
            local more = (action.slotAdd or 0) * math.max(0, (costs.slotLevel or 1) - 1)
            self:RollDice((count * times + more) * (doubled and 2 or 1), action.sides, function(rolls)
                -- A feat can reroll low dice or count them as higher (Sheet/DiceFeats.lua).
                local upTo, lowest = (action.reroll or 0) > 0 and action.reroll or nil, (action.lowest or 0) > 0 and action.lowest or nil
                self:AdjustRolls(rolls, action.sides, upTo, lowest, { reroll = action.rerollFrom, lowest = action.lowestFrom }, function(notes)
                    -- A feature can make low force damage dice count as higher.
                    local raised = action.damage == "force" and self:RaiseForceDice(rolls)
                    local note = self:ApplyDice(action.dice, rolls, mod)
                    -- Without dice it is a plain amount, such as temporary HP equal to a bonus.
                    local text = #rolls > 0 and RollText.Dice(doubled and "critical damage" or word, rolls, action.sides, mod)
                        or ("%s %d"):format(word, mod)
                    parts[#parts + 1] = text .. (raised and (" [" .. raised .. "]") or "") .. ns.DiceNotes(notes) .. (note and (" (" .. note .. ")") or "")
                    step()
                end)
            end)
        elseif action.type == "REROLL" then
            self:RerollLastSpell(action.mode, function(text)
                parts[#parts + 1] = text
                step()
            end)
        elseif action.type == "WEAPON" then
            local weapon = self:GetWeapon()
            if not weapon then return step() end
            -- The weapon's own damage always counts as an attack's damage.
            local target = weapon.heal and "HEALING" or "DAMAGE"
            local stat = self:WeaponStat(weapon)
            local mod = self:Mod(stat) + (bonusUsed[target] and 0 or (weapon.heal and self:Bonus(target) or self:DamageBonus(stat)))
            if not weapon.heal then mod = mod + (weapon.magic or 0) end -- a magic weapon's own bonus
            bonusUsed[target] = true
            local doubled = critical and not weapon.heal
            local count, sides = self:WeaponDice(weapon)
            self:RollDice(count * action.times * (doubled and 2 or 1), sides, function(rolls)
                parts[#parts + 1] = RollText.Dice(weapon.heal and "healing" or (doubled and "critical damage" or "damage"), rolls, sides, mod)
                step()
            end)
        else
            step()
        end
    end
    step()
end
