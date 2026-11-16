-- A check or save whose total can't fall below an ability score: Indomitable Might
-- makes a Strength check or Strength save that totals less than the Strength score
-- count as the score. Strength checks are "STR check" and the skills of Strength
-- (Athletics). Used by RPSheet:RollCheck (Actions/Dice.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local STRENGTH = { ["STR check"] = true, ["STR save"] = true }
for _, skill in ipairs(R.SKILLS) do
    if skill.stat == "STR" then STRENGTH[skill.name] = true end
end

-- " [counts as 18: Indomitable Might]" when the total is raised, otherwise "".
function RPSheet:ScoreFloorNote(label, total)
    if not STRENGTH[label] then return "" end
    local passive = ns.FeaturePassive(self:Sheet(), "Indomitable Might")
    if not (passive and passive.enabled) then return "" end
    local score = self:Score("STR")
    if total >= score then return "" end
    return (" [counts as %d: %s]"):format(score, ns.Mark("Indomitable Might"))
end
