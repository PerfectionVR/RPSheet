-- Bonuses that count only in some situations: features that stop working in armor,
-- and bonuses that are for attacks made with Strength.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- True without armor and without a shield.
function ns.Unarmored(sheet)
    return (sheet.armor or "NONE") == "NONE" and not sheet.shield
end

function ns.HeavyArmor(sheet)
    local armor = R.ARMOR[sheet.armor]
    return armor ~= nil and armor.dexCap == 0
end

-- A passive can carry a limit:
--   "UNARMORED"  only without armor and without a shield (a Monk's Unarmored Movement)
--   "NOHEAVY"    not in heavy armor (Fast Movement, Roving)
-- Returns what stops the passive right now, or nil. A beast form wears no armor.
function RPSheet:PassiveBlocked(passive)
    if not passive.limit or self:Form() then return nil end
    local sheet = self:Sheet()
    if passive.limit == "UNARMORED" and not ns.Unarmored(sheet) then
        return sheet.armor ~= "NONE" and "armor" or "a shield"
    end
    if passive.limit == "NOHEAVY" and ns.HeavyArmor(sheet) then return "heavy armor" end
end

-- What passives add to the damage of an attack made with `stat`. Some bonuses, such
-- as a rage's, are for Strength attacks only (effect target "STRDAMAGE").
function RPSheet:DamageBonus(stat)
    return self:Bonus("DAMAGE") + (stat == "STR" and self:Bonus("STRDAMAGE") or 0)
end
