-- A spell whose die grows (see Data/GrowingSpells.lua). Casting it starts it; after
-- that each left-click is the target's next turn after a failed save: the die grows
-- one size and the damage is rolled, without a slot. A right-click ends it, which is
-- what a successful save does.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- state.growing[<spell name>] = how far along the die sizes the spell is.
local function Running(self)
    local state = self:State()
    state.growing = state.growing or {}
    return state.growing
end

-- The die size the next click rolls while the spell is running, or nil when it isn't.
function RPSheet:GrowingSides(spell)
    local steps = R.GROWING_SPELLS[spell.name]
    local step = steps and Running(self)[spell.name]
    if not step then return end
    return steps[math.min(step + 1, #steps)]
end

-- Called when the spell has been cast with a slot.
function RPSheet:StartGrowingSpell(spell)
    if R.GROWING_SPELLS[spell.name] then Running(self)[spell.name] = 1 end
end

-- Ends every growing spell, without announcing it (a long rest).
function RPSheet:ClearGrowingSpells()
    self:State().growing = {}
end

-- Handles a click on a growing spell that is running. Returns true when it did, false
-- when the spell should be cast the usual way.
function RPSheet:GrowingSpellClick(spell, rightButton)
    local steps = R.GROWING_SPELLS[spell.name]
    if not steps then return false end
    local running = Running(self)
    local step = running[spell.name]
    if not step then return false end

    if rightButton then
        running[spell.name] = nil
        self:Announce(("%s ends."):format(ns.Mark(spell.name)))
        self:PopulateSoon()
        return true
    end

    step = math.min(step + 1, #steps)
    local sides = steps[step]
    local word, bonus = ns.DiceWord(spell.dice)
    local mod = (spell.addMod and self:Mod(self:CastStat(spell)) or 0) + (bonus and self:Bonus(bonus) or 0)
    self.busy = true
    self:RollDice(spell.count, sides, function(rolls)
        running[spell.name] = step
        local note = self:ApplyDice(spell.dice, rolls, mod)
        local text = ("%s grows after a failed save - %s%s"):format(ns.Mark(spell.name),
            RollText.Dice(word, rolls, sides, mod), note and (" (" .. note .. ")") or "")
        if spell.kind == "SAVE" then
            text = text .. (", %s save DC %d"):format(R.STAT_NAMES[spell.save] or spell.save, self:SpellDC(spell) or 8)
        end
        self.busy = false
        self:Announce(text)
        self:PopulateSoon()
    end)
    return true
end
