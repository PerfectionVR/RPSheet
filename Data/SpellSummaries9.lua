-- What the core 9th-level spells do, in a sentence or three of our own words. Shown
-- in place of the bare facts a spell's entry is built from (see Data/SpellSummaries.lua).
local _, ns = ...
local R = ns.Rules

R.SPELL_SUMMARIES = R.SPELL_SUMMARIES or {}
local S = R.SPELL_SUMMARIES

S["Astral Projection"] = "Takes an hour. You and up to eight willing creatures within 10 feet leave your bodies asleep and travel the Astral Plane in spirit forms with all your abilities, each tied to its body by a silver cord. A form or body dropped to 0 hit points ends the trip; a cut cord kills."
S["Foresight"] = "Takes a minute. For 8 hours a willing creature you touch has advantage on every d20 roll, and attacks against it have disadvantage. Casting it again ends the first."
S["Gate"] = "A portal 5 to 20 feet across opens within 60 feet onto an exact place on another plane for up to a minute; anything passing through its front arrives there. Speaking the true name of a creature on another plane opens the gate beside it and pulls it through."
S["Imprisonment"] = "Takes a minute. A creature within 30 feet that fails a Wisdom save is locked away until dispelled, in a way you choose: buried, chained, shut in a pocket space, shrunk into a gem or put to sleep. It doesn't age and can't be found by magic. You set one condition that frees it. One that passes is immune for 24 hours."
S["Mass Heal"] = "You restore up to 700 hit points, shared as you like among creatures you can see within 60 feet. Those healed are also no longer blinded, deafened or poisoned."
S["Meteor Swarm"] = "Four fiery orbs fall on points you can see within a mile, each a 40-foot sphere: 20d6 fire and 20d6 bludgeoning damage, half on a successful Dexterity save. A creature caught in several is hit only once."
S["Power Word Heal"] = "A creature within 60 feet regains all its hit points, is no longer charmed, frightened, paralyzed, poisoned or stunned, and can use its reaction to stand up."
S["Power Word Kill"] = "A creature within 60 feet with 100 hit points or fewer dies, with no save. A tougher one takes 12d12 psychic damage."
S["Prismatic Wall"] = "A wall of seven coloured layers, up to 90 feet long or a globe 30 feet across, stands within 60 feet for 10 minutes. Others who come within 20 feet must pass a Constitution save or be blinded for a minute. Passing through means a Dexterity save against each layer: five deal 12d6 damage (half on a success), one petrifies, one blinds and banishes."
S["Shapechange"] = "For up to an hour you become any creature you have seen, other than a construct or undead, of a challenge rating up to your level, keeping your mind and gaining the first form's hit points as temporary hit points. An action changes to another form."
S["Storm of Vengeance"] = "A storm 300 feet in radius gathers within a mile for up to a minute. Creatures under it must pass a Constitution save or take 2d6 thunder damage and be deafened. Each later turn brings something new: acid rain for 4d6, six lightning bolts for 10d6 (half on a successful Dexterity save), hail for 2d6, then freezing gales."
S["Time Stop"] = "Time stops for everyone but you while you take 1d4 + 1 turns in a row. It ends early if anything you do affects another creature or what it carries, or if you move more than 1,000 feet away."
S["True Polymorph"] = "A creature or object within 30 feet becomes another creature or object for up to an hour: creature to creature, creature to object or object to creature. An unwilling creature resists with a Wisdom save. Hold your concentration for the full hour and it lasts until dispelled."
S["True Resurrection"] = "Takes an hour. A creature dead for up to 200 years, and not of old age, returns at full hit points, cured and whole, even without a body if you speak its name."
S["Weird"] = "The creatures you choose in a 30-foot sphere within 120 feet take 10d10 psychic damage and are frightened for up to a minute; a successful Wisdom save halves the damage and avoids the fear. The frightened save at the end of each turn: 5d10 more on a failure, free on a success."
S["Wish"] = "You cast any spell of 8th level or lower without its requirements or costly components. Or you ask for more: a valuable object, full healing for twenty, resistance for ten, immunity to one spell, one feat swapped for another, or a reroll of a recent event. Anything beyond copying a spell weakens you for days and may cost you the spell for good."
