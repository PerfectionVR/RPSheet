-- A Beast Master's primal companion: the three kinds of beast it can be, and the pet
-- families that decide the kind, the specialization and the mastery of its strike.
-- The family is the option picked for the "Primal Companion" feature.
local _, ns = ...
local R = ns.Rules

R.PET_FEATURE = "Primal Companion"

-- Every kind has an Armor Class of 13 plus its master's Wisdom modifier.
-- hp: hit points at level 0 and for each level. die/flat: Beast's Strike damage,
-- before the Wisdom modifier. scores: the beast's own ability scores. charge: the die
-- a strike adds after a 20-foot run, which also knocks prone. grapple: a hit grapples.
R.PET_BLOCKS = {
    Land = { name = "beast of the land", darkvision = 60, hp = 5, die = 8, flat = 2, speed = "40 feet, also climbing", size = "Medium",
        scores = { STR = 14, DEX = 14, CON = 15, INT = 8, WIS = 14, CHA = 11 }, charge = 6,
        strike = "After moving 20 feet straight at the target it deals 1d6 more and knocks a Large or smaller target prone." },
    Sea = { name = "beast of the sea", darkvision = 90, hp = 5, die = 6, flat = 2, speed = "swimming 60 feet, 5 feet on land", size = "Medium",
        scores = { STR = 14, DEX = 14, CON = 15, INT = 8, WIS = 14, CHA = 11 }, grapple = true,
        strike = "The target is grappled; it escapes against your spell save DC. The beast breathes air and water." },
    Sky = { name = "beast of the sky", darkvision = 60, hp = 4, die = 4, flat = 3, speed = "flying 60 feet, 10 feet on the ground", size = "Small",
        scores = { STR = 6, DEX = 16, CON = 13, INT = 8, WIS = 14, CHA = 11 },
        strike = "It doesn't provoke opportunity attacks when it flies out of reach." },
}

-- What is said about a strike's mastery where the weapon wording (Rules.MASTERIES)
-- doesn't fit a beast.
R.PET_MASTERY_NOTES = {
    Push = "On a hit: can push a Large or smaller target 10 feet away",
    Vex = "On a hit: the companion has advantage on its next attack against it",
}

R.PET_SPECS = { C = "Cunning", F = "Ferocity", T = "Tenacity" }

-- family | kind of beast | specialization | mastery of its strike
local DATA = [[
Basilisk|Land|C|Slow
Bat|Sky|F|Vex
Bear|Land|T|Push
Beetle|Land|T|Sap
Bird of Prey|Sky|C|Slow
Blood Beast|Sky|T|Slow
Boar|Land|C|Sap
Camel|Land|C|Push
Carrion Bird|Sky|F|Cleave
Cat|Land|F|Graze
Courser|Land|F|Graze
Crab|Land|T|Slow
Crocolisk|Land|F|Slow
Direhorn|Land|T|Cleave
Dolphin|Sea|T|Vex
Dragonhawk|Sky|T|Graze
Feathermane|Sky|T|Graze
Fox|Land|C|Graze
Frenzy|Sea|F|Cleave
Gorilla|Land|F|Push
Gruffhorn|Land|C|Push
Hopper|Land|T|Graze
Hound|Land|C|Slow
Hydra|Land|T|Cleave
Hyena|Land|C|Cleave
Lizard|Land|T|Cleave
Mammoth|Land|T|Slow
Mechanized Animal|Land|C|Sap
Monkey|Land|C|Graze
Moth|Sky|C|Vex
Oxen|Land|T|Push
Raptor|Land|C|Cleave
Ray|Sky|F|Vex
Riverbeast|Land|T|Cleave
Rodent|Land|C|Cleave
Scalehide|Land|F|Sap
Scorpid|Land|F|Cleave
Serpent|Land|C|Graze
Sea Serpent|Sea|C|Graze
Shark|Sea|C|Graze
Spider|Land|F|Slow
Stag|Land|T|Vex
Tallstrider|Land|F|Slow
Threshadon|Sea|T|Sap
Turtle|Land|T|Sap
Wasp|Sky|F|Cleave
Waterfowl|Land|T|Vex
Wolf|Land|F|Slow
]]

-- Families that need a special ability to tame.
local UNUSUAL = { ["Blood Beast"] = true, Direhorn = true, Feathermane = true, ["Mechanized Animal"] = true, Threshadon = true }

R.PET_FAMILIES, R.PET_FAMILY_ORDER = {}, {}
for line in DATA:gmatch("[^\r\n]+") do
    local name, block, spec, mastery = strsplit("|", line)
    R.PET_FAMILIES[name] = { name = name, block = block, spec = spec, mastery = mastery, unusual = UNUSUAL[name] }
    R.PET_FAMILY_ORDER[#R.PET_FAMILY_ORDER + 1] = name
end

-- The family of the character's companion, or nil when none is picked.
function R.Pet(sheet)
    return R.PET_FAMILIES[(sheet and sheet.featureOptions or {})[R.PET_FEATURE] or ""]
end

-- The kind of beast the character's companion is; a beast of the land until one is picked.
function R.PetBlock(sheet)
    local pet = R.Pet(sheet)
    return R.PET_BLOCKS[pet and pet.block or "Land"]
end

-- Hit points of the companion at a level. A Tenacity pet has more from level 6.
function R.PetHP(sheet, level)
    local block, pet = R.PetBlock(sheet), R.Pet(sheet)
    return block.hp + block.hp * level + ((pet and pet.spec == "T" and level >= 6) and level or 0)
end
