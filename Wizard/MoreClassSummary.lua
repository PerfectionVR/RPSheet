-- The text above the "More classes" rows of the wizard's class step: how the levels
-- are split, what each class asks for and gives, and what stands in a class's way.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local GOLD, RED = Opt.GOLD, Opt.RED

-- "Strength or Dexterity" for the abilities a class needs at 13.
local function Needs(class)
    local rule, names = R.MULTICLASS[class.base], {}
    for _, stat in ipairs(rule and rule.primary or {}) do names[#names + 1] = ns.Term(R.STAT_NAMES[stat]) end
    return table.concat(names, rule and rule.either and " or " or " and ")
end

function W.MoreClassSummary()
    if not W.MoreClassesOpen() then return "" end
    local draft, rows = W.draft, W.Extras()
    if #rows == 0 then
        return "Above level 1 you can split your levels over more than one class. Your first class gives its saving throws and full training; another class gives less, and asks for a score of 13 in its main abilities and in those of your first class.\n"
    end
    local first = R.CLASSES[draft.class]
    local parts = { ("%s %d"):format(first.name, W.FirstLevel()) }
    for _, row in ipairs(rows) do parts[#parts + 1] = ("%s %d"):format(R.CLASSES[row.class].name, row.level) end
    local lines = { ("%sLevel %d: %s|r"):format(GOLD, draft.level, table.concat(parts, " / ")) }
    lines[#lines + 1] = ("%s, your first class, needs %s %d or higher to take another."):format(first.name, Needs(first), R.MULTICLASS_SCORE)
    for index, row in ipairs(rows) do
        local class = R.CLASSES[row.class]
        lines[#lines + 1] = ("%s%s|r needs %s %d or higher and gives %s."):format(
            GOLD, class.name, Needs(class), R.MULTICLASS_SCORE, ns.MulticlassGains(row.class))
        local block = W.ExtraBlock(index, false)
        if block then lines[#lines + 1] = ("%s%s: %s.|r"):format(RED, class.name, block) end
    end
    lines[#lines + 1] = "|cff909090The scores are checked on the ability score step. The choices of each class's levels are asked after the character is made.|r"
    return table.concat(lines, "\n") .. "\n"
end
