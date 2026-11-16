-- Subclass features of the Rogue. See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local F = R.SUBCLASS_FEATURES

-- Size of a Soulknife's Psionic Energy Die.
local function PsionicDie(level)
    return AtLevel(level, { { 3, 6 }, { 5, 8 }, { 11, 10 }, { 17, 12 } })
end

F["Assassin"] = {
    Passive(3, "Assassinate", "Advantage on initiative rolls, which the sheet rolls for you. In the first round you have advantage against creatures that haven't acted, and a Sneak Attack hit then deals extra damage equal to your level: use Assassinate: first round.",
        nil, { advantage = { "initiative" } }),
    Ability(3, "Assassinate: first round", "When your Sneak Attack hits in the first round of a combat: extra damage of the weapon's type, equal to your level.",
        { Dice(0, 4, "LEVEL", "DAMAGE") }),
    Passive(3, "Assassin's Tools", "You have a disguise kit and a poisoner's kit, and proficiency with both. The sheet gives the proficiencies.",
        nil, { tools = { "Disguise Kit", "Poisoner's Kit" } }),
    Passive(9, "Infiltration Expertise", "You can mimic a person's speech and handwriting after an hour of study, and Steady Aim no longer stops you moving."),
    Ability(13, "Envenom Weapons", "Your Poison Cunning Strike also deals this poison damage each time the target fails its save, the repeated ones too. It ignores resistance.",
        { Dice(2, 6) }),
    Passive(17, "Death Strike", function(_, sheet)
        return ("When you hit with Sneak Attack in the first round, the target makes a Constitution save (DC %d); on a failure the attack's damage is doubled."):format(Kit.DC(sheet, "DEX"))
    end),
}
F["Soulknife"] = {
    Passive(3, "Psionic Power", function(level)
        return ("Your Psionic Energy Dice are d%ds. One comes back on a short rest, all on a long rest."):format(PsionicDie(level))
    end),
    Ability(3, "Psychic Blade", "A blade of psychic energy for an attack as part of the Attack action. Finesse and thrown (60 feet); it leaves no mark.",
        { Roll("ATTACK", "DEX"), Dice(1, 6, "DEX") }),
    Ability(3, "Psychic Blade (bonus action)", "After attacking with a Psychic Blade, a second blade as a bonus action if your other hand is free.",
        { Roll("ATTACK", "DEX"), Dice(1, 4, "DEX") }),
    Ability(3, "Psi-Bolstered Knack", "When you fail a check with a skill or tool you are proficient in: add the roll. If it still fails the die isn't spent: right-click this ability, or click the link the sheet shows you after the roll, and you keep it.",
        function(level) return { Kit.Refundable(Spend("Psionic Energy Dice"), "the check still failed"), Dice(1, PsionicDie(level), "", "OTHER") } end),
    Ability(3, "Psychic Whispers", "Magic action: link minds with creatures you can see, up to your proficiency bonus, for as many hours as the roll. The first use after a long rest costs no die; the sheet keeps track of that.",
        function(level) return { Kit.FirstFree(Spend("Psionic Energy Dice")), Dice(1, PsionicDie(level), "", "OTHER") } end),
    Ability(9, "Homing Strikes", "When a Psychic Blade attack misses: add the roll to the attack roll. The die is spent only if that makes it hit: when it still misses, right-click this ability, or click the link the sheet shows you after the roll, and you keep it.",
        function(level) return { Kit.Refundable(Spend("Psionic Energy Dice"), "the attack still missed"), Dice(1, PsionicDie(level), "", "OTHER") } end),
    Ability(9, "Psychic Teleportation", "Bonus action: throw a blade and teleport to where it lands, up to 10 feet times the roll.",
        function(level) return { Spend("Psionic Energy Dice"), Dice(1, PsionicDie(level), "", "OTHER") } end),
    Limited(13, "Psychic Veil", "Magic action: become invisible for an hour or until you deal damage or force a save. Once per long rest; after that each use costs a Psionic Energy Die, which the sheet spends.", 1, nil, nil, { "Psionic Energy Dice", 1 }),
    Limited(17, "Rend Mind", function(_, sheet)
        return ("When your Psychic Blade deals Sneak Attack damage: the target makes a Wisdom save (DC %d) or is stunned for a minute, repeating the save each turn. Once per long rest; after that each use costs three Psionic Energy Dice, which the sheet spends."):format(Kit.DC(sheet, "DEX"))
    end, 1, nil, nil, { "Psionic Energy Dice", 3 }),
}
F["Swashbuckler"] = {
    Passive(3, "Fancy Footwork", "A creature you make a melee attack against on your turn can't make opportunity attacks against you for the rest of that turn."),
    Passive(3, "Rakish Audacity", "You add your Charisma modifier to initiative. You can Sneak Attack without advantage when you are within 5 feet of your target, no one else is within 5 feet of you, and you don't have disadvantage.",
        { Bonus("INIT", 0, "CHA") }),
    Passive(9, "Panache", "Two more Cunning Strike options: Goad and Awe."),
    Kit.CunningStrike(9, "Goad", 1, "If it fails, until the end of its next turn the target has disadvantage attacking anyone but you and can't make opportunity attacks against others.", "Wisdom"),
    Kit.CunningStrike(9, "Awe", 3, "Creatures you choose within 30 feet that fail are charmed by you until the end of your next turn.", "Wisdom"),
    Passive(13, "Dashing Strikes", "Two more Cunning Strike options: Invigorate and Parrying Stance."),
    Kit.CunningStrike(13, "Invigorate", 2, "A creature you can see within 30 feet adds 1d6 to its attack rolls and saving throws until the end of its next turn; roll that die with Dashing Strikes: bonus die."),
    Kit.CunningStrike(13, "Parrying Stance", 2, "Add 1d6 to your Armor Class until the start of your next turn; roll it with Dashing Strikes: bonus die."),
    Ability(13, "Dashing Strikes: bonus die", "The d6 that Invigorate adds to attack rolls and saves, or Parrying Stance to your Armor Class.", { Dice(1, 6, "", "OTHER") }),
    Passive(17, "Master Duelist", "Right after you use Sneak Attack you can attack the same target again, if you are within 5 feet of it and no one else is within 5 feet of you."),
}
