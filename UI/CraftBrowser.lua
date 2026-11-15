-- The item browser on what the character's professions can make (UI/ItemBrowser.lua):
-- a tab per making profession it practises, each recipe as a block with what it
-- costs and how long it takes, and buttons to make it or to mark it as learned.
-- The Scrolls tab is in UI/ScribeTab.lua.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local Scribe = UI.Scribe
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local RED = "|cffff5555"

-- The Customize > Professions page, behind the cog of the crafting window.
function ns.OpenProfessionOptions()
    AceConfigDialog:Open(ADDON)
    AceConfigDialog:SelectGroup(ADDON, "customize", "professions")
end

-- After a button changed the character. The sheet is rebuilt on the next frame,
-- because the button is part of what gets rebuilt, and the browser with it; what the
-- button did may have asked for that already (paying), and it happens once.
local function Changed(self)
    ns.RebuildOptions() -- an item's page under Customize may have come
    self:ClampState()
    self:PopulateSoon()
end

local CRAFT = {
    first = { name = "Can make", tip = "Everything you can make right now." },
    empty = "Nothing you can make right now. A making profession opens with proficiency in one of its tools, and you need that tool with you; its tab then lists every recipe and what it still asks for.",
    options = function() ns.OpenProfessionOptions() end,
    title = function(self) return ("%s - Crafting"):format(self:GetCharacterName()) end,
    class = function() return nil end, -- judged by the active character
    find = function() return nil end,  -- a block describes the listed item, not a carried one
    ownListed = true,                  -- "Can make" repeats recipes of the other tabs
}

-- A tab per making profession the character practises.
function CRAFT.kinds(self)
    local tabs = {}
    for _, profession in ipairs(self:Professions("make")) do tabs[#tabs + 1] = profession.tab end
    if self:ScribeWays() then tabs[#tabs + 1] = Scribe.tab end
    return tabs
end

function CRAFT.standing(self)
    local level, parts = self:ProfessionLevel(), {}
    for _, kind in ipairs(R.MATERIAL_ORDER) do
        local worth = self:Trade().materials[kind]
        if worth > 0 then parts[#parts + 1] = ("%s %s%s|r"):format(R.MATERIALS[kind]:lower(), UI.ACCENT, ns.CoinText(worth)) end
    end
    return ("Skill %s%s (+%d)|r     Money %s%s|r     Materials %s\n%sMake pays with fitting materials you gathered first and coins for the rest; Coins only leaves the materials alone.|r"):format(
        UI.ACCENT, R.PROFESSION_LEVELS[level].name, level,
        UI.ACCENT, ns.CoinText(self:Coins()), #parts > 0 and table.concat(parts, ", ") or (UI.GREY .. "none|r"), UI.GREY)
end

-- A profession's recipes, the ones asking for the least skill first.
function CRAFT.list(self, tab)
    if tab.scribe then return Scribe.entries(self) end
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
    for _, entry in ipairs(self:ScribeWays() and Scribe.entries(self) or {}) do
        if self:CanScribe(entry.spell) then entries[#entries + 1] = entry end
    end
    return entries
end

function CRAFT.marks(self, entry)
    if entry.scribe then return Scribe.marks(self, entry) end
    local marks = { entry.profession.name:lower(), R.PROFESSION_LEVELS[entry.recipe.level].name:lower() }
    if entry.recipe.vehicle then
        if self:OwnedMount(entry.name) then marks[#marks + 1] = "you own one" end
        return marks
    end
    local carried = self:CarriedItem(entry.name)
    if carried then marks[#marks + 1] = "you have " .. carried.qty end
    return marks
end

-- A vehicle is described by the stable's words, a scroll by its spell.
function CRAFT.lines(self, entry)
    if entry.scribe then return Scribe.lines(self, entry) end
    if entry.recipe.vehicle then return UI.MountLines(self, entry.name) end
    return UI.ItemLines(self, entry.name)
end

function CRAFT.notes(self, entry)
    if entry.scribe then return Scribe.notes(self, entry) end
    local profession, recipe = entry.profession, entry.recipe
    local cost = ns.CraftCost(recipe.name)
    local lines = { ("%sTo make: materials worth %s and %s of work.|r"):format(UI.ACCENT, ns.CoinText(cost),
        ns.DaysText(self:CraftDays(profession, recipe.name))) }
    local base, open = R.RECIPE_BASE[recipe.name], R.RECIPE_OPEN[recipe.name]
    if base then lines[#lines + 1] = ("%sThat includes the price of the %s it is made from.|r"):format(UI.GREY, base:lower()) end
    if open then lines[#lines + 1] = ("%sThat is the magic alone: %s is bought or made apart, by a profession that makes its kind.|r"):format(UI.GREY, open) end
    if recipe.vehicle then lines[#lines + 1] = UI.GREY .. "Built, it stands with your mounts and vehicles. Building it asks no standing with a faction.|r" end
    if R.CONSUMABLES[recipe.name] then lines[#lines + 1] = UI.GREY .. "Used up when used: half the usual time and cost.|r" end
    if not recipe.basic then
        lines[#lines + 1] = UI.GREY .. (self:RecipeKnown(recipe) and "A recipe you learned.|r"
            or "Not part of the skill itself: it is learned from a trainer, a find or a faction, as the DM says.|r")
    end
    local can, why = self:CanCraft(profession, recipe)
    if not can then lines[#lines + 1] = ("%sNot now: %s.|r"):format(RED, why) end
    return lines
end

function CRAFT.buttons(self, card, entry)
    if entry.scribe then return Scribe.buttons(self, card, entry, Changed) end
    local profession, recipe = entry.profession, entry.recipe
    UI.AddItemButton(card, 0.5, "Make  " .. ns.CoinText((ns.CraftCost(recipe.name))), (self:CanCraft(profession, recipe)), function()
        if self:Craft(profession, recipe) then Changed(self) end
    end)
    -- The choice of what pays only matters while there are materials that could.
    if self:MaterialsFor(profession) > 0 then
        UI.AddItemButton(card, 0.5, "Coins only", (self:CanCraft(profession, recipe, true)), function()
            if self:Craft(profession, recipe, true) then Changed(self) end
        end)
    end
    if not recipe.basic then
        local known = self:RecipeKnown(recipe)
        UI.AddItemButton(card, 0.5, known and "Forget recipe" or "Learned it", true, function()
            self:LearnRecipe(recipe, not known)
            Changed(self)
        end)
    end
end

-- Opens the crafting window, on a profession's tab when one is given.
function RPSheet:ShowCrafting(profession)
    self:OpenItemBrowser(CRAFT, profession and profession.tab)
end
