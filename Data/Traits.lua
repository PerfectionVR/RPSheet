-- Species traits that do more than remind: a choice to make, a number of uses, dice
-- to roll, or a change to how hit dice heal. Traits not listed here are standing
-- rules with nothing to track, and stay as passives (see Data/Species.lua).
--   choice   "SKILL" (a skill proficiency) or "FEAT" (an origin feat) to pick
--   options  the skills to pick from; any skill when left out
--   uses     uses per long rest: a number, or "PROF" for the proficiency bonus
--   short    "ALL" if a short rest gives the uses back too
--   level    character level the trait starts at
--   actions  what clicking it does (see Data/FeatureKit.lua); may be function(level)
--   passive  a passive that comes with it: { name, desc, effects, startsOff }
--   hitDie   added to each hit die spent; hitDieMax = hit dice heal their maximum
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local Dice, Roll = Kit.Dice, Kit.Roll

R.TRAITS = {
    -- Choices
    ["Skillful"] = { choice = "SKILL" },
    ["Keen Senses"] = { choice = "SKILL", options = { "Insight", "Perception", "Survival" } },
    ["Versatile"] = { choice = "FEAT" },

    -- Uses and dice
    ["Stonecunning"] = { uses = "PROF", desc = "Bonus action while touching stone: you sense vibrations within 60 feet for 10 minutes. Uses equal to your proficiency bonus per long rest." },
    ["Adrenaline Rush"] = { uses = "PROF", short = "ALL", actions = { Dice(0, 4, "PROF", "TEMPHP") },
        desc = "Dash as a bonus action and gain temporary HP equal to your proficiency bonus. Uses equal to your proficiency bonus, back on a short or long rest." },
    ["Relentless Endurance"] = { uses = 1, actions = { Dice(0, 4, "", "SELFHEAL", 1) },
        desc = "When you would drop to 0 hit points, you drop to 1 instead. Once per long rest. Click it when it happens." },
    ["Draconic Flight"] = { uses = 1, level = 5, desc = "Bonus action: for 10 minutes you fly at your walking speed. Once per long rest." },
    ["Heroic Presence"] = { uses = 1, short = "ALL", desc = "When you cast a spell from your Eredar Lineage you gain Heroic Inspiration. Once per rest." },
    ["Touch of the Grave"] = { uses = 1,
        actions = function(level) return { Dice(math.ceil(level / 4) + 1, 4, "", "DRAIN") } end,
        desc = "When you hit: extra necrotic damage, a d4 per point of your proficiency bonus, and you heal by the same amount. Once per long rest." },
    ["Fury of the Small"] = { uses = "PROF", actions = { Dice(0, 4, "PROF", "DAMAGE") },
        desc = "Once per turn when you damage a creature larger than you: extra damage equal to your proficiency bonus. Uses equal to your proficiency bonus per long rest." },
    ["Built for Success"] = { uses = "PROF", actions = { Dice(1, 4, "", "OTHER") },
        desc = "After seeing a d20 roll of yours, add a d4 to it. Uses equal to your proficiency bonus per long rest." },
    ["Emergency Fail-Safe"] = { uses = 1, short = "ALL",
        desc = "Reaction when you become Bloodied: spend a Hit Die to heal. Once per rest. Click this, then the Hit Dice bar." },
    ["Darkflight"] = { uses = "PROF",
        -- Temporary HP of twice the proficiency bonus, and the form's extra speed.
        actions = function(level)
            return { Dice(0, 4, "", "TEMPHP", 2 * (math.ceil(level / 4) + 1)), Kit.SwitchOn("Bestial form") }
        end,
        passive = { name = "Bestial form", startsOff = true, effects = { Kit.Bonus("SPEED", 10) },
                    desc = "Switch on while Darkflight lasts (1 minute): +10 feet of speed, resistance to necrotic damage, and as a reaction you can move 10 feet when a creature ends its turn next to you." },
        desc = "Bonus action: take a bestial form for a minute. You gain temporary HP equal to twice your proficiency bonus, 10 feet of speed, resistance to necrotic damage and a reactive step. Uses equal to your proficiency bonus per long rest." },
    ["Azerite Surge"] = { uses = "PROF",
        actions = function(level)
            return { Dice(Kit.AtLevel(level, { { 1, 1 }, { 5, 2 }, { 11, 3 }, { 17, 4 } }), 10, "", "HEALING") }
        end,
        desc = "In place of one attack: a 15-foot cone of Azerite. Creatures you choose are healed by the roll; the others take the same roll as radiant damage, half on a Dexterity save (DC 8 + Constitution modifier + proficiency bonus). Uses equal to your proficiency bonus per long rest." },
    ["Horns"] = { actions = { Roll("ATTACK", "STR"), Dice(1, 6, "STR") },
        desc = "An unarmed strike with your horns: 1d6 + Strength piercing damage." },

    -- Hit dice
    ["Quiet Contemplation"] = { hitDie = 1 },
    ["Inner Peace"] = { hitDie = 1 },
    ["Troll Healing"] = { hitDieMax = true },
}

-- Traits that become a clickable ability rather than a passive.
function R.TraitIsAbility(name)
    local trait = R.TRAITS[name]
    return trait ~= nil and (trait.uses ~= nil or trait.actions ~= nil)
end
