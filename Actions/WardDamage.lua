-- Protective spells that act when damage is taken (data in Data/SpellWardRolls.lua):
--   * dice that come off the damage (Resistance, Time Dilation): "Take damage" rolls
--     them and takes the sum off before resistance halves what is left;
--   * hit points owed afterwards (Time Dilation), paid a die at a time;
--   * a bond whose caster takes what the guarded creature takes (Warding Bond).
-- The sheet has no turns, so a once-a-turn ward is rolled every time and says so; the
-- damage menu has a row to take damage without it (RPSheet:DamageExtras).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local TakeDamage = RPSheet.TakeDamage

-- The wards that are on and whose dice come off damage of this type.
local function RolledWards(self, damageType)
    local found = {}
    for _, passive in ipairs(self:Sheet().passives) do
        local _, option, spell = R.WardOf(passive.auto)
        -- One that has been used and is only owed for takes nothing off any more.
        if option and option.roll and passive.enabled and not passive.owed then
            local fits = not option.reduce
            for _, name in ipairs(option.reduce or {}) do fits = fits or name == damageType end
            if fits then found[#found + 1] = { passive = passive, option = option, spell = spell } end
        end
    end
    return found
end

local function Remove(self, passive)
    local passives = self:Sheet().passives
    for at = #passives, 1, -1 do
        if passives[at] == passive then table.remove(passives, at) end
    end
end

-- A bond ends when its caster drops to 0 hit points. Actions/Damage.lua calls this
-- once the damage has really been taken, which can be after a die rolled in chat.
function RPSheet:EndBondsAtZero()
    if (self:State().hp or 1) > 0 then return end
    local passives = self:Sheet().passives
    for at = #passives, 1, -1 do
        local _, option, spell = R.WardOf(passives[at].auto)
        if option and option.guard then
            table.remove(passives, at)
            self:Print(("%s ends: you are at 0 hit points."):format(spell))
        end
    end
end

-- A ward that works a single time is used up; one that is paid back stays to say so.
local function UseUp(self, wards)
    for _, entry in ipairs(wards) do
        local option = entry.option
        if option.once and option.owed then
            entry.passive.owed = option.owed
            self:Print(("%s: at the end of each of your next %d turns you lose 1d%d hit points. \"Take damage\" has a row for it."):format(
                entry.spell, option.owed, option.roll[2]))
        elseif option.once then
            Remove(self, entry.passive)
        end
    end
end

-- `ward` false takes the damage without rolling any ward (it was used this turn);
-- `crit` is true for a critical hit.
function RPSheet:TakeDamage(amount, damageType, reduction, ward, crit)
    local wards = {}
    if ward ~= false and (tonumber(amount) or 0) >= 1 and not (damageType and self:Defenses().immune[damageType]) then
        wards = RolledWards(self, damageType)
    end
    if #wards == 0 then
        return TakeDamage(self, amount, damageType, reduction, nil, crit)
    end
    if self.busy or self:IsRolling() then
        self:Print("Another roll is still going. Take the damage again when it is done.")
        return
    end
    self.busy = true
    local total, notes = reduction or 0, {}
    local function roll(index)
        local entry = wards[index]
        if not entry then
            self.busy = false
            TakeDamage(self, amount, damageType, total, table.concat(notes, "; "), crit)
            return UseUp(self, wards)
        end
        local count, sides = entry.option.roll[1], entry.option.roll[2]
        self:RollDice(count, sides, function(rolls)
            local sum = 0
            for _, value in ipairs(rolls) do sum = sum + value end
            total = total + sum
            notes[#notes + 1] = ("%s %dd%d: %d%s"):format(entry.spell, count, sides, sum, entry.option.perTurn and ", once a turn" or "")
            roll(index + 1)
        end)
    end
    roll(1)
end

-- Loses one die of the hit points a ward is owed. Losing hit points is not damage:
-- nothing halves it, temporary hit points don't take it, concentration isn't tested.
function RPSheet:PayWardDebt(passive)
    local _, option, spell = R.WardOf(passive.auto)
    if not option or not option.roll or (passive.owed or 0) <= 0 then return end
    if self.busy or self:IsRolling() then return end
    self.busy = true
    self:RollDice(1, option.roll[2], function(rolls)
        self.busy = false
        local state, max = self:State(), self:MaxHP()
        local before = state.hp or max
        state.hp = math.max(0, before - rolls[1])
        passive.owed = passive.owed - 1
        if passive.owed <= 0 then Remove(self, passive) end
        local down = before > 0 and state.hp == 0
        if down then self:ClearDeathSaves() end
        self:Announce(("loses %d hit points to %s (1d%d: %d), %s: %d/%d HP.%s"):format(before - state.hp, ns.Mark(spell), option.roll[2], rolls[1],
            passive.owed > 0 and ("%d more to come"):format(passive.owed) or "the last of it", state.hp, max, down and " Down at 0 HP." or ""))
        if down then
            self:EndConcentration("at 0 hit points")
            self:LeaveForms("at 0 hit points")
        end
        self:EndBondsAtZero()
        self:QueueBroadcast()
        self:PopulateSoon()
    end)
end

-- More rows for the damage menu, each { label, request = for RPSheet:AskAmount } or
-- { label, run = function }: what the wards that are on call for.
function RPSheet:DamageExtras()
    local extras = {}
    for _, passive in ipairs(self:Sheet().passives) do
        local _, option, spell = R.WardOf(passive.auto)
        if option and passive.enabled and option.guard then
            extras[#extras + 1] = { label = spell .. ": what the one you guard took",
                request = { prompt = "How much damage did the creature you guard take?\nYou take the same amount, whatever its type." } }
        elseif option and passive.enabled and option.roll and passive.owed then
            extras[#extras + 1] = { label = ("%s: lose 1d%d hit points (end of your turn, %d to go)"):format(spell, option.roll[2], passive.owed),
                run = function() self:PayWardDebt(passive) end }
        elseif option and passive.enabled and option.roll and option.perTurn then
            for _, name in ipairs(option.reduce or {}) do
                extras[#extras + 1] = { label = ("%s, %s already used this turn"):format(name:sub(1, 1):upper() .. name:sub(2), spell),
                    request = { damageType = name, ward = false } }
            end
        end
    end
    return extras
end
