-- Spell scrolls: what scribing one takes, by the spell's level, and the numbers a
-- scroll that was found (not scribed by its reader) casts with. A scroll is an item
-- named after its spell, "Spell Scroll: Fireball" (Sheet/Scribing.lua).
local _, ns = ...
local R = ns.Rules

R.SCROLL_PREFIX = "Spell Scroll: "
-- Scribing takes proficiency in this skill, or with a scribe's tools.
R.SCRIBE_SKILL = "Arcana"

-- [spell level] = days of eight hours' work and cost in copper.
R.SCROLL_COSTS = {
    [0] = { days = 1, cost = 1500 }, { days = 1, cost = 2500 }, { days = 3, cost = 10000 }, { days = 5, cost = 15000 },
    { days = 10, cost = 100000 }, { days = 25, cost = 150000 }, { days = 40, cost = 1000000 }, { days = 50, cost = 1250000 },
    { days = 60, cost = 1500000 }, { days = 120, cost = 5000000 },
}
-- What a scroll is worth, in copper: twice what scribing it costs.
function R.ScrollValue(level)
    return 2 * R.SCROLL_COSTS[math.max(0, math.min(9, level or 0))].cost
end
-- [spell level] = how rare the scroll is, which is the skill a scribe's tools ask for.
R.SCROLL_RARITY = {
    [0] = "Common", "Common", "Uncommon", "Uncommon", "Rare", "Rare", "Very rare", "Very rare", "Very rare", "Legendary",
}
-- [spell level] = { save DC, attack bonus } of a scroll someone else wrote.
R.SCROLL_FOUND = {
    [0] = { 13, 5 }, { 13, 5 }, { 13, 5 }, { 15, 7 }, { 15, 7 }, { 17, 9 }, { 17, 9 }, { 18, 10 }, { 18, 10 }, { 19, 11 },
}
