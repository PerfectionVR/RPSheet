-- "Abilities" tab: each ability is a list of steps (see Rules.ACTIONS).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- The fields of one step. Which ones show depends on the step's type.
local function StepOptions(ability, index, action)
    local function this() return action end
    -- hidden unless the step is one of the given types
    local function Only(...)
        local kinds = { ... }
        return function()
            for _, kind in ipairs(kinds) do
                if action.type == kind then return false end
            end
            return true
        end
    end
    local isDice = function() return action.type == "DICE" end

    return {
        type = "group", inline = true, order = 20 + index,
        name = function() return ("%s%d. %s|r"):format(Opt.GREEN, index, RPSheet:ActionText(action)) end,
        args = {
            type = With({
                type = "select", order = 1, name = "Step", values = R.ACTIONS, sorting = R.ACTION_ORDER,
            }, this, "type"),

            -- Roll a d20
            kind = With({
                type = "select", order = 2, name = "Kind of roll", hidden = Only("ROLL"),
                desc = "Decides which passive bonuses apply: attack rolls, spell attacks, checks or saving throws.",
                values = R.ROLL_KINDS, sorting = R.ROLL_KIND_ORDER,
            }, this, "kind"),
            stat = With({
                type = "select", order = 3, hidden = Only("ROLL", "DICE"),
                name = function() return isDice() and "Plus" or "Ability" end,
                values = function() return isDice() and R.AMOUNT_SOURCES or Opt.STAT_OR_NONE end,
                sorting = function() return isDice() and R.AMOUNT_SOURCE_ORDER or Opt.STAT_OR_NONE_ORDER end,
            }, this, "stat"),
            stat2 = With({
                type = "select", order = 4, name = "Second ability", hidden = Only("ROLL"),
                values = Opt.STAT_OR_NONE, sorting = Opt.STAT_OR_NONE_ORDER,
            }, this, "stat2"),
            proficient = With({
                type = "toggle", order = 5, name = "Add proficiency bonus", hidden = Only("ROLL"),
            }, this, "proficient"),

            -- Roll dice
            count = With({
                type = "range", order = 6, min = 1, max = 20, step = 1, name = "Number of dice", hidden = Only("DICE"),
            }, this, "count"),
            sides = With({
                type = "select", order = 7, name = "Die", hidden = Only("DICE"),
                values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
            }, this, "sides"),
            dice = With({
                type = "select", order = 8, name = "Counts as", hidden = Only("DICE"), values = R.DICE_KINDS, sorting = R.DICE_KIND_ORDER,
            }, this, "dice"),

            -- Roll the weapon's dice
            times = With({
                type = "range", order = 9, min = 1, max = 5, step = 1, name = "Weapon dice multiplier", hidden = Only("WEAPON"),
                desc = "Rolls the equipped weapon's dice this many times and adds its ability modifier once.",
            }, this, "times"),

            -- Spend, regain or empty a resource
            resource = With({
                type = "select", order = 10, name = "Resource", hidden = Only("SPEND", "GAIN", "EMPTY"),
                desc = "HP, a class resource, one of your own resources, or a spell slot.",
                values = Opt.TrackerValues,
            }, this, "resource"),
            amount = With({
                type = "range", order = 11, min = 1, max = 100, softMax = 10, step = 1, name = "Amount", hidden = Only("SPEND", "GAIN"),
            }, this, "amount"),
            freeIfFull = With({
                type = "select", order = 12, name = "Free when this is full", hidden = Only("SPEND"),
                desc = "The cost is waived while the chosen resource is at its maximum.",
                values = Opt.TrackerValues,
            }, this, "freeIfFull"),

            -- Switch a passive
            passive = With({
                type = "select", order = 13, name = "Passive", hidden = Only("TOGGLE"), values = Opt.PassiveValues,
            }, this, "passive"),
            mode = With({
                type = "select", order = 14, name = "Do", hidden = Only("TOGGLE"), values = R.TOGGLE_MODES,
            }, this, "mode"),

            remove = {
                type = "execute", order = 20, name = "Remove step",
                func = function()
                    table.remove(ability.actions, index)
                    ns.RebuildOptions()
                    Opt.Changed()
                end,
            },
        },
    }
end

local function Build(ability)
    local function self() return ability end
    local args = {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        desc = With({
            type = "input", order = 2, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
        actionsHeader = { type = "header", order = 10, name = "What it does" },
        actionsHelp = {
            type = "description", order = 11,
            name = "An ability is a list of steps carried out in order when you click it: spend a resource, roll to hit, roll damage, switch a passive on. Add as many as you need. Costs are checked first; if you can't pay, nothing is rolled.",
        },
        addAction = {
            type = "execute", order = 1000, name = "Add step",
            func = function()
                table.insert(ability.actions, CopyTable(R.TEMPLATES.action))
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
    }
    for index, action in ipairs(ability.actions) do
        args["action" .. index] = StepOptions(ability, index, action)
    end
    return args
end

Opt.lists.abilities = {
    order = 3, title = "Abilities", noun = "ability", template = R.TEMPLATES.ability, build = Build,
    help = "Things you click to use: class features, spells, feats. Each is built from steps, so any ability can be recreated or invented.\n",
}
