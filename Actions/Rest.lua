-- Resting: long rests, short rests, and spending hit dice to heal.
local _, ns = ...
local RPSheet = ns.addon
local RollText = ns.RollText

local function HasPassive(sheet, name)
    for _, passive in ipairs(sheet.passives) do
        if passive.name == name and passive.enabled then return true end
    end
    return false
end

-- Everything back to full: HP, hit dice, resources and spell slots.
function RPSheet:LongRest()
    local state = self:State()
    self:ClampState(true)
    state.tempHP = 0
    state.exhaustion = math.max(0, (state.exhaustion or 0) - 1)
    state.conditions.Concentrating = nil
    self:ClearDeathSaves()
    -- Humans wake up inspired (Resourceful).
    if HasPassive(self:Sheet(), "Resourceful") then state.inspiration = true end
    self:Announce("finishes a long rest.")
    self:PopulateSoon()
end

-- Gives back what recharges on a short rest. HP only comes back by spending hit dice.
function RPSheet:ShortRest()
    local regained = {}
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.short then
            local before = tracker.get()
            tracker.set(tracker.short == "ALL" and tracker.max or (before + tracker.short))
            if tracker.get() > before then regained[#regained + 1] = tracker.label end
        end
    end
    local text = "finishes a short rest"
    if #regained > 0 then text = text .. " (regains " .. table.concat(regained, ", ") .. ")" end
    self:Announce(text .. ".")
    self:Refresh()
end

-- Rolls one hit die and heals by the result plus the Constitution modifier (at least 1).
function RPSheet:SpendHitDie()
    local state, class = self:State(), self:ClassData()
    if (state.hitDice or 0) <= 0 then
        self:Print("No hit dice left. A long rest restores them.")
        return
    end
    local sides = class and class.hitDie or ns.Rules.DEFAULT_HIT_DIE
    local mod = self:Mod("CON")
    self:RollDice(1, sides, function(rolls)
        local healed = math.max(1, rolls[1] + mod)
        state.hitDice = state.hitDice - 1
        state.hp = math.min(self:MaxHP(), (state.hp or 0) + healed)
        self:ClearDeathSaves()
        self:Announce(("spends a hit die - %s (now %d/%d HP)"):format(
            RollText.Dice("healing", rolls, sides, mod), state.hp, self:MaxHP()))
        self:PopulateSoon()
    end)
end
