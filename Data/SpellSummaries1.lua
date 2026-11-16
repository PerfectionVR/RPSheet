-- What the core 1st-level spells that had only a line of facts do, in a sentence or
-- three of our own words. Shown in place of those facts (see Data/SpellSummaries.lua);
-- the 1st-level spells written by hand in Data/Spells.lua keep their own text.
local _, ns = ...
local R = ns.Rules

R.SPELL_SUMMARIES = R.SPELL_SUMMARIES or {}
local S = R.SPELL_SUMMARIES

S["Alarm"] = "For 8 hours a door, window or area up to a 20-foot cube within 30 feet is warded: you are warned whenever a creature touches or enters it, except those you named. The warning is a handbell heard within 60 feet, or a silent ping in your mind that wakes you if you are within a mile."
S["Animal Friendship"] = "A beast you can see within 30 feet that fails a Wisdom save is charmed by you for 24 hours. Damage from you or your allies ends it. One more beast for each slot level above 1st."
S["Color Spray"] = "Flashing colours burst from you in a 15-foot cone: each creature there that fails a Constitution save is blinded until the end of your next turn."
S["Comprehend Languages"] = "For an hour you understand the literal meaning of any spoken or signed language, and any writing you touch, about a minute a page. Codes and secret messages stay hidden."
S["Create or Destroy Water"] = "You create up to 10 gallons of clean water in an open container within 30 feet, or as rain over a 30-foot cube that puts out open flames. Or you destroy as much water, or the fog in such a cube. 10 more gallons, or a cube 5 feet larger, for each slot level above 1st."
S["Detect Evil and Good"] = "For up to 10 minutes you sense where any aberration, celestial, elemental, fey, fiend or undead within 30 feet is, and whether a Hallow spell is at work there. A foot of stone, dirt or wood, an inch of metal or thin lead blocks it."
S["Detect Poison and Disease"] = "For up to 10 minutes you sense where poisons, poisonous or venomous creatures and magical diseases are within 30 feet, and what kind each is. A foot of stone, dirt or wood, an inch of metal or thin lead blocks it."
S["Disguise Self"] = "For an hour you, your clothes and your gear look different: up to a foot shorter or taller, heavier or lighter, but with the same shape of body. Touch gives the illusion away, and a creature that studies you sees through it with an Intelligence (Investigation) check against your spell save DC."
S["Expeditious Retreat"] = "Bonus action. You Dash at once, and for up to 10 minutes you can Dash again as a bonus action on each of your turns."
S["Grease"] = "Slick grease covers a 10-foot square within 60 feet for a minute and makes it difficult terrain. A creature standing there when it appears, or that enters it or ends its turn there, falls prone unless it passes a Dexterity save."
S["Identify"] = "Touching an object for the whole casting, you learn a magic item's properties, how to use it, whether it needs attunement, its charges, and the spells working on it. Touching a creature instead, you learn which spells are working on it."
S["Illusory Script"] = "Writing you make looks normal to you and those you choose, and like an unreadable magical script to everyone else, for 10 days. Or it can show others a different meaning, hand and language you know. Truesight reads the real message."
S["Purify Food and Drink"] = "Poison and rot leave all nonmagical food and drink in a 5-foot sphere within 10 feet."
S["Silent Image"] = "For up to 10 minutes an image of a thing, creature or sight, no larger than a 15-foot cube, appears within 60 feet. It has no sound or smell; as a Magic action you move it. Touch reveals it, and a creature that studies it sees through it with an Intelligence (Investigation) check against your spell save DC."
S["Tenser's Floating Disk"] = "For an hour a flat disk of force 3 feet across floats 3 feet off the ground within 30 feet and carries up to 500 pounds. It stays within 20 feet of you as you move, can't cross a drop or rise of 10 feet, and the spell ends if you get more than 100 feet away or it is overloaded."
S["Unseen Servant"] = "For an hour an invisible, mindless force (AC 10, 1 hit point, Strength 2) does simple chores for you within 60 feet: fetching, cleaning, serving and the like. A bonus action on your turn tells it to move 15 feet and handle an object. It can't attack."
