-- "Weapons" tab.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local With = Opt.With

local function Build(weapon)
    local function self() return weapon end
    return {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        stat = With({
            type = "select", order = 2, name = "Ability",
            desc = "Strength for most melee weapons, Dexterity for ranged and finesse weapons.",
            values = Opt.STAT_VALUES, sorting = R.STATS,
        }, self, "stat"),
        dice = With({
            type = "range", order = 3, min = 1, max = 10, step = 1, name = "Number of dice",
        }, self, "dice"),
        sides = With({
            type = "select", order = 4, name = "Die", values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
        }, self, "sides"),
        proficient = With({
            type = "toggle", order = 5, name = "Proficient",
            desc = "Adds your proficiency bonus to the attack roll.",
        }, self, "proficient"),
        heal = With({
            type = "toggle", order = 6, name = "Healing, no attack roll",
            desc = "Rolls the dice as healing and skips the d20.",
        }, self, "heal"),
    }
end

Opt.lists.weapons = {
    order = 1, title = "Weapons", noun = "weapon", template = R.TEMPLATES.weapon, build = Build,
    help = "Attack = d20 + ability modifier + proficiency bonus, then damage dice + ability modifier. A natural 20 doubles the dice. Right-click the weapon row on the sheet to swap weapons.\n",
}
