-- Renown that follows from a rule instead of from the DM's word, and the factions a
-- character can't both rise with. Sheet/RenownRules.lua works the scores out.
local _, ns = ...
local R = ns.Rules

-- A stronghold in a faction's lands adds this to the score while it stands there.
R.STRONGHOLD_RENOWN = 1
-- Where a stronghold counts for each faction that has such lands.
R.STRONGHOLD_LANDS = {
    ["Darnassus"] = "Darnassus or Teldrassil, or later Bel'ameth or Amirdrassil",
    ["Exodar"] = "the Exodar, the Vindicaar or the Azuremyst Isles",
    ["Gilneas"] = "anywhere in Gilneas",
    ["Gnomeregan"] = "Gnomeregan, New Tinkertown or Mechagon Island",
    ["Ironforge"] = "Ironforge or elsewhere in Khaz Modan (not a gnome settlement), around Aerie Peak, or Shadowforge City",
    ["Stormwind"] = "Stormwind City, Elwynn Forest, Westfall, Stromgarde or Kul Tiras",
    ["Bilgewater Cartel"] = "Bilgewater Harbor or another holding of the cartel",
    ["Darkspear Tribe"] = "the Echo Isles or Zandalar",
    ["Orgrimmar"] = "Orgrimmar or elsewhere in Durotar (not the Echo Isles)",
    ["Silvermoon City"] = "Silvermoon City or elsewhere in Quel'Thalas, or Suramar",
    ["Thunder Bluff"] = "Thunder Bluff or elsewhere in Mulgore, or Highmountain",
    ["Undercity"] = "the Undercity or the Ruins of Lordaeron",
}

-- What the faction a species starts with gains for each other faction of its side that
-- has reached a tier. The gains add up: a faction at Honored has given 1 + 2.
R.SIDE_RENOWN_GAIN = { Friendly = 1, Honored = 2, Revered = 3, Exalted = 5 }

-- What a faction's merchants take off their prices from Honored on: percent, and the
-- highest rarity of magic item the discount covers. It is for everyday equipment and
-- those magic items; the player says whose merchant is selling (Sheet/Shop.lua).
R.RENOWN_DISCOUNT = { Honored = { 10, "Uncommon" }, Revered = { 15, "Rare" }, Exalted = { 25, "Very rare" } }
-- Not everyday equipment: fuel is a thing of this world's engineers, and a spell
-- component is named by what it is worth, so a cheaper one would not do.
R.NO_DISCOUNT_ITEMS = { ["Fuel"] = true }
R.NO_DISCOUNT_KINDS = { ["Spell components"] = true }
-- The mounts, vehicles and ships that are everyday equipment. The ones a faction
-- breeds or builds for itself keep their price.
R.DISCOUNT_RIDES = {}
for _, name in ipairs({
    "Camel", "Draft Horse", "Elephant", "Mastiff", "Mule", "Pony", "Riding Horse", "Warhorse",
    "Carriage", "Cart", "Chariot", "Sled", "Wagon",
    "Airship", "Galley", "Keelboat", "Longship", "Rowboat", "Sailing Ship", "Warship",
}) do
    R.DISCOUNT_RIDES[name] = true
end

-- Rivals: a character rises with one of the pair, never with both.
R.RIVAL_FACTIONS = { { "Explorers' League", "Reliquary" } }
