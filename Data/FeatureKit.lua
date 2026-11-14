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
--   limit = "UNARMORED" or "NOHEAVY"  armor that stops its effects (Sheet/Limits.lua)
--   when = function(sheet)  only while this is true (any kind of feature); the sheet
--                      may be a stand-in with just class, subclass and level
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

-- A cost the player can take back once after the click, for a use or die that is only
-- spent when it turned the roll around. `when` finishes "if ...": "the check still failed".
function Kit.Refundable(spend, when)
    spend.refund = when
    return spend
end

-- A cost that is waived the first time the ability is used after each long rest.
function Kit.FirstFree(spend)
    spend.firstFree = true
    return spend
end

function Kit.SwitchOn(passive)
    return { type = "TOGGLE", passive = passive, mode = "ON" }
end

-- A count of 0 rolls nothing and gives just the flat amount and the modifier.
function Kit.Dice(count, sides, stat, kind, flat)
    return { type = "DICE", count = count, sides = sides, stat = stat or "", dice = kind or "DAMAGE", flat = flat or 0 }
end

-- Damage dice of a named type, for the types a feature treats differently: low
-- "force" dice can count as higher (see Sheet/Metamorphosis.lua).
function Kit.Typed(dice, damage)
    dice.damage = damage
    return dice
end

-- Dice that count once for each level of the spell slot the ability spends.
function Kit.PerSlot(dice)
    dice.perSlot = true
    return dice
end

-- Dice that gain `more` dice for each level of the spent slot above 1st (a smite).
function Kit.SlotAdd(dice, more)
    dice.slotAdd = more
    return dice
end

-- Dice that grow by one for each earlier use of `resource` since a long rest; the
-- first use rolls nothing (Overchannel).
function Kit.Strain(dice, resource)
    dice.strain = resource
    return dice
end

function Kit.SwitchOff(passive)
    return { type = "TOGGLE", passive = passive, mode = "OFF" }
end

-- A step that changes spell slots: "RECOVER", "TOPOINTS" or "FROMPOINTS"
-- (see Actions/SlotActions.lua).
function Kit.Slots(mode)
    return { type = "SLOTS", mode = mode }
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

-- A Barbarian's Rage Damage bonus at a level. Several features roll that many dice.
function Kit.RageDamage(level)
    return Kit.AtLevel(level, { { 1, 2 }, { 9, 3 }, { 16, 4 } })
end

-- A feature that offers a choice between named options (Primal Order, Divine Order,
-- a Circle of the Land's land). The pick is kept in sheet.featureOptions[<name>] and
-- made in the level dialog or under Customize.
--   options  { { name = "Warden", desc = "...", effects = {...}, advantage = {...},
--               flags = {...}, saves = {...}, strike = {...}, training = { "medium" } }, ... }
-- An option carries the same extras a Passive can; they apply once it is chosen.
-- Another feature can depend on a pick:  feature.option = { "Elemental Fury", "Primal Strike" }.
function Kit.Choice(level, name, desc, options)
    local feature = Kit.Passive(level, name, desc)
    feature.options = options
    return feature
end

function Kit.Option(name, desc, extra)
    local option = { name = name, desc = desc }
    for key, value in pairs(extra or {}) do option[key] = value end
    return option
end

-- Marks a feature as belonging to one option of a Choice.
function Kit.For(choice, option, feature)
    feature.option = { choice, option }
    return feature
end
