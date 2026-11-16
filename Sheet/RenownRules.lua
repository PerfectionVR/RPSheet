-- A faction's renown score as it counts: the score the player keeps (sheet.renown),
-- plus what the rules add by themselves (data in Data/RenownRules.lua):
--   * 1 while the character's stronghold stands in the faction's lands
--     (sheet.stronghold = that faction's name),
--   * for the faction the species starts with: 1, 2, 3 and 5 for every other faction of
--     the same side that has reached Friendly, Honored, Revered and Exalted.
-- That gain comes the first time a tier is reached and stays when the other faction's
-- score drops again, so the sheet records the highest tier each faction has reached
-- (sheet.renownReached, kept up by ns.NoteRenownReached).
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

-- The lowest score of the highest tier `score` reaches: 10 for 12, 0 below Friendly.
local function TierFloor(score)
    for _, tier in ipairs(R.RENOWN_TIERS) do
        if score >= tier[1] then return tier[1] end
    end
    return 0
end

-- The lowest score of the highest tier the faction has ever reached, as recorded.
function ns.RenownReached(sheet, faction)
    local reached = type(sheet.renownReached) == "table" and tonumber(sheet.renownReached[faction]) or 0
    return TierFloor(reached)
end

-- Records the tiers reached as the scores are now. Called whenever the sheet is
-- brought up to date after a change (ns.ApplyRenownPerks), so nothing is missed. A
-- character from before the record starts with the tiers its scores have now.
function ns.NoteRenownReached(sheet)
    if type(sheet.renownReached) ~= "table" then sheet.renownReached = {} end
    if type(sheet.renown) ~= "table" then return end
    for _, faction in ipairs(R.ALL_FACTIONS) do
        local now = TierFloor(Standing(sheet, faction) or 0)
        if now > ns.RenownReached(sheet, faction) then sheet.renownReached[faction] = now end
    end
end

-- The tier a faction reached earlier and has dropped out of since, by name, where the
-- faction the character started with still has the gain from it; nil otherwise.
function ns.RenownLostTier(sheet, faction)
    if type(sheet.renown) ~= "table" then return end
    -- It only matters for the other factions of the side the character started on.
    local home, side = ns.RenownHome(sheet)
    if not home or faction == home or SIDE[faction] ~= side then return end
    local reached = ns.RenownReached(sheet, faction)
    if reached > TierFloor(Standing(sheet, faction) or 0) then return R.RenownTier(reached) end
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
            -- A tier counts from the first time it was reached, whatever the score is now.
            local now = other ~= faction and Standing(sheet, other) or 0
            local theirs = other ~= faction and math.max(now, ns.RenownReached(sheet, other)) or 0
            local gain = 0
            for _, tier in ipairs(R.RENOWN_TIERS) do
                if theirs >= tier[1] then gain = gain + R.SIDE_RENOWN_GAIN[tier[2]] end
            end
            if gain > 0 then
                local tier = R.RenownTier(theirs)
                added[#added + 1] = { ("%s (%s%s)"):format(other, tier ~= R.RenownTier(now) and "once " or "", tier), gain }
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
