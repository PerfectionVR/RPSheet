-- Which carried items are things to wear or wield: the armor an item name stands for
-- (Rules.ARMOR), the shield, and the drawers of the starting closet in the wizard.
local _, ns = ...
local R = ns.Rules

-- Item name (Data/GearArms.lua) -> armor key (Data/Rules.lua).
R.ARMOR_ITEMS = {
    ["Padded Armor"] = "PADDED", ["Leather Armor"] = "LEATHER", ["Studded Leather Armor"] = "STUDDED",
    ["Hide Armor"] = "HIDE", ["Chain Shirt"] = "CHAINSHIRT", ["Scale Mail"] = "SCALE",
    ["Breastplate"] = "BREASTPLATE", ["Half Plate Armor"] = "HALFPLATE", ["Ring Mail"] = "RINGMAIL",
    ["Chain Mail"] = "CHAINMAIL", ["Splint Armor"] = "SPLINT", ["Plate Armor"] = "PLATE",
}
R.SHIELD_ITEM = "Shield"

-- The closet's drawers: every kind of plain gear, the things to fight with first.
R.CLOSET_KINDS = {
    "Weapons and ammunition", "Armor and shields", "Packs", "Spellcasting focuses",
    "Adventuring gear", "Tools and instruments",
}
