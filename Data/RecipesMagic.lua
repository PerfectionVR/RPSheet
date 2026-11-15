-- The rest of what each making profession can make (Data/Recipes.lua has the plain
-- gear and the first magic items): every magic item of the lists, put with the
-- profession and skill that makes it. Potions, wands, weapons, armor and scrolls up
-- to rare come with the skill; everything else is a recipe to be learned.
local _, ns = ...
local R = ns.Rules
local Add = R.AddRecipes

local function Has(key, name)
    for _, recipe in ipairs(R.RECIPES[key] or {}) do
        if recipe.name == name then return true end
    end
end

-- Adds every magic item whose name fits one of the patterns. Those up to `basicTo`
-- (a skill level) come with the skill; 0 means all have to be learned.
local function Family(key, patterns, basicTo)
    for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
        for _, pattern in ipairs(patterns) do
            if name:find(pattern) and not Has(key, name) then
                Add(key, name, (R.RARITY_LEVEL[R.ITEMS[name].rarity] or 99) <= basicTo)
                break
            end
        end
    end
end
local RARE = R.RARITY_LEVEL.Rare

-- The plain thing a magic one is made from, where the lists price it.
for name, base in pairs({
    ["Shield of Expression"] = "Shield", ["Shield of Missile Attraction"] = "Shield", ["Animated Shield"] = "Shield",
    ["Arrow-Catching Shield"] = "Shield", ["Sentinel Shield"] = "Shield", ["Spellguard Shield"] = "Shield",
    ["Armor of Invulnerability"] = "Plate Armor", ["Dwarven Plate"] = "Plate Armor", ["Elven Chain"] = "Chain Shirt",
    ["Dagger of Venom"] = "Dagger", ["Mace of Terror"] = "Mace", ["Mace of Smiting"] = "Mace", ["Mace of Disruption"] = "Mace",
    ["Scimitar of Speed"] = "Scimitar", ["Trident of Fish Command"] = "Trident", ["Javelin of Lightning"] = "Javelin",
    ["Quarterstaff of the Acrobat"] = "Quarterstaff", ["Thunderous Greatclub"] = "Greatclub", ["Staff of Striking"] = "Quarterstaff",
}) do
    if R.ITEMS[base] then R.RECIPE_BASE[name] = base end
end
-- Magic that goes on any weapon of a kind: the plain weapon is paid for apart.
for _, name in ipairs({ "Dragon Slayer", "Giant Slayer", "Vicious Weapon", "Weapon of Warning", "Flame Tongue", "Frost Brand",
    "Sword of Life Stealing", "Sword of Answering", "Holy Avenger", "Luck Blade", "Dwarven Thrower" }) do
    R.RECIPE_OPEN[name] = "the plain weapon"
end
for _, kind in ipairs({ "Armor", "Weapon" }) do
    for rarity in pairs(R.MAGIC_CRAFT) do
        R.RECIPE_OPEN[("Enspelled %s (%s)"):format(kind, rarity)] = kind == "Armor" and "the plain suit of armor" or "the plain weapon"
    end
end

Family("alchemy", { "^Potion of ", "^Oil of ", "Elixir", "^Philter of ", "^Flask of the Titans" }, RARE)
Add("alchemy", "Perfume of Bewitching;Alchemy Jug;Dust of Disappearance;Dust of Dryness;Keoghtom's Ointment;Philosopher's Stone;Sovereign Glue;Universal Solvent")

local ANY_WEAPON = "Dragon Slayer;Giant Slayer;Vicious Weapon;Weapon of Warning"
Add("blacksmithing", ANY_WEAPON .. ";Flame Tongue;Sword of Life Stealing;Mace of Smiting;Mace of Disruption;Mace of Terror;Sun Blade;Javelin of Lightning;"
    .. "Dagger of Venom;Trident of Fish Command;Elven Chain;Shield of Expression;Sentinel Shield;Arrow-Catching Shield;Shield of Missile Attraction;"
    .. "Walloping Ammunition;+1 Ammunition;+2 Ammunition", true)
Add("blacksmithing", "Frost Brand;Dwarven Thrower;Scimitar of Speed;Dwarven Plate;Animated Shield;Spellguard Shield;+3 Ammunition;Ammunition of Slaying;"
    .. "Holy Avenger;Luck Blade;Sword of Answering;Armor of Invulnerability")
Add("blacksmithing", "Dark Shard Amulet;Dread Helm;Figurine of Wondrous Power, Silver Raven;Gauntlets of Ogre Power;Helm of Comprehending Languages;"
    .. "Helm of Telepathy;Sending Stones;Belt of Hill Giant Strength;Brazier of Commanding Fire Elementals;Dimensional Shackles;"
    .. "Figurine of Wondrous Power, Bronze Griffon;Figurine of Wondrous Power, Golden Lions;Figurine of Wondrous Power, Marble Elephant;"
    .. "Helm of Teleportation;Horseshoes of Speed;Iron Bands of Bilarro;Stone of Controlling Earth Elementals;Belt of Fire Giant Strength;"
    .. "Belt of Frost Giant Strength;Belt of Stone Giant Strength;Helm of Brilliance;Horseshoes of a Zephyr;Belt of Cloud Giant Strength;"
    .. "Belt of Storm Giant Strength;Iron Flask")

Add("cooking", "Bead of Nourishment;Bead of Refreshment;Heward's Handy Spice Pouch;Tankard of Sobriety")

Family("enchanting", { "^Wand of " }, RARE)
Add("enchanting", ANY_WEAPON .. ";Walloping Ammunition;+1 Ammunition;+2 Ammunition", true)
Family("enchanting", { "Rod", "^Enspelled " }, 0)
Add("enchanting", "+3 Ammunition;Ammunition of Slaying;Quarterstaff of the Acrobat;Thunderous Greatclub;Charlatan's Die;Pot of Awakening;Broom of Flying;"
    .. "Decanter of Endless Water;Pipes of Haunting;Pipes of the Sewers;Bowl of Commanding Water Elementals;Figurine of Wondrous Power, Ebony Fly")

Add("engineering", "Clockwork Amulet;Ear Horn of Hearing;Ersatz Eye;Horn of Silent Alarm;Instrument of Illusions;Instrument of Scribing;Lock of Trickery;"
    .. "Mystery Key;Orb of Direction;Orb of Time;Pipe of Smoke Monsters;Pole of Angling;Pole of Collapsing;Prosthetic Limb;Rival Coin;Veteran's Cane;"
    .. "Baba Yaga's Dancing Broom;Driftglobe;Eversmoking Bottle;Goblin Jumper Cables;Goggles of Night;Lantern of Revealing;Wind Fan;Chime of Opening;"
    .. "Cube of Summoning;Daern's Instant Fortress;Experimental Goblin Jetpack;Horn of Blasting;Horn of Valhalla, Brass;Horn of Valhalla, Silver;"
    .. "Portable Hole;Cauldron of Rebirth;Horn of Valhalla, Bronze;Apparatus of Kwalish;Cubic Gate;Horn of Valhalla, Iron;Sphere of Annihilation;"
    .. "Talisman of the Sphere;Well of Many Worlds")

Add("inscription", "Scroll of Protection", true)
Family("inscription", { "^Staff of ", "^Manual of ", "^Tome of " }, 0)
Add("inscription", "Enduring Spellbook;Deck of Illusions;Nolzur's Marvelous Pigments;Spirit Board;Scroll of Titan Summoning")

Family("jewelcrafting", { "^Ring of ", "^Ioun Stone of ", "^Quaal's Feather Token" }, 0)
Add("jewelcrafting", "Ruby of the War Mage;Amulet of Proof against Detection and Location;Brooch of Shielding;Circlet of Blasting;Elemental Gem;Eyes of Charming;"
    .. "Eyes of Minute Seeing;Gem of Brightness;Headband of Intellect;Medallion of Thoughts;Necklace of Adaptation;Pearl of Power;Periapt of Health;"
    .. "Periapt of Wound Closure;Amulet of Health;Bead of Force;Censer of Controlling Air Elementals;Cube of Force;Figurine of Wondrous Power, Bronze Griffon;"
    .. "Figurine of Wondrous Power, Ebony Fly;Figurine of Wondrous Power, Golden Lions;Figurine of Wondrous Power, Ivory Goats;"
    .. "Figurine of Wondrous Power, Jeweled Panther;Figurine of Wondrous Power, Marble Elephant;Figurine of Wondrous Power, Onyx Dog;"
    .. "Figurine of Wondrous Power, Serpentine Owl;Gem of Seeing;Necklace of Fireballs;Necklace of Prayer Beads;Periapt of Proof against Poison;"
    .. "Amulet of the Planes;Crystal Ball of Telepathy@5;Figurine of Wondrous Power, Obsidian Steed;Mirror of Life Trapping;"
    .. "Crystal Ball of Mind Reading;Crystal Ball of True Seeing")

Add("leatherworking", "Boots of False Tracks;Boots of Elvenkind;Boots of Striding and Springing;Boots of the Winterlands;Bracers of Archery;"
    .. "Heward's Handy Haversack@3;Quiver of Ehlonna;Saddle of the Cavalier;Winged Boots;Boots of Levitation;Boots of Speed")

Add("tailoring", "Cloak of Billowing;Cloak of Many Fashions;Clothes of Mending;Hat of Vermin;Hat of Wizardry;Rope of Mending;Talking Doll;Bag of Holding;"
    .. "Bag of Tricks;Cap of Water Breathing;Cloak of Elvenkind;Cloak of the Manta Ray;Gloves of Missile Snaring;Gloves of Swimming and Climbing;"
    .. "Gloves of Thievery;Hat of Disguise;Nature's Mantle;Robe of Useful Items;Rope of Climbing;Slippers of Spider Climbing;+1 Wraps of Unarmed Power;"
    .. "Bag of Beans;Cape of the Mountebank;Cloak of Displacement;Cloak of the Bat;Mantle of Spell Resistance;Robe of Eyes;Rope of Entanglement;"
    .. "Wings of Flying;+2 Wraps of Unarmed Power;Carpet of Flying;Cloak of Arachnida;Hat of Many Spells;Robe of Scintillating Colors;"
    .. "+3 Wraps of Unarmed Power;Cloak of Invisibility")
