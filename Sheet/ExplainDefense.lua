-- How the speed and the Armor Class are worked out (mirrors Sheet/DerivedSpeed.lua and
-- Sheet/DerivedDefense.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Out = ns.ExplainKit.Out
local Add = ns.ExplainKit.Add
local AddBonuses = ns.ExplainKit.AddBonuses
local Join = ns.ExplainKit.Join
local Total = ns.ExplainKit.Total

function RPSheet:ExplainSpeed()
    local stuck = self:Immobile()
    if stuck then
        Out(self, ("Speed |cffffd1000 ft|r: you are %s."):format(stuck))
        return
    end
    local mount = self:RiddenMount()
    if mount then
        Out(self, self:MountSpeedText(mount)) -- with what holds the mount back (Sheet/MountLoad.lua)
        return
    end
    local species, form = self:SpeciesData(), self:Form()
    -- An item can set the speed the rest is added to, or multiply the outcome (RPSheet:Speed).
    local base, setBy, replaced = self:BaseSpeed()
    local parts = { { form and form.name or species and species.name or "base", replaced or base } }
    if setBy then Add(parts, ("%s (sets your speed to %d)"):format(setBy, base), base - replaced) end
    AddBonuses(self, parts, "SPEED")
    Add(parts, "flying companion", self:CompanionSpeed())
    if not form then Add(parts, "armor too heavy for your Strength", -self:ArmorSpeedPenalty()) end
    local times, multiplier = self:EffectMultiplier("SPEED")
    if times > 1 then
        Add(parts, ("%s (speed times %d)"):format(multiplier, times), math.max(0, Total(parts)) * (times - 1))
    end
    if not form and self:Overloaded() then
        Out(self, ("Speed |cffffd100%d ft|r: you carry %.1f lb., more than the %d lb. you can, which holds your speed to %d feet. Without the load: %s."):format(
            self:Speed(), self:CarriedWeight(), self:CarryCapacity(), R.OVERLOADED_SPEED, Join(parts)))
        return
    end
    Out(self, ("Speed |cffffd100%d ft|r: %s."):format(Total(parts), Join(parts)))
end

function RPSheet:ExplainAC()
    local sheet = self:Sheet()
    local form = self:Form()
    if form then
        local formParts = { { form.name, form.ac } }
        if form.acStat then Add(formParts, R.STAT_NAMES[form.acStat], self:Mod(form.acStat)) end
        if form.beast and ns.HasSubclass(sheet, "Circle of the Moon") then
            Add(formParts, "Circle Forms (at least 13 + Wisdom)", math.max(0, 13 + self:Mod("WIS") - form.ac))
        end
        AddBonuses(self, formParts, "AC")
        Out(self, ("Armor Class |cffffd100%d|r: %s. Armor and shield don't count in this form."):format(Total(formParts), Join(formParts)))
        return
    end
    local armor = R.ARMOR[sheet.armor]
    local parts = { { armor.name, armor.ac } }
    local dex = self:Mod("DEX")
    local cap, raisedBy = self:ArmorDexCap(armor)
    if cap then
        Add(parts, ("Dexterity (at most +%d in this armor%s)"):format(cap, raisedBy and (", " .. raisedBy) or ""), math.min(dex, cap))
    else
        Add(parts, "Dexterity", dex)
    end
    local unarmored, unarmoredStat = self:UnarmoredDefense()
    if unarmoredStat then
        Add(parts, "Unarmored Defense, " .. R.STAT_NAMES[unarmoredStat], unarmored)
    end
    if sheet.shield then Add(parts, "shield", R.SHIELD_AC) end
    Add(parts, "magic armor and shield", self:WornBonus())
    AddBonuses(self, parts, "AC")
    Add(parts, "Fighting Style", self:StyleAC())
    Out(self, ("Armor Class |cffffd100%d|r: %s."):format(Total(parts), Join(parts)))
end
