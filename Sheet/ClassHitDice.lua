-- Hit points and Hit Dice by class. The first class gives its whole die at the
-- character's first level; every other level, of any class, gives the average of that
-- class's die, rounded up. Each class adds its own Hit Dice: dice of the same size are
-- one pool, dice of different sizes are counted apart.
local _, ns = ...
local R = ns.Rules

-- Hit points from the classes' dice alone, before Constitution and anything else.
function ns.DiceHitPoints(sheet)
    local total = 0
    for index, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        local die = class and class.hitDie or R.DEFAULT_HIT_DIE
        local level = view.level
        if index == 1 then
            total = die + (level - 1) * (die / 2 + 1)
        else
            total = total + level * (die / 2 + 1)
        end
    end
    return total
end

-- The character's Hit Dice as a list of pools, the first class's die first:
--   { sides = 10, count = 5, label = "Hit Dice", first = true }
-- `first` marks the pool that is kept where the Hit Dice always were (state.hitDice).
function ns.HitDice(sheet)
    local pools, bySides = {}, {}
    for _, view in ipairs(ns.ClassViews(sheet)) do
        local class = R.CLASSES[view.class]
        local sides = class and class.hitDie or R.DEFAULT_HIT_DIE
        local pool = bySides[sides]
        if not pool then
            pool = { sides = sides, count = 0, first = #pools == 0 }
            pools[#pools + 1], bySides[sides] = pool, pool
        end
        pool.count = pool.count + view.level
    end
    for _, pool in ipairs(pools) do
        pool.label = #pools == 1 and "Hit Dice" or ("Hit Dice (d%d)"):format(pool.sides)
    end
    return pools
end
