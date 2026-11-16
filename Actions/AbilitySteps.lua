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

-- The label a ROLL step goes by in the roll rules (Sheet/RollModes.lua), such as
-- "attack" or "CON save", and a second one for an attack made with Strength. Nil for
-- a roll the rules can't place: a check or save without an ability.
local function RollLabel(action)
    if action.kind == "ATTACK" then return "attack", action.stat == "STR" and "STR attack" or nil end
    if action.kind == "SPELL" then return "spell attack" end
    if not R.STAT_NAMES[action.stat] then return end
    return action.stat .. (action.kind == "SAVE" and " save" or " check")
end

-- True for an ability that only rolls the character's own saving throw: no action,
-- so it is still there for a character that can't act.
local function OwnSaveOnly(ability)
    local saves = 0
    for _, action in ipairs(ability.actions) do
        if action.type ~= "ROLL" or action.kind ~= "SAVE" then return false end
        saves = saves + 1
    end
    return saves > 0
end

-- Asks what the ability's rolls need to know (Actions/RollQuestions.lua), each kind
-- of roll once, then calls go(answers) with what was said by label.
local function AskRolls(self, ability, mode, go)
    local labels, found = {}, {}
    for _, action in ipairs(ability.actions) do
        local label, also = nil, nil
        if action.type == "ROLL" then label, also = RollLabel(action) end
        if label and found[label] == nil then
            found[label] = false
            labels[#labels + 1] = { label, also }
        end
    end
    local function ask(index)
        local entry = labels[index]
        if not entry then return go(found) end
        -- A save that fails without a roll has nothing to ask.
        if self:AutoFail(entry[1]) then return ask(index + 1) end
        self:AskRoll(entry[1], mode, entry[2], function(answers)
            found[entry[1]] = answers
            ask(index + 1)
        end)
    end
    ask(1)
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
ns.AbilityKit.RollLabel, ns.AbilityKit.OwnSaveOnly, ns.AbilityKit.AskRolls = RollLabel, OwnSaveOnly, AskRolls
