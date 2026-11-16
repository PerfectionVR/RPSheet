-- Feats that change a weapon attack's damage, applied by RPSheet:Attack
-- (Actions/Weapons.lua): Great Weapon Master's extra damage with a heavy weapon, Boon
-- of Irresistible Offense on a natural 20, Savage Attacker's second roll (the better
-- one is kept), Piercer's reroll and extra critical die, and Fists of Fury with a light
-- weapon. What they leave to the table (once per turn, on your own turn) is said in
-- the announcement.
local _, ns = ...
local RPSheet = ns.addon

-- Dice to add to the weapon's on a critical hit: Piercer's one more piercing die.
function RPSheet:WeaponCritDice(weapon)
    local data = ns.WeaponData(weapon)
    if data and data.damage == "piercing" and self:HasPassive("Piercer") then return 1 end
    return 0
end

-- Damage added to a hit, and notes: { flat = n, notes = { ... } }.
function RPSheet:WeaponFeatDamage(weapon, d20)
    local data, flat, notes = ns.WeaponData(weapon), 0, {}
    if data and data.props.H and self:HasPassive("Great Weapon Master") then
        local bonus = self:ProficiencyBonus()
        flat = flat + bonus
        notes[#notes + 1] = ("+%d %s, on a hit with the Attack action on your turn"):format(bonus, ns.Mark("Great Weapon Master"))
    end
    if d20 == 20 and self:HasPassive("Boon of Irresistible Offense") then
        local stat = ns.FeatRaisedStat(self:Sheet(), "Boon of Irresistible Offense")
            or (self:Score("DEX") > self:Score("STR") and "DEX" or "STR")
        local score = self:Score(stat)
        flat = flat + score
        notes[#notes + 1] = ("+%d %s (your %s)"):format(score, ns.Mark("Boon of Irresistible Offense"), ns.Rules.STAT_NAMES[stat])
    end
    return flat, notes
end

local function Sum(rolls)
    local total = 0
    for _, roll in ipairs(rolls) do total = total + roll end
    return total
end

-- Changes the rolled damage dice in place, then calls done(notes).
function RPSheet:WeaponFeatDice(weapon, rolls, sides, done)
    local data, notes = ns.WeaponData(weapon), {}
    local function Light()
        local upTo, lowest, from = self:StrikeDiceRules(data ~= nil and data.props.L == true, false)
        self:AdjustRolls(rolls, sides, upTo, lowest, from, function(more)
            for _, note in ipairs(more) do notes[#notes + 1] = note end
            done(notes)
        end)
    end
    -- Piercer: one die is rerolled, and the new roll kept. The sheet picks the lowest,
    -- when it is below the die's average.
    local function Pierce()
        if not (data and data.damage == "piercing" and self:HasPassive("Piercer")) or #rolls == 0 then return Light() end
        local low = 1
        for index, roll in ipairs(rolls) do
            if roll < rolls[low] then low = index end
        end
        if rolls[low] * 2 >= sides + 1 then return Light() end
        self:Roll(sides, function(value)
            notes[#notes + 1] = ("a %d rerolled as %d, Piercer once a turn"):format(rolls[low], value)
            rolls[low] = value
            Light()
        end)
    end
    -- Savage Attacker: the dice rolled twice, the better total kept.
    if not self:HasPassive("Savage Attacker") or #rolls == 0 then return Pierce() end
    self:RollDice(#rolls, sides, function(again)
        local first, second = Sum(rolls), Sum(again)
        if second > first then
            for index, roll in ipairs(again) do rolls[index] = roll end
        end
        notes[#notes + 1] = ("rolled twice, %d kept over %d, Savage Attacker once a turn"):format(math.max(first, second), math.min(first, second))
        Pierce()
    end)
end
