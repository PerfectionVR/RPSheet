-- What the player chose at each level, kept per level so that going down a level
-- undoes exactly that level's choices.
--
-- sheet.levels[level] = {
--     choice   = "ASI" (raise ability scores) or "FEAT"
--     asi      = { STR = 2 } or { STR = 1, DEX = 1 }; with a feat, at most one +1
--     feat     = name of the feat, for "FEAT"
--     featDesc = what the feat does
--     gaveSave = ability whose saving throw proficiency the feat granted, if any
-- }
-- sheet.asi (the total from level-ups, used for the scores) is worked out from these.
-- A feat chosen here is a passive marked auto = "level:<n>".
local _, ns = ...
local R = ns.Rules

local Levels = {}
ns.Levels = Levels

Levels.CHOICES = { ASI = "Ability Score Improvement", FEAT = "Feat" }
Levels.CHOICE_ORDER = { "ASI", "FEAT" }

local NO_RECORDS = {}

local function Sum(asi)
    local total = 0
    for _, stat in ipairs(R.STATS) do total = total + (asi[stat] or 0) end
    return total
end

function Levels.NewRecord(kind)
    return { choice = kind == "BOON" and "FEAT" or "ASI", asi = {}, feat = "", featDesc = "" }
end

-- The choice a level asks for: "ASI" (an improvement or a feat), "BOON" (an Epic Boon
-- feat), or nil for a level without one.
function Levels.Kind(sheet, level)
    if level == R.EPIC_BOON_LEVEL then return "BOON" end
    local class = R.CLASSES[sheet.class]
    for _, list in ipairs({ R.ASI_LEVELS, class and class.asiLevels or {} }) do
        for _, improvement in ipairs(list) do
            if improvement == level then return "ASI" end
        end
    end
end

function Levels.Record(sheet, level)
    return (sheet.levels or NO_RECORDS)[level]
end

-- True if the character has the feat from somewhere other than `level`: its
-- background, or another level.
function Levels.HasFeat(sheet, name, level)
    local own = "level:" .. level
    for _, passive in ipairs(sheet.passives) do
        if passive.name == name and passive.auto ~= own then return true end
    end
    return false
end

-- An ability score as it stands without the points of `level`'s own choice.
local function ScoreBefore(sheet, level, stat)
    local previous = Levels.Record(sheet, level)
    local counted = previous and level <= sheet.level and previous.asi[stat] or 0
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
    if feat.needTraining and not ns.ArmorTraining(sheet.class, sheet.passives)[feat.needTraining] then
        return feat.needTraining == "shield" and "needs shield training" or ("needs %s armor training"):format(feat.needTraining)
    end
    if feat.needCaster and not (R.CLASSES[sheet.class] and R.CLASSES[sheet.class].caster) then
        return "needs a spellcasting class"
    end
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
    -- Scores stop at 20; an Epic Boon can take one to 30.
    local cap = kind == "BOON" and R.BOON_MAX_SCORE or R.MAX_SCORE
    local previous = Levels.Record(sheet, level)
    local counted = previous and level <= sheet.level
    for _, stat in ipairs(R.STATS) do
        local add = record.asi[stat] or 0
        if add > 0 then
            local without = (sheet.base[stat] or 0) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
                - (counted and previous.asi[stat] or 0)
            if without + add > cap then
                return ("%s can't go above %d this way."):format(R.STAT_NAMES[stat], cap)
            end
        end
    end
end

-- Levels the character has reached whose choice is still open, lowest first.
function Levels.Pending(sheet)
    local pending = {}
    for level = 1, sheet.level do
        if Levels.Kind(sheet, level) then
            local record = Levels.Record(sheet, level)
            if not record or Levels.Problem(sheet, level, record) then pending[#pending + 1] = level end
        end
    end
    return pending
end

-- e.g. "Strength +2", "Feat: Tough" or "Feat: Resilient (Constitution +1)".
function Levels.Describe(record)
    local raised = {}
    for _, stat in ipairs(R.STATS) do
        if (record.asi[stat] or 0) > 0 then
            raised[#raised + 1] = ("%s +%d"):format(R.STAT_NAMES[stat], record.asi[stat])
        end
    end
    if record.choice ~= "FEAT" then return table.concat(raised, ", ") end
    local text = "Feat: " .. record.feat
    if #raised > 0 then text = text .. " (" .. table.concat(raised, ", ") .. ")" end
    return text
end

-- Works out the total points from level-ups from the levels the character has.
function Levels.Recompute(sheet)
    for _, stat in ipairs(R.STATS) do sheet.asi[stat] = 0 end
    for level, record in pairs(sheet.levels or NO_RECORDS) do
        if level <= sheet.level then
            for _, stat in ipairs(R.STATS) do
                sheet.asi[stat] = sheet.asi[stat] + (record.asi[stat] or 0)
            end
        end
    end
end

local function FeatPassive(sheet, level)
    local key = "level:" .. level
    for index, passive in ipairs(sheet.passives) do
        if passive.auto == key then return passive, index end
    end
end

-- Stores the choice for a level and puts its feat, if any, on the sheet.
-- A saving throw proficiency a level's feat granted is given up with that feat.
local function TakeBackSave(sheet, level)
    local old = sheet.levels[level]
    if old and old.gaveSave then sheet.saves[old.gaveSave] = nil end
end

function Levels.Set(sheet, level, record)
    TakeBackSave(sheet, level)
    local stored = CopyTable(record)
    stored.gaveSave = nil
    sheet.levels[level] = stored

    local passive, index = FeatPassive(sheet, level)
    if record.choice == "FEAT" and record.feat ~= "" then
        local known = R.FEATS[record.feat] -- a listed feat brings its own effects
        local changed = not passive or passive.name ~= record.feat
        if not passive then
            passive = { auto = "level:" .. level, enabled = true, effects = {} }
            sheet.passives[#sheet.passives + 1] = passive
        end
        passive.name = record.feat
        passive.desc = record.featDesc ~= "" and record.featDesc or ("Feat taken at level %d."):format(level)
        -- Effects are set when the feat is picked; after that they are the player's to edit.
        if changed then passive.effects = CopyTable(known and known.effects or {}) end
        if known and known.save then
            for _, stat in ipairs(R.STATS) do
                if (record.asi[stat] or 0) > 0 and not sheet.saves[stat] then
                    sheet.saves[stat], stored.gaveSave = true, stat
                end
            end
        end
    elseif passive then
        table.remove(sheet.passives, index)
    end
    Levels.Recompute(sheet)
end

-- Forgets the choices of levels the character no longer has, and their feats.
function Levels.Trim(sheet)
    for level in pairs(sheet.levels) do
        if level > sheet.level then
            local _, index = FeatPassive(sheet, level)
            if index then table.remove(sheet.passives, index) end
            TakeBackSave(sheet, level)
            sheet.levels[level] = nil
        end
    end
    Levels.Recompute(sheet)
end

-- A sheet from before choices were kept per level only has the totals. They are
-- spread over the improvement levels it has reached, lowest first.
function Levels.Migrate(sheet)
    if type(sheet.levels) == "table" then return end
    sheet.levels = {}
    local left, last = {}, nil
    for _, stat in ipairs(R.STATS) do left[stat] = sheet.asi[stat] or 0 end
    for level = 1, sheet.level do
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
    for level = 1, R.MAX_LEVEL do
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
