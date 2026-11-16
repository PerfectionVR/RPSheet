-- Spells that are rolled again after their casting (data: Data/SpellLater.lua): which
-- are running, from which slot, and how a click on their row reaches the later roll
-- (Actions/SpellLaterRoll.lua) instead of a new casting. A running spell ends with a
-- right-click, with concentration when it needs it, and with a rest that outlasts it:
-- the same moments that end a protective spell (Sheet/Wards.lua).
--   state.spellLater[<spell>] = { slot, hours, conc, lasting, step, ticks, dealt }
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local function Runs(self)
    local state = self:State()
    if type(state.spellLater) ~= "table" then state.spellLater = {} end
    return state.spellLater
end

-- The record of the spell's last casting, or nil.
function RPSheet:SpellLaterRun(spell)
    return R.SPELL_LATER[spell.name] and Runs(self)[spell.name] or nil
end

-- True while a lasting spell runs: a left-click rolls its later roll.
function RPSheet:SpellLaterRunning(spell)
    local run = self:SpellLaterRun(spell)
    return run ~= nil and run.lasting == true
end

-- True when casting it rolls none of its own dice (they come later).
function RPSheet:SpellLaterQuiet(spell)
    local later = R.SPELL_LATER[spell.name]
    return later ~= nil and later.quiet == true
end

-- How long a casting with that slot lasts, in hours.
local function Hours(later, level)
    local hours, from = later.hours or 0, 0
    for at, value in pairs(later.hoursAt or {}) do
        if at <= level and at > from then hours, from = value, at end
    end
    return hours
end

-- Called when the spell has been cast. `dealt` is the total its dice came to. Returns
-- a few words for the announcement, or nil.
function RPSheet:StartSpellLater(spell, level, dealt, noConcentration)
    local later = R.SPELL_LATER[spell.name]
    if not later or spell.fromScroll then return end
    level = math.max(level or spell.level, spell.level)
    Runs(self)[spell.name] = {
        slot = level, hours = Hours(later, level), lasting = later.hours ~= nil,
        conc = spell.concentration and not noConcentration or nil,
        step = 1, ticks = 0, dealt = dealt,
    }
    self:PopulateSoon() -- the row now says it is running
    if later.hours then return ("click it for %s"):format(later.rolls[1].label) end
    return "right-click it for what follows"
end

-- Ends one spell by hand.
function RPSheet:EndSpellLater(spell)
    Runs(self)[spell.name] = nil
    self:Announce(("%s ends."):format(ns.Mark(spell.name)))
    self:PopulateSoon()
end

-- Ends the spells that last `hours` or less, those that need concentration
-- (`concentration` true), or with neither given all of them. Returns the names of the
-- lasting ones that ended.
function RPSheet:EndSpellsLater(hours, concentration)
    local ended, runs = {}, Runs(self)
    for name, run in pairs(runs) do
        if type(run) ~= "table" or (not hours and not concentration) or (hours and (run.hours or 0) <= hours)
            or (concentration and run.conc) then
            runs[name] = nil
            if type(run) == "table" and run.lasting then ended[#ended + 1] = name end
        end
    end
    table.sort(ended)
    return ended
end

-- Wards and running spells end at the same moments: a rest, concentration ending.
local EndWards = RPSheet.EndWards
function RPSheet:EndWards(hours, concentration)
    local ended = EndWards(self, hours, concentration)
    for _, name in ipairs(self:EndSpellsLater(hours, concentration)) do ended[#ended + 1] = name end
    if #ended > 0 then self:PopulateSoon() end
    return ended
end

-- A click on the row of a spell with later rolls: a right-click offers them (and a
-- ritual casting, when it is one), a left-click on a running spell rolls the first.
-- Anything else, and every step of a casting already under way, is a casting.
local CastSpell = RPSheet.CastSpell
function RPSheet:CastSpell(spell, mode, ritual, benefit, answers)
    local later = R.SPELL_LATER[spell.name]
    if later and not spell.fromScroll and benefit == nil and answers == nil then
        if self.busy or self:IsRolling() then return end
        if ritual then return self:SpellLaterMenu(spell, mode) end
        if self:SpellLaterRunning(spell) then return self:RollSpellLater(spell, nil, mode) end
    end
    return CastSpell(self, spell, mode, ritual, benefit, answers)
end
