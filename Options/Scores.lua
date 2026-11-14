-- "Ability scores" page under Customize: point buy, standard array or manual, plus the background's points.
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
    local raised = {}
    for _, stat in ipairs(R.STATS) do
        if sheet.asi[stat] > 0 then raised[#raised + 1] = ("%s +%d"):format(ns.Term(stat), sheet.asi[stat]) end
    end
    if #raised > 0 then
        lines[#lines + 1] = ("From level-ups: %s. These follow your level choices on the Character tab."):format(table.concat(raised, ", "))
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
    return Opt.Bounded({
        type = "range", order = order, min = 3, max = R.MAX_SCORE, step = 1, name = R.STAT_NAMES[stat],
        desc = ns.Glossary[stat],
        hidden = function() return Sheet().scoreMethod == "ARRAY" end,
        get = function() return Sheet().base[stat] end,
        set = function(_, value)
            Sheet().base[stat] = value
            Opt.Changed()
        end,
    }, function()
        -- Point buy: 8 up to what the remaining points can pay for.
        if Sheet().scoreMethod == "POINTBUY" then return R.BASE_MIN, Opt.PointBuyMax(Sheet().base, stat) end
        return 3, R.MAX_SCORE
    end)
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

local function BackgroundSlider(stat, order)
    return Opt.Bounded({
        type = "range", order = order, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " (background)",
        desc = "Points from your background: +2 and +1, or +1 on three abilities.",
        get = function() return Sheet().bonus[stat] end,
        set = function(_, value)
            Sheet().bonus[stat] = value
            Opt.Changed()
        end,
    }, function()
        -- Only the abilities the background names, and only the points that are left.
        if not Opt.BackgroundAllows(Sheet().background, stat) then return 0, 0 end
        return 0, Opt.BonusMax(Sheet().bonus, stat)
    end)
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
    args["break" .. stat] = { type = "description", order = i * 10 + 3, name = "" }
end

Opt.custom.scores = { type = "group", order = 3, name = "Ability scores", args = args }
