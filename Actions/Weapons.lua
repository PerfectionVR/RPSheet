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
    local mod = self:Mod(weapon.stat)
    if weapon.heal then
        return ("%dd%d %s healing"):format(weapon.dice, weapon.sides, Util.Signed(mod + self:Bonus("HEALING")))
    end
    local toHit = mod + (weapon.proficient and self:ProficiencyBonus() or 0) + self:Bonus("ATTACK")
    return ("%s to hit, %dd%d %s damage"):format(
        Util.Signed(toHit), weapon.dice, weapon.sides, Util.Signed(mod + self:Bonus("DAMAGE")))
end

-- Attack: d20 + ability + proficiency, then the weapon's dice + ability.
-- A natural 20 rolls the damage dice twice. Healing "weapons" skip the d20.
function RPSheet:Attack(mode)
    local weapon = self:GetWeapon()
    if not weapon then return end
    local mod = self:Mod(weapon.stat)
    if weapon.heal then
        self:RollDice(weapon.dice, weapon.sides, function(rolls)
            self:Announce(("uses %s - %s"):format(weapon.name, RollText.Dice("healing", rolls, weapon.sides, mod + self:Bonus("HEALING"))))
        end)
        return
    end
    local attackMod = mod + (weapon.proficient and self:ProficiencyBonus() or 0) + self:Bonus("ATTACK")
    local damageMod = mod + self:Bonus("DAMAGE")
    self:RollD20(mode, function(d20, note)
        local crit = d20 == 20
        self:RollDice(weapon.dice * (crit and 2 or 1), weapon.sides, function(rolls)
            self:Announce(("attacks with %s - %s, %s"):format(
                weapon.name, RollText.Check("to hit", d20, attackMod, note),
                RollText.Dice(crit and "critical damage" or "damage", rolls, weapon.sides, damageMod)))
        end)
    end)
end
