-- Subclass features, added to a sheet by subclass and level like the class features
-- in Features.lua. Keyed by the subclass name as listed in Classes.lua.
--
-- Summaries are short and in our own words; features that roll or change numbers are
-- wired up. Not covered: the Death Knight's Oath of the Ebon Blade and the Demon Hunter
-- subclass, which rewrite parts of their base class.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local Passive = Kit.Passive

-- A Passive's description may be a function of the level. Its `extra` table can carry
-- advantage = { ... } (rolls it gives advantage on, by their label on the sheet) and
-- skillChoice (a skill to pick, see Sheet/Maneuvers.lua).
-- Resources a subclass brings, in the same form as class `pools` (see Classes.lua).
R.SUBCLASS_POOLS = {
    ["Battle Master"] = {
        { name = "Superiority Dice", short = "ALL", steps = { { 3, 4 }, { 7, 5 }, { 15, 6 } } },
    },
    ["Warrior of Mystic Brews"] = {
        { name = "Refreshing Dip Dice", from = 6, stat = "WIS", halfLevel = true, min = 1, short = "ALL" },
    },
    ["Soulknife"] = {
        { name = "Psionic Energy Dice", short = 1, steps = { { 3, 4 }, { 5, 6 }, { 9, 8 }, { 13, 10 }, { 17, 12 } } },
    },
}

-- The spells a subclass always has prepared. `byLevel` is { {level, "names"}, ... };
-- without it the passive is a general reminder.
local function AlwaysPrepared(what, byLevel)
    if not byLevel then
        return Passive(3, what .. " Spells", "Your subclass gives you extra spells at certain levels. They are always prepared and don't count against the number you can prepare.")
    end
    return Passive(3, what .. " Spells", function(level)
        local known = {}
        for _, step in ipairs(byLevel) do
            if level >= step[1] then known[#known + 1] = step[2] end
        end
        return "Always prepared, and not counted against the number you can prepare: " .. table.concat(known, ", ")
            .. ". They are on your spell list already."
    end, nil, { prepared = byLevel })
end

-- Filled by the Subclass*.lua files that follow, one per class.
R.SUBCLASS_FEATURES = {}

-- What those files share.
ns.SubclassKit = { AlwaysPrepared = AlwaysPrepared }
