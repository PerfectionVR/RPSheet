-- Subclass features, added to a sheet by subclass and level like the class features
-- in Features.lua. Keyed by the subclass name as listed in Classes.lua.
--
-- Summaries are short and in our own words; features that roll or change numbers are
-- wired up. Not covered: the Death Knight's Oath of the Ebon Blade and the Demon Hunter
-- subclass, which rewrite parts of their base class.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability = Kit.AtLevel, Kit.Passive, Kit.Ability
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus

-- Resources a subclass brings, in the same form as class `pools` (see Classes.lua).
R.SUBCLASS_POOLS = {
    ["Battle Master"] = {
        { name = "Superiority Dice", short = "ALL", steps = { { 3, 4 }, { 7, 5 }, { 15, 6 } } },
    },
    ["Soulknife"] = {
        { name = "Psionic Energy Dice", short = 1, steps = { { 3, 4 }, { 5, 6 }, { 9, 8 }, { 13, 10 }, { 17, 12 } } },
    },
}

local function AlwaysPrepared(what)
    return Passive(3, what .. " Spells", "Your subclass gives you extra spells at certain levels. They are always prepared and don't count against the number you can prepare.")
end

R.SUBCLASS_FEATURES = {
    ---------------------------------------------------------------------------
    -- Shaman (Barbarian)
    ---------------------------------------------------------------------------
    ["Path of the Elements"] = {
        Passive(3, "Raging Elements", "When you start raging, and as a bonus action while raging, you unleash one elemental option of your choice. Saves against them use 8 + Constitution modifier + proficiency bonus."),
        Passive(6, "Echo of the Elements", "You know Elementalism, and can spend a Rage use to cast Daylight, Water Walk or Wind Wall, using Wisdom."),
        Passive(10, "Primordial Bond", "While raging you have resistance to cold, fire and lightning damage."),
        Passive(14, "Elemental Overload", "Each of your Raging Elements options gains an extra effect."),
    },
    ["Path of the Spiritual Guardian"] = {
        Passive(3, "Spiritual Protectors", "While raging, a creature you hit becomes the target of your guardian spirits, which hinder it in a way you choose, such as giving it disadvantage on attacks against others."),
        Passive(6, "Spirit Shield", "While raging, as a reaction when another creature within 30 feet takes damage, reduce that damage by a number of d6s equal to your rage damage bonus."),
        Passive(10, "Consult the Spirits", "You can cast Augury or Clairvoyance without a slot or components, using Wisdom."),
        Passive(14, "Spirits' Fury", "Once per turn, when a melee weapon attack roll shows 18 to 20, you can make one extra attack with that weapon."),
    },
    ["Path of the World Tree"] = {
        Passive(3, "Vitality of the Tree", "When you start raging you gain temporary HP equal to your level. At the start of each turn while raging you can give temporary HP to another creature within 10 feet."),
        Passive(6, "Branches of the Tree", "While raging, as a reaction when a creature within 30 feet starts its turn, it makes a Strength save or is teleported next to you and can't move this turn."),
        Passive(10, "Battering Roots", "Your reach is 10 feet greater with heavy or versatile melee weapons, and hits with them can also push or topple."),
        Passive(14, "Travel Along the Tree", "When you start raging, and as a bonus action while raging, you can teleport up to 60 feet. Once per rage this can be 150 feet and carry up to six willing creatures."),
    },

    ---------------------------------------------------------------------------
    -- Warrior (Fighter)
    ---------------------------------------------------------------------------
    ["Battle Master"] = {
        Ability(3, "Maneuver", "Spend a Superiority Die on a maneuver you know and roll it. Most maneuvers add the roll to an attack's damage. Saves against them use 8 + Strength or Dexterity modifier + proficiency bonus.",
            function(level) return { Spend("Superiority Dice"), Dice(1, AtLevel(level, { { 3, 8 }, { 10, 10 }, { 18, 12 } })) } end),
        Passive(3, "Combat Superiority", "You know three maneuvers, and learn more at levels 7, 10 and 15. Your Superiority Dice come back on a short rest."),
        Passive(3, "Student of War", "Proficiency with one kind of artisan's tools and in one more Fighter skill."),
        Passive(7, "Know Your Enemy", "Bonus action, once per long rest or by spending a Superiority Die: learn a creature's immunities, resistances and vulnerabilities."),
        Passive(15, "Relentless", "Once per turn you can use a maneuver without spending a die, rolling a d8 in its place."),
    },
    ["Champion"] = {
        Passive(3, "Improved Critical", "Your weapon and unarmed attacks score a critical hit on a 19 or 20. From level 15, on an 18 to 20."),
        Passive(3, "Remarkable Athlete", "Advantage on initiative rolls and Athletics checks. After a critical hit you can move half your speed without provoking opportunity attacks."),
        Passive(7, "Additional Fighting Style", "You gain another Fighting Style feat."),
        Passive(10, "Heroic Warrior", "In combat, you can give yourself Heroic Inspiration at the start of any turn you begin without it."),
        Passive(18, "Survivor", "Advantage on death saves, with 18 to 20 counting as a 20. While Bloodied you regain 5 + Constitution modifier HP at the start of each turn."),
    },

    ---------------------------------------------------------------------------
    -- Paladin
    ---------------------------------------------------------------------------
    ["Oath of Devotion"] = {
        AlwaysPrepared("Oath of Devotion"),
        Ability(3, "Sacred Weapon", "When you take the Attack action. For 10 minutes one melee weapon you hold adds your Charisma modifier to its attack rolls, sheds light, and can deal radiant damage.",
            { Spend("Channel Divinity"), SwitchOn("Sacred Weapon active") }),
        Passive(3, "Sacred Weapon active", "Switch on while Sacred Weapon lasts. Adds your Charisma modifier to attack rolls.", { Bonus("ATTACK", 0, "CHA") }, true),
        Passive(7, "Aura of Devotion", "You and allies in your Aura of Protection can't be charmed."),
        Passive(15, "Smite of Protection", "When you cast Divine Smite, you and allies in your aura have cover until your next turn."),
        Passive(20, "Holy Nimbus", "Bonus action, once per long rest: for 10 minutes your aura shines with sunlight, harms enemies in it, and you have advantage on saves forced by fiends and undead."),
    },
    ["Oath of the Holy"] = {
        AlwaysPrepared("Oath of the Holy"),
        Ability(3, "Beacon of Light", "Magic action. For 1 minute, an ally within 60 feet also regains half the hit points whenever you heal someone else with a spell or Lay on Hands.",
            { Spend("Channel Divinity") }),
        Passive(7, "Lightbringer's Aura", "When you heal a Bloodied creature in your aura with a spell or Lay on Hands, it regains 1d6 more."),
        Passive(15, "Infusion of Light", "When you cast a spell that deals radiant damage, your Lay on Hands pool regains points equal to the damage rolled, up to a limit."),
        Passive(20, "Holy Deliverance", "Bonus action, once per long rest: for 10 minutes your aura is filled with holy power that bolsters your healing."),
    },
    ["Oath of Vengeance"] = {
        AlwaysPrepared("Oath of Vengeance"),
        Ability(3, "Vow of Enmity", "When you take the Attack action. For 1 minute you have advantage on attack rolls against one creature within 30 feet.",
            { Spend("Channel Divinity") }),
        Passive(7, "Relentless Avenger", "When you hit with an opportunity attack you can reduce the target's speed to 0 for the turn and then move half your speed."),
        Passive(15, "Soul of Vengeance", "When the creature under your Vow of Enmity makes an attack, you can use your reaction to make a melee attack against it."),
        Passive(20, "Avenging Angel", "Bonus action, once per long rest: for 10 minutes you gain a flying speed and an aura that frightens enemies."),
    },

    ---------------------------------------------------------------------------
    -- Hunter (Ranger)
    ---------------------------------------------------------------------------
    ["Beast Master"] = {
        Passive(3, "Primal Companion", "You summon a primal beast of the land, sea or sky. It acts on your turn, and you command it with a bonus action or by giving up one of your attacks."),
        Passive(7, "Exceptional Training", "When you command your beast you can also have it Dash, Disengage, Dodge or Help as its bonus action, and its attacks can deal force damage."),
        Passive(11, "Bestial Fury", "Your beast can strike twice when commanded, and deals extra damage to the creature under your Hunter's Mark once per turn."),
        Passive(15, "Share Spells", "A spell you cast on yourself can also affect your beast if it is within 30 feet."),
    },
    ["Hunter"] = {
        Passive(3, "Hunter's Lore", "You know the immunities, resistances and vulnerabilities of the creature marked by your Hunter's Mark."),
        Ability(3, "Colossus Slayer", "Hunter's Prey option. Once per turn, extra damage when you hit a creature that is missing hit points. The other option, Horde Breaker, gives an extra attack on a second nearby creature instead.",
            { Dice(1, 8) }),
        Passive(7, "Defensive Tactics", "Choose one: opportunity attacks have disadvantage against you, or a creature that hits you has disadvantage on its other attacks against you this turn. You can swap after a rest."),
        Passive(11, "Superior Hunter's Prey", "Once per turn, your Hunter's Mark damage can also hit a second creature within 30 feet of the first."),
        Passive(15, "Superior Hunter's Defense", "Reaction when you take damage: resistance to that damage type until the end of the turn."),
    },

    ---------------------------------------------------------------------------
    -- Rogue
    ---------------------------------------------------------------------------
    ["Assassin"] = {
        Passive(3, "Assassinate", "Advantage on initiative rolls. In the first round you have advantage against creatures that haven't acted, and your Sneak Attack deals extra damage equal to your level."),
        Passive(3, "Assassin's Tools", "You have a disguise kit and a poisoner's kit, and proficiency with both."),
        Passive(9, "Infiltration Expertise", "You can mimic a person's speech and handwriting after an hour of study, and Steady Aim no longer stops you moving."),
        Passive(13, "Envenom Weapons", "Your Poison Cunning Strike also deals 2d6 poison damage on a failed save, ignoring resistance."),
        Passive(17, "Death Strike", "A Sneak Attack in the first round forces a Constitution save; on a failure its damage is doubled."),
    },
    ["Soulknife"] = {
        Ability(3, "Psychic Blade", "A blade of psychic energy you can attack with whenever you take the Attack action. Finesse and thrown; it leaves no mark.",
            { Roll("ATTACK", "DEX"), Dice(1, 6, "DEX") }),
        Passive(3, "Psionic Power", "Psionic Energy Dice fuel your powers. Psi-Bolstered Knack: add one to a failed proficient check. Psychic Whispers: speak telepathically with several creatures for hours."),
        Passive(9, "Soul Blades", "Homing Strikes: add a Psionic Energy Die to a missed Psychic Blade attack. Psychic Teleportation: throw a blade and teleport up to 10 feet times the roll."),
        Passive(13, "Psychic Veil", "Magic action, once per long rest or by spending a die: become invisible for an hour or until you deal damage or force a save."),
        Passive(17, "Rend Mind", "When your Psychic Blade deals Sneak Attack damage, the target makes a Wisdom save or is stunned for up to a minute."),
    },
    ["Swashbuckler"] = {
        Passive(3, "Fancy Footwork", "A creature you make a melee attack against on your turn can't make opportunity attacks against you for the rest of that turn."),
        Passive(3, "Rakish Audacity", "You add your Charisma modifier to initiative. You can Sneak Attack without advantage when you are next to your target and no one else is next to you.",
            { Bonus("INIT", 0, "CHA") }),
        Passive(9, "Panache", "New Cunning Strike options that goad a target into attacking you or awe onlookers."),
        Passive(13, "Dashing Strikes", "New Cunning Strike options that bolster an ally or throw a target off balance."),
        Passive(17, "Master Duelist", "After using Sneak Attack you can attack the same target again if you are next to it and no one else is next to you."),
    },

    ---------------------------------------------------------------------------
    -- Priest (Cleric)
    ---------------------------------------------------------------------------
    ["Discipline Domain"] = {
        AlwaysPrepared("Discipline"),
        Passive(3, "Atonement", "Creatures you heal with a spell of level 1 or higher are blessed until the end of your next turn. When you then damage a creature with a slotted spell, the blessed are healed too."),
        Ability(3, "Holy Bolt", "Bonus action. A ranged spell attack against a creature within 60 feet that deals radiant damage on a hit.",
            { Spend("Channel Divinity"), Roll("SPELL", "WIS") }),
        Ability(6, "Luminous Barrier", "Bonus action. Each creature blessed by your Atonement gains temporary HP equal to your level plus your Wisdom modifier.",
            { Spend("Channel Divinity") }),
        Passive(17, "Ultimate Penitence", "Holy Bolt lets you teleport up to 30 feet first, and you can spend more to fire additional bolts."),
    },
    ["Life Domain"] = {
        AlwaysPrepared("Life Domain"),
        Passive(3, "Disciple of Life", "A slotted spell that heals a creature heals 2 + the slot's level more on the turn you cast it."),
        Ability(3, "Preserve Life", "Magic action. Restore hit points equal to five times your level, divided among Bloodied creatures within 30 feet, up to half their maximum each.",
            { Spend("Channel Divinity") }),
        Passive(6, "Blessed Healer", "When a slotted spell of yours heals others, you regain 2 + the slot's level yourself."),
        Passive(17, "Supreme Healing", "When you would roll dice to heal with a spell or Channel Divinity, use the highest possible result instead."),
    },
    ["Shadow Domain"] = {
        AlwaysPrepared("Shadow"),
        Ability(3, "Devouring Plague", "When a creature you can see within 30 feet fails a saving throw: it takes the roll as necrotic damage and you regain the same amount. A limited number of uses per long rest.",
            { Dice(1, 10) }),
        Ability(3, "Shadowform", "Bonus action. Take a shadowy form: you can Hide as a bonus action in dim light or darkness, and your void magic grows stronger.",
            { Spend("Channel Divinity") }),
        Passive(6, "Dispersion", "Reaction when hit: until the end of your next turn you resist all damage but can't act or cast."),
        Passive(17, "Vampiric Embrace", "While in Shadowform, whenever you roll a d6 of extra spell damage, a creature within 30 feet regains that many hit points."),
    },

    ---------------------------------------------------------------------------
    -- Druid
    ---------------------------------------------------------------------------
    ["Circle of the Land"] = {
        Passive(3, "Circle of the Land Spells", "After each long rest choose arid, polar, temperate or tropical land. You have that land's spells prepared for your level."),
        Ability(3, "Land's Aid", "Magic action, a point within 60 feet. Creatures of your choice in a 10-foot sphere make a Constitution save against necrotic damage, and one creature there is healed.",
            { Spend("Wild Shape") }),
        Passive(6, "Natural Recovery", "Once per long rest cast a Circle spell without a slot. On a short rest you can recover slots with a combined level up to half your level."),
        Passive(10, "Nature's Ward", "You can't be poisoned, and you resist the damage type tied to your current land."),
        Passive(14, "Nature's Sanctuary", "Magic action, spending a Wild Shape use: spectral trees give you and allies half cover and your Nature's Ward resistance for a minute."),
    },
    ["Circle of the Moon"] = {
        AlwaysPrepared("Circle of the Moon"),
        Passive(3, "Circle Forms", "Your Wild Shape forms can be tougher: challenge rating up to a third of your level, AC of at least 13 + Wisdom modifier, and temporary HP equal to three times your level."),
        Passive(6, "Improved Circle Forms", "In Wild Shape your attacks can deal radiant damage and you add your Wisdom modifier to Constitution saves."),
        Passive(10, "Moonlight Step", "Bonus action: teleport up to 30 feet and gain advantage on your next attack this turn. A few uses per long rest, or spend a 2nd-level slot."),
        Passive(14, "Lunar Form", "Once per turn deal 2d10 extra radiant damage in Wild Shape, and Moonlight Step can bring a willing creature along."),
    },
    ["Circle of the Stars"] = {
        Passive(3, "Star Map", "A star chart that serves as your spellcasting focus. With it you have Guidance and Guiding Bolt prepared, and can cast Guiding Bolt a few times per long rest without a slot."),
        Ability(3, "Starry Form", "Bonus action. Instead of a beast form you become starry for 10 minutes and choose a constellation: Archer (a bolt each turn), Chalice (extra healing) or Dragon (steadier concentration).",
            { Spend("Wild Shape") }),
        Ability(3, "Archer", "Starry Form, Archer constellation. Bonus action: a luminous arrow at a creature within 60 feet.",
            function(level) return { Roll("SPELL", "WIS"), Dice(level >= 10 and 2 or 1, 8, "WIS") } end),
        Ability(3, "Chalice", "Starry Form, Chalice constellation. When you heal with a slotted spell, you or a creature within 30 feet also regains this much.",
            function(level) return { Dice(level >= 10 and 2 or 1, 8, "WIS", "HEALING") } end),
        Passive(6, "Cosmic Omen", "After a long rest roll a die. Even: a reaction that adds a d6 to a creature's roll. Odd: one that subtracts a d6. A few uses per long rest."),
        Passive(10, "Twinkling Constellations", "Archer and Chalice use 2d8, the Dragon lets you fly and hover, and you can change constellation at the start of each turn."),
        Passive(14, "Full of Stars", "In Starry Form you resist bludgeoning, piercing and slashing damage."),
    },

    ---------------------------------------------------------------------------
    -- Monk
    ---------------------------------------------------------------------------
    ["Warrior of Mercy"] = {
        Passive(3, "Implements of Mercy", "Proficiency in Insight and Medicine and with the herbalism kit.", nil, { skills = { "Insight", "Medicine" } }),
        Ability(3, "Hand of Harm", "Once per turn when you hit with an unarmed strike: extra necrotic damage.",
            function(level) return { Spend("Focus Points"), Dice(1, Kit.MartialDie(level), "WIS") } end),
        Ability(3, "Hand of Healing", "Magic action: touch a creature to heal it. It can also replace one strike of your Flurry of Blows at no cost.",
            function(level) return { Spend("Focus Points"), Dice(1, Kit.MartialDie(level), "WIS", "HEALING") } end),
        Passive(6, "Physician's Touch", "Hand of Harm can also poison its target, and Hand of Healing can end a condition such as blinded, paralysed or stunned."),
        Passive(11, "Flurry of Healing and Harm", "Each strike of a Flurry of Blows can be a free Hand of Healing, and you can use Hand of Harm with a flurry strike without spending focus."),
        Passive(17, "Hand of Ultimate Mercy", "Magic action, 5 Focus Points, once per long rest: return a creature that died within a day to life."),
    },
    ["Warrior of Mystic Brews"] = {
        Passive(3, "Bonus Proficiencies", "Proficiency in Performance and with brewer's supplies.", nil, { skills = { "Performance" } }),
        Passive(3, "Drunken Technique", "When you spend focus on Patient Defense, your speed rises by 10 feet for the turn and you can make one unarmed strike."),
        Passive(6, "Mystic Brew", "After a rest with brewer's supplies you make one magical beverage with a lasting benefit. You can spend 1 Focus Point to make it last 8 hours."),
        Passive(6, "Tipsy Sway", "You can stand up from prone for 5 feet of movement. Reaction, 1 Focus Point: make a melee attack that missed you hit another creature next to you."),
        Passive(11, "Wizened Brewer", "You learn more complex brews with stronger effects."),
        Passive(17, "Intoxicated Frenzy", "After Patient Defense you can move your speed, making an unarmed strike against each creature you pass."),
        Passive(17, "Master Brewer", "One beverage can carry the effects of two different brews."),
    },
    ["Warrior of the Open Hand"] = {
        Passive(3, "Open Hand Technique", "When a Flurry of Blows strike hits you can also stop the target's opportunity attacks, push it 15 feet, or knock it prone."),
        Ability(6, "Wholeness of Body", "Bonus action: heal yourself. A number of uses per long rest equal to your Wisdom modifier.",
            function(level) return { Dice(1, Kit.MartialDie(level), "WIS", "HEALING") } end),
        Passive(11, "Fleet Step", "After any other bonus action you can also use Step of the Wind."),
        Passive(17, "Quivering Palm", "When you hit with an unarmed strike, spend 4 Focus Points to set up lethal vibrations. Later you can end them: the target makes a Constitution save against heavy force damage."),
    },

    ---------------------------------------------------------------------------
    -- Evoker (Sorcerer)
    ---------------------------------------------------------------------------
    ["Draconic Sorcery"] = {
        Passive(3, "Draconic Resilience", "Your maximum hit points increase by 1 for every Sorcerer level.", { Bonus("HP", 0, "LEVEL") }),
        Passive(3, "Draconic Scales", "Without armor your AC is 10 + Dexterity + Charisma modifiers. Switch this off while you wear armor.", { Bonus("AC", 0, "CHA") }),
        Passive(3, "Evoker Spells", "You always have extra spells prepared at certain levels. An Evoker uses the Evoker Spells list in place of the usual draconic one."),
        Passive(6, "Elemental Affinity", "Choose acid, cold, fire, lightning or poison. You resist it, and spells that deal it add your Charisma modifier to one damage roll."),
        Passive(14, "Dragon Wings", "Bonus action, once per long rest or for 3 Sorcery Points: wings give you a flying speed of 60 feet for an hour."),
        Passive(18, "Dragon Companion", "You can cast Summon Dragon without its material component, once per long rest without a slot, and can make it last without concentration."),
    },

    ---------------------------------------------------------------------------
    -- Warlock
    ---------------------------------------------------------------------------
    ["Fiend Patron"] = {
        AlwaysPrepared("Fiend"),
        Passive(3, "Dark One's Blessing", "When you reduce an enemy to 0 HP, or one drops within 10 feet of you, you gain temporary HP equal to your Charisma modifier plus your level."),
        Passive(6, "Dark One's Own Luck", "Add 1d10 to an ability check or saving throw after seeing the roll. A few uses per long rest."),
        Passive(10, "Fiendish Resilience", "After each rest choose a damage type other than force. You resist it until you choose another."),
        Passive(14, "Hurl Through Hell", "Once per turn when you hit, the target makes a Charisma save or vanishes through the Lower Planes, returning with heavy psychic damage. Once per long rest."),
    },
    ["Great Old One Patron"] = {
        AlwaysPrepared("Great Old One"),
        Passive(3, "Awakened Mind", "Bonus action: link minds with a creature within 30 feet and speak telepathically for a number of minutes equal to your level."),
        Passive(3, "Psychic Spells", "You can change the damage of your Warlock spells to psychic, and cast enchantments and illusions without words or gestures."),
        Passive(6, "Clairvoyant Combatant", "When you link minds you can force a Wisdom save: on a failure the creature has disadvantage attacking you and you have advantage attacking it."),
        Passive(10, "Eldritch Hex", "You always have Hex prepared, and its target also has disadvantage on saves with the chosen ability."),
        Passive(10, "Thought Shield", "Your thoughts can't be read, you resist psychic damage, and creatures that deal it to you take the same amount."),
        Passive(14, "Create Thrall", "Summon Aberration can last a minute without concentration, and the summoned creature gains temporary HP and deals extra damage to the target of your Hex."),
    },

    ---------------------------------------------------------------------------
    -- Mage (Wizard)
    ---------------------------------------------------------------------------
    ["Evoker"] = {
        Passive(3, "Evocation Savant", "Two free evocation spells in your spellbook now, and another each time you gain a new level of spell slots."),
        Passive(3, "Potent Cantrip", "A damaging cantrip still deals half damage when it misses or the target saves."),
        Passive(6, "Sculpt Spells", "When you cast an evocation spell you can protect a few creatures you can see: they pass the save and take no damage."),
        Passive(10, "Empowered Evocation", "Add your Intelligence modifier to one damage roll of any evocation spell you cast."),
        Passive(14, "Overchannel", "Deal maximum damage with a damaging spell of level 1 to 5. The first use each long rest is free; later ones cost you necrotic damage."),
    },
}
