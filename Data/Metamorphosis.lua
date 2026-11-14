-- Metamorphosis: the three benefits its caster chooses between. Each is a passive of
-- the Demon Hunter that starts switched off; casting the spell asks which one to
-- take and switches it on (see Sheet/Metamorphosis.lua). Only one is on at a time.
--
-- R.METAMORPHOSIS.benefits[<passive name>] = {
--     label  what the menu calls it
--     took   what the announcement says about it
--     hp     current hit points gained when it starts
-- }
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

local LEVEL = 9 -- when a Demon Hunter learns the spell
local LASTS = " Lasts as long as the spell: switch it off when the spell ends. Taking another benefit ends this one."

R.METAMORPHOSIS = { spell = "Metamorphosis", benefits = {}, order = {} }

local function Benefit(label, took, desc, effects, extra, hp)
    local name = R.METAMORPHOSIS.spell .. ": " .. label
    extra.startsOff = true
    table.insert(R.SUBCLASS_FEATURES["Demon Hunter"], Kit.Passive(LEVEL, name, desc .. LASTS, effects, extra))
    R.METAMORPHOSIS.benefits[name] = { label = label, took = took, hp = hp }
    table.insert(R.METAMORPHOSIS.order, name)
end

Benefit("Chaos", "force damage dice of 1 or 2 count as 3",
    "On while Metamorphosis fills you with chaos. When you roll force damage, a die showing 1 or 2 counts as a 3. The sheet does this for the force spells it knows and for Hunter's Mark: damage.",
    nil, { flags = { forceMin = 3 } })
Benefit("Fel Flame", "melee weapon hits deal 1d6 more fire damage",
    "On while Metamorphosis wreathes your weapons in fel fire. Your melee weapon hits deal 1d6 more fire damage, which the sheet rolls with every melee attack.",
    nil, { strike = { sides = 6, damage = "fire" } })
Benefit("Demon Hide", "+2 Armor Class and 5 more hit points",
    "On while Metamorphosis hardens your skin. +2 Armor Class, and your current and maximum hit points are 5 higher.",
    { Kit.Bonus("AC", 2), Kit.Bonus("HP", 5) }, {}, 5)
