-- Spells that change the weapon rows while they last (data: Data/SpellWardWeapons.lua),
-- and True Strike, which changes the next attack only: the ability a weapon uses, its
-- die, its bonus, and dice added to its hits. The weapon helpers of Sheet/Armoury.lua,
-- Sheet/StyleEffects.lua and Sheet/Combat.lua are wrapped here.
--   state.trueStrike = { stat, count }   until the next weapon attack rolls its damage
local _, ns = ...
local RPSheet = ns.addon

local STAFFS = { Club = true, Quarterstaff = true }

-- The spellcasting ability of a listed spell on the sheet, or nil.
local function CastStatOf(self, name)
    for _, spell in ipairs(self:Sheet().spells or {}) do
        if spell.name == name then return self:CastStat(spell) end
    end
end

-- Shillelagh holds for a melee attack with a club or quarterstaff.
local function Shillelagh(self, weapon)
    local data = ns.WeaponData(weapon)
    return self:FeatureFlag("shillelagh") and data and STAFFS[data.name or weapon.base] and not weapon.heal
end

local WeaponStat = RPSheet.WeaponStat
function RPSheet:WeaponStat(weapon)
    local strike = self:State().trueStrike
    if type(strike) == "table" and strike.stat and not weapon.heal then return strike.stat end
    if Shillelagh(self, weapon) then return CastStatOf(self, "Shillelagh") or WeaponStat(self, weapon) end
    return WeaponStat(self, weapon)
end

-- Shillelagh's die: a d8, a d10 from level 5, a d12 from 11, 2d6 from 17.
local WeaponDice = RPSheet.WeaponDice
function RPSheet:WeaponDice(weapon)
    if not Shillelagh(self, weapon) then return WeaponDice(self, weapon) end
    local level = self:Level()
    if level >= 17 then return 2, 6 end
    return 1, level >= 11 and 12 or level >= 5 and 10 or 8
end

-- Magic Weapon and Elemental Weapon make a weapon that isn't magic a magic one.
local WeaponStyle = RPSheet.WeaponStyle
function RPSheet:WeaponStyle(weapon)
    local attack, damage, minDie = WeaponStyle(self, weapon)
    if not weapon.heal and (weapon.magic or 0) == 0 then
        local magic, toHit = self:FeatureFlag("weaponMagic"), self:FeatureFlag("weaponAttack")
        if type(magic) == "number" then attack, damage = attack + magic, damage + magic end
        if type(toHit) == "number" then attack = attack + toHit end
    end
    return attack, damage, minDie
end

-- A spell's dice for ranged weapons too (`all`), and True Strike's radiant dice, which
-- its attack uses up.
local StrikeDice = RPSheet.StrikeDice
function RPSheet:StrikeDice(weapon)
    local strikes = StrikeDice(self, weapon)
    local data = ns.WeaponData(weapon)
    if not weapon.heal and data and data.ranged then
        for _, passive in ipairs(self:Sheet().passives) do
            if passive.enabled and type(passive.strike) == "table" and passive.strike.all then strikes[#strikes + 1] = passive.strike end
        end
    end
    local state = self:State()
    local strike = state.trueStrike
    if type(strike) == "table" and not weapon.heal then
        state.trueStrike = nil
        if (strike.count or 0) > 0 then strikes[#strikes + 1] = { count = strike.count, sides = 6, damage = "True Strike radiant" } end
        self:PopulateSoon()
    end
    return strikes
end

-- After True Strike is cast: the next weapon attack goes by it. Its radiant dice: one
-- at level 5, two at 11, three at 17.
function RPSheet:ReadyTrueStrike(spell)
    local level = self:Level()
    local count = level >= 17 and 3 or level >= 11 and 2 or level >= 5 and 1 or 0
    self:State().trueStrike = { stat = self:CastStat(spell), count = count }
    self:PopulateSoon()
    return ("your next weapon attack uses %s%s"):format(ns.Rules.STAT_NAMES[self:CastStat(spell)] or self:CastStat(spell),
        count > 0 and (" and deals %dd6 radiant damage more"):format(count) or "")
end
