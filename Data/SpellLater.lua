-- Spells that do something again after they are cast: the extra dice of a mark on
-- each hit, a weapon of force that attacks on later turns, a cloud that burns whoever
-- walks in. The sheet rolls these from the spell's row without spending a slot
-- (Actions/SpellLater.lua): while a lasting spell runs, a left-click rolls its first
-- roll; a right-click offers every roll and ending it. Nothing counts turns: the
-- player clicks when the rules say the roll happens.
--
-- R.SPELL_LATER[<spell>] = {
--   hours    how long it lasts, in whole hours (0: under an hour), for the rests that
--            end it; hoursAt = { [slot level] = hours } when a higher slot makes it
--            longer. Left out: the spell is over at once and its later rolls are only
--            offered on the right-click (a left-click casts it again).
--   quiet    true: casting rolls none of the spell's own dice (they come on a hit)
--   rolls    what can be rolled later, the first one on a left-click:
--     label     when it is rolled, in a few words
--     same      true: the casting's own roll again (attack or save, dice, slot growth)
--     count, sides, word   dice of their own and what they are ("fire damage")
--     dice      what the dice count as (Rules.DICE_KINDS); damage when left out
--     up        dice added for each slot level above the spell's own
--     attack    "spell" for a spell attack, "weapon" for one with your spellcasting
--               ability and proficiency; save = "DEX" names a saving throw instead
--     addMod    adds your spellcasting modifier; flat: a number added
--     also      { count, sides, word, up }: a second roll of another damage type
--     above     true: only offered when cast with a higher slot; below: only when not
--     half      true: you regain half of the damage the spell dealt last; "TEMPHP":
--               as temporary hit points
--     flatUp    added to `flat` for each slot level above the spell's own
--     selfWard  temporary hit points for you while the spell's protection is on you
--     toYou     the damage is yours: it is taken at once (with your resistances)
--     levels    true: the dice count once per spell level, chosen from a menu
--     sequence  (on the entry) true: the left-click goes through the rolls in order,
--               staying on the last one
--     tick      true: no dice, one more die for the rolls marked ticks = true
--     ends      true: the spell is over after this roll
--     feature, featureSides   with that class feature the die has that many sides
-- }
local _, ns = ...
local R = ns.Rules

R.SPELL_LATER = {}
local L = R.SPELL_LATER

-- The casting's own roll again.
function R.LaterSame(label) return { label = label, same = true } end
-- Dice of their own; `extra` holds the other fields.
function R.LaterDice(label, count, sides, word, extra)
    local roll = { label = label, count = count, sides = sides, word = word }
    for key, value in pairs(extra or {}) do roll[key] = value end
    return roll
end
local Same, Dice = R.LaterSame, R.LaterDice

-- Extra dice on each hit ---------------------------------------------------------------
L["Hex"] = { hours = 1, hoursAt = { [2] = 4, [3] = 8, [5] = 24 }, quiet = true,
    rolls = { Dice("a hit on the cursed creature", 1, 6, "necrotic damage") } }
L["Hunter's Mark"] = { hours = 1, hoursAt = { [3] = 8, [5] = 24 }, quiet = true,
    rolls = { Dice("a hit on the marked creature", 1, 6, "force damage", { feature = "Foe Slayer", featureSides = 10 }) } }
L["Divine Favor"] = { hours = 0, quiet = true, rolls = { Dice("a weapon hit", 1, 4, "radiant damage") } }

-- Attacks and blasts on later turns ------------------------------------------------------
L["Call Lightning"] = { hours = 0, rolls = { Same("another bolt (an action)") } }
L["Cloud of Daggers"] = { hours = 0, rolls = { Same("a creature enters the cube or ends its turn there") } }
L["Moonbeam"] = { hours = 0, rolls = { Same("a creature enters the beam or ends its turn there") } }
L["Flaming Sphere"] = { hours = 0, rolls = { Same("a creature ends its turn beside the sphere, or is rammed") } }
L["Spirit Guardians"] = { hours = 0, rolls = { Same("a creature enters the aura or ends its turn there") } }
L["Heat Metal"] = { hours = 0, rolls = { Same("the metal burns again (a bonus action)") } }
L["Spiritual Weapon"] = { hours = 0, rolls = { Same("another attack (a bonus action)") } }
L["Flame Blade"] = { hours = 0, rolls = { Same("another attack (an action)") } }
L["Vampiric Touch"] = { hours = 0, rolls = { Same("another touch (an action)"),
    { label = "you regain half the damage of the last hit", half = true } } }
L["Witch Bolt"] = { hours = 0, rolls = { Dice("the arc strikes again (a bonus action)", 1, 12, "lightning damage") } }
L["Eye Beam"] = { hours = 0, rolls = { Same("another burst (an action)") } }
L["Grasping Vine"] = { hours = 0, rolls = { Same("another attack (a bonus action)") } }
L["Bigby's Hand"] = { hours = 0, rolls = {
    Same("Clenched Fist (a bonus action)"),
    Dice("Grasping Hand crushes the creature it holds (a bonus action)", 4, 6, "bludgeoning damage", { up = 2, addMod = true }),
    Dice("Forceful Hand pushes (a bonus action)", 0, 0, nil, { save = "STR" }),
    Dice("Grasping Hand grabs (a bonus action)", 0, 0, nil, { save = "DEX" }) } }
L["Mordenkainen's Sword"] = { hours = 0, rolls = { Same("another attack (a bonus action)") } }
L["Conjure Fey"] = { hours = 0, rolls = { Same("another attack (a bonus action)") } }
L["Conjure Celestial"] = { hours = 0, rolls = { Same("Searing Light on a creature"),
    Dice("Healing Light on a creature", 4, 12, "healing", { dice = "HEALING", addMod = true, up = 1 }) } }
L["Sunbeam"] = { hours = 0, rolls = { Same("a new beam (an action)") } }
L["Void Eruption"] = { hours = 0, rolls = { Dice("Void Bolt (a bonus action)", 2, 6, "necrotic damage", { attack = "spell", addMod = true }) } }
L["Phantasmal Force"] = { hours = 0, rolls = { Dice("the phantasm harms the creature on your turn", 2, 8, "psychic damage") } }
L["Phantasmal Killer"] = { hours = 0, rolls = { Same("its save at the end of its turn") } }
L["Combustion"] = { hours = 0, rolls = { Dice("the end of your turn", 3, 8, "fire damage") } }
