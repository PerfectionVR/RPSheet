-- Rolling one of a spell's later rolls (data: Data/SpellLater.lua), without a slot:
-- the attack or the save it comes with, its dice with what the slot of the casting
-- added, and what it does to the character (healing, half of the damage dealt).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- The rolls offered for this casting: some only follow a higher slot, some only not.
function RPSheet:SpellLaterRolls(spell)
    local later, list = R.SPELL_LATER[spell.name], {}
    if not later then return list end
    local run = self:SpellLaterRun(spell)
    local above = run and run.slot > spell.level
    for index, roll in ipairs(later.rolls) do
        if not (roll.above and not above) and not (roll.below and above) then list[#list + 1] = index end
    end
    return list
end

-- What a roll comes to: { count, sides, mod, kind, save, attack, dice, word, also }.
function RPSheet:SpellLaterDice(spell, roll, levels)
    local run = self:SpellLaterRun(spell)
    local slot = run and run.slot or spell.level
    local above = math.max(0, slot - spell.level)
    local found = {}
    if roll.same then
        local growth = self:SlotGrowth(spell, slot)
        local word, bonus = ns.DiceWord(spell.dice)
        found.count, found.sides, found.dice, found.word = self:SpellDiceCount(spell) + growth.dice, spell.sides, spell.dice, word
        found.mod = (spell.addMod and self:Mod(self:CastStat(spell)) or 0) + (bonus and self:Bonus(bonus) or 0) + growth.flat
        found.attack = spell.kind == "ATTACK" and "spell" or nil
        found.save = spell.kind == "SAVE" and spell.save or nil
        if growth.also then found.also = { count = growth.also.count, sides = growth.also.sides, word = growth.also.word, kind = growth.also.kind } end
    else
        found.count, found.sides = (roll.count or 0) + above * (roll.up or 0), roll.sides or 0
        if roll.feature and ns.HasFeature(self:Sheet(), roll.feature) then found.sides = roll.featureSides end
        found.dice = roll.dice or "DAMAGE"
        -- Temporary hit points for whoever it is on: yours only while its passive is on.
        if roll.selfWard then found.dice = self:WardOn(spell.name) and "TEMPHP" or "OTHER" end
        found.word = roll.word or ns.DiceWord(found.dice)
        -- What adds to healing rolls adds to these too, as to the casting's.
        found.mod = (roll.flat or 0) + above * (roll.flatUp or 0) + (roll.addMod and self:Mod(self:CastStat(spell)) or 0)
            + (found.dice == "HEALING" and self:Bonus("HEALING") or 0)
        found.attack, found.save = roll.attack, roll.save
        if roll.also then found.also = { count = roll.also.count + above * (roll.also.up or 0), sides = roll.also.sides, word = roll.also.word } end
    end
    if roll.ticks and run then found.count = found.count + (run.ticks or 0) end
    if roll.levels then found.count = found.count * (levels or 1) end
    return found
end

-- Rolls the later roll `index` (the left-click's one when nil). `levels` is the spell
-- level picked for a roll that counts once per level.
function RPSheet:RollSpellLater(spell, index, mode, levels)
    local later = R.SPELL_LATER[spell.name]
    local run = self:SpellLaterRun(spell)
    if not index then
        index = later.sequence and run and math.min(run.step or 1, #later.rolls) or self:SpellLaterRolls(spell)[1]
    end
    local roll = later.rolls[index]
    if not roll or self.busy or self:IsRolling() then return end
    if self:CantAct("use " .. spell.name) then return end
    local head = ("%s, %s"):format(ns.Mark(spell.name), roll.label)
    if run and later.sequence then run.step = math.min(index + 1, #later.rolls) end

    if roll.tick then
        if run then run.ticks = (run.ticks or 0) + 1 end
        local grown = self:SpellLaterDice(spell, later.rolls[index + 1] or roll)
        self:Announce(("%s - now %dd%d"):format(head, grown.count, grown.sides))
        return self:PopulateSoon()
    end
    if roll.half then
        local half = math.floor(((run and run.dealt) or 0) / 2)
        local note = self:ApplyDice(roll.half == "TEMPHP" and "TEMPHP" or "SELFHEAL", {}, half)
        self:Announce(("%s - %d hit points (%s)"):format(head, half, note))
        return self:PopulateSoon()
    end

    local found = self:SpellLaterDice(spell, roll, levels)
    local parts, taken = {}, 0
    if found.save then parts[#parts + 1] = ("%s save DC %d"):format(R.STAT_NAMES[found.save] or found.save, self:SpellDC(spell) or 8) end
    self.busy = true
    local function finish()
        self.busy = false
        if roll.ends and run then
            self:State().spellLater[spell.name] = nil
            parts[#parts + 1] = "the spell ends"
        end
        self:Announce(head .. (#parts > 0 and (" - " .. table.concat(parts, ", ")) or ""))
        self:PopulateSoon()
        -- Damage the caster takes is taken now, with their resistances.
        if roll.toYou and taken > 0 then self:TakeDamage(taken, found.word:match("^(%a+) damage$")) end
    end
    local function alsoRoll()
        local also = found.also
        if not also then return finish() end
        local _, bonus = ns.DiceWord(also.kind or "DAMAGE")
        local alsoMod = bonus == "HEALING" and self:Bonus(bonus) or 0
        self:RollDice(also.count, also.sides, function(rolls)
            local note = self:ApplyDice(also.kind or "DAMAGE", rolls, alsoMod)
            parts[#parts + 1] = RollText.Dice(also.word, rolls, also.sides, alsoMod) .. (note and (" (" .. note .. ")") or "")
            finish()
        end)
    end
    local function dice(critical)
        if found.count <= 0 then
            if found.mod ~= 0 then
                local note = self:ApplyDice(found.dice, {}, found.mod)
                parts[#parts + 1] = ("%d %s"):format(found.mod, found.word) .. (note and (" (" .. note .. ")") or "")
            end
            return alsoRoll()
        end
        self:RollDice(found.count * (critical and 2 or 1), found.sides, function(rolls)
            local total = found.mod
            for _, value in ipairs(rolls) do total = total + value end
            if found.dice == "DAMAGE" and run then run.dealt = math.max(0, total) end
            taken = math.max(0, total)
            local note = self:ApplyDice(found.dice, rolls, found.mod)
            parts[#parts + 1] = RollText.Dice(critical and ("critical " .. found.word) or found.word, rolls, found.sides, found.mod)
                .. (note and (" (" .. note .. ")") or "")
            alsoRoll()
        end)
    end
    if not found.attack then return dice(false) end
    -- An attack with your spellcasting ability: a spell attack, or a strike of your own.
    local label = found.attack == "weapon" and "attack" or "spell attack"
    local bonus = found.attack == "weapon"
        and (self:Mod(self:CastStat(spell)) + self:ProficiencyBonus() + self:Bonus("ATTACK")) or (self:SpellAttack(spell) or 0)
    mode = self:ResolveMode(label, mode)
    self:RollTest(mode, function(d20, note, extra)
        parts[#parts + 1] = RollText.Check(label, d20, bonus, note, extra)
        dice(d20 == 20)
    end)
end

-- True while the passive of the spell's protection is on (Sheet/Wards.lua).
function RPSheet:WardOn(name)
    for _, passive in ipairs(self:Sheet().passives) do
        local _, _, spell = R.WardOf(passive.auto)
        if spell == name and passive.enabled then return true end
    end
    return false
end
