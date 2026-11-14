-- Using an ability: a list of steps carried out in order (see Rules.ACTIONS).
-- Costs are checked first, then the rolls happen one after another, then resources
-- and passives are updated and one line is announced.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- Short description of one step, for tooltips and the editor.
function RPSheet:ActionText(action)
    local kind = action.type
    if kind == "ROLL" then
        local parts = { "d20" }
        if R.STAT_NAMES[action.stat] then parts[#parts + 1] = action.stat end
        if R.STAT_NAMES[action.stat2] then parts[#parts + 1] = action.stat2 end
        if action.proficient then parts[#parts + 1] = "proficiency" end
        if (action.rollFlat or 0) ~= 0 then parts[#parts + 1] = tostring(action.rollFlat) end
        return ("%s: %s"):format(R.ROLL_KINDS[action.kind] or "Roll", table.concat(parts, " + "))
    elseif kind == "DICE" then
        local text = R.DICE_KINDS[action.dice] or "Dice"
        text = action.count > 0 and ("%s: %dd%d"):format(text, action.count, action.sides) or (text .. ":")
        if (action.flat or 0) ~= 0 then text = text .. " + " .. action.flat end
        if action.perSlot then text = text .. " per slot level" end
        if (action.strain or "") ~= "" then text = text .. ", more with each use" end
        if (action.slotAdd or 0) > 0 then text = text .. (", +%dd%d per slot level above 1st"):format(action.slotAdd, action.sides) end
        if R.AMOUNT_SOURCES[action.stat] and action.stat ~= "" then
            text = text .. " + " .. (R.AMOUNT_SHORT[action.stat] or action.stat)
        end
        return text
    elseif kind == "WEAPON" then
        return ("Weapon dice x%d"):format(action.times)
    elseif kind == "SPEND" then
        local text = ("Spend %d %s"):format(action.amount, action.resource)
        if action.freeIfFull ~= "" then text = text .. (" (free when %s is full)"):format(action.freeIfFull) end
        return text
    elseif kind == "GAIN" then
        return ("Regain %d %s"):format(action.amount, action.resource)
    elseif kind == "EMPTY" then
        return ("Empty %s"):format(action.resource)
    elseif kind == "TOGGLE" then
        return ("%s: %s"):format(R.TOGGLE_MODES[action.mode] or "Flip", action.passive)
    elseif kind == "SLOTS" then
        return ns.SLOT_ACTION_TEXT[action.mode] or "Spell slots"
    elseif kind == "NEXTROLL" then
        return ("Next roll: %s"):format(action.mode == "DIS" and "disadvantage" or "advantage")
    end
    return "?"
end

-- Works out what the SPEND steps cost. Returns the costs and their wording, or nil
-- (after telling the player why) when the ability can't be paid for.
local function CollectCosts(self, ability)
    local costs, texts = {}, {}
    for _, action in ipairs(ability.actions) do
        if action.type == "SPEND" then
            local tracker = self:FindTracker(action.resource)
            if not tracker then
                self:Print(("%s needs the resource \"%s\", which this sheet doesn't have."):format(ability.name, action.resource))
                return
            end
            -- The "Cast at" row picks a higher slot to pay with.
            if tracker.kind == "slot" and self.castLevel and self.castLevel > tracker.level then
                for _, other in ipairs(self:GetTrackers()) do
                    if other.kind == "slot" and other.level == self.castLevel then tracker = other end
                end
            end
            -- A spell slot that is used up can be paid with the lowest higher one left.
            if tracker.kind == "slot" and tracker.get() < action.amount then
                for _, other in ipairs(self:GetTrackers()) do
                    if other.kind == "slot" and other.level > tracker.level and other.get() >= action.amount then
                        tracker = other
                        break
                    end
                end
            end
            local full = action.freeIfFull ~= "" and self:FindTracker(action.freeIfFull)
            if full and full.get() >= full.max then
                texts[#texts + 1] = ("free, %s is full"):format(full.label)
            else
                costs[#costs + 1] = { tracker = tracker, amount = action.amount }
                if tracker.kind == "slot" then costs.slotLevel = tracker.level end
                texts[#texts + 1] = ("%d %s"):format(action.amount, tracker.label)
            end
        end
    end
    local needed = {}
    for _, cost in ipairs(costs) do
        local label = cost.tracker.label
        needed[label] = (needed[label] or 0) + cost.amount
        if needed[label] > cost.tracker.get() then
            self:Print(("Not enough %s for %s (%d needed, %d left)."):format(label, ability.name, needed[label], cost.tracker.get()))
            return
        end
    end
    return costs, texts
end

-- Modifier and label for a ROLL step.
local function RollStep(self, action)
    local labels, mod = {}, 0
    for _, stat in ipairs({ action.stat, action.stat2 }) do
        if R.STAT_NAMES[stat] then
            labels[#labels + 1] = stat
            mod = mod + self:Mod(stat)
        end
    end
    if action.proficient then mod = mod + self:ProficiencyBonus() end
    mod = mod + (action.rollFlat or 0) -- a bonus of its own, such as a beast form's attack
    if action.kind == "ATTACK" then
        mod = mod + self:Bonus("ATTACK")
    elseif action.kind == "SPELL" then
        mod = mod + self:Bonus("SPELLATK")
    elseif action.kind == "SAVE" then
        mod = mod + self:Bonus("SAVES")
    else
        mod = mod + self:Bonus("CHECKS")
    end
    local label = (R.ROLL_KINDS[action.kind] or "Roll"):lower()
    if #labels > 0 then label = label .. " (" .. table.concat(labels, " + ") .. ")" end
    return label, mod
end

-- Applies the steps that don't roll anything. Returns true if a passive was switched.
local function ApplyChanges(self, ability, costs)
    local switched = false
    for _, cost in ipairs(costs) do
        cost.tracker.set(cost.tracker.get() - cost.amount)
    end
    for _, action in ipairs(ability.actions) do
        if action.type == "GAIN" or action.type == "EMPTY" then
            local tracker = self:FindTracker(action.resource)
            if tracker then
                tracker.set(action.type == "EMPTY" and 0 or (tracker.get() + action.amount))
            end
        elseif action.type == "TOGGLE" then
            for _, passive in ipairs(self:Sheet().passives) do
                if passive.name == action.passive then
                    if action.mode == "ON" then
                        passive.enabled = true
                        -- Taking a form ends any other form.
                        if R.FORMS[passive.name] then
                            for _, other in ipairs(self:Sheet().passives) do
                                if other ~= passive and R.FORMS[other.name] then other.enabled = false end
                            end
                        end
                    elseif action.mode == "OFF" then
                        passive.enabled = false
                    else
                        passive.enabled = not passive.enabled
                    end
                    switched = true
                end
            end
        elseif action.type == "NEXTROLL" then
            -- Sets the "Next roll" row; it is used up by the next d20.
            self.rollMode, self.rollModeLocked = action.mode == "DIS" and "DIS" or "ADV", false
        end
    end
    return switched
end

-- `mode` is "ADV" or "DIS" to roll the ability's d20s with advantage or disadvantage.
function RPSheet:UseAbility(ability, mode)
    -- One thing at a time: a roll that is still waiting for its result would be dropped.
    if self.busy or self:IsRolling() then return end

    local costs, costTexts = CollectCosts(self, ability)
    if not costs then return end
    -- Steps that change spell slots are checked before anything is spent.
    local slotPlans = {}
    for _, action in ipairs(ability.actions) do
        if action.type == "SLOTS" then
            local plan = ns.PlanSlotAction(self, action)
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
        if costs.slotLevel then self.castLevel = nil end
        for _, plan in ipairs(slotPlans) do
            plan.apply()
            parts[#parts + 1] = plan.text
        end
        local text = "uses " .. ns.Mark(ability.name)
        if #costTexts > 0 then text = text .. " (" .. table.concat(costTexts, ", ") .. ")" end
        if #parts > 0 then text = text .. " - " .. table.concat(parts, ", ") end
        self.busy = false
        self:Announce(text)
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
            local rollMode = mode
            if action.kind == "ATTACK" then
                rollMode = self:ResolveMode("attack", mode, action.stat == "STR" and "STR attack" or nil)
            elseif action.kind == "SPELL" then
                rollMode = self:ResolveMode("spell attack", mode)
            end
            self:RollD20(rollMode, function(d20, note)
                -- A widened critical range is for weapon and unarmed attacks, not spells.
                if (action.kind == "ATTACK" and d20 >= self:CritFrom()) or (action.kind == "SPELL" and d20 == 20) then critical = true end
                parts[#parts + 1] = RollText.Check(label, d20, mod, note)
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
                local note = self:ApplyDice(action.dice, rolls, mod)
                -- Without dice it is a plain amount, such as temporary HP equal to a bonus.
                local text = #rolls > 0 and RollText.Dice(doubled and "critical damage" or word, rolls, action.sides, mod)
                    or ("%s %d"):format(word, mod)
                parts[#parts + 1] = text .. (note and (" (" .. note .. ")") or "")
                step()
            end)
        elseif action.type == "WEAPON" then
            local weapon = self:GetWeapon()
            if not weapon then return step() end
            -- The weapon's own damage always counts as an attack's damage.
            local target = weapon.heal and "HEALING" or "DAMAGE"
            local stat = self:WeaponStat(weapon)
            local mod = self:Mod(stat) + (bonusUsed[target] and 0 or (weapon.heal and self:Bonus(target) or self:DamageBonus(stat)))
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
