-- The addon's equipment against the rules site: weapons, armor, tools, every plain
-- item's price and weight, mounts, vehicles and ships, and every magic item's rarity,
-- attunement and weight. The site's facts are in tests/data/ (see t-conform-lib.lua).
dofile(ARG3 .. "/t-conform-lib.lua")
dofile(ARG3 .. "/conform-items-allow.lua") -- the deliberate differences, with reasons

local DAMAGE = { B = "bludgeoning", P = "piercing", S = "slashing" }
local ARMOR_TYPES = { LA = true, MA = true, HA = true }
local TOOL_TYPES = { AT = true, INS = true, GS = true, T = true }
local RIDE_TYPES = { MNT = true, VEH = true, SHP = true, AIR = true }
-- The site's name for a thing the addon calls something else.
local PLAIN_NAME = { ["Feed (per day)"] = "Feed" }

local counts = { weapons = 0, armor = 0, tools = 0, plain = 0, rides = 0, magic = 0 }
local siteWeapons, siteTools, sitePlain, siteRides = {}, {}, {}, {}
local beastSize = {}
for _, file in ipairs({ "beasts-1.txt", "beasts-2.txt" }) do
    for _, row in ipairs(ReadData(file)) do beastSize[row[2]] = row.sz end
end

local function Price(key, name, row)
    local item = R.ITEMS[name]
    if not item then return end
    Same(key .. "price", item.cost, row.cp or 0)
    Same(key .. "weight", item.weight, row.lb or 0)
end

local function Weapon(name, row)
    siteWeapons[name] = true
    counts.weapons = counts.weapons + 1
    local weapon, key = R.WEAPONS[name], "weapon/" .. name .. "/"
    if not weapon then return end
    Same(key .. "category", weapon.category, row.wc:upper())
    Same(key .. "ranged", tostring(weapon.ranged), tostring(row[3] == "R"))
    Same(key .. "dice", weapon.dice[2] == 1 and "1" or ("%dd%d"):format(weapon.dice[1], weapon.dice[2]), row.d)
    Same(key .. "damage", weapon.damage, DAMAGE[row.dt] or row.dt)
    Same(key .. "versatile", weapon.versatile and ("1d" .. weapon.versatile) or "", row.d2 or "")
    Same(key .. "properties", Keys(weapon.props), Sorted(row.pr or ""))
    Same(key .. "mastery", weapon.mastery, row.m)
    Same(key .. "range", weapon.range or "", row.rg or "")
end

local function Armor(name, row)
    counts.armor = counts.armor + 1
    local armor, key = R.ARMOR[R.ARMOR_ITEMS[name] or ""], "armor/" .. name .. "/"
    if not armor then Differ(key .. "missing", "no armor of that name") return end
    Same(key .. "ac", armor.ac, row.ac)
    Same(key .. "dex cap", armor.dexCap or "none", (row[3] == "LA" and "none") or (row[3] == "MA" and 2) or 0)
    Same(key .. "strength", armor.minStr or 0, row.str or 0)
    Same(key .. "stealth", armor.stealth and 1 or 0, row.st or 0)
end

---------------------------------------------------------------------------
-- Mounts, vehicles and ships
---------------------------------------------------------------------------
local SIZE = { M = "M", L = "L", H = "H", S = "S" }
local function Speeds(mount)
    local parts = { "walk " .. (mount.speed or 0) }
    for _, kind in ipairs({ "climb", "fly", "swim" }) do
        if (mount[kind] or 0) > 0 then parts[#parts + 1] = kind .. " " .. mount[kind] end
    end
    return Sorted(parts)
end
local function Ride(name, row)
    siteRides[name] = true
    local mount, key = R.MOUNTS[name], "ride/" .. name .. "/"
    if not mount then return end
    counts.rides = counts.rides + 1
    if row.cp then Same(key .. "price", mount.cost, row.cp) else Same(key .. "unsold", tostring(mount.unsold or false), "true") end
    if row[3] == "MNT" then
        if row.spd then Same(key .. "speed", mount.speed, row.spd) end
        if row.cap then Same(key .. "capacity", mount.capacity, row.cap) end
        if beastSize[name] then Same(key .. "size", mount.size, SIZE[beastSize[name]] or beastSize[name]) end
    elseif row[3] == "VEH" and not row.vspd then
        Same(key .. "weight", mount.weight, row.lb)
    else
        Same(key .. "pace", mount.travel, row.vspd .. " mph")
        Same(key .. "cargo", mount.capacity, (tonumber(row.cargo) or 0) * 2000)
        if row.lb then Same(key .. "weight", mount.weight, row.lb) end
        local desc = mount.desc
        Same(key .. "crew", desc:match("Crew (%d+)") or (row[2] ~= "WoW" and 0 or row.crew), row.crew)
        if row[2] ~= "WoW" then Same(key .. "passengers", desc:match("(%d+) passengers") or 0, row.pass or 0) end
        Same(key .. "ac", desc:match("Armor Class (%d+)"), row.vac)
        Same(key .. "hp", desc:match("(%d+) hit points"), row.vhp)
        Same(key .. "threshold", desc:match("less than (%d+) damage") or 0, row.vdt or 0)
    end
end

---------------------------------------------------------------------------
-- Plain items: base items first, then the rest
---------------------------------------------------------------------------
for _, file in ipairs({ "items-base.txt", "items-plain.txt" }) do
    for _, row in ipairs(ReadData(file)) do
        local name, kind = PLAIN_NAME[row[1]] or row[1], row[3]
        if row.wc and kind ~= "SCF" then Weapon(name, row) end
        if ARMOR_TYPES[kind] then Armor(name, row) end
        if kind == "S" then Same("armor/Shield/ac", R.SHIELD_AC, row.ac) end
        if TOOL_TYPES[kind] then
            siteTools[name] = true
            counts.tools = counts.tools + 1
            if R.TOOLS[name] then Same("tool/" .. name .. "/kind", R.TOOLS[name].kind, kind) end
        end
        if RIDE_TYPES[kind] then
            -- The setting's book lists the Warhorse again with the same numbers.
            if not (siteRides[name] and row[2] == "WoW") or name ~= "Warhorse" then Ride(name, row) end
        elseif name == "Stabling (per day)" then
            Same("stabling", R.STABLE_COPPER, row.cp)
        else
            sitePlain[name] = true
            counts.plain = counts.plain + 1
            Price("item/" .. name .. "/", name, row)
            if name == "Feed" then Same("feed", R.FEED_COPPER, row.cp) end
        end
    end
end
BothWays("weapon", siteWeapons, R.WEAPONS)
BothWays("tool", siteTools, R.TOOLS)
local addonPlain, addonRides = {}, {}
for name, item in pairs(R.ITEMS) do
    if item.kind ~= "Magic items" and item.kind ~= "Spell components" then addonPlain[name] = true end
end
BothWays("item", sitePlain, addonPlain)
for name, mount in pairs(R.MOUNTS) do
    if mount.group ~= "Companions" and mount.group ~= "Made and summoned" then addonRides[name] = true end
end
BothWays("ride", siteRides, addonRides)
for name in pairs(R.ARMOR_ITEMS) do
    if not sitePlain[name] then Differ("armor/" .. name .. "/extra", "in the addon, not on the site") end
end
for name in pairs(R.WEAPONS) do
    COMPARED = COMPARED + 1
    if not R.ITEMS[name] then Differ("weapon/" .. name .. "/unpriced", "a weapon without a price and weight in the item lists") end
end
for name in pairs(R.TOOLS) do
    COMPARED = COMPARED + 1
    if not R.ITEMS[name] then Differ("tool/" .. name .. "/unpriced", "a tool without a price and weight in the item lists") end
end

-- The setting's own tables: what a mount costs, carries and asks for, the creature it
-- is (for its speeds and size), and the powered vehicles.
local function Renown(mount)
    if not mount.renown then return "" end
    local names = {}
    for index = 2, #mount.renown do names[#names + 1] = mount.renown[index] end
    return mount.renown[1] .. " " .. Sorted(names)
end
local GOBLIN = "10 " .. Sorted({ "Bilgewater Cartel", "Steamwheedle Cartel" })
local function SiteRenown(text)
    if text == "" then return "" end
    if text == "10 any goblin cartel" then return GOBLIN end
    local score, names = text:match("^(%d+) (.+)$")
    return score .. " " .. Sorted(names)
end
for _, row in ipairs(ReadData("misc.txt")) do
    local name, mount = row[2], R.MOUNTS[row[2]]
    if row[1] == "mountrow" and mount then
        local key = "ride/" .. name .. "/"
        Same(key .. "table price", mount.cost, tonumber(row.gp) * 100)
        Same(key .. "table capacity", mount.capacity, row.cap)
        Same(key .. "renown", Renown(mount), SiteRenown(row.need))
    elseif row[1] == "mountas" and mount then
        Same("ride/" .. name .. "/speeds", Speeds(mount), Sorted(row.spd))
        Same("ride/" .. name .. "/size", mount.size, row.sz)
    elseif row[1] == "powered" and mount then
        local key = "ride/" .. name .. "/"
        Same(key .. "table price", mount.cost, (tonumber(row.gp) or 0) * 100)
        Same(key .. "table cargo", mount.capacity, row.cargo)
        Same(key .. "table pace", mount.travel, row.mph .. " mph")
        Same(key .. "renown", Renown(mount), SiteRenown(row.need))
    elseif (row[1] == "mountrow" or row[1] == "powered") and not mount then
        Differ("ride/" .. name .. "/missing", "in the setting's table, not in the addon")
    end
end

---------------------------------------------------------------------------
-- Tool abilities, flying carpets, professions and companions
---------------------------------------------------------------------------
local siteProfessions, addonProfessions, siteCompanions, regionIndex = {}, {}, {}, 0
for _, row in ipairs(ReadData("misc-more.txt")) do
    local kind, name = row[1], row[2]
    if kind == "toolstat" then
        Same("tool/" .. name .. "/ability", R.TOOLS[name] and R.TOOLS[name].stat or "none", row[3])
    elseif kind == "carpet" then
        local carpet = R.MOUNTS[("Carpet of Flying (%s)"):format(name)] or {}
        Same("carpet/" .. name .. "/capacity", carpet.capacity or "none", row.cap)
        Same("carpet/" .. name .. "/fly", carpet.fly or "none", row.fly)
    elseif kind == "region" then
        regionIndex = regionIndex + 1
        local region = R.REGIONS[regionIndex] or {}
        Same("region/" .. name .. "/name", (region.name or ""):gsub("^levels ", ""), name)
        Same("region/" .. name .. "/dc", region.dc, row.dc)
        Same("region/" .. name .. "/common", region.common, tonumber(row.common) * 100)
        Same("region/" .. name .. "/rare", region.rare, tonumber(row.rare) * 100)
    elseif kind == "disenchant" then
        local entry = R.DISENCHANT[name] or {}
        Same("disenchant/" .. name .. "/skill", entry.level, row[3])
        Same("disenchant/" .. name .. "/residue", entry.worth, tonumber(row[4]) * 100)
    elseif kind == "profession" then
        siteProfessions[row[2] .. "/" .. row[3]] = true
    elseif kind == "companion" then
        siteCompanions[name] = true
    end
end
Same("regions", #R.REGIONS, regionIndex)
for _, profession in pairs(R.PROFESSIONS) do addonProfessions[profession.kind .. "/" .. profession.name] = true end
BothWays("profession", siteProfessions, addonProfessions)
BothWays("companion", siteCompanions, R.COMPANIONS)

---------------------------------------------------------------------------
-- Magic items
---------------------------------------------------------------------------
local RARITY = { C = "Common", U = "Uncommon", R = "Rare", V = "Very rare", L = "Legendary", A = "Artifact" }
-- Where the addon keeps one entry for a family the site lists member by member.
local RENAME = {
    { "^Ioun Stone, (.+)$", "Ioun Stone of %1" }, { "^Carpet of Flying, .+$", "Carpet of Flying" },
    { "^Bag of Tricks, .+$", "Bag of Tricks" }, { "^Elemental Gem, .+$", "Elemental Gem" },
    { "^%a+ Dragon Scale Mail$", "Dragon Scale Mail" }, { "^Scroll of Protection %(.+%)$", "Scroll of Protection" },
    { "^Scroll of Titan Summoning %(.+%)$", "Scroll of Titan Summoning" },
    { "^Figurine of Wondrous Power %((.+)%)$", "Figurine of Wondrous Power, %1" }, { "^(.+) %(%*%)$", "%1" },
    { "^Armor of Vulnerability %(.+%)$", "Armor of Vulnerability" },
    -- The states and halves of an artifact are the one item.
    { "^Ashbringer %(True State%)$", "Ashbringer" }, { "^Corrupted Ashbringer$", "Ashbringer" },
    { "^Staff of Light and Shadow %(.+%)$", "Staff of Light and Shadow" },
}
-- A make's `fits` in the addon for what the site says it goes on.
local FITS = {
    ["LA,MA,HA"] = "armor", ["MA,HA not Hide Armor"] = "metal", ["S"] = "shield", ["weapon"] = "weapon",
    ["simple,martial"] = "weapon", ["M"] = "melee", ["A,AF"] = "ammo", ["A,AF,M"] = "arms",
}
local function AddonName(name, rarity)
    if name:find("^Enspelled %a+ %(") then return name:gsub("%(.+%)", "(" .. (RARITY[rarity] or rarity) .. ")") end
    for _, rule in ipairs(RENAME) do
        if name:find(rule[1]) then return (name:gsub(rule[1], rule[2])) end
    end
    return name
end
local variantByTitle = {}
for _, key in ipairs(R.ITEM_VARIANTS) do variantByTitle[R.ITEM_VARIANT[key].title] = R.ITEM_VARIANT[key] end

local siteMagic = {}
local function Magic(name, rarity, attune, pounds, fits, bonus)
    local known = AddonName(name, rarity)
    siteMagic[known] = true
    counts.magic = counts.magic + 1
    local item, key = R.ITEMS[known], "magic/" .. name .. "/"
    if item and item.kind == "Magic items" then
        Same(key .. "rarity", item.rarity, RARITY[rarity] or rarity)
        Same(key .. "attunement", item.attune and "a" or "", attune ~= "" and "a" or "")
        if pounds then Same(key .. "weight", item.weight, pounds) end
    end
    -- A make that the site has once per kind (the three suits of vulnerability) is
    -- one make each in the addon too, under the site's own name.
    local variant = fits and variantByTitle[name] or variantByTitle[known]
    if variant then
        siteMagic["variant:" .. variant.title] = true
        Same(key .. "variant rarity", variant.rarity, RARITY[rarity] or rarity)
        Same(key .. "variant attunement", variant.attune and "a" or "", attune ~= "" and "a" or "")
        Same(key .. "variant fits", variant.fits, FITS[fits] or fits)
        -- A weapon's or a suit's bonus is on the make; a piece of ammunition's is for
        -- the one shot and only said.
        if variant.fits ~= "ammo" then Same(key .. "variant bonus", variant.bonus or 0, tonumber(bonus) or 0) end
    elseif fits then
        siteMagic["variant:" .. known] = true -- a make the addon should have
    end
end
for _, file in ipairs({ "items-magic-1.txt", "items-magic-2.txt", "items-magic-3.txt" }) do
    for _, row in ipairs(ReadData(file)) do Magic(row[1], row[3], row[4] or "", tonumber(row[6]) or 0) end
end
for _, row in ipairs(ReadData("items-variants.txt")) do
    if row[1] == "variant" then Magic(row[2], row[4], row[5] or "", nil, row.fits, row.bw or row.bac) end
end
local addonMagic = {}
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do addonMagic[name] = true end
for title in pairs(variantByTitle) do addonMagic["variant:" .. title] = true end
for name in pairs(siteMagic) do
    if variantByTitle[name] then addonMagic[name] = addonMagic[name] or true end -- a variant stands for the item too
end
BothWays("magic", siteMagic, addonMagic)

print(("compared: %d weapons, %d suits of armor, %d tools, %d plain items, %d mounts and vehicles, %d magic items and makes")
    :format(counts.weapons, counts.armor, counts.tools, counts.plain, counts.rides, counts.magic))
Finish("items")
