-- A one-off bonus or penalty to the next d20: a die added (Bless, Guidance, Bardic
-- Inspiration), a die taken off (Bane), a number (cover on a Dexterity save). It is
-- set on the "Next roll" rows of the sheet (UI/SheetNextRoll.lua), rolled after the
-- d20 and shown in the announcement, and used up by the roll like the roll mode,
-- unless it is kept for every roll.
--   self.rollBonusDie    { sign = 1 or -1, sides = 4 } or nil
--   self.rollBonusFlat   a number, 0 for none
--   self.rollBonusLocked true: both stay until they are changed
local _, ns = ...
local RPSheet = ns.addon

local SIDES = { 4, 6, 8, 10, 12 }
local MAX_FLAT = 10

-- A click on the "+d4" or "-d4" row: on, or off when that die is on already.
-- `grow` moves to the next die size instead (d4, d6, ... d12, then d4 again).
function RPSheet:SetRollBonusDie(sign, grow)
    local die = self.rollBonusDie
    local same = die and die.sign == sign
    if grow then
        local sides = same and die.sides or SIDES[#SIDES]
        for index, size in ipairs(SIDES) do
            if size == sides then sides = SIDES[index % #SIDES + 1] break end
        end
        self.rollBonusDie = { sign = sign, sides = sides }
    else
        self.rollBonusDie = not same and { sign = sign, sides = 4 } or nil
    end
    self:RollBonusChanged()
end

-- A click on the "+N" row: one more, or one less.
function RPSheet:ChangeRollBonusFlat(delta)
    self.rollBonusFlat = math.max(-MAX_FLAT, math.min(MAX_FLAT, (self.rollBonusFlat or 0) + delta))
    self:RollBonusChanged()
end

-- Keeps what is set for every roll, or goes back to one roll.
function RPSheet:LockRollBonus()
    self.rollBonusLocked = not self.rollBonusLocked
    self:RollBonusChanged()
end

function RPSheet:RollBonusChanged()
    -- Nothing set: nothing to keep.
    if not self.rollBonusDie and (self.rollBonusFlat or 0) == 0 then self.rollBonusLocked = false end
    self:RefreshRollBonus() -- the rows that show it (UI/SheetNextRoll.lua)
end

-- Rolls a d20 like RPSheet:RollD20, then what the "Next roll" rows add to it, and
-- passes on the die, its note, and `extra` = { value = 3, text = "1d4" } (nil when
-- nothing is set) for ns.RollText.Check. A natural 20 or 1 still goes by the die.
function RPSheet:RollTest(mode, callback)
    local die, flat = self.rollBonusDie, self.rollBonusFlat or 0
    if not self.rollBonusLocked and (die or flat ~= 0) then
        self.rollBonusDie, self.rollBonusFlat = nil, 0 -- used up by this roll
        self:RefreshRollBonus()
    end
    self:RollD20(mode, function(d20, note)
        if d20 == 1 then self:NaturalOne() end -- a Zandalari troll's inspiration (Actions/Inspiration.lua)
        if not die and flat == 0 then return callback(d20, note) end
        local words = {}
        if flat ~= 0 then words[1] = ns.Util.Signed(flat) end
        if not die then return callback(d20, note, { value = flat, text = "next roll " .. words[1] }) end
        table.insert(words, 1, ("%s1d%d"):format(die.sign < 0 and "-" or "", die.sides))
        self:Roll(die.sides, function(rolled)
            callback(d20, note, { value = die.sign * rolled + flat, text = table.concat(words, " ") })
        end)
    end)
end
