-- Allegiance, languages and renown.
local _, ns = ...
local R = ns.Rules

R.ALLEGIANCES = { ALLIANCE = "Alliance", HORDE = "Horde", NEUTRAL = "Unaffiliated" }
R.ALLEGIANCE_ORDER = { "ALLIANCE", "HORDE", "NEUTRAL" }

---------------------------------------------------------------------------
-- Languages: your side's common tongue plus two from its list.
-- Unaffiliated characters pick three from either list.
---------------------------------------------------------------------------
R.COMMON_LANGUAGE = { ALLIANCE = "Common", HORDE = "Orcish" }
R.LANGUAGE_PICKS = 2
R.LANGUAGES = {
    ALLIANCE = { "Common", "Common Sign Language", "Darnassian", "Draconic", "Draenei", "Dwarven", "Gnomish", "Hara'ni", "Pandaren", "Thalassian" },
    HORDE = { "Orcish", "Orcish Sign Language", "Draconic", "Forsaken", "Goblin", "Hara'ni", "Pandaren", "Shalassian", "Taur-ahe", "Thalassian", "Vulpera", "Zandali" },
    -- Secret or otherworldly; normally learned through a feature, not picked at creation.
    RARE = { "Cyphers of the First Ones", "Druidic", "Eredun", "Furbolg", "Kalimag", "Nathrezim", "Nazja", "Nerglish", "Nerubian", "Ogre", "Qiraji", "Shath'Yar", "Thieves' Cant", "Titan", "Vrykul" },
}

-- Every language once, in a stable order.
R.ALL_LANGUAGES = {}
do
    local seen = {}
    for _, group in ipairs({ "ALLIANCE", "HORDE", "RARE" }) do
        for _, language in ipairs(R.LANGUAGES[group]) do
            if not seen[language] then
                seen[language] = true
                table.insert(R.ALL_LANGUAGES, language)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Renown: standing with a faction, from 0 upwards
---------------------------------------------------------------------------
R.RENOWN_TIERS = { { 50, "Exalted" }, { 25, "Revered" }, { 10, "Honored" }, { 3, "Friendly" } }
R.STARTING_RENOWN = 3

R.FACTIONS = {
    ALLIANCE = { "Darnassus", "Exodar", "Gilneas", "Gnomeregan", "Ironforge", "Obsidian Warders", "Stormwind", "Tushui" },
    HORDE = { "Bilgewater Cartel", "Dark Talons", "Darkspear Tribe", "Huojin", "Orgrimmar", "Silvermoon City", "Thunder Bluff", "Undercity" },
    OTHER = { "Argent Dawn", "Cenarion Circle", "Earthen Ring", "Explorers' League", "Reliquary", "Kirin Tor", "Steamwheedle Cartel", "Valdrakken Accord" },
}
R.ALL_FACTIONS = {}
for _, group in ipairs({ "ALLIANCE", "HORDE", "OTHER" }) do
    for _, faction in ipairs(R.FACTIONS[group]) do table.insert(R.ALL_FACTIONS, faction) end
end

-- Subfaction a species starts with renown in. A table gives one per allegiance;
-- elves, draenei, tauren and trolls get theirs from their lineage instead.
R.SPECIES_RENOWN = {
    DRACTHYR = { ALLIANCE = "Obsidian Warders", HORDE = "Dark Talons" },
    DWARF = "Ironforge",
    FORSAKEN = "Undercity",
    GNOME = "Gnomeregan",
    GOBLIN = "Bilgewater Cartel",
    HUMAN = "Stormwind",
    ORC = "Orgrimmar",
    PANDAREN = { ALLIANCE = "Tushui", HORDE = "Huojin" },
    VULPERA = "Orgrimmar",
    WORGEN = "Gilneas",
}
-- Taking these classes raises renown with an order.
R.CLASS_RENOWN = { DRUID = "Cenarion Circle", MAGE = "Kirin Tor", SHAMAN = "Earthen Ring" }

-- "Honored" for 12, "" below Friendly.
function R.RenownTier(score)
    for _, tier in ipairs(R.RENOWN_TIERS) do
        if score >= tier[1] then return tier[2] end
    end
    return ""
end
