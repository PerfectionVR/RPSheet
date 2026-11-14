-- Tools: the kits, artisan's tools, instruments and gaming sets a character can be
-- proficient with, and the ability a check with each normally uses.
-- A class or background that names its tool grants it; one that lets the player choose
-- ("any artisan's tool") is ticked by hand under Customize, Proficiencies.
local _, ns = ...
local R = ns.Rules

R.TOOL_KINDS = { T = "Kit", AT = "Artisan's tools", INS = "Instrument", GS = "Gaming set" }

-- name | kind | ability
local DATA = [[
Disguise Kit|T|CHA
Forgery Kit|T|DEX
Herbalism Kit|T|INT
Navigator's Tools|T|WIS
Poisoner's Kit|T|INT
Thieves' Tools|T|DEX
Alchemist's Supplies|AT|INT
Brewer's Supplies|AT|INT
Calligrapher's Supplies|AT|DEX
Carpenter's Tools|AT|STR
Cartographer's Tools|AT|WIS
Cobbler's Tools|AT|DEX
Cook's Utensils|AT|WIS
Glassblower's Tools|AT|INT
Jeweler's Tools|AT|INT
Leatherworker's Tools|AT|DEX
Mason's Tools|AT|STR
Painter's Supplies|AT|WIS
Potter's Tools|AT|INT
Smith's Tools|AT|STR
Tinker's Tools|AT|DEX
Weaver's Tools|AT|DEX
Woodcarver's Tools|AT|DEX
Bagpipes|INS|CHA
Drum|INS|CHA
Dulcimer|INS|CHA
Flute|INS|CHA
Horn|INS|CHA
Lute|INS|CHA
Lyre|INS|CHA
Pan Flute|INS|CHA
Shawm|INS|CHA
Viol|INS|CHA
Dice Set|GS|WIS
Dragonchess Set|GS|WIS
Playing Cards|GS|WIS
Three-Dragon Ante Set|GS|WIS
]]

R.TOOLS, R.TOOL_ORDER = {}, {}
for line in DATA:gmatch("[^\r\n]+") do
    local name, kind, stat = strsplit("|", line)
    R.TOOLS[name] = { name = name, kind = kind, stat = stat }
    R.TOOL_ORDER[#R.TOOL_ORDER + 1] = name
end

-- Tools a class gives, by Player's Handbook class. (A Monk chooses one artisan's tool
-- or instrument: ticked by hand.)
R.CLASS_TOOLS = {
    Druid = { "Herbalism Kit" },
    Rogue = { "Thieves' Tools" },
}

-- The tool a background gives, by background key. Artisan, Entertainer, Guard, Noble
-- and Soldier let the player choose one of a kind: ticked by hand.
R.BACKGROUND_TOOLS = {
    ACOLYTE = "Calligrapher's Supplies", CHARLATAN = "Forgery Kit", CRIMINAL = "Thieves' Tools",
    FARMER = "Carpenter's Tools", GUIDE = "Cartographer's Tools", HERMIT = "Herbalism Kit",
    MERCHANT = "Navigator's Tools", SAGE = "Calligrapher's Supplies", SAILOR = "Navigator's Tools",
    SCRIBE = "Calligrapher's Supplies", WAYFARER = "Thieves' Tools",
}
R.BACKGROUND_TOOL_CHOICE = {
    ARTISAN = "one kind of artisan's tools", ENTERTAINER = "one musical instrument",
    GUARD = "one gaming set", NOBLE = "one gaming set", SOLDIER = "one gaming set",
}
