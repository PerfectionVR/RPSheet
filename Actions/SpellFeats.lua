-- What feats and Metamagic do to a spell once it is cast (called from
-- Actions/Spells.lua and Actions/Abilities.lua): low dice rerolled or counted higher
-- (Sheet/DiceFeats.lua), a free casting that takes the die's highest number (Fiendish
-- Vigor), the d4 of Boon of Spell Recall, and the rerolls of Empowered Spell and
-- Seeking Spell, offered on their own rows after the casting.
local _, ns = ...
local RPSheet = ns.addon
local RollText = ns.RollText

-- Changes a spell's rolled dice in place, then calls done(notes). sides is the die
-- rolled when the target changed it (Toll the Dead's d12), else the spell's own.
function RPSheet:SpellFeatDice(spell, chosen, rolls, done, sides)
    sides = sides or spell.sides
    if chosen and chosen.maxDice then
        for index in ipairs(rolls) do rolls[index] = sides end
        return done({ ("highest number on each die, %s"):format(chosen.feature) })
    end
    local upTo, lowest, from = self:SpellDiceRules(spell.dice, ns.SpellDamageType(spell))
    self:AdjustRolls(rolls, sides, upTo, lowest, from, done)
end

-- Boon of Spell Recall: a slot of level 1 to 4 comes back when a d4 shows its level.
function RPSheet:SpellRecall(slot)
    if not slot.level or slot.level > 4 or not self:HasPassive("Boon of Spell Recall") then return end
    self:Roll(4, function(rolled)
        if rolled == slot.level then
            slot.set(slot.get() + 1)
            self:Announce(("rolls 1d4 for %s: %d - the %s isn't spent."):format(ns.Mark("Boon of Spell Recall"), rolled, slot.label))
            self:Refresh()
        else
            self:Print(("Boon of Spell Recall: the d4 shows %d, so the %s is spent."):format(rolled, slot.label))
        end
    end)
end

---------------------------------------------------------------------------
-- Rerolls after the casting
---------------------------------------------------------------------------
-- The last casting's damage dice and spell attack, for the rerolls:
-- self.lastSpellRolls = { dice = { spell, rolls, sides, mod, word, kind }, attack = { spell, mod } }.
function RPSheet:RememberSpellRoll(kind, data)
    local last = self.lastSpellRolls or {}
    self.lastSpellRolls = last
    if kind == "attack" then last.dice = nil end -- a new casting begins with its attack
    if kind == "dice" and last.attack and last.attack.spell ~= data.spell then last.attack = nil end
    last[kind] = data
end

-- What a reroll of this mode ("DAMAGE" or "ATTACK") would work on, or nil and why not.
local function Target(self, mode)
    local last = self.lastSpellRolls or {}
    if mode == "ATTACK" then
        if last.attack then return last.attack end
        return nil, "Seeking Spell rerolls the attack roll of the spell you just cast: cast one with a spell attack first."
    end
    if last.dice and last.dice.kind == "DAMAGE" then return last.dice end
    return nil, "Empowered Spell rerolls the damage dice of the spell you just cast: cast one that deals damage first."
end

-- True if every reroll the ability asks for has something to work on; says why not.
function RPSheet:CanReroll(ability)
    for _, action in ipairs(ability.actions or {}) do
        if action.type == "REROLL" then
            local target, why = Target(self, action.mode)
            if not target then
                self:Print(why)
                return false
            end
        end
    end
    return true
end

-- Rerolls the last casting's damage dice (as many as the Charisma modifier, at least
-- one: the lowest ones, below the die's average) or its attack roll. Calls done(text).
function RPSheet:RerollLastSpell(mode, done)
    local target = Target(self, mode)
    if not target then return done("nothing to reroll") end
    local last = self.lastSpellRolls
    if mode == "ATTACK" then
        last.attack = nil
        return self:Roll(20, function(d20)
            done(RollText.Check(("%s attack rerolled"):format(target.spell), d20, target.mod))
        end)
    end
    last.dice = nil
    local rolls, order = target.rolls, {}
    for index in ipairs(rolls) do order[#order + 1] = index end
    table.sort(order, function(a, b) return rolls[a] < rolls[b] end)
    local count, picked = math.max(1, self:Mod("CHA")), {}
    for _, index in ipairs(order) do
        if #picked < count and rolls[index] * 2 < target.sides + 1 then picked[#picked + 1] = index end
    end
    if #picked == 0 then return done(("%s: no die below average to reroll"):format(target.spell)) end
    self:RollDice(#picked, target.sides, function(new)
        for at, index in ipairs(picked) do rolls[index] = new[at] end
        done(("%s, %d %s rerolled: %s"):format(target.spell, #picked, #picked == 1 and "die" or "dice",
            RollText.Dice(target.word, rolls, target.sides, target.mod)))
    end)
end
