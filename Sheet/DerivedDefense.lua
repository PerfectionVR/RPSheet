-- Numbers worked out from the saved sheet: hit points and Armor Class.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Level 1 takes the full hit die; each later level takes the average, rounded up.
function RPSheet:MaxHP()
    local level = self:Level()
    -- A beast form's Constitution doesn't change the hit points.
    -- Each class's levels count with that class's die (Sheet/ClassHitDice.lua).
    local total = ns.DiceHitPoints(self:Sheet()) + level * self:OwnMod("CON")
    return math.max(1, total + self:Bonus("HP") + self:Sheet().hpAdjust)
end

-- Unarmored Defense: without armor, a class adds an ability modifier to Armor Class;
-- a Monk's stops working with a shield. A character who has the feature can't gain
-- it again from another class, so the first class that has it decides: the first
-- class, then the later ones in the usual class order (the sheet doesn't keep the
-- order in which those were taken).
function RPSheet:UnarmoredDefense()
    local sheet = self:Sheet()
    if sheet.armor ~= "NONE" then return 0 end
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local class = R.CLASSES[key]
        if class.unarmored then
            if sheet.shield and not class.unarmoredShield then return 0 end
            return self:Mod(class.unarmored), class.unarmored
        end
    end
    return 0
end

function RPSheet:AC()
    local sheet = self:Sheet()
    -- A beast form has an Armor Class of its own; armor and shield don't count.
    local form = self:Form()
    if form then
        local ac = form.ac + (form.acStat and self:Mod(form.acStat) or 0)
        -- A Circle of the Moon druid's beast forms have at least 13 + Wisdom.
        if form.beast and ns.HasSubclass(sheet, "Circle of the Moon") then ac = math.max(ac, 13 + self:Mod("WIS")) end
        return ac + self:Bonus("AC")
    end
    local armor = R.ARMOR[sheet.armor]
    local dex = self:Mod("DEX")
    -- Medium Armor Master can raise medium armor's limit (Sheet/FeatRules.lua).
    local cap = self:ArmorDexCap(armor)
    if cap then dex = math.min(dex, cap) end
    local ac = armor.ac + dex
    ac = ac + (self:UnarmoredDefense())
    if sheet.shield then ac = ac + R.SHIELD_AC end
    ac = ac + self:WornBonus() -- magic armor and shield
    return ac + self:Bonus("AC") + self:StyleAC()
end
