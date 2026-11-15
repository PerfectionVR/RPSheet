-- Beasts of challenge rating 0 (form of the entries: see Data/Beasts.lua).
local _, ns = ...
local R = ns.Rules
local B, N = R.BEASTS, R.BEAST_NOTES

B["Baboon"] = { cr = 0, size = "Small", ac = 12, speed = 30, moves = "climbing 30 feet", str = 8, dex = 14, con = 11, senses = {}, skills = {},
    note = N.pack,
    attacks = { { "Bite", 1, 1, 4, -1, "piercing" } } }
B["Badger"] = { cr = 0, size = "Tiny", ac = 11, speed = 20, moves = "burrowing 5 feet", str = 10, dex = 11, con = 16, senses = { Darkvision = 30 }, skills = { "Perception" },
    attacks = { { "Bite", 2, 0, 4, 1, "piercing" } } }
B["Bat"] = { cr = 0, fly = true, size = "Tiny", ac = 12, speed = 5, moves = "flying 30 feet", str = 2, dex = 15, con = 8, senses = { Blindsight = 60 }, skills = {},
    attacks = { { "Bite", 4, 0, 4, 1, "piercing" } } }
B["Cat"] = { cr = 0, size = "Tiny", ac = 12, speed = 40, moves = "climbing 40 feet", str = 3, dex = 15, con = 10, senses = { Darkvision = 60 }, skills = { "Perception", "Stealth" },
    note = "Its jumps go by Dexterity instead of Strength.",
    attacks = { { "Scratch", 4, 0, 4, 1, "slashing" } } }
B["Crab"] = { cr = 0, size = "Tiny", ac = 11, speed = 20, moves = "swimming 20 feet", str = 6, dex = 11, con = 12, senses = { Blindsight = 30 }, skills = { "Stealth" },
    note = N.amphibious,
    attacks = { { "Claw", 2, 0, 4, 1, "bludgeoning" } } }
B["Deer"] = { cr = 0, size = "Medium", ac = 13, speed = 50, str = 11, dex = 16, con = 11, senses = { Darkvision = 60 }, skills = { "Perception" },
    note = N.agile,
    attacks = { { "Ram", 2, 1, 4, 0, "bludgeoning" } } }
B["Eagle"] = { cr = 0, fly = true, size = "Small", ac = 12, speed = 10, moves = "flying 60 feet", str = 6, dex = 15, con = 12, senses = {}, skills = { "Perception" },
    attacks = { { "Talons", 4, 1, 4, 2, "slashing" } } }
B["Frog"] = { cr = 0, size = "Tiny", ac = 11, speed = 20, moves = "swimming 20 feet", str = 1, dex = 13, con = 8, senses = { Darkvision = 30 }, skills = { "Perception", "Stealth" },
    note = N.amphibious .. " It long jumps 10 feet and high jumps 5 feet, even from a standstill.",
    attacks = { { "Bite", 3, 0, 4, 1, "piercing" } } }
B["Giant Fire Beetle"] = { cr = 0, size = "Small", ac = 13, speed = 30, moves = "climbing 30 feet", str = 8, dex = 10, con = 12, senses = { Blindsight = 30 }, skills = {},
    note = "It glows: bright light for 10 feet around it and dim light for 10 feet beyond.",
    attacks = { { "Bite", 1, 0, 4, 1, "fire" } } }
B["Goat"] = { cr = 0, size = "Medium", ac = 10, speed = 40, moves = "climbing 30 feet", str = 11, dex = 10, con = 11, senses = { Darkvision = 60 }, skills = { "Perception" },
    attacks = { { "Ram", 2, 0, 4, 1, "bludgeoning", "After moving 20 feet straight at the target the damage is 1d4 instead." } } }
B["Hawk"] = { cr = 0, fly = true, size = "Tiny", ac = 13, speed = 10, moves = "flying 60 feet", str = 5, dex = 16, con = 8, senses = {}, skills = { "Perception" },
    attacks = { { "Talons", 5, 0, 4, 1, "slashing" } } }
B["Hyena"] = { cr = 0, size = "Medium", ac = 11, speed = 50, str = 11, dex = 13, con = 12, senses = { Darkvision = 60 }, skills = { "Perception" },
    note = N.pack,
    attacks = { { "Bite", 2, 1, 6, 0, "piercing" } } }
B["Jackal"] = { cr = 0, size = "Small", ac = 12, speed = 40, str = 8, dex = 15, con = 11, senses = { Darkvision = 90 }, skills = { "Perception", "Stealth" },
    attacks = { { "Bite", 1, 1, 4, -1, "piercing" } } }
B["Lizard"] = { cr = 0, size = "Tiny", ac = 10, speed = 20, moves = "climbing 20 feet, also on ceilings", str = 2, dex = 11, con = 10, senses = { Darkvision = 30 }, skills = {},
    attacks = { { "Bite", 2, 0, 4, 1, "piercing" } } }
B["Octopus"] = { cr = 0, size = "Small", ac = 12, speed = 5, moves = "swimming 30 feet", str = 4, dex = 15, con = 11, senses = { Darkvision = 30 }, skills = { "Perception", "Stealth" },
    note = N.water .. " It squeezes through gaps an inch wide at no cost. " .. N.ink,
    attacks = { { "Tentacles", 4, 0, 4, 1, "bludgeoning" } } }
B["Owl"] = { cr = 0, fly = true, size = "Tiny", ac = 11, speed = 5, moves = "flying 60 feet", str = 3, dex = 13, con = 8, senses = { Darkvision = 120 }, skills = { "Perception", "Stealth" },
    note = N.flyby,
    attacks = { { "Talons", 3, 0, 4, 1, "slashing" } } }
B["Piranha"] = { cr = 0, size = "Tiny", ac = 13, speed = 5, moves = "swimming 40 feet", str = 2, dex = 16, con = 9, senses = { Darkvision = 60 }, skills = {},
    note = N.water,
    attacks = { { "Bite", 5, 0, 4, 1, "piercing", N.wounded } } }
B["Rat"] = { cr = 0, size = "Tiny", ac = 10, speed = 20, moves = "climbing 20 feet", str = 2, dex = 11, con = 9, senses = { Darkvision = 30 }, skills = { "Perception" },
    note = N.agile,
    attacks = { { "Bite", 2, 0, 4, 1, "piercing" } } }
B["Raven"] = { cr = 0, fly = true, size = "Tiny", ac = 12, speed = 10, moves = "flying 50 feet", str = 2, dex = 14, con = 10, senses = {}, skills = { "Perception" },
    note = "It can mimic simple sounds it has heard.",
    attacks = { { "Beak", 4, 0, 4, 1, "piercing" } } }
B["Scorpion"] = { cr = 0, size = "Tiny", ac = 11, speed = 10, str = 2, dex = 11, con = 8, senses = { Blindsight = 10 }, skills = {},
    attacks = { { "Sting", 2, 0, 4, 1, "piercing", plus = { 1, 6, "poison" } } } }
B["Seahorse"] = { cr = 0, size = "Tiny", ac = 12, speed = 5, moves = "swimming 20 feet", str = 1, dex = 12, con = 8, senses = {}, skills = { "Perception", "Stealth" },
    note = N.water .. " It has no attack. As an action underwater it swims its speed without provoking opportunity attacks.",
    attacks = {} }
B["Spider"] = { cr = 0, size = "Tiny", ac = 12, speed = 20, moves = "climbing 20 feet, also on ceilings and webs", str = 2, dex = 14, con = 8, senses = { Darkvision = 30 }, skills = { "Stealth" },
    note = "It knows where anything touching the web it is on is.",
    attacks = { { "Bite", 4, 0, 4, 1, "piercing", plus = { 1, 4, "poison" } } } }
B["Vulture"] = { cr = 0, fly = true, size = "Medium", ac = 10, speed = 10, moves = "flying 50 feet", str = 7, dex = 10, con = 13, senses = {}, skills = { "Perception" },
    note = N.pack,
    attacks = { { "Beak", 2, 1, 4, 0, "piercing" } } }
B["Weasel"] = { cr = 0, size = "Tiny", ac = 13, speed = 30, moves = "climbing 30 feet", str = 3, dex = 16, con = 8, senses = { Darkvision = 60 }, skills = { "Acrobatics", "Perception", "Stealth" },
    attacks = { { "Bite", 5, 0, 4, 1, "piercing" } } }
