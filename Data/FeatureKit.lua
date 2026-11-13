-- Shorthand for writing class and subclass features as data (see Features.lua and
-- SubclassFeatures.lua).
local _, ns = ...

local Kit = {}
ns.FeatureKit = Kit

-- Value for the current level from { {level, value}, ... } steps.
function Kit.AtLevel(level, steps)
    local value
    for _, step in ipairs(steps) do
        if level >= step[1] then value = step[2] end
    end
    return value
end

-- A reminder or number-changing passive. `effects` may be a table or function(level).
-- `extra` can carry startsOff = true (switched off until the player turns it on) and
-- skills = { ... } (skill proficiencies the feature grants).
function Kit.Passive(level, name, desc, effects, extra)
    local feature = { level = level, name = name, kind = "passive", desc = desc, effects = effects }
    if extra == true then extra = { startsOff = true } end
    for key, value in pairs(extra or {}) do feature[key] = value end
    return feature
end

-- Something to click. `actions` may be a table or function(level).
function Kit.Ability(level, name, desc, actions)
    return { level = level, name = name, kind = "ability", desc = desc, actions = actions }
end

-- An ability with its own uses, shown as a bar of the same name. Clicking spends one.
--   uses   a number, { {level, uses}, ... } steps, or { stat = "WIS" } for that
--          ability's modifier (never fewer than 1)
--   short  what a short rest gives back: a number of uses or "ALL"; nil = long rest only
function Kit.Limited(level, name, desc, uses, actions, short)
    local pool = { name = name, from = level, short = short }
    if type(uses) == "number" then
        pool.steps = { { level, uses } }
    elseif uses.stat then
        pool.stat, pool.flat, pool.min = uses.stat, uses.flat or 0, uses.min or 1
    else
        pool.steps = uses
    end
    local feature = Kit.Ability(level, name, desc, function(current)
        local list = type(actions) == "function" and actions(current) or CopyTable(actions or {})
        table.insert(list, 1, Kit.Spend(name))
        return list
    end)
    feature.pool = pool
    return feature
end

function Kit.Spend(resource, amount)
    return { type = "SPEND", resource = resource, amount = amount or 1, freeIfFull = "" }
end

function Kit.SwitchOn(passive)
    return { type = "TOGGLE", passive = passive, mode = "ON" }
end

function Kit.Dice(count, sides, stat, kind)
    return { type = "DICE", count = count, sides = sides, stat = stat or "", dice = kind or "DAMAGE" }
end

function Kit.Roll(kind, stat, proficient)
    return { type = "ROLL", kind = kind, stat = stat, stat2 = "", proficient = proficient ~= false }
end

function Kit.Bonus(target, flat, stat, times)
    return { target = target, flat = flat or 0, stat = stat or "", times = times or 1 }
end

-- The Monk's Martial Arts die at a level.
function Kit.MartialDie(level)
    return Kit.AtLevel(level, { { 1, 6 }, { 5, 8 }, { 11, 10 }, { 17, 12 } })
end
