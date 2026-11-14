-- Whether a d20 is rolled with advantage or disadvantage, from everything the sheet
-- knows: the player's choice, features, conditions and armor.
-- Rolls are named by their label on the sheet: "attack", "spell attack",
-- "initiative", a skill's name, "STR check", "DEX save".
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local skillNames
local function IsSkill(label)
    if not skillNames then
        skillNames = {}
        for _, skill in ipairs(R.SKILLS) do skillNames[skill.name] = true end
    end
    return skillNames[label] == true
end

local function IsAttack(label)
    return label == "attack" or label == "spell attack"
end

-- Ability checks: skills, plain ability checks and initiative.
local function IsCheck(label)
    return label == "initiative" or IsSkill(label) or label:find(" check$") ~= nil
end

-- A condition or armor that gives disadvantage on the roll: its name, or nil.
function RPSheet:DisadvantageFrom(label)
    local on = self:State().conditions
    if IsAttack(label) then
        for _, name in ipairs({ "Blinded", "Frightened", "Poisoned", "Prone", "Restrained" }) do
            if on[name] then return name end
        end
    end
    if IsCheck(label) then
        for _, name in ipairs({ "Frightened", "Poisoned" }) do
            if on[name] then return name end
        end
    end
    if label == "DEX save" and on.Restrained then return "Restrained" end
    if label == "initiative" then
        for _, name in ipairs({ "Incapacitated", "Paralyzed", "Petrified", "Stunned", "Unconscious" }) do
            if on[name] then return name end
        end
    end
    if label == "Stealth" and not self:Form() then
        local armor = R.ARMOR[self:Sheet().armor]
        if armor and armor.stealth then return "armor" end
    end
end

-- A condition that gives advantage on the roll: its name, or nil.
function RPSheet:AdvantageFrom(label)
    local on = self:State().conditions
    if on.Invisible and (IsAttack(label) or label == "initiative") then return "Invisible" end
end

-- A condition under which the saving throw fails without a roll: its name, or nil.
function RPSheet:AutoFail(label)
    if label ~= "STR save" and label ~= "DEX save" then return end
    local on = self:State().conditions
    for _, name in ipairs({ "Paralyzed", "Petrified", "Stunned", "Unconscious" }) do
        if on[name] then return name end
    end
end

-- A condition that stops the character from moving: its name, or nil.
function RPSheet:Immobile()
    local on = self:State().conditions
    for _, name in ipairs({ "Grappled", "Paralyzed", "Petrified", "Restrained", "Unconscious" }) do
        if on[name] then return name end
    end
end

-- Feet of speed heavy armor costs a character without the Strength for it.
function RPSheet:ArmorSpeedPenalty()
    if self:Form() then return 0 end
    local armor = R.ARMOR[self:Sheet().armor]
    return (armor and armor.minStr and self:Score("STR") < armor.minStr) and 10 or 0
end

-- The mode a roll ends up with: `mode` is what the player chose ("ADV", "DIS" or nil).
-- Advantage and disadvantage from any number of sources cancel each other out.
function RPSheet:ResolveMode(label, mode)
    local advantage = mode == "ADV" or self:HasAdvantage(label) or self:AdvantageFrom(label) ~= nil
    local disadvantage = mode == "DIS" or self:DisadvantageFrom(label) ~= nil
    if advantage and disadvantage then return nil end
    return (advantage and "ADV") or (disadvantage and "DIS") or nil
end
