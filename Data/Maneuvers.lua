-- Battle Master maneuvers, the core ones and the setting's own, with short summaries
-- in our own words. A Battle Master knows a few of these (see R.MANEUVERS_KNOWN) and
-- each use spends a Superiority Die.
--   dice   what the die counts as when rolled: "DAMAGE" (added to a hit's damage) or
--          "OTHER" (added to a roll, to AC, or reducing damage)
--   save   saving throw the target makes, against 8 + Strength or Dexterity modifier
--          + proficiency bonus
--   add    also added to the die: "BEST" (the higher of Strength and Dexterity) or
--          "HALFLEVEL" (half the character's level)
local _, ns = ...
local R = ns.Rules

-- Maneuvers known at a level, and the size of the Superiority Die.
R.MANEUVERS_KNOWN = { { 3, 3 }, { 7, 5 }, { 10, 7 }, { 15, 9 } }
R.SUPERIORITY_DIE = { { 3, 8 }, { 10, 10 }, { 18, 12 } }

R.MANEUVERS = {
    ["Ambush"] = { dice = "OTHER", desc = "Add the die to a Stealth check or an initiative roll." },
    ["Bait and Switch"] = { dice = "OTHER", desc = "Swap places with a willing creature within 5 feet, without provoking opportunity attacks. Until your next turn, you or that creature adds the die to its AC." },
    ["Battle Shout"] = { dice = "OTHER", desc = "Bonus action. Allies within 30 feet who hear you add the die to the damage of their next melee hit before your next turn." },
    ["Commander's Strike"] = { dice = "DAMAGE", desc = "In place of one of your attacks, an ally uses its reaction to attack, adding the die to its damage." },
    ["Commanding Presence"] = { dice = "OTHER", desc = "Add the die to an Intimidation, Performance or Persuasion check." },
    ["Demoralizing Shout"] = { dice = "OTHER", desc = "Bonus action. Enemies within 30 feet who hear you subtract the die from the damage of their next melee hit on anyone but you, until the end of your next turn." },
    ["Disarming Attack"] = { dice = "DAMAGE", save = "STR", desc = "When you hit: add the die to the damage, and the target drops something it holds if it fails the save." },
    ["Distracting Strike"] = { dice = "DAMAGE", desc = "When you hit: add the die to the damage, and the next attack on the target by someone else, before your next turn, has advantage." },
    ["Evasive Footwork"] = { dice = "OTHER", desc = "Bonus action. Disengage, and add the die to your AC until your next turn." },
    ["Feinting Attack"] = { dice = "DAMAGE", desc = "Bonus action. Advantage on your next attack this turn against a creature within 5 feet; add the die to its damage if it hits." },
    ["Goading Attack"] = { dice = "DAMAGE", save = "WIS", desc = "When you hit: add the die to the damage. If the target fails the save it has disadvantage attacking anyone but you until the end of your next turn." },
    ["Heroic Leap"] = { dice = "DAMAGE", save = "STR", desc = "Bonus action. Jump up to your Strength score in feet. Creatures within 5 feet of where you land take the die as bludgeoning damage, half on a successful save." },
    ["Lunging Attack"] = { dice = "DAMAGE", desc = "Bonus action. Dash. If you then move 5 feet in a straight line before a melee hit this turn, add the die to its damage." },
    ["Maneuvering Attack"] = { dice = "DAMAGE", desc = "When you hit: add the die to the damage, and an ally can use its reaction to move half its speed without provoking opportunity attacks." },
    ["Menacing Attack"] = { dice = "DAMAGE", save = "WIS", desc = "When you hit: add the die to the damage. If the target fails the save it is frightened until the end of your next turn." },
    ["Mortal Strike"] = { dice = "DAMAGE", desc = "When you hit: add the die to the damage, and the target can't regain hit points until the end of your next turn." },
    ["Parry"] = { dice = "OTHER", add = "BEST", desc = "Reaction when a melee attack damages you: reduce the damage by the roll." },
    ["Precision Attack"] = { dice = "OTHER", desc = "When you miss: add the die to the attack roll, which may turn it into a hit." },
    ["Pushing Attack"] = { dice = "DAMAGE", save = "STR", desc = "When you hit: add the die to the damage. A Large or smaller target that fails the save is pushed up to 15 feet away." },
    ["Rally"] = { dice = "OTHER", add = "HALFLEVEL", desc = "Bonus action. An ally within 30 feet gains temporary hit points equal to the roll." },
    ["Riposte"] = { dice = "DAMAGE", desc = "Reaction when a melee attack misses you: make a melee attack against the attacker, adding the die to its damage on a hit." },
    ["Sweeping Attack"] = { dice = "DAMAGE", desc = "When you hit in melee: a second creature within 5 feet of the first takes the die as damage, if the attack roll would hit it too." },
    ["Tactical Assessment"] = { dice = "OTHER", desc = "Add the die to a History, Investigation or Insight check." },
    ["Trip Attack"] = { dice = "DAMAGE", save = "STR", desc = "When you hit: add the die to the damage. A Large or smaller target that fails the save falls prone." },
    ["Warding Maneuver"] = { dice = "OTHER", desc = "Reaction when you or a creature within 5 feet is hit, while you hold a melee weapon or a shield: add the die to the target's AC against that attack. If it still hits, the target resists its damage." },
}

R.MANEUVER_ORDER = {}
for name in pairs(R.MANEUVERS) do R.MANEUVER_ORDER[#R.MANEUVER_ORDER + 1] = name end
table.sort(R.MANEUVER_ORDER)
