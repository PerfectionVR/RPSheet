-- Short explanations of game terms, shown when a term is hovered in the wizard, the
-- editor or the sheet. These are brief summaries in our own words to jog the memory;
-- the books have the full rules.
local _, ns = ...

local G = {}
ns.Glossary = G

-- Abilities (short and full names)
local ABILITIES = {
    STR = { "Strength", "Physical power. Used for most melee attacks, Athletics, carrying and breaking things." },
    DEX = { "Dexterity", "Agility and reflexes. Used for ranged and finesse attacks, Armor Class, initiative, Acrobatics, Sleight of Hand and Stealth." },
    CON = { "Constitution", "Health and stamina. Adds to your hit points every level and helps you keep concentration on spells." },
    INT = { "Intelligence", "Reasoning and memory. Used for Arcana, History, Investigation, Nature and Religion, and for Wizard spells." },
    WIS = { "Wisdom", "Awareness and intuition. Used for Animal Handling, Insight, Medicine, Perception and Survival, and for Cleric, Druid and Ranger spells." },
    CHA = { "Charisma", "Force of personality. Used for Deception, Intimidation, Performance and Persuasion, and for Paladin, Sorcerer and Warlock spells." },
}
for short, entry in pairs(ABILITIES) do
    G[short], G[entry[1]] = entry[2], entry[2]
end

-- Skills
G["Athletics"] = "Strength. Climbing, jumping, swimming, grappling and shoving."
G["Acrobatics"] = "Dexterity. Keeping your balance, tumbling, and staying on your feet in tricky situations."
G["Sleight of Hand"] = "Dexterity. Picking pockets, palming objects and other feats of manual trickery."
G["Stealth"] = "Dexterity. Hiding, moving quietly and slipping past notice."
G["Arcana"] = "Intelligence. Knowledge of spells, magic items, arcane symbols and the planes."
G["History"] = "Intelligence. Knowledge of past events, kingdoms, wars and legendary people."
G["Investigation"] = "Intelligence. Searching for clues and working out what they mean."
G["Nature"] = "Intelligence. Knowledge of terrain, plants, animals and weather."
G["Religion"] = "Intelligence. Knowledge of gods, rites, holy symbols and cults."
G["Animal Handling"] = "Wisdom. Calming, training or controlling animals, and riding in difficult moments."
G["Insight"] = "Wisdom. Reading a creature's mood and intentions; noticing lies."
G["Medicine"] = "Wisdom. Stabilising the dying and diagnosing illness."
G["Perception"] = "Wisdom. Spotting, hearing or otherwise noticing things around you."
G["Survival"] = "Wisdom. Tracking, foraging, navigating and predicting the weather."
G["Deception"] = "Charisma. Lying convincingly, by word or deed."
G["Intimidation"] = "Charisma. Influencing others through threats and menace."
G["Performance"] = "Charisma. Entertaining an audience with music, acting or storytelling."
G["Persuasion"] = "Charisma. Influencing others with tact, reason or good manners."

-- General terms
G["Hit die"] = "The die that sets your hit points. You get its maximum at level 1 and its average each level after, plus your Constitution modifier per level."
G["Saving throw"] = "A d20 roll to resist a spell, trap, poison or similar threat. You add the ability's modifier, plus your proficiency bonus if you are proficient in that save."
G["Proficiency bonus"] = "A bonus that grows with level, from +2 to +6. It is added to anything you are proficient in: saving throws, skills, weapon attacks and spells."
G["Expertise"] = "Your proficiency bonus is added twice for that skill."
G["Darkvision"] = "You see in dim light as if it were bright, and in darkness as if it were dim, out to the listed distance."
G["Origin feat"] = "A feat granted by your background at level 1."
G["Heroic Inspiration"] = "A reward you can spend to reroll one die and use the new result."
G["Bloodied"] = "At half your hit points or fewer."
G["Hero class"] = "Death Knight, Demon Hunter and Evoker. They are meant for characters who are already experienced, so they normally start at level 3 or higher."
G["Specialization"] = "A World of Warcraft specialization, such as Frost or Restoration. It is a guide to which subclass, spells and feats suit that style of play; it has no rules of its own."

-- Origin feats (Player's Handbook)
G["Alert"] = "You add your proficiency bonus to initiative, and after rolling initiative you can swap your result with a willing ally's."
G["Crafter"] = "Proficiency with three artisan's tools, a discount on nonmagical purchases, and you can quickly craft simple gear after a long rest."
G["Healer"] = "With a healer's kit you can let a creature spend one of its hit dice to heal, and you reroll 1s on healing dice."
G["Lucky"] = "A few luck points each day, equal to your proficiency bonus. Spend one for advantage on your own d20 roll or to give an attacker disadvantage against you."
G["Magic Initiate"] = "Two cantrips and one level 1 spell from the chosen class's list. You can cast that spell once a day for free, or with your spell slots."
G["Magic Initiate (Cleric)"] = G["Magic Initiate"]
G["Magic Initiate (Druid)"] = G["Magic Initiate"]
G["Magic Initiate (Wizard)"] = G["Magic Initiate"]
G["Musician"] = "Proficiency with three instruments. After a rest your music gives Heroic Inspiration to a few allies."
G["Savage Attacker"] = "Once per turn when you hit with a weapon, roll its damage dice twice and use either result."
G["Skilled"] = "Proficiency in any three skills or tools of your choice."
G["Tavern Brawler"] = "Stronger unarmed strikes: d4 damage, reroll 1s, a free push once per turn, and proficiency with improvised weapons."
G["Tough"] = "Your maximum hit points increase by 2 for every level you have."

-- Species traits: Player's Handbook species (the book adds Azeroth lineages to some)
G["Dwarven Resilience"] = "Resistance to poison damage, and advantage on saving throws against being poisoned."
G["Dwarven Toughness"] = "Your maximum hit points increase by 1 for every level you have."
G["Stonecunning"] = "As a bonus action while touching stone, you sense vibrations around you for a short time. A few uses per long rest."
G["Elven Lineage"] = "Choose an elven lineage, such as blood elf, night elf, nightborne or void elf. It gives a level 1 benefit and a spell at levels 3 and 5, each castable once a day for free."
G["Fey Ancestry"] = "Advantage on saving throws against being charmed."
G["Keen Senses"] = "Proficiency in Insight, Perception or Survival, your choice."
G["Trance"] = "You don't need sleep and magic can't put you to sleep. Four hours of meditation counts as a long rest."
G["Gnomish Cunning"] = "Advantage on Intelligence, Wisdom and Charisma saving throws."
G["Gnomish Lineage"] = "Minor magic from your gnomish heritage: a couple of cantrips, and in Azeroth the knack of building small clockwork devices."
G["Resourceful"] = "You gain Heroic Inspiration whenever you finish a long rest."
G["Skillful"] = "Proficiency in one skill of your choice."
G["Versatile"] = "You gain an origin feat of your choice."
G["Adrenaline Rush"] = "Dash as a bonus action and gain a few temporary hit points. A few uses per rest."
G["Relentless Endurance"] = "Once per long rest, when you would drop to 0 hit points, you drop to 1 instead."

-- Species traits: D&D: World of Warcraft
G["Gliding Wings"] = "In your natural form you ignore most falling damage and can glide forward as you fall."
G["Natural Weaponry"] = "In your natural form you can shove a creature with wings or tail as a bonus action."
G["Visage"] = "You can shape-shift between your draconic form and a humanoid visage. Your gear and statistics stay the same."
G["Draconic Flight"] = "From level 5, once per long rest you can take to the air for ten minutes, flying at your walking speed."
G["Eredar Lineage"] = "Choose Draenei, Krokul, Lightforged or Man'ari. Your lineage gives a level 1 benefit and a spell at levels 3 and 5, each castable once a day for free."
G["Heroic Presence"] = "Casting a spell from your Eredar Lineage gives you Heroic Inspiration, once per rest."
G["Azerite Surge"] = "In place of one attack you release a cone of Azerite: chosen creatures are healed, the rest must save or take radiant damage. It grows stronger as you level."
G["Earthen Resilience"] = "Resistance to poison damage, and advantage on saving throws against being poisoned."
G["Ingest Minerals"] = "Going without food never exhausts you."
G["Quiet Contemplation"] = "Each hit die you spend on a short rest heals 1 extra hit point."
G["Deathly Endurance"] = "Resistance to necrotic damage."
G["Everlasting"] = "You don't need to eat, drink, breathe or sleep, and four motionless hours count as a long rest."
G["Touch of the Grave"] = "Once per long rest, add necrotic damage to a hit (a d4 per point of proficiency bonus) and heal by the same amount."
G["Will of the Forsaken"] = "Advantage on saving throws against being charmed or frightened."
G["Fury of the Small"] = "Add your proficiency bonus to damage against a creature larger than you. Once per turn, a few times per long rest."
G["Nimble Escape"] = "You can Disengage or Hide as a bonus action."
G["Gift of the World Tree"] = "Proficiency in the Nature and Survival skills."
G["Haranir Magic"] = "You know the Druidcraft and Thorn Whip cantrips. You learn Entangle at level 3 and Spike Growth at level 5, each castable once per long rest without a slot."
G["Built for Success"] = "Add a d4 to a d20 roll after seeing it. A few uses per long rest."
G["Emergency Fail-Safe"] = "When you become Bloodied you can react by spending a hit die to heal. Once per rest."
G["Mechanical Nature"] = "Resistance to poison damage, advantage against being paralysed or poisoned, and no need to eat, drink or breathe."
G["Sentry's Rest"] = "You don't need sleep; six motionless hours count as a long rest."
G["Specialized Design"] = "Proficiency with two tools of your choice."
G["Bouncy"] = "Resistance to damage from falling."
G["Inner Peace"] = "Each hit die you spend on a short rest heals 1 extra hit point."
G["Quaking Palm"] = "A creature you hit in melee on your turn can't make opportunity attacks against you that turn."
G["Horns"] = "Your unarmed strike can deal d6 piercing damage plus your Strength modifier."
G["Goring Rush"] = "After you Dash and move far enough, you can make an unarmed strike as a bonus action."
G["Hammering Horns"] = "After hitting in melee with the Attack action, you can shove that target as a bonus action, and push it farther than usual."
G["Tauren Lineage"] = "Choose a tauren lineage, such as Mulgore. It grants a supernatural ability of its own."
G["Bloodied Frenzy"] = "While Bloodied you have advantage on attack rolls."
G["Troll Healing"] = "Hit dice you spend on a short rest heal their maximum instead of being rolled."
G["Troll Lineage"] = "Choose Amani, Darkspear or Zandalari. Each gives a small benefit tied to Heroic Inspiration or to moving through rough ground."
G["Fire Resistance"] = "Resistance to fire damage."
G["Nose for Trouble"] = "The first damage you take after rolling initiative is reduced by your level."
G["Vulpera Nimbleness"] = "You can move through the space of creatures larger than you."
G["Darkflight"] = "As a bonus action you take a bestial form for a minute: temporary hit points, more speed and other benefits. A few uses per long rest."
G["Instinctual Shift"] = "When you roll initiative you can use Darkflight at once, without spending an action."

---------------------------------------------------------------------------
-- Turning terms into hoverable text
---------------------------------------------------------------------------
-- `name` as a hover link if the glossary knows it, plain text otherwise. `label` is
-- the text to show when it differs from the name. Links only react inside widgets
-- that enable them (see UI/TermLabel.lua); elsewhere they read as normal text.
function ns.Term(name, label)
    label = label or name
    if not G[name] then return label end
    return ("|cffffd100|Hrpsheet:%s|h%s|h|r"):format(name, label)
end

-- A list of names as hover links, joined with `separator` (default ", ").
function ns.Terms(names, separator)
    local parts = {}
    for i, name in ipairs(names) do parts[i] = ns.Term(name) end
    return table.concat(parts, separator or ", ")
end
