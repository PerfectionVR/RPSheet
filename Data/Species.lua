-- Playable species: size, speed, darkvision and trait names.
local _, ns = ...
local R = ns.Rules

---------------------------------------------------------------------------
-- Species
-- Traits are listed by name and become passives on the sheet. A trait with `effects`
-- changes numbers by itself; the others are reminders to look up in the book.
---------------------------------------------------------------------------
R.SPECIES = {
    DRACTHYR  = { name = "Dracthyr", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Gliding Wings", "Natural Weaponry", "Visage", "Draconic Flight" } },
    DRAENEI   = { name = "Draenei", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Eredar Lineage", "Heroic Presence" } },
    DWARF     = { name = "Dwarf", sizes = { "M" }, speed = 30, darkvision = 120,
                  traits = { "Dwarven Resilience", "Dwarven Toughness", "Stonecunning" },
                  effects = { ["Dwarven Toughness"] = { { target = "HP", flat = 0, stat = "LEVEL", times = 1 } } } },
    EARTHEN   = { name = "Earthen", sizes = { "M" }, speed = 30, darkvision = 120,
                  traits = { "Azerite Surge", "Earthen Resilience", "Ingest Minerals", "Quiet Contemplation" } },
    ELF       = { name = "Elf", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Elven Lineage", "Fey Ancestry", "Keen Senses", "Trance" } },
    FORSAKEN  = { name = "Forsaken", sizes = { "S", "M" }, speed = 30, darkvision = 60,
                  traits = { "Deathly Endurance", "Everlasting", "Touch of the Grave", "Will of the Forsaken" } },
    GNOME     = { name = "Gnome", sizes = { "S" }, speed = 30, darkvision = 60,
                  traits = { "Gnomish Cunning", "Gnomish Lineage" } },
    GOBLIN    = { name = "Goblin", sizes = { "S" }, speed = 30, darkvision = 60,
                  traits = { "Fey Ancestry", "Fury of the Small", "Nimble Escape" } },
    HARANIR   = { name = "Haranir", sizes = { "M" }, speed = 30, darkvision = 120,
                  traits = { "Gift of the World Tree", "Haranir Magic" },
                  skills = { "Nature", "Survival" } }, -- granted by Gift of the World Tree
    HUMAN     = { name = "Human", sizes = { "S", "M" }, speed = 30,
                  traits = { "Resourceful", "Skillful", "Versatile" } },
    MECHAGNOME = { name = "Mechagnome", sizes = { "S" }, speed = 30,
                  traits = { "Built for Success", "Emergency Fail-Safe", "Mechanical Nature", "Sentry's Rest", "Specialized Design" } },
    ORC       = { name = "Orc", sizes = { "M" }, speed = 30, darkvision = 120,
                  traits = { "Adrenaline Rush", "Relentless Endurance" } },
    PANDAREN  = { name = "Pandaren", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Bouncy", "Inner Peace", "Quaking Palm" } },
    TAUREN    = { name = "Tauren", sizes = { "M" }, speed = 30,
                  traits = { "Horns", "Goring Rush", "Hammering Horns", "Tauren Lineage" } },
    TROLL     = { name = "Troll", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Bloodied Frenzy", "Troll Healing", "Troll Lineage" } },
    VULPERA   = { name = "Vulpera", sizes = { "S" }, speed = 30, darkvision = 60,
                  traits = { "Fire Resistance", "Nose for Trouble", "Vulpera Nimbleness" } },
    WORGEN    = { name = "Worgen", sizes = { "M" }, speed = 30, darkvision = 60,
                  traits = { "Darkflight", "Instinctual Shift" } },
}
R.SPECIES_ORDER = {
    "DRACTHYR", "DRAENEI", "DWARF", "EARTHEN", "ELF", "FORSAKEN", "GNOME", "GOBLIN", "HARANIR",
    "HUMAN", "MECHAGNOME", "ORC", "PANDAREN", "TAUREN", "TROLL", "VULPERA", "WORGEN",
}

