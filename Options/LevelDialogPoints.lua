-- The level dialog: the Ability Score Improvement's sliders.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Levels = ns.Levels
local L = ns.LevelDialog
local args = L.args

-- Two points to place: a slider per ability.
for index, stat in ipairs(R.STATS) do
    args["asi" .. stat] = Opt.Bounded({
        type = "range", order = 30 + index, min = 0, max = R.ASI_POINTS, step = 1,
        name = function()
            return ("%s (%d)"):format(R.STAT_NAMES[stat], (RPSheet:NaturalScore(stat, true))) -- your own, also in a beast form
        end,
        desc = ns.Glossary[stat],
        hidden = function() return not L.IsImprovement() end,
        get = function() return L.draft and L.draft.record.asi[stat] or 0 end,
        set = function(_, value) L.draft.record.asi[stat] = value > 0 and value or nil end,
    }, function()
        if not L.draft then return 0, R.ASI_POINTS end
        -- The points still to place, and no further than the highest score allowed.
        local sheet, mine, placed = L.Sheet(), L.draft.record.asi[stat] or 0, 0
        for _, other in ipairs(R.STATS) do placed = placed + (L.draft.record.asi[other] or 0) end
        local saved = Levels.Record(sheet, L.draft.level)
        local counted = saved and ns.HasSlot(sheet, L.draft.level) and saved.asi[stat] or 0
        local room = R.MAX_SCORE - (RPSheet:NaturalScore(stat, true) - counted) -- your own score: an item that sets it higher leaves the room as it is
        return 0, math.max(0, math.min(R.ASI_POINTS, mine + R.ASI_POINTS - placed, room))
    end)
end
