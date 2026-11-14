-- Lists a class picks a set number of options from: a Sorcerer's Metamagic and a
-- Warlock's Eldritch Invocations. Summaries are short and in our own words.
-- (A Battle Master's maneuvers work the same way but have their own files.)
--
-- R.PICK_LISTS[key] = {
--     title   heading in the level dialog
--     base    the Player's Handbook class that has the list
--     known   { {level, how many}, ... }
--     items   { [name] = { desc, level = minimum level, needs = another pick it requires,
--                          cost = Sorcery Points it spends, dice = { count, sides, stat } } }
-- }
-- A pick with a cost or dice becomes a clickable ability; the others are passives.
local _, ns = ...
local R = ns.Rules

R.PICK_LISTS = {
    metamagic = {
        title = "Metamagic", base = "Sorcerer",
        known = { { 2, 2 }, { 10, 4 }, { 17, 6 } },
        items = {
            ["Careful Spell"] = { cost = 1, desc = "When a spell of yours forces saves: creatures you choose, up to your Charisma modifier, pass the save automatically and take no damage where a success would halve it." },
            ["Distant Spell"] = { cost = 1, desc = "Double a spell's range, or give a touch spell a range of 30 feet." },
            ["Empowered Spell"] = { cost = 1, desc = "Reroll damage dice of a spell, up to your Charisma modifier, and use the new rolls. Can be combined with another Metamagic option." },
            ["Extended Spell"] = { cost = 1, desc = "Double a spell's duration, up to 24 hours. If it needs concentration, you have advantage on saves to keep it." },
            ["Heightened Spell"] = { cost = 2, desc = "One target of a spell has disadvantage on its saves against it." },
            ["Quickened Spell"] = { cost = 2, desc = "Cast a spell with a casting time of an action as a bonus action. Not if you have cast, or go on to cast, another spell of level 1 or higher this turn." },
            ["Seeking Spell"] = { cost = 1, desc = "When a spell attack misses: reroll the d20 and use the new roll. Can be combined with another Metamagic option." },
            ["Subtle Spell"] = { cost = 1, desc = "Cast a spell without words, gestures or materials, except materials that are consumed or have a cost." },
            ["Transmuted Spell"] = { cost = 1, desc = "Change a spell's acid, cold, fire, lightning, poison or thunder damage to another of those types." },
            ["Twinned Spell"] = { cost = 1, desc = "For a spell that can target one more creature when cast with a higher slot: treat it as cast one level higher." },
        },
    },
    invocations = {
        title = "Eldritch Invocations", base = "Warlock",
        known = { { 1, 1 }, { 2, 3 }, { 5, 5 }, { 7, 6 }, { 9, 7 }, { 12, 8 }, { 15, 9 }, { 18, 10 } },
        items = {
            ["Agonizing Blast"] = { level = 2, desc = "Add your Charisma modifier to the damage of one damaging Warlock cantrip you know: tick \"Add spellcasting modifier\" on it." },
            ["Armor of Shadows"] = { desc = "Cast Mage Armor on yourself without a spell slot." },
            ["Ascendant Step"] = { level = 5, desc = "Cast Levitate on yourself without a spell slot." },
            ["Call of the Void"] = { level = 5, needs = "Pact of the Legion", desc = "Your Pact of the Legion familiar can be a Voidwalker, and you can command it more freely." },
            ["Curse of Corruption"] = { level = 2, dice = { 0, 4, "CHA" }, desc = "When an enemy cursed by one of your Warlock spells (such as Hex) starts its turn, it makes a Charisma save or takes necrotic damage equal to your Charisma modifier." },
            ["Devil's Sight"] = { level = 2, desc = "You see normally in dim light and darkness, magical or not, out to 120 feet." },
            ["Devouring Blade"] = { level = 12, needs = "Thirsting Blade", desc = "Thirsting Blade gives two extra attacks, not one." },
            ["Eldritch Mind"] = { desc = "Advantage on Constitution saves to keep concentrating." },
            ["Eldritch Smite"] = { level = 5, needs = "Pact of the Blade", dice = { 1, 8 }, desc = "Once per turn when you hit with your pact weapon, spend a pact slot: 1d8 force damage plus 1d8 per level of the slot, and you can knock a Huge or smaller target prone. Click once per die." },
            ["Eldritch Spear"] = { level = 2, desc = "One damaging Warlock cantrip with a range of 10 feet or more reaches 30 feet farther per Warlock level." },
            ["Expendable Minions"] = { level = 9, desc = "When your familiar or a creature you summoned dies, you or a creature within 60 feet regains hit points equal to your level plus Charisma modifier." },
            ["Fiendish Vigor"] = { level = 2, desc = "Cast False Life on yourself without a spell slot, gaining the highest number its die can show." },
            ["Gaze of Two Minds"] = { level = 5, desc = "Bonus action: touch a willing creature and perceive through its senses, casting spells as if you were in its place." },
            ["Gift of the Depths"] = { level = 5, desc = "You breathe underwater and have a swimming speed. Once per long rest you can cast Water Breathing without a slot." },
            ["Gift of the Protectors"] = { level = 9, needs = "Pact of the Tome", desc = "Creatures who write their name in your Book of Shadows drop to 1 hit point instead of 0, once per long rest for the book." },
            ["Health Funnel"] = { level = 2, desc = "Bonus action: spend any number of your Hit Dice. Your familiar, or another fiend you command, gains temporary hit points equal to the rolls plus your Charisma modifier for each die." },
            ["Investment of the Chain Master"] = { level = 5, needs = "Pact of the Chain", desc = "Your familiar gains a flying or swimming speed, attacks as a bonus action on your command, deals necrotic or radiant damage, uses your spell save DC, and can resist damage with its reaction." },
            ["Legion Summoning"] = { level = 9, needs = "Pact of the Legion", desc = "Once per long rest, cast Planar Binding without a slot to summon and bind a Felguard, Felhound, Incubus or Succubus." },
            ["Lessons of the First Ones"] = { level = 2, desc = "You gain an origin feat of your choice. Add it under Customize, Passives." },
            ["Lifedrinker"] = { level = 9, needs = "Pact of the Blade", dice = { 1, 6 }, desc = "Once per turn when you hit with your pact weapon: 1d6 extra necrotic, psychic or radiant damage, and you can spend a Hit Die to heal." },
            ["Mask of Many Faces"] = { level = 2, desc = "Cast Disguise Self without a spell slot." },
            ["Master Demonologist"] = { level = 5, desc = "Fiends you command also deal your Hex's extra damage to its target." },
            ["Master of Myriad Forms"] = { level = 5, desc = "Cast Alter Self without a spell slot." },
            ["Misty Visions"] = { level = 2, desc = "Cast Silent Image without a spell slot." },
            ["One with Shadows"] = { level = 5, desc = "In dim light or darkness, cast Invisibility on yourself without a spell slot." },
            ["Otherworldly Leap"] = { level = 2, desc = "Cast Jump on yourself without a spell slot." },
            ["Pact of the Blade"] = { desc = "Bonus action: conjure a pact weapon, a simple or martial melee weapon you are proficient with. It can attack with Charisma and deal necrotic, psychic or radiant damage." },
            ["Pact of the Chain"] = { desc = "You know Find Familiar and cast it without a slot, with special forms to choose from. You can give up one of your attacks to let the familiar attack." },
            ["Pact of the Legion"] = { desc = "You know Find Familiar and cast it without a slot, summoning a Fel Imp. You can give up one of your attacks to let it attack." },
            ["Pact of the Tome"] = { desc = "After a rest you conjure a Book of Shadows holding three cantrips and two 1st-level rituals from any class, which you can cast while you hold it." },
            ["Repelling Blast"] = { level = 2, desc = "When one Warlock cantrip that uses an attack roll hits a Large or smaller creature, you can push it up to 10 feet away." },
            ["Thirsting Blade"] = { level = 5, needs = "Pact of the Blade", desc = "You attack twice with your pact weapon when you take the Attack action." },
            ["Visions of Distant Realms"] = { level = 9, desc = "Cast Arcane Eye without a spell slot." },
            ["Whispers of the Grave"] = { level = 7, desc = "Cast Speak with Dead without a spell slot." },
            ["Witch Sight"] = { level = 15, desc = "Truesight out to 30 feet." },
        },
    },
}
-- Invocations that can be taken again, each time for another cantrip or feat. Every
-- further time is an option of its own that builds on the one before.
local AGAIN = {
    ["Agonizing Blast"] = "cantrip", ["Eldritch Spear"] = "cantrip", ["Repelling Blast"] = "cantrip",
    ["Lessons of the First Ones"] = "origin feat",
}
for name, what in pairs(AGAIN) do
    local items = R.PICK_LISTS.invocations.items
    local previous = name
    for _, nth in ipairs({ "second", "third" }) do
        local again = ("%s (%s)"):format(name, nth)
        items[again] = { level = items[name].level, needs = previous, desc = ("%s Taken again, for a different %s."):format(items[name].desc, what) }
        previous = again
    end
end
R.PICK_LIST_ORDER = { "metamagic", "invocations" }

for _, list in pairs(R.PICK_LISTS) do
    list.order = {}
    for name in pairs(list.items) do list.order[#list.order + 1] = name end
    table.sort(list.order)
end
