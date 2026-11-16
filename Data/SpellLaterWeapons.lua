-- Later rolls of spells that strengthen hits or give temporary hit points (how an
-- entry is written: Data/SpellLater.lua). Cast on yourself, the hits of your weapon
-- rows get the dice by themselves (Data/SpellWardWeapons.lua); these rolls are for
-- your allies' hits, your spell attacks, and the casting cast on someone else.
local _, ns = ...
local R = ns.Rules
local L, Same, Dice = R.SPELL_LATER, R.LaterSame, R.LaterDice

-- Dice on hits -------------------------------------------------------------------------
L["Crusader's Mantle"] = { hours = 0, quiet = true, rolls = { Same("you or an ally hits with a weapon or an unarmed strike") } }
L["Elemental Weapon"] = { hours = 1, quiet = true, rolls = { Same("a hit with the weapon") } }
L["Fount of Moonlight"] = { hours = 0, quiet = true, rolls = { Dice("a melee hit", 2, 6, "radiant damage"),
    Dice("your reaction: the creature that hurt you", 0, 0, nil, { save = "CON" }) } }
L["Conjure Minor Elementals"] = { hours = 0, quiet = true, rolls = { Same("an attack hits a creature within 15 feet of you") } }
L["Rain of Fire"] = { hours = 0, rolls = { Same("a creature enters the rain or ends its turn there"),
    Dice("your spell attack hits a creature in the rain", 1, 6, "necrotic damage") } }
L["Throw Glaive"] = { rolls = { Same("the glaive bounces to another target (once for each level of the slot)") } }

-- Temporary hit points -----------------------------------------------------------------
-- Heroism: yours while its protection is on you (cast on yourself), else the target's.
L["Heroism"] = { hours = 0, rolls = { Dice("the start of the target's turn", 0, 0, "temporary hit points", { addMod = true, selfWard = true }) } }
L["Armor of Agathys"] = { hours = 1, rolls = { Dice("a creature hits you in melee", 0, 0, "cold damage", { flat = 5, flatUp = 5 }) } }
L["Consume Soul"] = { rolls = { { label = "you gain temporary hit points: half the damage it took", half = "TEMPHP" } } }
-- The 120 are shared out as you like; the menu offers your share of an even split.
L["Power Word Fortify"] = { rolls = {} }
for _, share in ipairs({ 120, 60, 40, 30, 24, 20 }) do
    table.insert(L["Power Word Fortify"].rolls, Dice(("your share: %d"):format(share), 0, 0, "temporary hit points", { dice = "TEMPHP", flat = share }))
end
