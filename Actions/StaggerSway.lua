-- More rows for the damage menu from the character's own features: the Delayed
-- Reaction pool of Stagger and Sway (taken at the end of the turn, or thinned with a
-- bonus action), and a row to say a spent reaction is back. Each damage adds a d6 to
-- the pool (Actions/DamageSteps.lua); the pool's own damage adds none.
-- Wraps RPSheet:DamageExtras (Actions/WardDamage.lua), so it loads after that file.
local _, ns = ...
local RPSheet = ns.addon

-- Rolls the pool and takes it as force damage.
function RPSheet:TakeDelayedPool()
    local state = self:State()
    local count = state.delayedDice or 0
    if count <= 0 or self.busy or self:IsRolling() then return end
    self.busy = true
    self:RollDice(count, 6, function(rolls)
        self.busy = false
        state.delayedDice = nil
        local sum = 0
        for _, value in ipairs(rolls) do sum = sum + value end
        if sum <= 0 then return end
        self:TakeDamage(sum, "force", nil, nil, false, { pool = true, said = ns.RollText.Dice("Delayed Reaction", rolls, 6, 0) })
    end)
end

-- Purify: a bonus action takes as many dice out of the pool as the Wisdom modifier.
function RPSheet:PurifyPool()
    local state = self:State()
    local removed = math.min(state.delayedDice or 0, math.max(0, self:Mod("WIS")))
    if removed <= 0 or self:CantAct("use Purify") then return end
    state.delayedDice = state.delayedDice - removed
    if state.delayedDice <= 0 then state.delayedDice = nil end
    self:Announce(("uses %s: %d %s out of the Delayed Reaction pool, %dd6 left."):format(ns.Mark("Stagger and Sway"), removed,
        removed == 1 and "die" or "dice", state.delayedDice or 0))
    self:PopulateSoon()
end

local DamageExtras = RPSheet.DamageExtras
function RPSheet:DamageExtras()
    local extras, state = DamageExtras(self), self:State()
    local pool = state.delayedDice or 0
    if pool > 0 then
        extras[#extras + 1] = { label = ("Delayed Reaction: take %dd6 force damage (end of your turn)"):format(pool),
            run = function() self:TakeDelayedPool() end }
        local purify = math.min(pool, math.max(0, self:Mod("WIS")))
        if purify > 0 then
            extras[#extras + 1] = { label = ("Purify: take %d %s out of the pool (bonus action)"):format(purify, purify == 1 and "die" or "dice"),
                run = function() self:PurifyPool() end }
        end
    end
    if state.reactionUsed and self:DamageOptions().reactions then
        extras[#extras + 1] = { label = "Your reaction is back (your turn has started)", run = function() self:ReactionBack() end }
    end
    return extras
end
