-- Later rolls of spells that harm over the next turn or two, that keep healing, or that
-- name dice for one of their options or for something that may happen afterwards
-- (how an entry is written: Data/SpellLater.lua).
local _, ns = ...
local R = ns.Rules
local L, Same, Dice = R.SPELL_LATER, R.LaterSame, R.LaterDice

-- Damage at the start or end of the target's next turns -------------------------------
L["Melf's Acid Arrow"] = { rolls = { Dice("the end of the target's next turn, after a hit", 2, 4, "acid damage", { up = 1 }) } }
L["Moonfire"] = { rolls = { Dice("the end of the target's next turn, after a failed save", 1, 8, "radiant damage", { up = 1 }) } }
L["Sigil of Flame"] = { rolls = { Dice("the start of the target's next turn, for it and those near it", 1, 8, "fire damage", { save = "CON", up = 1 }) } }
L["Vitriolic Sphere"] = { rolls = { Dice("the end of its next turn, after a failed save", 5, 4, "acid damage") } }
L["Emberstorm"] = { rolls = { Dice("a burning creature starts its turn", 1, 8, "fire damage") } }
L["Death and Decay"] = { rolls = { Dice("your attack hits a cursed creature", 1, 6, "necrotic damage") } }
L["Searing Smite"] = { hours = 0, rolls = { Dice("the start of the target's turn", 1, 6, "fire damage", { save = "CON", up = 1 }) } }
L["Ensnaring Strike"] = { hours = 0, rolls = { Dice("the start of its turn while restrained", 1, 6, "piercing damage", { up = 1 }) } }
L["Shadow Word: Pain"] = { hours = 0, rolls = { Dice("the start of its turn while cursed", 1, 10, "psychic damage", { save = "WIS" }) } }
L["Serpent Sting"] = { hours = 0, rolls = { Dice("the end of its turn while poisoned", 2, 6, "poison damage", { save = "CON" }) } }
L["Weird"] = { hours = 0, rolls = { Dice("a frightened creature's save at the end of its turn", 5, 10, "psychic damage", { save = "WIS" }) } }
-- The bead grows by a die each time your turn ends; it bursts when the spell ends.
L["Delayed Blast Fireball"] = { hours = 0, quiet = true, rolls = {
    { label = "your turn ends: the bead grows by 1d6", tick = true },
    { label = "the bead explodes", same = true, ticks = true, ends = true } } }

-- Healing on later turns -----------------------------------------------------------------
L["Aura of Vitality"] = { hours = 0, rolls = { Same("the start of your turn: one creature in the aura") } }
L["Regrowth"] = { hours = 0, rolls = { Dice("the start of your turn", 1, 8, "healing", { dice = "HEALING" }) } }
L["Prayer of Mending"] = { hours = 0, rolls = { Same("the warded creature takes damage") } }
L["Tranquility"] = { hours = 0, rolls = { Same("your allies in the area (a bonus action)") } }
L["Dream Flight"] = { hours = 0, rolls = { Same("you move past a creature") } }
L["Emerald Blossom"] = { hours = 0, rolls = { Dice("the end of your turn: allies near the bulb", 0, 0, "healing", { dice = "HEALING", flat = 5 }) } }
L["Regenerate"] = { hours = 1, rolls = { Dice("the start of the target's turn", 0, 0, "healing", { dice = "HEALING", flat = 1 }) } }

-- Dice for an option or for what may follow ---------------------------------------------
L["Alter Self"] = { hours = 1, rolls = { Dice("a natural weapon strike", 1, 6, "damage", { attack = "weapon", addMod = true }) } }
L["Blistering Scales"] = { hours = 0, rolls = { Dice("a scale explodes on a melee attacker", 1, 8, "fire damage") } }
L["Breath of Eons"] = { hours = 0, rolls = { Dice("a cursed creature takes damage", 1, 10, "force damage") } }
L["Ebon Might"] = { rolls = { Dice("an empowered creature hits", 1, 4, "force damage") } }
L["Enlarge/Reduce"] = { hours = 0, rolls = { Dice("an enlarged creature's weapon hit", 1, 4, "damage"),
    Dice("a reduced creature's weapon hit (taken off, to 1 at least)", 1, 4, "less damage", { dice = "OTHER" }) } }
L["Entropic Embrace"] = { hours = 0, rolls = {
    Dice("Touch of the Void: you damage a creature", 1, 4, "necrotic damage", { up = 1 }),
    Dice("Touch of the Void: you heal a creature", 1, 4, "healing", { dice = "HEALING", up = 1 }) } }
L["Meld into Stone"] = { hours = 8, rolls = { Dice("you are forced out of the stone (damage to you)", 6, 6, "force damage", { toYou = true }) } }
L["Web"] = { hours = 1, rolls = { Dice("a creature starts its turn in burning webs", 2, 4, "fire damage") } }
L["Dimension Door"] = { rolls = { Dice("you arrive in an occupied space (each of you)", 4, 6, "force damage", { toYou = true }) } }
L["Teleport"] = { rolls = {
    Dice("the outcome (the DM's roll)", 1, 100, "on the table", { dice = "OTHER" }),
    Dice("a mishap (each who travels)", 3, 10, "force damage", { toYou = true }),
    Dice("off target: miles away", 2, 12, "miles", { dice = "OTHER" }),
    Dice("off target: direction (1 east, then clockwise)", 1, 8, "direction", { dice = "OTHER" }) } }
L["Wish"] = { rolls = {
    Dice("the stress of a spell you cast later", 1, 10, "necrotic damage", { levels = true, toYou = true }),
    Dice("days your Strength stays 3", 2, 4, "days", { dice = "OTHER" }) } }

-- A second roll the spell asks for --------------------------------------------------------
L["Prismatic Spray"] = { rolls = {
    Dice("which ray strikes a creature (8: two rays, rerolling 8s)", 1, 8, "ray", { dice = "OTHER" }),
    Dice("a red, orange, yellow, green or blue ray", 12, 6, "damage of its colour", { save = "DEX" }),
    Dice("indigo: its save at the end of each of its turns", 0, 0, nil, { save = "CON" }),
    Dice("violet: its save at the start of your next turn", 0, 0, nil, { save = "WIS" }) } }
L["Prismatic Wall"] = { hours = 0, rolls = {
    Dice("a creature comes within 20 feet: blinded unless it saves", 0, 0, nil, { save = "CON" }),
    Dice("a red, orange, yellow, green or blue layer", 12, 6, "damage of its colour", { save = "DEX" }),
    Dice("the indigo or violet layer", 0, 0, nil, { save = "DEX" }) } }
-- A glyph lasts until it is set off or dispelled: no rest ends it.
L["Symbol"] = { hours = 100000, rolls = {
    Dice("Death: a creature in the sphere", 10, 10, "necrotic damage", { save = "CON" }),
    Dice("Discord, Fear, Sleep or Stunning: a creature in the sphere", 0, 0, nil, { save = "WIS" }),
    Dice("Pain: a creature in the sphere", 0, 0, nil, { save = "CON" }) } }
L["Synaptic Static"] = { rolls = {
    Dice("a muddled creature's attack, check or concentration save (taken off)", 1, 6, "taken off", { dice = "OTHER" }),
    Dice("its save at the end of each of its turns", 0, 0, nil, { save = "INT" }) } }
