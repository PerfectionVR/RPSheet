-- The creature templates (Data/Creatures.lua) sorted into groups, for the list a
-- session's owner adds from: by type (as the creature's facts have it), by people, by
-- side, and by challenge. People and side are our own sorting by name: a creature in
-- neither list goes under "Others".
--   R.CREATURE_GROUPINGS = { { key, name, tip }, ... }
--   R.CreatureGroups(key) = { { name, list = { <creature name>, ... } }, ... }
local _, ns = ...
local R = ns.Rules

local PEOPLE = {
    { "Demons", "Doomguard", "Fel Imp", "Felguard", "Felhound", "Immol'thar", "Infernal", "Pit Lord", "Shivarra", "Voidcaller", "Voidwalker" },
    { "Satyrs", "Alzzin the Wildshaper", "Felsworn Satyr", "Shadowstalker Satyr" },
    { "Nerubians", "Anub'arak", "Hadronox", "Krik'thir the Gatewatcher", "Nerubian Crypt Fiend", "Nerubian Venomancer", "Nerubian Warrior" },
    { "Naga", "Lady Sarevess", "Naga Myrmidon", "Naga Sea Witch", "Naga Siren" },
    { "Murlocs", "Gelihast", "Murloc Forager", "Murloc Oracle" },
    { "Ogres", "Cho'Rush the Observer", "Foreman Rhahk'Zor", "King Gordok" },
    { "Humans", "Anduin Wrynn", "Arcanist Doan", "Edwin VanCleef", "High Inquisitor Sally Whitemane", "Houndmaster Loksey", "Jaina Proudmoore",
        "Scarlet Champion Herod", "Scarlet Commander Mograine" },
    { "Elves", "Alleria Windrunner", "Illidan Stormrage", "Prince Tortheldrin" },
    { "Orcs", "Thrall", "Twilight Lord Kelris" },
    { "Goblins", "Captain Greenskin", "Gilnid", "Sneed's Shredder" },
    { "Furbolgs", "Furbolg Totemic", "Furbolg Ursa" },
    { "Faceless", "N'raqi Faceless General", "N'raqi Faceless One" },
}

local SIDES = {
    { "Burning Legion", "Alzzin the Wildshaper", "Doomguard", "Fel Imp", "Felguard", "Felhound", "Felsworn Satyr", "Immol'thar", "Infernal", "Pit Lord",
        "Shadowstalker Satyr", "Shivarra", "Voidcaller", "Voidwalker" },
    { "Scourge", "Abomination", "Anub'arak", "Krik'thir the Gatewatcher", "Lich King Arthas", "Nerubian Crypt Fiend", "Pustulant Monstrosity" },
    { "Scarlet Crusade", "Arcanist Doan", "Bloodmage Thalnos", "High Inquisitor Sally Whitemane", "Houndmaster Loksey", "Scarlet Champion Herod",
        "Scarlet Commander Mograine" },
    { "Shadowfang Keep", "Baron Ashbury", "Baron Silverlaine", "Commander Springvale", "Lord Godfrey", "Lord Walden", "Springvale's Specter" },
    { "Defias Brotherhood", "Captain Greenskin", "Edwin VanCleef", "Foreman Rhahk'Zor", "Gilnid", "Sneed's Shredder" },
    { "Old Gods", "Aku'mai", "N'raqi Faceless General", "N'raqi Faceless One", "Twilight Lord Kelris" },
    { "Azjol-Nerub", "Hadronox", "Nerubian Venomancer", "Nerubian Warrior" },
    { "Naga", "Lady Sarevess", "Naga Myrmidon", "Naga Sea Witch", "Naga Siren" },
    { "Dire Maul", "Cho'Rush the Observer", "Illyanna Ravenoak", "King Gordok", "Prince Tortheldrin" },
    { "Alliance", "Alleria Windrunner", "Anduin Wrynn", "Jaina Proudmoore", "Mechanostrider" },
    { "Horde", "Sylvanas Windrunner", "Thrall" },
    { "The wilds", "Ancient of War", "Furbolg Totemic", "Furbolg Ursa", "Gelihast", "Ghamoo-Ra", "Moonkin", "Murloc Forager", "Murloc Oracle",
        "Pandarian Dragon Turtle", "Quilboar Thornweaver" },
}

local TIERS = { { 4, "Challenge 0 to 4" }, { 10, "Challenge 5 to 10" }, { 16, "Challenge 11 to 16" }, { 99, "Challenge 17 and up" } }

R.CREATURE_GROUPINGS = {
    { key = "kind", name = "Type", tip = "What kind of creature it is: beast, dragon, undead and so on." },
    { key = "people", name = "People", tip = "The people or brood it belongs to." },
    { key = "side", name = "Side", tip = "Who it stands or is found with." },
    { key = "challenge", name = "Challenge", tip = "How dangerous it is." },
}

-- A lookup from a list of { group, name, name, ... }; `order` gets the groups' names.
local function Lookup(lists, order)
    local of = {}
    for _, list in ipairs(lists) do
        order[#order + 1] = list[1]
        for index = 2, #list do of[list[index]] = list[1] end
    end
    return of
end

local function Flight(name)
    return name:find(" Dragonflight ", 1, true) and true or false
end

local peopleOrder, sideOrder = {}, {}
local people, side = Lookup(PEOPLE, peopleOrder), Lookup(SIDES, sideOrder)

local GROUP_OF = {
    kind = function(creature) return (creature.kind:gsub("^%l", string.upper)) end,
    people = function(creature)
        if Flight(creature.name) then return "Dragons" end
        return people[creature.name] or (creature.kind == "undead" and "Undead") or "Others"
    end,
    side = function(creature)
        if Flight(creature.name) then return "Dragonflights" end
        return side[creature.name] or "Others"
    end,
    challenge = function(creature)
        for _, tier in ipairs(TIERS) do
            if creature.challenge <= tier[1] then return tier[2] end
        end
    end,
}

-- The order the groups come in: as listed above where they are, by name otherwise,
-- "Others" last.
local function Rank(key)
    local rank = {}
    local order = key == "people" and peopleOrder or key == "side" and sideOrder or nil
    if key == "challenge" then
        for index, tier in ipairs(TIERS) do rank[tier[2]] = index end
    elseif order then
        rank[key == "people" and "Dragons" or "Dragonflights"] = 0
        for index, name in ipairs(order) do rank[name] = index end
        rank["Undead"] = #order + 1
    end
    rank["Others"] = 1000
    return rank
end

local built = {}
function R.CreatureGroups(key)
    if built[key] then return built[key] end
    local of, groups, byName = GROUP_OF[key] or GROUP_OF.kind, {}, {}
    for _, name in ipairs(R.CREATURE_ORDER) do
        local group = of(R.CREATURES[name])
        if not byName[group] then
            byName[group] = { name = group, list = {} }
            groups[#groups + 1] = byName[group]
        end
        table.insert(byName[group].list, name)
    end
    local rank = Rank(key)
    table.sort(groups, function(a, b)
        local ra, rb = rank[a.name] or 500, rank[b.name] or 500
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)
    built[key] = groups
    return groups
end
