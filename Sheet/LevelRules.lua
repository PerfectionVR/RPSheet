-- Level choices: whether a choice is allowed (a feat's prerequisites, the points, the
-- highest score), and which levels still wait for one.
local _, ns = ...
local R = ns.Rules
local Levels = ns.Levels
local Sum = Levels.Sum
local NO_RECORDS = {}

-- An ability score as it stands without the points of `level`'s own choice.
local function ScoreBefore(sheet, level, stat)
    local previous = Levels.Record(sheet, level)
    local counted = previous and ns.HasSlot(sheet, level) and previous.asi[stat] or 0
    return (sheet.base[stat] or 0) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0) - counted
end

-- Why the character can't take a listed feat at `level`, or nil if it can: it has
-- the feat already, or misses a prerequisite. A feat typed by hand is only checked
-- for being a duplicate.
function Levels.FeatBlock(sheet, level, name)
    local feat = R.FEATS[name]
    if not (feat and feat.repeatable) and Levels.HasFeat(sheet, name, level) then
        return "you already have it"
    end
    if not feat then return end
    if feat.needSpecies and sheet.species ~= feat.needSpecies then
        return ("needs to be a %s"):format(R.SPECIES[feat.needSpecies].name)
    end
    if feat.needAllStats then
        local names = {}
        for _, stat in ipairs(feat.needAllStats) do
            if ScoreBefore(sheet, level, stat) < 13 then names[#names + 1] = R.STAT_NAMES[stat] end
        end
        if #names > 0 then return ("needs %s 13 or higher"):format(table.concat(names, " and ")) end
    end
    if feat.needStats then
        local met, names = false, {}
        for _, stat in ipairs(feat.needStats) do
            met = met or ScoreBefore(sheet, level, stat) >= 13
            names[#names + 1] = R.STAT_NAMES[stat]
        end
        if not met then return ("needs %s 13 or higher"):format(table.concat(names, " or ")) end
    end
    if feat.needTraining and not ns.SheetArmorTraining(sheet)[feat.needTraining] then
        return feat.needTraining == "shield" and "needs shield training" or ("needs %s armor training"):format(feat.needTraining)
    end
    if feat.needCaster and not ns.CasterView(sheet) then
        return "needs a spellcasting class"
    end
end

-- The points Epic Boons (at other levels than `level`) added to an ability score.
function Levels.BoonPoints(sheet, stat, level)
    local points = 0
    for slot, record in pairs(sheet.levels or NO_RECORDS) do
        if slot ~= level and ns.HasSlot(sheet, slot) and Levels.Kind(sheet, slot) == "BOON" then
            points = points + (record.asi[stat] or 0)
        end
    end
    return points
end

-- Why `record` can't be accepted for `level`, or nil when it is complete and allowed.
function Levels.Problem(sheet, level, record)
    local kind = Levels.Kind(sheet, level)
    if not kind then return end
    local points = Sum(record.asi)
    if record.choice == "ASI" then
        if points ~= R.ASI_POINTS then
            return ("Place %d ability score points: +2 to one ability or +1 to two."):format(R.ASI_POINTS)
        end
    else
        if record.feat == "" then return kind == "BOON" and "Name the Epic Boon you take." or "Name the feat you take." end
        if points > 1 then return "A feat raises one ability by 1 at most." end
        local block = Levels.FeatBlock(sheet, level, record.feat)
        if block then return ("You can't take %s: %s."):format(record.feat, block) end
        local known = R.FEATS[record.feat]
        if known and known.save then
            -- Resilient: the raised ability must be one you aren't yet proficient in.
            local raised
            for _, stat in ipairs(R.STATS) do
                if (record.asi[stat] or 0) > 0 then raised = stat end
            end
            local previous = Levels.Record(sheet, level)
            if not raised then return "Choose the ability this feat raises: you gain its saving throw proficiency." end
            if sheet.saves[raised] and not (previous and previous.gaveSave == raised) then
                return ("You are already proficient in %s saving throws. Pick another ability."):format(R.STAT_NAMES[raised])
            end
        end
    end
    -- Scores stop at 20; an Epic Boon can take one to 30. What a boon added on top
    -- doesn't count against an earlier level's points.
    local cap = kind == "BOON" and R.BOON_MAX_SCORE or R.MAX_SCORE
    local previous = Levels.Record(sheet, level)
    local counted = previous and ns.HasSlot(sheet, level)
    for _, stat in ipairs(R.STATS) do
        local add = record.asi[stat] or 0
        if add > 0 then
            local without = (sheet.base[stat] or 0) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
                - (counted and previous.asi[stat] or 0) - (kind == "BOON" and 0 or Levels.BoonPoints(sheet, stat, level))
            if without + add > cap then
                return ("%s can't go above %d this way."):format(R.STAT_NAMES[stat], cap)
            end
        end
    end
end

-- Levels the character has reached whose choice is still open, lowest first.
function Levels.Pending(sheet)
    local pending = {}
    for _, level in ipairs(ns.LevelSlots(sheet)) do
        if Levels.Kind(sheet, level) then
            local record = Levels.Record(sheet, level)
            if not record or Levels.Problem(sheet, level, record) then pending[#pending + 1] = level end
        end
    end
    return pending
end
