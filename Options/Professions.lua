-- "Professions" page under Customize: which professions the character's proficiencies
-- open, and the gathered materials, archaeology fragments and learned recipes set
-- directly. Nothing here is held to the rules; a recipe beyond the skill shows in red.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

local GREY = "|cff909090"

-- Every profession with what opens it, the open ones lit.
local function Standing()
    local level = RPSheet:ProfessionLevel()
    local lines = { ("Skill at every profession you practise: %s%s (+%d)|r. It follows your proficiency bonus and can make magic items up to %s.\n"):format(
        Opt.GOLD, R.PROFESSION_LEVELS[level].name, level, R.PROFESSION_LEVELS[level].rarity:lower()) }
    for _, key in ipairs(R.PROFESSION_ORDER) do
        local profession = R.PROFESSIONS[key]
        local can, lacks = RPSheet:CanPractise(profession)
        local tool = RPSheet:CraftTool(profession) or RPSheet:ProfessionTool(profession)
        local missing = can and profession.kind == "make" and RPSheet:MissingTool(profession)
        lines[#lines + 1] = can and ("%s%s|r%s%s"):format(Opt.GREEN, profession.name, tool and (" with " .. tool) or "",
                missing and (" %s(%s)|r"):format(Opt.RED, missing) or "")
            or ("%s%s: needs %s|r"):format(GREY, profession.name, lacks)
    end
    lines[#lines + 1] = "\nA profession opens with proficiency in one of its tools (or, for archaeology, the History skill). Tick those on the Proficiencies page.\n"
    return table.concat(lines, "\n")
end

local args = {
    standing = { type = "description", order = 1, fontSize = "medium", name = Standing },
    toolCheck = {
        type = "toggle", order = 2, width = "full", name = "Check that you carry the tool",
        desc = "Making something takes the tool in hand, not only knowing how to use it. While this is on, a profession only makes things when one of its tools you are proficient with is among your items. Switch it off when your DM rules otherwise.",
        get = function() return Opt.Sheet().toolsWaived ~= true end,
        set = function(_, value) Opt.Sheet().toolsWaived = not value; Opt.Changed() end,
    },
    materialsHeader = { type = "header", order = 10, name = "Materials" },
    materialsHelp = {
        type = "description", order = 10.5,
        name = "What you gathered, bought or found, as a worth per kind. Write it like 50 gp; a bare number is gold. Making something pays with fitting materials before coins, unless you pick coins only in the crafting window.\n",
    },
    fragmentsHeader = { type = "header", order = 20, name = "Archaeology" },
    recipesHeader = { type = "header", order = 30, name = "Learned recipes" },
    recipesHelp = {
        type = "description", order = 30.5,
        name = "Plain gear, vehicles and the common, uncommon and rare magic arms, armor, potions, scrolls and wands come with the skill. The recipes below are learned from a trainer, a find or a faction: tick the ones the DM has given you. The crafting window has the same tick on each recipe.\n",
    },
}

for index, kind in ipairs(R.MATERIAL_ORDER) do
    args["material" .. kind] = {
        type = "input", order = 11 + index / 100, name = R.MATERIALS[kind],
        desc = ("The worth of the %s you have."):format(R.MATERIALS[kind]:lower()),
        get = function() return ns.CoinText(RPSheet:Trade().materials[kind]) end,
        set = function(_, value)
            local copper = ns.ParseCoins(value)
            if not copper then return end
            RPSheet:Trade().materials[kind] = math.min(99999999, copper)
            Opt.Changed()
        end,
    }
end

for index, field in ipairs({ "plain", "magic" }) do
    args["fragments" .. field] = {
        type = "range", order = 21 + index / 100, min = 0, max = 60, softMax = 12, step = 1,
        name = field == "plain" and "Fragments" or "Magic fragments",
        desc = field == "plain" and ("%d of one origin make a relic, with a DC %d History check."):format(R.RELIC_FRAGMENTS, R.RELIC_DC)
            or ("%d of one origin make a magic item of the DM's choice."):format(R.RELIC_FRAGMENTS),
        get = function() return RPSheet:Trade().fragments[field] end,
        set = function(_, value)
            local fragments = RPSheet:Trade().fragments
            fragments[field] = value
            if field == "plain" then fragments.failedAt = nil end -- a new count is a new try
            Opt.Changed()
        end,
    }
end

-- The profession (or professions) a learned recipe belongs to, and the skill it asks for.
local function RecipeHome(name)
    local homes, level = {}, 2
    for _, key in ipairs(R.PROFESSION_ORDER) do
        local profession = R.PROFESSIONS[key]
        local recipe = profession.kind == "make" and ns.FindRecipe(profession, name)
        if recipe then homes[#homes + 1], level = profession.name, recipe.level end
    end
    return table.concat(homes, ", "), level
end

local names = {}
for name in pairs(R.LEARNED_RECIPES) do names[#names + 1] = name end
table.sort(names)
for index, name in ipairs(names) do
    local homes, level = RecipeHome(name)
    args["recipe" .. index] = {
        type = "toggle", order = 31 + index / 1000, width = 1.5,
        name = function()
            local beyond = RPSheet:Trade().recipes[name] and RPSheet:ProfessionLevel() < level
            return beyond and ("%s %s(beyond your skill)|r"):format(name, Opt.RED) or name
        end,
        desc = ("%s. Takes %s skill (proficiency bonus +%d)."):format(homes, R.PROFESSION_LEVELS[level].name:lower(), level),
        get = function() return RPSheet:Trade().recipes[name] == true end,
        set = function(_, value)
            RPSheet:Trade().recipes[name] = value or nil
            Opt.Changed()
        end,
    }
end

Opt.custom.professions = { type = "group", order = 9.5, name = "Professions", args = args }
