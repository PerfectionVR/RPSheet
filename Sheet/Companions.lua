-- Companion creatures on the sheet (the entries of sheet.mounts of kind COMPANION):
-- which one is out, its loyalty, and the part of a loyal one's gift that is a number
-- the sheet can count. See Data/Companions.lua for the rules.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

local NONE = {}

-- The companion creature that is out right now, if any.
function RPSheet:Companion()
    for _, entry in ipairs(self:Sheet().mounts or NONE) do
        if entry.called and entry.name ~= "" and entry.kind == "COMPANION" then return entry end
    end
end

-- Loyalty a newly gained companion has, and the most it can reach. Both follow the
-- character's own Charisma, not that of a form.
function RPSheet:StartingLoyalty()
    return math.max(1, Util.ScoreMod(self:Score("CHA", true)))
end

function RPSheet:LoyaltyCap()
    return self:Score("CHA", true)
end

-- The gift the character has right now: the family's entry of Rules.COMPANIONS and
-- the companion giving it. Nothing unless a loyal enough companion is out.
function RPSheet:CompanionGift()
    local entry = self:Companion()
    local family = entry and R.COMPANIONS[entry.family]
    if family and entry.loyalty >= R.LOYALTY_GIFT then return family, entry end
end

-- Feet the gift adds to the character's own speed (RPSheet:Speed).
function RPSheet:CompanionSpeed()
    local gift = self:CompanionGift()
    return gift and gift.speed or 0
end

-- 2 when the gift makes the character an expert in that skill, else 0 (RPSheet:SkillMod).
function RPSheet:CompanionSkillRank(name)
    local gift = self:CompanionGift()
    for _, skill in ipairs(gift and gift.skills or NONE) do
        if skill == name then return 2 end
    end
    return 0
end
