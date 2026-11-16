-- Professions: gathering materials and making things. A character has no list of
-- professions to pick from: it can practise each one whose tool (or skill) it is
-- proficient with, and its skill at all of them is its proficiency bonus.
--   R.PROFESSIONS[<key>] = {
--     name, kind   "gather" or "make"
--     tools        the kinds of tools that open it: proficiency with any one will do
--     skill        or the skill that opens it (archaeology); `free` needs nothing
--     yields       the material a gathering profession brings in (R.MATERIALS)
--     uses         the materials a making profession can pay with before coins
--     word         what its recipes are called
--     desc         a summary in our own words
--     makes        by skill level, what else the level opens that the item lists
--                  don't hold (Data/Recipes.lua has the items the sheet can make)
--   }
local _, ns = ...
local R = ns.Rules

-- Skill by proficiency bonus, and the rarest magic item that skill can make.
R.PROFESSION_LEVELS = {
    [2] = { name = "Apprentice", rarity = "Common" }, [3] = { name = "Journeyman", rarity = "Uncommon" },
    [4] = { name = "Expert", rarity = "Rare" }, [5] = { name = "Artisan", rarity = "Very rare" },
    [6] = { name = "Master", rarity = "Legendary" },
}
R.RARITY_LEVEL = { Common = 2, Uncommon = 3, Rare = 4, ["Very rare"] = 5, Legendary = 6 }

-- Where the gathering happens: the levels a region (or, for skinning, the creature's
-- challenge rating) is meant for, the DC, and what one find is worth in copper.
R.REGIONS = {
    { name = "levels 1-4", top = 4, dc = 10, common = 1000, rare = 2500 },
    { name = "levels 5-10", top = 10, dc = 12, common = 5000, rare = 10000 },
    { name = "levels 11-16", top = 16, dc = 15, common = 25000, rare = 50000 },
    { name = "levels 17-20", top = 20, dc = 17, common = 100000, rare = 250000 },
    { name = "endgame", top = 99, dc = 20, common = 500000, rare = 750000 },
}
R.RARE_FIND_MARGIN = 5 -- beating the DC by this much finds something rare

-- Materials are kept as a worth in copper per kind, not as named herbs and ores.
R.MATERIALS = {
    herbs = "Herbs", ore = "Ore, stone and gems", leather = "Leather and hide",
    fish = "Fish", cloth = "Cloth", residue = "Magical residue",
}
R.MATERIAL_ORDER = { "herbs", "ore", "leather", "fish", "cloth", "residue" }

-- Archaeology.
R.RELIC_FRAGMENTS, R.RELIC_DC, R.FRAGMENT_DIE = 6, 15, 6
-- Where the table trains to gain levels: days per point of the new bonus, and copper a day.
R.TRAINING_COPPER_PER_DAY = 200
-- Enchanting: taking the magic out of an item, from this skill up. By the item's
-- rarity: the skill needed and the worth of the residue.
R.DISENCHANT_LEVEL = 3
R.DISENCHANT = {
    Common = { level = 3, worth = 2500 }, Uncommon = { level = 4, worth = 10000 },
    Rare = { level = 5, worth = 100000 }, ["Very rare"] = { level = 6, worth = 1000000 },
}
-- Cooking: the great feast an artisan cook can lay out in an hour.
R.FEAST_LEVEL, R.FEAST_COST = 5, 100000

R.PROFESSIONS, R.PROFESSION_ORDER = {}, {}
local function Profession(key, name, kind, entry)
    entry.key, entry.name, entry.kind = key, name, kind
    entry.tab = { name = entry.short or name, profession = entry } -- its tab in the crafting window
    R.PROFESSIONS[key] = entry
    R.PROFESSION_ORDER[#R.PROFESSION_ORDER + 1] = key
end

Profession("archaeology", "Archaeology", "gather", { skill = "History",
    desc = "An hour at a dig site and an Intelligence (History) check unearths 1d6 fragments. Beating the DC by 5 finds a whole relic, worth a rare find there; a natural 20 finds a magic fragment. Six fragments of one origin make a relic with a DC 15 History check; six magic fragments make a magic item the DM chooses, as rare as your skill allows. The DM says where the dig sites are." })
Profession("fishing", "Fishing", "gather", { free = true, yields = "fish",
    desc = "Mostly a way to forage for food on the road. Looking for a particular fish is a Wisdom (Survival) check, once per stretch of a journey. On a natural 20 the DM may let you pull up a crate worth a rare find." })
Profession("herbalism", "Herbalism", "gather", { tools = { "Herbalism Kit" }, yields = "herbs",
    desc = "Herbs, flowers and mushrooms, mostly for alchemy and inscription. A Wisdom (Survival) check once per stretch of a journey: one find per day of it, and one of them rare when you beat the DC by 5." })
Profession("mining", "Mining", "gather", { tools = { "Mason's Tools" }, yields = "ore",
    desc = "Ores, stones and gems, mostly for blacksmithing, engineering and jewelcrafting. A Wisdom (Survival) check once per stretch of a journey: one find per day of it, and one of them rare when you beat the DC by 5. Where the DM uses named ores, smelting them at a forge takes an hour per 10 gp of worth." })
Profession("skinning", "Skinning", "gather", { tools = { "Leatherworker's Tools" }, yields = "leather",
    desc = "Ten minutes with a dead beast or beastlike monster and a Wisdom (Survival) check with your tools; the DC goes by the creature's challenge rating. Success gives leather worth a common find, beating the DC by 5 a hide worth a rare one. A beastlike fiend needs journeyman skill, a dragon artisan skill; either gives a hide." })

Profession("alchemy", "Alchemy", "make", { tools = { "Alchemist's Supplies", "Herbalism Kit" }, uses = { "herbs" }, word = "recipes",
    desc = "Potions, oils, dusts and perfumes, mostly from herbs.",
    makes = { [2] = "common potions, a bewitching perfume", [3] = "uncommon potions, dusts and ointments", [4] = "rare potions",
        [5] = "very rare potions", [6] = "legendary potions, the strongest glue and its solvent" } })
Profession("blacksmithing", "Blacksmithing", "make", { short = "Smithing", tools = { "Mason's Tools", "Smith's Tools" }, uses = { "ore" }, word = "plans",
    desc = "Things of metal and stone: melee weapons, medium and heavy armor, shields and ironware.",
    makes = { [2] = "common magic arms and armor of those kinds", [3] = "uncommon ones, helms, gauntlets and sending stones",
        [4] = "rare ones, belts and bracers", [5] = "very rare ones", [6] = "legendary ones" } })
Profession("cooking", "Cooking", "make", { tools = { "Brewer's Supplies", "Cook's Utensils" }, uses = { "fish", "herbs" }, word = "recipes",
    desc = "Food and drink, from fish, herbs and game. The Chef feat stands for higher skill.",
    makes = { [2] = "a few common magic trinkets for the table", [5] = "a great feast: an hour and 1,000 gp of ingredients for the effect of Heroes' Feast" } })
Profession("enchanting", "Enchanting", "make", { tools = { "Carpenter's Tools", "Potter's Tools", "Woodcarver's Tools" }, uses = { "residue" }, word = "formulas",
    desc = "Wooden and ranged weapons, ammunition, wands and rods, mostly from the residue of disenchanted items.",
    makes = { [2] = "common wands and magic ammunition", [3] = "uncommon wands, rods and enspelled gear, and disenchanting",
        [4] = "rare ones", [5] = "very rare ones", [6] = "legendary ones" } })
Profession("engineering", "Engineering", "make", { tools = { "Tinker's Tools" }, uses = { "ore" }, word = "schematics",
    desc = "Gadgets and firearms: part mundane science, part magic. Making the bolts and powders is part of each schematic.",
    makes = { [2] = "common clockwork trinkets", [3] = "a three-wheeled trike, goggles, lanterns", [4] = "a flying machine or a motorcycle, a jetpack",
        [5] = "very rare firearms", [6] = "legendary firearms and devices" } })
Profession("inscription", "Inscription", "make", { tools = { "Calligrapher's Supplies", "Cartographer's Tools", "Painter's Supplies" }, uses = { "herbs" }, word = "techniques",
    desc = "Inks, maps, scrolls and staffs. Milling herbs into pigment is part of each technique. The Inscription Adept feat adds to it.",
    makes = { [2] = "common scrolls and staffs", [3] = "uncommon ones, a deck of illusions", [4] = "rare ones",
        [5] = "very rare ones, manuals and tomes", [6] = "legendary ones" } })
Profession("jewelcrafting", "Jewelcrafting", "make", { short = "Jewels", tools = { "Glassblower's Tools", "Jeweler's Tools" }, uses = { "ore" }, word = "designs",
    desc = "Jewelry, glass and lenses, from metals and gems.",
    makes = { [3] = "uncommon rings, amulets, circlets and periapts", [4] = "rare rings, figurines and orbiting stones",
        [5] = "very rare ones, a crystal ball", [6] = "legendary ones" } })
Profession("leatherworking", "Leatherworking", "make", { short = "Leather", tools = { "Cobbler's Tools", "Leatherworker's Tools" }, uses = { "leather" }, word = "patterns",
    desc = "Light armor and hide armor, slings and whips, packs and cases, mostly from what skinning brings in.",
    makes = { [2] = "common magic leather goods", [3] = "uncommon ones, boots, bracers and saddles", [4] = "rare ones",
        [5] = "very rare ones", [6] = "legendary ones" } })
Profession("tailoring", "Tailoring", "make", { tools = { "Weaver's Tools" }, uses = { "cloth" }, word = "patterns",
    desc = "Cloth goods: padded armor, clothes, rope and tents. Cloth is bought or found, not gathered.",
    makes = { [2] = "common cloaks, hats and clothes", [3] = "uncommon cloaks, bags and gloves", [4] = "rare cloaks and robes",
        [5] = "very rare robes, a flying carpet", [6] = "legendary robes and cloaks" } })

-- A faction that halves the time of one making profession at Honored says so in its
-- perk text (Data/FactionPerks.lua): [faction] = profession key.
R.PROFESSION_HASTE = {}
for faction, perks in pairs(R.FACTION_PERKS or {}) do
    local name = perks.Honored and perks.Honored.text:match("^(%a+) takes you half the time")
    for key, profession in pairs(R.PROFESSIONS) do
        if profession.name == name then R.PROFESSION_HASTE[faction] = key end
    end
end
