-- Subclass features of the Shaman (Barbarian). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local F = R.SUBCLASS_FEATURES

F["Path of the Elements"] = {
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
    Passive(10, "Primordial Bond", "While raging you have resistance to cold, fire and lightning damage.", nil,
        { resist = { "cold", "fire", "lightning" }, whileOn = "Raging" }),
    Passive(14, "Elemental Overload", "Each of your Raging Elements options gains an extra effect, described on the option."),
}
F["Path of the Spiritual Guardian"] = {
    Passive(3, "Spiritual Protectors", "While raging, a creature you hit becomes the target of your spirits. Choose Distract (disadvantage attacking anyone but you), Hinder (add the Slow mastery to the hit) or Strike."),
    Ability(3, "Spirit Strike", "Spiritual Protectors option: extra cold, fire or lightning damage on the creature you hit.", { Dice(1, 4) }),
    Ability(6, "Spirit Shield", "While raging, reaction when another creature within 30 feet takes damage: reduce it by the roll.",
        function(level) return { Dice(Kit.RageDamage(level), 6, "", "OTHER") } end),
    Limited(10, "Consult the Spirits", "Cast Augury or Clairvoyance without a slot or components, using Wisdom. Once per short or long rest.", 1, nil, "ALL"),
    Passive(14, "Spirits' Fury", "Once per turn, when a melee weapon attack roll in your Attack action shows 18 to 20, you can make one extra attack with that weapon."),
}
F["Path of the World Tree"] = {
    Ability(3, "Vitality Surge", "When you start raging you gain temporary hit points equal to your level.",
        { Dice(0, 4, "LEVEL", "TEMPHP") }),
    Ability(3, "Life-Giving Force", "At the start of each turn while raging: another creature within 10 feet gains temporary hit points equal to the roll.",
        function(level) return { Dice(Kit.RageDamage(level), 6, "", "OTHER") } end),
    Passive(6, "Branches of the Tree", function(_, sheet)
        return ("While raging, reaction when a creature within 30 feet starts its turn: it makes a Strength save, DC %d, or is teleported next to you, and you can reduce its speed to 0 for the turn."):format(Kit.DC(sheet, "STR"))
    end),
    Passive(10, "Battering Roots", "Your reach is 10 feet greater with heavy or versatile melee weapons, and hits with them can add Push or Topple to the mastery you use."),
    Passive(14, "Travel Along the Tree", "When you start raging, and as a bonus action while raging, you can teleport up to 60 feet. Once per rage this can be 150 feet and carry up to six willing creatures."),
}
