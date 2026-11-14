-- "Weapons" tab.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
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
        style = With({
            type = "toggle", order = 7, name = "Fighting Style applies",
            desc = "Adds your Fighting Style's bonus to this weapon. Untick it for weapons the style doesn't cover, such as a melee weapon with Archery.",
            hidden = function() return not RPSheet:StyleAffectsWeapons() end,
        }, self, "style"),
        mastery = With({
            type = "select", order = 8,
            name = function()
                local limit = RPSheet:MasteryLimit()
                local used = RPSheet:MasteriesUsed()
                if limit == 0 then return "Mastery" end
                return ("Mastery (%s%d of %d used|r)"):format(used > limit and Opt.RED or "", used, limit)
            end,
            desc = function()
                local lines = { "The mastery property of this kind of weapon. You need the Weapon Mastery feature. Your class allows the mastery of a set number of weapons; the count turns red when you go over it." }
                for _, name in ipairs(R.MASTERY_ORDER) do
                    if name ~= "" then lines[#lines + 1] = ("|cffffd100%s|r: %s"):format(name, R.MASTERIES[name].desc) end
                end
                return table.concat(lines, "\n\n")
            end,
            values = function()
                local values = { [""] = "None" }
                for _, name in ipairs(R.MASTERY_ORDER) do
                    if name ~= "" then values[name] = name end
                end
                return values
            end,
            sorting = R.MASTERY_ORDER,
        }, self, "mastery"),
    }
end

Opt.lists.weapons = {
    order = 1, title = "Weapons", noun = "weapon", template = R.TEMPLATES.weapon, build = Build,
    help = "Attack = d20 + ability modifier + proficiency bonus, then damage dice + ability modifier. A natural 20 doubles the dice. Right-click the weapon row on the sheet to swap weapons.\n",
}
