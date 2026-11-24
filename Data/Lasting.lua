-- Features that are "on for a while": the passive a class feature switches on when it
-- is used, by the passive's name, and what switches it off besides a click on it.
-- The sheet keeps no clock: outside a combat session the time they last is left to the
-- player. In a session they are counted in the character's own turns
-- (Integrations/FightTimers.lua).
--   label          what the announcement calls the feature
--   incapacitated  true: it ends when a condition that incapacitates is ticked
--                  (Actions/Incapacitated.lua)
--   rounds         how long it lasts, in rounds: it ends at the start of that many of
--                  the character's turns after it was switched on
--   toEnd          true: it lasts to the end of that turn, not its start
--   upkeep         true: it ends sooner unless it is kept up each turn (a rage)
-- Every one of them lasts an hour or less, so a short or long rest outlasts it
-- (Actions/Rest.lua).
local _, ns = ...
local R = ns.Rules

R.LASTING = {
    ["Raging"] = { label = "Rage", incapacitated = true, rounds = 100, upkeep = true },
    ["Superior Defense active"] = { label = "Superior Defense", incapacitated = true, rounds = 10 },
    ["Full of Stars"] = { label = "Starry Form", incapacitated = true, rounds = 100 },
    ["Dragon"] = { label = "Starry Form", incapacitated = true, rounds = 100 },
    ["Shadowform active"] = { label = "Shadowform", incapacitated = true, rounds = 10 },
    ["Divine Sense active"] = { label = "Divine Sense", incapacitated = true, rounds = 100 },
    ["Nature's Sanctuary active"] = { label = "Nature's Sanctuary", incapacitated = true, rounds = 10 },
    -- Ends only when the paladin ends it, or after ten minutes.
    ["Holy Nimbus active"] = { label = "Holy Nimbus", rounds = 100 },
    ["Avenging Angel active"] = { label = "Avenging Angel", rounds = 100 },
    ["Aspect of the Horsemen active"] = { label = "Aspect of the Horsemen", rounds = 100 },
    ["Dragon Wings active"] = { label = "Dragon Wings", rounds = 600 },             -- an hour, as long as a short rest
    -- Ten minutes or less too, so a rest outlasts them; the rules don't end them when
    -- you are incapacitated.
    ["Sacred Weapon active"] = { label = "Sacred Weapon", rounds = 100 },    -- 10 minutes
    ["Vow of Enmity active"] = { label = "Vow of Enmity", rounds = 10 },    -- 1 minute
    ["Innate Sorcery active"] = { label = "Innate Sorcery", rounds = 10 },  -- 1 minute
    ["Reckless"] = { label = "Reckless Attack", rounds = 1 },              -- until your next turn
    ["Dispersed"] = { label = "Dispersion", rounds = 1, toEnd = true },                  -- until the end of your next turn
    -- Species traits and feats (Data/Traits.lua, Data/FeatUses.lua)
    ["Draconic Flight active"] = { label = "Draconic Flight", rounds = 100 }, -- 10 minutes
    ["Parrying"] = { label = "Parry", rounds = 1 },                        -- until your next turn
}
