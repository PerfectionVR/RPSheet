-- A spell whose die grows (see Data/GrowingSpells.lua). Casting it starts it; after
-- that each left-click is the target's next turn after a failed save: the die grows
-- one size and the damage is rolled, without a slot. A right-click ends it, which is
-- what a successful save does.
-- One read from a scroll runs beside the character's own casting of that spell, with
-- the scroll's numbers, and has a row of its own on the sheet while it lasts.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- state.growing[<spell name>] = how far along the die sizes the spell is.
-- state.growingScrolls[<spell name>] = the same for one read from a scroll, with
-- state.scrollSpells[<spell name>] = the copy that was cast (marked scrollRun).
local function Steps(self, spell)
    local state = self:State()
    local key = spell.scrollRun and "growingScrolls" or "growing"
    if type(state[key]) ~= "table" then state[key] = {} end
    return state[key]
end

local function ScrollSpells(self)
    local state = self:State()
    if type(state.scrollSpells) ~= "table" then state.scrollSpells = {} end
    return state.scrollSpells
end

-- The die size the next click rolls while the spell is running, or nil when it isn't.
function RPSheet:GrowingSides(spell)
    local steps = R.GROWING_SPELLS[spell.name]
    local step = steps and Steps(self, spell)[spell.name]
    if not step then return end
    return steps[math.min(step + 1, #steps)]
end

-- Called when the spell has been cast: with a slot, or from a scroll.
function RPSheet:StartGrowingSpell(spell)
    if not R.GROWING_SPELLS[spell.name] then return end
    if not spell.fromScroll then
        Steps(self, spell)[spell.name] = 1
        return
    end
    -- The scroll itself is gone; its numbers stay with the copy.
    local copy = {}
    for key, value in pairs(spell) do
        if key ~= "fromScroll" then copy[key] = type(value) == "table" and CopyTable(value) or value end
    end
    copy.scrollRun = true
    ScrollSpells(self)[spell.name] = copy
    Steps(self, copy)[spell.name] = 1
end

-- The growing spells read from a scroll that are running, by name: the copies to
-- show as rows and to click (UI/SheetSpells.lua).
function RPSheet:ScrollRuns()
    local runs = {}
    for name, copy in pairs(ScrollSpells(self)) do
        if type(copy) == "table" and Steps(self, copy)[name] then runs[#runs + 1] = copy end
    end
    table.sort(runs, function(a, b) return a.name < b.name end)
    return runs
end

-- Ends every growing spell, without announcing it (a long rest).
function RPSheet:ClearGrowingSpells()
    local state = self:State()
    state.growing, state.growingScrolls, state.scrollSpells = {}, {}, {}
end

-- Handles a click on a growing spell that is running. Returns true when it did, false
-- when the spell should be cast the usual way.
function RPSheet:GrowingSpellClick(spell, rightButton)
    local steps = R.GROWING_SPELLS[spell.name]
    if not steps then return false end
    local running = Steps(self, spell)
    local step = running[spell.name]
    if not step then return false end

    if rightButton then
        running[spell.name] = nil
        if spell.scrollRun then ScrollSpells(self)[spell.name] = nil end
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
