-- Making an item with a profession (recipes in Data/Recipes.lua): what it costs,
-- how long it takes, whether the character may, and the making itself. The sheet
-- keeps no clock, so the time is said in chat and left to the table.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Materials in copper and days of work (eight hours each) for a listed item.
-- Plain gear: half its price, a day per 10 gp of price. A magic item: by rarity,
-- halved for one that is used up, plus the full price of what it is made from.
function ns.CraftCost(name)
    local item = R.ITEMS[name]
    if not item.rarity then
        return math.floor(item.cost / 2), math.max(1, math.ceil(item.cost / R.CRAFT_COPPER_PER_DAY))
    end
    local row = R.CRAFT_FIXED[name] or R.MAGIC_CRAFT[item.rarity]
    if not row then return 0, 0 end -- an artifact is not made
    local cost, days = row.cost, row.days
    if R.CONSUMABLES[name] and not R.CRAFT_FIXED[name] then cost, days = cost / 2, days / 2 end
    local base = R.RECIPE_BASE[name]
    return math.floor(cost + (base and R.ITEMS[base].cost or 0)), days
end

-- 1 -> "1 day", 2.5 -> "2.5 days"
function ns.DaysText(days)
    local text = (("%.2f"):format(days):gsub("0+$", ""):gsub("%.$", ""))
    return text .. (days == 1 and " day" or " days")
end

-- Days the character itself needs: a faction can halve a profession's time.
function RPSheet:CraftDays(profession, name)
    local _, days = ns.CraftCost(name)
    return self:ProfessionHaste(profession) and days / 2 or days
end

-- True when the recipe needs no learning or was learned.
function RPSheet:RecipeKnown(recipe)
    return recipe.basic or self:Trade().recipes[recipe.name] == true
end

-- True when the character may make the recipe now. Otherwise false and why not.
function RPSheet:CanCraft(profession, recipe)
    local can, lacks = self:CanPractise(profession)
    if not can then return false, "you need " .. lacks end
    if self:ProfessionLevel() < recipe.level then
        return false, ("it takes %s skill (proficiency bonus +%d)"):format(R.PROFESSION_LEVELS[recipe.level].name:lower(), recipe.level)
    end
    if not self:RecipeKnown(recipe) then return false, "you haven't learned it" end
    local cost = ns.CraftCost(recipe.name)
    if self:MaterialsFor(profession) + self:Coins() < cost then return false, "you can't pay for the materials" end
    return true
end

-- The recipe for `name` in a profession's list, or nil.
function ns.FindRecipe(profession, name)
    for _, recipe in ipairs(R.RECIPES[profession.key] or {}) do
        if recipe.name == name then return recipe end
    end
end

-- Records that a recipe was learned (or, with false, forgets it). The sheet can't
-- know when a trainer, a find or a faction teaches one, so the player says so.
function RPSheet:LearnRecipe(name, known)
    if not R.LEARNED_RECIPES[name] then return end
    self:Trade().recipes[name] = known and true or nil
    if known then self:Print(("You now know how to make %s."):format(name)) end
end

-- Makes one: pays the materials (gathered ones first, then coins) and adds the item.
-- True when it was made.
function RPSheet:Craft(profession, recipe)
    local can, why = self:CanCraft(profession, recipe)
    if not can then
        self:Print(("You can't make %s: %s."):format(recipe.name, why))
        return false
    end
    local name = recipe.name
    if not self:PayWithMaterials(profession, ns.CraftCost(name), "making " .. name) then return false end
    self:AddItem(name, 1)
    local days = self:CraftDays(profession, name)
    local tool = self:ProfessionTool(profession)
    self:Announce(("makes %s with %s (%s of work)."):format(ns.Mark(name), tool or profession.name:lower(), ns.DaysText(days)))
    local notes = { ("%s of eight hours' work, which needn't follow one another. A helper proficient with the same tools halves it."):format(ns.DaysText(days)) }
    if R.RECIPE_OPEN[name] then
        notes[#notes + 1] = ("That is the magic alone: %s is bought or made apart."):format(R.RECIPE_OPEN[name])
    end
    self:Print(table.concat(notes, " "))
    return true
end
