-- The fixed sets of starting gear: what a class and a background hand a new character
-- in place of gold alone (Rules.START_GOLD and Rules.BACKGROUND_GOLD in Data/Coins.lua).
-- items: catalogue names (Data/Gear.lua, Data/GearArms.lua) with ";" between them and
-- "*4" for more than one; gold: gold pieces left over; choices: the things of a kind
-- the set leaves the player to choose (Rules.GEAR_CHOICES), picked on the wizard's
-- last page (Wizard/GearChoices.lua).
local _, ns = ...
local R = ns.Rules

-- The kinds of thing a set lets the player choose one of: named items, or every tool
-- of some kinds (Rules.TOOL_KINDS in Data/Tools.lua).
R.GEAR_CHOICES = {
    HOLY = { name = "Holy symbol", items = { "Amulet", "Emblem", "Reliquary" } },
    INSTRUMENT = { name = "Musical instrument", tools = { INS = true } },
    ARTISAN = { name = "Artisan's tools", tools = { AT = true } },
    GAMING = { name = "Gaming set", tools = { GS = true } },
    CRAFT = { name = "Artisan's tools or instrument", tools = { AT = true, INS = true } },
}

-- One choice of a set. `trained`: the thing chosen is also the tool the class or the
-- background makes the character proficient with, so the choice settles both.
local function Choice(kind, trained)
    return { kind = kind, trained = trained or false }
end
local HOLY, INSTRUMENT, GAMING = { Choice("HOLY") }, { Choice("INSTRUMENT") }, { Choice("GAMING", true) }

-- By the class a class builds on. Most offer one set; a Fighter chooses between two.
R.CLASS_GEAR = {
    Barbarian = { { items = "Greataxe;Handaxe*4;Explorer's Pack", gold = 15 } },
    Bard = { { items = "Leather Armor;Dagger*2;Entertainer's Pack", gold = 19, choices = INSTRUMENT } },
    Cleric = { { items = "Chain Shirt;Shield;Mace;Priest's Pack", gold = 7, choices = HOLY } },
    Druid = { {
        -- The druidic focus is a wooden staff, which is a quarterstaff as well: the set
        -- hands out the weapon, so that it can be readied, and says what else it is.
        items = "Leather Armor;Shield;Sickle;Quarterstaff;Explorer's Pack;Herbalism Kit", gold = 9,
        note = "The Quarterstaff is a wooden staff that doubles as your druidic focus.",
    } },
    Fighter = {
        { label = "Heavy armor and a greatsword", items = "Chain Mail;Greatsword;Flail;Javelin*8;Dungeoneer's Pack", gold = 4 },
        { label = "Light armor, two blades and a longbow", items = "Studded Leather Armor;Scimitar;Shortsword;Longbow;Arrows (20);Quiver;Dungeoneer's Pack", gold = 11 },
    },
    Monk = { { items = "Spear;Dagger*5;Explorer's Pack", gold = 11, choices = { Choice("CRAFT", true) } } },
    Paladin = { { items = "Chain Mail;Shield;Longsword;Javelin*6;Priest's Pack", gold = 9, choices = HOLY } },
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
    ACOLYTE = { items = "Calligrapher's Supplies;Book;Parchment*10;Robe", gold = 8, choices = HOLY, note = "The Book holds prayers." },
    ARTISAN = { items = "Pouch*2;Traveler's Clothes", gold = 32, choices = { Choice("ARTISAN", true) } },
    CHARLATAN = { items = "Forgery Kit;Costume;Fine Clothes", gold = 15 },
    CRIMINAL = { items = "Dagger*2;Thieves' Tools;Crowbar;Pouch*2;Traveler's Clothes", gold = 16 },
    ENTERTAINER = { items = "Costume*2;Mirror;Perfume;Traveler's Clothes", gold = 11, choices = { Choice("INSTRUMENT", true) } },
    FARMER = { items = "Sickle;Carpenter's Tools;Healer's Kit;Iron Pot;Shovel;Traveler's Clothes", gold = 30 },
    GUARD = { items = "Spear;Light Crossbow;Bolts (20);Hooded Lantern;Manacles;Quiver;Traveler's Clothes", gold = 12, choices = GAMING },
    GUIDE = { items = "Shortbow;Arrows (20);Cartographer's Tools;Bedroll;Quiver;Tent;Traveler's Clothes", gold = 3 },
    HERMIT = { items = "Quarterstaff;Herbalism Kit;Bedroll;Book;Lamp;Oil*3;Traveler's Clothes", gold = 16, note = "The Book is about philosophy." },
    MERCHANT = { items = "Navigator's Tools;Pouch*2;Traveler's Clothes", gold = 22 },
    NOBLE = { items = "Fine Clothes;Perfume", gold = 29, choices = GAMING },
    SAGE = { items = "Quarterstaff;Calligrapher's Supplies;Book;Parchment*8;Robe", gold = 8, note = "The Book is about history." },
    SAILOR = { items = "Dagger;Navigator's Tools;Rope;Traveler's Clothes", gold = 20 },
    SCRIBE = { items = "Calligrapher's Supplies;Fine Clothes;Lamp;Oil*3;Parchment*12", gold = 23 },
    SOLDIER = { items = "Spear;Shortbow;Arrows (20);Healer's Kit;Quiver;Traveler's Clothes", gold = 14, choices = GAMING },
    WAYFARER = { items = "Dagger*2;Thieves' Tools;Bedroll;Pouch*2;Traveler's Clothes", gold = 16, choices = { Choice("GAMING") } },
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

-- The catalogue items a kind of choice offers, in the catalogue's order.
function R.GearChoiceNames(kind)
    local choice, names = R.GEAR_CHOICES[kind], {}
    for _, name in ipairs(choice and choice.items or {}) do
        if R.ITEMS[name] then names[#names + 1] = name end
    end
    for _, name in ipairs(choice and choice.tools and R.TOOL_ORDER or {}) do
        if choice.tools[R.TOOLS[name].kind] and R.ITEMS[name] then names[#names + 1] = name end
    end
    return names
end
