-- What the core 8th-level spells do, in a sentence or three of our own words. Shown
-- in place of the bare facts a spell's entry is built from (see Data/SpellSummaries.lua).
local _, ns = ...
local R = ns.Rules

R.SPELL_SUMMARIES = R.SPELL_SUMMARIES or {}
local S = R.SPELL_SUMMARIES

S["Animal Shapes"] = "Any number of willing creatures within 30 feet become beasts of your choice, Large or smaller and of challenge rating 4 or lower, for 24 hours. Each keeps its hit points and mind and gains the first form's hit points as temporary hit points. An action reshapes them; a bonus action lets one change back."
S["Antimagic Field"] = "For up to an hour no magic works within 10 feet of you: no spells cast or reaching in, no magic items, no teleporting. Ongoing spells are suppressed while inside. Dispel Magic can't remove it."
S["Antipathy/Sympathy"] = "Takes an hour. For 10 days a creature or object within 60 feet repels or draws one kind of creature you name. One that comes within 120 feet and fails a Wisdom save is frightened and must flee, or charmed and must approach and stay. It can save again once more than 120 feet away."
S["Befuddlement"] = "A creature within 150 feet takes 10d12 psychic damage, half on a successful Intelligence save. If it fails it can't cast spells or use magic actions, and saves again only every 30 days; strong healing magic also ends it."
S["Clone"] = "Takes an hour. From a creature or a piece of its flesh you grow a spare body in a vessel over 120 days, the same age or younger. If the original later dies, its soul moves into the clone with its memories and abilities, but none of its gear."
S["Control Weather"] = "Takes 10 minutes, outdoors. For up to 8 hours you shift the weather within 5 miles one step at a time: rain, temperature and wind. Each change takes 1d4 x 10 minutes to arrive."
S["Demiplane"] = "A shadowy door appears on a flat surface within 60 feet for an hour and opens onto an empty room 30 feet on each side, outside the world. Things left inside stay there, and a later casting can open a door to the same room."
S["Dominate Monster"] = "A creature within 60 feet that fails a Wisdom save is charmed for up to an hour and obeys your mental commands. It saves with advantage if you are fighting it, and again whenever it takes damage. Up to 8 hours with a 9th-level slot."
S["Earthquake"] = "The ground shakes in a 100-foot radius within 500 feet for up to a minute: difficult terrain. When you cast it and at the end of each of your turns, creatures on the ground must pass a Dexterity save or fall prone and lose concentration. Fissures open and buildings take 50 damage each turn; a collapsing one deals 12d6 bludgeoning damage, half on a successful Dexterity save."
S["Glibness"] = "For an hour you can treat any Charisma check you roll as a 15, and magic that tests for lies reads you as truthful."
S["Holy Aura"] = "For up to a minute the creatures you choose within 30 feet of you have advantage on all saves, and attacks against them have disadvantage. A fiend or undead that hits one in melee must pass a Constitution save or be blinded until the end of its next turn."
S["Incendiary Cloud"] = "A cloud of embers fills a 20-foot sphere within 150 feet for up to a minute, heavily obscured, and drifts 10 feet each turn the way you choose. A creature in it when it appears, or that enters or ends its turn there, takes 10d8 fire damage, half on a successful Dexterity save."
S["Maze"] = "A creature within 60 feet is sent, with no save, into a maze outside the world for up to 10 minutes. It can spend its action on a DC 20 Investigation check to find the way out, which ends the spell."
S["Mind Blank"] = "For 24 hours a willing creature you touch is immune to psychic damage and to being charmed, and no magic can read its thoughts or feelings, find it, watch it from afar or control its mind."
S["Power Word Stun"] = "A creature within 60 feet with 150 hit points or fewer is stunned, with no save at first; it makes a Constitution save at the end of each of its turns to recover. A tougher creature just can't move until the start of your next turn."
S["Sunburst"] = "Sunlight flashes in a 60-foot sphere within 150 feet: 12d6 radiant damage and blinded for a minute; a successful Constitution save halves the damage and avoids the blindness. The blinded save again at the end of each of their turns. It dispels magical darkness."
S["Telepathy"] = "For 24 hours you and a willing creature you know, anywhere on your plane, can share words, images and sounds mind to mind."
S["Tsunami"] = "Takes a minute. A wall of water up to 300 feet long and high rises within a mile for up to 6 rounds: 6d10 bludgeoning damage, half on a successful Strength save. Each turn it rolls 50 feet away from you, carrying off those who fail a Strength save for 5d10, and shrinks by 50 feet and 1d10."
