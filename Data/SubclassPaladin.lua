-- Subclass features of the Paladin. See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local AlwaysPrepared = ns.SubclassKit.AlwaysPrepared
local F = R.SUBCLASS_FEATURES

F["Oath of Devotion"] = {
    AlwaysPrepared("Oath of Devotion", { { 3, "Protection from Evil and Good, Shield of Faith" }, { 5, "Aid, Zone of Truth" }, { 9, "Beacon of Hope, Dispel Magic" }, { 13, "Freedom of Movement, Guardian of Faith" }, { 17, "Commune, Flame Strike" } }),
    Ability(3, "Sacred Weapon", "When you take the Attack action. For 10 minutes one melee weapon you hold adds your Charisma modifier to its attack rolls (at least +1), sheds light, and can deal radiant damage.",
        { Spend("Channel Divinity"), SwitchOn("Sacred Weapon active") }),
    Passive(3, "Sacred Weapon active", "Switch on while Sacred Weapon lasts. Adds your Charisma modifier, at least +1, to attack rolls; it is meant for the one weapon you imbued.",
        function(_, sheet) return { Bonus("ATTACK", math.max(1, Kit.Mod(sheet, "CHA"))) } end, true),
    Passive(7, "Aura of Devotion", "You and allies in your Aura of Protection can't be charmed.", nil, { conditionImmune = { "Charmed" } }),
    Passive(15, "Smite of Protection", "When you cast Divine Smite, you and allies in your aura have half cover until the start of your next turn."),
    Limited(20, "Holy Nimbus", "Bonus action, for 10 minutes: advantage on saves forced by fiends and undead, enemies that start their turn in your aura take radiant damage equal to your Charisma modifier plus proficiency bonus, and the aura is filled with sunlight. Once per long rest, or again by spending a 5th-level slot.", 1),
}
F["Oath of the Holy"] = {
    AlwaysPrepared("Oath of the Holy", { { 3, "Cure Wounds, Healing Word" }, { 5, "Lesser Restoration, Prayer of Healing" }, { 9, "Dispel Magic, Mass Healing Word" }, { 13, "Aura of Life, Death Ward" }, { 17, "Greater Restoration, Mass Cure Wounds" } }),
    Ability(3, "Beacon of Light", "Magic action. For 1 minute, an ally within 60 feet also regains half the hit points whenever you heal someone else with a spell or Lay on Hands.",
        { Spend("Channel Divinity") }),
    Ability(7, "Lightbringer's Aura", "When you heal a Bloodied creature in your aura with a spell or Lay on Hands, it regains this much more.", { Dice(1, 6, "", "HEALING") }),
    Passive(15, "Infusion of Light", "When you cast a spell that deals radiant damage, your Lay on Hands pool regains points equal to the damage rolled, up to its maximum. Raise the bar by hand."),
    Limited(20, "Holy Deliverance", function(level, sheet)
        return ("Bonus action: for 10 minutes your aura is filled with sunlight, and a Bloodied ally that starts its turn in it regains %d hit points (Charisma modifier plus proficiency bonus). Once per long rest, or again by spending a 5th-level slot."):format(
            math.max(0, Kit.Mod(sheet, "CHA") + Kit.Prof(level)))
    end, 1),
}
F["Oath of Vengeance"] = {
    AlwaysPrepared("Oath of Vengeance", { { 3, "Bane, Hunter's Mark" }, { 5, "Hold Person, Misty Step" }, { 9, "Haste, Protection from Energy" }, { 13, "Banishment, Dimension Door" }, { 17, "Hold Monster, Scrying" } }),
    Ability(3, "Vow of Enmity", "When you take the Attack action. For 1 minute you have advantage on attack rolls against one creature within 30 feet. If it drops to 0 hit points you can move the vow to another. Switches the vow on.",
        { Spend("Channel Divinity"), SwitchOn("Vow of Enmity active") }),
    Passive(3, "Vow of Enmity active", "Switch on while you attack the creature under your vow: the sheet rolls your attacks with advantage.", nil, { startsOff = true, advantage = { "attack" } }),
    Passive(7, "Relentless Avenger", "When you hit with an opportunity attack you can reduce the target's speed to 0 for the turn and then move half your speed."),
    Passive(15, "Soul of Vengeance", "When the creature under your Vow of Enmity hits or misses with an attack, you can use your reaction to make a melee attack against it."),
    Limited(20, "Avenging Angel", function(_, sheet)
        return ("Bonus action: for 10 minutes you have a flying speed of 60 feet. An enemy that starts its turn in your aura makes a Wisdom save, DC %d, or is frightened of you for a minute, and attacks against it have advantage. Once per long rest, or again by spending a 5th-level slot."):format(Kit.DC(sheet, "CHA"))
    end, 1),
}
