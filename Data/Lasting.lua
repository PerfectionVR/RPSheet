-- Features that are "on for a while": the passive a class feature switches on when it
-- is used, by the passive's name, and what switches it off besides a click on it.
-- The sheet keeps no clock, so the minutes they last are left to the player.
--   label          what the announcement calls the feature
--   incapacitated  true: it ends when a condition that incapacitates is ticked
--                  (Actions/Incapacitated.lua)
-- Every one of them lasts an hour or less, so a short or long rest outlasts it
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
    ["Avenging Angel active"] = { label = "Avenging Angel" },
    ["Aspect of the Horsemen active"] = { label = "Aspect of the Horsemen" },
    ["Dragon Wings active"] = { label = "Dragon Wings" },             -- an hour, as long as a short rest
    -- Ten minutes or less too, so a rest outlasts them; the rules don't end them when
    -- you are incapacitated.
    ["Sacred Weapon active"] = { label = "Sacred Weapon" },    -- 10 minutes
    ["Vow of Enmity active"] = { label = "Vow of Enmity" },    -- 1 minute
    ["Innate Sorcery active"] = { label = "Innate Sorcery" },  -- 1 minute
    ["Reckless"] = { label = "Reckless Attack" },              -- until your next turn
    ["Dispersed"] = { label = "Dispersion" },                  -- until the end of your next turn
}
