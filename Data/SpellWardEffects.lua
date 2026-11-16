-- Spells that change the one they are cast on while they last: Armor Class, hit
-- points, speeds (form of the entries: Data/SpellWards.lua). Cast on yourself, each
-- switches on a passive with these numbers (Sheet/Wards.lua). An option can also have:
--     effectsAt  function(slot level) returning the effects, for numbers that grow
--     flags      mageArmor = 13: that base Armor Class without armor; acFloor = 17:
--                Armor Class at least that (Sheet/SpellAC.lua)
--     heal       function(slot level): hit points gained at once with a higher maximum
--     tempHP     function(slot level, sheet): temporary hit points gained at once
--     rollHP     { 2, 10 }: a higher maximum by a roll, and as many hit points
--                (those three: Sheet/WardStart.lua)
local _, ns = ...
local R = ns.Rules
local Bonus = ns.FeatureKit.Bonus

local W = R.SPELL_WARDS

-- An effect that sets a speed to at least `feet`, or multiplies it (Data/EffectModes.lua).
local function Speed(target, feet) return { target = target, flat = feet, stat = "", times = 1, mode = "MIN" } end
local function Walking(target) return { target = target, flat = 0, stat = "", times = 1, mode = "WALK" } end
local function Times(target, by) return { target = target, flat = by, stat = "", times = 1, mode = "TIMES" } end

-- Armor Class ---------------------------------------------------------------------------
W["Mage Armor"] = { hours = 8, { text = "a base Armor Class of 13 plus your Dexterity modifier while you wear no armor", flags = { mageArmor = 13 } } }
W["Shield"] = { hours = 0, own = true, { text = "+5 to Armor Class until the start of your next turn, and no damage from Magic Missile", effects = { Bonus("AC", 5) } } }
W["Shield of Faith"] = { hours = 0, conc = true, { text = "+2 to Armor Class", effects = { Bonus("AC", 2) } } }
W["Barkskin"] = { hours = 1, { text = "an Armor Class of 17 if yours is lower", flags = { acFloor = 17 } } }
W["Haste"] = { hours = 0, conc = true, { text = "double speed, +2 to Armor Class, advantage on Dexterity saves and one more limited action each turn",
    effects = { Bonus("AC", 2), Times("SPEED", 2) }, advantage = { "DEX save" } } }
W["Blistering Scales"] = { hours = 0, conc = true, { text = "+1 to Armor Class while a scale is left", effects = { Bonus("AC", 1) } } }
W["Demon Spikes"] = { hours = 0, own = true, { text = "+2 to Armor Class, and 10 piercing damage to a creature within 5 feet that hits you in melee",
    effects = { Bonus("AC", 2) } } }

-- Hit points ------------------------------------------------------------------------------
-- Aid: 5 at 2nd level, 5 more for each slot level above.
local function Aid(slot) return 5 * (slot - 1) end
W["Aid"] = { hours = 8, { text = "more hit points, maximum and current: 5, and 5 more for each slot level above 2nd",
    effectsAt = function(slot) return { Bonus("HP", Aid(slot)) } end, heal = Aid } }
W["Heroes' Feast"][1].rollHP = { 2, 10 }
W["Heroes' Feast"][1].text = "resistance to poison damage, can't be Frightened or Poisoned, and 2d10 more hit points, maximum and current"
W["Vampiric Blood"] = { hours = 0, conc = true, own = true, { text = "10 more maximum hit points", effects = { Bonus("HP", 10) } } }
W["Armor of Agathys"] = { hours = 1, own = true, { text = "5 temporary hit points for each level of the slot; while they last, a creature that hits you in melee takes as much cold damage",
    tempHP = function(slot) return 5 * slot end } }
W["Heroism"] = { hours = 0, conc = true, { conditionImmune = { "Frightened" },
    text = "can't be Frightened, and temporary hit points equal to the caster's spellcasting modifier at the start of each of your turns" } }

-- Speeds ----------------------------------------------------------------------------------
W["Longstrider"] = { hours = 1, { text = "+10 feet of speed", effects = { Bonus("SPEED", 10) } } }
W["Fly"] = { hours = 0, conc = true, { text = "a flying speed of 60 feet, and you can hover", effects = { Speed("FLY", 60) } } }
W["Spider Climb"] = { hours = 1, conc = true, { text = "a climbing speed equal to your speed, and your hands are free while you climb", effects = { Walking("CLIMB") } } }
W["Fel Rush"] = { hours = 0, own = true, { text = "+30 feet of speed until the end of your turn, and moving doesn't provoke opportunity attacks", effects = { Bonus("SPEED", 30) } } }
W["Breath of Eons"] = { hours = 0, conc = true, own = true, { text = "a flying speed of 60 feet; you can hover, and moving doesn't provoke opportunity attacks", effects = { Speed("FLY", 60) } } }
W["Dream Flight"] = { hours = 0, conc = true, own = true, { text = "a flying speed of 60 feet; you can hover, and moving doesn't provoke opportunity attacks", effects = { Speed("FLY", 60) } } }
-- Alter Self: the aquatic shape is the one with a speed.
W["Alter Self"] = { hours = 1, conc = true, own = true,
    { label = "aquatic", text = "you breathe water and have a swimming speed equal to your speed", effects = { Walking("SWIM") } },
    { label = "new look", text = "a new appearance" },
    { label = "natural weapons", text = "natural weapons of 1d6 with your spellcasting ability (right-click the spell to roll one)" } }
-- Speeds of protective spells listed earlier.
W["Gaseous Form"][1].effects = { Speed("FLY", 10) }
W["Gaseous Form"][1].text = "resistance to bludgeoning, piercing and slashing damage, can't be Prone, and a flying speed of 10 feet as your only way to move"
W["Wind Walk"][1].effects = { Speed("FLY", 300) }
W["Wind Walk"][1].text = "resistance to bludgeoning, piercing and slashing damage, can't be Prone, and a flying speed of 300 feet"
W["Apotheosis"][1].effects = { Speed("FLY", 90) }
W["Apotheosis"][1].text = "resistance to bludgeoning, piercing, radiant and slashing damage, and a flying speed of 90 feet"

-- A shape of its own -----------------------------------------------------------------------
-- Tree of Life: the speed of 10 feet that can't be reduced is left in words.
W["Tree of Life"] = { hours = 0, own = true, { conditionImmune = { "Paralyzed", "Restrained" },
    text = "+2 to Armor Class, 10 temporary hit points, can't be Paralyzed or Restrained, +1 to your Druid spells' save DC and advantage on their attack rolls; you are Large and your speed is 10 feet, which nothing reduces",
    effects = { Bonus("AC", 2), Bonus("SPELLDC", 1) }, advantage = { "spell attack" }, tempHP = function() return 10 end } }
