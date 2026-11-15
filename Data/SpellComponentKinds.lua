-- Spell components that are not a thing carried for the purpose: a weapon that is at
-- hand, or a few coins from the purse. They join the parts of Data/SpellComponents.lua,
-- so the same check, tooltip and switch under Customize cover them. Also how many
-- targets a spell can have when it needs its components once for each.
--
-- A weapon part:  { weapon = "any" | "melee" | "proficient", cost = least worth in copper }
-- A coin part:    { coins = copper, consumed = true when the casting uses them up }
local _, ns = ...
local R = ns.Rules

local function Add(spell, part)
    R.SPELL_COMPONENTS[spell] = R.SPELL_COMPONENTS[spell] or {}
    table.insert(R.SPELL_COMPONENTS[spell], part)
end

Add("Conjure Barrage", { weapon = "any", cost = 1 })
Add("Conjure Volley", { weapon = "any", cost = 1 })
Add("Steel Wind Strike", { weapon = "melee", cost = 10 })
Add("True Strike", { weapon = "proficient", cost = 1 })
Add("Detect Thoughts", { coins = 1 })
Add("Gentle Repose", { coins = 2, consumed = true })

-- What a weapon part asks for, in words.
R.COMPONENT_WEAPONS = {
    any = "a melee or ranged weapon",
    melee = "a melee weapon",
    proficient = "a weapon you are proficient with",
}

-- Spells whose components are needed once for each target (the parts marked `each`):
--   max   the most targets one casting can have
--   up    more of them for each slot level above the spell's own
R.COMPONENT_TARGETS = {
    ["Astral Projection"] = { max = 9 }, -- the caster and up to eight others
    ["Create Undead"] = { max = 3, up = 1 },
}
