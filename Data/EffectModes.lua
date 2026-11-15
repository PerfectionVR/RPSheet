-- Effects that do something other than add: an item or passive can set an ability
-- score or the speed to at least a number (a belt of giant strength, striding boots),
-- or multiply the speed (boots that double it). Everything else an effect does is
-- adding, which is what an empty mode means.
local _, ns = ...
local R = ns.Rules

R.EFFECT_MODES = {
    [""] = "Adds the amount",
    MIN = "Sets it to the amount, if that is higher",
    TIMES = "Multiplies it by the amount",
}
R.EFFECT_MODE_ORDER = { "", "MIN", "TIMES" }
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

-- How an effect works on its target: "" adds, "MIN" sets it to at least the flat
-- amount, "TIMES" multiplies by it. Only the speed can be set or multiplied by choice.
function ns.EffectMode(effect)
    if ns.IsScoreTarget(effect.target) then return "MIN" end
    if effect.target == "SPEED" and (effect.mode == "MIN" or effect.mode == "TIMES") then return effect.mode end
    return ""
end

-- The whole number a "TIMES" effect multiplies by.
function ns.EffectTimes(effect)
    return math.max(1, math.min(R.MAX_MULTIPLIER, math.floor(tonumber(effect.flat) or 1)))
end
