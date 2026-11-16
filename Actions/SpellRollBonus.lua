-- What switched-on passives do to a d20 beyond advantage (data: Data/SpellWardBoons.lua):
-- a die added to some rolls (Bless, Guidance), a low roll counted as higher
-- (Glibness), disadvantage on some rolls (a reduced creature), and advantage that a
-- single roll uses up (Guided Prayer).
-- A roll's label is known to RPSheet:ResolveMode, which every roll of the sheet asks
-- right before RPSheet:RollTest; it is kept until that roll is made.
local _, ns = ...
local RPSheet = ns.addon

local NONE = {}

local function Lists(labels, label)
    for _, each in ipairs(labels or NONE) do
        if each == label then return true end
    end
    return false
end

local ResolveMode = RPSheet.ResolveMode
function RPSheet:ResolveMode(label, ...)
    self.rollLabel = label
    return ResolveMode(self, label, ...)
end

-- A switched-on passive that gives disadvantage on the roll.
local DisadvantageFrom = RPSheet.DisadvantageFrom
function RPSheet:DisadvantageFrom(label, answers)
    local found = DisadvantageFrom(self, label, answers)
    if found then return found end
    for _, passive in ipairs(self:Sheet().passives or NONE) do
        if passive.enabled and passive.name ~= "" and Lists(passive.disadvantage, label) then return passive.name end
    end
end

-- The dice and the lowest roll switched-on passives give the roll with this label.
local function Boons(self, label)
    local dice, floor, from = {}, nil, nil
    if not label then return dice end
    for _, passive in ipairs(self:Sheet().passives or NONE) do
        if passive.enabled and passive.name ~= "" and not self:PassiveBlocked(passive) then
            local die, least = passive.rollDie, passive.minRoll
            if type(die) == "table" and Lists(die.labels, label) then dice[#dice + 1] = { sides = die.sides, from = passive.name } end
            if type(least) == "table" and Lists(least.labels, label) and (not floor or least.value > floor) then floor, from = least.value, passive.name end
        end
    end
    return dice, floor, from
end

local RollTest = RPSheet.RollTest
function RPSheet:RollTest(mode, callback)
    local label = self.rollLabel
    self.rollLabel = nil
    -- Advantage for one roll only (Guided Prayer) is used up by it.
    for _, passive in ipairs(label and self:Sheet().passives or NONE) do
        if passive.enabled and passive.oneRoll and Lists(passive.advantage, label) then
            passive.enabled = false
            self:PopulateSoon()
        end
    end
    local dice, floor, from = Boons(self, label)
    if #dice == 0 and not floor then return RollTest(self, mode, callback) end
    RollTest(self, mode, function(d20, note, extra)
        if floor and d20 < floor then
            note = ("%s [rolled %d, counts as %d: %s]"):format(note or "", d20, floor, from)
            d20 = floor
        end
        -- Each die is added to what the "Next roll" rows added, and named.
        local function Step(index, added)
            local die = dice[index]
            if not die then return callback(d20, note, added) end
            self:Roll(die.sides, function(rolled)
                local text = ("1d%d %s"):format(die.sides, die.from)
                if added then
                    added = { value = added.value + rolled, text = added.text .. ", " .. text }
                else
                    added = { value = rolled, text = text }
                end
                Step(index + 1, added)
            end)
        end
        Step(1, extra)
    end)
end
