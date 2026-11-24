-- Small rules of feats, traits and blessings that change a number the sheet works out
-- elsewhere: found by the name of a passive on the sheet, or the species' traits.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

-- True if a switched-on passive of that name is on the sheet (a feat, a blessing).
function ns.PassiveOn(sheet, name)
    for _, passive in ipairs(sheet.passives or NONE) do
        if passive.name == name and passive.enabled then return true end
    end
    return false
end

function RPSheet:HasPassive(name)
    return ns.PassiveOn(self:Sheet(), name)
end

-- True if the character's species has the trait.
function RPSheet:HasTrait(name)
    return ns.HasTrait(self:Sheet(), name)
end

-- The most Dexterity a suit of armor lets count for Armor Class, and what raised it:
-- Medium Armor Master lets medium armor take 3 rather than 2 with a Dexterity of 16
-- or more. Nil for armor without a limit.
function RPSheet:ArmorDexCap(armor)
    if not armor or not armor.dexCap then return nil end
    if armor.dexCap == 2 and self:HasPassive("Medium Armor Master") and self:Score("DEX") >= 16 then
        return 3, "Medium Armor Master"
    end
    return armor.dexCap
end

-- Troll's Bloodied Frenzy: advantage on attack rolls while at half hit points or fewer.
function RPSheet:BloodiedFrenzy(label)
    if label ~= "attack" and label ~= "spell attack" then return false end
    if not self:HasTrait("Bloodied Frenzy") then return false end
    local hp, max = self:State().hp, self:MaxHP()
    return type(hp) == "number" and hp > 0 and hp <= max / 2
end

-- The ability a feat taken at a level raised there, or nil (a background's feat or
-- one typed in raises none the sheet can tell).
function ns.FeatRaisedStat(sheet, featName)
    for _, passive in ipairs(sheet.passives or NONE) do
        local level = passive.name == featName and tonumber((passive.auto or ""):match("^level:(%d+)$"))
        local record = level and ns.Levels.Record(sheet, level)
        for _, stat in ipairs(R.STATS) do
            if record and (record.asi[stat] or 0) > 0 then return stat end
        end
    end
end
