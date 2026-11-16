-- Effects that do something other than add: an item or passive can set an ability
-- score or a speed to at least a number (a belt of giant strength, striding boots, a
-- ring of swimming), multiply the walking speed (boots that double it), or make a
-- swimming, climbing or flying speed equal to the walking speed (spider slippers).
-- Everything else an effect does is adding, which is what an empty mode means.
local _, ns = ...
local R = ns.Rules

R.EFFECT_MODES = {
    [""] = "Adds the amount",
    MIN = "Sets it to the amount, if that is higher",
    TIMES = "Multiplies it by the amount",
    WALK = "Equal to your walking speed",
}
R.MAX_MULTIPLIER = 10 -- keeps a typo from making a speed of thousands of feet

-- Older effects have no mode and keep adding.
R.TEMPLATES.effect.mode = ""

-- An ability score can only be set, never added to: points belong on the Scores page.
for _, stat in ipairs(R.STATS) do
    R.EFFECT_TARGETS["SCORE:" .. stat] = "Ability score: " .. R.STAT_NAMES[stat]
    table.insert(R.EFFECT_TARGET_ORDER, "SCORE:" .. stat)
end

function ns.IsScoreTarget(target)
    return type(target) == "string" and target:sub(1, 6) == "SCORE:"
end

-- The other ways of moving, each a speed of its own (Data/MoveSpeeds.lua): the effect
-- target of each, listed right after the walking speed.
R.MOVE_TARGETS = { SWIM = "swim", CLIMB = "climb", FLY = "fly" }
R.EFFECT_TARGETS.SWIM, R.EFFECT_TARGETS.CLIMB, R.EFFECT_TARGETS.FLY = "Swimming speed (feet)", "Climbing speed (feet)", "Flying speed (feet)"
for index, target in ipairs(R.EFFECT_TARGET_ORDER) do
    if target == "SPEED" then
        for offset, move in ipairs({ "SWIM", "CLIMB", "FLY" }) do table.insert(R.EFFECT_TARGET_ORDER, index + offset, move) end
        break
    end
end

-- The ways an effect on `target` can count, as a list of modes; nil when it only adds
-- (or, for an ability score, only sets).
local SPEED_MODES, MOVE_MODES = { "", "MIN", "TIMES" }, { "", "MIN", "WALK" }
function ns.EffectModesFor(target)
    if target == "SPEED" then return SPEED_MODES end
    if R.MOVE_TARGETS[target] then return MOVE_MODES end
end

-- How an effect works on its target: "" adds, "MIN" sets it to at least the flat
-- amount, "TIMES" multiplies by it, "WALK" makes it equal to the walking speed. Only
-- a speed can be set, multiplied or tied to the walking speed by choice.
function ns.EffectMode(effect)
    if ns.IsScoreTarget(effect.target) then return "MIN" end
    for _, mode in ipairs(ns.EffectModesFor(effect.target) or {}) do
        if mode == effect.mode then return mode end
    end
    return ""
end

-- The whole number a "TIMES" effect multiplies by.
function ns.EffectTimes(effect)
    return math.max(1, math.min(R.MAX_MULTIPLIER, math.floor(tonumber(effect.flat) or 1)))
end
