-- "Passives" tab: each passive is a list of effects (see Rules.EFFECT_TARGETS).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- The amount's slider reaches what the effect's way of counting needs: a bonus, a
-- score or speed to set, or a multiplier. The options library reads `hidden` before
-- it sets a slider up, which is where the range is brought up to date (see Opt.Bounded).
-- A speed that equals the walking speed has no amount.
local AMOUNT_RANGES = { [""] = { -20, 20 }, TIMES = { 2, R.MAX_MULTIPLIER } }
function Opt.EffectAmount(effect, option)
    option.hidden = function()
        local mode = ns.EffectMode(effect)
        local range = AMOUNT_RANGES[mode]
            or (ns.EffectModesFor(effect.target) and { 0, 120 } or { 1, 30 }) -- a speed or a score to set
        local current = tonumber(effect.flat) or 0
        option.min, option.max = math.min(range[1], current), math.max(range[2], current)
        return mode == "WALK"
    end
    return option
end

-- The ways of counting the effect's target allows, for the "How" dropdown.
local function ModeValues(effect)
    local values = {}
    for _, mode in ipairs(ns.EffectModesFor(effect.target) or {}) do values[mode] = R.EFFECT_MODES[mode] end
    return values
end

-- The editor for one effect of `owner`: a passive, or an item (Options/Inventory.lua).
local function EffectOptions(owner, index, effect, base)
    local function this() return effect end
    -- The dropdown shows the way the effect counts now: a way its target doesn't
    -- allow (left over from another target) counts, and shows, as plain adding.
    local function ShowsMode(option)
        option.get = function() return ns.EffectMode(effect) end
        return option
    end
    -- An effect that sets or multiplies (Data/EffectModes.lua) has only its amount.
    local function Adds() return ns.EffectMode(effect) == "" end
    return {
        type = "group", inline = true, order = base + 20 + index,
        name = function() return Opt.GREEN .. RPSheet:EffectText(effect) .. "|r" end,
        args = {
            target = With({
                type = "select", order = 1, name = "Changes",
                desc = "What the effect works on. An ability score can only be set to a number, which counts when it is higher than your own score.",
                values = R.EFFECT_TARGETS, sorting = R.EFFECT_TARGET_ORDER,
            }, this, "target"),
            mode = ShowsMode(With({
                type = "select", order = 1.5, name = "How",
                desc = "Your walking speed can be added to, set to a number when that is higher than your own speed, or multiplied (2 doubles it). A swimming, climbing or flying speed can be set to a number, made equal to your walking speed, or added to when you have one.",
                values = function() return ModeValues(effect) end,
                sorting = function() return ns.EffectModesFor(effect.target) or {} end,
                hidden = function() return not ns.EffectModesFor(effect.target) end,
            }, this, "mode")),
            flat = Opt.EffectAmount(effect, With({
                type = "range", order = 2, min = -20, max = 20, step = 1,
                name = function() return Adds() and "Flat amount" or "Amount" end,
                desc = "A fixed bonus (or penalty), for example +1. For an effect that sets or multiplies: the number it sets, or multiplies by.",
            }, this, "flat")),
            stat = With({
                type = "select", order = 3, name = "Plus",
                desc = "Adds an ability modifier, your level or your proficiency bonus.",
                values = R.AMOUNT_SOURCES, sorting = R.AMOUNT_SOURCE_ORDER,
                hidden = function() return not Adds() end,
            }, this, "stat"),
            times = With({
                type = "range", order = 4, min = 1, max = 5, step = 1, name = "Counted",
                desc = "How many times that value is added. 2 = twice.",
                hidden = function() return effect.stat == "" or not Adds() end,
            }, this, "times"),
            remove = {
                type = "execute", order = 5, name = "Remove effect",
                func = function()
                    table.remove(owner.effects, index)
                    ns.RebuildOptions()
                    Opt.Changed()
                end,
            },
        },
    }
end

-- Adds the "Effects" block to a page: a heading, `help`, one editor per effect of
-- `owner` and an Add button. `base` moves the block down the page (default 0).
function Opt.AddEffectArgs(args, owner, help, base)
    base = base or 0
    args.effectsHeader = { type = "header", order = base + 10, name = "Effects" }
    args.effectsHelp = { type = "description", order = base + 11, name = help }
    args.addEffect = {
        type = "execute", order = base + 1000, name = "Add effect",
        func = function()
            table.insert(owner.effects, CopyTable(R.TEMPLATES.effect))
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    for index, effect in ipairs(owner.effects) do
        args["effect" .. index] = EffectOptions(owner, index, effect, base)
    end
end

local function Build(passive)
    local function self() return passive end
    local args = {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        enabled = With({
            type = "toggle", order = 2, name = "Switched on",
            desc = "Effects only count while the passive is on. You can also click the passive on the sheet, or have an ability switch it.",
        }, self, "enabled"),
        desc = With({
            type = "input", order = 3, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
    }
    Opt.AddEffectArgs(args, passive, "Each effect adds a flat number, a modifier, your level or your proficiency bonus to one thing, or sets an ability score or a speed to a number that counts when it is higher than your own (your walking speed can also be multiplied). A swimming, climbing or flying speed is one you only have when something sets it: to a number, or to your walking speed. A passive can have as many effects as you like, and effects from different passives add up.")
    return args
end

Opt.lists.passives = {
    order = 4, title = "Passives", noun = "passive", template = R.TEMPLATES.passive, build = Build,
    help = "Always-on features, traits, feats and temporary stances. Their effects change your numbers while they are switched on.\n",
}
