-- The Dragon constellation of a Circle of the Stars druid (Data/SubclassDruid.lua): on an
-- Intelligence or Wisdom check, and on the save to keep concentrating, a d20 of 9 or
-- lower counts as 10 while the Dragon passive is on (its flag mindFloor). Checks are
-- rolled in Actions/Dice.lua, the concentration save in Actions/Conditions.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local MIND = { INT = true, WIS = true }

-- The ability a check with this label uses: "INT check", a skill, or a tool.
local function CheckStat(label)
    local stat = label:match("^(%u+) check$")
    if stat then return stat end
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == label then return skill.stat end
    end
    return R.TOOLS[label] and R.TOOLS[label].stat
end

-- True if a low d20 on the check with this label counts as 10.
function RPSheet:MindFloor(label)
    if not self:FeatureFlag("mindFloor") then return false end
    return MIND[CheckStat(label) or ""] == true
end

-- The same for the save to keep concentrating.
function RPSheet:ConcentrationFloor()
    return self:FeatureFlag("mindFloor") == true
end
