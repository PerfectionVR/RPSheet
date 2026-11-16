-- The Horde subfactions' own renown perks (how an entry is written: Data/FactionPerks.lua).
local _, ns = ...
local R = ns.Rules
local P = R.FACTION_PERKS

local ONCE = " Once, then again after your renown rises."

P["Bilgewater Cartel"] = {
    Friendly = { text = "A month with a trainer teaches you Goblin or Alchemist's Supplies.", train = { "Goblin", "Alchemist's Supplies" } },
    Honored = { text = "Alchemy takes you half the time." },
    Revered = { text = "Before a quest for the cartel you get a charm that summons a clockwork goblin for an hour, once. It explodes when it falls or the hour ends: 2d6 fire within 10 feet, Dexterity save DC 13 for half." .. ONCE },
    Exalted = { text = "A cartel captain with a ship and six crew joins you for one adventure; more hands are yours to hire." .. ONCE },
}
P["Dark Talons"] = {
    Friendly = { text = "A month with a trainer teaches you Draconic or History.", train = { "Draconic", "History" } },
    Honored = { text = "Strike of the Earth-Warder: +1 to hit and damage with unarmed strikes, and +1 to the save DC of your grapples and shoves.",
        grant = { name = "Strike of the Earth-Warder",
            desc = "+1 to attack and damage rolls with unarmed strikes, and +1 to the save DC of your grapples and shoves. The sheet adds it to your Unarmed Strike row." } },
    Revered = { text = "Before a quest for the Talons you get a charm of terror with three uses: creatures you choose within 30 feet flee in fear for a minute, Wisdom save DC 15, repeated each turn." .. ONCE },
    Exalted = { text = "A whelp of the black dragonflight joins you for one adventure; its death costs 2d6 renown." .. ONCE },
}
P["Darkspear Tribe"] = {
    Friendly = { text = "A month with a trainer teaches you Zandali or Religion.", train = { "Zandali", "Religion" } },
    Honored = { text = "Offerings to the loa during a short rest and a DC 15 Religion check earn a charm that works once as a potion you choose from a list of lesser ones." .. ONCE },
    Revered = { text = "The loa's charm can also work as one of a list of stronger potions, such as invisibility or superior healing." },
    Exalted = { text = "A shadow hunter and six hexxers join you for one adventure." .. ONCE },
}
P["Huojin"] = {
    Friendly = { text = "A month with a trainer teaches you Pandaren, Brewer's Supplies or Cook's Utensils.",
        train = { "Pandaren", "Brewer's Supplies", "Cook's Utensils" } },
    Honored = { text = "Advantage on initiative rolls.",
        grant = { name = "Huojin Readiness", advantage = { "initiative" },
            desc = "Advantage on initiative rolls, which the sheet rolls for you." } },
    Revered = { text = "Blessing of Health: +2 Constitution, to at most 22.",
        grant = { name = "Blessing of Health", scores = { CON = 2 }, scoreMax = 22,
            desc = "Your Constitution is 2 higher, to at most 22. The sheet counts it." } },
    Exalted = { text = "Huojin monks keep a training area in your stronghold, on top of its usual facilities." },
}
P["Orgrimmar"] = {
    Friendly = { text = "A month with a trainer teaches you Orcish, Orcish Sign Language, Vulpera or Leatherworker's Tools.",
        train = { "Orcish", "Orcish Sign Language", "Vulpera", "Leatherworker's Tools" } },
    Honored = { text = "Leatherworking takes you half the time." },
    Revered = { text = "Before a quest for Orgrimmar its leaders grant a blessing of your choice, which lasts until the quest ends." .. ONCE },
    Exalted = { text = "A warband leader, a shaman and three seasoned warriors, all on dire wolves, join you for one adventure." .. ONCE },
}
P["Silvermoon City"] = {
    Friendly = { text = "A month with a trainer teaches you Shalassian, Thalassian, or Carpenter's, Potter's or Woodcarver's Tools.",
        train = { "Shalassian", "Thalassian", "Carpenter's Tools", "Potter's Tools", "Woodcarver's Tools" } },
    Honored = { text = "Enchanting takes you half the time." },
    Revered = { text = "Before a quest for Silvermoon you get a charm that works as a wand you choose (fireballs, web, polymorph and others). Its charges don't return." .. ONCE },
    Exalted = { text = "A magister, or four mages, joins you for one adventure." .. ONCE },
}
P["Thunder Bluff"] = {
    Friendly = { text = "A month with a trainer teaches you Taur-ahe or the Herbalism Kit.", train = { "Taur-ahe", "Herbalism Kit" } },
    Honored = { text = "Gathering herbs yields one more, and a rare one when you beat the DC by 4 or more." },
    Revered = { text = "Before a quest for Thunder Bluff you get the Charm of An'she: three castings of Summon Beast at 3rd level, until the quest ends." .. ONCE },
    Exalted = { text = "A tauren shaman with eight helpers joins you for one adventure." .. ONCE },
}
P["Undercity"] = {
    Friendly = { text = "A month with a trainer teaches you Forsaken or Alchemist's Supplies.", train = { "Forsaken", "Alchemist's Supplies" } },
    Honored = { text = "Alchemy takes you half the time." },
    Revered = { text = "Before a quest for the Undercity you get the Charm of the Banshee: three castings of Summon Undead, until the quest ends." .. ONCE },
    Exalted = { text = "Two Forsaken necromancers and five undead soldiers join you for one adventure." .. ONCE },
}
