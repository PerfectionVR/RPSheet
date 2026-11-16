-- Lessons of the First Ones: each time the invocation is taken it gives an origin feat
-- of the player's choice, kept in sheet.featureOptions[<the pick's name>] and chosen
-- under Customize, Metamagic, invocations, maneuvers (Options/ClassPicks.lua). The
-- feat is a passive marked auto = "lessons:<the pick's name>", so the feat's own
-- choices are asked for like any other feat's (Sheet/FeatChoices.lua).
local _, ns = ...
local R = ns.Rules

local PREFIX = "lessons:"
local NONE = {}

-- The Lessons of the First Ones picks the character has, in order.
function ns.LessonPicks(sheet)
    local picks = type(sheet.picks) == "table" and sheet.picks.invocations
    local names = {}
    if type(picks) ~= "table" or ns.SheetPickLimit(sheet, "invocations") <= 0 then return names end
    for name, on in pairs(picks) do
        if on and name:find("^Lessons of the First Ones") then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

-- The origin feats a pick can be: not one the character has from elsewhere (unless it
-- may be taken again), and the pick's own always. `free` lists every one.
function ns.LessonOptions(sheet, pick, free)
    local own, names = PREFIX .. pick, {}
    for _, name in ipairs(R.FEAT_NAMES.GENERAL) do
        local feat = R.FEATS[name]
        if feat.kind == "ORIGIN" then
            local taken = false
            for _, passive in ipairs(sheet.passives or NONE) do
                taken = taken or (passive.name == name and passive.auto ~= own)
            end
            local allowed = not feat.needSpecies or feat.needSpecies == sheet.species
            if free or (sheet.featureOptions or NONE)[pick] == name or (allowed and (feat.repeatable or not taken)) then
                names[#names + 1] = name
            end
        end
    end
    return names
end

-- The picks whose feat isn't chosen yet.
function ns.OpenLessons(sheet)
    local open = {}
    for _, pick in ipairs(ns.LessonPicks(sheet)) do
        if not R.FEATS[(sheet.featureOptions or NONE)[pick] or ""] then open[#open + 1] = pick end
    end
    return open
end

-- Sheet upkeep, after the picks and before the feats' choices.
function ns.ApplyLessonFeats(sheet)
    local wanted = {}
    for _, pick in ipairs(ns.LessonPicks(sheet)) do
        local feat = R.FEATS[(sheet.featureOptions or NONE)[pick] or ""]
        if feat and feat.kind == "ORIGIN" then wanted[PREFIX .. pick] = feat end
    end
    for index = #sheet.passives, 1, -1 do
        local auto = sheet.passives[index].auto or ""
        if auto:find("^" .. PREFIX) and not wanted[auto] then table.remove(sheet.passives, index) end
    end
    for key, feat in pairs(wanted) do
        local passive
        for _, each in ipairs(sheet.passives) do
            if each.auto == key then passive = each end
        end
        if not passive then
            passive = { auto = key, enabled = true }
            sheet.passives[#sheet.passives + 1] = passive
        end
        if passive.name ~= feat.name then passive.effects = CopyTable(feat.effects or NONE) end
        passive.name = feat.name
        passive.desc = ("Origin feat from Lessons of the First Ones. %s"):format(feat.desc)
    end
end
