-- The damage types, and how a feature says which of them a character shrugs off.
--
-- A species trait (Data/Traits.lua), a lineage (Data/Lineages.lua), a feat, a form, a
-- condition, a class feature or an option of one (Data/FeatureKit.lua) can carry:
--   resist      { "fire", ... }   half damage, rounded down
--   immune      { ... }           no damage
--   vulnerable  { ... }           double damage
--   conditionImmune { "Charmed", ... }   conditions it can't be put under
--   whileOn     "Raging"          only while the passive of that name is switched on
-- On a class feature the lists may be function(level, sheet). They count while the
-- passive they belong to is switched on (see Sheet/Defenses.lua).
local _, ns = ...
local R = ns.Rules

R.DAMAGE_TYPES = {
    "acid", "bludgeoning", "cold", "fire", "force", "lightning", "necrotic",
    "piercing", "poison", "psychic", "radiant", "slashing", "thunder",
}
R.DAMAGE_TYPE = {}
for _, name in ipairs(R.DAMAGE_TYPES) do R.DAMAGE_TYPE[name] = true end

-- For a dropdown in the editor: the types by name, with "not set" first.
R.DAMAGE_TYPE_VALUES = { [""] = "Not set" }
R.DAMAGE_TYPE_ORDER = { "" }
for _, name in ipairs(R.DAMAGE_TYPES) do
    R.DAMAGE_TYPE_VALUES[name] = name:sub(1, 1):upper() .. name:sub(2)
    R.DAMAGE_TYPE_ORDER[#R.DAMAGE_TYPE_ORDER + 1] = name
end

R.WEAPON_DAMAGE = { "bludgeoning", "piercing", "slashing" }

-- Every damage type except the ones named: R.AllDamage("force").
function R.AllDamage(...)
    local skip, list = {}, {}
    for _, name in ipairs({ ... }) do skip[name] = true end
    for _, name in ipairs(R.DAMAGE_TYPES) do
        if not skip[name] then list[#list + 1] = name end
    end
    return list
end

-- "fire and cold", "all damage", "all damage except force": a sorted list in words.
function R.DamageList(list)
    local total = #R.DAMAGE_TYPES
    if #list == total then return "all damage" end
    if #list >= total - 4 then
        local have, missing = {}, {}
        for _, name in ipairs(list) do have[name] = true end
        for _, name in ipairs(R.DAMAGE_TYPES) do
            if not have[name] then missing[#missing + 1] = name end
        end
        return "all damage except " .. table.concat(missing, ", ")
    end
    return table.concat(list, ", ")
end
