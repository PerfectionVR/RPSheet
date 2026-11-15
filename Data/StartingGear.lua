-- The fixed sets of starting gear: what a class and a background hand a new character
-- in place of gold alone (Rules.START_GOLD and Rules.BACKGROUND_GOLD in Data/Coins.lua).
-- items: catalogue names (Data/Gear.lua, Data/GearArms.lua) with ";" between them and
-- "*4" for more than one; gold: gold pieces left over; pick: what the set leaves the
-- player to choose in the closet, as the end of "Still to pick in the closet: ...".
local _, ns = ...
local R = ns.Rules

local HOLY = "a holy symbol (an Amulet, Emblem or Reliquary, under Focuses)"
local INSTRUMENT = "a musical instrument (under Tools)"
local GAMING = "the gaming set you are proficient with (under Tools)"

-- By the class a class builds on. Most offer one set; a Fighter chooses between two.
R.CLASS_GEAR = {
    Barbarian = { { items = "Greataxe;Handaxe*4;Explorer's Pack", gold = 15 } },
    Bard = { { items = "Leather Armor;Dagger*2;Entertainer's Pack", gold = 19, pick = INSTRUMENT } },
    Cleric = { { items = "Chain Shirt;Shield;Mace;Priest's Pack", gold = 7, pick = HOLY } },
    Druid = { {
        items = "Leather Armor;Shield;Sickle;Wooden Staff;Explorer's Pack;Herbalism Kit", gold = 9,
        note = "The Wooden Staff is your druidic focus.",
    } },
    Fighter = {
        { label = "Heavy armor and a greatsword", items = "Chain Mail;Greatsword;Flail;Javelin*8;Dungeoneer's Pack", gold = 4 },
        { label = "Light armor, two blades and a longbow", items = "Studded Leather Armor;Scimitar;Shortsword;Longbow;Arrows (20);Quiver;Dungeoneer's Pack", gold = 11 },
    },
    Monk = { { items = "Spear;Dagger*5;Explorer's Pack", gold = 11, pick = "the artisan's tools or musical instrument you are proficient with (under Tools)" } },
    Paladin = { { items = "Chain Mail;Shield;Longsword;Javelin*6;Priest's Pack", gold = 9, pick = HOLY } },
    Ranger = { {
        items = "Studded Leather Armor;Scimitar;Shortsword;Longbow;Arrows (20);Quiver;Sprig of Mistletoe;Explorer's Pack", gold = 7,
        note = "The Sprig of Mistletoe is your druidic focus.",
    } },
    Rogue = { { items = "Leather Armor;Dagger*2;Shortsword;Shortbow;Arrows (20);Quiver;Thieves' Tools;Burglar's Pack", gold = 8 } },
    Sorcerer = { { items = "Spear;Dagger*2;Crystal;Dungeoneer's Pack", gold = 28, note = "The Crystal is your arcane focus." } },
    Warlock = { { items = "Leather Armor;Sickle;Dagger*2;Orb;Book;Scholar's Pack", gold = 15, note = "The Orb is your arcane focus; the Book holds occult lore." } },
    Wizard = { { items = "Dagger*2;Quarterstaff;Robe;Spellbook;Scholar's Pack", gold = 5, note = "The Quarterstaff doubles as your arcane focus." } },
}

-- By background (Data/Backgrounds.lua).
R.BACKGROUND_GEAR = {
    ACOLYTE = { items = "Calligrapher's Supplies;Book;Parchment*10;Robe", gold = 8, pick = HOLY, note = "The Book holds prayers." },
    ARTISAN = { items = "Pouch*2;Traveler's Clothes", gold = 32, pick = "the artisan's tools you are proficient with (under Tools)" },
    CHARLATAN = { items = "Forgery Kit;Costume;Fine Clothes", gold = 15 },
    CRIMINAL = { items = "Dagger*2;Thieves' Tools;Crowbar;Pouch*2;Traveler's Clothes", gold = 16 },
    ENTERTAINER = { items = "Costume*2;Mirror;Perfume;Traveler's Clothes", gold = 11, pick = "the musical instrument you are proficient with (under Tools)" },
    FARMER = { items = "Sickle;Carpenter's Tools;Healer's Kit;Iron Pot;Shovel;Traveler's Clothes", gold = 30 },
    GUARD = { items = "Spear;Light Crossbow;Bolts (20);Hooded Lantern;Manacles;Quiver;Traveler's Clothes", gold = 12, pick = GAMING },
    GUIDE = { items = "Shortbow;Arrows (20);Cartographer's Tools;Bedroll;Quiver;Tent;Traveler's Clothes", gold = 3 },
    HERMIT = { items = "Quarterstaff;Herbalism Kit;Bedroll;Book;Lamp;Oil*3;Traveler's Clothes", gold = 16, note = "The Book is about philosophy." },
    MERCHANT = { items = "Navigator's Tools;Pouch*2;Traveler's Clothes", gold = 22 },
    NOBLE = { items = "Fine Clothes;Perfume", gold = 29, pick = GAMING },
    SAGE = { items = "Quarterstaff;Calligrapher's Supplies;Book;Parchment*8;Robe", gold = 8, note = "The Book is about history." },
    SAILOR = { items = "Dagger;Navigator's Tools;Rope;Traveler's Clothes", gold = 20 },
    SCRIBE = { items = "Calligrapher's Supplies;Fine Clothes;Lamp;Oil*3;Parchment*12", gold = 23 },
    SOLDIER = { items = "Spear;Shortbow;Arrows (20);Healer's Kit;Quiver;Traveler's Clothes", gold = 14, pick = GAMING },
    WAYFARER = { items = "Dagger*2;Thieves' Tools;Bedroll;Pouch*2;Traveler's Clothes", gold = 16, pick = "a gaming set (under Tools)" },
}

-- A set's items as a list of { name, count }, leaving out anything the catalogue lacks.
function R.GearList(set)
    local list = {}
    for entry in (set.items or ""):gmatch("[^;]+") do
        local name, count = entry:match("^(.-)%*(%d+)$")
        name = strtrim(name or entry)
        if R.ITEMS[name] then list[#list + 1] = { name = name, count = tonumber(count) or 1 } end
    end
    return list
end

-- "Greataxe, Handaxe x4, Explorer's Pack" for a list from R.GearList.
function R.GearText(list)
    local parts = {}
    for _, entry in ipairs(list) do
        parts[#parts + 1] = entry.count > 1 and ("%s x%d"):format(entry.name, entry.count) or entry.name
    end
    return table.concat(parts, ", ")
end
