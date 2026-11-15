-- Beasts a druid can know as Wild Shape forms. The beasts themselves are in the
-- Data/BeastsCR*.lua files, by challenge rating; Data/BeastPicks.lua turns them into
-- the "forms" pick list (see Data/Picks.lua) and into forms (see Data/Forms.lua) that
-- are in effect while the passive "<Beast> form" is switched on.
--
-- R.BEASTS[name] = {
--     cr         challenge rating, which decides the druid level that can learn it
--     fly        true if it has a flying speed (never before level 8)
--     size, ac   size and Armor Class
--     speed      walking speed; moves = its other ways of moving
--     str, dex, con   the scores the character takes on
--     senses     { Darkvision = 60, Blindsight = 10 }: ranges in feet
--     skills     skills the beast is proficient in
--     attacks    { { name, attack bonus, dice, sides, flat damage, damage type, note,
--                    plus = { dice, sides, type }   more damage of another type
--                    reach = feet                    when longer than 5 feet
--                    ranged = "25/50" } }            a thrown or shot attack
--                An attack bonus of false is an action without an attack roll, such
--                as one the target saves against; the note says how it works.
--     note       anything else worth knowing
-- }
-- BeastPicks adds level, moonLevel (Circle of the Moon) and desc to each.
local _, ns = ...
local R = ns.Rules

R.BEASTS = {}

-- Riders that many beasts share.
R.BEAST_NOTES = {
    pack = "Advantage on attacks against a creature with one of your allies next to it.",
    agile = "Moving out of an enemy's reach doesn't provoke opportunity attacks.",
    flyby = "Flying out of an enemy's reach doesn't provoke opportunity attacks.",
    water = "It breathes only water.",
    amphibious = "It breathes air and water.",
    swarm = "A swarm: it can share a space with other creatures, fits through any gap one of its animals fits through, and can't regain hit points or gain temporary hit points.",
    escape = "Bonus action: Disengage or Hide.",
    ink = "Once a day it can release a cloud of ink as a reaction.",
    twice = "Two of these with the Attack action: click once for each.",
    wounded = "Advantage if the target is below its full hit points.",
    thinned = "While you are Bloodied, count only one of the two dice.",
    recharge = "Once used, it comes back on a 6 on a d6 rolled at the start of your turn.",
}

-- The name of the passive that marks a beast form as taken.
function R.BeastFormPassive(name)
    return name .. " form"
end
