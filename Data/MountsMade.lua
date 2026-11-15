-- Mounts that are made or summoned instead of bought: flying carpets, figurines that
-- turn into a creature for some hours, and the steed a spell calls. They are listed in
-- the stable to be added for nothing; the note says how one is come by.
-- (How an entry is written: Data/Mounts.lua.)
local _, ns = ...
local R = ns.Rules

local GROUP = "Made and summoned"
R.MOUNT_GROUPS[#R.MOUNT_GROUPS + 1] = GROUP
R.MOUNT_NAMES[GROUP] = {}

local function Add(name, entry)
    entry.kind, entry.unsold, entry.size = "MOUNT", true, entry.size or "L"
    R.AddMount(GROUP, name, entry)
end

-- Flying carpets: the larger, the slower. `thing`: not an animal, so a rider of any
-- size sits on it and it takes no saddle.
for _, carpet in ipairs({ { "3 by 5 ft", 80, 200 }, { "4 by 6 ft", 60, 400 }, { "5 by 7 ft", 40, 600 }, { "6 by 9 ft", 30, 800 } }) do
    Add(("Carpet of Flying (%s)"):format(carpet[1]), {
        fly = carpet[2], capacity = carpet[3], thing = true,
        desc = "A Very Rare magic carpet: an artisan tailor can make one, or it is found. A Magic action and its command word set it flying, and it goes where you tell it while you are within 30 feet. It lifts up to twice its load, at half its speed.",
    })
end

-- Figurines of wondrous power that can be ridden. The goats and the elephant carry
-- what the rules list for those animals as mounts. For the others no number is
-- listed: `estimate` marks a capacity worked out from the creature's size and
-- Strength (15 pounds a point, doubled for a Large creature), and the note says so.
local FIGURINE = "A %s figurine of wondrous power, found as treasure or made as a magic item. A Magic action throws it down within 60 feet and it becomes %s. It turns back early at 0 hit points or when you say so."
local function Figurine(name, rarity, becomes, entry)
    entry.desc = FIGURINE:format(rarity, becomes) .. (entry.desc and (" " .. entry.desc) or "")
        .. (entry.estimate and (" " .. R.CAPACITY_ESTIMATED) or "")
    Add(name .. " (figurine)", entry)
end
Figurine("Bronze Griffon", "Rare", "a griffon for up to 6 hours, then rests 5 days", { speed = 30, fly = 80, capacity = 540, estimate = true })
Figurine("Ebony Fly", "Rare", "a giant fly for up to 12 hours, then rests 2 days", { speed = 30, fly = 60, capacity = 420, estimate = true })
Figurine("Ivory Goat of Traveling", "Rare", "a large goat as fast as a riding horse", { speed = 60, capacity = 480,
    desc = "It has 24 charges and uses one for each hour or part of an hour as a goat; when they are gone it rests 7 days and has them all back." })
Figurine("Ivory Goat of Travail", "Rare", "a giant goat for up to 3 hours, then rests 30 days", { speed = 40, climb = 30, capacity = 510 })
Figurine("Ivory Goat of Terror", "Rare", "a giant goat for up to 3 hours", { speed = 40, climb = 30, capacity = 510,
    desc = "It can't attack, but its horns come off as magic weapons, and enemies near it take fright while you ride it." })
Figurine("Marble Elephant", "Rare", "an elephant for up to 24 hours, then rests 7 days", { speed = 40, capacity = 1320, size = "H" })
Figurine("Obsidian Steed", "Very Rare", "a nightmare for up to 24 hours, then rests 5 days", { speed = 60, fly = 90, capacity = 540, estimate = true,
    desc = "It fights only to defend itself, and one time in ten it ignores your orders." })
Figurine("Jeweled Panther", "Rare", "a large flying panther for up to 12 hours, then rests 2 days", { speed = 50, climb = 40, fly = 30, capacity = 420, estimate = true,
    desc = "An expert jewelcrafter can make one." })

-- The steed of the Find Steed spell: Large, shaped like an animal of the caster's
-- choice. No rule lists what it carries: the number is that of a Large creature of
-- its Strength (18), and each note says it is an estimate.
local STEED = "Summoned with Find Steed: a loyal otherworldly mount that shares your turn in a fight and stays until it drops to 0 hit points, you die, or you cast the spell again."
local ESTIMATED = " " .. R.CAPACITY_ESTIMATED
Add("Otherworldly Steed", { speed = 60, capacity = 540, desc = STEED .. " Cast with a slot of 4th level or higher it also flies: take the flying one then." .. ESTIMATED })
Add("Otherworldly Steed (flying)", { speed = 60, fly = 60, capacity = 540, desc = STEED .. " This is the steed of a casting with a slot of 4th level or higher." .. ESTIMATED })
Add("Cliffside Wylderdrake", { speed = 60, fly = 60, capacity = 540, renown = { 25, "Valdrakken Accord" }, keep = true,
    desc = "The dragon steed of those Revered by the Valdrakken Accord: their blessing casts Find Steed at 4th level for it. It flies out of an enemy's reach without provoking opportunity attacks." .. ESTIMATED })
Add("Spirit of Eche'ro", { speed = 60, fly = 60, capacity = 540,
    desc = "The spirit of a famed Highmountain moose. An artisan archaeologist pieces six magic fragments from Highmountain tauren dig sites into a staff that casts Find Steed at 4th level to call it." .. ESTIMATED })
