-- The deliberate differences between the addon's equipment and the rules site, each
-- with its reason (see t-conform-lib.lua). Loaded by t-conform-items.lua; not a test by itself.

-- Plain items
Allow("stabling", "the site's item says 5 cp, but the price table of its own copy of the book says 5 SP a day, which is what the addon charges")
Allow("item/Spellbook/extra", "the 2024 rules give a wizard a spellbook without pricing it; the starting set needs the item, with the earlier rules' 50 gp and 3 lb.")
Allow("item/Sling Bullet/missing", "one bullet costs a fifth of a copper piece, which the purse can't pay; sold by the twenty")
Allow("item/Trinket/missing", "a keepsake without price or weight, for the player to describe: added as an item of one's own")
Allow("item/Psychic Blade/missing", "a class feature's weapon, not something to buy or carry")
Allow("weapon/Psychic Blade/missing", "a class feature's weapon, not one of the basic weapons")
for _, name in ipairs({ "Antimatter Rifle", "Automatic Rifle", "Hunting Rifle", "Laser Pistol", "Laser Rifle", "Revolver", "Semiautomatic Pistol", "Shotgun" }) do
    Allow("weapon/" .. name .. "/missing", "modern and futuristic firearms are an optional rule of other worlds; Azeroth has the musket and the pistol")
    Allow("item/" .. name .. "/missing", "modern and futuristic firearms are an optional rule of other worlds; Azeroth has the musket and the pistol")
end
for _, name in ipairs({ "Energy Cell", "Grenade Launcher", "Fragmentation Grenade", "Dynamite Stick", "Bomb", "Gunpowder (keg)", "Gunpowder (powder horn)", "Smoke Grenade" }) do
    Allow("item/" .. name .. "/missing", "explosives and their gear are an optional rule with attacks of their own, which the sheet has no rolls for")
end

-- Magic items
AllowLike("^magic/Spell Scroll %(.+%)/missing$", "a spell scroll is made for a spell, with its rarity and price by the spell's level: Data/Scrolls.lua")
for _, name in ipairs({ "Axe of the Dwarvish Lords", "Blackrazor", "Book of Exalted Deeds", "Book of Vile Darkness", "Demonomicon of Iggwilv", "Eye of Vecna",
    "Hand of Vecna", "Orb of Dragonkind", "Sword of Kas", "Wand of Orcus", "Wave", "Whelm" }) do
    Allow("magic/" .. name .. "/missing", "an artifact of other worlds' gods and villains, which Azeroth doesn't have")
end
Allow("magic/Shalamayne (Ellemayne)/missing", "one half of Shalamayne, which the artifact's description covers")
Allow("magic/Shalamayne (Shalla'tor)/missing", "one half of Shalamayne, which the artifact's description covers")
for _, name in ipairs({ "Bag of Beans", "Keoghtom's Ointment", "Nolzur's Marvelous Pigments", "Pot of Awakening", "Stone of Controlling Earth Elementals" }) do
    Allow("magic/" .. name .. "/weight", "the site gives the weight in the item's text, not as a number; the addon's is that weight")
end
Allow("magic/Adamantine Weapon/variant fits", "the site lets ammunition be adamantine too; the make is offered for melee weapons, ammunition not being a weapon of the sheet")
