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
    return label == "initiative" or IsSkill(label) or R.TOOLS[label] ~= nil or label:find(" check$") ~= nil
end

-- The condition that leaves the character incapacitated: Incapacitated itself or one
-- that includes it. Its name, or nil.
local INCAPACITATING = { "Incapacitated", "Paralyzed", "Petrified", "Stunned", "Unconscious" }
function RPSheet:Incapacitated()
    local on = self:State().conditions
    for _, name in ipairs(INCAPACITATING) do
        if on[name] then return name end
    end
end

-- (for Actions/RollQuestions.lua, which asks about attacks and checks)
ns.IsAttackRoll = IsAttack
ns.IsCheckRoll = IsCheck

-- A condition or armor that gives disadvantage on the roll: its name, or nil.
-- `answers` is what the player said about this one roll (Actions/RollQuestions.lua):
-- Frightened = false when the source of the fear is out of sight, Grappled = false
-- when the attack is against the grappler. Without an answer both count.
function RPSheet:DisadvantageFrom(label, answers)
    local on = self:State().conditions
    -- Turned to stone, poison does nothing. Unconscious includes Prone.
    local poisoned = on.Poisoned and not on.Petrified
    local frightened = on.Frightened and not (answers and answers.Frightened == false)
    if IsAttack(label) then
        if on.Blinded then return "Blinded" end
        if frightened then return "Frightened" end
        for _, name in ipairs({ "Prone", "Restrained" }) do
            if on[name] then return name end
        end
        if poisoned then return "Poisoned" end
        if on.Unconscious then return "Unconscious" end
        if on.Grappled and not (answers and answers.Grappled == false) then return "Grappled" end
    end
    if IsCheck(label) then
        if frightened then return "Frightened" end
        if poisoned then return "Poisoned" end
    end
    if label == "DEX save" and on.Restrained then return "Restrained" end
    if label == "initiative" then
        local name = self:Incapacitated()
        if name then return name end
    end
    if label == "Stealth" and not self:Form() then
        local armor = R.ARMOR[self:Sheet().armor]
        -- Mithral armor is quiet (Sheet/ItemVariants.lua).
        if armor and armor.stealth and not ns.ArmorWaives(self:Sheet(), "noStealth") then return "armor" end
    end
end

-- A condition or a loyal companion's gift that gives advantage on the roll: its name,
-- or nil.
function RPSheet:AdvantageFrom(label)
    local on = self:State().conditions
    if on.Invisible and (IsAttack(label) or label == "initiative") then return "Invisible" end
    if self:CompanionAdvantage(label) then return "your companion" end
    if self:BloodiedFrenzy(label) then return "Bloodied Frenzy" end
    -- A trait, feat or item that covers every save of that ability (Sheet/SaveAdvantages.lua).
    local always = self:SaveAdvantages(label)
    if always[1] then return always[1].from end
end

-- A condition under which the saving throw fails without a roll: its name, or nil.
function RPSheet:AutoFail(label)
    if label ~= "STR save" and label ~= "DEX save" then return end
    local on = self:State().conditions
    for _, name in ipairs({ "Paralyzed", "Petrified", "Stunned", "Unconscious" }) do
        if on[name] then return name end
    end
end

-- True when a switched-on passive other than the one named gives advantage on the roll.
function RPSheet:OtherAdvantage(label, except)
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= except then
            local feat = R.FEATS[passive.name]
            for _, list in ipairs({ feat and feat.advantage or {}, passive.advantage or {} }) do
                for _, name in ipairs(list) do
                    if name == label then return true end
                end
            end
        end
    end
    return false
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
    if ns.ArmorWaives(self:Sheet(), "noStrength") then return 0 end -- mithral asks for none
    return (armor and armor.minStr and self:Score("STR") < armor.minStr) and 10 or 0
end

-- The mode a roll ends up with: `mode` is what the player chose ("ADV", "DIS" or nil).
-- Advantage and disadvantage from any number of sources cancel each other out.
-- `also` is a second label the roll goes by, such as "STR attack" for an attack made
-- with Strength. `extra` is true for advantage from something the sheet was told
-- about for this roll alone (what a save is against); `answers` is everything the
-- player was asked about this roll, where `about` is that same thing.
function RPSheet:ResolveMode(label, mode, also, extra, answers)
    if answers and answers.about then extra = true end
    local advantage = extra == true or mode == "ADV" or self:HasAdvantage(label) or self:AdvantageFrom(label) ~= nil
        or (also ~= nil and self:HasAdvantage(also))
    -- Danger Sense doesn't work while incapacitated: without it, is there still advantage?
    if advantage and not extra and mode ~= "ADV" and label == "DEX save" and self:Incapacitated()
        and ns.HasFeature(self:Sheet(), "Danger Sense") then
        advantage = self:AdvantageFrom(label) ~= nil or self:OtherAdvantage(label, "Danger Sense")
    end
    local disadvantage = mode == "DIS" or self:DisadvantageFrom(label, answers) ~= nil
    if advantage and disadvantage then return nil end
    return (advantage and "ADV") or (disadvantage and "DIS") or nil
end
