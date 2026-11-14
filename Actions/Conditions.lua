-- Conditions and exhaustion: what the character is under right now.
-- Conditions are reminders, announced when they change. Exhaustion changes numbers
-- (see RPSheet:Bonus in Sheet/Derived.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Names of the active conditions, in the order of Rules.CONDITIONS.
function RPSheet:Conditions()
    local state, active = self:State(), {}
    for _, condition in ipairs(R.CONDITIONS) do
        if state.conditions[condition.name] then active[#active + 1] = condition.name end
    end
    return active
end

function RPSheet:Exhaustion()
    return self:State().exhaustion or 0
end

-- Conditions that leave a character incapacitated, which ends concentration.
local INCAPACITATES = { Incapacitated = true, Paralyzed = true, Petrified = true, Stunned = true, Unconscious = true }

-- Ends the spell being concentrated on, with the reason for the announcement. Does
-- nothing when the character isn't concentrating.
function RPSheet:EndConcentration(reason)
    local conditions = self:State().conditions
    if not conditions.Concentrating then return end
    conditions.Concentrating = nil
    -- A save still waiting for the damage clicks to stop is no longer needed.
    if self.concentrationTimer then self.concentrationTimer:Cancel() end
    self.concentrationDamage, self.concentrationTimer = nil, nil
    self:Announce(("loses %s: %s."):format(ns.Mark("Concentrating"), reason))
    self:QueueBroadcast()
    self:PopulateSoon()
end

function RPSheet:ToggleCondition(name)
    local conditions = self:State().conditions
    conditions[name] = not conditions[name] or nil
    local term = ns.Mark(name)
    self:Announce(conditions[name] and ("is now %s."):format(term) or ("is no longer %s."):format(term))
    if conditions[name] and INCAPACITATES[name] then
        self:EndConcentration(name:lower())
        self:LeaveForms(name:lower()) -- a Wild Shape form ends too
    end
    self:QueueBroadcast()
    self:PopulateSoon()
end

function RPSheet:ChangeExhaustion(delta)
    local state = self:State()
    local level = math.max(0, math.min(R.MAX_EXHAUSTION, self:Exhaustion() + delta))
    if level == self:Exhaustion() then return end
    state.exhaustion = level
    self:Announce(level == 0 and "is no longer exhausted." or ("is at exhaustion level %d."):format(level))
    self:QueueBroadcast()
    self:PopulateSoon()
end

-- Damage taken while concentrating calls for a Constitution save. Hit points go down
-- a click at a time, so the reminder waits until the clicking stops.
function RPSheet:DamageTaken(amount)
    if not self:State().conditions.Concentrating then return end
    self.concentrationDamage = (self.concentrationDamage or 0) + amount
    if self.concentrationTimer then self.concentrationTimer:Cancel() end
    self.concentrationTimer = C_Timer.NewTimer(2.5, function()
        local damage = self.concentrationDamage or 0
        self.concentrationDamage, self.concentrationTimer = nil, nil
        if damage > 0 and self:State().conditions.Concentrating then
            self:RollConcentration(damage)
        end
    end)
end

-- The Constitution save to keep a spell after taking damage: DC 10, or half the damage
-- if that is higher, 30 at most. A failure ends the concentration.
function RPSheet:RollConcentration(damage)
    local dc = math.min(30, math.max(10, math.floor(damage / 2)))
    if self.busy or self:IsRolling() then
        self:Print(("You took %d damage while concentrating: roll a Constitution save, DC %d, to keep the spell."):format(damage, dc))
        return
    end
    local mod = self:SaveMod("CON")
    self.busy = true
    self:RollD20(self:ResolveMode("CON save", nil), function(d20, note)
        self.busy = false
        local kept = d20 + mod >= dc
        if not kept then
            self:State().conditions.Concentrating = nil
            self:QueueBroadcast()
            self:PopulateSoon()
        end
        self:Announce(("took %d damage while concentrating - %s, DC %d: %s"):format(damage,
            ns.RollText.Check(ns.Mark("CON save"), d20, mod, note), dc, kept and "keeps the spell" or "loses the spell"))
    end)
end

-- A menu at the cursor with a tick box per condition.
function RPSheet:OpenConditionMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print("The condition menu isn't available in this version of the game.")
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Conditions")
        for _, condition in ipairs(R.CONDITIONS) do
            local box = root:CreateCheckbox(condition.name,
                function() return self:State().conditions[condition.name] == true end,
                function() self:ToggleCondition(condition.name) end)
            box:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, condition.name)
                GameTooltip_AddNormalLine(tooltip, condition.desc, true)
            end)
        end
    end)
end

-- What others are told, e.g. { "Poisoned", "Prone", "Exhaustion 2" }.
function RPSheet:ConditionSummary()
    local list = self:Conditions()
    if self:Exhaustion() > 0 then list[#list + 1] = "Exhaustion " .. self:Exhaustion() end
    return list
end
