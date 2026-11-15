-- Numbers worked out from the saved sheet: ability scores and their modifiers.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

-- The score that counts: the character's own, or the number an item sets it to when
-- that is higher (Sheet/SetEffects.lua).
function RPSheet:Score(stat, own)
    local score, used = self:NaturalScore(stat, own)
    if not used then return score end
    return math.max(score, self:EffectFloor("SCORE:" .. used) or 0)
end

-- Starting score, plus the background's points, plus points from level-ups: the score
-- before anything worn sets it higher. Also returns the ability the score was taken
-- from, or nothing when it is a beast form's fixed number.
-- `own`: the character's own score, whatever form it is in.
function RPSheet:NaturalScore(stat, own)
    local sheet = self:Sheet()
    -- In a beast form some abilities take the score of another.
    local form = not own and self:Form()
    local taken = form and form.scores[stat]
    if type(taken) == "number" then return taken end -- a beast's own score
    if taken then stat = taken end
    local score = (sheet.base[stat] or R.BASE_MIN) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
    -- A capstone feature can raise a score further, up to 25.
    local raised = sheet.featureScores and sheet.featureScores[stat]
    if raised then score = math.max(score, math.min(25, score + raised)) end
    return score, stat
end

-- Modifier of an ability; an empty or unknown ability counts as +0.
function RPSheet:Mod(stat)
    if not R.STAT_NAMES[stat] then return 0 end
    return Util.ScoreMod(self:Score(stat))
end

-- The character's own modifier, whatever form it is in: hit points stay its own.
function RPSheet:OwnMod(stat)
    if not R.STAT_NAMES[stat] then return 0 end
    return Util.ScoreMod(self:Score(stat, true))
end

function RPSheet:PointsSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + (R.COST[self:Sheet().base[stat]] or 0)
    end
    return total
end

function RPSheet:BonusSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + self:Sheet().bonus[stat]
    end
    return total
end
