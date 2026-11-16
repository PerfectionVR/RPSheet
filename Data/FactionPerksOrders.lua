-- The renown perks of the orders and cartels that stand outside the two sides
-- (how an entry is written: Data/FactionPerks.lua).
local _, ns = ...
local R = ns.Rules
local P = R.FACTION_PERKS

P["Argent Dawn"] = {
    Friendly = { text = "Blessing of Argent Will: advantage on saves against being charmed by a fiend or an undead.",
        grant = { name = "Blessing of Argent Will",
            desc = "Advantage on saving throws to avoid or end being charmed by a fiend or an undead. The sheet asks what a save is against when you roll one." } },
    Honored = { text = "A long rest in an Argent Dawn sanctuary gives a charm that casts Healing Word once within 7 days." },
    Revered = { text = "Blessing of Argent Fortitude: immune to poison damage and to being poisoned.",
        grant = { name = "Blessing of Argent Fortitude", desc = "You are immune to poison damage and to the poisoned condition." } },
    Exalted = { text = "For 15,000 gold the Dawn adds resistance to one damage type of your choice to a rare item you are attuned to, which becomes very rare." },
}
P["Cenarion Circle"] = {
    Friendly = { text = "A month with a trainer teaches you Druidic or Nature.", train = { "Druidic", "Nature" } },
    Honored = { text = "A long rest in a Circle sanctuary gives a charm of restoration: three charges for Lesser Restoration (1) or Greater Restoration (2)." },
    Revered = { text = "Wildguard Blessing: advantage on saving throws against spells.",
        grant = { name = "Wildguard Blessing",
            desc = "Advantage on saving throws against spells. The sheet asks what a save is against when you roll one." } },
    Exalted = { text = "You are a Guardian of Cenarius, and may buy a war hippogryph mount for 2,000 gold. Both are lost if your renown drops below 50." },
}
P["Earthen Ring"] = {
    Friendly = { text = "A month with a trainer teaches you Kalimag. Elementals untouched by the Old Gods are friendly to you by default.",
        train = { "Kalimag" } },
    Honored = { text = "The portals of both Earthshrines are open to you, and a long rest in a Ring sanctuary gives a charm with three castings of Summon Elemental within 7 days." },
    Revered = { text = "Blessing of the Earthen Ring: once a day, summon an air, earth, fire or water elemental that serves you for an hour.",
        grant = { kind = "ability", name = "Blessing of the Earthen Ring", uses = 1,
            desc = "Magic action: an air, earth, fire or water elemental appears within 30 feet, obeys you and acts right after you. It leaves after an hour, when it dies, or when you dismiss it as a bonus action. Once per day; the sheet gives the use back on a long rest." } },
    Exalted = { text = "Blessing of the Farseer: the powers of a ring of elemental command, tied to an elemental plane you choose anew after each long rest.",
        grant = { name = "Blessing of the Farseer" } },
}
-- The League and the Reliquary keep the same perks; a character works with one of them.
P["Explorers' League"] = {
    Friendly = { text = "A month with a trainer teaches you any language or History.", train = { "History", anyLanguage = true } },
    Honored = { text = "A dig site yields one more fragment on a success, and you have advantage on History checks to piece fragments into a relic." },
    Revered = { text = "Seven days among the order's relics and a long rest give a charm for 7 days, chosen by the relics' origin: it lends you a language and holds one spell or burst of power." },
    Exalted = { text = "The vaults lend you a legendary item of your choice for one fitting adventure, a week after you ask. Not returning it costs 2d12 renown. Once, then again after your renown rises." },
}
P["Reliquary"] = P["Explorers' League"]
P["Kirin Tor"] = {
    Friendly = { text = "A modest life in Dalaran costs you nothing. You may ask the archmages a favor as many times as your renown score: a spell of up to 3rd level cast, or a common or uncommon arcane item, at half price, or a month of teaching in a language or a tool." },
    Honored = { text = "Your free lifestyle is comfortable. Favors reach 4th-level spells and rare items, or library research during a stronghold turn; a stronghold in Dalaran has its events rolled twice and you pick one." },
    Revered = { text = "Your free lifestyle is wealthy. Favors reach 6th-level spells and very rare items, or scriptorium work during a stronghold turn." },
    Exalted = { text = "Your free lifestyle is aristocratic. Favors reach 8th-level spells and legendary items, and two apprentices speed up any magic item you craft." },
}
P["Steamwheedle Cartel"] = {
    Friendly = { text = "A month with a trainer teaches you Goblin, Alchemist's Supplies or Tinker's Tools.",
        train = { "Goblin", "Alchemist's Supplies", "Tinker's Tools" } },
    Honored = { text = "Before a quest for the cartel you get 1d4 flasks of Noggenfogger Elixir. Once, then again after your renown rises." },
    Revered = { text = "The cartel sells you an experimental goblin jetpack for 2,000 gold, without further discount." },
    Exalted = { text = "The cartel sells you its apparatus, a walking and diving machine, for 100,000 gold, without further discount." },
}
P["Valdrakken Accord"] = {
    Friendly = { text = "A month with a trainer teaches you Draconic.", train = { "Draconic" } },
    Honored = { text = "Blessing of the Proto-Whelp: once per long rest, cast Find Familiar without components; the familiar is a crimson proto-whelp. A stronghold on the Dragon Isles gains a garden.",
        grant = { kind = "ability", name = "Blessing of the Proto-Whelp", uses = 1,
            desc = "Cast Find Familiar without material components, once per long rest. The familiar is a crimson proto-whelp with a pseudodragon's abilities, and vanishes if your renown drops below 10." } },
    Revered = { text = "Blessing of the Wylderdrake: cast Find Steed at 4th level; the steed is a flying wylderdrake.",
        grant = { kind = "ability", name = "Blessing of the Wylderdrake",
            desc = "Cast Find Steed as a 4th-level spell without a slot. The steed is a cliffside wylderdrake: a dragon whose slam deals force damage and which flies out of reach without provoking opportunity attacks, in place of the steed's usual bonus actions." } },
    Exalted = { text = "You are an Ally of Dragons: uncorrupted dragons are friendly to you by default, and once ever an Aspect grants you a wish." },
}
