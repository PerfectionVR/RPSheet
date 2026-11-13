-- Player's Handbook backgrounds and the origin feats that change numbers.
local _, ns = ...
local R = ns.Rules

---------------------------------------------------------------------------
-- Backgrounds (Player's Handbook): three abilities to raise, two skills, an origin feat
---------------------------------------------------------------------------
R.BACKGROUNDS = {
    ACOLYTE     = { name = "Acolyte",     stats = { "INT", "WIS", "CHA" }, skills = { "Insight", "Religion" },            feat = "Magic Initiate (Cleric)" },
    ARTISAN     = { name = "Artisan",     stats = { "STR", "DEX", "INT" }, skills = { "Investigation", "Persuasion" },    feat = "Crafter" },
    CHARLATAN   = { name = "Charlatan",   stats = { "DEX", "CON", "CHA" }, skills = { "Deception", "Sleight of Hand" },   feat = "Skilled" },
    CRIMINAL    = { name = "Criminal",    stats = { "DEX", "CON", "INT" }, skills = { "Sleight of Hand", "Stealth" },     feat = "Alert" },
    ENTERTAINER = { name = "Entertainer", stats = { "STR", "DEX", "CHA" }, skills = { "Acrobatics", "Performance" },      feat = "Musician" },
    FARMER      = { name = "Farmer",      stats = { "STR", "CON", "WIS" }, skills = { "Animal Handling", "Nature" },      feat = "Tough" },
    GUARD       = { name = "Guard",       stats = { "STR", "INT", "WIS" }, skills = { "Athletics", "Perception" },        feat = "Alert" },
    GUIDE       = { name = "Guide",       stats = { "DEX", "CON", "WIS" }, skills = { "Stealth", "Survival" },            feat = "Magic Initiate (Druid)" },
    HERMIT      = { name = "Hermit",      stats = { "CON", "WIS", "CHA" }, skills = { "Medicine", "Religion" },           feat = "Healer" },
    MERCHANT    = { name = "Merchant",    stats = { "CON", "INT", "CHA" }, skills = { "Animal Handling", "Persuasion" },  feat = "Lucky" },
    NOBLE       = { name = "Noble",       stats = { "STR", "INT", "CHA" }, skills = { "History", "Persuasion" },          feat = "Skilled" },
    SAGE        = { name = "Sage",        stats = { "CON", "INT", "WIS" }, skills = { "Arcana", "History" },              feat = "Magic Initiate (Wizard)" },
    SAILOR      = { name = "Sailor",      stats = { "STR", "DEX", "WIS" }, skills = { "Acrobatics", "Perception" },       feat = "Tavern Brawler" },
    SCRIBE      = { name = "Scribe",      stats = { "DEX", "INT", "WIS" }, skills = { "Investigation", "Perception" },    feat = "Skilled" },
    SOLDIER     = { name = "Soldier",     stats = { "STR", "DEX", "CON" }, skills = { "Athletics", "Intimidation" },      feat = "Savage Attacker" },
    WAYFARER    = { name = "Wayfarer",    stats = { "DEX", "WIS", "CHA" }, skills = { "Insight", "Stealth" },             feat = "Lucky" },
}
R.BACKGROUND_ORDER = {
    "ACOLYTE", "ARTISAN", "CHARLATAN", "CRIMINAL", "ENTERTAINER", "FARMER", "GUARD", "GUIDE",
    "HERMIT", "MERCHANT", "NOBLE", "SAGE", "SAILOR", "SCRIBE", "SOLDIER", "WAYFARER",
}
-- Origin feats that change numbers by themselves.
R.FEAT_EFFECTS = {
    Tough = { { target = "HP", flat = 0, stat = "LEVEL", times = 2 } },
    Alert = { { target = "INIT", flat = 0, stat = "PROF", times = 1 } },
}

