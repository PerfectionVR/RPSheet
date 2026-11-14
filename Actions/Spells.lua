-- Casting a spell from the sheet's spell list: spends a slot, rolls what the spell
-- needs (a spell attack, or dice against a saving throw), and announces it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util
local RollText = ns.RollText

-- The lowest spell slot of at least `level` that still has a use, or nil.
local function FindSlot(self, level)
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind == "slot" and tracker.level >= level and (tracker.get() or 0) > 0 then
            return tracker
        end
    end
end

-- Short description for the spell's row, e.g. "attack +5, 2d8" or "DEX save DC 13, 8d6".
function RPSheet:SpellText(spell)
    local parts = {}
    if spell.kind == "ATTACK" then
        parts[#parts + 1] = "attack " .. Util.Signed(self:SpellAttack() or 0)
    elseif spell.kind == "SAVE" then
        parts[#parts + 1] = ("%s save DC %d"):format(spell.save, self:SpellDC() or 8)
    end
    if spell.count > 0 then
        local dice = ("%dd%d"):format(spell.count, spell.sides)
        if spell.addMod then dice = dice .. " " .. Util.Signed(self:Mod(self:CastStat())) end
        local word = ns.DiceWord(spell.dice)
        parts[#parts + 1] = dice .. (word ~= "damage" and (" " .. word) or "")
    end
    if spell.concentration then parts[#parts + 1] = "concentration" end
    return table.concat(parts, ", ")
end

-- `mode` is "ADV" or "DIS" for the spell attack roll.
function RPSheet:CastSpell(spell, mode)
    if self.busy or self:IsRolling() then return end

    -- Cantrips are free; other spells use the lowest slot that fits.
    local slot
    if spell.level > 0 then
        slot = FindSlot(self, spell.level)
        if not slot then
            self:Print(("No spell slot of %s or higher left for %s."):format(R.SPELL_LEVELS[spell.level]:lower(), spell.name))
            return
        end
    end

    local word, bonus = ns.DiceWord(spell.dice)
    local diceMod = (spell.addMod and self:Mod(self:CastStat()) or 0) + (bonus and self:Bonus(bonus) or 0)
    local parts = {}
    self.busy = true

    local function finish()
        if slot then slot.set(slot.get() - 1) end
        local text = "casts " .. spell.name
        if slot then text = text .. (" (%s)"):format(slot.label) end
        if #parts > 0 then text = text .. " - " .. table.concat(parts, ", ") end
        self.busy = false
        self:Announce(text)
        self:Refresh()
    end

    -- A natural 20 on the spell attack doubles the dice.
    local function rollDice(critical)
        if spell.count <= 0 then return finish() end
        self:RollDice(spell.count * (critical and 2 or 1), spell.sides, function(rolls)
            local label = word == "damage" and critical and "critical damage" or word
            local note = self:ApplyDice(spell.dice, rolls, diceMod)
            parts[#parts + 1] = RollText.Dice(label, rolls, spell.sides, diceMod) .. (note and (" (" .. note .. ")") or "")
            finish()
        end)
    end

    if spell.kind == "ATTACK" then
        self:RollD20(mode, function(d20, note)
            parts[#parts + 1] = RollText.Check("spell attack", d20, self:SpellAttack() or 0, note)
            rollDice(d20 == 20)
        end)
    else
        if spell.kind == "SAVE" then
            parts[#parts + 1] = ("%s save DC %d"):format(R.STAT_NAMES[spell.save] or spell.save, self:SpellDC() or 8)
        end
        rollDice(false)
    end
end
