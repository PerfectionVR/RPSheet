-- Core class features (2024 rules), added to a sheet automatically by class and level.
-- Keyed by the Player's Handbook class a World of Warcraft class uses.
--
-- Each feature becomes an ability (something you click) or a passive. Features that
-- change numbers or roll dice are fully wired; the rest are short reminders in our
-- own words. Numbers that grow with level are given as functions of the level and
-- are refreshed whenever the character's level changes.
--
-- A feature with a set number of uses (Limited) gets a bar of its own on the sheet.
-- Subclass features are in SubclassFeatures.lua; what Death Knights, Demon Hunters and
-- Shaman do differently is in ClassOverrides.lua.
local _, ns = ...
local R = ns.Rules

local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Bonus

local WEAPON_MASTERY = Passive(1, "Weapon Mastery", "You can use the mastery property of a few kinds of weapon you are proficient with, and change your choices after a long rest. Set each weapon's mastery under Customize, Weapons: it shows on the weapon row and is called out when you attack.")
local FIGHTING_STYLE = "You gain a Fighting Style feat of your choice."
local function ExtraAttack(level)
    return Passive(level, "Extra Attack", "You attack twice, instead of once, when you take the Attack action.")
end

R.FEATURES = {
    Barbarian = {
        Ability(1, "Rage", "Bonus action. For up to 10 minutes: resistance to bludgeoning, piercing and slashing damage, bonus damage on Strength attacks, and advantage on Strength checks and saves. You can't cast spells while raging.",
            { Spend("Rage"), SwitchOn("Raging") }),
        Passive(1, "Raging", "Switch on while you rage. Adds the rage damage bonus to your damage rolls.",
            function(level) return { Bonus("DAMAGE", AtLevel(level, { { 1, 2 }, { 9, 3 }, { 16, 4 } })) } end, true),
        WEAPON_MASTERY,
        Passive(2, "Danger Sense", "Advantage on Dexterity saving throws unless you are incapacitated."),
        Passive(2, "Reckless Attack", "On your first attack of a turn you can attack recklessly: advantage on Strength attacks this turn, but attacks against you have advantage until your next turn."),
        ExtraAttack(5),
        Passive(5, "Fast Movement", "Your speed increases by 10 feet while you aren't wearing heavy armor.", { Bonus("SPEED", 10) }),
        Passive(7, "Feral Instinct", "Advantage on initiative rolls."),
        Passive(9, "Brutal Strike", "When you attack recklessly you can give up advantage on one attack to deal 1d10 extra damage and push or slow the target."),
        Passive(11, "Relentless Rage", "While raging, when you drop to 0 HP you can make a DC 10 Constitution save to stay up with HP equal to twice your level. The DC rises by 5 each time until you rest."),
        Limited(15, "Persistent Rage", "Your rage lasts the full 10 minutes without needing to be extended. Once per long rest, when you roll initiative, you regain all Rage uses.", 1,
            { { type = "GAIN", resource = "Rage", amount = 6 } }),
        Passive(18, "Indomitable Might", "If a Strength check or save totals less than your Strength score, use the score instead."),
        Passive(20, "Primal Champion", "Your Strength and Constitution each increase by 4, to a maximum of 25."),
    },

    Cleric = {
        Passive(1, "Divine Order", "Protector: heavy armor and martial weapons. Thaumaturge: an extra cantrip and a bonus to Arcana or Religion checks."),
        Ability(2, "Divine Spark", "Magic action, 30 feet. Heal a creature by the roll, or make it roll a Constitution save: it takes the roll as radiant or necrotic damage, half on a success.",
            function(level) return { Spend("Channel Divinity"), Dice(AtLevel(level, { { 2, 1 }, { 7, 2 }, { 13, 3 }, { 18, 4 } }), 8, "WIS", "HEALING") } end),
        Ability(2, "Turn Undead", "Magic action. Each undead of your choice within 30 feet makes a Wisdom save or is frightened and incapacitated for 1 minute.",
            { Spend("Channel Divinity") }),
        Passive(5, "Sear Undead", "Undead that fail against Turn Undead also take radiant damage: a d8 per point of your Wisdom modifier."),
        Passive(7, "Blessed Strikes", "Divine Strike: once per turn add 1d8 necrotic or radiant damage to a weapon hit. Or Potent Spellcasting: add your Wisdom modifier to cantrip damage."),
        Limited(10, "Divine Intervention", "Magic action, once per long rest. Cast any Cleric spell of 5th level or lower without a slot or components.", 1),
        Passive(14, "Improved Blessed Strikes", "Divine Strike deals 2d8. Or, with Potent Spellcasting, your damaging cantrips also grant temporary HP to you or an ally."),
    },

    Druid = {
        Passive(1, "Druidic", "You know the secret language of druids and always have Speak with Animals prepared."),
        Passive(1, "Primal Order", "Magician: an extra cantrip and a bonus to Arcana or Nature checks. Warden: medium armor and martial weapons."),
        Ability(2, "Wild Shape", "Bonus action. Take the form of a beast you know for a number of hours equal to half your level. You gain temporary HP equal to your level.",
            { Spend("Wild Shape") }),
        Passive(2, "Wild Companion", "You can spend a spell slot or a Wild Shape use to cast Find Familiar without components."),
        Passive(5, "Wild Resurgence", "Once per turn, with no Wild Shape uses left, you can spend a spell slot to gain one. Once per long rest you can spend a Wild Shape use for a 1st-level slot."),
        Passive(7, "Elemental Fury", "Potent Spellcasting: add your Wisdom modifier to cantrip damage. Or Primal Strike: once per turn add 1d8 elemental damage to a weapon or beast-form hit."),
        Passive(18, "Beast Spells", "You can cast spells while in a Wild Shape form."),
    },

    Fighter = {
        Passive(1, "Fighting Style", FIGHTING_STYLE),
        Ability(1, "Second Wind", "Bonus action. Regain hit points equal to the roll. One use comes back on a short rest, all on a long rest.",
            { Spend("Second Wind"), Dice(1, 10, "LEVEL", "SELFHEAL") }),
        WEAPON_MASTERY,
        Ability(2, "Action Surge", "Take one additional action this turn, other than the Magic action. Once per turn.", { Spend("Action Surge") }),
        Ability(2, "Tactical Mind", "When you fail an ability check: spend a Second Wind use and add the roll to the check. If it still fails the use isn't spent: left-click the Second Wind bar to take it back.",
            { Spend("Second Wind"), Dice(1, 10, "", "OTHER") }),
        Passive(5, "Extra Attack", function(level)
            local attacks = (level >= 20 and "four times") or (level >= 11 and "three times") or "twice"
            return ("You attack %s, instead of once, when you take the Attack action. Click the weapon once per attack."):format(attacks)
        end),
        Passive(5, "Tactical Shift", "When you use Second Wind you can move up to half your speed without provoking opportunity attacks."),
        Ability(9, "Indomitable", "When you fail a saving throw: reroll it, adding your level. You must use the new roll. Click this, then roll the save again and add the bonus shown.",
            { Spend("Indomitable"), Dice(0, 4, "LEVEL", "OTHER") }),
        Passive(9, "Tactical Master", "When you attack with a weapon whose mastery you can use, you can swap that mastery for Push, Sap or Slow for that attack."),
        Passive(13, "Studied Attacks", "If you miss a creature with an attack, you have advantage on your next attack against it before the end of your next turn."),
    },

    Monk = {
        Passive(1, "Martial Arts", "Your unarmed strikes and monk weapons can use Dexterity and your Martial Arts die, and you can make one unarmed strike as a bonus action."),
        Ability(1, "Unarmed Strike", "A punch, kick or headbutt using your Martial Arts die.",
            function(level)
                return {
                    { type = "ROLL", kind = "ATTACK", stat = "DEX", stat2 = "", proficient = true },
                    Dice(1, AtLevel(level, { { 1, 6 }, { 5, 8 }, { 11, 10 }, { 17, 12 } }), "DEX"),
                }
            end),
        Ability(2, "Flurry of Blows", "Bonus action. Make two unarmed strikes, or three from level 10.", { Spend("Focus Points") }),
        Ability(2, "Patient Defense", "Bonus action. Disengage and Dodge together. Without spending focus you can still Disengage.", { Spend("Focus Points") }),
        Ability(2, "Step of the Wind", "Bonus action. Disengage and Dash together, and your jump distance doubles. Without spending focus you can still Dash.", { Spend("Focus Points") }),
        Passive(2, "Unarmored Movement", "Your speed increases while you wear no armor and carry no shield.",
            function(level) return { Bonus("SPEED", AtLevel(level, { { 2, 10 }, { 6, 15 }, { 10, 20 }, { 14, 25 }, { 18, 30 } })) } end),
        Limited(2, "Uncanny Metabolism", "Once per long rest, when you roll initiative: regain all Focus Points and heal by the roll.", 1,
            function(level) return { { type = "GAIN", resource = "Focus Points", amount = 20 }, Dice(1, Kit.MartialDie(level), "LEVEL", "SELFHEAL") } end),
        Passive(3, "Deflect Attacks", "Reaction when hit by an attack: reduce the damage by 1d10 + your Dexterity modifier + your level. If it drops to 0, you can spend focus to redirect it."),
        Passive(4, "Slow Fall", "Reaction when you fall: reduce the damage by five times your level."),
        ExtraAttack(5),
        Ability(5, "Stunning Strike", "Once per turn when you hit with a monk weapon or unarmed strike: the target makes a Constitution save or is stunned until the start of your next turn.",
            { Spend("Focus Points") }),
        Passive(6, "Empowered Strikes", "Your unarmed strikes can deal force damage."),
        Passive(7, "Evasion", "On a Dexterity save for half damage you take none on a success and half on a failure."),
        Passive(10, "Self-Restoration", "At the end of each turn you can end the charmed, frightened or poisoned condition on yourself. Going without food or drink doesn't exhaust you."),
        Passive(14, "Disciplined Survivor", "You are proficient in all saving throws, and can spend 1 Focus Point to reroll a failed save."),
        Passive(18, "Superior Defense", "At the start of your turn you can spend 3 Focus Points to resist all damage except force for 1 minute."),
    },

    Paladin = {
        Ability(1, "Lay on Hands", "Bonus action. Heal a creature you touch from your pool. This spends 5 points; change the bar by hand for other amounts. Spending 5 can also remove the poisoned condition.",
            { Spend("Lay on Hands", 5) }),
        WEAPON_MASTERY,
        Passive(2, "Fighting Style", FIGHTING_STYLE),
        Ability(2, "Divine Smite", "After you hit with a melee weapon or unarmed strike: 2d8 radiant damage. Add 1d8 against fiends and undead, and 1d8 for each slot level above 1st.",
            { Spend("1st-level slot"), Dice(2, 8) }),
        Ability(3, "Divine Sense", "Bonus action. For 10 minutes you know the location of celestials, fiends and undead within 60 feet.", { Spend("Channel Divinity") }),
        ExtraAttack(5),
        Limited(5, "Faithful Steed", "You always have Find Steed prepared. Once per long rest you can cast it without a slot.", 1),
        Passive(6, "Aura of Protection", "You and allies within 10 feet add your Charisma modifier to saving throws (at least +1).", { Bonus("SAVES", 0, "CHA") }),
        Ability(9, "Abjure Foes", "Magic action. Creatures of your choice within 60 feet make a Wisdom save or are frightened for 1 minute and can do little on their turns.",
            { Spend("Channel Divinity") }),
        Passive(10, "Aura of Courage", "You and allies in your aura can't be frightened."),
        Passive(11, "Radiant Strikes", "Your melee weapon and unarmed hits deal 1d8 extra radiant damage."),
        Passive(14, "Restoring Touch", "When you use Lay on Hands you can spend 5 points per condition to end blinded, charmed, deafened, frightened, paralysed or stunned."),
    },

    Ranger = {
        Ability(1, "Hunter's Mark", "Bonus action, a free casting of the spell. Mark a creature you can see for up to an hour.",
            { Spend("Favored Enemy"), SwitchOn("Hunter's Mark") }),
        Passive(1, "Hunter's Mark", "Switch on while a creature is marked. Your hits on it deal 1d6 extra force damage, and you have advantage on Perception and Survival checks to find it.", nil, true),
        WEAPON_MASTERY,
        Passive(2, "Deft Explorer", "Expertise in one skill you are proficient in, and two extra languages."),
        Passive(2, "Fighting Style", FIGHTING_STYLE),
        ExtraAttack(5),
        Passive(6, "Roving", "Your speed increases by 10 feet without heavy armor, and you gain climbing and swimming speeds.", { Bonus("SPEED", 10) }),
        Passive(9, "Expertise", "Expertise in two more skills you are proficient in."),
        Limited(10, "Tireless", "Magic action: gain temporary HP equal to the roll. You have uses equal to your Wisdom modifier per long rest. A short rest also reduces your exhaustion by one.",
            { stat = "WIS" }, { Dice(1, 8, "WIS", "TEMPHP") }),
        Passive(13, "Relentless Hunter", "Taking damage can't break your concentration on Hunter's Mark."),
        Limited(14, "Nature's Veil", "Bonus action: become invisible until the end of your next turn. You have uses equal to your Wisdom modifier per long rest.", { stat = "WIS" }),
        Passive(17, "Precise Hunter", "Advantage on attack rolls against the creature marked by your Hunter's Mark."),
        Passive(18, "Feral Senses", "Blindsight out to 30 feet."),
    },

    Rogue = {
        Passive(1, "Expertise", "Expertise in two skills you are proficient in. Two more at level 6."),
        Ability(1, "Sneak Attack", "Once per turn, extra damage on a hit with a finesse or ranged weapon when you have advantage, or when an ally is next to the target.",
            function(level) return { Dice(math.ceil(level / 2), 6) } end),
        Passive(1, "Thieves' Cant", "You know the secret mix of jargon and signs used by thieves, plus one other language."),
        WEAPON_MASTERY,
        Passive(2, "Cunning Action", "Dash, Disengage or Hide as a bonus action."),
        Passive(3, "Steady Aim", "Bonus action, if you haven't moved: advantage on your next attack this turn, and your speed is 0 until the turn ends."),
        Passive(5, "Cunning Strike", "Give up Sneak Attack dice to add an effect to the hit, such as poison, a trip or a withdrawal."),
        Passive(5, "Uncanny Dodge", "Reaction when an attacker you can see hits you: halve the damage."),
        Passive(7, "Evasion", "On a Dexterity save for half damage you take none on a success and half on a failure."),
        Passive(7, "Reliable Talent", "On checks with skills or tools you are proficient in, treat a d20 roll of 9 or lower as a 10."),
        Passive(15, "Slippery Mind", "You gain proficiency in Wisdom and Charisma saving throws."),
        Passive(18, "Elusive", "No attack roll has advantage against you unless you are incapacitated."),
        Limited(20, "Stroke of Luck", "Turn a failed d20 roll into a 20. Once per short or long rest.", 1, nil, "ALL"),
    },

    Sorcerer = {
        Ability(1, "Innate Sorcery", "Bonus action. For 1 minute your spell save DC rises by 1 and you have advantage on spell attack rolls.",
            { Spend("Innate Sorcery"), SwitchOn("Innate Sorcery active") }),
        Passive(1, "Innate Sorcery active", "Switch on while Innate Sorcery lasts. Adds 1 to your spell save DC; remember the advantage on spell attacks.",
            { Bonus("SPELLDC", 1) }, true),
        Passive(2, "Font of Magic", "You can turn Sorcery Points into spell slots and spell slots into Sorcery Points."),
        Passive(2, "Metamagic", "You know Metamagic options that reshape your spells for a cost in Sorcery Points."),
        Limited(5, "Sorcerous Restoration", "Once per long rest, when you finish a short rest: regain Sorcery Points up to half your level. Raise the Sorcery Points bar by hand.", 1),
        Passive(7, "Sorcery Incarnate", "With no Innate Sorcery uses left you can spend 2 Sorcery Points to activate it, and while it is active you can use two Metamagic options on one spell."),
    },

    Warlock = {
        Passive(1, "Eldritch Invocations", "You know a number of invocations: fragments of forbidden knowledge that grant lasting magical abilities."),
        Passive(1, "Pact Magic", "Your spell slots are all of one level and come back on a short rest."),
        Limited(2, "Magical Cunning", "Once per long rest, a 1-minute rite restores half of your pact slots, rounded up. Restore the slots on the sheet by hand.", 1),
        Limited(9, "Contact Patron", "You always have Contact Other Plane prepared. Once per long rest you can cast it without a slot, succeeding on its save.", 1),
        Limited(11, "Mystic Arcanum", "You learn one 6th-level spell to cast once per long rest without a slot, and a 7th, 8th and 9th-level one at levels 13, 15 and 17. Each can be cast once; the bar counts the casts you have left.",
            { { 11, 1 }, { 13, 2 }, { 15, 3 }, { 17, 4 } }),
    },

    Wizard = {
        Passive(1, "Ritual Adept", "You can cast any ritual spell in your spellbook as a ritual without preparing it."),
        Ability(1, "Arcane Recovery", "After a short rest, recover spell slots with a combined level of up to half your level, rounded up, none above 5th. Restore the slots on the sheet by hand.",
            { Spend("Arcane Recovery") }),
        Passive(2, "Scholar", "Expertise in one of Arcana, History, Investigation, Medicine, Nature or Religion that you are proficient in."),
        Passive(5, "Memorize Spell", "After a short rest you can swap one prepared spell for another from your spellbook."),
        Passive(18, "Spell Mastery", "Choose a 1st and a 2nd-level spell from your spellbook: you can cast them at their lowest level without a slot."),
    },
}
