-- The character's professions (Data/Professions.lua): which it can practise, how
-- skilled it is, and what it has gathered. Saved on the sheet:
--   sheet.materials[<kind>]   worth of gathered materials, in copper
--   sheet.recipes[<item>]     true for a recipe learned from a trainer, a find or a faction
--   sheet.fragments           { plain, magic, failedAt }: archaeology finds
-- Nothing says which professions a character has: that follows from its tool and
-- skill proficiencies, and the skill level from its proficiency bonus.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local MAX_WORTH, MAX_FRAGMENTS = 99999999, 999

local function Whole(value, high)
    value = tonumber(value)
    if not value or value ~= value then return 0 end
    return math.max(0, math.min(high, math.floor(value)))
end

-- Makes the saved fields well-formed; a character from before professions has none.
-- `source` is the untrusted sheet an import was read from.
function ns.NormalizeProfessions(sheet, source)
    source = source or sheet
    local materials = type(source.materials) == "table" and source.materials or {}
    local recipes = type(source.recipes) == "table" and source.recipes or {}
    local fragments = type(source.fragments) == "table" and source.fragments or {}
    local clean = { materials = {}, recipes = {}, fragments = {} }
    for _, kind in ipairs(R.MATERIAL_ORDER) do clean.materials[kind] = Whole(materials[kind], MAX_WORTH) end
    for name in pairs(R.LEARNED_RECIPES) do
        if recipes[name] == true then clean.recipes[name] = true end
    end
    clean.fragments.plain, clean.fragments.magic = Whole(fragments.plain, MAX_FRAGMENTS), Whole(fragments.magic, MAX_FRAGMENTS)
    local failedAt = tonumber(fragments.failedAt)
    clean.fragments.failedAt = failedAt and Whole(failedAt, MAX_FRAGMENTS) or nil
    sheet.materials, sheet.recipes, sheet.fragments = clean.materials, clean.recipes, clean.fragments
end

-- The three saved fields of the active character, made whole on first use.
function RPSheet:Trade()
    local sheet = self:Sheet()
    local fragments = sheet.fragments
    if type(sheet.materials) ~= "table" or type(sheet.recipes) ~= "table" or type(fragments) ~= "table"
        or not fragments.plain or not fragments.magic or sheet.materials[R.MATERIAL_ORDER[1]] == nil then
        ns.NormalizeProfessions(sheet)
    end
    return sheet
end

-- Skill at every profession: the proficiency bonus, 2 (apprentice) to 6 (master).
function RPSheet:ProfessionLevel()
    return math.max(2, math.min(6, self:ProficiencyBonus()))
end

-- The tool the character practises the profession with: the first it is proficient
-- with. Nil when it has none, or when the profession needs no tool.
function RPSheet:ProfessionTool(profession)
    for _, name in ipairs(profession.tools or {}) do
        if self:ToolSource(name) then return name end
    end
end

-- True when the character can practise it. Otherwise false and what it lacks.
function RPSheet:CanPractise(profession)
    if profession.free then return true end
    if profession.skill then
        if (self:Sheet().skills[profession.skill] or 0) >= 1 then return true end
        return false, ("proficiency in %s"):format(profession.skill)
    end
    if self:ProfessionTool(profession) then return true end
    return false, "proficiency with " .. table.concat(profession.tools, " or ")
end

-- The professions the character can practise, of a kind ("gather", "make") or all.
function RPSheet:Professions(kind)
    local list = {}
    for _, key in ipairs(R.PROFESSION_ORDER) do
        local profession = R.PROFESSIONS[key]
        if (not kind or profession.kind == kind) and self:CanPractise(profession) then list[#list + 1] = profession end
    end
    return list
end

-- True when a faction the character is Honored with halves the profession's time.
function RPSheet:ProfessionHaste(profession)
    local renown = self:Sheet().renown or {}
    for faction, key in pairs(R.PROFESSION_HASTE) do
        local tier = R.RenownTier(tonumber(renown[faction]) or 0)
        if key == profession.key and tier ~= "" and tier ~= "Friendly" then return true end
    end
    return false
end

-- Worth of the materials a profession can pay with, in copper.
function RPSheet:MaterialsFor(profession)
    local materials, total = self:Trade().materials, 0
    for _, kind in ipairs(profession.uses or {}) do total = total + materials[kind] end
    return total
end

-- Adds to (or with a negative amount takes from) the materials of a kind.
function RPSheet:AddMaterials(kind, copper)
    local materials = self:Trade().materials
    materials[kind] = math.max(0, math.min(MAX_WORTH, materials[kind] + math.floor(copper)))
    self:PopulateSoon()
end

-- Pays `copper` for something made with the profession: its materials first, coins
-- for the rest. False, and nothing paid, when the two together fall short.
function RPSheet:PayWithMaterials(profession, copper, reason)
    local materials = self:Trade().materials
    local fromStock = math.min(copper, self:MaterialsFor(profession))
    if not self:CanAfford(copper - fromStock) then
        self:Print(("You can't afford %s (%s): you have %s in coins and %s in fitting materials."):format(
            ns.CoinText(copper), reason, ns.CoinText(self:Coins()), ns.CoinText(fromStock)))
        return false
    end
    local left = fromStock
    for _, kind in ipairs(profession.uses or {}) do
        local used = math.min(left, materials[kind])
        materials[kind], left = materials[kind] - used, left - used
    end
    if fromStock > 0 then self:Print(("Used %s of your materials (%s)."):format(ns.CoinText(fromStock), reason)) end
    return self:SpendCoins(copper - fromStock, reason)
end

-- The names of material kinds, in small letters: { "fish", "herbs" }.
function ns.MaterialNames(kinds)
    local names = {}
    for _, kind in ipairs(kinds or {}) do names[#names + 1] = R.MATERIALS[kind]:lower() end
    return names
end

-- What opens each profession of a kind (or all), one per line, for a tooltip.
function ns.ProfessionNeeds(kind)
    local lines = {}
    for _, key in ipairs(R.PROFESSION_ORDER) do
        local profession = R.PROFESSIONS[key]
        if not kind or profession.kind == kind then
            local needs = profession.free and "nothing" or profession.skill and (profession.skill .. " (skill)")
                or table.concat(profession.tools, " or ")
            lines[#lines + 1] = ("%s: %s"):format(profession.name, needs)
        end
    end
    return "Proficiency with one of these opens a profession:\n\n" .. table.concat(lines, "\n")
end
