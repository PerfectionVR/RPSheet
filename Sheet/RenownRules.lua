-- A faction's renown score as it counts: the score the player keeps (sheet.renown),
-- plus what the rules add by themselves (data in Data/RenownRules.lua):
--   * 1 while the character's stronghold stands in the faction's lands
--     (sheet.stronghold = that faction's name),
--   * for the faction the species starts with: 1, 2, 3 and 5 for every other faction of
--     the same side that is Friendly, Honored, Revered and Exalted.
-- The rule speaks of the first time a tier is reached; the sheet keeps no history, so
-- it goes by the scores as they are now.
local _, ns = ...
local R = ns.Rules

local SIDE = {}
for _, side in ipairs({ "ALLIANCE", "HORDE" }) do
    for _, faction in ipairs(R.FACTIONS[side]) do SIDE[faction] = side end
end

-- The faction the character's species or lineage starts with, and its side; nil when
-- there is none or it isn't a faction of the Alliance or the Horde.
function ns.RenownHome(sheet)
    local home = R.SPECIES_RENOWN[sheet.species]
    if type(home) == "table" then home = home[sheet.allegiance] end
    local _, lineage = R.Lineage(sheet.species, sheet.lineage)
    home = lineage and lineage.renown or home
    if home and SIDE[home] then return home, SIDE[home] end
end

-- The player's own score with what a stronghold adds. Nil for a faction not on the sheet.
local function Standing(sheet, faction)
    local own = tonumber(sheet.renown[faction])
    if not own then return end
    local stronghold = (sheet.stronghold == faction and R.STRONGHOLD_LANDS[faction]) and R.STRONGHOLD_RENOWN or 0
    return own + stronghold, own, stronghold
end

-- The score that counts, and what the rules added to it as a list of { label, points }
-- (empty when it is all the player's own). 0 for a faction the sheet doesn't list.
function ns.RenownScore(sheet, faction)
    local added = {}
    if type(sheet.renown) ~= "table" then return 0, added end
    local score, _, stronghold = Standing(sheet, faction)
    if not score then return 0, added end
    if stronghold > 0 then added[#added + 1] = { "your stronghold in its lands", stronghold } end
    local home, side = ns.RenownHome(sheet)
    if home == faction then
        for _, other in ipairs(R.FACTIONS[side]) do
            local theirs = other ~= faction and Standing(sheet, other) or 0
            local gain = 0
            for _, tier in ipairs(R.RENOWN_TIERS) do
                if theirs >= tier[1] then gain = gain + R.SIDE_RENOWN_GAIN[tier[2]] end
            end
            if gain > 0 then
                added[#added + 1] = { ("%s (%s)"):format(other, R.RenownTier(theirs)), gain }
                score = score + gain
            end
        end
    end
    return score, added
end

-- "Counts as 9: 3 of your own, +1 your stronghold in its lands, +3 Ironforge (Honored)."
-- Nil when nothing was added.
function ns.RenownRuleLine(sheet, faction)
    local score, added = ns.RenownScore(sheet, faction)
    if #added == 0 then return end
    local parts = { ("%d of your own"):format(tonumber(sheet.renown[faction]) or 0) }
    for _, part in ipairs(added) do parts[#parts + 1] = ("+%d %s"):format(part[2], part[1]) end
    return ("Counts as %d: %s."):format(score, table.concat(parts, ", "))
end

-- The rival of `faction` the character also has renown with, or nil. With no faction
-- given: the first pair the character has renown with both of, as two names.
function ns.RenownRival(sheet, faction)
    if type(sheet.renown) ~= "table" then return end
    for _, pair in ipairs(R.RIVAL_FACTIONS) do
        local first, second = (tonumber(sheet.renown[pair[1]]) or 0) > 0, (tonumber(sheet.renown[pair[2]]) or 0) > 0
        if first and second then
            if not faction then return pair[1], pair[2] end
            if faction == pair[1] then return pair[2] end
            if faction == pair[2] then return pair[1] end
        end
    end
end
