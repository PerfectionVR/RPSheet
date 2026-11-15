-- Wizard step 3: the ability scores (point buy, the standard array or by hand) and the
-- background's points.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local Util = ns.Util
local W = ns.Wizard
local GOLD, RED = Opt.GOLD, Opt.RED
local Page = W.Page

local function ScoreSummary()
    local draft, lines = W.draft, {}
    if draft.scoreMethod == "POINTBUY" then
        lines[#lines + 1] = ("Points spent: %s%d / %d|r. Scores of 14 and 15 cost 2 points per step."):format(GOLD, W.PointsSpent(), R.POINTS)
    elseif draft.scoreMethod == "ARRAY" then
        lines[#lines + 1] = "Assign 15, 14, 13, 12, 10 and 8. Picking a value swaps it with the ability that had it."
    else
        lines[#lines + 1] = "Enter the scores you rolled or agreed with your DM."
    end
    local background = R.BACKGROUNDS[draft.background]
    lines[#lines + 1] = ("Background points placed: %s%d / %d|r%s"):format(
        GOLD, W.BonusSpent(), R.BONUS_TOTAL,
        background and (" on " .. ns.Terms(background.stats) .. " (+2 and +1, or +1 each).") or ".")
    local totals = {}
    for _, stat in ipairs(R.STATS) do
        local score = draft.base[stat] + draft.bonus[stat]
        totals[#totals + 1] = ("%s %d (%s)"):format(ns.Term(stat), score, Util.Signed(Util.ScoreMod(score)))
    end
    lines[#lines + 1] = table.concat(totals, "    ")
    return table.concat(lines, "\n") .. "\n"
end

local scoreArgs = {
    method = {
        type = "select", order = 1, name = "Method", width = "double",
        values = R.SCORE_METHODS, sorting = R.SCORE_METHOD_ORDER,
        get = function() return W.draft.scoreMethod end,
        set = function(_, value)
            W.draft.scoreMethod = value
            for i, stat in ipairs(R.STATS) do
                W.draft.base[stat] = value == "ARRAY" and R.STANDARD_ARRAY[i] or R.BASE_MIN
            end
        end,
    },
    summary = { type = "description", order = 2, fontSize = "medium", name = ScoreSummary, dialogControl = "RPSheetTermLabel" },
}
for i, stat in ipairs(R.STATS) do
    scoreArgs["score" .. stat] = Opt.Bounded({
        type = "range", order = i * 10, step = 1, name = R.STAT_NAMES[stat], min = 3, max = R.MAX_SCORE,
        desc = ns.Glossary[stat],
        hidden = function() return not W.draft or W.draft.scoreMethod == "ARRAY" end,
        get = function() return W.draft and W.draft.base[stat] end,
        set = function(_, value) W.draft.base[stat] = value end,
    }, function()
        if not W.draft then return 3, R.MAX_SCORE end
        -- Point buy: 8 up to what the remaining points can pay for.
        if W.draft.scoreMethod == "POINTBUY" then return R.BASE_MIN, Opt.PointBuyMax(W.draft.base, stat) end
        -- With the background's points on top a score stops at the highest allowed.
        return 3, R.MAX_SCORE - (W.draft.bonus[stat] or 0)
    end)
    scoreArgs["array" .. stat] = {
        type = "select", order = i * 10, name = R.STAT_NAMES[stat], desc = ns.Glossary[stat],
        values = Opt.ARRAY_VALUES, sorting = Opt.ARRAY_ORDER,
        hidden = function() return W.draft.scoreMethod ~= "ARRAY" end,
        get = function() return W.draft.base[stat] end,
        set = function(_, value)
            local base = W.draft.base
            for _, other in ipairs(R.STATS) do
                if base[other] == value then base[other] = base[stat] end
            end
            base[stat] = value
        end,
    }
    scoreArgs["bonus" .. stat] = Opt.Bounded({
        type = "range", order = i * 10 + 1, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " (background)",
        hidden = function() return not W.draft end,
        get = function() return W.draft and W.draft.bonus[stat] end,
        set = function(_, value) W.draft.bonus[stat] = value end,
    }, function()
        if not W.draft then return 0, R.BONUS_MAX end
        -- Only the abilities the background names, and only the points that are left.
        if not Opt.BackgroundAllows(W.draft.background, stat) then return 0, 0 end
        -- ...and no further than the highest score allowed (a score set by hand can be 20).
        return 0, math.max(0, math.min(Opt.BonusMax(W.draft.bonus, stat), R.MAX_SCORE - (W.draft.base[stat] or 0)))
    end)
    scoreArgs["break" .. stat] = { type = "description", order = i * 10 + 2, name = "" }
end
local scorePage = Page(3, scoreArgs)

W.pages[3] = scorePage
