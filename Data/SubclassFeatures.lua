-- Subclass features, added to a sheet by subclass and level like the class features
-- in Features.lua. Keyed by the subclass name as listed in Classes.lua.
--
-- Summaries are short and in our own words; features that roll or change numbers are
-- wired up. Not covered: the Death Knight's Oath of the Ebon Blade and the Demon Hunter
-- subclass, which rewrite parts of their base class.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus

-- A Passive's description may be a function of the level. Its `extra` table can carry
-- advantage = { ... } (rolls it gives advantage on, by their label on the sheet) and
-- skillChoice (a skill to pick, see Sheet/Maneuvers.lua).
-- Resources a subclass brings, in the same form as class `pools` (see Classes.lua).
R.SUBCLASS_POOLS = {
    ["Battle Master"] = {
        { name = "Superiority Dice", short = "ALL", steps = { { 3, 4 }, { 7, 5 }, { 15, 6 } } },
    },
    ["Warrior of Mystic Brews"] = {
        { name = "Refreshing Dip Dice", from = 6, stat = "WIS", halfLevel = true, min = 1 },
    },
    ["Soulknife"] = {
        { name = "Psionic Energy Dice", short = 1, steps = { { 3, 4 }, { 5, 6 }, { 9, 8 }, { 13, 10 }, { 17, 12 } } },
    },
}

-- Size of a Soulknife's Psionic Energy Die.
local function PsionicDie(level)
    return AtLevel(level, { { 3, 6 }, { 5, 8 }, { 11, 10 }, { 17, 12 } })
end

-- The spells a subclass always has prepared. `byLevel` is { {level, "names"}, ... };
-- without it the passive is a general reminder.
local function AlwaysPrepared(what, byLevel)
    if not byLevel then
        return Passive(3, what .. " Spells", "Your subclass gives you extra spells at certain levels. They are always prepared and don't count against the number you can prepare.")
    end
    return Passive(3, what .. " Spells", function(level)
        local known = {}
        for _, step in ipairs(byLevel) do
            if level >= step[1] then known[#known + 1] = step[2] end
        end
        return "Always prepared, and not counted against the number you can prepare: " .. table.concat(known, ", ")
            .. ". They are on your spell list already."
    end, nil, { prepared = byLevel })
end

R.SUBCLASS_FEATURES = {
    ---------------------------------------------------------------------------
    -- Shaman (Barbarian)
    ---------------------------------------------------------------------------
    ["Path of the Elements"] = {
        Passive(3, "Raging Elements", function(level, sheet)
            return ("When you start raging, and as a bonus action while raging, you unleash Icefury, Lava Burst or Lightning Bolt. Saves against them use DC %d (8 + Constitution modifier + proficiency bonus).%s"):format(
                Kit.DC(sheet, "CON"), level >= 14 and " Elemental Overload gives each an extra effect, on a hit or a miss." or "")
        end),
        Ability(3, "Icefury", function(level)
            return "Ice at a creature within 30 feet: a spell attack using Constitution. On a hit, cold damage, and the next fire damage it takes before the end of your next turn adds 1d10."
                .. (level >= 14 and " Hit or miss, it subtracts half the roll from its next damage roll." or "")
        end, function(level) return { Kit.Roll("SPELL", "CON"), Dice(Kit.RageDamage(level), 8) } end),
        Ability(3, "Lava Burst", function(level)
            return "Molten lava at a creature within 30 feet. Dexterity save: fire damage, half on a success. On a failure the next lightning damage it takes before the end of your next turn adds 1d8."
                .. (level >= 14 and " Either way, it and each enemy within 10 feet start burning." or "")
        end, function(level) return { Dice(Kit.RageDamage(level), 4) } end),
        Ability(3, "Lightning Bolt", function(level)
            return "Lightning at a creature within 30 feet. Dexterity save: lightning damage, half on a success. On a failure the next cold damage it takes before the end of your next turn adds 1d6."
                .. (level >= 14 and " Either way, the bolt leaps to a second creature within 30 feet, which saves against the same roll." or "")
        end, function(level) return { Dice(Kit.RageDamage(level), 6) } end),
        Ability(6, "Echo of the Elements", "You know the Elementalism cantrip. Spend a Rage use to cast Daylight, Water Walk or Wind Wall, using Wisdom.", { Spend("Rage") }),
        Passive(10, "Primordial Bond", "While raging you have resistance to cold, fire and lightning damage."),
        Passive(14, "Elemental Overload", "Each of your Raging Elements options gains an extra effect, described on the option."),
    },
    ["Path of the Spiritual Guardian"] = {
        Passive(3, "Spiritual Protectors", "While raging, a creature you hit becomes the target of your spirits. Choose Distract (disadvantage attacking anyone but you), Hinder (add the Slow mastery to the hit) or Strike."),
        Ability(3, "Spirit Strike", "Spiritual Protectors option: extra cold, fire or lightning damage on the creature you hit.", { Dice(1, 4) }),
        Ability(6, "Spirit Shield", "While raging, reaction when another creature within 30 feet takes damage: reduce it by the roll.",
            function(level) return { Dice(Kit.RageDamage(level), 6, "", "OTHER") } end),
        Limited(10, "Consult the Spirits", "Cast Augury or Clairvoyance without a slot or components, using Wisdom. Once per short or long rest.", 1, nil, "ALL"),
        Passive(14, "Spirits' Fury", "Once per turn, when a melee weapon attack roll in your Attack action shows 18 to 20, you can make one extra attack with that weapon."),
    },
    ["Path of the World Tree"] = {
        Ability(3, "Vitality Surge", "When you start raging you gain temporary hit points equal to your level.",
            { Dice(0, 4, "LEVEL", "TEMPHP") }),
        Ability(3, "Life-Giving Force", "At the start of each turn while raging: another creature within 10 feet gains temporary hit points equal to the roll.",
            function(level) return { Dice(Kit.RageDamage(level), 6, "", "OTHER") } end),
        Passive(6, "Branches of the Tree", function(_, sheet)
            return ("While raging, reaction when a creature within 30 feet starts its turn: it makes a Strength save, DC %d, or is teleported next to you, and you can reduce its speed to 0 for the turn."):format(Kit.DC(sheet, "STR"))
        end),
        Passive(10, "Battering Roots", "Your reach is 10 feet greater with heavy or versatile melee weapons, and hits with them can add Push or Topple to the mastery you use."),
        Passive(14, "Travel Along the Tree", "When you start raging, and as a bonus action while raging, you can teleport up to 60 feet. Once per rage this can be 150 feet and carry up to six willing creatures."),
    },

    ---------------------------------------------------------------------------
    -- Warrior (Fighter)
    ---------------------------------------------------------------------------
    ["Battle Master"] = {
        Passive(3, "Combat Superiority", function(level)
            return ("You know %d maneuvers, each an ability on the sheet that spends a Superiority Die. The die is a d%d. All dice come back on a short or long rest. Only one maneuver can be used per attack. Maneuvers are chosen when you level, or under Customize."):format(
                AtLevel(level, R.MANEUVERS_KNOWN), AtLevel(level, R.SUPERIORITY_DIE))
        end),
        Passive(3, "Student of War", "Proficiency with one kind of artisan's tools and in one more skill from the Warrior's list.", nil, { skillChoice = "CLASS" }),
        Limited(7, "Know Your Enemy", "Bonus action: learn the immunities, resistances and vulnerabilities of a creature you can see within 30 feet. Once per long rest; spending a Superiority Die gives the use back.", 1),
        Passive(10, "Improved Combat Superiority", "Your Superiority Die is a d10."),
        Passive(15, "Relentless", "Once per turn you can use a maneuver without spending a die, rolling a d8 in its place. Roll it with /roll 8."),
        Passive(18, "Ultimate Combat Superiority", "Your Superiority Die is a d12."),
    },
    ["Champion"] = {
        Passive(3, "Improved Critical", function(level)
            return ("Your weapon and unarmed attacks score a critical hit on a roll of %s. The sheet applies this to your attacks."):format(level >= 15 and "18, 19 or 20" or "19 or 20")
        end, function(level) return { Bonus("CRIT", level >= 15 and 2 or 1) } end),
        Passive(3, "Remarkable Athlete", "Advantage on initiative rolls and Athletics checks, which the sheet rolls for you. After a critical hit you can move half your speed without provoking opportunity attacks.",
            nil, { advantage = { "initiative", "Athletics" } }),
        Passive(7, "Additional Fighting Style", "You gain another Fighting Style feat."),
        Passive(10, "Heroic Warrior", "In combat, you can give yourself Heroic Inspiration at the start of any turn you begin without it."),
        Passive(18, "Survivor", "Advantage on death saves, with 18 to 20 counting as a 20: the sheet rolls them this way. While Bloodied you regain hit points at the start of each turn: use Heroic Rally.",
            nil, { advantage = { "death save" } }),
        Ability(18, "Heroic Rally", "At the start of your turn, while Bloodied and above 0 hit points: regain 5 + your Constitution modifier.",
            { Dice(0, 4, "CON", "SELFHEAL", 5) }),
    },

    ---------------------------------------------------------------------------
    -- Paladin
    ---------------------------------------------------------------------------
    ["Oath of Devotion"] = {
        AlwaysPrepared("Oath of Devotion", { { 3, "Protection from Evil and Good, Shield of Faith" }, { 5, "Aid, Zone of Truth" }, { 9, "Beacon of Hope, Dispel Magic" }, { 13, "Freedom of Movement, Guardian of Faith" }, { 17, "Commune, Flame Strike" } }),
        Ability(3, "Sacred Weapon", "When you take the Attack action. For 10 minutes one melee weapon you hold adds your Charisma modifier to its attack rolls (at least +1), sheds light, and can deal radiant damage.",
            { Spend("Channel Divinity"), SwitchOn("Sacred Weapon active") }),
        Passive(3, "Sacred Weapon active", "Switch on while Sacred Weapon lasts. Adds your Charisma modifier to attack rolls.", { Bonus("ATTACK", 0, "CHA") }, true),
        Passive(7, "Aura of Devotion", "You and allies in your Aura of Protection can't be charmed."),
        Passive(15, "Smite of Protection", "When you cast Divine Smite, you and allies in your aura have half cover until the start of your next turn."),
        Limited(20, "Holy Nimbus", "Bonus action, for 10 minutes: advantage on saves forced by fiends and undead, enemies that start their turn in your aura take radiant damage equal to your Charisma modifier plus proficiency bonus, and the aura is filled with sunlight. Once per long rest, or again by spending a 5th-level slot.", 1),
    },
    ["Oath of the Holy"] = {
        AlwaysPrepared("Oath of the Holy", { { 3, "Cure Wounds, Healing Word" }, { 5, "Lesser Restoration, Prayer of Healing" }, { 9, "Dispel Magic, Mass Healing Word" }, { 13, "Aura of Life, Death Ward" }, { 17, "Greater Restoration, Mass Cure Wounds" } }),
        Ability(3, "Beacon of Light", "Magic action. For 1 minute, an ally within 60 feet also regains half the hit points whenever you heal someone else with a spell or Lay on Hands.",
            { Spend("Channel Divinity") }),
        Ability(7, "Lightbringer's Aura", "When you heal a Bloodied creature in your aura with a spell or Lay on Hands, it regains this much more.", { Dice(1, 6, "", "HEALING") }),
        Passive(15, "Infusion of Light", "When you cast a spell that deals radiant damage, your Lay on Hands pool regains points equal to the damage rolled, up to its maximum. Raise the bar by hand."),
        Limited(20, "Holy Deliverance", "Bonus action: for 10 minutes your aura is filled with holy power that heals Bloodied allies and bolsters your healing. Once per long rest, or again by spending a 5th-level slot.", 1),
    },
    ["Oath of Vengeance"] = {
        AlwaysPrepared("Oath of Vengeance", { { 3, "Bane, Hunter's Mark" }, { 5, "Hold Person, Misty Step" }, { 9, "Haste, Protection from Energy" }, { 13, "Banishment, Dimension Door" }, { 17, "Hold Monster, Scrying" } }),
        Ability(3, "Vow of Enmity", "When you take the Attack action. For 1 minute you have advantage on attack rolls against one creature within 30 feet. If it drops to 0 hit points you can move the vow to another. Switches the vow on.",
            { Spend("Channel Divinity"), SwitchOn("Vow of Enmity active") }),
        Passive(3, "Vow of Enmity active", "Switch on while you attack the creature under your vow: the sheet rolls your attacks with advantage.", nil, { startsOff = true, advantage = { "attack" } }),
        Passive(7, "Relentless Avenger", "When you hit with an opportunity attack you can reduce the target's speed to 0 for the turn and then move half your speed."),
        Passive(15, "Soul of Vengeance", "When the creature under your Vow of Enmity hits or misses with an attack, you can use your reaction to make a melee attack against it."),
        Limited(20, "Avenging Angel", "Bonus action: for 10 minutes you have a flying speed of 60 feet and an aura that frightens enemies. Once per long rest, or again by spending a 5th-level slot.", 1),
    },

    ---------------------------------------------------------------------------
    -- Hunter (Ranger)
    ---------------------------------------------------------------------------
    ["Beast Master"] = {
        Passive(3, "Primal Companion", "You summon a primal beast of the land, sea or sky. It acts on your turn: it Dodges unless you spend a bonus action, or give up one of your attacks, to command it. If it dies you can bring it back with a spell slot."),
        Passive(7, "Exceptional Training", "When you command your beast with a bonus action it can also Dash, Disengage, Dodge or Help as its own bonus action, and its attacks can deal force damage."),
        Passive(11, "Bestial Fury", "Your beast can strike twice when commanded. The first time each turn it hits the creature under your Hunter's Mark, it deals that spell's extra damage too."),
        Passive(15, "Share Spells", "A spell you cast on yourself can also affect your beast if it is within 30 feet."),
    },
    ["Hunter"] = {
        Passive(3, "Hunter's Lore", "You know the immunities, resistances and vulnerabilities of the creature marked by your Hunter's Mark."),
        Passive(3, "Hunter's Prey", "Choose Colossus Slayer or Horde Breaker; you can swap after a short or long rest. Horde Breaker: once per turn, after attacking a creature, make another attack with the same weapon against a different creature within 5 feet of it."),
        Ability(3, "Colossus Slayer", "Hunter's Prey option. Once per turn, extra damage when your weapon hits a creature that is missing hit points.",
            { Dice(1, 8) }),
        Passive(7, "Defensive Tactics", "Choose one; you can swap after a short or long rest. Escape the Horde: opportunity attacks have disadvantage against you. Multiattack Defense: a creature that hits you has disadvantage on its other attacks against you this turn."),
        Passive(11, "Superior Hunter's Prey", "Once per turn, when you damage the creature under your Hunter's Mark, the spell's extra damage can also hit a different creature within 30 feet of it."),
        Passive(15, "Superior Hunter's Defense", "Reaction when you take damage: resistance to that damage, and any other of the same type, until the end of the turn."),
    },

    ---------------------------------------------------------------------------
    -- Rogue
    ---------------------------------------------------------------------------
    ["Assassin"] = {
        Passive(3, "Assassinate", "Advantage on initiative rolls, which the sheet rolls for you. In the first round you have advantage against creatures that haven't acted, and a Sneak Attack hit then deals extra damage equal to your level.",
            nil, { advantage = { "initiative" } }),
        Passive(3, "Assassin's Tools", "You have a disguise kit and a poisoner's kit, and proficiency with both."),
        Passive(9, "Infiltration Expertise", "You can mimic a person's speech and handwriting after an hour of study, and Steady Aim no longer stops you moving."),
        Passive(13, "Envenom Weapons", "Your Poison Cunning Strike also deals 2d6 poison damage on a failed save, ignoring resistance."),
        Passive(17, "Death Strike", function(_, sheet)
            return ("When you hit with Sneak Attack in the first round, the target makes a Constitution save (DC %d); on a failure the attack's damage is doubled."):format(Kit.DC(sheet, "DEX"))
        end),
    },
    ["Soulknife"] = {
        Passive(3, "Psionic Power", function(level)
            return ("Your Psionic Energy Dice are d%ds. One comes back on a short rest, all on a long rest."):format(PsionicDie(level))
        end),
        Ability(3, "Psychic Blade", "A blade of psychic energy for an attack as part of the Attack action. Finesse and thrown (60 feet); it leaves no mark.",
            { Roll("ATTACK", "DEX"), Dice(1, 6, "DEX") }),
        Ability(3, "Psychic Blade (bonus action)", "After attacking with a Psychic Blade, a second blade as a bonus action if your other hand is free.",
            { Roll("ATTACK", "DEX"), Dice(1, 4, "DEX") }),
        Ability(3, "Psi-Bolstered Knack", "When you fail a check with a skill or tool you are proficient in: add the roll. If it still fails the die isn't spent: give it back on the bar.",
            function(level) return { Spend("Psionic Energy Dice"), Dice(1, PsionicDie(level), "", "OTHER") } end),
        Ability(3, "Psychic Whispers", "Magic action: link minds with creatures you can see, up to your proficiency bonus, for as many hours as the roll. The first use after a long rest costs no die.",
            function(level) return { Spend("Psionic Energy Dice"), Dice(1, PsionicDie(level), "", "OTHER") } end),
        Ability(9, "Homing Strikes", "When a Psychic Blade attack misses: add the roll to the attack roll. The die is spent only if that makes it hit.",
            function(level) return { Spend("Psionic Energy Dice"), Dice(1, PsionicDie(level), "", "OTHER") } end),
        Ability(9, "Psychic Teleportation", "Bonus action: throw a blade and teleport to where it lands, up to 10 feet times the roll.",
            function(level) return { Spend("Psionic Energy Dice"), Dice(1, PsionicDie(level), "", "OTHER") } end),
        Limited(13, "Psychic Veil", "Magic action: become invisible for an hour or until you deal damage or force a save. Once per long rest; after that it costs a Psionic Energy Die, spent on its bar by hand.", 1),
        Limited(17, "Rend Mind", function(_, sheet)
            return ("When your Psychic Blade deals Sneak Attack damage: the target makes a Wisdom save (DC %d) or is stunned for a minute, repeating the save each turn. Once per long rest; after that it costs three Psionic Energy Dice."):format(Kit.DC(sheet, "DEX"))
        end, 1),
    },
    ["Swashbuckler"] = {
        Passive(3, "Fancy Footwork", "A creature you make a melee attack against on your turn can't make opportunity attacks against you for the rest of that turn."),
        Passive(3, "Rakish Audacity", "You add your Charisma modifier to initiative. You can Sneak Attack without advantage when you are within 5 feet of your target, no one else is within 5 feet of you, and you don't have disadvantage.",
            { Bonus("INIT", 0, "CHA") }),
        Passive(9, "Panache", "Two more Cunning Strike options: Goad and Awe."),
        Kit.CunningStrike(9, "Goad", 1, "If it fails, until the end of its next turn the target has disadvantage attacking anyone but you and can't make opportunity attacks against others.", "Wisdom"),
        Kit.CunningStrike(9, "Awe", 3, "Creatures you choose within 30 feet that fail are awed by you until the end of your next turn.", "Wisdom"),
        Passive(13, "Dashing Strikes", "Two more Cunning Strike options: Invigorate and Parrying Stance."),
        Kit.CunningStrike(13, "Invigorate", 2, "A creature you can see within 30 feet adds 1d6 to its attack rolls and saving throws until the end of its next turn."),
        Kit.CunningStrike(13, "Parrying Stance", 2, "Roll 1d6 for a defensive bonus that lasts until the start of your next turn."),
        Passive(17, "Master Duelist", "Right after you use Sneak Attack you can attack the same target again, if you are within 5 feet of it and no one else is within 5 feet of you."),
    },

    ---------------------------------------------------------------------------
    -- Priest (Cleric)
    ---------------------------------------------------------------------------
    ["Discipline Domain"] = {
        AlwaysPrepared("Discipline", { { 3, "Arcane Vigor, Guiding Bolt, Magic Weapon, Shield of Faith" }, { 5, "Prayer of Mending, Protection from Energy" }, { 7, "Guardian of Faith, Stoneskin" }, { 9, "Circle of Power, Destructive Wave" } }),
        Passive(3, "Atonement", "Creatures you heal with a spell of level 1 or higher are blessed until the end of your next turn. When you then damage a creature with a slotted spell, each blessed creature regains hit points equal to that slot's level."),
        Ability(3, "Holy Bolt", function(level)
            return "Bonus action. A ranged spell attack against a creature within 60 feet: radiant damage on a hit, and a creature you choose within 60 feet is healed by the second roll."
                .. (level >= 17 and " You can teleport 30 feet first, and spend a spell slot to hurl as many more bolts as its level: click again for each." or "")
        end, { Spend("Channel Divinity"), Roll("SPELL", "WIS"), Dice(2, 10, "WIS"), Dice(1, 10, "WIS", "HEALING") }),
        Ability(6, "Luminous Barrier", "Bonus action. Each creature blessed by your Atonement gains temporary hit points equal to the amount shown (your level + Wisdom modifier), and resists all damage while it has them.",
            function(level) return { Spend("Channel Divinity"), Dice(0, 4, "WIS", "OTHER", level) } end),
        Passive(17, "Ultimate Penitence", "Holy Bolt lets you teleport up to 30 feet first, and you can spend a spell slot to fire additional bolts."),
    },
    ["Life Domain"] = {
        AlwaysPrepared("Life Domain", { { 3, "Aid, Bless, Cure Wounds, Lesser Restoration" }, { 5, "Mass Healing Word, Revivify" }, { 7, "Aura of Life, Death Ward" }, { 9, "Greater Restoration, Mass Cure Wounds" } }),
        Passive(3, "Disciple of Life", "A slotted spell that heals a creature heals 2 + the slot's level more on the turn you cast it."),
        Ability(3, "Preserve Life", "Magic action. Restore the hit points shown (five times your level), divided among Bloodied creatures within 30 feet, up to half their maximum each.",
            function(level) return { Spend("Channel Divinity"), Dice(0, 4, "", "HEALING", 5 * level) } end),
        Passive(6, "Blessed Healer", "When a slotted spell of yours heals others, you regain 2 + the slot's level yourself."),
        Passive(17, "Supreme Healing", "When you would roll dice to heal with a spell or Channel Divinity, use the highest possible result instead."),
    },
    ["Shadow Domain"] = {
        AlwaysPrepared("Shadow", { { 3, "Crown of Madness, Dissonant Whispers, Mind Spike, Shadow Word: Pain" }, { 5, "Summon Undead, Vampiric Touch" }, { 7, "Evard's Black Tentacles, Psychic Horror" }, { 9, "Dominate Person, Void Eruption" } }),
        Limited(3, "Devouring Plague", "When a creature you can see within 30 feet fails a saving throw: it takes the roll as necrotic damage and you regain the same amount. Uses equal to your Wisdom modifier per long rest.",
            { stat = "WIS" }, { Dice(1, 10, "", "DRAIN") }),
        Ability(3, "Shadowform", "Bonus action. For 1 minute you take a shadowy form: Hide as a bonus action in dim light or darkness, and add 1d6 to one damage roll of a slotted spell that deals psychic or necrotic damage. It ends if you deal radiant damage with a spell.",
            { Spend("Channel Divinity") }),
        Ability(3, "Void Empowerment", "In Shadowform: the extra damage for a slotted spell that deals psychic or necrotic damage.", { Dice(1, 6) }),
        Limited(6, "Dispersion", "Reaction when an attack hits you: until the end of your next turn you resist all damage, fly 40 feet, and can't act. Afterwards you can spend up to half your Hit Dice to heal. Once per short or long rest.", 1, nil, "ALL"),
        Passive(17, "Vampiric Embrace", "While in Shadowform, whenever you roll the d6 of extra spell damage, a creature within 30 feet regains that many hit points."),
    },

    ---------------------------------------------------------------------------
    -- Druid
    ---------------------------------------------------------------------------
    ["Circle of the Land"] = {
        Kit.Choice(3, "Circle of the Land Spells", "After each long rest you choose a kind of land and have its spells prepared for your level.", {
            Kit.Option("Arid", "Level 3: Blur, Burning Hands, Fire Bolt. Level 5: Fireball. Level 7: Blight. Level 9: Wall of Stone. Nature's Ward: resistance to fire."),
            Kit.Option("Polar", "Level 3: Fog Cloud, Hold Person, Ray of Frost. Level 5: Sleet Storm. Level 7: Ice Storm. Level 9: Cone of Cold. Nature's Ward: resistance to cold."),
            Kit.Option("Temperate", "Level 3: Misty Step, Shocking Grasp, Sleep. Level 5: Lightning Bolt. Level 7: Freedom of Movement. Level 9: Tree Stride. Nature's Ward: resistance to lightning."),
            Kit.Option("Tropical", "Level 3: Acid Splash, Ray of Sickness, Web. Level 5: Stinking Cloud. Level 7: Polymorph. Level 9: Insect Plague. Nature's Ward: resistance to poison."),
        }),
        Ability(3, "Land's Aid", function(_, sheet)
            return ("Magic action, a point within 60 feet. Creatures you choose in a 10-foot sphere take the first roll as necrotic damage, half on a successful Constitution save, DC %d. One creature you choose there is healed by the second roll."):format(Kit.DC(sheet, "WIS"))
        end, function(level)
            local dice = AtLevel(level, { { 3, 2 }, { 10, 3 }, { 14, 4 } })
            return { Spend("Wild Shape"), Dice(dice, 6), Dice(dice, 6, "", "HEALING") }
        end),
        Limited(6, "Natural Recovery", "Once per long rest, cast one of your Circle spells without a slot. Also once per long rest, on a short rest, recover spell slots with a combined level up to half your level (none above 5th); restore those by hand.", 1),
        Passive(10, "Nature's Ward", "You can't be poisoned, and you resist the damage type of your current land (named on your Circle of the Land Spells)."),
        Ability(14, "Nature's Sanctuary", "Magic action. Spectral trees fill a 15-foot cube within 120 feet for a minute: you and allies have half cover there, and allies gain your Nature's Ward resistance. A bonus action moves it up to 60 feet.",
            { Spend("Wild Shape") }),
    },
    ["Circle of the Moon"] = {
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
    },
    ["Circle of the Stars"] = {
        Limited(3, "Star Map", "A star chart that serves as your spellcasting focus. With it you have Guidance and Guiding Bolt prepared. Clicking casts Guiding Bolt without a slot: uses equal to your Wisdom modifier per long rest.",
            { stat = "WIS" }, { Roll("SPELL", "WIS"), Dice(4, 6) }),
        Ability(3, "Starry Form", "Bonus action. For 10 minutes you become starry in place of a beast form, and choose a constellation: Archer, Chalice or Dragon. From level 10 you can change it at the start of each turn.",
            { Spend("Wild Shape") }),
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
        Passive(6, "Physician's Touch", "Hand of Harm can also poison its target until the end of your next turn. Hand of Healing can also end one of blinded, deafened, paralyzed, poisoned or stunned."),
        Limited(11, "Flurry of Healing and Harm", "With Flurry of Blows, each strike can be a free Hand of Healing, and one damaging strike can use Hand of Harm without spending focus. Uses equal to your Wisdom modifier per long rest.",
            { stat = "WIS" }),
        Limited(17, "Hand of Ultimate Mercy", "Magic action: touch a creature that died within a day. It returns to life with hit points equal to the roll, and several conditions removed. Once per long rest.",
            1, { Spend("Focus Points", 5), Dice(4, 10, "WIS", "HEALING") }),
    },
    ["Warrior of Mystic Brews"] = {
        Passive(3, "Bonus Proficiencies", "Proficiency in Performance and with brewer's supplies.", nil, { skills = { "Performance" } }),
        Passive(3, "Drunken Technique", "When you spend focus on Patient Defense, your speed rises by 10 feet for the turn and you can make one unarmed strike."),
        Passive(6, "Mystic Brew", function(level)
            return ("After a short or long rest with brewer's supplies you make one magical beverage, which only you can drink (1 minute). Its benefit lasts an hour, or 8 hours if you spend 1 Focus Point, or until you drink another. Brews: Cinnamon Dragon, Heavenly Spirit, Refreshing Dip%s. Switch on the brew you drank."):format(
                level >= 11 and ", Blue Lightning, Drunkard's Luck, Stumbling Monk" or "")
        end),
        Ability(6, "Cinnamon Dragon", function(_, sheet)
            return ("Brew. Magic action: toxic flames in a 30-foot cone. Fire damage and poisoned until the end of its next turn; half damage only on a successful Dexterity save, DC %d."):format(Kit.DC(sheet, "WIS"))
        end, function(level) return { Dice(4, Kit.MartialDie(level)) } end),
        Passive(6, "Heavenly Spirit", "Brew. Resistance to two of cold, necrotic, psychic and radiant damage, your choice.", nil, true),
        Ability(6, "Refreshing Dip", "Brew. Whenever you regain hit points, spend a die from the pool to regain that much more.",
            function(level) return { Spend("Refreshing Dip Dice"), Dice(1, Kit.MartialDie(level), "", "SELFHEAL") } end),
        Passive(6, "Tipsy Sway", "You can stand up from prone for 5 feet of movement."),
        Ability(6, "Redirect Attack", "Reaction when an enemy misses you with a melee attack: it hits another creature of your choice within 5 feet of you, other than the attacker.",
            { Spend("Focus Points") }),
        Passive(11, "Blue Lightning", "Brew. Whenever you take a reaction that isn't an opportunity attack or a spell, you can make one unarmed strike as part of it.", nil, true),
        Passive(11, "Drunkard's Luck", "Brew. You gain Heroic Inspiration, and can give it to yourself whenever you make a check or save without it.", nil, true),
        Passive(11, "Stumbling Monk", "Brew. After any bonus action other than Patient Defense you can also use Patient Defense.", nil, true),
        Passive(17, "Intoxicated Frenzy", function(_, sheet)
            return ("Right after Patient Defense you can move up to your speed, making an unarmed strike against each creature you pass (once each). A creature hit falls prone unless it passes a Dexterity save, DC %d."):format(Kit.DC(sheet, "WIS"))
        end),
        Passive(17, "Master Brewer", "One beverage can carry the effects of two different brews."),
    },
    ["Warrior of the Open Hand"] = {
        Passive(3, "Open Hand Technique", function(_, sheet)
            return ("When a Flurry of Blows strike hits you can add one effect: Addle (no opportunity attacks until its next turn), Push (Strength save or pushed 15 feet) or Topple (Dexterity save or prone). Save DC %d."):format(Kit.DC(sheet, "WIS"))
        end),
        Limited(6, "Wholeness of Body", "Bonus action: heal yourself by the roll. Uses equal to your Wisdom modifier per long rest.",
            { stat = "WIS" }, function(level) return { Dice(1, Kit.MartialDie(level), "WIS", "SELFHEAL") } end),
        Passive(11, "Fleet Step", "After any bonus action other than Step of the Wind you can also use Step of the Wind."),
        Ability(17, "Quivering Palm", function(_, sheet)
            return ("When you hit with an unarmed strike: set up lethal vibrations that last a number of days equal to your level. Later, as an action or in place of an attack, end them: the target takes the roll as force damage, half on a successful Constitution save, DC %d. Click once to set up (spends the focus); roll the damage when you end them."):format(Kit.DC(sheet, "WIS"))
        end, { Spend("Focus Points", 4), Dice(10, 12) }),
    },

    ---------------------------------------------------------------------------
    -- Evoker (Sorcerer)
    ---------------------------------------------------------------------------
    ["Draconic Sorcery"] = {
        Passive(3, "Draconic Resilience", "Your maximum hit points increase by 1 for every Sorcerer level.", { Bonus("HP", 0, "LEVEL") }),
        Passive(3, "Draconic Scales", "Without armor your AC is 10 + Dexterity + Charisma modifiers. Switch this off while you wear armor.", { Bonus("AC", 0, "CHA") }),
        Passive(3, "Evoker Spells", "You always have extra spells prepared at certain levels. An Evoker takes the spells of its specialization from the Evoker list in place of the usual draconic ones. Add them under Customize, Spells, ticked as not counting."),
        Kit.Choice(6, "Elemental Affinity", "The damage type your draconic magic is attuned to. You resist it, and add your Charisma modifier to one damage roll of a spell that deals it.", {
            Kit.Option("Acid", "You resist acid damage, and add your Charisma modifier to one damage roll of a spell that deals acid damage."),
            Kit.Option("Cold", "You resist cold damage, and add your Charisma modifier to one damage roll of a spell that deals cold damage."),
            Kit.Option("Fire", "You resist fire damage, and add your Charisma modifier to one damage roll of a spell that deals fire damage."),
            Kit.Option("Lightning", "You resist lightning damage, and add your Charisma modifier to one damage roll of a spell that deals lightning damage."),
            Kit.Option("Poison", "You resist poison damage, and add your Charisma modifier to one damage roll of a spell that deals poison damage."),
        }),
        Limited(14, "Dragon Wings", "Bonus action: wings give you a flying speed of 60 feet for an hour. Once per long rest; after that it costs 3 Sorcery Points, spent on their bar by hand.", 1),
        Limited(18, "Dragon Companion", "You can cast Summon Dragon without its material component and make it last a minute without concentration. Once per long rest you can cast it without a slot.", 1),
    },

    ---------------------------------------------------------------------------
    -- Warlock
    ---------------------------------------------------------------------------
    ["Fiend Patron"] = {
        AlwaysPrepared("Fiend", { { 3, "Burning Hands, Command, Scorching Ray, Suggestion" }, { 5, "Fireball, Stinking Cloud" }, { 7, "Fire Shield, Wall of Fire" }, { 9, "Geas, Insect Plague" } }),
        Ability(3, "Dark One's Blessing", "When you reduce an enemy to 0 hit points, or one drops within 10 feet of you: you gain temporary hit points equal to your Charisma modifier plus your level.",
            function(level) return { Dice(0, 4, "CHA", "TEMPHP", level) } end),
        Limited(6, "Dark One's Own Luck", "Add the roll to an ability check or saving throw after seeing the d20, once per roll. Uses equal to your Charisma modifier per long rest.",
            { stat = "CHA" }, { Dice(1, 10, "", "OTHER") }),
        Passive(10, "Fiendish Resilience", "After each short or long rest choose a damage type other than force. You resist it until you choose another."),
        Limited(14, "Hurl Through Hell", function(_, sheet)
            return ("Once per turn when you hit: the target makes a Charisma save, DC %d, or vanishes through the Lower Planes, taking the roll as psychic damage (unless it is a fiend) and returning incapacitated at the end of your next turn. Once per long rest, or again by spending a pact slot."):format(Kit.DC(sheet, "CHA"))
        end, 1, { Dice(8, 10) }),
    },
    ["Great Old One Patron"] = {
        AlwaysPrepared("Great Old One", { { 3, "Detect Thoughts, Dissonant Whispers, Phantasmal Force, Tasha's Hideous Laughter" }, { 5, "Clairvoyance, Hunger of Hadar" }, { 7, "Confusion, Summon Aberration" }, { 9, "Modify Memory, Telekinesis" } }),
        Passive(3, "Awakened Mind", function(level)
            return ("Bonus action: link minds with a creature you can see within 30 feet and speak telepathically for %d minutes, over a number of miles equal to your Charisma modifier."):format(level)
        end),
        Passive(3, "Psychic Spells", "You can change the damage of your Warlock spells to psychic, and cast enchantments and illusions without words or gestures."),
        Limited(6, "Clairvoyant Combatant", function(_, sheet)
            return ("When you link minds with Awakened Mind: the creature makes a Wisdom save, DC %d. On a failure it has disadvantage attacking you and you have advantage attacking it while the link lasts. Once per short or long rest, or again by spending a pact slot."):format(Kit.DC(sheet, "CHA"))
        end, 1, nil, "ALL"),
        Passive(10, "Eldritch Hex", "You always have Hex prepared, and its target also has disadvantage on saves with the chosen ability."),
        Passive(10, "Thought Shield", "Your thoughts can't be read, you resist psychic damage, and creatures that deal it to you take the same amount."),
        Passive(14, "Create Thrall", "Summon Aberration can last a minute without concentration; the creature then gains temporary hit points equal to your level plus Charisma modifier and deals your Hex's extra damage once per turn."),
    },

    ---------------------------------------------------------------------------
    -- Mage (Wizard)
    ---------------------------------------------------------------------------
    ["Evoker"] = {
        Passive(3, "Evocation Savant", "Two free evocation spells of 2nd level or lower in your spellbook now, and another each time you gain a new level of spell slots."),
        Passive(3, "Potent Cantrip", "A damaging cantrip still deals half damage when it misses or the target saves, with no other effect."),
        Passive(6, "Sculpt Spells", "When you cast an evocation spell you can protect creatures you can see, one more than the spell's level: they pass the save and take no damage."),
        Passive(10, "Empowered Evocation", "Add your Intelligence modifier to one damage roll of any evocation spell you cast."),
        Ability(14, "Overchannel", "Deal maximum damage with a damaging spell of level 1 to 5 on the turn you cast it. The first use each long rest is free. After that, roll this for each level of the slot and take it as necrotic damage; it grows by 1d12 per level with each further use.",
            { Dice(2, 12) }),
    },
}
