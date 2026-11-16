-- Damage that reaches 0 hit points (called from Actions/Damage.lua):
--   * Death Ward on the character: 1 hit point instead, and the spell ends;
--   * Relentless Rage while raging: a Constitution save, DC 10 and 5 more for each
--     use since the last rest; on a success the hit points become twice the level in
--     the class. Damage that kills outright leaves no room for it.
-- And damage to a character already at 0: failed death saves.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The Death Ward passive that is on (Data/SpellWardDeath.lua), and where it is.
local function DeathWard(sheet)
    for at, passive in ipairs(sheet.passives) do
        local _, option = R.WardOf(passive.auto)
        if option and option.deathWard and passive.enabled then return passive, at end
    end
end

-- The levels in the class whose rage keeps going, while it does; nil otherwise.
local function RelentlessLevel(sheet)
    local raging = false
    for _, passive in ipairs(sheet.passives) do
        if passive.name == "Raging" and passive.enabled and (passive.auto or ""):find("^class:") then raging = true end
    end
    if not raging then return end
    for _, ability in ipairs(sheet.abilities) do
        if ability.name == "Relentless Rage" and (ability.auto or ""):find("^class:") then
            local view = ns.BaseView(sheet, "Barbarian")
            return view and view.level or sheet.level
        end
    end
end

-- The DC of the next Relentless Rage save.
function RPSheet:RelentlessDC()
    return 10 + 5 * (self:State().relentlessUses or 0)
end

-- `left` damage gets past temporary hit points while the character has `before`.
-- Calls `done(kept, saved)`: the hit points to keep instead of 0 and why, or nothing.
function RPSheet:CatchAtZero(left, before, max, done)
    if before <= 0 or before - left > 0 then return done() end
    local sheet, state = self:Sheet(), self:State()
    local ward, at = DeathWard(sheet)
    if ward then
        table.remove(sheet.passives, at)
        return done(1, ("%s: 1 HP instead of 0, and the spell ends"):format(ns.Mark("Death Ward")))
    end
    local level = RelentlessLevel(sheet)
    if not level or left - before >= max or (state.deathFail or 0) >= 3 then return done() end
    local dc, mod = self:RelentlessDC(), self:SaveMod("CON")
    state.relentlessUses = (state.relentlessUses or 0) + 1
    self.busy = true
    self:RollD20(self:ResolveMode("CON save"), function(d20, note)
        self.busy = false
        local total = d20 + mod
        local roll = ("%s: CON save %d%s %s %d = %d against DC %d"):format(ns.Mark("Relentless Rage"), d20, note, mod >= 0 and "+" or "-", math.abs(mod), total, dc)
        if total >= dc then
            done(2 * level, ("%s, stands with %d HP"):format(roll, 2 * level))
        else
            done(nil, roll .. ", fails")
        end
    end, true)
end

-- Damage to a character already at 0 hit points: a failed death save, two when the
-- hit was a critical one, or death when it is as much as the hit point maximum.
-- Returns the words for the announcement.
function ns.HurtWhileDown(state, damage, max, crit)
    if (state.deathFail or 0) >= 3 then return "Already dead" end
    if damage >= max then
        state.deathFail = 3
        return "Dead: that is as much as their hit point maximum"
    end
    if (state.deathPass or 0) >= 3 then state.deathPass, state.deathFail = 0, 0 end -- no longer stable
    state.deathFail = math.min(3, (state.deathFail or 0) + (crit and 2 or 1))
    local what = crit and "A critical hit, two failed death saves" or "A failed death save"
    if state.deathFail >= 3 then return crit and (what .. ": dead") or "A third failed death save: dead" end
    return ("%s: %d passed, %d failed"):format(what, state.deathPass or 0, state.deathFail)
end
