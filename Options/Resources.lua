-- "Resources" tab: the player's own pools (energy, combo points, superiority dice...).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

local function Build(resource)
    local function self() return resource end
    return {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        flat = With({
            type = "range", order = 2, min = 0, max = 200, softMax = 20, step = 1, name = "Flat amount",
        }, self, "flat"),
        stat = With({
            type = "select", order = 3, name = "Plus",
            desc = "Adds an ability modifier, your level or your proficiency bonus to the maximum.",
            values = R.AMOUNT_SOURCES, sorting = R.AMOUNT_SOURCE_ORDER,
        }, self, "stat"),
        times = With({
            type = "range", order = 4, min = 1, max = 10, step = 1, name = "Counted",
            desc = "How many times that value is added. Lay on Hands, for example, is 5 times your level.",
            hidden = function() return resource.stat == "" end,
        }, self, "times"),
        startEmpty = With({
            type = "toggle", order = 5, name = "Starts empty",
            desc = "For things you build up, like combo points. A long rest sets it to 0 instead of full.",
        }, self, "startEmpty"),
        shortRest = With({
            type = "toggle", order = 6, name = "Recharges on a short rest",
            desc = "A short rest refills it. Otherwise only a long rest does.",
        }, self, "shortRest"),
        now = {
            type = "description", order = 7,
            name = function()
                local max = math.max(0, RPSheet:Amount(resource.flat, resource.stat, resource.times))
                return ("%sMaximum now: %d|r"):format(Opt.GREEN, max)
            end,
        },
    }
end

Opt.lists.resources = {
    order = 5, title = "Resources", noun = "resource", template = R.TEMPLATES.resource, build = Build,
    help = "Your own pools: energy, combo points, superiority dice, anything you track. Spell slots and your class's resources (Rage, Focus Points, Lay on Hands...) are added automatically from class and level and don't need an entry here.\n",
}
