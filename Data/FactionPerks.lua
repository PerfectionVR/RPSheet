-- What each faction gives of its own at each renown tier, on top of the perks every
-- faction gives (Data/Factions.lua). This file: how an entry is written, what a side
-- as a whole gives, and the Alliance. The Horde and the orders have files of their own.
--   R.FACTION_PERKS[<faction>][<tier>] = {
--     text   the perk in a sentence or two, shown with the renown score
--     train  what a month with the faction's trainers can teach: languages, tools and
--            skills by name; anyLanguage = true adds every language. The player picks
--            one (Sheet/RenownTraining.lua)
--     grant  something the sheet puts on the character while the score is high enough
--            (Sheet/RenownPerks.lua):
--              name       what the passive or ability is called
--              kind       "ability" for something to click; a passive when left out
--              desc       its own wording; `text` when left out
--              effects, advantage, startsOff   as for a class feature's passive
--              uses       uses per long rest, shown as a bar of the same name
--              scores, scoreMax   ability scores it raises, and how far
--   }
local _, ns = ...
local R = ns.Rules
local Bonus = ns.FeatureKit.Bonus

R.FACTION_PERKS = {}
local P = R.FACTION_PERKS

-- The side a subfaction belongs to gives these once any of its subfactions reaches the tier.
R.SIDE_NAMES = { ALLIANCE = "Alliance", HORDE = "Horde" }
R.SIDE_PERKS = {
    Honored = "Everyone who stands with the %s is friendly to you by default.",
    Revered = "A stronghold in %s lands has its events rolled twice when you maintain it, and you pick one.",
}
-- Exalted with all of these makes an ambassador of the side.
R.AMBASSADOR_FACTIONS = {
    ALLIANCE = { "Darnassus", "Exodar", "Gilneas", "Gnomeregan", "Ironforge", "Stormwind" },
    HORDE = { "Bilgewater Cartel", "Darkspear Tribe", "Orgrimmar", "Silvermoon City", "Thunder Bluff", "Undercity" },
}
R.AMBASSADOR_PERK = "Ambassador of the %s: its leaders receive you at any time, gather in council on a week's notice and may lend troops to a worthy cause, and one of its great heroes joins you for one adventure."

local ONCE = " Once, then again after your renown rises."

P["Darnassus"] = {
    Friendly = { text = "A month with a trainer teaches you Darnassian, Thalassian or the Herbalism Kit.",
        train = { "Darnassian", "Thalassian", "Herbalism Kit" } },
    Honored = { text = "Gathering herbs yields one more, and a rare one when you beat the DC by 4 or more." },
    Revered = { text = "Before a quest for Darnassus its leaders grant a blessing of your choice, which lasts until the quest ends." .. ONCE },
    Exalted = { text = "A Warden, a Sentinel commander with three scouts, or a high priestess of Elune joins you for one adventure." .. ONCE },
}
P["Exodar"] = {
    Friendly = { text = "A month with a trainer teaches you Draenei, Glassblower's Tools or Jeweler's Tools.",
        train = { "Draenei", "Glassblower's Tools", "Jeweler's Tools" } },
    Honored = { text = "Jewelcrafting takes you half the time." },
    Revered = { text = "Before a quest for the Exodar its leaders grant a charm of heroism, restoration or vitality, which lasts until used or the quest ends." .. ONCE },
    Exalted = { text = "Fifty draenei soldiers with three sergeants and a commander join you for one adventure." .. ONCE },
}
P["Gilneas"] = {
    Friendly = { text = "A month with a trainer teaches you Common, Common Sign Language or Leatherworker's Tools.",
        train = { "Common", "Common Sign Language", "Leatherworker's Tools" } },
    Honored = { text = "+2 to checks made to skin a creature." },
    Revered = { text = "Before a quest for Gilneas its leaders grant a charm that conjures animal spirits in worgen shape, three times, until the quest ends." .. ONCE },
    Exalted = { text = "A pack of six worgen skirmishers and their leader joins you for one adventure." .. ONCE },
}
P["Gnomeregan"] = {
    Friendly = { text = "A month with a trainer teaches you Gnomish or Tinker's Tools.", train = { "Gnomish", "Tinker's Tools" } },
    Honored = { text = "Engineering takes you half the time." },
    Revered = { text = "Before a quest for Gnomeregan you are lent a device that works as a wand of wonder for you alone. Its charges don't return, and it bursts harmlessly with the last one." },
    Exalted = { text = "A shield guardian serves you. It turns on you if your renown drops below 50.",
        grant = { name = "Shield Guardian", desc = "Gnomeregan gave you a shield guardian that serves you as a companion. It turns on you if your renown with Gnomeregan drops below 50." } },
}
P["Ironforge"] = {
    Friendly = { text = "A month with a trainer teaches you Dwarven, Mason's Tools or Smith's Tools.",
        train = { "Dwarven", "Mason's Tools", "Smith's Tools" } },
    Honored = { text = "Blacksmithing takes you half the time." },
    Revered = { text = "Before a quest for Ironforge you are lent a dwarven relic: a belt of dwarvenkind, dwarven plate or a dwarven thrower. Not returning it costs 1d8 renown." },
    Exalted = { text = "Fifty dwarf soldiers with three sergeants and a commander join you for one adventure." .. ONCE },
}
P["Obsidian Warders"] = {
    Friendly = { text = "A month with a trainer teaches you Draconic or History.", train = { "Draconic", "History" } },
    Honored = { text = "Sight of the Earth-Warder: advantage on initiative rolls and Perception checks.",
        grant = { name = "Sight of the Earth-Warder", advantage = { "initiative", "Perception" },
            desc = "Advantage on initiative rolls and Perception checks. The sheet rolls them this way." } },
    Revered = { text = "Before a quest for the Warders their leaders grant the Blessing of Protection (+1 to AC and saving throws) until the quest ends." .. ONCE,
        grant = { name = "Blessing of Protection", startsOff = true, effects = { Bonus("AC", 1), Bonus("SAVES", 1) },
            desc = "Switch on while you carry the blessing asked for before a quest for the Warders: +1 to AC and saving throws until the quest ends." } },
    Exalted = { text = "A whelp of the black dragonflight joins you for one adventure; its death costs 2d6 renown." .. ONCE },
}
P["Stormwind"] = {
    Friendly = { text = "A month with a trainer teaches you Common, Common Sign Language or Weaver's Tools.",
        train = { "Common", "Common Sign Language", "Weaver's Tools" } },
    Honored = { text = "Tailoring takes you half the time." },
    Revered = { text = "Before a quest for Stormwind its leaders grant any blessing or charm you name, until used or the quest ends." .. ONCE },
    Exalted = { text = "Fifty soldiers with their officers, an SI:7 spy master with three agents, a champion of the Light, or a Kul Tiran admiral with a warship joins you for one adventure." .. ONCE },
}
P["Tushui"] = {
    Friendly = { text = "A month with a trainer teaches you Pandaren, Brewer's Supplies or Cook's Utensils.",
        train = { "Pandaren", "Brewer's Supplies", "Cook's Utensils" } },
    Honored = { text = "A short rest spent in silent meditation ends with Heroic Inspiration.",
        grant = { name = "Tushui Meditation" } },
    Revered = { text = "Blessing of Understanding: +2 Wisdom, to at most 22.",
        grant = { name = "Blessing of Understanding", scores = { WIS = 2 }, scoreMax = 22,
            desc = "Your Wisdom is 2 higher, to at most 22. The sheet counts it." } },
    Exalted = { text = "A Tushui monk keeps a meditation chamber in your stronghold, on top of its usual facilities." },
}
