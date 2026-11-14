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

-- The slot levels the character has, lowest first.
local function SlotLevels(self)
    local levels = {}
    for level, count in pairs(self:SpellSlots()) do
        if count > 0 then levels[#levels + 1] = level end
    end
    table.sort(levels)
    return levels
end

-- The "Cast at" row: the lowest slot that fits (nil), or a slot level to cast the next
-- spell with. It goes back to the lowest after one spell.
function RPSheet:CycleCastLevel()
    local levels, nextLevel = SlotLevels(self)
    for _, level in ipairs(levels) do
        if level > (self.castLevel or levels[1] or 0) then nextLevel = level break end
    end
    self.castLevel = nextLevel
    self:Refresh()
    self:PopulateSoon() -- the spell tooltips say what that slot level does
end

-- Number of dice a spell rolls: a scaling cantrip rolls one more set at character
-- levels 5, 11 and 17.
function RPSheet:SpellDiceCount(spell)
    if not spell.scales or spell.level > 0 then return spell.count end
    local level, tier = self:Level(), 1
    for _, step in ipairs({ 5, 11, 17 }) do
        if level >= step then tier = tier + 1 end
    end
    return spell.count * tier
end

-- The number of separate attacks one casting makes: more beams for a scaling cantrip,
-- more rays for a higher slot.
function RPSheet:SpellHits(spell, slot)
    local hits = math.max(1, spell.hits or 1)
    if spell.hitsScale and spell.level == 0 then
        for _, step in ipairs({ 5, 11, 17 }) do
            if self:Level() >= step then hits = hits + 1 end
        end
    end
    if slot and (spell.hitsUp or 0) > 0 then hits = hits + (slot.level - spell.level) * spell.hitsUp end
    return hits
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
        -- A growing spell that is running shows the die its next turn rolls.
        local grown = self:GrowingSides(spell)
        local dice = ("%dd%d"):format(self:SpellDiceCount(spell), grown or spell.sides)
        if grown then dice = "running, next " .. dice end
        -- Some spells add a fixed number as well (see Data/SlotGrowth.lua).
        local flat = self:SlotGrowth(spell).flat
        if spell.addMod or flat ~= 0 then dice = dice .. " " .. Util.Signed((spell.addMod and self:Mod(self:CastStat()) or 0) + flat) end
        local word = ns.DiceWord(spell.dice)
        parts[#parts + 1] = dice .. (word ~= "damage" and (" " .. word) or "")
    end
    if spell.concentration then parts[#parts + 1] = "concentration" end
    return table.concat(parts, ", ")
end

-- `mode` is "ADV" or "DIS" for the spell attack roll. `ritual` casts a ritual spell
-- without a slot. `benefit` is the pick for a spell that offers a choice of benefits;
-- without it the spell asks first (see Sheet/Metamorphosis.lua).
function RPSheet:CastSpell(spell, mode, ritual, benefit)
    if self.busy or self:IsRolling() then return end
    -- A beast form can't cast (see Sheet/Forms.lua).
    local blocked = self:FormBlocksSpell(spell)
    if blocked then
        self:Print(blocked)
        return
    end
    -- A spell with a growing die that is already running rolls its next turn instead.
    if self:GrowingSpellClick(spell, ritual) then return end

    -- Cantrips are free; other spells use the lowest slot that fits.
    local slot
    ritual = ritual and spell.ritual and spell.level > 0
    -- A spell chosen for a class feature may need no slot (see Actions/SpellChoices.lua).
    local chosen, spent
    if spell.level > 0 and not ritual then chosen, spent = self:ChosenCasting(spell) end
    if spent then
        self:Print(spent)
        return
    end
    if spell.level > 0 and not ritual and not chosen then
        local level = math.max(spell.level, self.castLevel or 0)
        slot = FindSlot(self, level)
        if not slot then
            self:Print(("No spell slot of %s or higher left for %s."):format(R.SPELL_LEVELS[level]:lower(), spell.name))
            return
        end
    end
    -- What the slot used changes: more dice, a number added, a second roll, and what
    -- is only stated, such as more targets (see Actions/SlotGrowth.lua).
    local growth = self:SlotGrowth(spell, slot and slot.level)
    local moreDice = growth.dice

    -- Nothing is spent until the benefit is picked: the menu casts the spell again with it.
    local benefits = not benefit and self:SpellBenefits(spell)
    if benefits and self:AskBenefit(spell, benefits, function(pick) self:CastSpell(spell, mode, ritual, pick) end) then
        return
    end

    local word, bonus = ns.DiceWord(spell.dice)
    local diceMod = (spell.addMod and self:Mod(self:CastStat()) or 0) + (bonus and self:Bonus(bonus) or 0) + growth.flat
    local parts = {}
    self.busy = true

    local function finish()
        if slot then slot.set(slot.get() - 1) end
        if chosen then self:SpendChosenCasting(spell, chosen) end
        if self.castLevel then self:PopulateSoon() end -- the tooltips spoke of that slot level
        self.castLevel = nil
        if R.GROWING_SPELLS[spell.name] then
            self:StartGrowingSpell(spell)
            self:PopulateSoon() -- the row now shows the next die
        end
        for _, note in ipairs(growth.notes) do parts[#parts + 1] = note end
        -- Only one spell can be concentrated on: a new one replaces the old. A few
        -- spells need no concentration with a high enough slot.
        if spell.concentration and not growth.noConcentration then
            local conditions = self:State().conditions
            parts[#parts + 1] = conditions.Concentrating and "concentrating on it now, the earlier spell ends" or "concentrating"
            conditions.Concentrating = true
            self:PopulateSoon()
        end
        -- The benefit picked for the casting is switched on, ending any other.
        if benefit then
            parts[#parts + 1] = self:TakeBenefit(benefit)
            self:PopulateSoon()
        end
        local text = "casts " .. ns.Mark(spell.name)
        if slot then text = text .. (" (%s)"):format(slot.label) end
        if chosen then text = text .. (" (%s, no slot)"):format(chosen.feature) end
        if ritual then text = text .. " (as a ritual, no slot)" end
        if #parts > 0 then text = text .. " - " .. table.concat(parts, ", ") end
        self.busy = false
        self:Announce(text)
        self:Refresh()
    end

    -- A natural 20 on the spell attack doubles the dice.
    local function rollDice(critical, after)
        if spell.count <= 0 then return after() end
        self:RollDice((self:SpellDiceCount(spell) + moreDice) * (critical and 2 or 1), spell.sides, function(rolls)
            local label = word == "damage" and critical and "critical damage" or word
            -- A feature can make low force damage dice count as higher.
            local raised = spell.dice == "DAMAGE" and R.SPELL_DAMAGE[spell.name] == "force" and self:RaiseForceDice(rolls)
            local note = self:ApplyDice(spell.dice, rolls, diceMod)
            parts[#parts + 1] = RollText.Dice(label, rolls, spell.sides, diceMod) .. (raised and (" [" .. raised .. "]") or "")
                .. (note and (" (" .. note .. ")") or "")
            after()
        end)
    end

    -- A second part with dice of its own (a burst, healing alongside the damage) is
    -- rolled once, last, and is not doubled by a critical hit.
    local function finishWithSecondRoll()
        local also = growth.also
        if not also then return finish() end
        local _, alsoBonus = ns.DiceWord(also.kind)
        local alsoMod = alsoBonus == "HEALING" and self:Bonus(alsoBonus) or 0
        self:RollDice(also.count, also.sides, function(rolls)
            local note = self:ApplyDice(also.kind, rolls, alsoMod)
            parts[#parts + 1] = RollText.Dice(also.word, rolls, also.sides, alsoMod) .. (note and (" (" .. note .. ")") or "")
            finish()
        end)
    end

    if spell.kind == "ATTACK" then
        -- A feature that gives advantage on spell attacks (Innate Sorcery) applies by itself.
        mode = self:ResolveMode("spell attack", mode) -- conditions count too
        -- A spell of several rays, beams or shards rolls each attack in turn.
        local hits = self:SpellHits(spell, slot)
        local function attack(index)
            self:RollD20(mode, function(d20, note)
                local label = hits > 1 and ("attack %d"):format(index) or "spell attack"
                parts[#parts + 1] = RollText.Check(label, d20, self:SpellAttack() or 0, note)
                rollDice(d20 == 20, function()
                    if index < hits then attack(index + 1) else finishWithSecondRoll() end
                end)
            end)
        end
        attack(1)
    else
        if spell.kind == "SAVE" then
            parts[#parts + 1] = ("%s save DC %d"):format(R.STAT_NAMES[spell.save] or spell.save, self:SpellDC() or 8)
        end
        rollDice(false, finishWithSecondRoll)
    end
end
