-- What the rules ask of the other classes of a wizard character (Wizard/MoreClasses.lua),
-- step by step: which class can be taken, its subclass and skill on the class step,
-- a skill given twice on the origin step, the scores of 13 on the ability score step.
-- The check itself is the level dialog's (ns.MulticlassBlock in Sheet/ClassRules.lua),
-- asked of a stand-in for the character the draft would make.
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard

local NONE = {}
local HIGH = {} -- scores that meet every class, for the steps before the scores are set
for _, stat in ipairs(R.STATS) do HIGH[stat] = R.MAX_SCORE end

-- The character one level short of done, with the first `count` other classes: what
-- the level dialog would look at before the next class is added.
local function StandIn(count, scores)
    local draft, classes = W.draft, {}
    for index, row in ipairs(W.Extras()) do
        if index <= count then classes[row.class] = { level = row.level, subclass = "", spec = "", skill = "" } end
    end
    return {
        class = draft.class, level = draft.level - 1, classes = classes,
        base = scores and draft.base or HIGH, bonus = scores and draft.bonus or NONE, asi = NONE,
    }
end

-- Why other class `index` can't be taken (or `key` in its place), or nil. The scores
-- of 13 are only looked at when `scores` is set: they are chosen on a later step.
function W.ExtraBlock(index, scores, key)
    local row = W.Extras()[index]
    key = key or (row and row.class)
    return key and ns.MulticlassBlock(StandIn(index - 1, scores), key) or nil
end

-- The skills other class `index` lets the character pick one of: its list without
-- what the first class, the background and the other rows already give.
function W.ExtraSkills(index)
    local draft, row = W.draft, W.Extras()[index]
    if not row then return {} end
    local taken = {}
    for skill, picked in pairs(draft.classSkills) do
        if picked then taken[skill] = 1 end
    end
    local background = R.BACKGROUNDS[draft.background]
    for _, skill in ipairs(background and background.skills or NONE) do taken[skill] = 1 end
    for other, entry in ipairs(W.Extras()) do
        if other ~= index and (entry.skill or "") ~= "" then taken[entry.skill] = 1 end
    end
    return ns.MulticlassSkills({ skills = taken }, row.class, row.skill)
end

-- What is wrong with the other classes on a step of the wizard, or nil.
function W.ExtrasProblem(step)
    local draft, rows = W.draft, W.Extras()
    if step == 1 and W.ExtraLevels() > draft.level - 1 then
        return ("Your other classes take %d levels. Your first class keeps at least one: raise the level or lower theirs."):format(W.ExtraLevels())
    end
    for index, row in ipairs(rows) do
        local class = R.CLASSES[row.class]
        if step == 1 then
            local block = W.ExtraBlock(index, false)
            if block then return ("%s can't be one of your classes: %s."):format(class.name, block) end
            if row.level >= R.SUBCLASS_LEVEL and #class.subclasses > 0 and row.subclass == "" then
                return ("Choose a subclass for %s: it has one from level %d of the class."):format(class.name, R.SUBCLASS_LEVEL)
            end
            if row.skill == "" and #W.ExtraSkills(index) > 0 then
                return ("Choose the skill %s gives you."):format(class.name)
            end
            if row.skill ~= "" and draft.classSkills[row.skill] then
                return ("%s is one of your class skills already. Pick another skill for %s."):format(row.skill, class.name)
            end
        elseif step == 2 then
            local background = R.BACKGROUNDS[draft.background]
            for _, skill in ipairs(background and background.skills or NONE) do
                if skill == row.skill then
                    return ("This background already gives %s, the skill you picked for %s. Go back to step 1 and pick another, or choose a different background."):format(skill, class.name)
                end
            end
        elseif step == 3 then
            local block = W.ExtraBlock(index, true)
            if block then
                return ("%s as another class: %s. Raise the score, or go back to step 1 and change your classes."):format(class.name, block)
            end
        end
    end
end
