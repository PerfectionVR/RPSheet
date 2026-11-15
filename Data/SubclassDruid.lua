-- Subclass features of the Druid. See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local AlwaysPrepared, Prepared = ns.SubclassKit.AlwaysPrepared, ns.SubclassKit.Prepared
local F = R.SUBCLASS_FEATURES

-- The damage type a Circle of the Land druid resists, by the land chosen (Nature's Ward).
local LAND_WARD = { Arid = { "fire" }, Polar = { "cold" }, Temperate = { "lightning" }, Tropical = { "poison" } }

-- The spells of each kind of land, always prepared while that land is the one chosen.
local LAND_SPELLS = {
    Arid = { { 3, "Blur, Burning Hands, Fire Bolt" }, { 5, "Fireball" }, { 7, "Blight" }, { 9, "Wall of Stone" } },
    Polar = { { 3, "Fog Cloud, Hold Person, Ray of Frost" }, { 5, "Sleet Storm" }, { 7, "Ice Storm" }, { 9, "Cone of Cold" } },
    Temperate = { { 3, "Misty Step, Shocking Grasp, Sleep" }, { 5, "Lightning Bolt" }, { 7, "Freedom of Movement" }, { 9, "Tree Stride" } },
    Tropical = { { 3, "Acid Splash, Ray of Sickness, Web" }, { 5, "Stinking Cloud" }, { 7, "Polymorph" }, { 9, "Insect Plague" } },
}

F["Circle of the Land"] = {
    Prepared(function(sheet) return LAND_SPELLS[(sheet.featureOptions or {})["Circle of the Land Spells"]] end,
    Kit.Choice(3, "Circle of the Land Spells", "After each long rest you choose a kind of land and have its spells prepared for your level: they are put on your spell list.", {
        Kit.Option("Arid", "Level 3: Blur, Burning Hands, Fire Bolt. Level 5: Fireball. Level 7: Blight. Level 9: Wall of Stone. Nature's Ward: resistance to fire."),
        Kit.Option("Polar", "Level 3: Fog Cloud, Hold Person, Ray of Frost. Level 5: Sleet Storm. Level 7: Ice Storm. Level 9: Cone of Cold. Nature's Ward: resistance to cold."),
        Kit.Option("Temperate", "Level 3: Misty Step, Shocking Grasp, Sleep. Level 5: Lightning Bolt. Level 7: Freedom of Movement. Level 9: Tree Stride. Nature's Ward: resistance to lightning."),
        Kit.Option("Tropical", "Level 3: Acid Splash, Ray of Sickness, Web. Level 5: Stinking Cloud. Level 7: Polymorph. Level 9: Insect Plague. Nature's Ward: resistance to poison."),
    })),
    Ability(3, "Land's Aid", function(_, sheet)
        return ("Magic action, a point within 60 feet. Creatures you choose in a 10-foot sphere take the first roll as necrotic damage, half on a successful Constitution save, DC %d. One creature you choose there is healed by the second roll."):format(Kit.DC(sheet, "WIS"))
    end, function(level)
        local dice = AtLevel(level, { { 3, 2 }, { 10, 3 }, { 14, 4 } })
        return { Spend("Wild Shape"), Dice(dice, 6), Dice(dice, 6, "", "HEALING") }
    end),
    Limited(6, "Natural Recovery", "Once per long rest, cast one of your Circle spells without a slot.", 1),
    Limited(6, "Natural Recovery: slots", "Once per long rest, on a short rest: recover spell slots with a combined level up to half your level, rounded up, none above 5th. The highest spent slots that fit come back; change the bars by hand for another mix.", 1,
        { Kit.Slots("RECOVER") }),
    Passive(10, "Nature's Ward", "You can't be poisoned, and you resist the damage type of your current land (named on your Circle of the Land Spells).", nil, {
        conditionImmune = { "Poisoned" },
        resist = function(_, sheet) return LAND_WARD[(sheet.featureOptions or {})["Circle of the Land Spells"]] end,
    }),
    Ability(14, "Nature's Sanctuary", "Magic action. Spectral trees fill a 15-foot cube within 120 feet for a minute: you and allies have half cover there, and allies gain your Nature's Ward resistance. A bonus action moves it up to 60 feet.",
        { Spend("Wild Shape") }),
}
F["Circle of the Moon"] = {
    AlwaysPrepared("Circle of the Moon", { { 3, "Cure Wounds, Moonbeam, Starry Wisp" }, { 5, "Conjure Animals" }, { 7, "Fount of Moonlight" }, { 9, "Mass Cure Wounds" } }),
    Ability(3, "Circle Forms", function(level)
        return ("Your Wild Shape forms are tougher: challenge rating up to %d, an AC of at least 13 + your Wisdom modifier, and temporary hit points equal to three times your level (this, in place of the usual amount). You can cast your Circle spells in beast form."):format(math.max(1, math.floor(level / 3)))
    end, function(level) return { Dice(0, 4, "", "TEMPHP", 3 * level) } end),
    Ability(3, "Cat Form", function(level)
        return ("Wild Shape. You become a great cat for %d hours: Armor Class 13 + Wisdom modifier, speed 40 feet, Strength and Dexterity equal to your Wisdom, darkvision, proficiency in Stealth. You gain temporary hit points equal to three times your level. The sheet uses these numbers while the form is on."):format(math.floor(level / 2))
    end, function(level)
        return { Spend("Wild Shape"), Dice(0, 4, "", "TEMPHP", 3 * level), Kit.SwitchOff("Bear Form active"), SwitchOn("Cat Form active") }
    end),
    Passive(3, "Cat Form active", "Switched on while you are in Cat Form. Each turn you can Pounce once and Prowl: move up to half your speed without provoking opportunity attacks, then hide.",
        function(level) return level >= 6 and { Bonus("SAVE:CON", 0, "WIS") } or {} end, true),
    Ability(3, "Pounce", "Cat Form. A melee attack with your spell attack modifier. The damage grows at levels 5, 11 and 17.",
        function(level) return { Roll("SPELL", "WIS"), Dice(AtLevel(level, { { 1, 1 }, { 5, 2 }, { 11, 3 }, { 17, 4 } }), 10, "WIS") } end),
    Ability(3, "Pounce: with advantage", "Cat Form. If you had advantage on the Pounce: this much more damage, and a Large or smaller target is knocked prone.",
        function(level) return { Dice(AtLevel(level, { { 1, 1 }, { 6, 2 }, { 9, 3 }, { 12, 4 }, { 15, 5 }, { 18, 6 } }), 6) } end),
    Ability(3, "Primal Wrath", function(_, sheet)
        return ("Cat Form. Spend a spell slot: each creature you choose within 5 feet makes a Dexterity save, DC %d, or takes the damage. The dice count once per level of the slot; set a higher one at \"Cast at\"."):format(Kit.DC(sheet, "WIS"))
    end, { Spend("1st-level slot"), Kit.PerSlot(Dice(2, 6, "WIS")) }),
    Ability(3, "Bear Form", function(level)
        return ("Wild Shape. You become a great bear for %d hours: Armor Class 15 + Wisdom modifier, speed 30 feet, Strength and Dexterity equal to your Wisdom, darkvision. You gain temporary hit points equal to three times your level. The sheet uses these numbers while the form is on."):format(math.floor(level / 2))
    end, function(level)
        return { Spend("Wild Shape"), Dice(0, 4, "", "TEMPHP", 3 * level), Kit.SwitchOff("Cat Form active"), SwitchOn("Bear Form active") }
    end),
    Passive(3, "Bear Form active", "Switched on while you are in Bear Form. You Mangle twice with the Attack action. Reaction, Growl: when a creature you can see attacks someone else within 5 feet of you, that attack and others against that target have disadvantage until your next turn, while you stay within 5 feet.",
        function(level) return level >= 6 and { Bonus("SAVE:CON", 0, "WIS") } or {} end, true),
    Ability(3, "Mangle", "Bear Form. A melee attack with your spell attack modifier; you make two with the Attack action, so click once for each. The damage grows at levels 5, 11 and 17.",
        function(level) return { Roll("SPELL", "WIS"), Dice(AtLevel(level, { { 1, 1 }, { 5, 2 }, { 11, 3 }, { 17, 4 } }), 8, "WIS") } end),
    Ability(3, "Frenzied Regeneration", "Bear Form, bonus action. Spend a spell slot to gain temporary hit points equal to five times its level; set a higher one at \"Cast at\".",
        { Spend("1st-level slot"), Kit.PerSlot(Dice(0, 4, "", "TEMPHP", 5)) }),
    Ability(3, "Leave form", "Bonus action. You return to your own shape. The form also ends when you are incapacitated.",
        { Kit.SwitchOff("Cat Form active"), Kit.SwitchOff("Bear Form active") }),
    Passive(6, "Improved Circle Forms", "In Wild Shape your attacks can deal radiant damage, and you add your Wisdom modifier to Constitution saving throws."),
    Limited(10, "Moonlight Step", "Bonus action: teleport up to 30 feet and gain advantage on your next attack this turn (the sheet sets it). Uses equal to your Wisdom modifier per long rest; a slot of 2nd level or higher restores one.",
        { stat = "WIS" }, { Kit.NextRoll("ADV") }),
    Ability(14, "Lunar Form", "Once per turn: extra radiant damage on a target you hit with a Wild Shape form's attack. Moonlight Step can also bring a willing creature within 10 feet along.",
        { Dice(2, 10) }),
}
F["Circle of the Stars"] = {
    -- (A druid who picked Guidance as a cantrip gets that pick back: Sheet/SpellPicks.lua)
    Prepared({ { 3, "Guidance, Guiding Bolt" } }, Limited(3, "Star Map", "A star chart that serves as your spellcasting focus. With it you have Guidance and Guiding Bolt prepared; neither counts against your cantrips or prepared spells. Clicking casts Guiding Bolt without a slot: uses equal to your Wisdom modifier per long rest.",
        { stat = "WIS" }, { Roll("SPELL", "WIS"), Dice(4, 6) })),
    Ability(3, "Starry Form", "Bonus action. For 10 minutes you become starry in place of a beast form, and choose a constellation: Archer, Chalice or Dragon. From level 10 you can change it at the start of each turn.",
        function(level) return level >= 14 and { Spend("Wild Shape"), SwitchOn("Full of Stars") } or { Spend("Wild Shape") } end),
    Ability(3, "Archer", "Starry Form, Archer constellation. When you take the form, and as a bonus action after: a luminous arrow at a creature within 60 feet.",
        function(level) return { Roll("SPELL", "WIS"), Dice(level >= 10 and 2 or 1, 8, "WIS") } end),
    Ability(3, "Chalice", "Starry Form, Chalice constellation. When you heal with a slotted spell, you or a creature within 30 feet also regains this much.",
        function(level) return { Dice(level >= 10 and 2 or 1, 8, "WIS", "HEALING") } end),
    Passive(3, "Dragon", function(level)
        return "Starry Form, Dragon constellation. Switch on while it glimmers: on Intelligence and Wisdom checks and concentration saves, a d20 roll of 9 or lower counts as 10." .. (level >= 10 and " You also have a flying speed of 20 feet and can hover." or "")
    end, nil, true),
    Limited(6, "Cosmic Omen", "After a long rest roll a die. Even (Weal): as a reaction, add the roll to a d20 test of a creature within 30 feet. Odd (Woe): subtract it. Uses equal to your Wisdom modifier per long rest.",
        { stat = "WIS" }, { Dice(1, 6, "", "OTHER") }),
    Passive(10, "Twinkling Constellations", "Archer and Chalice use 2d8, the Dragon lets you fly and hover, and you can change constellation at the start of each turn."),
    Passive(14, "Full of Stars", "Switch on while you are in Starry Form, which switches it on for you: you resist bludgeoning, piercing and slashing damage.",
        nil, { startsOff = true, resist = R.WEAPON_DAMAGE }),
}
