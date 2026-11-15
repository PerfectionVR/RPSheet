-- What the core 7th-level spells do, in a sentence or three of our own words. Shown
-- in place of the bare facts a spell's entry is built from (see Data/SpellSummaries.lua).
local _, ns = ...
local R = ns.Rules

R.SPELL_SUMMARIES = R.SPELL_SUMMARIES or {}
local S = R.SPELL_SUMMARIES

S["Conjure Celestial"] = "A pillar of light, 10 feet in radius, shines within 90 feet for up to 10 minutes and moves 30 feet when you move. Each creature in it, or that enters it or ends its turn there, gets one light from you, once per turn: healing for 4d12 plus your spellcasting modifier, or searing for 6d12 radiant damage, half on a successful Dexterity save. 1d12 more for each slot level above 7th."
S["Delayed Blast Fireball"] = "A glowing bead sits at a point within 150 feet for up to a minute and explodes when the spell ends: a 20-foot sphere of 12d6 fire damage, plus 1d6 for each of your turns it waited, half on a successful Dexterity save. A creature that touches it can throw it away if it passes a Dexterity save. 1d6 more for each slot level above 7th."
S["Divine Word"] = "Bonus action. The creatures you choose within 30 feet make a Charisma save. One that fails with 50 hit points or fewer is deafened, blinded and deafened, or blinded, deafened and stunned, and dies at 20 or fewer. A celestial, elemental, fey or fiend that fails is sent home for 24 hours."
S["Etherealness"] = "You step into the edge of the Ethereal Plane for up to 8 hours: you see the world you left in grey out to 60 feet, move through its objects, and can't touch or be touched by it. Three willing creatures for each slot level above 7th."
S["Finger of Death"] = "A creature within 60 feet takes 7d8 + 30 necrotic damage, half on a successful Constitution save. A humanoid it kills rises as a zombie under your command."
S["Fire Storm"] = "Fire fills ten 10-foot cubes, arranged as you like, within 150 feet: 7d10 fire damage, half on a successful Dexterity save. Loose flammable objects catch fire."
S["Forcecage"] = "An invisible prison of force appears within 100 feet for up to an hour: a barred cage up to 20 feet on a side, or a solid box up to 10 feet that also blocks spells. Those inside can't walk out, and teleporting out needs a successful Charisma save."
S["Mirage Arcane"] = "Takes 10 minutes. Land up to a mile square that you can see looks, sounds, smells and feels like other terrain for 10 days, buildings included. It can be walked on and can even hurt; truesight sees through it."
S["Mordenkainen's Magnificent Mansion"] = "Takes a minute. A door within 300 feet leads to a furnished home outside the world for 24 hours, with food for a hundred guests and unseen servants. Only you and those you name can enter, and the door can't be seen while shut."
S["Mordenkainen's Sword"] = "A sword of force hovers within 90 feet for up to a minute and makes a melee spell attack: 4d12 force damage plus your spellcasting modifier. A bonus action on later turns moves it 30 feet and attacks again."
S["Plane Shift"] = "You and up to eight willing creatures holding hands travel to another plane, arriving in or near a place you name in general terms, or exactly at a teleportation circle whose sigils you know."
S["Power Word Fortify"] = "You share out 120 temporary hit points among up to six creatures you can see within 60 feet."
S["Prismatic Spray"] = "Eight rays flash in a 60-foot cone. Each creature makes a Dexterity save and a d8 picks its ray: 12d6 fire, acid, lightning, poison or cold damage (half on a success), slow petrification, blindness followed by banishment to another plane, or two rays at once."
S["Project Image"] = "An illusory copy of you appears for up to a day in a place you have seen within 500 miles. You see and hear through it, and an action moves it 60 feet and makes it speak. Any damage ends it."
S["Regenerate"] = "Takes a minute. A creature you touch regains 4d8 + 15 hit points, then 1 at the start of each of its turns for an hour. Severed parts grow back after 2 minutes."
S["Resurrection"] = "Takes an hour. A creature you touch that has been dead for up to a century, and not of old age, returns at full hit points with its body whole. It has -4 to d20 rolls, easing by 1 with each long rest. Raising one dead a year or more wears you out until a long rest."
S["Reverse Gravity"] = "For up to a minute everything loose in a cylinder 50 feet in radius and 100 feet high within 100 feet falls upward and hangs at the top. A Dexterity save lets a creature grab something fixed. It all falls back when the spell ends."
S["Sequester"] = "An object or willing creature you touch becomes invisible and can't be found or watched by magic, until dispelled or until a condition you set comes about. A creature sleeps without ageing or needing food or air."
S["Simulacrum"] = "Takes 12 hours. Snow or ice becomes a living copy of a beast or humanoid that stays near you for the casting. It has half the original's hit points, obeys you, and can't learn, rest or heal on its own. A new casting destroys the old copy."
S["Symbol"] = "Takes a minute. You inscribe a hidden glyph with a trigger you set. When triggered it fills a 60-foot sphere for 10 minutes with one effect you chose: death (10d10 necrotic damage, half on a successful Constitution save), discord, fear, pain, sleep or stunning, each resisted with a save."
S["Teleport"] = "You and up to eight willing creatures within 10 feet, or one object, travel at once to a place you know on your plane. The better you know it, the surer the arrival; a poorly known place can put you off target or cause a mishap that hurts."
