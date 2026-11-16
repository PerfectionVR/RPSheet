-- What feats give to click: uses with a bar, dice to roll, a passive to switch on.
-- Each entry becomes an ability marked auto = "featuse:<name>" while a passive named
-- like the feat is on the sheet (Sheet/FeatUses.lua). Summaries in our own words.
--   name     the ability's name, and its bar's when it has uses
--   uses     uses per long rest: a number, or "PROF" for the proficiency bonus
--   short    "ALL" if a short rest gives them back too
--   initiative  true if rolling initiative gives them back too
--   waitRests   sides of the die that says how many long rests it takes to come back
--   actions  what clicking does besides spending a use (see Data/FeatureKit.lua); may
--            be function(level)
--   passive  a passive the ability switches on: { name, desc, effects }
--   desc     the ability's text; may be function(sheet) for numbers that follow it
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local Dice = Kit.Dice

R.FEAT_USES = {
    ["Lucky"] = { {
        name = "Luck Points", uses = "PROF", actions = { Kit.NextRoll("ADV") },
        desc = "Spend a luck point for advantage on your next d20 test: clicking sets the Next roll row. Or spend one to give an attack roll against you disadvantage. As many points as your proficiency bonus, back after a long rest.",
    } },
    ["Mage Slayer"] = { {
        name = "Guarded Mind", uses = 1, short = "ALL",
        desc = "When you fail an Intelligence, Wisdom or Charisma saving throw, you succeed instead. Once per short or long rest.",
    } },
    ["Arathi Heritage"] = { {
        name = "Lethargy Resilience", uses = 1, waitRests = 4,
        desc = "When you fail a saving throw against falling Unconscious, or to wake from it, you succeed instead. It comes back after 1d4 long rests: the sheet rolls the d4 at the first one and holds the use back until the last.",
    } },
    ["Boon of Recovery"] = {
        { name = "Last Stand", uses = 1, actions = { Dice(0, 4, "HALFHP", "SELFHEAL", 1) },
          desc = "When you would drop to 0 hit points, you drop to 1 and regain half your maximum. Once per long rest. Click it when it happens: the sheet heals you." },
        { name = "Recover Vitality", uses = 10, actions = { Dice(1, 10, "", "SELFHEAL") },
          desc = "Bonus action: spend dice from a pool of ten d10s and regain hit points equal to their roll. Click once for each die. The pool fills again after a long rest." },
    },
    ["Boon of Fate"] = { {
        name = "Improve Fate", uses = 1, short = "ALL", initiative = true, actions = { Dice(2, 4, "", "OTHER") },
        desc = "When you or a creature within 60 feet succeeds or fails a d20 test, roll 2d4 and add or take away the total. Once, then again after a short or long rest or when you roll initiative.",
    } },
    ["Chef"] = { {
        name = "Bolstering Treats", uses = "PROF", actions = { Dice(0, 4, "PROF", "TEMPHP") },
        desc = "After a long rest you have treats equal to your proficiency bonus, good for 8 hours. Eating one is a bonus action and gives temporary hit points equal to your proficiency bonus: click when you eat one. Hand one to an ally and click too, to count it; they gain the hit points themselves. Your short-rest meal is added when you spend Hit Dice.",
    } },
    ["Charger"] = { {
        name = "Charge Attack", actions = { Dice(1, 8) },
        desc = "Once per turn, after moving 10 feet straight at a target before hitting it with a melee attack as part of the Attack action: 1d8 extra damage, or push it 10 feet if it is at most one size larger. Dashing adds 10 feet to your speed.",
    } },
    ["Fingers of Frost"] = { {
        name = "Frostbite",
        actions = function(level) return { Kit.Typed(Dice(Kit.Prof(level), 4), "cold") } end,
        desc = "When you deal cold damage to a Restrained creature: extra cold damage, a d4 for each point of your proficiency bonus.",
    } },
    ["Poisoner"] = { {
        name = "Poisoned Weapon", actions = { Kit.Typed(Dice(2, 8), "poison") },
        desc = function(sheet)
            local stat = ns.FeatRaisedStat(sheet, "Poisoner") or (Kit.Mod(sheet, "INT") > Kit.Mod(sheet, "DEX") and "INT" or "DEX")
            return ("When a creature takes damage from your poisoned weapon or ammunition: Constitution save, DC %d, or 2d8 poison damage and Poisoned until the end of your next turn. A dose is applied as a bonus action and lasts a minute or until it deals damage. An hour with a poisoner's kit and 50 gp of materials make doses equal to your proficiency bonus."):format(Kit.DC(sheet, stat))
        end,
    } },
    ["Defensive Duelist"] = { {
        name = "Parry", actions = { Kit.SwitchOn("Parrying") },
        passive = { name = "Parrying", effects = { Kit.Bonus("AC", 0, "PROF") },
                    desc = "On while you parry: your proficiency bonus is added to your Armor Class against melee attacks. Switch it off at the start of your next turn; a rest ends it too." },
        desc = "Reaction when a creature hits you with a melee attack while you hold a finesse weapon: add your proficiency bonus to your Armor Class against melee attacks until your next turn, which may turn the hit into a miss. Switches Parrying on.",
    } },
    ["Polearm Master"] = { {
        name = "Pole Strike", actions = { Kit.Roll("ATTACK", "STR"), Kit.Typed(Dice(1, 4, "STR"), "bludgeoning") },
        desc = "Bonus action right after you take the Attack action with a quarterstaff, a spear or a heavy reach weapon: strike with its other end, a d4 of bludgeoning damage. Your reaction can also attack a creature that comes into your reach.",
    } },
}
