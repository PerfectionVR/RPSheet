-- Beasts of challenge rating 1/8 and 1/4 (form of the entries: see Data/Beasts.lua).
local _, ns = ...
local R = ns.Rules
local B, N = R.BEASTS, R.BEAST_NOTES

-- 1/8
B["Blood Hawk"] = { cr = 1 / 8, fly = true, size = "Small", ac = 12, speed = 10, moves = "flying 60 feet", str = 6, dex = 14, con = 10, senses = {}, skills = { "Perception" },
    note = N.pack,
    attacks = { { "Beak", 4, 1, 4, 2, "piercing", "Against a Bloodied target the die is a d8." } } }
B["Camel"] = { cr = 1 / 8, size = "Large", ac = 10, speed = 50, str = 15, dex = 8, con = 17, senses = { Darkvision = 60 }, skills = {},
    attacks = { { "Bite", 4, 1, 4, 2, "bludgeoning" } } }
B["Giant Crab"] = { cr = 1 / 8, size = "Medium", ac = 15, speed = 30, moves = "swimming 30 feet", str = 13, dex = 13, con = 11, senses = { Blindsight = 30 }, skills = { "Stealth" },
    note = N.amphibious,
    attacks = { { "Claw", 3, 1, 6, 1, "bludgeoning", "A Medium or smaller target is grappled (DC 11 to escape). Each of the two claws can hold one." } } }
B["Giant Rat"] = { cr = 1 / 8, size = "Small", ac = 13, speed = 30, moves = "climbing 30 feet", str = 7, dex = 16, con = 11, senses = { Darkvision = 60 }, skills = { "Perception" },
    note = N.pack,
    attacks = { { "Bite", 5, 1, 4, 3, "piercing" } } }
B["Giant Weasel"] = { cr = 1 / 8, size = "Medium", ac = 13, speed = 40, moves = "climbing 30 feet", str = 11, dex = 17, con = 10, senses = { Darkvision = 60 }, skills = { "Acrobatics", "Perception", "Stealth" },
    attacks = { { "Bite", 5, 1, 4, 3, "piercing" } } }
B["Mastiff"] = { cr = 1 / 8, size = "Medium", ac = 12, speed = 40, str = 13, dex = 14, con = 12, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Bite", 3, 1, 6, 1, "piercing", "A Medium or smaller target is knocked prone." } } }
B["Mule"] = { cr = 1 / 8, size = "Medium", ac = 10, speed = 40, str = 14, dex = 10, con = 13, senses = {}, skills = {},
    note = "It carries as much as a creature one size larger.",
    attacks = { { "Hooves", 4, 1, 4, 2, "bludgeoning" } } }
B["Pony"] = { cr = 1 / 8, size = "Medium", ac = 10, speed = 40, str = 15, dex = 10, con = 13, senses = {}, skills = {},
    attacks = { { "Hooves", 4, 1, 4, 2, "bludgeoning" } } }
B["Venomous Snake"] = { cr = 1 / 8, size = "Tiny", ac = 12, speed = 30, moves = "swimming 30 feet", str = 2, dex = 15, con = 11, senses = { Blindsight = 10 }, skills = {},
    attacks = { { "Bite", 4, 1, 4, 2, "piercing", plus = { 1, 6, "poison" } } } }

-- 1/4
B["Boar"] = { cr = 1 / 4, size = "Medium", ac = 11, speed = 40, str = 13, dex = 11, con = 14, senses = {}, skills = {},
    note = "While Bloodied you have advantage on attacks.",
    attacks = { { "Gore", 3, 1, 6, 1, "piercing", "After moving 20 feet straight at a Medium or smaller target: 1d6 more, and it is knocked prone." } } }
B["Constrictor Snake"] = { cr = 1 / 4, size = "Large", ac = 13, speed = 30, moves = "swimming 30 feet", str = 15, dex = 14, con = 12, senses = { Blindsight = 10 }, skills = { "Perception", "Stealth" },
    attacks = { { "Bite", 4, 1, 8, 2, "piercing" },
        { "Constrict", false, 3, 4, 0, "bludgeoning", "One Medium or smaller creature you can see within 5 feet makes a DC 12 Strength save. If it fails it takes the damage and is grappled (DC 12 to escape)." } } }
B["Draft Horse"] = { cr = 1 / 4, size = "Large", ac = 10, speed = 40, str = 18, dex = 10, con = 15, senses = {}, skills = {},
    attacks = { { "Hooves", 6, 1, 4, 4, "bludgeoning" } } }
B["Elk"] = { cr = 1 / 4, size = "Large", ac = 10, speed = 50, str = 16, dex = 10, con = 11, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Ram", 5, 1, 6, 3, "bludgeoning", "After moving 20 feet straight at a Large or smaller target: 1d6 more, and it is knocked prone." } } }
B["Giant Badger"] = { cr = 1 / 4, size = "Medium", ac = 13, speed = 30, moves = "burrowing 10 feet", str = 13, dex = 10, con = 17, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Bite", 3, 2, 4, 1, "piercing" } } }
B["Giant Bat"] = { cr = 1 / 4, fly = true, size = "Large", ac = 13, speed = 10, moves = "flying 60 feet", str = 15, dex = 16, con = 11, senses = { Blindsight = 120 }, skills = {},
    attacks = { { "Bite", 5, 1, 6, 3, "piercing" } } }
B["Giant Centipede"] = { cr = 1 / 4, size = "Small", ac = 14, speed = 30, moves = "climbing 30 feet", str = 5, dex = 14, con = 12, senses = { Blindsight = 30 }, skills = {},
    attacks = { { "Bite", 4, 1, 4, 2, "piercing", "The target is poisoned until the start of your next turn." } } }
B["Giant Frog"] = { cr = 1 / 4, size = "Medium", ac = 11, speed = 30, moves = "swimming 30 feet", str = 12, dex = 13, con = 11, senses = { Darkvision = 30 }, skills = { "Perception", "Stealth" },
    note = N.amphibious .. " It long jumps 20 feet and high jumps 10 feet, even from a standstill.",
    attacks = { { "Bite", 3, 1, 6, 2, "piercing", "A Medium or smaller target is grappled (DC 11 to escape)." },
        { "Swallow", false, 2, 4, 0, "acid", "You swallow a Small or smaller creature you are grappling: it is blinded and restrained inside, and you can't Bite. At the end of your next turn it takes the damage and, if it lives, is spat out prone." } } }
B["Giant Lizard"] = { cr = 1 / 4, size = "Large", ac = 12, speed = 40, moves = "climbing 40 feet, also on ceilings", str = 15, dex = 12, con = 13, senses = { Darkvision = 60 }, skills = {},
    attacks = { { "Bite", 4, 1, 8, 2, "piercing" } } }
B["Giant Venomous Snake"] = { cr = 1 / 4, size = "Medium", ac = 14, speed = 40, moves = "swimming 40 feet", str = 10, dex = 18, con = 13, senses = { Blindsight = 10 }, skills = { "Perception" },
    attacks = { { "Bite", 6, 1, 4, 4, "piercing", reach = 10, plus = { 1, 8, "poison" } } } }
B["Giant Wolf Spider"] = { cr = 1 / 4, size = "Medium", ac = 13, speed = 40, moves = "climbing 40 feet, also on ceilings", str = 12, dex = 16, con = 13, senses = { Blindsight = 10, Darkvision = 60 }, skills = { "Perception", "Stealth" },
    attacks = { { "Bite", 5, 1, 4, 3, "piercing", plus = { 2, 4, "poison" } } } }
B["Panther"] = { cr = 1 / 4, size = "Medium", ac = 13, speed = 50, moves = "climbing 40 feet", str = 14, dex = 16, con = 10, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.escape,
    attacks = { { "Rend", 5, 1, 6, 3, "slashing" } } }
B["Pteranodon"] = { cr = 1 / 4, fly = true, size = "Medium", ac = 13, speed = 10, moves = "flying 60 feet", str = 12, dex = 15, con = 10, senses = {}, skills = { "Perception" },
    note = N.flyby,
    attacks = { { "Bite", 4, 1, 8, 2, "piercing" } } }
B["Riding Horse"] = { cr = 1 / 4, size = "Large", ac = 11, speed = 60, str = 16, dex = 13, con = 12, senses = {}, skills = {},
    attacks = { { "Hooves", 5, 1, 8, 3, "bludgeoning" } } }
B["Swarm of Bats"] = { cr = 1 / 4, fly = true, size = "Large", ac = 12, speed = 5, moves = "flying 30 feet", str = 5, dex = 15, con = 10, senses = { Blindsight = 60 }, skills = {},
    note = N.swarm,
    attacks = { { "Bites", 4, 2, 4, 0, "piercing", N.thinned } } }
B["Swarm of Rats"] = { cr = 1 / 4, size = "Medium", ac = 10, speed = 30, moves = "climbing 30 feet", str = 9, dex = 11, con = 9, senses = { Darkvision = 30 }, skills = {},
    note = N.swarm,
    attacks = { { "Bites", 2, 2, 4, 0, "piercing", N.thinned } } }
B["Swarm of Ravens"] = { cr = 1 / 4, fly = true, size = "Medium", ac = 12, speed = 10, moves = "flying 50 feet", str = 6, dex = 14, con = 12, senses = {}, skills = { "Perception" },
    note = N.swarm,
    attacks = { { "Beaks", 4, 1, 6, 2, "piercing", "Only 1d4, with nothing added, while you are Bloodied." },
        { "Cacophony", false, 0, 4, 0, "no", "One creature in your space makes a DC 10 Wisdom save. If it fails it is deafened until the start of your next turn, with disadvantage on ability checks and attacks while it is. " .. N.recharge } } }
B["Wolf"] = { cr = 1 / 4, size = "Medium", ac = 12, speed = 40, str = 14, dex = 15, con = 12, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = N.pack,
    attacks = { { "Bite", 4, 1, 6, 2, "piercing", "A Medium or smaller target is knocked prone." } } }
