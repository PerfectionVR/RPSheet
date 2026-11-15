-- What each making profession (Data/Professions.lua) can make out of the item lists
-- (Data/Gear.lua, Data/GearArms.lua, Data/MagicItems.lua), and what making costs.
--   R.RECIPES[<profession key>] = list of { name, level, basic }
-- `level` is the skill it asks for: 2 for plain gear, by rarity for a magic item.
-- `basic` recipes come with the skill; the others have to be learned first, from a
-- trainer, a find or a faction (sheet.recipes).
local _, ns = ...
local R = ns.Rules

-- Plain gear: materials worth half the price, and a day of work per this much price.
R.CRAFT_COPPER_PER_DAY = 1000
-- A magic item, by rarity: days of work and materials in copper. A magic item made
-- from a priced thing costs that thing's full price on top (R.RECIPE_BASE).
R.MAGIC_CRAFT = {
    Common = { days = 5, cost = 5000 }, Uncommon = { days = 10, cost = 20000 },
    Rare = { days = 50, cost = 200000 }, ["Very rare"] = { days = 125, cost = 2000000 },
    Legendary = { days = 250, cost = 10000000 },
}
-- Used up when used: half the time and cost, and nothing to disenchant.
R.CONSUMABLES = { ["Potion of Healing"] = true }
-- Recipes with a time and cost of their own.
R.CRAFT_FIXED = { ["Potion of Healing"] = { days = 1, cost = 2500 } }
-- The priced thing a magic item is made from.
R.RECIPE_BASE = {
    ["+1 Shield"] = "Shield", ["+2 Shield"] = "Shield", ["+3 Shield"] = "Shield", ["Shield of the Cavalier"] = "Shield",
    ["Dragon Scale Mail"] = "Scale Mail", ["Glamoured Studded Leather"] = "Studded Leather Armor",
}
-- Magic items that stand for any weapon or armor: the plain one is paid for apart.
R.RECIPE_OPEN = {}
for bonus = 1, 3 do
    R.RECIPE_OPEN[("+%d Weapon"):format(bonus)] = "the plain weapon"
    R.RECIPE_OPEN[("+%d Armor"):format(bonus)] = "the plain suit of armor"
end

R.RECIPES = {}
-- Adds the listed names (";" between them) that the item lists hold.
local function Add(key, names, basic)
    local list = R.RECIPES[key] or {}
    R.RECIPES[key] = list
    for name in names:gmatch("[^;]+") do
        local item = R.ITEMS[name]
        if item then
            list[#list + 1] = { name = name, level = item.rarity and R.RARITY_LEVEL[item.rarity] or 2, basic = basic }
        end
    end
end

-- Weapons and armor by what they are, so the lists follow the data.
local function Weapons(wanted, except)
    local names = {}
    for _, name in ipairs(R.WEAPON_ORDER) do
        if R.WEAPONS[name].ranged == wanted and not except[name] then names[#names + 1] = name end
    end
    return table.concat(names, ";")
end
local function Armor(kinds, except)
    local names = {}
    for name, key in pairs(R.ARMOR_ITEMS) do
        if kinds[R.ARMOR[key].name:match("%((%a+)%)")] and name ~= except then names[#names + 1] = name end
    end
    table.sort(names)
    return table.concat(names, ";")
end

local ARCANE, DRUIDIC, HOLY = "Crystal;Orb;Rod;Staff;Wand", "Sprig of Mistletoe;Wooden Staff;Yew Wand", "Amulet;Emblem;Reliquary"
-- Magic arms and armor up to rare come with the skill; the very rare ones don't.
local ARMS, ARMS3 = "+1 Weapon;+2 Weapon", "+3 Weapon"

Add("alchemy", "Acid;Alchemist's Fire;Component Pouch;Fuel;Oil;Paper;Perfume;Potion of Healing", true)

Add("blacksmithing", Weapons(false, { Club = true, Greatclub = true, Quarterstaff = true, Whip = true }), true)
Add("blacksmithing", Armor({ medium = true, heavy = true }, "Hide Armor") .. ";Shield", true)
Add("blacksmithing", "Ball Bearings;Block and Tackle;Bucket;Caltrops;Chain;Crowbar;Firearm Bullets (10);Grappling Hook;Iron Pot;Iron Spikes;Sling Bullets (20)", true)
Add("blacksmithing", ARMS .. ";+1 Armor;+1 Shield;+2 Shield", true)
Add("blacksmithing", ARMS3 .. ";+2 Armor;+3 Armor;+3 Shield;Shield of the Cavalier;Dragon Scale Mail;Stone of Good Luck;Bracers of Defense")

Add("cooking", "Antitoxin;Rations", true)

Add("enchanting", "Club;Greatclub;Quarterstaff;" .. Weapons(true, { Musket = true, Pistol = true, Sling = true }), true)
Add("enchanting", "Arrows (20);Bolts (20);Needles (50);Barrel;Chest;Ink Pen;Jug;Ladder;Lamp;Pole;Portable Ram;Torch;" .. ARCANE .. ";" .. DRUIDIC, true)
Add("enchanting", ARMS .. ";+1 Wand of the War Mage;+2 Wand of the War Mage", true)
Add("enchanting", ARMS3 .. ";+3 Wand of the War Mage;+1 Rod of the Pact Keeper;+2 Rod of the Pact Keeper;+3 Rod of the Pact Keeper")

Add("engineering", "Musket;Pistol;Bell;Bullseye Lantern;Flask;Hooded Lantern;Hunting Trap;Lock;Manacles;Mirror;Shovel;Signal Whistle;Tinderbox;" .. ARMS, true)
Add("engineering", ARMS3)

Add("inscription", DRUIDIC .. ";" .. HOLY .. ";Ink;Map", true)
Add("inscription", "Staff of Power")

Add("jewelcrafting", ARCANE .. ";" .. HOLY .. ";Glass Bottle;Magnifying Glass;Spyglass;Vial", true)
Add("jewelcrafting", "Ring of Protection;Ioun Stone of Protection;Scarab of Protection")

Add("leatherworking", "Sling;Whip;Hide Armor;Leather Armor;Studded Leather Armor;Backpack;Climber's Kit;Crossbow Bolt Case;Map or Scroll Case;Parchment;Pouch;Quiver;Waterskin", true)
Add("leatherworking", ARMS .. ";+1 Armor;Glamoured Studded Leather", true)
Add("leatherworking", ARMS3 .. ";+2 Armor;+3 Armor")

Add("tailoring", "Padded Armor;Basket;Bedroll;Blanket;Fine Clothes;Net;Robe;Rope;Sack;String;Tent;Traveler's Clothes;+1 Armor", true)
Add("tailoring", "+2 Armor;+3 Armor;Cloak of Protection;Robe of Stars;Robe of the Archmagi")

-- The recipes that have to be learned, by item name, for the saved list.
R.LEARNED_RECIPES = {}
for _, list in pairs(R.RECIPES) do
    for _, recipe in ipairs(list) do
        if not recipe.basic then R.LEARNED_RECIPES[recipe.name] = true end
    end
end
