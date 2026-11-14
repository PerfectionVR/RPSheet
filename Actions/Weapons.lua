-- The equipped weapon and attacking with it.
local _, ns = ...
local RPSheet = ns.addon
local Util = ns.Util
local RollText = ns.RollText

function RPSheet:GetWeapon()
    local weapons = Util.Named(self:Sheet().weapons)
    return weapons[self:State().weapon] or weapons[1]
end

function RPSheet:SwapWeapon()
    local count = #Util.Named(self:Sheet().weapons)
    if count == 0 then return end
    self:State().weapon = self:State().weapon % count + 1
    self:Refresh()
end

-- Text for the weapon row on the sheet, e.g. "+5 to hit, 1d8 +3 damage".
function RPSheet:WeaponText(weapon)
    local mod = self:Mod(self:WeaponStat(weapon))
    if weapon.heal then
        return ("%dd%d %s healing"):format(weapon.dice, weapon.sides, Util.Signed(mod + self:Bonus("HEALING")))
    end
    local styleAttack, styleDamage = self:WeaponStyle(weapon)
    local toHit = mod + (weapon.proficient and self:ProficiencyBonus() or 0) + self:Bonus("ATTACK") + styleAttack
    local count, sides = self:WeaponDice(weapon)
    local text = ("%s to hit, %dd%d %s %s"):format(
        Util.Signed(toHit), count, sides, Util.Signed(mod + self:Bonus("DAMAGE") + styleDamage), ns.DamageWord(weapon))
    local mastery = self:WeaponMastery(weapon)
    return mastery and (text .. ", " .. mastery) or text
end

-- Attack: d20 + ability + proficiency, then the weapon's dice + ability.
-- A natural 20 rolls the damage dice twice. Healing "weapons" skip the d20.
function RPSheet:Attack(mode)
    local weapon = self:GetWeapon()
    if not weapon then return end
    local mod = self:Mod(self:WeaponStat(weapon))
    if weapon.heal then
        self:RollDice(weapon.dice, weapon.sides, function(rolls)
            self:Announce(("uses %s - %s"):format(ns.Mark(weapon.name), RollText.Dice("healing", rolls, weapon.sides, mod + self:Bonus("HEALING"))))
        end)
        return
    end
    local styleAttack, styleDamage, minDie = self:WeaponStyle(weapon)
    local attackMod = mod + (weapon.proficient and self:ProficiencyBonus() or 0) + self:Bonus("ATTACK") + styleAttack
    local damageMod = mod + self:Bonus("DAMAGE") + styleDamage
    local mastery = self:MasteryNote(weapon)
    local count, sides = self:WeaponDice(weapon)
    local word = ns.DamageWord(weapon)
    self:RollD20(mode, function(d20, note)
        local crit = d20 == 20
        self:RollDice(count * (crit and 2 or 1), sides, function(rolls)
            -- Great Weapon Fighting: low damage dice count as higher.
            for index, roll in ipairs(rolls) do rolls[index] = math.max(roll, minDie) end
            local text = ("attacks with %s - %s, %s"):format(
                ns.Mark(weapon.name), RollText.Check("to hit", d20, attackMod, note),
                RollText.Dice(crit and ("critical " .. word) or word, rolls, sides, damageMod))
            if mastery then text = text .. ". " .. mastery end
            self:Announce(text)
        end)
    end)
end
