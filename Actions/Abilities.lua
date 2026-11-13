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
        return ("%s: %s"):format(R.ROLL_KINDS[action.kind] or "Roll", table.concat(parts, " + "))
    elseif kind == "DICE" then
        local text = ("%s: %dd%d"):format(R.DICE_KINDS[action.dice] or "Dice", action.count, action.sides)
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
            local full = action.freeIfFull ~= "" and self:FindTracker(action.freeIfFull)
            if full and full.get() >= full.max then
                texts[#texts + 1] = ("free, %s is full"):format(full.label)
            else
                costs[#costs + 1] = { tracker = tracker, amount = action.amount }
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
                    elseif action.mode == "OFF" then
                        passive.enabled = false
                    else
                        passive.enabled = not passive.enabled
                    end
                    switched = true
                end
            end
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

    local parts, index = {}, 0
    self.busy = true

    local function finish()
        local switched = ApplyChanges(self, ability, costs)
        local text = "uses " .. ability.name
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
            self:RollD20(mode, function(d20, note)
                parts[#parts + 1] = RollText.Check(label, d20, mod, note)
                step()
            end)
        elseif action.type == "DICE" then
            local healing = action.dice == "HEALING"
            local mod = self:Amount(0, action.stat, 1) + self:Bonus(healing and "HEALING" or "DAMAGE")
            self:RollDice(action.count, action.sides, function(rolls)
                parts[#parts + 1] = RollText.Dice(healing and "healing" or "damage", rolls, action.sides, mod)
                step()
            end)
        elseif action.type == "WEAPON" then
            local weapon = self:GetWeapon()
            if not weapon then return step() end
            local mod = self:Mod(weapon.stat) + self:Bonus(weapon.heal and "HEALING" or "DAMAGE")
            self:RollDice(weapon.dice * action.times, weapon.sides, function(rolls)
                parts[#parts + 1] = RollText.Dice(weapon.heal and "healing" or "damage", rolls, weapon.sides, mod)
                step()
            end)
        else
            step()
        end
    end
    step()
end
