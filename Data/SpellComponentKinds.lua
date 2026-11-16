-- Spell components that are not a thing carried for the purpose: a weapon that is at
-- hand, or a few coins from the purse. They join the parts of Data/SpellComponents.lua,
-- so the same check, tooltip and switch under Customize cover them. Also how many
-- targets a spell can have when it needs its components once for each.
--
-- A weapon part:  { weapon = "any" | "melee" | "proficient", cost = least worth in copper }
-- A coin part:    { coins = copper, consumed = true when the casting uses them up }
-- An ammunition part: { ammo = true, kinds = { { bundle = , single = } }, words = what
--                 they are called, qty = how many pieces, note = a line for the tooltip }
--                 (counted and taken in Sheet/ComponentAmmo.lua)
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
-- (Detect Thoughts' copper piece is neither priced nor used up: a focus or a component
-- pouch stands in for it, as for every such component, so it isn't asked for.)
Add("Gentle Repose", { coins = 2, consumed = true })

-- Ammunition is sold by the bundle; a single piece is listed too, at a twentieth of
-- the bundle's price and weight, so an opened bundle has something to turn into.
R.AddGear("Weapons and ammunition", "Arrow|5|0.05;Bolt|5|0.075")
Add("Cordon of Arrows", {
    ammo = true, qty = 4, upQty = 2, consumed = true, words = "arrows or bolts",
    kinds = { { bundle = "Arrows (20)", single = "Arrow" }, { bundle = "Bolts (20)", single = "Bolt" } },
    note = "A bundle counts as its twenty pieces: loose pieces go first, then a bundle is opened and what is left of it stays with you as loose pieces. Magic ammunition doesn't count. Four pieces are needed; a higher slot plants two more for each level above 2nd, as many of those as you carry. The planted pieces are taken off your list: put back any that are still in the ground when the spell ends.",
})

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
