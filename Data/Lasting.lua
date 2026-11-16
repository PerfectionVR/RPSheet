-- Features that are "on for a while": the passive a class feature switches on when it
-- is used, by the passive's name, and what switches it off besides a click on it.
-- The sheet keeps no clock, so the minutes they last are left to the player.
--   label          what the announcement calls the feature
--   incapacitated  true: it ends when a condition that incapacitates is ticked
--                  (Actions/Incapacitated.lua)
-- Every one of them lasts ten minutes or less, so a short or long rest outlasts it
-- (Actions/Rest.lua).
local _, ns = ...
local R = ns.Rules

R.LASTING = {
    ["Raging"] = { label = "Rage", incapacitated = true },
    ["Superior Defense active"] = { label = "Superior Defense", incapacitated = true },
    ["Full of Stars"] = { label = "Starry Form", incapacitated = true },
    ["Dragon"] = { label = "Starry Form", incapacitated = true },
    ["Shadowform active"] = { label = "Shadowform", incapacitated = true },
    ["Divine Sense active"] = { label = "Divine Sense", incapacitated = true },
    ["Nature's Sanctuary active"] = { label = "Nature's Sanctuary", incapacitated = true },
    -- Ends only when the paladin ends it, or after ten minutes.
    ["Holy Nimbus active"] = { label = "Holy Nimbus" },
}
