-- What class, species, lineage, background and allegiance hand out: saving throw
-- proficiencies, skills, traits, the origin feat, class features, a starting language
-- and starting renown. Additive: it never removes anything the player put on a sheet.
local _, ns = ...
local R = ns.Rules

local function FindPassive(sheet, name)
    for index, passive in ipairs(sheet.passives) do
        if passive.name == name then return passive, index end
    end
end

local function FindAuto(list, key)
    for _, entry in ipairs(list) do
        if entry.auto == key then return entry end
    end
end

-- Where the feature comes from, followed by the glossary's summary of it.
local function Describe(name, origin)
    local summary = ns.Glossary[name]
    return summary and (origin .. " " .. summary) or origin
end

local function AddPassive(sheet, name, desc, effects)
    if FindPassive(sheet, name) then return end
    sheet.passives[#sheet.passives + 1] = {
        name = name, enabled = true, desc = desc, effects = CopyTable(effects or {}),
    }
end

local function AddSkills(sheet, skills)
    for _, skill in ipairs(skills or {}) do
        sheet.skills[skill] = math.max(sheet.skills[skill] or 0, 1)
    end
end

local function StartRenown(sheet, faction)
    if faction then
        sheet.renown[faction] = math.max(sheet.renown[faction] or 0, R.STARTING_RENOWN)
    end
end

---------------------------------------------------------------------------
local function ApplyClass(sheet, class)
    for _, stat in ipairs(class.saves) do sheet.saves[stat] = true end
    StartRenown(sheet, R.CLASS_RENOWN[sheet.class])
end

-- The lineage trait is one passive that follows the chosen lineage. Until a lineage
-- is chosen it is the general "choose a lineage" reminder.
local function ApplyLineage(sheet, species)
    local lineages, option = R.Lineage(sheet.species, sheet.lineage)
    if not lineages then return end
    local key = "lineage:" .. sheet.species
    local passive = FindAuto(sheet.passives, key)
    if not passive then
        -- Take over the plain reminder an earlier version may have added.
        local plain, index = FindPassive(sheet, lineages.trait)
        if plain and (plain.auto or "") == "" then table.remove(sheet.passives, index) end
        passive = { auto = key, enabled = true }
        sheet.passives[#sheet.passives + 1] = passive
    end
    if option then
        passive.name = option.name
        passive.desc = ("%s lineage. %s"):format(species.name, option.desc)
        passive.effects = CopyTable(option.effects or {})
        AddSkills(sheet, option.skills)
        StartRenown(sheet, option.renown)
    else
        passive.name = lineages.trait
        passive.desc = Describe(lineages.trait, species.name .. " trait.")
        passive.effects = {}
    end
end

local function ApplySpecies(sheet, species)
    -- A lineage passive left over from a previous species no longer applies.
    for index = #sheet.passives, 1, -1 do
        local auto = sheet.passives[index].auto or ""
        if auto:find("^lineage:") and auto ~= "lineage:" .. sheet.species then table.remove(sheet.passives, index) end
    end

    local sizeAllowed = false
    for _, size in ipairs(species.sizes) do
        sizeAllowed = sizeAllowed or size == sheet.size
    end
    if not sizeAllowed then sheet.size = species.sizes[#species.sizes] end

    local lineages = R.LINEAGES[sheet.species]
    for _, trait in ipairs(species.traits) do
        -- A trait with uses or dice is an ability, added by ns.ApplyTraits.
        if not (lineages and lineages.trait == trait) and not R.TraitIsAbility(trait) then
            AddPassive(sheet, trait, Describe(trait, species.name .. " trait."), species.effects and species.effects[trait])
        end
    end
    AddSkills(sheet, species.skills)
    ApplyLineage(sheet, species)

    local renown = R.SPECIES_RENOWN[sheet.species]
    if type(renown) == "table" then renown = renown[sheet.allegiance] end
    StartRenown(sheet, renown)
end

local function ApplyBackground(sheet, background)
    AddSkills(sheet, background.skills)
    AddPassive(sheet, background.feat,
        Describe(background.feat, "Origin feat from the " .. background.name .. " background."),
        R.FEAT_EFFECTS[background.feat])
end

-- Everyone speaks their side's common tongue.
local function ApplyAllegiance(sheet)
    local common = R.COMMON_LANGUAGE[sheet.allegiance]
    if common then sheet.languages[common] = true end
end

function ns.ApplyGrants(sheet)
    local class, species, background = R.CLASSES[sheet.class], R.SPECIES[sheet.species], R.BACKGROUNDS[sheet.background]
    ApplyAllegiance(sheet)
    if class then ApplyClass(sheet, class) end
    if species then ApplySpecies(sheet, species) end
    if background then ApplyBackground(sheet, background) end
    ns.ApplyClassFeatures(sheet)
    ns.ApplyLineageSpells(sheet)
    ns.ApplyTraits(sheet)
end
