-- The animals and machines a character can buy to ride: price in gold, speed in feet,
-- pounds carried, and a note in our own words (see Rules.AddRide in Data/Mounts.lua).
-- Many are only sold to those in good standing with the faction that breeds them.
local _, ns = ...
local R = ns.Rules
local Ride = R.AddRide

-- Ordinary animals, sold anywhere.
Ride("Camel", 50, 50, 450, "A desert animal that goes a long way on little water.")
Ride("Draft Horse", 50, 40, 540, "A heavy horse bred to pull and to carry.")
Ride("Elephant", 200, 40, 1320, "Carries more than any other animal for sale, and is big enough for a Large rider.", { size = "H" })
Ride("Mastiff", 25, 40, 195, "A big dog. Only a Small rider fits on it.", { size = "M" })
Ride("Mule", 8, 40, 420, "Cheap, sure-footed and stubborn. Only a Small rider fits on it; anyone can load it.", { size = "M" })
Ride("Pony", 30, 40, 225, "A small horse for a Small rider.", { size = "M" })
Ride("Riding Horse", 75, 60, 480, "The everyday mount: fast and easy to keep.")
Ride("Giant Seahorse", 1000, 5, 450, "A mount for under water. On land it barely moves.", { swim = 40 })
Ride("Talbuk", 150, 50, 480, "A horned, deer-like runner from the plains of Outland.")
Ride("Zhevra", 200, 50, 480, "A striped horse of the Barrens with a single horn.")

-- Sold to the Honored (renown 10) of a faction.
Ride("Dire Wolf", 750, 50, 510, "The war wolf of the orcs.", { renown = { 10, "Orgrimmar" } })
Ride("Elekk", 400, 40, 510, "The tusked riding beast of the draenei. It climbs well.", { climb = 30, renown = { 10, "Exodar" } })
Ride("Giant Goat", 400, 40, 510, "The mountain ram of the dwarves. It climbs well.", { climb = 30, renown = { 10, "Ironforge" } })
Ride("Giant Hyena", 750, 50, 480, "A desert hunter the goblins of the cartel sell.", { renown = { 10, "Steamwheedle Cartel" } })
Ride("Hawkstrider", 150, 50, 420, "The tall, bright bird the blood elves ride.", { renown = { 10, "Silvermoon City" } })
Ride("Kodo", 100, 40, 450, "The great lizard of the tauren: mount and beast of burden. It climbs as fast as it walks.", { climb = 40, renown = { 10, "Thunder Bluff" } })
Ride("Mechanostrider", 450, 60, 420, "A two-legged gnomish walking machine.", { renown = { 10, "Gnomeregan" } })
Ride("Nightsaber", 750, 40, 510, "The great cat of the night elves.", { renown = { 10, "Darnassus" } })
Ride("Pandarian Dragon Turtle", 500, 30, 480, "Slow on land, quick in the water.", { swim = 60, renown = { 10, "Huojin", "Tushui" } })
Ride("Raptor", 1000, 60, 570, "The hunting lizard of the trolls.", { renown = { 10, "Darkspear Tribe" } })
Ride("Warhorse", 400, 60, 540, "A horse trained for battle.", { renown = { 10, "Stormwind" } })
Ride("Warhorse Skeleton", 500, 60, 540, "A dead horse that still runs for the Forsaken.", { renown = { 10, "Undercity" } })

-- Flying mounts, sold to the Revered (renown 25) of a side.
Ride("Gryphon", 2000, 30, 540, "The flying mount of the Alliance.", { fly = 80, renown = { 25, "ALLIANCE" } })
Ride("Wind Rider", 2000, 10, 450, "The flying mount of the Horde. It is clumsy on the ground.", { fly = 60, renown = { 25, "HORDE" } })
-- Every other capacity here is the listed one. This one is not listed anywhere; it is
-- what a Large creature of its Strength (17) carries, and the note says so.
Ride("Cenarion War Hippogryph", 2000, 40, 510, "Sold only to the Exalted of the Cenarion Circle. It stops obeying you if your renown there drops below 50. " .. R.CAPACITY_ESTIMATED,
    { fly = 60, renown = { 50, "Cenarion Circle" }, keep = true })
