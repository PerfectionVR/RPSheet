-- Beasts of challenge rating 2 to 6, which only a Circle of the Moon druid reaches
-- (form of the entries: see Data/Beasts.lua).
local _, ns = ...
local R = ns.Rules
local B, N = R.BEASTS, R.BEAST_NOTES

local TRAMPLE = "Bonus action. One prone creature within 5 feet makes a DC %d Dexterity save, taking the damage, or half on a success."

-- 2
B["Allosaurus"] = { cr = 2, size = "Large", ac = 13, speed = 60, str = 19, dex = 13, con = 17, senses = {}, skills = { "Perception" },
    attacks = { { "Bite", 6, 2, 10, 4, "piercing" },
        { "Claws", 6, 1, 8, 4, "slashing", "After moving 30 feet straight at a Large or smaller target: it is knocked prone and you can Bite it once." } } }
B["Giant Boar"] = { cr = 2, size = "Large", ac = 13, speed = 40, str = 17, dex = 10, con = 16, senses = {}, skills = {},
    note = "While Bloodied you have advantage on melee attacks.",
    attacks = { { "Gore", 5, 2, 6, 3, "piercing", "After moving 20 feet straight at a Large or smaller target: 2d6 more, and it is knocked prone." } } }
B["Giant Constrictor Snake"] = { cr = 2, size = "Huge", ac = 12, speed = 30, moves = "swimming 30 feet", str = 19, dex = 14, con = 12, senses = { Blindsight = 10 }, skills = { "Perception" },
    note = "One Bite and one Constrict with the Attack action.",
    attacks = { { "Bite", 6, 2, 6, 4, "piercing", reach = 10 },
        { "Constrict", false, 2, 8, 4, "bludgeoning", "One Large or smaller creature you can see within 10 feet makes a DC 14 Strength save. If it fails it takes the damage and is grappled (DC 14 to escape)." } } }
B["Hunter Shark"] = { cr = 2, size = "Large", ac = 12, speed = 5, moves = "swimming 40 feet", str = 18, dex = 14, con = 15, senses = { Blindsight = 60 }, skills = { "Perception" },
    note = N.water,
    attacks = { { "Bite", 6, 3, 6, 4, "piercing", N.wounded } } }
B["Plesiosaurus"] = { cr = 2, size = "Large", ac = 13, speed = 20, moves = "swimming 40 feet", str = 18, dex = 15, con = 16, senses = {}, skills = { "Perception", "Stealth" },
    note = "It holds its breath for an hour.",
    attacks = { { "Bite", 6, 2, 6, 4, "piercing", reach = 10 } } }
B["Polar Bear"] = { cr = 2, size = "Large", ac = 12, speed = 40, moves = "swimming 40 feet", str = 20, dex = 14, con = 16, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    attacks = { { "Rend", 7, 1, 8, 5, "slashing", N.twice } } }
B["Rhinoceros"] = { cr = 2, size = "Large", ac = 13, speed = 40, str = 21, dex = 8, con = 15, senses = {}, skills = {},
    attacks = { { "Gore", 7, 2, 8, 5, "piercing", "After moving 20 feet straight at a Large or smaller target: 2d8 more, and it is knocked prone." } } }
B["Saber-Toothed Tiger"] = { cr = 2, size = "Large", ac = 13, speed = 40, str = 18, dex = 17, con = 15, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.escape .. " With a 10-foot run-up it long jumps 25 feet.",
    attacks = { { "Rend", 6, 2, 6, 4, "slashing", N.twice } } }
B["Swarm of Venomous Snakes"] = { cr = 2, size = "Medium", ac = 14, speed = 30, moves = "swimming 30 feet", str = 8, dex = 18, con = 11, senses = { Blindsight = 10 }, skills = {},
    note = N.swarm,
    attacks = { { "Bites", 6, 1, 8, 4, "piercing", "While you are Bloodied the piercing die is a d4.", plus = { 3, 6, "poison" } } } }

-- 3
B["Ankylosaurus"] = { cr = 3, size = "Huge", ac = 15, speed = 30, str = 19, dex = 11, con = 15, senses = {}, skills = {},
    attacks = { { "Tail", 6, 1, 10, 4, "bludgeoning", "A Huge or smaller target is knocked prone. " .. N.twice, reach = 10 } } }
B["Giant Scorpion"] = { cr = 3, size = "Large", ac = 15, speed = 40, str = 16, dex = 13, con = 15, senses = { Blindsight = 60 }, skills = {},
    note = "Two Claws and one Sting with the Attack action.",
    attacks = { { "Claw", 5, 1, 6, 3, "bludgeoning", "A Large or smaller target is grappled (DC 13 to escape). Each of the two claws can hold one." },
        { "Sting", 5, 1, 8, 3, "piercing", plus = { 2, 10, "poison" } } } }
B["Killer Whale"] = { cr = 3, size = "Huge", ac = 12, speed = 5, moves = "swimming 60 feet", str = 19, dex = 14, con = 13, senses = { Blindsight = 120 }, skills = { "Perception", "Stealth" },
    note = "It holds its breath for 30 minutes.",
    attacks = { { "Bite", 6, 5, 6, 4, "piercing" } } }

-- 4
B["Archelon"] = { cr = 4, size = "Huge", ac = 17, speed = 20, moves = "swimming 80 feet", str = 18, dex = 16, con = 13, senses = {}, skills = { "Stealth" },
    note = N.amphibious,
    attacks = { { "Bite", 6, 3, 6, 4, "piercing", N.twice } } }
B["Elephant"] = { cr = 4, size = "Huge", ac = 12, speed = 40, str = 22, dex = 9, con = 17, senses = {}, skills = {},
    attacks = { { "Gore", 8, 2, 8, 6, "piercing", "After moving 20 feet straight at a Huge or smaller target it is knocked prone. " .. N.twice },
        { "Trample", false, 2, 10, 6, "bludgeoning", TRAMPLE:format(16) } } }
B["Hippopotamus"] = { cr = 4, size = "Large", ac = 14, speed = 30, moves = "swimming 30 feet", str = 21, dex = 7, con = 15, senses = {}, skills = { "Perception" },
    note = "It holds its breath for 10 minutes.",
    attacks = { { "Bite", 7, 2, 10, 5, "piercing", N.twice } } }

-- 5
B["Giant Crocodile"] = { cr = 5, size = "Huge", ac = 14, speed = 30, moves = "swimming 50 feet", str = 21, dex = 9, con = 17, senses = {}, skills = { "Stealth" },
    note = "It holds its breath for an hour. One Bite and one Tail with the Attack action.",
    attacks = { { "Bite", 8, 3, 10, 5, "piercing", "A Large or smaller target is grappled (DC 15 to escape) and restrained while it is; your Tail can't reach it." },
        { "Tail", 8, 3, 8, 5, "bludgeoning", "A Large or smaller target is knocked prone.", reach = 10 } } }
B["Giant Shark"] = { cr = 5, size = "Huge", ac = 13, speed = 5, moves = "swimming 60 feet", str = 23, dex = 11, con = 21, senses = { Blindsight = 60 }, skills = { "Perception" },
    note = N.water,
    attacks = { { "Bite", 9, 3, 10, 6, "piercing", N.wounded .. " " .. N.twice } } }
B["Triceratops"] = { cr = 5, size = "Huge", ac = 14, speed = 50, str = 22, dex = 9, con = 17, senses = {}, skills = {},
    attacks = { { "Gore", 9, 2, 12, 6, "piercing", "After moving 20 feet straight at a Huge or smaller target: 2d8 more, and it is knocked prone. " .. N.twice } } }

-- 6
B["Giant Squid"] = { cr = 6, size = "Huge", ac = 12, speed = 5, moves = "swimming 80 feet", str = 23, dex = 14, con = 12, senses = { Darkvision = 120 }, skills = { "Perception" },
    note = N.water .. " One Bite and one Tentacle with the Attack action. " .. N.ink,
    attacks = { { "Bite", 9, 4, 10, 6, "piercing" },
        { "Tentacle", 9, 3, 8, 6, "bludgeoning", "A Huge or smaller target is grappled (DC 16 to escape) and can be pulled up to 10 feet straight toward you. Each of the two tentacles can hold one.", reach = 15 } } }
B["Mammoth"] = { cr = 6, size = "Huge", ac = 13, speed = 50, str = 24, dex = 9, con = 21, senses = {}, skills = {},
    attacks = { { "Gore", 10, 2, 10, 7, "piercing", "After moving 20 feet straight at a Huge or smaller target it is knocked prone. " .. N.twice, reach = 10 },
        { "Trample", false, 4, 10, 7, "bludgeoning", TRAMPLE:format(18) } } }
