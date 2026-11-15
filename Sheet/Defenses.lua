-- The damage types the character resists, is immune to or is vulnerable to, and the
-- conditions it can't be put under (fields: see Data/DamageTypes.lua).
-- Everything is tied to something that can be switched off: a passive, the form the
-- character is in, a condition. Rules data names its types outright; only a passive
-- the player wrote is read by its wording (Sheet/DefenseText.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local FIELDS = { "resist", "immune", "vulnerable", "conditionImmune" }

-- Puts a class feature's lists on its passive (see Sheet/ClassFeatures.lua). They are
-- refreshed with the feature, so a list can follow the level or a choice.
function ns.CopyDefenses(entry, feature, sheet)
    for _, field in ipairs(FIELDS) do
        local list = feature[field]
        if type(list) == "function" then list = list(sheet.level, sheet) end
        entry[field] = type(list) == "table" and CopyTable(list) or nil
    end
    entry.whileOn = feature.whileOn
end

-- True if the species has the trait.
local function HasTrait(sheet, name)
    local species = R.SPECIES[sheet.species]
    for _, trait in ipairs(species and species.traits or {}) do
        if trait == name then return true end
    end
    return false
end

-- Names of every species' traits: a passive called like one is rules data, not the
-- player's own, even when the character's species has changed since.
local traitNames
local function IsTraitName(name)
    if not traitNames then
        traitNames = {}
        for _, species in pairs(R.SPECIES) do
            for _, trait in ipairs(species.traits) do traitNames[trait] = true end
        end
    end
    return traitNames[name] == true
end

-- { resist = { fire = "Fire Resistance" }, immune = {}, vulnerable = {},
--   conditionImmune = { Charmed = "Aura of Devotion" } }: each with where it comes from.
function RPSheet:Defenses()
    local sheet, state = self:Sheet(), self:State()
    local found, on = {}, {}
    for _, field in ipairs(FIELDS) do found[field] = {} end
    for _, passive in ipairs(sheet.passives) do
        if passive.enabled and passive.name ~= "" then on[passive.name] = true end
    end

    local function Note(field, name, source)
        if field == "conditionImmune" or R.DAMAGE_TYPE[name] then
            found[field][name] = found[field][name] or source
        end
    end
    local function Add(data, source)
        if type(data) ~= "table" or (data.whileOn and not on[data.whileOn]) then return end
        for _, field in ipairs(FIELDS) do
            for _, name in ipairs(type(data[field]) == "table" and data[field] or {}) do Note(field, name, source) end
        end
    end

    for _, passive in ipairs(sheet.passives) do
        if on[passive.name] and passive.enabled and not self:PassiveBlocked(passive) then
            local auto, name = passive.auto or "", passive.name
            local trait = R.TRAITS[auto:match("^trait:(.+)$") or ""]
            local feat = ns.FeatByName(name)
            Add(passive, name) -- a class feature carries its own lists
            -- Damage types the player chose for it (Sheet/DefensePicks.lua).
            for _, each in ipairs(ns.DefensePicks(sheet, name)) do Note("resist", each, name) end
            Add(feat, name)
            if trait and trait.passive and trait.passive.name == name then
                Add(trait.passive, name) -- the form a trait switches on
            elseif auto:find("^lineage:") then
                local _, option = R.Lineage(sheet.species, sheet.lineage)
                Add(option, name)
            elseif auto == "" and HasTrait(sheet, name) then
                Add(R.TRAITS[name], name)
            elseif auto == "" and not feat and not IsTraitName(name) and type(passive.desc) == "string" then
                -- Written by the player: the wording is all there is.
                ns.ReadDefenses(passive.desc, function(field, each) Note(field, each, name) end)
            end
        end
    end
    -- Armor made to resist a damage type, while it is worn and attuned (Sheet/ItemVariants.lua).
    for _, item in ipairs(sheet.items or {}) do
        local made = ns.ItemDefenses(item)
        if made and self:ItemActive(item) then Add(made, item.name) end
    end
    -- Damage types picked for a feat.
    for _, instance in ipairs(ns.FeatInstances(sheet)) do
        if instance.passive and instance.passive.enabled then
            ns.EachFeatPick(sheet.featChoices, instance, "resist", function(value)
                Note("resist", tostring(value):lower(), instance.name)
            end)
        end
    end
    local form = self:Form()
    if form then Add(form, form.name) end
    for _, condition in ipairs(R.CONDITIONS) do
        if state.conditions[condition.name] then Add(condition, condition.name) end
    end
    return found
end

-- The names found for one field, sorted, and a "name: source" line for each.
function ns.DefenseNames(entries)
    local names, lines = {}, {}
    for name in pairs(entries) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do lines[#lines + 1] = ("%s: %s"):format(name, entries[name]) end
    return names, lines
end

-- Damage types the character resists, sorted.
function RPSheet:Resistances()
    return (ns.DefenseNames(self:Defenses().resist))
end
