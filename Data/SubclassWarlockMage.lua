-- Subclass features of the Warlock and the Mage (Wizard). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local AlwaysPrepared = ns.SubclassKit.AlwaysPrepared
local F = R.SUBCLASS_FEATURES

-- A Fiend warlock resists one damage type of their choice, never force.
local RESILIENCE = {}
for _, name in ipairs(R.AllDamage("force")) do
    RESILIENCE[#RESILIENCE + 1] = Kit.Option(name:sub(1, 1):upper() .. name:sub(2),
        ("You resist %s damage. You can choose another type after each short or long rest."):format(name), { resist = { name } })
end

F["Fiend Patron"] = {
    AlwaysPrepared("Fiend", { { 3, "Burning Hands, Command, Scorching Ray, Suggestion" }, { 5, "Fireball, Stinking Cloud" }, { 7, "Fire Shield, Wall of Fire" }, { 9, "Geas, Insect Plague" } }),
    Ability(3, "Dark One's Blessing", "When you reduce an enemy to 0 hit points, or one drops within 10 feet of you: you gain temporary hit points equal to your Charisma modifier plus your level.",
        function(level) return { Dice(0, 4, "CHA", "TEMPHP", level) } end),
    Limited(6, "Dark One's Own Luck", "Add the roll to an ability check or saving throw after seeing the d20, once per roll. Uses equal to your Charisma modifier per long rest.",
        { stat = "CHA" }, { Dice(1, 10, "", "OTHER") }),
    Kit.Choice(10, "Fiendish Resilience", "After each short or long rest choose a damage type other than force. You resist it until you choose another.", RESILIENCE),
    Limited(14, "Hurl Through Hell", function(_, sheet)
        return ("Once per turn when you hit: the target makes a Charisma save, DC %d, or vanishes through the Lower Planes, taking the roll as psychic damage (unless it is a fiend) and returning incapacitated at the end of your next turn. Once per long rest, or again by spending a pact slot."):format(Kit.DC(sheet, "CHA"))
    end, 1, { Dice(8, 10) }),
}
F["Great Old One Patron"] = {
    AlwaysPrepared("Great Old One", { { 3, "Detect Thoughts, Dissonant Whispers, Phantasmal Force, Tasha's Hideous Laughter" }, { 5, "Clairvoyance, Hunger of Hadar" }, { 7, "Confusion, Summon Aberration" }, { 9, "Modify Memory, Telekinesis" } }),
    Passive(3, "Awakened Mind", function(level)
        return ("Bonus action: link minds with a creature you can see within 30 feet and speak telepathically for %d minutes, over a number of miles equal to your Charisma modifier."):format(level)
    end),
    Passive(3, "Psychic Spells", "You can change the damage of your Warlock spells to psychic, and cast enchantments and illusions without words or gestures."),
    Limited(6, "Clairvoyant Combatant", function(_, sheet)
        return ("When you link minds with Awakened Mind: the creature makes a Wisdom save, DC %d. On a failure it has disadvantage attacking you and you have advantage attacking it while the link lasts. Once per short or long rest, or again by spending a pact slot."):format(Kit.DC(sheet, "CHA"))
    end, 1, nil, "ALL"),
    Passive(10, "Eldritch Hex", "You always have Hex prepared, and its target also has disadvantage on saves with the chosen ability."),
    Passive(10, "Thought Shield", "Your thoughts can't be read, you resist psychic damage, and creatures that deal it to you take the same amount.", nil, { resist = { "psychic" } }),
    Passive(14, "Create Thrall", "Summon Aberration can last a minute without concentration; the creature then gains temporary hit points equal to your level plus Charisma modifier and deals your Hex's extra damage once per turn."),
}

-- Mage (Wizard)
F["Evoker"] = {
    Passive(3, "Evocation Savant", "Two free evocation spells of 2nd level or lower in your spellbook now, and another each time you gain a new level of spell slots."),
    Passive(3, "Potent Cantrip", "A damaging cantrip still deals half damage when it misses or the target saves, with no other effect."),
    Passive(6, "Sculpt Spells", "When you cast an evocation spell you can protect creatures you can see, one more than the spell's level: they pass the save and take no damage."),
    Passive(10, "Empowered Evocation", "Add your Intelligence modifier to one damage roll of any evocation spell you cast."),
    Limited(14, "Overchannel", "Deal maximum damage with a damaging spell of level 1 to 5 on the turn you cast it. The first use after a long rest costs nothing. Each later use rolls necrotic damage that you take and that ignores resistance and immunity: 2d12 for each level of the slot, and 1d12 more per level with every further use. Set the slot's level at \"Cast at\" before you click, and lower your HP by the roll. The bar counts the uses.",
        10, { Kit.Strain(Kit.PerSlot(Dice(2, 12)), "Overchannel") }),
}
