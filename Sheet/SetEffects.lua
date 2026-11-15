-- Effects that set or multiply a number instead of adding to it (Data/EffectModes.lua):
-- which of them count right now, and the ability scores and speed they lead to.
-- Only an effect's flat amount is used here, so working out a score never needs a score.
local _, ns = ...
local RPSheet = ns.addon

local NONE = {}

-- Calls visit(effect, name of the passive or item) for every effect of that mode aimed
-- at `target` that counts now: a switched-on passive, or an item that is equipped and
-- attuned where it asks for that.
local function Each(self, target, mode, visit)
    local sheet = self:Sheet()
    for _, passive in ipairs(sheet.passives or NONE) do
        if passive.enabled and passive.name ~= "" and not self:PassiveBlocked(passive) then
            for _, effect in ipairs(passive.effects or NONE) do
                if effect.target == target and ns.EffectMode(effect) == mode then visit(effect, passive.name) end
            end
        end
    end
    for _, item in ipairs(sheet.items or NONE) do
        if #(item.effects or NONE) > 0 and self:ItemActive(item) then
            for _, effect in ipairs(item.effects) do
                if effect.target == target and ns.EffectMode(effect) == mode then visit(effect, item.name) end
            end
        end
    end
end

-- The highest number anything sets `target` to, and what sets it; nil when nothing does.
function RPSheet:EffectFloor(target)
    local best, from
    Each(self, target, "MIN", function(effect, name)
        local value = tonumber(effect.flat) or 0
        if not best or value > best then best, from = value, name end
    end)
    return best, from
end

-- What `target` is multiplied by, and what does it. Multipliers don't pile up: the
-- largest one counts.
function RPSheet:EffectMultiplier(target)
    local most, from = 1, nil
    Each(self, target, "TIMES", function(effect, name)
        local times = ns.EffectTimes(effect)
        if times > most then most, from = times, name end
    end)
    return most, from
end

-- What raises this ability's score above the character's own right now: the name of
-- the item or passive and the score it sets. Nil when the own score is as high.
function RPSheet:ScoreSetBy(stat, own)
    local score, used = self:NaturalScore(stat, own)
    if not used then return nil end
    local floor, from = self:EffectFloor("SCORE:" .. used)
    if floor and floor > score then return from, floor end
end

-- The speed everything else is added to: the species' or the form's, or the higher
-- number an item sets it to. Also returns what set it and the speed it replaced.
function RPSheet:BaseSpeed()
    local form, species = self:Form(), self:SpeciesData()
    local own = form and form.speed or species and species.speed or 30
    local floor, from = self:EffectFloor("SPEED")
    if floor and floor > own then return floor, from, own end
    return own
end
