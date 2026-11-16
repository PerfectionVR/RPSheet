-- Numbers worked out from the saved sheet: class, species, level, proficiency bonus,
-- and what the origin gives. The rest is in Sheet/Derived*.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

function RPSheet:ClassData()
    return R.CLASSES[self:Sheet().class]
end

function RPSheet:SpeciesData()
    return R.SPECIES[self:Sheet().species]
end

function RPSheet:Level()
    return self:Sheet().level
end

function RPSheet:ProficiencyBonus()
    return 2 + math.floor((self:Level() - 1) / 4)
end

-- The chosen lineage's entry (see Data/Lineages.lua), or nil.
function RPSheet:LineageData()
    local sheet = self:Sheet()
    local _, option = R.Lineage(sheet.species, sheet.lineage)
    return option
end

-- Darkvision range in feet, or nil. A lineage can extend the species' range.
function RPSheet:Darkvision()
    local species, lineage = self:SpeciesData(), self:LineageData()
    return lineage and lineage.darkvision or species and species.darkvision
end

-- Languages the character knows, sorted.
function RPSheet:Languages()
    local known = {}
    for _, language in ipairs(R.ALL_LANGUAGES) do
        if self:Sheet().languages[language] then known[#known + 1] = language end
    end
    return known
end
