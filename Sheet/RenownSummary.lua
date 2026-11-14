-- The words for a faction's renown: the perks of every tier reached (what all factions
-- give, the faction's own, and its side's), then the next tier and the score it needs.
-- Shown as the tooltip of the renown row on the sheet and under the score in the editor.
local _, ns = ...
local R = ns.Rules

-- "ALLIANCE" or "HORDE" for a subfaction of one of the two sides.
local SIDE = {}
for side in pairs(R.SIDE_NAMES) do
    for _, faction in ipairs(R.FACTIONS[side]) do SIDE[faction] = side end
end

-- Everything one tier of a faction gives, as one paragraph.
local function TierText(faction, tier)
    local parts = { R.RENOWN_PERKS[tier] }
    local own = R.FACTION_PERKS[faction] and R.FACTION_PERKS[faction][tier]
    if own then parts[#parts + 1] = own.text end
    local side = SIDE[faction]
    if side and R.SIDE_PERKS[tier] then parts[#parts + 1] = R.SIDE_PERKS[tier]:format(R.SIDE_NAMES[side]) end
    return table.concat(parts, " ")
end

-- The side whose ambassador the character is through this faction, or nil.
local function Ambassador(sheet, faction)
    local side = SIDE[faction]
    local mine = false
    for _, name in ipairs(side and R.AMBASSADOR_FACTIONS[side] or {}) do
        if (tonumber(sheet.renown[name]) or 0) < R.RENOWN_TIERS[1][1] then return end
        mine = mine or name == faction
    end
    return mine and side or nil
end

-- What the trainers taught, or that the choice is still open; nil when there is none.
local function TrainingLine(sheet, faction)
    local options = ns.RenownTrainingOptions(sheet, faction)
    if #options == 0 then return end
    local pick = (sheet.renownTraining or {})[faction]
    for _, name in ipairs(options) do
        if name == pick then return ("Trained by the faction: %s."):format(pick) end
    end
    return "Training not chosen yet: pick it under Customize, Lineage, languages, renown."
end

-- `accent` is the color code the tier names are written in.
function ns.RenownSummary(sheet, faction, accent)
    local score = tonumber(sheet.renown[faction]) or 0
    local lines, upcoming = {}, nil
    for index = #R.RENOWN_TIERS, 1, -1 do
        local need, tier = R.RENOWN_TIERS[index][1], R.RENOWN_TIERS[index][2]
        if score >= need then
            lines[#lines + 1] = ("%s%s|r: %s"):format(accent, tier, TierText(faction, tier))
        elseif not upcoming then
            upcoming = ("%sNext, %s at %d|r: %s"):format(accent, tier, need, TierText(faction, tier))
        end
    end
    local side = Ambassador(sheet, faction)
    if side then lines[#lines + 1] = accent .. R.AMBASSADOR_PERK:format(R.SIDE_NAMES[side]):gsub(":", "|r:", 1) end
    lines[#lines + 1] = TrainingLine(sheet, faction)
    lines[#lines + 1] = upcoming
    return table.concat(lines, "\n\n")
end
