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
-- <n> is the level for a character of one class. With several classes it is the number
-- of a level of one class (Sheet/ClassSlots.lua): a class gives its improvements at
-- its own levels.
-- Checking a choice is in Sheet/LevelRules.lua, storing it in Sheet/LevelStore.lua.
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
-- feat), or nil for a level without one. It goes by the level of the class.
function Levels.Kind(sheet, slot)
    local key, level = ns.SlotClass(sheet, slot)
    if level == R.EPIC_BOON_LEVEL then return "BOON" end
    local class = R.CLASSES[key]
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
        if ns.HasSlot(sheet, level) then
            for _, stat in ipairs(R.STATS) do
                sheet.asi[stat] = sheet.asi[stat] + (record.asi[stat] or 0)
            end
        end
    end
end

Levels.Sum = Sum -- for the other level files
