-- "Passives" tab: each passive is a list of effects (see Rules.EFFECT_TARGETS).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- The editor for one effect of `owner`: a passive, or an item (Options/Inventory.lua).
local function EffectOptions(owner, index, effect, base)
    local function this() return effect end
    return {
        type = "group", inline = true, order = base + 20 + index,
        name = function() return Opt.GREEN .. RPSheet:EffectText(effect) .. "|r" end,
        args = {
            target = With({
                type = "select", order = 1, name = "Adds to",
                values = R.EFFECT_TARGETS, sorting = R.EFFECT_TARGET_ORDER,
            }, this, "target"),
            flat = With({
                type = "range", order = 2, min = -20, max = 20, step = 1, name = "Flat amount",
                desc = "A fixed bonus (or penalty), for example +1.",
            }, this, "flat"),
            stat = With({
                type = "select", order = 3, name = "Plus",
                desc = "Adds an ability modifier, your level or your proficiency bonus.",
                values = R.AMOUNT_SOURCES, sorting = R.AMOUNT_SOURCE_ORDER,
            }, this, "stat"),
            times = With({
                type = "range", order = 4, min = 1, max = 5, step = 1, name = "Counted",
                desc = "How many times that value is added. 2 = twice.",
                hidden = function() return effect.stat == "" end,
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
    Opt.AddEffectArgs(args, passive, "Each effect adds a flat number, a modifier, your level or your proficiency bonus to one thing. A passive can have as many effects as you like, and effects from different passives add up.")
    return args
end

Opt.lists.passives = {
    order = 4, title = "Passives", noun = "passive", template = R.TEMPLATES.passive, build = Build,
    help = "Always-on features, traits, feats and temporary stances. Their effects change your numbers while they are switched on.\n",
}
