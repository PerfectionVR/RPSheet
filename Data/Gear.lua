-- Adventuring gear, packs and spellcasting focuses: name, price in copper pieces and
-- weight in pounds (see Rules.AddGear in Data/Items.lua).
local _, ns = ...
local R = ns.Rules

R.AddGear("Adventuring gear",
    "Acid|2500|1;Alchemist's Fire|5000|1;Antitoxin|5000|0;Backpack|200|5;Ball Bearings|100|2;"
    .. "Barrel|200|70;Basic Poison|10000|0;Basket|40|2;Bedroll|100|7;Bell|100|0;Blanket|50|3;"
    .. "Block and Tackle|100|5;Book|2500|5;Bucket|5|2;Bullseye Lantern|1000|2;Caltrops|100|2;"
    .. "Candle|1|0;Chain|500|10;Chest|500|25;Climber's Kit|2500|12;Component Pouch|2500|2;"
    .. "Costume|500|4;Crossbow Bolt Case|100|1;Crowbar|200|5;Fine Clothes|1500|6;Flask|2|1;Fuel|100|10;"
    .. "Glass Bottle|200|2;Grappling Hook|200|4;Healer's Kit|500|3;Holy Water|2500|1;"
    .. "Hooded Lantern|500|2;Hunting Trap|500|25;Ink|1000|0;Ink Pen|2|0;Iron Pot|200|10;"
    .. "Iron Spikes|100|5;Jug|2|4;Ladder|10|25;Lamp|50|1;Lock|1000|1;Magnifying Glass|10000|0;"
    .. "Manacles|200|6;Map|100|0;Map or Scroll Case|100|1;Mirror|500|0.5;Net|100|3;Oil|10|1;"
    .. "Paper|20|0;Parchment|10|0;Perfume|500|0;Pole|5|7;Portable Ram|400|35;Pouch|50|1;"
    .. "Quiver|100|1;Rations|50|2;Robe|100|4;Rope|100|5;Sack|1|0.5;Shovel|200|5;"
    .. "Signal Whistle|5|0;Spyglass|100000|1;String|10|0;Tent|200|20;Tinderbox|50|1;Torch|1|1;"
    .. "Traveler's Clothes|200|4;Vial|100|0;Waterskin|20|5")

-- A pack is bought and carried as one item; its weight is that of everything in it.
R.AddGear("Packs",
    "Burglar's Pack|1600|47.5;Diplomat's Pack|3900|39;Dungeoneer's Pack|1200|55;"
    .. "Entertainer's Pack|4000|58.5;Explorer's Pack|1000|55;Priest's Pack|3300|29;"
    .. "Scholar's Pack|4000|22")

R.AddGear("Spellcasting focuses",
    "Amulet|500|1;Crystal|1000|1;Emblem|500|0;Orb|2000|3;Reliquary|500|2;Rod|1000|2;"
    .. "Sprig of Mistletoe|100|0;Staff|500|4;Wand|1000|1;Wooden Staff|500|4;Yew Wand|1000|1")
