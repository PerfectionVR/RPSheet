-- Fighting Styles and weapon masteries on the character (data in Data/Combat.lua).
--
-- A class with the Fighting Style feature picks one style (sheet.fightingStyle); a
-- Champion's Additional Fighting Style adds a second (sheet.fightingStyle2). The
-- Weapon Mastery feature lets each weapon use the mastery set on it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local STYLE_FIELDS = { "fightingStyle", "fightingStyle2" }
local STYLE_FEATURES = { "Fighting Style", "Additional Fighting Style" }
ns.STYLE_FIELDS, ns.STYLE_FEATURES = STYLE_FIELDS, STYLE_FEATURES

-- The passive a class or subclass feature of that name put on the sheet, if any.
local function FeaturePassive(sheet, feature)
    for _, passive in ipairs(sheet.passives) do
        local auto = passive.auto or ""
        if auto:sub(-#feature - 1) == ":" .. feature and (auto:find("^class:") or auto:find("^subclass:")) then
            return passive
        end
    end
end

-- True if the character can pick its first (slot 1) or second (slot 2) Fighting Style.
function ns.HasStyleSlot(sheet, slot)
    return FeaturePassive(sheet, STYLE_FEATURES[slot]) ~= nil
end

-- Styles that can go in a slot: a style can't be taken twice.
function ns.StyleChoices(sheet, slot)
    local other = sheet[STYLE_FIELDS[slot == 1 and 2 or 1]]
    local names = {}
    local class = R.CLASSES[sheet.class]
    for _, name in ipairs(R.FIGHTING_STYLE_ORDER) do
        local style = R.FIGHTING_STYLES[name]
        -- Some styles belong to one class.
        local allowed = (not style.base or (class and class.base == style.base)) and (not style.class or sheet.class == style.class)
        if allowed and (name ~= other or not ns.HasStyleSlot(sheet, slot == 1 and 2 or 1)) then names[#names + 1] = name end
    end
    return names
end

-- The styles the character has chosen and is entitled to.
function RPSheet:FightingStyles()
    local sheet, styles = self:Sheet(), {}
    local taken = {}
    for slot, field in ipairs(STYLE_FIELDS) do
        local style = R.FIGHTING_STYLES[sheet[field]]
        if style and ns.HasStyleSlot(sheet, slot) and not taken[style] then
            styles[#styles + 1], taken[style] = style, true
        end
    end
    return styles
end

-- What the Fighting Styles add to a weapon: attack bonus, damage bonus, and the
-- lowest a damage die can count as.
function RPSheet:WeaponStyle(weapon)
    local attack, damage, minDie = 0, 0, 1
    if not weapon.heal then
        for _, style in ipairs(self:FightingStyles()) do
            if ns.FitsStyle(weapon, style) then
                attack, damage = attack + (style.attack or 0), damage + (style.damage or 0)
                minDie = math.max(minDie, style.minDie or 1)
            end
        end
    end
    return attack, damage, minDie
end

-- Armor Class from Fighting Styles.
function RPSheet:StyleAC()
    local total = 0
    if self:Sheet().armor ~= "NONE" then
        for _, style in ipairs(self:FightingStyles()) do total = total + (style.armoredAC or 0) end
    end
    return total
end

-- True if any chosen style changes weapon numbers, so weapons need the tick box.
function RPSheet:StyleAffectsWeapons()
    for _, style in ipairs(self:FightingStyles()) do
        if style.attack or style.damage or style.minDie then return true end
    end
    return false
end

-- Shows the chosen style on the feature's passive. Called whenever class features
-- are refreshed (see Sheet/ClassFeatures.lua).
function ns.ApplyFightingStyles(sheet)
    for slot, feature in ipairs(STYLE_FEATURES) do
        local passive = FeaturePassive(sheet, feature)
        if passive then
            local name = sheet[STYLE_FIELDS[slot]]
            local style = R.FIGHTING_STYLES[name]
            if style then
                passive.name, passive.desc = feature .. ": " .. name, style.desc
            else
                passive.name = feature
                passive.desc = "You have a Fighting Style to choose. Pick it under Customize, Class and origin."
            end
        end
    end
end

---------------------------------------------------------------------------
-- Weapon mastery
---------------------------------------------------------------------------
function RPSheet:HasWeaponMastery()
    return FeaturePassive(self:Sheet(), "Weapon Mastery") ~= nil
end

-- The mastery a weapon can use right now, or nil.
function RPSheet:WeaponMastery(weapon)
    local mastery = R.MASTERIES[weapon.mastery]
    -- The number a class allows is shown, not enforced: see Options/Weapons.lua.
    if mastery and not weapon.heal and self:HasWeaponMastery() then return weapon.mastery, mastery end
end

-- What is said about the mastery when attacking, e.g. "On a hit: pushes the target 10 feet (Push)".
function RPSheet:MasteryNote(weapon)
    local name, mastery = self:WeaponMastery(weapon)
    if not name then return end
    local mod = self:Mod(weapon.stat)
    local number = name == "Topple" and (8 + mod + self:ProficiencyBonus()) or math.max(0, mod)
    return ("%s (%s)"):format(mastery.note:format(number), name)
end
