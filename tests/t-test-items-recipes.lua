-- Recipes for magic items: every magic item has a recipe or is on the list of those
-- nobody makes, each is with a profession that makes its kind, and a recipe is
-- learned for one profession (with what older characters learned carried over).
dofile(ARG3 .. "/t-test-items-lib.lua")

local makers = {} -- [item] = { [profession key] = recipe }
for _, key in ipairs(R.PROFESSION_ORDER) do
    for _, recipe in ipairs(R.RECIPES[key] or {}) do
        makers[recipe.name] = makers[recipe.name] or {}
        makers[recipe.name][key] = recipe
        Eq(recipe.id, key .. ":" .. recipe.name, "id of " .. recipe.name)
    end
end

---------------------------------------------------------------------------
-- Covered: a recipe, or a reason
---------------------------------------------------------------------------
local made, unmade, artifacts = 0, 0, 0
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    local item, why = R.ITEMS[name], R.NOT_MADE[name]
    if makers[name] then
        made = made + 1
        Check(why == nil, name .. ": has a recipe and is on the list of items that can't be made")
        Check(item.rarity ~= "Artifact", name .. ": an artifact with a recipe")
        for key, recipe in pairs(makers[name]) do
            -- Arms, armor, potions, scrolls and wands up to rare come with the skill;
            -- nothing rarer does.
            if recipe.basic then
                Check((R.RARITY_LEVEL[item.rarity] or 9) <= R.RARITY_LEVEL.Rare, ("%s (%s): a %s recipe that comes with the skill"):format(name, key, item.rarity))
            end
            local cost, days = ns.CraftCost(name)
            Check(cost > 0 and days > 0, name .. ": no cost or time to make")
        end
    else
        unmade = unmade + 1
        Check(type(why) == "string" and #why > 10, name .. ": neither a recipe nor a reason why it can't be made")
        if item.rarity == "Artifact" then artifacts = artifacts + 1 end
    end
end
for name in pairs(R.NOT_MADE) do Check(R.ITEMS[name] and R.ITEMS[name].rarity, name .. " on the list of unmade items is not a magic item") end
print("magic items made", made, "not made", unmade, "of which artifacts", artifacts)
Eq(artifacts, 7, "artifacts")
Eq(unmade - artifacts, 3, "other items nobody makes")

---------------------------------------------------------------------------
-- With the profession that makes its kind
---------------------------------------------------------------------------
local function Makers(name)
    local keys = {}
    for key in pairs(makers[name] or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    return table.concat(keys, " ")
end
for name, want in pairs({
    -- armor of any kind: metal, leather and padded each have their maker
    ["Mariner's Armor"] = "blacksmithing leatherworking tailoring", ["Demon Armor"] = "blacksmithing leatherworking tailoring",
    ["Armor of Vulnerability"] = "blacksmithing leatherworking tailoring", ["Cast-Off Armor"] = "blacksmithing leatherworking tailoring",
    -- armor of one kind
    ["Efreeti Chain"] = "blacksmithing", ["Plate Armor of Etherealness"] = "blacksmithing", ["Judgment Armor"] = "blacksmithing",
    ["Defias Leather"] = "leatherworking",
    -- swords, axes, hammers: metal melee weapons
    ["Vorpal Sword"] = "blacksmithing", ["Berserker Axe"] = "blacksmithing", ["Hammer of Thunderbolts"] = "blacksmithing",
    ["Sword of Sharpness"] = "blacksmithing", Shadowfang = "blacksmithing", ["Sylvan Talon"] = "blacksmithing",
    -- bows and a club
    Oathbow = "enchanting", ["Energy Bow"] = "enchanting", ["Lute of Thunderous Thumping"] = "enchanting",
    -- any melee weapon; any weapon
    Defender = "blacksmithing enchanting leatherworking", ["Nine Lives Stealer"] = "blacksmithing enchanting engineering leatherworking",
    -- the rest by what they are
    ["Life-Staff of the Web Lair"] = "inscription", ["Vithrak, Gaze of the Deadman"] = "jewelcrafting", ["Crystal Ball"] = "jewelcrafting",
    ["Dust of Sneezing and Choking"] = "alchemy", ["Instrument of the Bards, Ollamh Harp"] = "engineering", ["Steamwheedle Apparatus"] = "engineering",
}) do
    Eq(Makers(name), want, "who makes " .. name)
end
-- Up to rare with the skill, rarer learned.
for name, basic in pairs({ ["Sword of Wounding"] = true, ["Berserker Axe"] = true, Shadowfang = true, ["Defias Leather"] = true,
    ["Mariner's Armor"] = true, ["Vorpal Sword"] = false, ["Demon Armor"] = false, Oathbow = false, ["Judgment Armor"] = false }) do
    for key, recipe in pairs(makers[name]) do Eq(recipe.basic == true, basic, ("%s (%s) comes with the skill"):format(name, key)) end
end
-- Skill by rarity, and a named base in the price.
Eq(makers["Vorpal Sword"].blacksmithing.level, 6, "a legendary sword takes a master")
Eq(makers["Moon-Touched Sword"].blacksmithing.level, 2, "a common sword an apprentice")
Eq(ns.CraftCost("Shadowfang"), 200000 + R.ITEMS.Longsword.cost, "Shadowfang: rare, and the longsword")
Eq(ns.CraftCost("Defias Leather"), 200000 + R.ITEMS["Leather Armor"].cost, "Defias Leather: rare, and the leather armor")
Eq(R.ITEMS.Shadowfang.cost, 400000 + R.ITEMS.Longsword.cost, "and its price has the longsword in it")
Eq(ns.CraftCost("Ashbringer"), 0, "an artifact has no cost to make")

---------------------------------------------------------------------------
-- Learned for one profession
---------------------------------------------------------------------------
local sheet = NewChar("WARRIOR", 17)
for _, name in ipairs(R.TOOL_ORDER) do
    sheet.tools[name] = true
    if R.ITEMS[name] and not RPSheet:CarriedItem(name) then RPSheet:AddItem(name) end
end
local smith, ench = R.PROFESSIONS.blacksmithing, R.PROFESSIONS.enchanting
local engi, leather = R.PROFESSIONS.engineering, R.PROFESSIONS.leatherworking
local four = { smith, ench, engi, leather }
local function Known(name)
    local keys = {}
    for _, profession in ipairs(four) do
        local recipe = ns.FindRecipe(profession, name)
        if recipe and RPSheet:RecipeKnown(recipe) then keys[#keys + 1] = profession.key end
    end
    return table.concat(keys, " ")
end
Eq(Known("+3 Weapon"), "", "+3 Weapon: nobody knows it yet")
local mark = #PRINTED
RPSheet:LearnRecipe(ns.FindRecipe(ench, "+3 Weapon"), true)
Eq(Known("+3 Weapon"), "enchanting", "learned for enchanting alone")
Check(PrintedSince(mark):find("You now know how to make +3 Weapon with enchanting.", 1, true), "and said so: " .. PrintedSince(mark))
Eq(RPSheet:Trade().recipes["enchanting:+3 Weapon"], true, "saved under profession and item")
Eq(RPSheet:Trade().recipes["+3 Weapon"], nil, "not under the bare name")
RPSheet:AddCoins(100000000)
local can, why = RPSheet:CanCraft(smith, ns.FindRecipe(smith, "+3 Weapon"))
Check(not can and why == "you haven't learned it", "the smith hasn't: " .. tostring(why))
Check(RPSheet:CanCraft(ench, ns.FindRecipe(ench, "+3 Weapon")), "the enchanter makes it")
RPSheet:LearnRecipe(ns.FindRecipe(smith, "+3 Weapon"), true)
RPSheet:LearnRecipe(ns.FindRecipe(ench, "+3 Weapon"), false)
Eq(Known("+3 Weapon"), "blacksmithing", "forgetting one keeps the other")

-- An older character: learned by the item's name, which stood for every profession.
sheet.recipes = { ["+3 Weapon"] = true, ["Robe of Stars"] = true, ["leatherworking:+2 Armor"] = true, ["cooking:+3 Weapon"] = true, Longsword = true }
Run("NormalizeProfessions", ns.NormalizeProfessions, sheet)
Eq(Known("+3 Weapon"), "blacksmithing enchanting engineering leatherworking", "an old +3 Weapon is known to all four")
Check(sheet.recipes["tailoring:Robe of Stars"] == true, "an old recipe of one profession is carried over")
Check(sheet.recipes["leatherworking:+2 Armor"] == true and sheet.recipes["blacksmithing:+2 Armor"] == nil, "a new-style entry stays with its profession")
Check(sheet.recipes["+3 Weapon"] == nil and sheet.recipes["cooking:+3 Weapon"] == nil and sheet.recipes.Longsword == nil, "bare names and nonsense are gone")
local count = 0
for _ in pairs(sheet.recipes) do count = count + 1 end
Eq(count, 6, "entries after the conversion")
-- Once converted, forgetting one doesn't bring it back.
RPSheet:LearnRecipe(ns.FindRecipe(engi, "+3 Weapon"), false)
Run("NormalizeProfessions again", ns.NormalizeProfessions, sheet)
Eq(Known("+3 Weapon"), "blacksmithing enchanting leatherworking", "forgotten stays forgotten")
-- Through export and import.
local text = RPSheet:ExportSheet()
local back = Run("DecodeSheet", RPSheet.DecodeSheet, RPSheet, text)
if Check(type(back) == "table", "the export decodes") then
    Check(back.recipes["tailoring:Robe of Stars"] == true and back.recipes["blacksmithing:+3 Weapon"] == true and back.recipes["engineering:+3 Weapon"] == nil,
        "learned recipes survive an export")
end
-- An export from before: bare names.
sheet.recipes = { ["+3 Weapon"] = true }
back = Run("DecodeSheet old", RPSheet.DecodeSheet, RPSheet, RPSheet:ExportSheet())
if Check(type(back) == "table", "the old export decodes") then
    Check(back.recipes["enchanting:+3 Weapon"] == true and back.recipes["blacksmithing:+3 Weapon"] == true, "an old export's recipes are converted on import")
end

Done("recipes")
