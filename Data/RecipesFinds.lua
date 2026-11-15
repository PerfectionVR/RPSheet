-- Recipes for the magic items the earlier recipe lists (Data/RecipesMagic.lua) had
-- not reached, and the list of magic items nobody makes. The rule followed: armor
-- goes to the profession that makes its plain kind (smiths metal armor, leatherworkers
-- leather and hide, tailors padded), a weapon likewise (smiths metal melee weapons,
-- enchanters wooden and ranged ones, engineers firearms, leatherworkers slings and
-- whips), a staff to inscription, a ring to jewelcrafting, a dust to alchemy. A
-- wondrous item no profession names goes to the one that makes the plain thing it is,
-- or the things most like it, and otherwise to engineering, whose tools make any
-- wondrous item. Arms and armor up to rare come with the skill; the rest is learned.
local _, ns = ...
local R = ns.Rules
local Add = R.AddRecipes

-- The plain thing a named one is made from, where the lists price it.
for name, base in pairs({ Shadowfang = "Longsword", ["Defias Leather"] = "Leather Armor", ["Lute of Thunderous Thumping"] = "Club" }) do
    if R.ITEMS[base] then R.RECIPE_BASE[name] = base end
end

-- Armor that exists in any kind of suit: each profession makes it of its own suits.
local ANY_ARMOR, ANY_ARMOR_HIGH = "Armor of Gleaming;Cast-Off Armor;Smoldering Armor;Mariner's Armor;Armor of Vulnerability", "Demon Armor"
for _, key in ipairs({ "blacksmithing", "leatherworking", "tailoring" }) do
    Add(key, ANY_ARMOR, true)
    Add(key, ANY_ARMOR_HIGH)
end
Add("leatherworking", "Defias Leather", true)
Add("blacksmithing", "Efreeti Chain;Plate Armor of Etherealness;Judgment Armor")

-- Swords, axes and hammers are a smith's; a weapon of any kind is made by whoever
-- makes that kind.
Add("blacksmithing", "Moon-Touched Sword;Sylvan Talon;Sword of Vengeance;Berserker Axe;Sword of Wounding;Shadowfang", true)
Add("blacksmithing", "Dancing Sword;Executioner's Axe;Sword of Sharpness;Hammer of Thunderbolts;Moonblade;Vorpal Sword")
for _, key in ipairs({ "blacksmithing", "enchanting", "leatherworking" }) do Add(key, "Defender") end -- any melee weapon
for _, key in ipairs({ "blacksmithing", "enchanting", "engineering", "leatherworking" }) do Add(key, "Nine Lives Stealer") end -- any weapon
Add("enchanting", "Energy Bow;Oathbow;Lute of Thunderous Thumping") -- bows, and a club with strings

-- Wondrous items, each with the things most like it.
Add("alchemy", "Dust of Sneezing and Choking")                       -- the other dusts
Add("blacksmithing", "Hearthstone;Belt of Dwarvenkind;Efreeti Bottle") -- sending stones, the giants' belts, the iron flask
Add("enchanting", "Folding Boat")                                    -- carpentry
Add("engineering", "Candle of the Deep;Candle of Invocation;Steamwheedle Apparatus;Instrument of the Bards, Doss Lute;"
    .. "Instrument of the Bards, Fochlucan Bandore;Instrument of the Bards, Mac-Fuirmidh Cittern;Instrument of the Bards, Canaith Mandolin;"
    .. "Instrument of the Bards, Cli Lyre;Instrument of the Bards, Anstruth Harp;Instrument of the Bards, Ollamh Harp") -- the other instruments, the apparatus
Add("inscription", "Deck of Many Things;Life-Staff of the Web Lair") -- the other deck, staffs
Add("jewelcrafting", "Eyes of the Eagle;Crystal Ball;Crown of the Ogre King;Vithrak, Gaze of the Deadman;Talisman of Pure Good;"
    .. "Talisman of Ultimate Evil;Aviana's Feather")                 -- lenses, crystal balls, circlets, rings, holy symbols, feather tokens

-- Magic items no profession makes, and why. Every magic item of the lists has a
-- recipe or is named here (tests/t-test-items-recipes.lua holds that).
R.NOT_MADE = {
    ["Bag of Devouring"] = "it is the mouth of a creature from elsewhere, not a made thing",
    ["Hag Eye"] = "only a coven of hags makes one",
    ["Gnomeregan Engineering Device"] = "Gnomeregan's leaders lend it; it works for the one it was lent to",
}
-- An artifact is found, never made: the rules give it no time and no cost.
for _, name in ipairs(R.ITEM_NAMES["Magic items"] or {}) do
    if R.ITEMS[name].rarity == "Artifact" then R.NOT_MADE[name] = "an artifact is one of a kind and can't be made" end
end
