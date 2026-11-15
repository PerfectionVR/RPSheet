-- What a faction's trainers taught the character: one language, tool or skill from the
-- faction's list (the `train` of a perk in Data/FactionPerks.lua), picked under
-- Customize, Lineage, languages, renown.
--   sheet.renownTraining[<faction>] = the pick; kept when renown drops, so it returns
--   sheet.renownGranted[<faction>]  = the language or skill that pick added to the sheet
-- A tool isn't stored: the pick itself is the proficiency (see RPSheet:ToolSource).
local _, ns = ...
local R = ns.Rules

local SKILL = {}
for _, skill in ipairs(R.SKILLS) do SKILL[skill.name] = true end

-- The tier that offers training and the score it needs, or nil for a faction without.
local function TrainingTier(faction)
    local perks = R.FACTION_PERKS[faction]
    for index = #R.RENOWN_TIERS, 1, -1 do
        local need, tier = R.RENOWN_TIERS[index][1], R.RENOWN_TIERS[index][2]
        if perks and perks[tier] and perks[tier].train then return perks[tier].train, need end
    end
end

-- What can be picked for a faction, in the data's order. Empty until the score allows it.
function ns.RenownTrainingOptions(sheet, faction)
    local train, need = TrainingTier(faction)
    local names = {}
    if not train or ns.RenownScore(sheet, faction) < need then return names end
    for _, name in ipairs(train) do names[#names + 1] = name end
    if train.anyLanguage then
        for _, language in ipairs(R.ALL_LANGUAGES) do names[#names + 1] = language end
    end
    return names
end

-- The pick that counts right now: made, still on the list, and the score high enough.
local function Pick(sheet, faction)
    local pick = sheet.renownTraining[faction]
    for _, name in ipairs(ns.RenownTrainingOptions(sheet, faction)) do
        if name == pick then return pick end
    end
end

-- True if a trainer taught the character this tool.
function ns.RenownTool(sheet, name)
    if not R.TOOLS[name] or type(sheet.renownTraining) ~= "table" then return false end
    for _, faction in ipairs(R.ALL_FACTIONS) do
        if Pick(sheet, faction) == name then return true end
    end
    return false
end

-- Languages trainers taught: they come on top of the ones the character may choose.
function ns.RenownLanguageCount(sheet)
    local count = 0
    for _, name in pairs(sheet.renownGranted or {}) do
        if not SKILL[name] then count = count + 1 end
    end
    return count
end

-- Gives back what an earlier pick added, unless the player has since built on it.
local function Withdraw(sheet, faction)
    local granted = sheet.renownGranted[faction]
    if not granted then return end
    if SKILL[granted] then
        if sheet.skills[granted] == 1 then sheet.skills[granted] = nil end
    else
        sheet.languages[granted] = nil
    end
    sheet.renownGranted[faction] = nil
end

-- Sheet upkeep, called from ns.ApplyRenownPerks.
function ns.ApplyRenownTraining(sheet)
    for _, key in ipairs({ "renownTraining", "renownGranted", "languages", "skills" }) do
        if type(sheet[key]) ~= "table" then sheet[key] = {} end
    end
    for _, faction in ipairs(R.ALL_FACTIONS) do
        local pick = Pick(sheet, faction)
        if sheet.renownGranted[faction] ~= pick then Withdraw(sheet, faction) end
        -- Something the character already has is left alone, and not taken back later.
        if pick and not sheet.renownGranted[faction] and not R.TOOLS[pick] then
            if SKILL[pick] and (sheet.skills[pick] or 0) == 0 then
                sheet.skills[pick], sheet.renownGranted[faction] = 1, pick
            elseif not SKILL[pick] and not sheet.languages[pick] then
                sheet.languages[pick], sheet.renownGranted[faction] = true, pick
            end
        end
    end
end
