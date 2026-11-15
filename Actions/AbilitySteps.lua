-- Using an ability: the modifier of a ROLL step, and carrying out the steps that don't roll.
local _, ns = ...
local R = ns.Rules

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
    if costs.freeUse then self:TakeFreeUse(ability.name) end
    for _, action in ipairs(ability.actions) do
        if action.type == "GAIN" or action.type == "EMPTY" then
            local tracker = self:FindTracker(action.resource)
            if tracker then
                tracker.set(action.type == "EMPTY" and 0 or (tracker.get() + action.amount))
            end
        elseif action.type == "TOGGLE" then
            for _, passive in ipairs(self:Sheet().passives) do
                if passive.name == action.passive then
                    local wasOn = passive.enabled
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
                    -- Some passives end others when they start (see Sheet/Metamorphosis.lua).
                    if passive.enabled and not wasOn then self:PassiveSwitchedOn(passive) end
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

ns.AbilityKit.RollStep, ns.AbilityKit.ApplyChanges = RollStep, ApplyChanges
