-- Level choices from elsewhere: an old sheet that only kept totals, and the records of
-- an import string.
local _, ns = ...
local R = ns.Rules
local Levels = ns.Levels
local Sum = Levels.Sum

-- A sheet from before choices were kept per level only has the totals. They are
-- spread over the improvement levels it has reached, lowest first.
function Levels.Migrate(sheet)
    if type(sheet.levels) == "table" then return end
    sheet.levels = {}
    local left, last = {}, nil
    for _, stat in ipairs(R.STATS) do left[stat] = sheet.asi[stat] or 0 end
    -- (the levels the character has, class by class: Sheet/ClassSlots.lua)
    for _, level in ipairs(ns.LevelSlots(sheet)) do
        if Levels.Kind(sheet, level) == "ASI" and Sum(left) > 0 then
            local record, room = Levels.NewRecord("ASI"), R.ASI_POINTS
            for _, stat in ipairs(R.STATS) do
                local take = math.min(room, left[stat])
                if take > 0 then
                    record.asi[stat], left[stat], room = take, left[stat] - take, room - take
                end
            end
            sheet.levels[level], last = record, record
        end
    end
    -- More points than the levels allow (a DM's gift, perhaps) stay with the last one.
    if Sum(left) > 0 then
        if not last then
            last = Levels.NewRecord("ASI")
            sheet.levels[1] = last
        end
        for _, stat in ipairs(R.STATS) do
            if left[stat] > 0 then last.asi[stat] = (last.asi[stat] or 0) + left[stat] end
        end
    end
end

-- A safe copy of level records that came from outside (an import string), or nil.
function Levels.Clean(source)
    if type(source) ~= "table" then return end
    local clean = {}
    for _, level in ipairs(ns.AllLevelSlots()) do
        local record = source[level]
        if type(record) == "table" then
            local copy = Levels.NewRecord("ASI")
            copy.choice = record.choice == "FEAT" and "FEAT" or "ASI"
            for _, key in ipairs({ "feat", "featDesc" }) do
                if type(record[key]) == "string" then
                    copy[key] = record[key]:gsub("[|%c]", ""):sub(1, key == "feat" and 60 or 400)
                end
            end
            if R.STAT_NAMES[record.gaveSave] then copy.gaveSave = record.gaveSave end
            if type(record.asi) == "table" then
                for _, stat in ipairs(R.STATS) do
                    local points = math.floor(tonumber(record.asi[stat]) or 0)
                    if points > 0 then copy.asi[stat] = math.min(12, points) end
                end
            end
            clean[level] = copy
        end
    end
    return clean
end
