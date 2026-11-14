-- Senses and damage resistances, gathered for the sheet's Combat section.
-- Darkvision comes from the species (or the beast form). Everything else is read from
-- the wording of the passives that are switched on, so a trait, feat, feature or one
-- of the player's own passives counts as soon as its text says "resistance to fire
-- damage" or "blindsight out to 30 feet".
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local DAMAGE_TYPES = {
    acid = true, bludgeoning = true, cold = true, fire = true, force = true, lightning = true, necrotic = true,
    piercing = true, poison = true, psychic = true, radiant = true, slashing = true, thunder = true,
}
local SENSES = { "Darkvision", "Blindsight", "Tremorsense", "Truesight" }

-- Calls visit(text) for the description of every passive that is switched on.
local function EachPassiveText(self, visit)
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= "" and type(passive.desc) == "string" then visit(passive.desc:lower()) end
    end
end

-- Damage types the character resists, sorted.
function RPSheet:Resistances()
    local found = {}
    EachPassiveText(self, function(text)
        -- "resistance to fire damage", "resist cold damage", "resists fire and cold damage"
        for phrase in text:gmatch("resist%a*%s+t?o?%s*([%a%s,]-) damage") do
            for word in phrase:gmatch("%a+") do
                if DAMAGE_TYPES[word] then found[word] = true end
            end
        end
    end)
    local list = {}
    for name in pairs(found) do list[#list + 1] = name end
    table.sort(list)
    return list
end

-- { "Darkvision 60 ft", "Blindsight 10 ft" }: the longest range of each sense.
function RPSheet:Senses()
    local range = {}
    local species, form = self:SpeciesData(), self:Form()
    if species and species.darkvision then range.Darkvision = species.darkvision end
    if form and form.darkvision then range.Darkvision = math.max(range.Darkvision or 0, form.darkvision) end
    EachPassiveText(self, function(text)
        for _, sense in ipairs(SENSES) do
            -- "blindsight out to 30 feet", "darkvision of 60 feet", "truesight 30 feet"
            for feet in text:gmatch(sense:lower() .. "[%a%s]-(%d+) feet") do
                range[sense] = math.max(range[sense] or 0, tonumber(feet))
            end
        end
    end)
    local list = {}
    for _, sense in ipairs(SENSES) do
        if range[sense] then list[#list + 1] = ("%s %d ft"):format(sense, range[sense]) end
    end
    return list
end
