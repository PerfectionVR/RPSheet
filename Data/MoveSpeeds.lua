-- Swimming, climbing and flying speeds: the words for them, and the feats, features
-- and picks that give one for good. Sheet/MoveSpeeds.lua works the numbers out.
-- Without such a speed a character still swims and climbs, at a foot more for each
-- foot moved; the sheet then shows nothing.
local _, ns = ...
local R = ns.Rules

R.MOVE_KINDS = { "swim", "climb", "fly" }
R.MOVE_LABELS = { swim = "Swim", climb = "Climb", fly = "Fly" }
R.MOVE_NOUNS = { swim = "swimming", climb = "climbing", fly = "flying" }
R.MOVE_TARGET = { swim = "SWIM", climb = "CLIMB", fly = "FLY" }
R.MOVE_TIPS = {
    swim = "How far you can swim on your turn. Without a swimming speed, every foot swum costs one foot more.",
    climb = "How far you can climb on your turn. Without a climbing speed, every foot climbed costs one foot more.",
    fly = "How far you can fly on your turn. If you are knocked prone or your speed drops to 0 while in the air, you fall, unless you can hover.",
}

-- A beast's `moves` text names its speeds with these words (Data/BeastPicks.lua).
R.MOVE_WORDS = { swimming = "swim", climbing = "climb", flying = "fly" }

-- What gives a speed equal to the walking speed while the passive of that name is on
-- the sheet and switched on. They are found by name, so a character that had the feat
-- or feature before the sheet kept these speeds has them too. Speeds that last a
-- while (wings for an hour, a rage) are not here: a passive of your own with an
-- effect on that speed, switched on while it lasts, does that.
R.MOVE_GRANTS = {
    ["Athlete"] = { climb = true },
    ["Draconic Flight active"] = { fly = true }, -- switched on by the trait, off by hand or a rest
    ["Child of the Sea"] = { swim = true },
    ["Gift of the Depths"] = { swim = true },
    ["Roving"] = { climb = true, swim = true },
}
