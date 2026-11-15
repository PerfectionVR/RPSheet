-- How a weapon's attack and damage are worked out (mirrors Actions/Weapons.lua).
local _, ns = ...
local RPSheet = ns.addon
local Util = ns.Util
local Out = ns.ExplainKit.Out
local Add = ns.ExplainKit.Add
local AddBonuses = ns.ExplainKit.AddBonuses
local Join = ns.ExplainKit.Join
local Total = ns.ExplainKit.Total
local Ability = ns.ExplainKit.Ability

function RPSheet:ExplainWeapon(weapon)
    local sheet = self:Sheet()
    if weapon.heal then
        local parts = {}
        Ability(self, parts, self:WeaponStat(weapon))
        AddBonuses(self, parts, "HEALING")
        Out(self, ("%s, healing %dd%d %s: %s."):format(weapon.name, weapon.dice, weapon.sides, Util.Signed(Total(parts)), Join(parts)))
        return
    end
    local hit, damage, notes = {}, {}, {}
    Ability(self, hit, self:WeaponStat(weapon))
    Ability(self, damage, self:WeaponStat(weapon))
    if weapon.proficient then Add(hit, "proficiency", self:ProficiencyBonus()) end
    Add(hit, "magic weapon", weapon.magic)
    Add(damage, "magic weapon", weapon.magic)
    AddBonuses(self, hit, "ATTACK")
    AddBonuses(self, damage, "DAMAGE")
    if self:WeaponStat(weapon) == "STR" then AddBonuses(self, damage, "STRDAMAGE") end
    -- Fighting Styles that fit this weapon (see RPSheet:WeaponStyle).
    -- Every class's style counts, none twice (ns.StylesHeld).
    for _, held in ipairs(ns.StylesHeld(sheet)) do
        local name, style = held.name, held.style
        if ns.FitsStyle(weapon, style) then
            Add(hit, name, style.attack)
            Add(damage, name, style.damage)
            if style.minDie then notes[#notes + 1] = ("%s: a damage die below %d counts as %d"):format(name, style.minDie, style.minDie) end
        end
    end
    local count, sides = self:WeaponDice(weapon)
    local data = ns.WeaponData(weapon)
    if data and data.versatile then
        notes[#notes + 1] = weapon.twoHands and "held in two hands for the larger die" or "held in one hand"
    end
    Out(self, ("%s, to hit |cffffd100%s|r: %s. %s %dd%d |cffffd100%s|r: %s.%s"):format(
        weapon.name, Util.Signed(Total(hit)), Join(hit),
        ns.DamageWord(weapon):gsub("^%l", string.upper), count, sides, Util.Signed(Total(damage)), Join(damage),
        #notes > 0 and (" " .. table.concat(notes, "; "):gsub("^%l", string.upper) .. ".") or ""))
end
