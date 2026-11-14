-- Common magic items whose magic is a plain bonus, with that bonus as effects the
-- sheet counts while the item is equipped (and attuned, where it needs that).
-- Descriptions are one-line summaries in our own words.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

-- { target, bonus } pairs as effects (see Rules.EFFECT_TARGETS).
local function Adds(...)
    local effects = {}
    for index = 1, select("#", ...), 2 do
        local target, flat = select(index, ...)
        effects[#effects + 1] = { target = target, flat = flat, stat = "", times = 1 }
    end
    return effects
end

local ATTUNE = { attune = true }
local TIERS = { { 1, "Uncommon" }, { 2, "Rare" }, { 3, "Very rare" } }
local ARMOR_RARITY = { "Rare", "Very rare", "Legendary" }

for _, tier in ipairs(TIERS) do
    local bonus, rarity = tier[1], tier[2]
    Magic(("+%d Armor"):format(bonus), ARMOR_RARITY[bonus],
        ("A suit of armor that adds %d to your Armor Class on top of what the armor gives."):format(bonus), Adds("AC", bonus))
    Magic(("+%d Shield"):format(bonus), rarity,
        ("A shield that adds %d to your Armor Class on top of a shield's usual bonus."):format(bonus), Adds("AC", bonus), { weight = 6 })
    -- A weapon's bonus is for that weapon alone, so it is set on the weapon itself.
    Magic(("+%d Weapon"):format(bonus), rarity,
        ("Adds %d to attack and damage rolls made with it. Set this as the weapon's magic bonus on the Weapons page."):format(bonus))
    Magic(("+%d Wand of the War Mage"):format(bonus), rarity,
        ("While you hold it, adds %d to your spell attack rolls, and your spell attacks ignore cover. For spellcasters."):format(bonus),
        Adds("SPELLATK", bonus), { attune = true, weight = 1 })
    Magic(("+%d Rod of the Pact Keeper"):format(bonus), rarity,
        ("While you hold it, adds %d to your spell attack rolls and your spell save DC. For Warlocks."):format(bonus),
        Adds("SPELLATK", bonus, "SPELLDC", bonus), { attune = true, weight = 2 })
end

Magic("Cloak of Protection", "Uncommon", "While worn, adds 1 to your Armor Class and to every saving throw.", Adds("AC", 1, "SAVES", 1), ATTUNE)
Magic("Ring of Protection", "Rare", "While worn, adds 1 to your Armor Class and to every saving throw.", Adds("AC", 1, "SAVES", 1), ATTUNE)
Magic("Bracers of Defense", "Rare", "Add 2 to your Armor Class while you wear no armor and use no shield.", Adds("AC", 2),
    { attune = true, limit = "UNARMORED" })
Magic("Ioun Stone of Protection", "Rare", "A prism that circles your head and adds 1 to your Armor Class.", Adds("AC", 1), ATTUNE)
Magic("Stone of Good Luck", "Uncommon", "While you carry it, adds 1 to every ability check and saving throw.", Adds("CHECKS", 1, "SAVES", 1), ATTUNE)
Magic("Robe of Stars", "Very rare", "While worn, adds 1 to every saving throw. Its stars can be spent as force missiles.", Adds("SAVES", 1), ATTUNE)
Magic("Scarab of Protection", "Legendary", "Adds 1 to your Armor Class, and its charges can turn a failed save against the undead into a success.",
    Adds("AC", 1), { attune = true, weight = 1 })
Magic("Shield of the Cavalier", "Very rare", "A shield that adds 2 to your Armor Class on top of a shield's usual bonus, and can bash or protect.",
    Adds("AC", 2), { attune = true, weight = 6 })
Magic("Dragon Scale Mail", "Very rare", "Scale mail that adds 1 to your Armor Class and guards against one kind of dragon's breath.",
    Adds("AC", 1), { attune = true, weight = 45 })
Magic("Glamoured Studded Leather", "Rare", "Studded leather that adds 1 to your Armor Class and can look like any other outfit.",
    Adds("AC", 1), { weight = 13 })
Magic("Robe of the Archmagi", "Legendary", "Adds 2 to your spell attack rolls and spell save DC. Without armor your base Armor Class is 15 plus Dexterity (set that by hand).",
    Adds("SPELLATK", 2, "SPELLDC", 2), ATTUNE)
Magic("Staff of Power", "Very rare", "While you hold it, adds 2 to your Armor Class, saving throws and spell attack rolls. As a weapon it has a magic bonus of 2.",
    Adds("AC", 2, "SAVES", 2, "SPELLATK", 2), { attune = true, weight = 4 })
Magic("Shadowfang", "Rare", "A sword with a magic bonus of 1 (set it on the Weapons page). Under the night sky it deals 2d6 more necrotic damage.",
    nil, { weight = 3 })
Magic("Potion of Healing", "Common", "Drinking it as a bonus action restores 2d4 + 2 hit points.", nil, { cost = 5000, weight = 0.5 })
