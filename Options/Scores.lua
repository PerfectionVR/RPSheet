-- "Ability scores" tab: point buy, standard array or manual, plus the background's points.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Util = ns.Util
local Sheet = Opt.Sheet

local function SetMethod(_, value)
    local sheet = Sheet()
    sheet.scoreMethod = value
    if value == "ARRAY" then
        for i, stat in ipairs(R.STATS) do sheet.base[stat] = R.STANDARD_ARRAY[i] end
    elseif value == "POINTBUY" then
        for _, stat in ipairs(R.STATS) do sheet.base[stat] = R.BASE_MIN end
    end
    Opt.Changed()
end

local function Summary()
    local sheet, lines = Sheet(), {}
    if sheet.scoreMethod == "POINTBUY" then
        lines[#lines + 1] = ("Points spent: %s%d / %d|r. Scores of 14 and 15 cost 2 points per step."):format(
            Opt.GOLD, RPSheet:PointsSpent(), R.POINTS)
    elseif sheet.scoreMethod == "ARRAY" then
        lines[#lines + 1] = "Assign 15, 14, 13, 12, 10 and 8. Picking a value swaps it with the ability that had it."
    else
        lines[#lines + 1] = "Enter the scores you rolled or agreed with your DM."
    end
    local background = R.BACKGROUNDS[sheet.background]
    lines[#lines + 1] = ("Background points placed: %s%d / %d|r%s"):format(
        Opt.GOLD, RPSheet:BonusSpent(), R.BONUS_TOTAL,
        background and (" on " .. ns.Terms(background.stats) .. " (+2 and +1, or +1 each).") or ".")
    local points = RPSheet:ImprovementPoints()
    if points > 0 then
        lines[#lines + 1] = ("Level-up points placed: %s%d / %d|r. Each Ability Score Improvement gives 2 points; a feat taken instead uses up 2 (or 1 if the feat itself raises an ability)."):format(
            Opt.GOLD, RPSheet:ImprovementSpent(), points)
    end
    local totals = {}
    for _, stat in ipairs(R.STATS) do
        totals[#totals + 1] = ("%s %d (%s)"):format(ns.Term(stat), RPSheet:Score(stat), Util.Signed(RPSheet:Mod(stat)))
    end
    lines[#lines + 1] = table.concat(totals, "    ")
    return table.concat(lines, "\n") .. "\n"
end

-- Slider for point buy and manual scores.
local function ScoreSlider(stat, order)
    return {
        type = "range", order = order, min = 3, max = R.MAX_SCORE, step = 1, name = R.STAT_NAMES[stat],
        desc = ns.Glossary[stat],
        hidden = function() return Sheet().scoreMethod == "ARRAY" end,
        get = function() return Sheet().base[stat] end,
        set = function(_, value)
            local sheet = Sheet()
            local old = sheet.base[stat]
            if sheet.scoreMethod == "POINTBUY" then
                value = math.max(R.BASE_MIN, math.min(R.BASE_MAX, value))
            end
            sheet.base[stat] = value
            if sheet.scoreMethod == "POINTBUY" and RPSheet:PointsSpent() > R.POINTS then
                sheet.base[stat] = old
                RPSheet:Print(("Not enough points for %s %d."):format(R.STAT_NAMES[stat], value))
                return
            end
            Opt.Changed()
        end,
    }
end

-- Dropdown for the standard array: picking a value swaps it with the ability that had it.
local function ArrayPicker(stat, order)
    return {
        type = "select", order = order, name = R.STAT_NAMES[stat], desc = ns.Glossary[stat],
        values = Opt.ARRAY_VALUES, sorting = Opt.ARRAY_ORDER,
        hidden = function() return Sheet().scoreMethod ~= "ARRAY" end,
        get = function() return Sheet().base[stat] end,
        set = function(_, value)
            local base = Sheet().base
            for _, other in ipairs(R.STATS) do
                if base[other] == value then base[other] = base[stat] end
            end
            base[stat] = value
            Opt.Changed()
        end,
    }
end

-- Points from Ability Score Improvements gained by levelling. Shown once there are any.
local function ImprovementSlider(stat, order)
    return {
        type = "range", order = order, min = 0, max = 12, softMax = 6, step = 1,
        name = R.STAT_NAMES[stat] .. " (level-ups)",
        desc = "Points from Ability Score Improvements: 2 per improvement, +2 to one ability or +1 to two. A score can't go above 20 this way.",
        hidden = function() return RPSheet:ImprovementPoints() == 0 and Sheet().asi[stat] == 0 end,
        get = function() return Sheet().asi[stat] end,
        set = function(_, value)
            local asi = Sheet().asi
            local old = asi[stat]
            asi[stat] = value
            local problem
            if RPSheet:ImprovementSpent() > RPSheet:ImprovementPoints() then
                problem = ("Only %d level-up points to place."):format(RPSheet:ImprovementPoints())
            elseif value > old and RPSheet:Score(stat) > R.MAX_SCORE then
                problem = ("%s can't go above %d this way."):format(R.STAT_NAMES[stat], R.MAX_SCORE)
            end
            if problem then
                asi[stat] = old
                RPSheet:Print(problem)
                return
            end
            Opt.Changed()
        end,
    }
end

local function BackgroundSlider(stat, order)
    return {
        type = "range", order = order, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " (background)",
        desc = "Points from your background: +2 and +1, or +1 on three abilities.",
        disabled = function()
            return not Opt.BackgroundAllows(Sheet().background, stat) and Sheet().bonus[stat] == 0
        end,
        get = function() return Sheet().bonus[stat] end,
        set = function(_, value)
            local bonus = Sheet().bonus
            local old = bonus[stat]
            bonus[stat] = value
            if RPSheet:BonusSpent() > R.BONUS_TOTAL then
                bonus[stat] = old
                RPSheet:Print(("Only %d background points in total."):format(R.BONUS_TOTAL))
                return
            end
            Opt.Changed()
        end,
    }
end

local args = {
    method = {
        type = "select", order = 1, name = "Method", width = "double",
        values = R.SCORE_METHODS, sorting = R.SCORE_METHOD_ORDER,
        get = function() return Sheet().scoreMethod end,
        set = SetMethod,
    },
    summary = { type = "description", order = 2, fontSize = "medium", name = Summary, dialogControl = "RPSheetTermLabel" },
}
for i, stat in ipairs(R.STATS) do
    args["score" .. stat] = ScoreSlider(stat, i * 10)
    args["array" .. stat] = ArrayPicker(stat, i * 10)
    args["bonus" .. stat] = BackgroundSlider(stat, i * 10 + 1)
    args["asi" .. stat] = ImprovementSlider(stat, i * 10 + 2)
    args["break" .. stat] = { type = "description", order = i * 10 + 3, name = "" }
end

Opt.tabs.scores = { type = "group", order = 3, name = "Ability scores", args = args }
