-- Conditions a character can be under, with short reminders in our own words.
-- "Concentrating" isn't a condition in the rules, but it is tracked the same way.
local _, ns = ...
local R = ns.Rules

R.CONDITIONS = {
    { name = "Blinded", desc = "You can't see and fail checks that need sight. Your attacks have disadvantage; attacks against you have advantage." },
    { name = "Charmed", desc = "You can't attack the charmer or target them with harmful effects, and they have advantage on social checks with you." },
    { name = "Concentrating", desc = "You are holding a spell. Taking damage forces a Constitution save (DC 10, or half the damage if higher) to keep it. Casting another concentration spell ends it, and so does dropping to 0 hit points or being incapacitated." },
    { name = "Deafened", desc = "You can't hear and fail checks that need hearing." },
    { name = "Frightened", desc = "Disadvantage on checks and attacks while the source of your fear is in sight, and you can't willingly move closer to it." },
    { name = "Grappled", desc = "Your speed is 0. You have disadvantage on attacks against anyone but the grappler, who can drag you along." },
    { name = "Incapacitated", desc = "You can't take actions, bonus actions or reactions, can't speak, and lose concentration. Disadvantage on initiative." },
    { name = "Invisible", desc = "You can't be seen. Advantage on initiative and on your attacks; attacks against you have disadvantage." },
    { name = "Paralyzed", desc = "Incapacitated, speed 0. You fail Strength and Dexterity saves. Attacks against you have advantage, and hits from within 5 feet are critical." },
    { name = "Petrified", desc = "Turned to stone: incapacitated, speed 0, unaware. You fail Strength and Dexterity saves, resist all damage, and attacks against you have advantage." },
    { name = "Poisoned", desc = "Disadvantage on attack rolls and ability checks." },
    { name = "Prone", desc = "You can only crawl. Disadvantage on your attacks. Attacks from within 5 feet have advantage against you; others have disadvantage." },
    { name = "Restrained", desc = "Speed 0. Disadvantage on your attacks and Dexterity saves; attacks against you have advantage." },
    { name = "Stunned", desc = "Incapacitated. You fail Strength and Dexterity saves, and attacks against you have advantage." },
    { name = "Unconscious", desc = "Incapacitated and prone, unaware, speed 0. You drop what you hold and fail Strength and Dexterity saves. Attacks against you have advantage, and hits from within 5 feet are critical." },
}

-- Exhaustion is counted in levels. Each one takes 2 from every d20 roll and 5 feet
-- from speed; the sixth kills. A long rest removes one level.
R.MAX_EXHAUSTION = 6
R.EXHAUSTION_D20 = 2
R.EXHAUSTION_SPEED = 5
R.CONDITION_HELP = "The sheet applies what a condition does to your own rolls: disadvantage on attacks and checks, saves that fail, a speed of 0. What it does to rolls against you is for the others to apply."
R.EXHAUSTION_HELP = "Each level takes 2 from your d20 rolls and 5 feet from your speed, which the sheet applies for you. At level 6 you die. A long rest removes one level."
