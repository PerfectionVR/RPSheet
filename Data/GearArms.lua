-- Armor, weapons, ammunition and tools as things to buy and carry: name, price in
-- copper pieces and weight in pounds (see Rules.AddGear in Data/Items.lua). What a
-- weapon or a suit of armor does in a fight is in Data/Weapons.lua and Data/Rules.lua.
local _, ns = ...
local R = ns.Rules

R.AddGear("Armor and shields",
    "Padded Armor|500|8;Leather Armor|1000|10;Studded Leather Armor|4500|13;Hide Armor|1000|12;"
    .. "Chain Shirt|5000|20;Scale Mail|5000|45;Breastplate|40000|20;Half Plate Armor|75000|40;"
    .. "Ring Mail|3000|40;Chain Mail|7500|55;Splint Armor|20000|60;Plate Armor|150000|65;"
    .. "Shield|1000|6")

R.AddGear("Weapons and ammunition",
    "Battleaxe|1000|4;Blowgun|1000|1;Club|10|2;Dagger|200|1;Dart|5|0.25;Flail|1000|2;"
    .. "Glaive|2000|6;Greataxe|3000|7;Greatclub|20|10;Greatsword|5000|6;Halberd|2000|6;"
    .. "Hand Crossbow|7500|3;Handaxe|500|2;Heavy Crossbow|5000|18;Javelin|50|2;Lance|1000|6;"
    .. "Light Crossbow|2500|5;Light Hammer|200|2;Longbow|5000|2;Longsword|1500|3;Mace|500|4;"
    .. "Maul|1000|10;Morningstar|1500|4;Musket|50000|10;Pike|500|18;Pistol|25000|3;"
    .. "Quarterstaff|20|4;Rapier|2500|2;Scimitar|2500|3;Shortbow|2500|2;Shortsword|1000|2;"
    .. "Sickle|100|2;Sling|10|0;Spear|100|3;Trident|500|4;War Pick|500|2;Warhammer|1500|5;"
    .. "Whip|200|3;Arrows (20)|100|1;Bolts (20)|100|1.5;Firearm Bullets (10)|300|2;"
    .. "Needles (50)|100|1;Sling Bullets (20)|4|1.5")

R.AddGear("Tools and instruments",
    "Alchemist's Supplies|5000|8;Brewer's Supplies|2000|9;Calligrapher's Supplies|1000|5;"
    .. "Carpenter's Tools|800|6;Cartographer's Tools|1500|6;Cobbler's Tools|500|5;"
    .. "Cook's Utensils|100|8;Glassblower's Tools|3000|5;Jeweler's Tools|2500|2;"
    .. "Leatherworker's Tools|500|5;Mason's Tools|1000|8;Painter's Supplies|1000|5;"
    .. "Potter's Tools|1000|3;Smith's Tools|2000|8;Tinker's Tools|5000|10;Weaver's Tools|100|5;"
    .. "Woodcarver's Tools|100|5;Disguise Kit|2500|3;Forgery Kit|1500|5;Herbalism Kit|500|3;"
    .. "Navigator's Tools|2500|2;Poisoner's Kit|5000|2;Thieves' Tools|2500|1;Dice Set|10|0;"
    .. "Dragonchess Set|100|0;Playing Cards|50|0;Three-Dragon Ante Set|100|0;Bagpipes|3000|6;"
    .. "Drum|600|3;Dulcimer|2500|10;Flute|200|1;Horn|300|2;Lute|3500|2;Lyre|3000|2;"
    .. "Pan Flute|1200|2;Shawm|200|1;Viol|3000|1")
