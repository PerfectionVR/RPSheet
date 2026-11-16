-- The named magic makes: armor, weapons and ammunition that exist of every plain
-- item of a kind (a Flame Tongue of any melee weapon, Mariner's Armor of any suit),
-- and the Enspelled Staff, which is a quarterstaff.
-- Each is also in the magic item lists as one item without a plain kind; the make
-- takes its rarity, attunement and words from there, so the two can't drift apart,
-- and adds what the sheet can count once the plain item is known: the magic bonus,
-- and resistances, immunities and vulnerabilities while it is worn and attuned.
local _, ns = ...
local R = ns.Rules
local Variant = R.AddVariant

-- The listed item's words without the note on where to set a weapon's bonus: a make
-- carries its bonus itself.
local function Words(name)
    local desc = R.ITEMS[name].desc
    desc = desc:gsub("^A weapon with a magic bonus of %d %(set it on the Weapons page%)%. ", "")
    return (desc:gsub(" with a magic bonus of %d %(set it on the Weapons page%)", ""))
end

-- A make of the listed item `name`: `fits` and `format` as in Data/ItemVariants.lua,
-- `more` for the bonus and whatever else the sheet counts.
local function Named(name, fits, format, more)
    local listed = R.ITEMS[name]
    if not listed then return end
    local entry = { title = name, fits = fits, format = format, rarity = listed.rarity, attune = listed.attune == true, desc = Words(name) }
    for key, value in pairs(more or {}) do entry[key] = value end
    Variant(entry.key or name, entry)
end

local SWORDS6 = "Glaive,Greatsword,Longsword,Rapier,Scimitar,Shortsword"
local SWORDS4 = "Glaive,Greatsword,Longsword,Scimitar"
local PLATE, CHAIN, BOWS = "Half Plate Armor,Plate Armor", "Chain Mail,Chain Shirt", "Longbow,Shortbow"

-- Armor
Named("Armor of Gleaming", "armor", "%s of Gleaming")
Named("Cast-Off Armor", "armor", "Cast-Off %s")
Named("Smoldering Armor", "armor", "Smoldering %s")
Named("Mariner's Armor", "armor", "Mariner's %s")
for _, kind in ipairs({ "bludgeoning", "piercing", "slashing" }) do
    local others = {}
    for _, other in ipairs({ "bludgeoning", "piercing", "slashing" }) do
        if other ~= kind then others[#others + 1] = other end
    end
    local word = kind:sub(1, 1):upper() .. kind:sub(2)
    Named("Armor of Vulnerability", "armor", ("%%s of Vulnerability (%s)"):format(word), {
        key = "vulnerability:" .. kind, title = ("Armor of Vulnerability (%s)"):format(word), resist = { kind }, vulnerable = others,
        desc = ("While you wear it and are attuned to it, you resist %s damage. It is cursed: you are vulnerable to %s and %s damage until the curse is lifted, even with the armor off. The sheet counts both while it is worn and attuned."):format(
            kind, others[1], others[2]) })
end
Named("Demon Armor", "armor", "Demon %s", { bonus = 1,
    desc = "Its claws make your unarmed strikes deal 1d8 slashing damage with a bonus of 1. It is cursed: it won't come off, and you fight demons at a disadvantage." })
Named("Elven Chain", CHAIN, "Elven %s", { bonus = 1, desc = "Anyone can wear it as if trained in it." })
Named("Dwarven Plate", PLATE, "Dwarven %s", { bonus = 2,
    desc = "When something pushes you along the ground you can use your reaction to be moved up to 10 feet less." })
Named("Efreeti Chain", CHAIN, "Efreeti %s", { bonus = 3, immune = { "fire" },
    desc = "Makes you immune to fire damage, which the sheet counts while it is worn and attuned, and lets you walk on molten rock." })
Named("Plate Armor of Etherealness", PLATE, "Armor of Etherealness (%s)", { short = true,
    desc = "Once a day a Magic action and a command word send you into the Ethereal Plane, as the Etherealness spell, until you say the word again or take the armor off." })
for _, rarity in ipairs({ "Uncommon", "Rare", "Very rare", "Legendary" }) do
    Named(("Enspelled Armor (%s)"):format(rarity), "armor", ("Enspelled %%s (%s)"):format(rarity:lower()))
end

-- Weapons of any kind
Named("Dragon Slayer", "weapon", "Dragon Slayer %s", { bonus = 1 })
Named("Giant Slayer", "weapon", "Giant Slayer %s", { bonus = 1 })
Named("Vicious Weapon", "weapon", "Vicious %s")
Named("Weapon of Warning", "weapon", "%s of Warning")
Named("Nine Lives Stealer", "weapon", "Nine Lives Stealer %s", { bonus = 2 })
Named("Holy Avenger", "weapon", "Holy Avenger %s", { bonus = 3 })
for _, rarity in ipairs({ "Uncommon", "Rare", "Very rare", "Legendary" }) do
    Named(("Enspelled Weapon (%s)"):format(rarity), "weapon", ("Enspelled %%s (%s)"):format(rarity:lower()))
end
-- An enspelled staff is a quarterstaff (it fights as one, and turns into a plain one
-- when its magic fails), so its make is of the quarterstaff alone. Its name says
-- "Staff" to keep it apart from an Enspelled Weapon made of a quarterstaff, which any
-- attuned creature can use; the staff asks for a spellcaster.
for _, rarity in ipairs({ "Uncommon", "Rare", "Very rare", "Legendary" }) do
    Named(("Enspelled Staff (%s)"):format(rarity), "Quarterstaff", ("Enspelled Staff (%%s, %s)"):format(rarity:lower()))
end
-- Melee weapons, swords, and weapons of a few kinds
Named("Flame Tongue", "melee", "Flame Tongue %s")
Named("Defender", "melee", "Defender %s", { bonus = 3 })
Named("Moon-Touched Sword", "sword", "Moon-Touched %s")
Named("Dancing Sword", "sword", "Dancing %s")
Named("Sword of Vengeance", SWORDS6, "%s of Vengeance", { bonus = 1 })
Named("Sword of Life Stealing", SWORDS6, "%s of Life Stealing")
Named("Sword of Wounding", SWORDS6, "%s of Wounding")
Named("Frost Brand", SWORDS6, "Frost Brand %s")
Named("Sword of Sharpness", SWORDS4, "%s of Sharpness")
Named("Vorpal Sword", SWORDS4, "Vorpal %s", { bonus = 3 })
Named("Luck Blade", "Glaive,Greatsword,Longsword,Rapier,Scimitar,Sickle,Shortsword", "Luck Blade (%s)", { bonus = 1,
    effects = R.ITEMS["Luck Blade"] and R.ITEMS["Luck Blade"].effects })
Named("Moonblade", "Greatsword,Longsword,Rapier,Scimitar,Shortsword", "Moonblade (%s)", { bonus = 1 })
Named("Sylvan Talon", "Dagger,Rapier,Scimitar,Shortsword,Sickle,Spear", "Sylvan Talon (%s)")
Named("Berserker Axe", "Battleaxe,Greataxe,Halberd", "Berserker %s", { bonus = 1,
    effects = { { target = "HP", flat = 0, stat = "LEVEL", times = 1 } },
    desc = "Attuned, you have 1 more hit point for each level, which the sheet counts while the axe is equipped. It is cursed: you won't part with it, attack worse with other weapons, and may go berserk when hurt." })
Named("Executioner's Axe", "Battleaxe,Greataxe,Halberd,Handaxe", "Executioner's %s", { bonus = 1 })
Named("Hammer of Thunderbolts", "Maul,Warhammer", "%s of Thunderbolts", { bonus = 1 })
Named("Energy Bow", BOWS, "Energy %s", { bonus = 1 })
Named("Oathbow", BOWS, "Oathbow (%s)")

-- Ammunition, by the piece
Named("Walloping Ammunition", "ammo", "Walloping %s", { stacks = true })
Named("Ammunition of Slaying", "ammo", "%s of Slaying", { stacks = true })
