-- Spells that change your weapon attacks while they last (form of the entries:
-- Data/SpellWards.lua, Data/SpellWardBoons.lua). Their flags are read by
-- Sheet/SpellWeapons.lua:
--     shillelagh = true    a club or quarterstaff uses your spellcasting ability and
--                          a larger die
--     weaponMagic = 1      +1 to attack and damage rolls of a weapon that isn't magic
--     weaponAttack = 1     +1 to its attack rolls only
-- flagsAt and strikeAt are functions of the slot level, for numbers that grow.
-- What hits by someone else deal, or spell attacks, is rolled from the spell's row
-- (Data/SpellLaterWeapons.lua).
local _, ns = ...
local R = ns.Rules

local W = R.SPELL_WARDS

W["Shillelagh"] = { hours = 0, own = true, { text = "your club or quarterstaff uses your spellcasting ability for melee attack and damage rolls, its die becomes a d8 (d10 at level 5, d12 at 11, 2d6 at 17), and it can deal force damage",
    flags = { shillelagh = true } } }
-- +1, +2 from a 3rd-level slot, +3 from a 6th-level one.
local function MagicBonus(slot) return slot >= 6 and 3 or slot >= 3 and 2 or 1 end
W["Magic Weapon"] = { hours = 1, { text = "+1 to attack and damage rolls with a weapon that isn't magic (+2 with a slot of 3rd to 5th level, +3 with 6th or higher)",
    flagsAt = function(slot) return { weaponMagic = MagicBonus(slot) } end } }
-- +1 and 1d4, +2 and 2d4 from a 5th-level slot, +3 and 3d4 from a 7th-level one.
local function ElementBonus(slot) return slot >= 7 and 3 or slot >= 5 and 2 or 1 end
W["Elemental Weapon"] = { hours = 1, conc = true }
for _, kind in ipairs({ "acid", "cold", "fire", "lightning", "thunder" }) do
    table.insert(W["Elemental Weapon"], { label = kind,
        text = ("+1 to attack rolls with a weapon that isn't magic, and 1d4 %s damage on its hits (+2 and 2d4 with a slot of 5th or 6th level, +3 and 3d4 with 7th or higher)"):format(kind),
        flagsAt = function(slot) return { weaponAttack = ElementBonus(slot) } end,
        strikeAt = function(slot) return { count = ElementBonus(slot), sides = 4, damage = kind, all = true } end })
end
W["Crusader's Mantle"] = { hours = 0, conc = true, own = true, { text = "1d4 radiant damage more on each hit with a weapon or an unarmed strike, for you and your allies within 30 feet",
    strike = { count = 1, sides = 4, damage = "radiant", all = true } } }
W["Fount of Moonlight"][1].strike = { count = 2, sides = 6, damage = "radiant" }
W["Fount of Moonlight"][1].text = "resistance to radiant damage, and 2d6 radiant damage more on your melee hits"
-- Only against creatures within 15 feet of you: the sheet adds them to melee hits.
W["Conjure Minor Elementals"] = { hours = 0, conc = true, own = true, { text = "2d8 acid, cold, fire or lightning damage more when you hit a creature within 15 feet of you (1d8 more for each slot level above 4th); added to your melee weapon hits",
    strikeAt = function(slot) return { count = 2 + (slot - 4), sides = 8, damage = "elemental" } end } }
W["Guided Prayer"] = { hours = 0, own = true, { text = "advantage on your next attack roll before the end of your next turn",
    advantage = { "attack", "spell attack" }, oneRoll = true } }
