-- Beasts of challenge rating 1/2 and 1 (form of the entries: see Data/Beasts.lua).
local _, ns = ...
local R = ns.Rules
local B, N = R.BEASTS, R.BEAST_NOTES

-- 1/2
B["Ape"] = { cr = 1 / 2, size = "Medium", ac = 12, speed = 30, moves = "climbing 30 feet", str = 16, dex = 14, con = 14, senses = {}, skills = { "Athletics", "Perception" },
    attacks = { { "Fist", 5, 1, 4, 3, "bludgeoning", N.twice },
        { "Rock", 5, 2, 6, 3, "bludgeoning", N.recharge, ranged = "25/50" } } }
B["Black Bear"] = { cr = 1 / 2, size = "Medium", ac = 11, speed = 30, moves = "climbing and swimming 30 feet", str = 15, dex = 12, con = 14, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Rend", 4, 1, 6, 2, "slashing", N.twice } } }
B["Crocodile"] = { cr = 1 / 2, size = "Large", ac = 12, speed = 20, moves = "swimming 30 feet", str = 15, dex = 10, con = 13, senses = {}, skills = { "Stealth" },
    note = "It holds its breath for an hour.",
    attacks = { { "Bite", 4, 1, 8, 2, "piercing", "A Medium or smaller target is grappled (DC 12 to escape) and restrained while it is." } } }
B["Giant Goat"] = { cr = 1 / 2, size = "Large", ac = 11, speed = 40, moves = "climbing 30 feet", str = 17, dex = 13, con = 12, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Ram", 5, 1, 6, 3, "bludgeoning", "After moving 20 feet straight at a Large or smaller target: 2d4 more, and it is knocked prone." } } }
B["Giant Seahorse"] = { cr = 1 / 2, size = "Large", ac = 14, speed = 5, moves = "swimming 40 feet", str = 15, dex = 12, con = 11, senses = {}, skills = {},
    note = N.water .. " Bonus action underwater: swim half its speed without provoking opportunity attacks.",
    attacks = { { "Ram", 4, 2, 6, 2, "bludgeoning", "After moving 20 feet straight at the target the dice are d8s." } } }
B["Giant Wasp"] = { cr = 1 / 2, fly = true, size = "Medium", ac = 13, speed = 10, moves = "flying 50 feet", str = 10, dex = 14, con = 10, senses = {}, skills = {},
    note = N.flyby,
    attacks = { { "Sting", 4, 1, 6, 2, "piercing", plus = { 2, 4, "poison" } } } }
B["Pandarian Dragon Turtle"] = { cr = 1 / 2, size = "Large", ac = 17, speed = 30, moves = "swimming 60 feet", str = 16, dex = 12, con = 15, senses = { Darkvision = 60 }, skills = {},
    note = N.amphibious,
    attacks = { { "Bite", 5, 1, 8, 3, "piercing", "A Large or smaller target is grappled (DC 13 to escape)." } } }
B["Reef Shark"] = { cr = 1 / 2, size = "Medium", ac = 12, speed = 5, moves = "swimming 30 feet", str = 14, dex = 15, con = 13, senses = { Blindsight = 30 }, skills = { "Perception" },
    note = N.water .. " " .. N.pack,
    attacks = { { "Bite", 4, 2, 4, 2, "piercing" } } }
B["Swarm of Insects"] = { cr = 1 / 2, size = "Medium", ac = 11, speed = 20, moves = "climbing 20 feet, also on ceilings (a swarm that flies 20 feet instead waits for level 8)", str = 3, dex = 13, con = 14, senses = { Blindsight = 30 }, skills = {},
    note = N.swarm,
    attacks = { { "Bites", 3, 2, 4, 1, "poison", N.thinned } } }
B["Warhorse"] = { cr = 1 / 2, size = "Large", ac = 11, speed = 60, str = 18, dex = 12, con = 13, senses = {}, skills = {},
    attacks = { { "Hooves", 6, 2, 4, 4, "bludgeoning", "After moving 20 feet straight at a Large or smaller target: 2d4 more, and it is knocked prone." } } }

-- 1
B["Brown Bear"] = { cr = 1, size = "Large", ac = 11, speed = 40, moves = "climbing 30 feet", str = 17, dex = 12, con = 15, senses = { Darkvision = 60 }, skills = { "Perception" },
    note = "One Bite and one Claw with the Attack action.",
    attacks = { { "Bite", 5, 1, 8, 3, "piercing" }, { "Claw", 5, 1, 4, 3, "slashing", "A Large or smaller target is knocked prone." } } }
B["Dire Wolf"] = { cr = 1, size = "Large", ac = 14, speed = 50, str = 17, dex = 15, con = 15, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.pack,
    attacks = { { "Bite", 5, 1, 10, 3, "piercing", "A Large or smaller target is knocked prone." } } }
B["Giant Hyena"] = { cr = 1, size = "Large", ac = 12, speed = 50, str = 16, dex = 14, con = 14, senses = { Darkvision = 60 }, skills = { "Perception" },
    note = "Once a day, as a bonus action right after damaging a creature that was already Bloodied: move up to half your speed and Bite once.",
    attacks = { { "Bite", 5, 2, 6, 3, "piercing" } } }
B["Giant Octopus"] = { cr = 1, size = "Large", ac = 11, speed = 10, moves = "swimming 60 feet", str = 17, dex = 13, con = 13, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.water .. " Out of water it holds its breath for an hour. " .. N.ink,
    attacks = { { "Tentacles", 5, 2, 6, 3, "bludgeoning", "A Medium or smaller target is grappled (DC 13 to escape) and restrained while it is. It takes all eight tentacles, so one target at a time.", reach = 10 } } }
B["Giant Spider"] = { cr = 1, size = "Large", ac = 14, speed = 30, moves = "climbing 30 feet, also on ceilings and webs", str = 14, dex = 16, con = 12, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = "It knows where anything touching the web it is on is.",
    attacks = { { "Bite", 5, 1, 8, 3, "piercing", plus = { 2, 6, "poison" } },
        { "Web", false, 0, 4, 0, "no", "One creature you can see within 60 feet makes a DC 13 Dexterity save or is restrained until the web is destroyed (Armor Class 10, 5 hit points, weak to fire). Once used, it comes back on a 5 or 6 on a d6 rolled at the start of your turn." } } }
B["Giant Toad"] = { cr = 1, size = "Large", ac = 11, speed = 30, moves = "swimming 30 feet", str = 15, dex = 13, con = 13, senses = { Darkvision = 60 }, skills = {},
    note = N.amphibious .. " It long jumps 20 feet and high jumps 10 feet, even from a standstill.",
    attacks = { { "Bite", 4, 1, 6, 2, "piercing", "A Medium or smaller target is grappled (DC 12 to escape).", plus = { 2, 4, "poison" } },
        { "Swallow", false, 3, 6, 0, "acid", "You swallow a Medium or smaller creature you are grappling: it is blinded and restrained inside and takes the damage at the end of each of your turns. One at a time, and you can't Bite meanwhile." } } }
B["Lion"] = { cr = 1, size = "Large", ac = 12, speed = 50, str = 17, dex = 15, con = 11, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.pack .. " With a 10-foot run-up it long jumps 25 feet.",
    attacks = { { "Rend", 5, 1, 8, 3, "slashing", "Two of these with the Attack action, or one and a Roar." },
        { "Roar", false, 0, 4, 0, "no", "One creature within 15 feet makes a DC 11 Wisdom save or is frightened until the start of your next turn." } } }
B["Swarm of Piranhas"] = { cr = 1, size = "Medium", ac = 13, speed = 5, moves = "swimming 40 feet", str = 13, dex = 16, con = 9, senses = { Darkvision = 60 }, skills = {},
    note = N.water .. " " .. N.swarm,
    attacks = { { "Bites", 5, 2, 4, 3, "piercing", N.wounded .. " " .. N.thinned } } }
B["Tiger"] = { cr = 1, size = "Large", ac = 13, speed = 40, str = 17, dex = 16, con = 14, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.escape,
    attacks = { { "Rend", 5, 2, 6, 3, "slashing", "A Large or smaller target is knocked prone." } } }
