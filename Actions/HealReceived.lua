-- Healing the character receives (offered by "Heal", UI/HealMenu.lua):
--   * its own last healing roll (a spell or ability that heals someone, cast on
--     itself): the roll is kept in memory until it is used or another one is made;
--   * a healing spell someone else cast on it: the sheet rolls the spell's dice for
--     the slot it was cast with, plus the caster's modifier when the spell adds it.
-- Wraps RPSheet:ApplyDice (Actions/Dice.lua), RPSheet:CastSpell (Actions/Spells.lua)
-- and RPSheet:UseAbility (Actions/Abilities.lua) to learn what rolled the healing.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local applyDice, castSpell, useAbility = RPSheet.ApplyDice, RPSheet.CastSpell, RPSheet.UseAbility

function RPSheet:CastSpell(spell, ...)
    self.healingFrom = spell and spell.name
    return castSpell(self, spell, ...)
end
function RPSheet:UseAbility(ability, ...)
    self.healingFrom = ability and ability.name
    return useAbility(self, ability, ...)
end

function RPSheet:ApplyDice(kind, rolls, mod)
    if kind == "HEALING" then
        local total = mod or 0
        for _, roll in ipairs(rolls or {}) do total = total + roll end
        self.lastHealing = { key = self.sheetKey, amount = math.max(0, total), from = self.healingFrom }
    end
    return applyDice(self, kind, rolls, mod)
end

-- The character's own healing roll that is still waiting: { amount, from }, or nil.
function RPSheet:LastHealing()
    local last = self.lastHealing
    if last and last.key == self.sheetKey and last.amount > 0 then return last end
end

-- Heals by that roll, which is then used up.
function RPSheet:HealFromLastRoll()
    local last = self:LastHealing()
    if not last then return end
    self.lastHealing = nil
    self:Heal(last.amount, ("your own %s"):format(last.from and ns.Mark(last.from) or "healing"))
end

-- The listed spells that roll healing dice, by level and then name.
function RPSheet:HealingSpells()
    local found = {}
    for name, spell in pairs(R.SPELLS) do
        if spell.dice == "HEALING" and (spell.count or 0) > 0 then found[#found + 1] = name end
    end
    table.sort(found, function(a, b)
        if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
        return a < b
    end)
    return found
end

-- The dice and the number added for a spell cast with a slot of `level`.
function RPSheet:HealingAt(name, level)
    local spell = R.SPELLS[name]
    local growth = self:SlotGrowth(spell, level)
    return spell.count + growth.dice, spell.sides, growth.flat
end

-- Rolls someone else's healing spell cast with a slot of `level`, adding `mod` (their
-- spellcasting modifier) when the spell adds it, and heals by the total.
function RPSheet:HealFromSpell(name, level, mod)
    local spell = R.SPELLS[name]
    if not spell or self.busy or self:IsRolling() then return end
    local count, sides, flat = self:HealingAt(name, level)
    flat = flat + (spell.addMod and math.floor(tonumber(mod) or 0) or 0)
    self.busy = true
    self:RollDice(count, sides, function(rolls)
        self.busy = false
        local total = flat
        for _, value in ipairs(rolls) do total = total + value end
        local said = ns.RollText.Dice(ns.Mark(name) .. " cast on them", rolls, sides, flat)
        if total <= 0 then
            self:Announce(said .. ": no hit points regained.")
            return
        end
        self:Heal(total, said)
    end)
end
