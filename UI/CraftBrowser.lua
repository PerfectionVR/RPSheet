-- The item browser on what the character's professions can make (UI/ItemBrowser.lua):
-- a tab per making profession it practises, each recipe as a block with what it
-- costs and how long it takes, and buttons to make it or to mark it as learned.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI

local RED = "|cffff5555"

-- After a button changed the character: on the next frame, because the button is part
-- of what gets rebuilt. Rebuilding the sheet rebuilds the browser too.
local function Changed(self)
    C_Timer.After(0, function()
        ns.RebuildOptions() -- an item's page under Customize may have come
        self:SheetChanged()
    end)
end

local CRAFT = {
    first = { name = "Can make", tip = "Everything you can make right now." },
    empty = "Nothing you can make right now. A making profession opens with proficiency in one of its tools; its tab then lists every recipe and what it still asks for.",
    title = function(self) return ("%s - Crafting"):format(self:GetCharacterName()) end,
    class = function() return nil end, -- judged by the active character
    find = function() return nil end,  -- a block describes the listed item, not a carried one
}

-- A tab per making profession the character practises.
function CRAFT.kinds(self)
    local tabs = {}
    for _, profession in ipairs(self:Professions("make")) do tabs[#tabs + 1] = profession.tab end
    return tabs
end

function CRAFT.standing(self)
    local level, parts = self:ProfessionLevel(), {}
    for _, kind in ipairs(R.MATERIAL_ORDER) do
        local worth = self:Trade().materials[kind]
        if worth > 0 then parts[#parts + 1] = ("%s %s%s|r"):format(R.MATERIALS[kind]:lower(), UI.ACCENT, ns.CoinText(worth)) end
    end
    return ("Skill %s%s (+%d)|r     Money %s%s|r     Materials %s"):format(UI.ACCENT, R.PROFESSION_LEVELS[level].name, level,
        UI.ACCENT, ns.CoinText(self:Coins()), #parts > 0 and table.concat(parts, ", ") or (UI.GREY .. "none|r"))
end

-- A profession's recipes, the ones asking for the least skill first.
function CRAFT.list(_, tab)
    local entries = {}
    for _, recipe in ipairs(R.RECIPES[tab.profession.key] or {}) do
        entries[#entries + 1] = { name = recipe.name, recipe = recipe, profession = tab.profession }
    end
    table.sort(entries, function(a, b)
        if a.recipe.level ~= b.recipe.level then return a.recipe.level < b.recipe.level end
        return a.name < b.name
    end)
    return entries
end

-- Every recipe of every practised profession that can be made as things stand.
function CRAFT.own(self)
    local entries = {}
    for _, profession in ipairs(self:Professions("make")) do
        for _, entry in ipairs(CRAFT.list(self, profession.tab)) do
            if self:CanCraft(profession, entry.recipe) then entries[#entries + 1] = entry end
        end
    end
    return entries
end

function CRAFT.marks(self, entry)
    local marks = { entry.profession.name:lower(), R.PROFESSION_LEVELS[entry.recipe.level].name:lower() }
    local carried = self:CarriedItem(entry.name)
    if carried then marks[#marks + 1] = "you have " .. carried.qty end
    return marks
end

function CRAFT.notes(self, entry)
    local profession, recipe = entry.profession, entry.recipe
    local cost = ns.CraftCost(recipe.name)
    local lines = { ("%sTo make: materials worth %s and %s of work.|r"):format(UI.ACCENT, ns.CoinText(cost),
        ns.DaysText(self:CraftDays(profession, recipe.name))) }
    local base, open = R.RECIPE_BASE[recipe.name], R.RECIPE_OPEN[recipe.name]
    if base then lines[#lines + 1] = ("%sThat includes the price of the %s it is made from.|r"):format(UI.GREY, base:lower()) end
    if open then lines[#lines + 1] = ("%sThat is the magic alone: %s is bought or made apart, by a profession that makes its kind.|r"):format(UI.GREY, open) end
    if not recipe.basic then
        lines[#lines + 1] = UI.GREY .. (self:RecipeKnown(recipe) and "A recipe you learned.|r"
            or "Not part of the skill itself: it is learned from a trainer, a find or a faction, as the DM says.|r")
    end
    local can, why = self:CanCraft(profession, recipe)
    if not can then lines[#lines + 1] = ("%sNot now: %s.|r"):format(RED, why) end
    return lines
end

function CRAFT.buttons(self, card, entry)
    local profession, recipe = entry.profession, entry.recipe
    UI.AddItemButton(card, 0.5, "Make  " .. ns.CoinText((ns.CraftCost(recipe.name))), (self:CanCraft(profession, recipe)), function()
        if self:Craft(profession, recipe) then Changed(self) end
    end)
    if not recipe.basic then
        local known = self:RecipeKnown(recipe)
        UI.AddItemButton(card, 0.5, known and "Forget recipe" or "Learned it", true, function()
            self:LearnRecipe(recipe.name, not known)
            Changed(self)
        end)
    end
end

-- Opens the crafting window, on a profession's tab when one is given.
function RPSheet:ShowCrafting(profession)
    self:OpenItemBrowser(CRAFT, profession and profession.tab)
end
