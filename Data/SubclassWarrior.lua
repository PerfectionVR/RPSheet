-- Subclass features of the Warrior (Fighter). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local F = R.SUBCLASS_FEATURES

F["Battle Master"] = {
    Passive(3, "Combat Superiority", function(level)
        return ("You know %d maneuvers, each an ability on the sheet that spends a Superiority Die. The die is a d%d. All dice come back on a short or long rest. Only one maneuver can be used per attack. Maneuvers are chosen when you level, or under Customize."):format(
            AtLevel(level, R.MANEUVERS_KNOWN), AtLevel(level, R.SUPERIORITY_DIE))
    end),
    Passive(3, "Student of War", "Proficiency with one kind of artisan's tools and in one more skill from the Warrior's list. Both are chosen when you level.", nil, { skillChoice = "CLASS" }),
    Limited(7, "Know Your Enemy", "Bonus action: learn the immunities, resistances and vulnerabilities of a creature you can see within 30 feet. Once per long rest; Know Your Enemy: restore gives the use back for a Superiority Die.", 1),
    Ability(7, "Know Your Enemy: restore", "No action needed: spend a Superiority Die to use Know Your Enemy again before a long rest.",
        { Spend("Superiority Dice"), { type = "GAIN", resource = "Know Your Enemy", amount = 1 } }),
    Passive(10, "Improved Combat Superiority", "Your Superiority Die is a d10."),
    Ability(15, "Relentless", "Once per turn you can use a maneuver without spending a Superiority Die: this rolls the d8 that takes its place. Use it in place of clicking the maneuver, and add what the maneuver adds.",
        { Dice(1, 8, "", "OTHER") }),
    Passive(18, "Ultimate Combat Superiority", "Your Superiority Die is a d12."),
}
F["Champion"] = {
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
}
