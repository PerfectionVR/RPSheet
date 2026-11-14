-- "Defense" tab: armor, shield, hit point adjustment.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Util = ns.Util
local Sheet, With = Opt.Sheet, Opt.With

local function Summary()
    local sheet, class = Sheet(), RPSheet:ClassData()
    local lines = {
        ("HP %s%d|r     AC %s%d|r     Initiative %s%s|r     Speed %s%d ft|r"):format(
            Opt.GOLD, RPSheet:MaxHP(), Opt.GOLD, RPSheet:AC(), Opt.GOLD, Util.Signed(RPSheet:Initiative()), Opt.GOLD, RPSheet:Speed()),
        ("Hit points: d%d at level 1, then the average each level, plus your Constitution modifier per level."):format(
            class and class.hitDie or R.DEFAULT_HIT_DIE),
    }
    local armor = R.ARMOR[sheet.armor]
    if armor.minStr and RPSheet:Score("STR") < armor.minStr then
        lines[#lines + 1] = ("%s%s needs Strength %d, or your speed drops by 10 feet.|r"):format(Opt.RED, armor.name, armor.minStr)
    end
    if sheet.armor == "NONE" and class and class.unarmored then
        lines[#lines + 1] = ("Unarmored Defense: without armor your AC also adds your %s modifier."):format(R.STAT_NAMES[class.unarmored])
    end
    lines[#lines + 1] = "These totals include your switched-on passives."
    return table.concat(lines, "\n") .. "\n"
end

Opt.custom.defense = {
    type = "group", order = 5, name = "Defense",
    args = {
        summary = { type = "description", order = 1, fontSize = "medium", name = Summary },
        armor = With({
            type = "select", order = 2, name = "Armor",
            desc = "Light armor adds your full Dexterity modifier, medium armor at most +2, heavy armor none.",
            values = Opt.ARMOR_VALUES, sorting = R.ARMOR_ORDER,
        }, Sheet, "armor"),
        shield = With({ type = "toggle", order = 3, name = "Shield (+2 AC)" }, Sheet, "shield"),
        hpAdjust = With({
            type = "range", order = 4, min = -100, max = 100, softMin = -20, softMax = 40, step = 1,
            name = "Hit point adjustment",
            desc = "Added to your maximum HP. Use it if you rolled your hit dice or your DM ruled differently.",
        }, Sheet, "hpAdjust"),
    },
}
