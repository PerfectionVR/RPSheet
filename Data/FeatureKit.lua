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
-- `desc` may be a function(level, sheet) for wording that follows the character.
-- `extra` can carry:
--   startsOff = true   switched off until the player turns it on
--   skills = { ... }   skill proficiencies the feature grants
--   saves = { ... }    saving throw proficiencies it grants
--   advantage = { ... } rolls it gives advantage on, by their label on the sheet
--   flags = { ... }    reliable = true (a d20 of 9 or lower counts as 10 on proficient
--                      skill checks), languages = n (more languages to choose)
--   skillChoice        a skill to pick (see Sheet/Maneuvers.lua)
--   scores = { DEX = 4 }  ability scores it raises, to a maximum of 25
--   strike = { sides = 8, damage = "radiant" }  a die added to every melee weapon hit
--   spec = "Blood"     only for a character of that specialization (abilities too)
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
    local feature = Kit.Ability(level, name, desc, function(current, sheet)
        local list = type(actions) == "function" and actions(current, sheet) or CopyTable(actions or {})
        table.insert(list, 1, Kit.Spend(name))
        return list
    end)
    feature.pool = pool
    return feature
end

-- Clicking the ability sets the sheet's "Next roll" row.
function Kit.NextRoll(mode)
    return { type = "NEXTROLL", mode = mode or "ADV" }
end

-- Numbers of a character, for descriptions that quote them. `sheet` is a saved sheet.
-- An ability score: starting score, background points, level-up points, and what
-- features add (which stops at 25).
function Kit.Score(sheet, stat)
    local score = (sheet.base[stat] or 10) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
    local raised = sheet.featureScores and sheet.featureScores[stat]
    if raised then score = math.max(score, math.min(25, score + raised)) end
    return score
end

function Kit.Mod(sheet, stat)
    return math.floor((Kit.Score(sheet, stat) - 10) / 2)
end

function Kit.Prof(level)
    return math.ceil(level / 4) + 1
end

-- Save DC of a feature: 8 + ability modifier + proficiency bonus.
function Kit.DC(sheet, stat)
    return 8 + Kit.Mod(sheet, stat) + Kit.Prof(sheet.level)
end

function Kit.Spend(resource, amount)
    return { type = "SPEND", resource = resource, amount = amount or 1, freeIfFull = "" }
end

function Kit.SwitchOn(passive)
    return { type = "TOGGLE", passive = passive, mode = "ON" }
end

-- A count of 0 rolls nothing and gives just the flat amount and the modifier.
function Kit.Dice(count, sides, stat, kind, flat)
    return { type = "DICE", count = count, sides = sides, stat = stat or "", dice = kind or "DAMAGE", flat = flat or 0 }
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

-- A Rogue's Cunning Strike option: Sneak Attack with `cost` fewer dice, plus an effect.
-- `save` is the ability the target saves with, against 8 + Dexterity + proficiency.
function Kit.CunningStrike(level, name, cost, text, save)
    return Kit.Ability(level, "Cunning Strike: " .. name,
        function(_, sheet)
            local desc = ("Sneak Attack with %d fewer %s. %s"):format(cost, cost == 1 and "die" or "dice", text)
            if save then desc = ("%s %s save DC %d."):format(desc, save, Kit.DC(sheet, "DEX")) end
            return desc
        end,
        function(current) return { Kit.Dice(math.max(0, math.ceil(current / 2) - cost), 6) } end)
end
