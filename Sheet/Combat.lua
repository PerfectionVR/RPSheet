-- Class features found on the sheet, weapon masteries, critical hits and what
-- switched-on passives add to rolls (data in Data/Combat.lua). Fighting Styles are in
-- Sheet/FightingStyles.lua. The Weapon Mastery feature lets each weapon use the
-- mastery set on it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The passive a class or subclass feature of that name put on the sheet, if any.
local function FeaturePassive(sheet, feature)
    for _, passive in ipairs(sheet.passives) do
        local auto = passive.auto or ""
        if auto:sub(-#feature - 1) == ":" .. feature and (auto:find("^class:") or auto:find("^subclass:")) then
            return passive
        end
    end
end

ns.FeaturePassive = FeaturePassive

---------------------------------------------------------------------------
-- Weapon mastery
---------------------------------------------------------------------------
function RPSheet:HasWeaponMastery()
    return FeaturePassive(self:Sheet(), "Weapon Mastery") ~= nil
end

-- The mastery a weapon can use right now, or nil.
function RPSheet:WeaponMastery(weapon)
    local mastery = R.MASTERIES[weapon.mastery]
    if not mastery or weapon.heal then return end
    -- The number a class allows is shown, not enforced: see Options/Weapons.lua.
    if self:HasWeaponMastery() then return weapon.mastery, mastery end
    -- Without the class feature, a feat unlocks the one kind of weapon picked for it.
    if ns.FeatMasteryWeapons(self:Sheet())[weapon.base or ""] then return weapon.mastery, mastery end
end

-- What is said about the mastery when attacking, e.g. "On a hit: pushes the target 10 feet [Push]".
function RPSheet:MasteryNote(weapon)
    local name, mastery = self:WeaponMastery(weapon)
    if not name then return end
    local mod = self:Mod(self:WeaponStat(weapon))
    local number = name == "Topple" and (8 + mod + self:ProficiencyBonus()) or math.max(0, mod)
    return ("%s %s"):format(mastery.note:format(number), ns.Mark(name))
end

---------------------------------------------------------------------------
-- Critical hits and advantage from features
---------------------------------------------------------------------------
-- The lowest d20 roll that is a critical hit with a weapon or unarmed strike:
-- 20, or lower with a passive that widens the range (a Champion's Improved Critical).
function RPSheet:CritFrom()
    return math.max(2, 20 - self:Bonus("CRIT"))
end

-- True if a switched-on passive gives advantage on the roll with this label
-- ("initiative", a skill's name, "DEX save", "death save").
function RPSheet:HasAdvantage(label)
    for _, passive in ipairs(self:Sheet().passives) do
        -- A feat on the sheet brings the advantage its data names.
        local feat = passive.enabled and R.FEATS[passive.name]
        for _, name in ipairs(feat and feat.advantage or {}) do
            if name == label then return true end
        end
        if passive.enabled and passive.advantage then
            for _, name in ipairs(passive.advantage) do
                if name == label then return true end
            end
        end
    end
    return false
end

-- A flag that switched-on passives carry (see Kit.Passive): true if any has it, or
-- the sum when it is a number. Nil when none does.
function RPSheet:FeatureFlag(name)
    local found
    for _, passive in ipairs(self:Sheet().passives) do
        local value = passive.enabled and passive.flags and passive.flags[name]
        if value == true then return true end
        if type(value) == "number" then found = (found or 0) + value end
    end
    return found
end

-- Dice that switched-on passives add to every melee weapon hit (Radiant Strikes),
-- as a list of { sides, damage }. None for a ranged basic weapon or a healing one.
function RPSheet:StrikeDice(weapon)
    local data, strikes = ns.WeaponData(weapon), {}
    if weapon.heal or (data and data.ranged) then return strikes end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.strike then strikes[#strikes + 1] = passive.strike end
    end
    return strikes
end
