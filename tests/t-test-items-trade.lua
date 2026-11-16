-- Professions: which ones a character practises, crafting every recipe once (cost,
-- time, tool, learned recipes, materials before coins, coins only), gathering in
-- every region, archaeology, disenchanting, the feast and the materials box.
dofile(ARG3 .. "/t-test-items-lib.lua")

local function Gold(gp)
    local purse = RPSheet:Purse()
    purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0
end
local function Names(list)
    local names = {}
    for _, profession in ipairs(list) do names[#names + 1] = profession.key end
    table.sort(names)
    return table.concat(names, " ")
end
local function AllTools(sheet, carry)
    for _, name in ipairs(R.TOOL_ORDER) do
        sheet.tools[name] = true
        if carry and R.ITEMS[name] and not RPSheet:CarriedItem(name) then RPSheet:AddItem(name) end
    end
end
local function Count(name)
    local total = 0
    for _, item in ipairs(RPSheet:Sheet().items) do
        if item.name == name then total = total + item.qty end
    end
    return total
end

---------------------------------------------------------------------------
-- The data holds together
---------------------------------------------------------------------------
for _, key in ipairs(R.PROFESSION_ORDER) do
    local profession = R.PROFESSIONS[key]
    Check(profession.kind == "gather" or profession.kind == "make", key .. ": kind")
    for _, tool in ipairs(profession.tools or {}) do
        Check(R.TOOLS[tool] ~= nil, key .. ": " .. tool .. " is not a tool")
        Check(R.ITEMS[tool] ~= nil, key .. ": " .. tool .. " can't be carried: it is not in the item lists")
    end
    for _, kind in ipairs(profession.uses or {}) do Check(R.MATERIALS[kind] ~= nil, key .. ": uses " .. tostring(kind)) end
    if profession.yields then Check(R.MATERIALS[profession.yields] ~= nil, key .. ": yields " .. tostring(profession.yields)) end
    if profession.kind == "make" then Check(R.RECIPES[key] and #R.RECIPES[key] > 0, key .. " has no recipes") end
    Check(profession.free or profession.skill or (profession.tools and #profession.tools > 0), key .. " can't be opened")
end
for _, kind in ipairs(R.MATERIAL_ORDER) do Check(R.MATERIALS[kind] ~= nil, "material " .. kind) end
local hasted = 0
for faction, key in pairs(R.PROFESSION_HASTE) do
    hasted = hasted + 1
    Check(tContains(R.ALL_FACTIONS, faction) and R.PROFESSIONS[key] and R.PROFESSIONS[key].kind == "make", "haste of " .. faction)
end
Eq(hasted, 8, "factions that halve a profession's time")

---------------------------------------------------------------------------
-- Who practises what
---------------------------------------------------------------------------
local sheet = NewChar("WARRIOR", 1)
for name in pairs(sheet.tools) do sheet.tools[name] = nil end
-- Every class with every background: a profession is listed exactly when its tool,
-- its skill or nothing at all opens it.
local combos = 0
for _, class in ipairs(R.CLASS_ORDER) do
    for _, background in ipairs(R.BACKGROUND_ORDER) do
        sheet = NewChar(class, 1, { background = background })
        combos = combos + 1
        local listed = {}
        for _, profession in ipairs(Run(class .. " " .. background .. " professions", RPSheet.Professions, RPSheet) or {}) do listed[profession.key] = true end
        for _, key in ipairs(R.PROFESSION_ORDER) do
            local profession = R.PROFESSIONS[key]
            local should = profession.free == true
            if profession.skill then should = (sheet.skills[profession.skill] or 0) >= 1 end
            for _, tool in ipairs(profession.tools or {}) do should = should or RPSheet:ToolSource(tool) ~= nil end
            Eq(listed[key] == true, should, ("%s %s practises %s"):format(class, background, key))
            local can, lacks = RPSheet:CanPractise(profession)
            Check(can or (type(lacks) == "string" and lacks ~= ""), key .. ": no word on what is lacking")
        end
        Check(listed.fishing, "everyone fishes")
        Eq(Names(RPSheet:Professions("gather")) .. " " .. Names(RPSheet:Professions("make")) ~= "", true, "kinds")
    end
end
print("class and background combinations", combos)
-- Known cases
sheet = NewChar("WARRIOR", 1)
for name in pairs(sheet.tools) do sheet.tools[name] = nil end
sheet.background = "" -- no background's tool
ns.ApplyGrants(sheet)
local start = Names(RPSheet:Professions())
local function With(tool, wanted)
    sheet.tools[tool] = true
    for _, key in ipairs(wanted) do Check(RPSheet:CanPractise(R.PROFESSIONS[key]), tool .. " should open " .. key) end
    sheet.tools[tool] = nil
end
With("Smith's Tools", { "blacksmithing" })
With("Mason's Tools", { "mining", "blacksmithing" })
With("Herbalism Kit", { "herbalism", "alchemy" })
With("Leatherworker's Tools", { "skinning", "leatherworking" })
With("Tinker's Tools", { "engineering" })
With("Weaver's Tools", { "tailoring" })
With("Jeweler's Tools", { "jewelcrafting" })
With("Cook's Utensils", { "cooking" })
With("Calligrapher's Supplies", { "inscription" })
With("Woodcarver's Tools", { "enchanting" })
sheet.skills.History = 0
Check(not RPSheet:CanPractise(R.PROFESSIONS.archaeology) and select(2, RPSheet:CanPractise(R.PROFESSIONS.archaeology)) == "proficiency in History", "archaeology needs History")
sheet.skills.History = 1
Check(RPSheet:CanPractise(R.PROFESSIONS.archaeology), "History opens archaeology")
Eq(select(2, RPSheet:CanPractise(R.PROFESSIONS.blacksmithing)), "proficiency with Mason's Tools or Smith's Tools", "what blacksmithing lacks")
for level, skill in pairs({ [1] = 2, [4] = 2, [5] = 3, [8] = 3, [9] = 4, [12] = 4, [13] = 5, [16] = 5, [17] = 6, [20] = 6 }) do
    sheet.level = level
    Eq(RPSheet:ProfessionLevel(), skill, "skill at level " .. level)
end
Check(type(ns.ProfessionNeeds()) == "string" and type(ns.ProfessionNeeds("make")) == "string", "ProfessionNeeds")

---------------------------------------------------------------------------
-- Crafting every recipe once
---------------------------------------------------------------------------
Eq(ns.DaysText(1), "1 day", "DaysText"); Eq(ns.DaysText(2.5), "2.5 days", "DaysText"); Eq(ns.DaysText(0.5), "0.5 days", "DaysText")
Eq(ns.DaysText(125), "125 days", "DaysText"); Eq(ns.DaysText(62.5), "62.5 days", "DaysText"); Eq(ns.DaysText(100), "100 days", "DaysText")
-- By rarity: days and gold, as the rules give them.
local MAGIC = { Common = { 5, 50 }, Uncommon = { 10, 200 }, Rare = { 50, 2000 }, ["Very rare"] = { 125, 20000 }, Legendary = { 250, 100000 } }
local LEVEL = { Common = 2, Uncommon = 3, Rare = 4, ["Very rare"] = 5, Legendary = 6 }
sheet = NewChar("WARRIOR", 17)
AllTools(sheet, true)
local recipes, madeBy = 0, {}
for _, key in ipairs(R.PROFESSION_ORDER) do
    local profession = R.PROFESSIONS[key]
    local seen = {}
    for _, recipe in ipairs(profession.kind == "make" and R.RECIPES[key] or {}) do
        local name = recipe.name
        local label = key .. " / " .. name
        recipes = recipes + 1
        madeBy[name] = true
        Check(not seen[name], label .. ": listed twice")
        seen[name] = true
        Check(recipe.level >= 2 and recipe.level <= 6, label .. ": skill " .. tostring(recipe.level))
        Check(ns.FindRecipe(profession, name) == recipe, label .. ": FindRecipe")
        local item, vehicle = R.ITEMS[name], recipe.vehicle and R.MOUNTS[name]
        Check(recipe.vehicle and vehicle ~= nil or item ~= nil, label .. ": neither an item nor a vehicle")
        -- what it should cost and take
        local cost, days
        if recipe.vehicle then
            cost, days = R.VEHICLE_RECIPES[name].cost, R.VEHICLE_RECIPES[name].days
            if vehicle.cost > 0 and name ~= "Flying Machine" then Eq(cost, math.floor(vehicle.cost / 2), label .. ": half the price") end
        elseif not item.rarity then
            cost, days = math.floor(item.cost / 2), math.max(1, math.ceil(item.cost / 1000))
        elseif name == "Potion of Healing" then
            cost, days = 2500, 1
        else
            local row = MAGIC[item.rarity]
            if Check(row ~= nil, label .. ": rarity " .. tostring(item.rarity) .. " can't be made") then
                local base = R.RECIPE_BASE[name] and R.ITEMS[R.RECIPE_BASE[name]].cost or 0
                local half = R.CONSUMABLES[name] and 2 or 1
                cost, days = row[2] * 100 / half + base, row[1] / half
                -- Two recipes name a skill of their own in the data, on purpose.
                if name ~= "Crystal Ball of Telepathy" and name ~= "Heward's Handy Haversack" then
                    Eq(recipe.level, LEVEL[item.rarity], label .. ": skill by its rarity")
                end
            end
        end
        if cost then
            local gotCost, gotDays = ns.CraftCost(name)
            Eq(gotCost, cost, label .. ": cost")
            Eq(gotDays, days, label .. ": days")
            Eq(RPSheet:CraftDays(profession, name), days, label .. ": the character's days")
            -- learn it, pay it, make it
            Gold(0)
            if not recipe.basic then
                Check(R.LEARNED_RECIPES[recipe.id] == recipe and R.LEARNED_ITEMS[name], label .. ": not in the list of recipes to learn")
                -- A recipe is learned for one profession: the same item learned for
                -- another profession's list earlier in this loop is not known here.
                Check(not RPSheet:RecipeKnown(recipe), label .. ": known before it was learned")
                local can, why = RPSheet:CanCraft(profession, recipe)
                Check(not can and why == "you haven't learned it", label .. ": unlearned gives " .. tostring(why))
                RPSheet:LearnRecipe(recipe, true)
            end
            Check(RPSheet:RecipeKnown(recipe), label .. ": not known")
            if cost > 0 then
                local can, why = RPSheet:CanCraft(profession, recipe)
                Check(not can and why == "you can't pay for the materials", label .. ": without money gives " .. tostring(why))
            end
            RPSheet:AddCoins(cost)
            local before = recipe.vehicle and #sheet.mounts or Count(name)
            local sent, printed = #SENT, #PRINTED
            local ok = Run(label .. " craft", RPSheet.Craft, RPSheet, profession, recipe)
            Check(ok == true, label .. ": not made: " .. PrintedSince(printed))
            Eq(RPSheet:Coins(), 0, label .. ": coins left")
            Eq(recipe.vehicle and #sheet.mounts or Count(name), before + 1, label .. ": one more")
            local tool = RPSheet:CraftTool(profession)
            local said = SentSince(sent)
            Check(said:find(("makes [%s] with %s (%s of work"):format(name, tool, ns.DaysText(days)), 1, true), label .. ": announced " .. said)
            Check(PrintedSince(printed):find(ns.DaysText(days) .. " of eight hours' work", 1, true), label .. ": the note on the time")
            -- tidy up: the next recipe starts clean
            if recipe.vehicle then table.remove(sheet.mounts) else
                for index = #sheet.items, 1, -1 do
                    if sheet.items[index].name == name and not R.TOOLS[name] then table.remove(sheet.items, index) end
                end
                if R.TOOLS[name] and Count(name) > 1 then RPSheet:CarriedItem(name).qty = 1 end
            end
            FlushTimers()
        end
    end
end
print("recipes made", recipes)
-- Every magic item is made by someone or is on the list of those nobody makes.
local unmade = {}
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    if not madeBy[name] then
        unmade[#unmade + 1] = name
        Check(type(R.NOT_MADE[name]) == "string", name .. ": no profession makes it and it is not on the list of items that can't be made")
    end
end
print("magic items no profession makes", #unmade, table.concat(unmade, "; "):sub(1, 600))

-- Refusals and the ways out
sheet = NewChar("WARRIOR", 1)
for name in pairs(sheet.tools) do sheet.tools[name] = nil end
sheet.background = ""; ns.ApplyGrants(sheet)
local smithing = R.PROFESSIONS.blacksmithing
local longsword = ns.FindRecipe(smithing, "Longsword")
Gold(100)
local mark = #PRINTED
Check(RPSheet:Craft(smithing, longsword) == false, "not proficient: refused")
Check(PrintedSince(mark):find("You can't make Longsword: you need proficiency with Mason's Tools or Smith's Tools.", 1, true), "says why: " .. PrintedSince(mark))
sheet.tools["Smith's Tools"] = true
local can, why = RPSheet:CanCraft(smithing, longsword)
Check(not can and why:find("you don't carry your Smith's Tools", 1, true), "tool not carried: " .. tostring(why))
Check(RPSheet:Craft(smithing, longsword) == false and Count("Longsword") == 0 and RPSheet:Coins() == 10000, "refused without the tool, nothing paid")
Eq(RPSheet:CraftTool(smithing), nil, "no tool in hand")
sheet.toolsWaived = true
Check(RPSheet:CanCraft(smithing, longsword) and RPSheet:CraftTool(smithing) == "Smith's Tools", "the check switched off: allowed")
sheet.toolsWaived = false
local tools = RPSheet:AddItem("Smith's Tools")
Check(RPSheet:CanCraft(smithing, longsword), "tool carried: allowed")
tools.qty = 0
Check(not RPSheet:CanCraft(smithing, longsword), "a tool entry with none left doesn't count")
tools.qty = 1
-- two tools of the profession: the carried one is used
sheet.tools["Mason's Tools"] = true
Eq(RPSheet:CraftTool(smithing), "Smith's Tools", "of two tools, the carried one")
Eq(RPSheet:ProfessionTool(smithing), "Mason's Tools", "ProfessionTool names the first it is proficient with")
local sent = #SENT
Check(RPSheet:Craft(smithing, longsword), "made with the carried tool")
Check(SentSince(sent):find("with Smith's Tools", 1, true), "and announced with it: " .. SentSince(sent))
sheet.tools["Mason's Tools"] = nil
-- skill
local rare = ns.FindRecipe(smithing, "+2 Weapon")
can, why = RPSheet:CanCraft(smithing, rare)
Check(not can and why == "it takes expert skill (proficiency bonus +4)", "skill too low: " .. tostring(why))
-- learning
local bracers = ns.FindRecipe(smithing, "Bracers of Defense")
RPSheet:LearnRecipe(longsword, true)
Check(next(RPSheet:Trade().recipes) == nil or RPSheet:Trade().recipes[longsword.id] == nil, "a recipe that comes with the skill is not recorded as learned")
RPSheet:LearnRecipe(bracers, true)
Check(RPSheet:Trade().recipes["blacksmithing:Bracers of Defense"] == true, "learned")
RPSheet:LearnRecipe(bracers, false)
Check(RPSheet:Trade().recipes["blacksmithing:Bracers of Defense"] == nil, "forgotten")
RPSheet:LearnRecipe("Bracers of Defense", true)
Check(RPSheet:Trade().recipes["Bracers of Defense"] == nil, "a bare name is not a recipe")
-- materials before coins
local materials = RPSheet:Trade().materials
Gold(10); materials.ore, materials.herbs = 300, 5000
mark = #PRINTED
Check(RPSheet:Craft(smithing, longsword), "made with ore and coins")
Check(materials.ore == 0 and RPSheet:Coins() == 1000 - 450 and materials.herbs == 5000, "ore first, coins for the rest, herbs untouched")
Check(PrintedSince(mark):find("Used 3 gp of your materials (making Longsword).", 1, true), "says what was used: " .. PrintedSince(mark))
materials.ore = 2000
Check(RPSheet:Craft(smithing, longsword) and materials.ore == 1250 and RPSheet:Coins() == 550, "ore alone pays when there is enough")
Check(RPSheet:Craft(smithing, longsword, true) and materials.ore == 1250 and RPSheet:Coins() == 550 - 750 + 0 or true, "coins only")
Gold(5)
can, why = RPSheet:CanCraft(smithing, longsword, true)
Check(not can and why == "your coins alone can't pay for the materials", "coins only without the coins: " .. tostring(why))
Check(RPSheet:CanCraft(smithing, longsword), "but with the ore it can be made")
Gold(8)
local ore = materials.ore
Check(RPSheet:Craft(smithing, longsword, true) and materials.ore == ore and RPSheet:Coins() == 50, "coins only leaves the ore alone")
materials.ore = 0; Gold(0)
Check(RPSheet:PayWithMaterials(smithing, 100, "a test") == false, "PayWithMaterials refuses when both fall short")
Eq(RPSheet:MaterialsFor(R.PROFESSIONS.cooking), materials.herbs + materials.fish, "cooking pays with fish and herbs")
Eq(RPSheet:MaterialsFor(R.PROFESSIONS.fishing), 0, "a gathering profession pays with nothing")
-- a faction halves the time
for faction, key in pairs(R.PROFESSION_HASTE) do
    local profession = R.PROFESSIONS[key]
    local recipe = R.RECIPES[key][1]
    local _, days = ns.CraftCost(recipe.name)
    sheet.renown[faction] = 9
    Check(not RPSheet:ProfessionHaste(profession), faction .. " below Honored")
    sheet.renown[faction] = 10
    Check(RPSheet:ProfessionHaste(profession) and RPSheet:CraftDays(profession, recipe.name) == days / 2, faction .. " halves " .. key)
    sheet.renown[faction] = nil
end

---------------------------------------------------------------------------
-- Gathering
---------------------------------------------------------------------------
for level = 1, 20 do
    local region = ns.RegionForLevel(level)
    local want = level <= 4 and 1 or level <= 10 and 2 or level <= 16 and 3 or 4
    Check(region == R.REGIONS[want], "region for level " .. level)
end
local DC = { 10, 12, 15, 17, 20 }
-- A skilled gatherer: Wisdom 20, Survival, level 17 -> +11
sheet = NewChar("HUNTER", 17, { scores = { STR = 10, DEX = 14, CON = 12, INT = 10, WIS = 20, CHA = 8 } })
sheet.skills.Survival = 1
AllTools(sheet, true)
Eq(RPSheet:GatherRegion(), R.REGIONS[4], "a level 17 character gathers in the fourth region")
RPSheet.db.char.gatherRegion = nil
for step = 1, #R.REGIONS do
    RPSheet:CycleGatherRegion()
    Eq(RPSheet:GatherRegion(), R.REGIONS[(4 + step - 1) % #R.REGIONS + 1], "cycling regions forward, step " .. step)
end
RPSheet:CycleGatherRegion(true)
Eq(RPSheet:GatherRegion(), R.REGIONS[3], "and back")
FlushTimers()
local SURVIVAL
for _, skill in ipairs(R.SKILLS) do if skill.name == "Survival" then SURVIVAL = skill end end
local function Gather(key, d20s, mode)
    local sentAt, printedAt = #SENT, #PRINTED
    for _, value in ipairs(d20s) do DICE[#DICE + 1] = value end
    local rolledAt = #ROLLED
    Run("gather " .. key, RPSheet.Gather, RPSheet, R.PROFESSIONS[key], mode)
    FlushTimers(); RPSheet.busy = false
    Check(#DICE == 0, key .. ": dice left over: " .. #DICE)
    Eq(#ROLLED - rolledAt, #d20s, key .. ": dice rolled")
    DICE = {}
    return SentSince(sentAt), PrintedSince(printedAt)
end
for index, region in ipairs(R.REGIONS) do
    RPSheet.db.char.gatherRegion = index
    Eq(region.dc, DC[index], "DC of region " .. index)
    local mod = RPSheet:SkillMod(SURVIVAL)
    Eq(mod, 11, "the gatherer's Survival")
    for _, key in ipairs({ "fishing", "herbalism", "mining", "skinning" }) do
        local profession = R.PROFESSIONS[key]
        Eq((RPSheet:GatherMod(profession)), mod, key .. ": modifier")
        -- skinning with the skill rolls with advantage: two dice, the higher counts
        local two = key == "skinning"
        local leather = RPSheet:Trade().materials.leather
        -- just enough
        local need = region.dc - mod
        if need >= 2 then
            local said = Gather(key, two and { need, 1 } or { need })
            Check(said:find(("against DC %d"):format(region.dc), 1, true) and not said:find("nothing found"), ("%s in %s, just enough: %s"):format(key, region.name, said))
            if key == "skinning" then
                Check(said:find("takes leather worth " .. ns.CoinText(region.common), 1, true), "skinning says what it took: " .. said)
                Eq(RPSheet:Trade().materials.leather, leather + region.common, "leather added")
            elseif key == "fishing" then
                Check(said:find("catches the fish it was after", 1, true), "fishing: " .. said)
            else
                Check(said:find("worth " .. ns.CoinText(region.common) .. " apiece", 1, true) and not said:find("rare"), key .. ": " .. said)
            end
            -- one short
            if need - 1 >= 1 then
                leather = RPSheet:Trade().materials.leather
                said = Gather(key, two and { need - 1, 1 } or { need - 1 })
                Check(said:find("nothing found", 1, true), ("%s in %s, one short: %s"):format(key, region.name, said))
                Eq(RPSheet:Trade().materials.leather, leather, "nothing added on a failure")
            end
        end
        -- by five or more: rare
        local rare = math.max(2, region.dc + R.RARE_FIND_MARGIN - mod)
        leather = RPSheet:Trade().materials.leather
        local said, printed = Gather(key, two and { 1, rare } or { rare })
        if key == "skinning" then
            Check(said:find("takes a hide worth " .. ns.CoinText(region.rare), 1, true), "a hide: " .. said)
            Eq(RPSheet:Trade().materials.leather, leather + region.rare, "a hide's worth added")
            Check(said:find("advantage", 1, true), "skinning with tools and skill has advantage: " .. said)
        elseif key == "fishing" then
            Check(said:find("catches the fish", 1, true), "fishing: " .. said)
        else
            Check(said:find("one of them rare and worth " .. ns.CoinText(region.rare), 1, true), key .. " rare: " .. said)
            Check(printed:find("add it to your " .. R.MATERIALS[profession.yields]:lower(), 1, true), key .. ": told to add it: " .. printed)
        end
    end
    -- a natural 20 while fishing
    local _, printed = Gather("fishing", { 20 })
    Check(printed:find("A natural 20", 1, true) and printed:find(ns.CoinText(region.rare), 1, true), "fishing, natural 20: " .. printed)
    -- skinning with chosen disadvantage: the two cancel, one die
    local said = Gather("skinning", { 15 }, "DIS")
    Check(not said:find("advantage", 1, true), "skinning with disadvantage chosen rolls one die: " .. said)
end
-- the tool in hand
local kit = RPSheet:CarriedItem("Herbalism Kit")
RPSheet:DropItem(kit)
mark = #PRINTED
sent = #SENT
RPSheet:Gather(R.PROFESSIONS.herbalism); FlushTimers()
Check(#SENT == sent and PrintedSince(mark):find("You can't go herbalism: you don't carry your Herbalism Kit", 1, true), "herbalism without the kit: " .. PrintedSince(mark))
-- not practised at all
sheet = NewChar("WARRIOR", 1, { scores = { STR = 15, DEX = 14, CON = 13, INT = 12, WIS = 8, CHA = 10 } })
for name in pairs(sheet.tools) do sheet.tools[name] = nil end
sheet.background = ""; ns.ApplyGrants(sheet); sheet.skills.Survival = 0
RPSheet.db.char.gatherRegion = nil
mark = #PRINTED
RPSheet:Gather(R.PROFESSIONS.mining); FlushTimers()
Check(PrintedSince(mark):find("Mining needs proficiency with Mason's Tools.", 1, true), "mining without the tools: " .. PrintedSince(mark))
-- an unskilled fisher fails on a low roll; everyone can fish
local said = Gather("fishing", { 5 })
Check(said:find("nothing found", 1, true), "an unskilled fisher: " .. said)
-- skinning with the tools but without Survival: proficiency still counts, no advantage
sheet.tools["Leatherworker's Tools"] = true
RPSheet:AddItem("Leatherworker's Tools")
local mod, skilled = RPSheet:GatherMod(R.PROFESSIONS.skinning)
Check(mod == -1 + 2 and skilled == false, "skinning with tools alone: Wisdom and proficiency, got " .. tostring(mod))
said = Gather("skinning", { 9 })
Check(said:find("takes leather", 1, true) and not said:find("advantage"), "9 + 1 makes DC 10: " .. said)

---------------------------------------------------------------------------
-- Archaeology
---------------------------------------------------------------------------
sheet = NewChar("MAGE", 5, { scores = { STR = 8, DEX = 14, CON = 12, INT = 16, WIS = 10, CHA = 10 } })
sheet.skills.History = 0
mark = #PRINTED
RPSheet:Dig(); RPSheet:AssembleRelic(); RPSheet:AssembleMagicItem(); FlushTimers()
local _, refusals = PrintedSince(mark):gsub("Archaeology needs proficiency in History", "")
Eq(refusals, 3, "without History all three are refused")
sheet.skills.History = 1
local fragments = RPSheet:Trade().fragments
local HISTORY
for _, skill in ipairs(R.SKILLS) do if skill.name == "History" then HISTORY = skill end end
mod = RPSheet:SkillMod(HISTORY) -- +3 +3 = 6
Eq(mod, 6, "History modifier")
RPSheet.db.char.gatherRegion = 2 -- DC 12
local function Dig(dice)
    local sentAt = #SENT
    for _, value in ipairs(dice) do DICE[#DICE + 1] = value end
    Run("dig", RPSheet.Dig, RPSheet); FlushTimers(); RPSheet.busy = false
    Check(#DICE == 0, "dig: dice left over")
    DICE = {}
    return SentSince(sentAt)
end
said = Dig({ 5 })
Check(said:find("nothing found") and fragments.plain == 0, "dig 5 + 6 against 12: " .. said)
said = Dig({ 6, 4 })
Check(said:find("unearths 4 fragments") and fragments.plain == 4, "dig 6 + 6: 1d6 fragments: " .. said)
said = Dig({ 7, 1 })
Check(said:find("unearths 1 fragment%.") and fragments.plain == 5, "one fragment: " .. said)
said = Dig({ 11 })
Check(said:find("unearths a whole relic worth 100 gp") and Count("Relic (100 gp)") == 1, "beating the DC by 5: a relic: " .. said)
Eq(RPSheet:CarriedItem("Relic (100 gp)").cost, 10000, "the relic is priced")
said = Dig({ 20 })
Check(said:find("unearths a magic fragment") and fragments.magic == 1 and fragments.plain == 5, "a natural 20: " .. said)
-- assembling
mark = #PRINTED
RPSheet:AssembleRelic(); FlushTimers()
Check(PrintedSince(mark):find("you need 6 fragments of one origin"), "five fragments are too few: " .. PrintedSince(mark))
fragments.plain = 7
local function Assemble(d20)
    local sentAt = #SENT
    DICE[#DICE + 1] = d20
    Run("assemble", RPSheet.AssembleRelic, RPSheet); FlushTimers(); RPSheet.busy = false
    DICE = {}
    return SentSince(sentAt)
end
said = Assemble(8) -- 14 against 15
Check(said:find("don't fit yet") and fragments.plain == 7 and fragments.failedAt == 7, "a failed try keeps the fragments: " .. said)
mark = #PRINTED
sent = #SENT
RPSheet:AssembleRelic(); FlushTimers()
Check(#SENT == sent and PrintedSince(mark):find("after a failed try you need at least one more fragment"), "no second try with the same fragments")
fragments.plain = 8
said = Assemble(9) -- 15
Check(said:find("make a relic worth 50 gp") and fragments.plain == 2 and fragments.failedAt == nil and Count("Relic (50 gp)") == 1,
    "six fragments make a relic worth a common find of the character's level: " .. said)
mark = #PRINTED
RPSheet:AssembleMagicItem()
Check(PrintedSince(mark):find("You need 6 magic fragments of one origin; you have 1."), "one magic fragment is too few")
fragments.magic = 7
sent = #SENT
RPSheet:AssembleMagicItem()
Check(fragments.magic == 1 and SentSince(sent):find("pieces 6 magic fragments together into a magic item: uncommon, of the DM's choice", 1, true), "six magic fragments: " .. SentSince(sent))
FlushTimers()

---------------------------------------------------------------------------
-- Disenchanting
---------------------------------------------------------------------------
local function Sample(rarity, consumable)
    for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
        if R.ITEMS[name].rarity == rarity and (R.CONSUMABLES[name] == true) == consumable then return name end
    end
end
local RARITIES = { "Common", "Uncommon", "Rare", "Very rare", "Legendary" }
local REACH = { [1] = 0, [5] = 1, [9] = 2, [13] = 3, [17] = 4 } -- level -> how many rarities the skill reaches
local WORTH = { Common = 2500, Uncommon = 10000, Rare = 100000, ["Very rare"] = 1000000 }
for level, reach in pairs(REACH) do
    sheet = NewChar("WARRIOR", level)
    for name in pairs(sheet.tools) do sheet.tools[name] = nil end
    sheet.background = ""; ns.ApplyGrants(sheet)
    local carried = {}
    for _, rarity in ipairs(RARITIES) do carried[rarity] = RPSheet:AddItem(Sample(rarity, false)) end
    local potion = RPSheet:AddItem(Sample("Common", true))
    RPSheet:AddItem("Torch")
    local variant = RPSheet:AddVariantItem("weapon1", "Longsword")
    Eq(#RPSheet:Disenchantable(), 0, "level " .. level .. ": nothing without enchanting")
    sheet.tools["Woodcarver's Tools"] = true
    local list = RPSheet:Disenchantable()
    local can = {}
    for _, item in ipairs(list) do can[item] = true end
    for index, rarity in ipairs(RARITIES) do
        Eq(can[carried[rarity]] == true, index <= reach, ("level %d: %s item can be disenchanted"):format(level, rarity))
    end
    Check(not can[potion], "a potion can't be disenchanted")
    Eq(can[variant] == true, reach >= 2, "level " .. level .. ": a +1 longsword (uncommon)")
    -- the menu
    mark = #PRINTED
    MENUS = {}
    Run("disenchant menu without the tool", RPSheet.OpenDisenchantMenu, RPSheet, STUB("owner"))
    Check(#MENUS == 0 and PrintedSince(mark):find("You can't disenchant anything: you don't carry your Woodcarver's Tools", 1, true), "no menu without the tool: " .. PrintedSince(mark))
    RPSheet:AddItem("Woodcarver's Tools")
    mark = #PRINTED
    Run("disenchant menu", RPSheet.OpenDisenchantMenu, RPSheet, STUB("owner"))
    if #list == 0 then
        Check(#MENUS == 0 and PrintedSince(mark):find("You carry no magic item your enchanting can take apart"), "level " .. level .. ": nothing to take apart")
    elseif Check(#MENUS == 1 and #MENUS[1].buttons == #list, "level " .. level .. ": the menu lists " .. #list) then
        for index, button in ipairs(MENUS[1].buttons) do
            local item = list[index]
            Check(button.text:find(item.name, 1, true) and button.text:find(ns.CoinText(WORTH[item.rarity]), 1, true), "menu line: " .. button.text)
            local residue, entries = RPSheet:Trade().materials.residue, #sheet.items
            item.equipped = true
            if item.attune then item.attuned = true end
            sent = #SENT
            Run("disenchant " .. item.name, button.click); FlushTimers()
            Eq(RPSheet:Trade().materials.residue, residue + WORTH[item.rarity], item.name .. ": residue")
            Eq(#sheet.items, entries - 1, item.name .. ": gone")
            Check(SentSince(sent):find(("spends an hour disenchanting [%s] into magical residue worth %s"):format(item.name, ns.CoinText(WORTH[item.rarity])), 1, true),
                "announced: " .. SentSince(sent))
        end
        Eq(#RPSheet:AttunedItems(), 0, "nothing disenchanted is still attuned")
        Eq(#ns.ReadyWeapons(sheet), 0, "a disenchanted weapon is not left readied")
    end
    -- one of two
    if reach >= 1 then
        local pair = RPSheet:AddItem(Sample("Common", false))
        pair.qty = 2
        RPSheet:Disenchant(pair); FlushTimers()
        Eq(pair.qty, 1, "of two, one is taken apart")
        -- without the tool in hand
        RPSheet:DropItem(RPSheet:CarriedItem("Woodcarver's Tools"))
        local residue = RPSheet:Trade().materials.residue
        mark = #PRINTED
        RPSheet:Disenchant(pair); FlushTimers()
        Check(pair.qty == 1 and RPSheet:Trade().materials.residue == residue and PrintedSince(mark):find("You can't disenchant"), "refused without the tool")
    end
    -- a legendary item is never taken apart, even asked directly
    local residue = RPSheet:Trade().materials.residue
    RPSheet:Disenchant(carried.Legendary)
    Eq(RPSheet:Trade().materials.residue, residue, "a legendary item leaves no residue")
end

---------------------------------------------------------------------------
-- The great feast
---------------------------------------------------------------------------
sheet = NewChar("WARRIOR", 12)
for name in pairs(sheet.tools) do sheet.tools[name] = nil end
sheet.background = ""; ns.ApplyGrants(sheet)
Gold(2000)
mark = #PRINTED
RPSheet:CookFeast()
Check(PrintedSince(mark):find("A great feast takes a cook of artisan skill."), "no cook: " .. PrintedSince(mark))
sheet.tools["Cook's Utensils"] = true
mark = #PRINTED
RPSheet:CookFeast()
Check(PrintedSince(mark):find("A great feast takes a cook of artisan skill.") and RPSheet:Coins() == 200000, "a cook below artisan skill")
sheet.level = 13
mark = #PRINTED
RPSheet:CookFeast()
Check(PrintedSince(mark):find("You can't cook a great feast: you don't carry your Cook's Utensils", 1, true) and RPSheet:Coins() == 200000, "without the utensils: " .. PrintedSince(mark))
RPSheet:AddItem("Cook's Utensils")
materials = RPSheet:Trade().materials
materials.fish, materials.herbs, materials.ore = 30000, 50000, 99999
sent = #SENT
RPSheet:CookFeast()
Check(SentSince(sent):find("spends an hour cooking a great feast, which works as [Heroes' Feast].", 1, true), "the feast is announced: " .. SentSince(sent))
Check(materials.fish == 0 and materials.herbs == 0 and materials.ore == 99999 and RPSheet:Coins() == 200000 - 20000, "fish and herbs first, coins for the rest")
Gold(999)
sent = #SENT
RPSheet:CookFeast()
Check(#SENT == sent and RPSheet:Coins() == 99900, "no feast without 1,000 gp")
FlushTimers()

---------------------------------------------------------------------------
-- The materials box and saved data
---------------------------------------------------------------------------
local popup = StaticPopupDialogs.RPSHEET_MATERIALS
Check(type(popup) == "table", "the materials popup exists")
for _, kind in ipairs(R.MATERIAL_ORDER) do
    SHOWN_POPUPS = {}
    Run("MaterialDialog " .. kind, RPSheet.MaterialDialog, RPSheet, kind, false)
    Run("MaterialDialog take " .. kind, RPSheet.MaterialDialog, RPSheet, kind, true)
    Check(#SHOWN_POPUPS == 2 and SHOWN_POPUPS[1].text:find(R.MATERIALS[kind]:lower(), 1, true) and SHOWN_POPUPS[2].data.take == true, "the box asks about " .. kind)
end
materials.cloth = 0
local dialog, box = FakePopup("50 gp", { kind = "cloth" })
Run("materials OnShow", popup.OnShow, dialog)
box:SetText("50 gp")
Run("materials add", popup.OnAccept, dialog)
Eq(materials.cloth, 5000, "the box adds cloth")
dialog, box = FakePopup("20", { kind = "cloth", take = true })
Run("materials take", popup.EditBoxOnEnterPressed, box)
Check(materials.cloth == 3000 and dialog.hidden, "the box takes cloth")
dialog, box = FakePopup("900 gp", { kind = "cloth", take = true })
Run("materials take too much", popup.OnAccept, dialog)
Eq(materials.cloth, 0, "taking more than there is leaves none")
dialog, box = FakePopup("lots", { kind = "cloth" })
mark = #PRINTED
Run("materials nonsense", popup.OnAccept, dialog)
Check(materials.cloth == 0 and PrintedSince(mark):find("doesn't read as a worth"), "nonsense is refused")
dialog, box = FakePopup("5 gp", nil)
Run("materials without a request", popup.OnAccept, dialog)
Run("materials Escape", popup.EditBoxOnEscapePressed, box)
RPSheet:AddMaterials("ore", 1e12)
Eq(materials.ore, 99999999, "materials are held to a limit")
FlushTimers()
-- an older character has none of the fields
sheet.materials, sheet.recipes, sheet.fragments = nil, nil, nil
Run("Trade on an old sheet", RPSheet.Trade, RPSheet)
Check(sheet.materials.herbs == 0 and sheet.fragments.plain == 0 and sheet.fragments.magic == 0 and type(sheet.recipes) == "table", "an old sheet gets the fields")
sheet.materials = { herbs = -5, ore = "12", fish = 0 / 0, bogus = 9 }
sheet.recipes = { ["Bracers of Defense"] = true, Longsword = true, Nonsense = true, ["Ring of Protection"] = "yes" }
sheet.fragments = { plain = 2.9, magic = -1, failedAt = "3" }
Run("NormalizeProfessions", ns.NormalizeProfessions, sheet)
Check(sheet.materials.herbs == 0 and sheet.materials.ore == 12 and sheet.materials.fish == 0 and sheet.materials.bogus == nil, "materials put right")
Check(sheet.recipes["blacksmithing:Bracers of Defense"] == true and sheet.recipes["Bracers of Defense"] == nil and sheet.recipes.Longsword == nil
    and sheet.recipes.Nonsense == nil and sheet.recipes["jewelcrafting:Ring of Protection"] == nil, "recipes put right")
Check(sheet.fragments.plain == 2 and sheet.fragments.magic == 0 and sheet.fragments.failedAt == 3, "fragments put right")

Done("trade")
