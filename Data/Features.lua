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
-- The better of Strength and Dexterity, for a Monk's strikes.
local function MonkStat(sheet)
    return Kit.Mod(sheet, "DEX") > Kit.Mod(sheet, "STR") and "DEX" or "STR"
end

-- `count` unarmed strikes: an attack roll and the Martial Arts die for each.
local function UnarmedStrikes(count, level, sheet)
    local stat, steps = MonkStat(sheet), {}
    for _ = 1, count do
        steps[#steps + 1] = Kit.Roll("ATTACK", stat)
        steps[#steps + 1] = Dice(1, Kit.MartialDie(level), stat)
    end
    return steps
end

local function ExtraAttack(level)
    return Passive(level, "Extra Attack", "You attack twice, instead of once, when you take the Attack action.")
end

R.FEATURES = {
    Barbarian = {
        Ability(1, "Rage", "Bonus action, not in heavy armor. Until the end of your next turn, extended each turn you attack, force a save or spend a bonus action (up to 10 minutes): resistance to bludgeoning, piercing and slashing damage, bonus damage on Strength attacks, and advantage on Strength checks and saves. You can't cast spells or concentrate. One use comes back on a short rest. Switches Raging on.",
            { Spend("Rage"), SwitchOn("Raging") }),
        Passive(1, "Raging", function(level)
            return ("Switch on while you rage. Adds %d to your damage rolls and gives advantage on Strength checks, Strength saves and Athletics, which the sheet rolls for you."):format(Kit.RageDamage(level))
        end, function(level) return { Bonus("DAMAGE", Kit.RageDamage(level)) } end,
            { startsOff = true, advantage = { "STR check", "STR save", "Athletics" } }),
        WEAPON_MASTERY,
        Passive(2, "Danger Sense", "Advantage on Dexterity saving throws unless you are incapacitated. The sheet rolls them this way.", nil, { advantage = { "DEX save" } }),
        Ability(2, "Reckless Attack", "On your first attack of a turn: advantage on Strength attacks until your next turn, but attacks against you have advantage too. Switches Reckless on; switch it off at the start of your next turn.",
            { SwitchOn("Reckless") }),
        Passive(2, "Reckless", "Switch on while you attack recklessly: the sheet rolls your attacks with advantage.", nil, { startsOff = true, advantage = { "attack" } }),
        ExtraAttack(5),
        Passive(5, "Fast Movement", "Your speed increases by 10 feet while you aren't wearing heavy armor.", { Bonus("SPEED", 10) }),
        Passive(7, "Feral Instinct", "Advantage on initiative rolls, which the sheet rolls for you.", nil, { advantage = { "initiative" } }),
        Passive(7, "Instinctive Pounce", "When you enter your Rage you can move up to half your speed as part of that bonus action."),
        Ability(9, "Brutal Strike", function(level)
            local effects = "Forceful Blow (push 15 feet, then you may follow) or Hamstring Blow (its speed drops by 15 feet)"
            if level >= 13 then effects = effects .. ", Staggering Blow (disadvantage on its next save, no opportunity attacks) or Sundering Blow (the next attack against it by another gets +5)" end
            return ("When you attack recklessly, give up advantage on one Strength attack: if it hits, extra damage and %s effect%s: %s."):format(
                level >= 17 and "two different" or "one", level >= 17 and "s" or "", effects)
        end, function(level) return { Dice(level >= 17 and 2 or 1, 10) } end),
        Ability(11, "Relentless Rage", function(level)
            return ("When you drop to 0 hit points while raging: roll this Constitution save against DC 10, which rises by 5 each time until you rest. On a success you stand with %d hit points: set your HP by hand."):format(2 * level)
        end, { Kit.Roll("SAVE", "CON") }),
        Passive(13, "Improved Brutal Strike", "Brutal Strike gains the Staggering Blow and Sundering Blow effects."),
        Limited(15, "Persistent Rage", "Your rage lasts the full 10 minutes without needing to be extended. Once per long rest, when you roll initiative, you regain all Rage uses.", 1,
            { { type = "GAIN", resource = "Rage", amount = 6 } }),
        Passive(17, "Improved Brutal Strike II", "Brutal Strike deals 2d10 and can apply two different effects."),
        Passive(18, "Indomitable Might", "If a Strength check or save totals less than your Strength score, use the score instead."),
        Passive(20, "Primal Champion", "Your Strength and Constitution each increase by 4, to a maximum of 25. The sheet applies this.", nil, { scores = { STR = 4, CON = 4 } }),
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
        Passive(1, "Martial Arts", function(level)
            return ("Unarmed and with monk weapons (simple melee weapons and light martial ones), without armor or a shield: you can use Dexterity for attacks and damage, roll a d%d in place of their normal damage, and make one unarmed strike as a bonus action."):format(Kit.MartialDie(level))
        end),
        Ability(1, "Unarmed Strike", "A punch, kick or headbutt using your Martial Arts die. Also your bonus-action strike.",
            function(level, sheet) return UnarmedStrikes(1, level, sheet) end),
        Passive(2, "Monk's Focus", function(_, sheet)
            return ("Focus Points fuel your techniques and all come back on a short or long rest. Saves against them use DC %d (8 + Wisdom modifier + proficiency bonus)."):format(Kit.DC(sheet, "WIS"))
        end),
        Ability(2, "Flurry of Blows", function(level)
            return ("Bonus action. %s unarmed strikes."):format(level >= 10 and "Three" or "Two")
        end, function(level, sheet)
            local steps = UnarmedStrikes(level >= 10 and 3 or 2, level, sheet)
            table.insert(steps, 1, Spend("Focus Points"))
            return steps
        end),
        Ability(2, "Patient Defense", function(level)
            return "Bonus action. Disengage and Dodge together. Without spending focus you can still Disengage."
                .. (level >= 10 and " You also gain temporary hit points equal to the roll." or "")
        end, function(level)
            local steps = { Spend("Focus Points") }
            if level >= 10 then steps[2] = Dice(2, Kit.MartialDie(level), "", "TEMPHP") end
            return steps
        end),
        Ability(2, "Step of the Wind", function(level)
            return "Bonus action. Disengage and Dash together, and your jump distance doubles. Without spending focus you can still Dash."
                .. (level >= 10 and " You can carry a willing Large or smaller creature within 5 feet along with you." or "")
        end, { Spend("Focus Points") }),
        Passive(2, "Unarmored Movement", "Your speed increases while you wear no armor and carry no shield.",
            function(level) return { Bonus("SPEED", AtLevel(level, { { 2, 10 }, { 6, 15 }, { 10, 20 }, { 14, 25 }, { 18, 30 } })) } end),
        Limited(2, "Uncanny Metabolism", "Once per long rest, when you roll initiative: regain all Focus Points and heal by the roll.", 1,
            function(level) return { { type = "GAIN", resource = "Focus Points", amount = 20 }, Dice(1, Kit.MartialDie(level), "LEVEL", "SELFHEAL") } end),
        Ability(3, "Deflect Attacks", function(level)
            return ("Reaction when an attack hits you with %s: reduce it by the roll."):format(level >= 13 and "any damage" or "bludgeoning, piercing or slashing damage")
        end, function(level) return { Dice(1, 10, "DEX", "OTHER", level) } end),
        Ability(3, "Deflect Attacks: redirect", function(_, sheet)
            return ("When Deflect Attacks reduces the damage to 0: send it at a creature within 5 feet (60 feet for a ranged attack), which takes the roll unless it passes a Dexterity save, DC %d."):format(Kit.DC(sheet, "WIS"))
        end, function(level) return { Spend("Focus Points"), Dice(2, Kit.MartialDie(level), "DEX") } end),
        Passive(4, "Slow Fall", function(level)
            return ("Reaction when you fall: reduce the damage by %d."):format(5 * level)
        end),
        ExtraAttack(5),
        Ability(5, "Stunning Strike", function(_, sheet)
            return ("Once per turn when you hit with a monk weapon or unarmed strike: the target makes a Constitution save, DC %d. On a failure it is stunned until the start of your next turn. On a success its speed is halved and the next attack against it has advantage."):format(Kit.DC(sheet, "WIS"))
        end, { Spend("Focus Points") }),
        Passive(6, "Empowered Strikes", "Your unarmed strikes can deal force damage."),
        Passive(7, "Evasion", "On a Dexterity save for half damage you take none on a success and half on a failure."),
        Passive(9, "Acrobatic Movement", "Without armor or a shield you can move along vertical surfaces and across liquids on your turn without falling."),
        Passive(10, "Heightened Focus", "Flurry of Blows makes three strikes, Patient Defense grants temporary hit points, and Step of the Wind can carry a creature along."),
        Passive(10, "Self-Restoration", "At the end of each turn you can end the charmed, frightened or poisoned condition on yourself. Going without food or drink doesn't exhaust you."),
        Passive(13, "Deflect Energy", "Deflect Attacks works against attacks of any damage type."),
        Passive(14, "Disciplined Survivor", "You are proficient in all saving throws.", nil, { saves = { "STR", "DEX", "CON", "INT", "WIS", "CHA" } }),
        Ability(14, "Disciplined Survivor: reroll", "When you fail a saving throw: reroll it. You must use the new roll.", { Spend("Focus Points") }),
        Passive(15, "Perfect Focus", "When you roll initiative without using Uncanny Metabolism and have 3 or fewer Focus Points, you go up to 4. Raise the bar by hand."),
        Ability(18, "Superior Defense", "At the start of your turn: for 1 minute, or until you are incapacitated, you resist all damage except force.",
            { Spend("Focus Points", 3) }),
        Passive(20, "Body and Mind", "Your Dexterity and Wisdom each increase by 4, to a maximum of 25. The sheet applies this.", nil, { scores = { DEX = 4, WIS = 4 } }),
    },

    Paladin = {
        Ability(1, "Lay on Hands", "Bonus action. Heal a creature you touch from your pool. Each click spends 5 points and heals 5; change the bar by hand for other amounts. Spending 5 can instead remove the poisoned condition.",
            { Spend("Lay on Hands", 5), Dice(0, 4, "", "HEALING", 5) }),
        WEAPON_MASTERY,
        Passive(2, "Fighting Style", FIGHTING_STYLE),
        Limited(2, "Paladin's Smite", "You always have Divine Smite prepared. Once per long rest you can cast it without a slot: this is that casting.", 1, { Dice(2, 8) }),
        Ability(2, "Divine Smite", "Bonus action after you hit with a melee weapon or unarmed strike: radiant damage. Add 1d8 against fiends and undead, and 1d8 for each slot level above 1st.",
            { Spend("1st-level slot"), Dice(2, 8) }),
        Ability(3, "Divine Sense", "Bonus action. For 10 minutes you know the location of celestials, fiends and undead within 60 feet.", { Spend("Channel Divinity") }),
        ExtraAttack(5),
        Limited(5, "Faithful Steed", "You always have Find Steed prepared. Once per long rest you can cast it without a slot.", 1),
        Passive(6, "Aura of Protection", function(level)
            return ("You and allies within %d feet add your Charisma modifier to saving throws (at least +1). The sheet adds it to yours."):format(level >= 18 and 30 or 10)
        end, { Bonus("SAVES", 0, "CHA") }),
        Ability(9, "Abjure Foes", function(_, sheet)
            return ("Magic action. Creatures you can see within 60 feet, up to your Charisma modifier, make a Wisdom save (DC %d) or are frightened for 1 minute and can only move, act or take a bonus action on their turns."):format(Kit.DC(sheet, "CHA"))
        end, { Spend("Channel Divinity") }),
        Passive(10, "Aura of Courage", "You and allies in your aura can't be frightened."),
        Passive(11, "Radiant Strikes", "Your melee weapon and unarmed hits deal 1d8 extra radiant damage. The sheet rolls it with every melee attack.",
            nil, { strike = { sides = 8, damage = "radiant" } }),
        Passive(14, "Restoring Touch", "When you use Lay on Hands you can spend 5 points per condition to end blinded, charmed, deafened, frightened, paralyzed or stunned."),
        Passive(18, "Aura Expansion", "Your Aura of Protection reaches 30 feet."),
    },

    Ranger = {
        Ability(1, "Hunter's Mark", "Bonus action, a casting of the spell without a slot. Mark a creature you can see within 90 feet for up to an hour (concentration). Switches the mark on.",
            { Spend("Favored Enemy"), SwitchOn("Hunter's Mark") }),
        Passive(1, "Hunter's Mark", function(level)
            return ("Switch on while a creature is marked. Your hits on it deal 1d%d extra force damage (use Hunter's Mark: damage), and you have advantage on Perception and Survival checks to find it.%s"):format(
                level >= 20 and 10 or 6, level >= 17 and " You have advantage on attack rolls against it, which the sheet applies while this is on." or "")
        end, nil, { startsOff = true, advantage = function(level) return level >= 17 and { "attack" } or nil end }),
        Ability(1, "Hunter's Mark: damage", "The extra force damage when you hit the marked creature.",
            function(level) return { Dice(1, level >= 20 and 10 or 6) } end),
        WEAPON_MASTERY,
        Passive(2, "Deft Explorer", "Expertise in one skill you are proficient in (set it under Customize, Proficiencies), and two more languages of your choice.", nil, { flags = { languages = 2 } }),
        Passive(2, "Fighting Style", FIGHTING_STYLE),
        ExtraAttack(5),
        Passive(6, "Roving", "Your speed increases by 10 feet without heavy armor, and you gain climbing and swimming speeds.", { Bonus("SPEED", 10) }),
        Passive(9, "Expertise", "Expertise in two more skills you are proficient in. Set them under Customize, Proficiencies."),
        Limited(10, "Tireless", "Magic action: gain temporary HP equal to the roll. Uses equal to your Wisdom modifier per long rest. A short rest also reduces your exhaustion by one.",
            { stat = "WIS" }, { Dice(1, 8, "WIS", "TEMPHP") }),
        Passive(13, "Relentless Hunter", "Taking damage can't break your concentration on Hunter's Mark."),
        Limited(14, "Nature's Veil", "Bonus action: become invisible until the end of your next turn. Uses equal to your Wisdom modifier per long rest.", { stat = "WIS" }),
        Passive(17, "Precise Hunter", "Advantage on attack rolls against the creature marked by your Hunter's Mark. Applied while the Hunter's Mark passive is switched on."),
        Passive(18, "Feral Senses", "Blindsight out to 30 feet."),
        Passive(20, "Foe Slayer", "Your Hunter's Mark deals a d10 of extra damage."),
    },

    Rogue = {
        Passive(1, "Expertise", function(level)
            return ("Expertise in %s skills you are proficient in: your proficiency bonus counts twice. Set them under Customize, Proficiencies."):format(level >= 6 and "four" or "two")
        end),
        Ability(1, "Sneak Attack", "Once per turn, extra damage on a hit with a finesse or ranged weapon when you have advantage, or when an ally is within 5 feet of the target and you don't have disadvantage.",
            function(level) return { Dice(math.ceil(level / 2), 6) } end),
        Passive(1, "Thieves' Cant", "You know the secret mix of jargon and signs used by thieves, and one more language of your choice.", nil, { flags = { languages = 1 } }),
        WEAPON_MASTERY,
        Passive(2, "Cunning Action", "Dash, Disengage or Hide as a bonus action."),
        Ability(3, "Steady Aim", "Bonus action, if you haven't moved this turn: advantage on your next attack roll, and your speed is 0 until the turn ends. Sets your next roll to advantage.",
            { Kit.NextRoll("ADV") }),
        Passive(5, "Cunning Strike", function(level)
            return ("When you deal Sneak Attack damage you can give up dice for an effect: use the Cunning Strike abilities in place of Sneak Attack. %s"):format(
                level >= 11 and "You can use two effects on one Sneak Attack, paying for both." or "One effect per Sneak Attack.")
        end),
        Kit.CunningStrike(5, "Poison", 1, "The target is poisoned for a minute if it fails, repeating the save each turn. Needs a poisoner's kit.", "Constitution"),
        Kit.CunningStrike(5, "Trip", 1, "A Large or smaller target falls prone if it fails.", "Dexterity"),
        Kit.CunningStrike(5, "Withdraw", 1, "Right after the attack you move up to half your speed without provoking opportunity attacks."),
        Passive(5, "Uncanny Dodge", "Reaction when an attacker you can see hits you: halve the damage."),
        Passive(7, "Evasion", "On a Dexterity save for half damage you take none on a success and half on a failure."),
        Passive(7, "Reliable Talent", "On checks with skills you are proficient in, a d20 roll of 9 or lower counts as a 10. The sheet applies this.", nil, { flags = { reliable = true } }),
        Kit.CunningStrike(14, "Daze", 2, "If it fails, on its next turn the target can only move, or take an action, or take a bonus action.", "Constitution"),
        Kit.CunningStrike(14, "Knock Out", 6, "If it fails, the target is unconscious for a minute or until it takes damage, repeating the save each turn.", "Constitution"),
        Kit.CunningStrike(14, "Obscure", 3, "If it fails, the target is blinded until the end of its next turn.", "Dexterity"),
        Passive(15, "Slippery Mind", "You are proficient in Wisdom and Charisma saving throws.", nil, { saves = { "WIS", "CHA" } }),
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
