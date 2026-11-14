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

function RPSheet:ToggleCondition(name)
    local conditions = self:State().conditions
    conditions[name] = not conditions[name] or nil
    local term = ns.Mark(name)
    self:Announce(conditions[name] and ("is now %s."):format(term) or ("is no longer %s."):format(term))
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
