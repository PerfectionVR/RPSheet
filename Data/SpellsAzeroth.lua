-- The spells of Azeroth: the ones the setting adds for its classes, on top of the
-- common spells in Data/Spells.lua. Summaries are short and in our own words.
--
-- R.SPELL_LISTS (by Player's Handbook class) gets the ones a class can prepare.
-- R.CLASS_SPELLS (by World of Warcraft class key) holds the spells a Death Knight's
-- and a Demon Hunter's subclass gives: those are always prepared, so they don't count
-- against the number of prepared spells.
local _, ns = ...
local R = ns.Rules
local Spell = R.DefineSpell

local HEAL = { dice = "HEALING" }
local HEAL_MOD = { dice = "HEALING", addMod = true }
local CONC = { concentration = true }
local function With(...)
    local merged = {}
    for _, extra in ipairs({ ... }) do
        for key, value in pairs(extra) do merged[key] = value end
    end
    return merged
end

-- Cleric (Priest)
Spell("Shadow Word: Pain", 1, "WIS", { 1, 10 }, "Psychic damage to a creature in range, plus your spellcasting modifier; half on a successful save. A creature that fails also takes 1d10 at the start of each of its turns for a minute.", { addMod = true, up = 1 })
Spell("Prayer of Mending", 3, nil, { 1, 8 }, "A ward on a willing creature: the next time it takes damage it regains hit points.", HEAL_MOD)
Spell("Holy Nova", 4, "CON", { 5, 6 }, "Holy light in a 30-foot burst around you: radiant damage to creatures you choose, half on a successful save. Other creatures you choose regain 3d6 hit points. Both grow by 1d6 for each slot level above 4th.", { up = 1 })
Spell("Psychic Horror", 4, "WIS", { 2, 10 }, "Visions of the Void: psychic damage, half on a successful save. A target that fails is frightened for a minute and stunned until the end of your next turn.")
Spell("Void Eruption", 5, "CON", { 5, 6 }, "Bonus action. Void energy bursts in a 20-foot sphere: necrotic damage, half on a successful save. While you concentrate, a bonus action hurls a bolt at a creature within 60 feet: a spell attack for 2d6 plus your spellcasting modifier.", CONC)
Spell("Apotheosis", 9, nil, nil, "Bonus action. You take a spectral, angelic form: a flying speed of 90 feet, damage resistances and stronger healing.")

-- Wizard (Mage)
Spell("Arcane Pulse", 0, "CON", { 1, 8 }, "A pulse of arcane force within 10 feet of you: force damage to creatures you choose on a failed save, and their speed drops by 10 feet until the end of your next turn. It does not grow with your level.")
Spell("Frost Nova", 1, "CON", { 2, 6 }, "A burst of frost within 15 feet of you: cold damage to creatures you choose, half on a successful save. Those who fail are also held in place.")
Spell("Flurry", 3, "ATTACK", { 3, 6 }, "Three shards of ice at one target or several, each with its own spell attack: click once per shard. A critical hit restrains the target.")
Spell("Combustion", 6, nil, nil, "You wreathe yourself in flames: immunity to fire damage and advantage on your spell attacks while it lasts. At the end of each of your turns, creatures you choose within 5 feet take 3d8 fire damage.")
Spell("Mass Polymorph", 9, "WIS", nil, "Creatures within 30 feet of you that fail the save are turned into identical beasts.", CONC)

-- Sorcerer (Evoker)
Spell("Azure Strike", 1, "ATTACK", { 2, 6 }, "Rays of force at up to two targets, each with its own spell attack: click once per ray. A hit also slows the target by 10 feet.")
Spell("Ebon Might", 1, nil, nil, "Creatures you choose within 10 feet of you are empowered until the end of your next turn: each of their hits deals 1d4 more force damage.")
Spell("Living Flame", 1, "ATTACK", { 2, 8 }, "Burn a creature: a spell attack for fire damage. Or heal a creature by 2d6 with no attack roll; the sheet rolls the attack, so roll the healing by hand.")
Spell("Dream Breath", 2, nil, { 2, 6 }, "Creatures you choose in a 15-foot cone regain hit points.", HEAL)
Spell("Eruption", 2, "DEX", { 3, 8 }, "Flames erupt in a 20-foot sphere: fire damage, half on a success.")
Spell("Blistering Scales", 3, nil, nil, "Bonus action. A willing creature gains +1 AC and five explosive scales: each deals 1d8 fire damage to a creature that hits it in melee.", CONC)
Spell("Emerald Blossom", 3, nil, nil, "Bonus action. A spectral bulb that heals creatures within 10 feet of it while it lasts.", CONC)
Spell("Breath of Eons", 4, nil, nil, "Bronze dragon magic: you fly 60 feet a turn without provoking opportunity attacks, and curse creatures you pass. A cursed creature takes 1d10 more force damage the next time it is damaged.", CONC)
Spell("Emberstorm", 4, "CON", { 6, 8 }, "White-hot embers fill a 20-foot sphere: fire damage, half on a success.")
Spell("Time Dilation", 4, nil, nil, "Reaction when a creature within 60 feet takes damage: it takes 4d8 less now and loses that many hit points over its next turns instead.")
Spell("Upheaval", 4, "DEX", { 3, 8 }, "Fiery stones erupt in a 20-foot cylinder: fire damage from the dice plus 1d12 bludgeoning damage, half on a successful save.")
Spell("Dream Flight", 5, nil, { 5, 4 }, "Green dragon magic: as you move past creatures you can heal them.", With(HEAL, CONC))
Spell("Rescue", 5, nil, nil, "Bonus action. You teleport, and one willing creature near where you were comes with you.")
Spell("Shattering Star", 5, "ATTACK", { 10, 8 }, "A bolt of concentrated force: on a hit the target also takes a -2 penalty to AC until your next turn.")
Spell("Azure Sweep", 6, "CON", { 7, 8 }, "Pure magic sweeps out 30 feet from you: force damage to creatures you choose, half on a successful save. Those who fail are slowed by 20 feet for a minute.")
Spell("Lay Waste", 7, "DEX", { 12, 6 }, "Molten cinders along a 120-foot line: fire damage, half on a success.")

-- Paladin
Spell("Consecration", 2, nil, { 1, 8 }, "The ground within 15 feet of you is consecrated: creatures you choose take radiant damage when they start their turn there.", CONC)
Spell("Guided Prayer", 3, nil, { 8, 4 }, "Reaction when you become Bloodied or are hurt while Bloodied: you regain hit points and have advantage on your next attack.", { dice = "SELFHEAL", addMod = true })
Spell("Divine Shield", 4, nil, nil, "Reaction when you take damage: you are immune to all damage until your next turn, and your speed can't be reduced.")

-- Warlock
Spell("Entropic Embrace", 1, nil, nil, "Reaction when both dice of a roll with advantage or disadvantage show the same number: you are cloaked in Void power for the duration. Once on each of your turns you deal 1d4 more necrotic damage, or heal 1d4 more; one more d4 for each slot level above 1st.")
Spell("Curse of Agony", 2, "CON", { 1, 4 }, "A curse of growing pain: the target takes the psychic damage whether it passes or fails. A success ends the curse; each failure makes the die one size larger, up to a d12.")
Spell("Hand of Gul'dan", 3, "DEX", { 4, 8 }, "A demonic meteor bursts in a 20-foot sphere: 2d8 fire and 2d8 necrotic damage, rolled together, half on a successful save. A creature that enters the area or ends its turn there later takes 1d8 of each.", CONC)
Spell("Rain of Fire", 3, "DEX", { 3, 8 }, "Hellfire rains into a 20-foot cylinder that you can move on later turns: fire damage, half on a successful save. Your spell attacks against creatures inside have advantage and deal 1d6 more necrotic damage.", CONC)

-- Ranger (Hunter)
Spell("Freezing Trap", 1, "CON", nil, "An unseen trap on the ground: the first creature to come within 5 feet is frozen in place if it fails the save, for a minute or until it takes damage.", CONC)
Spell("Serpent Sting", 3, nil, { 4, 6 }, "Bonus action after a weapon hit: extra poison damage, and the target is poisoned for a minute. At the end of each of its turns it makes a Constitution save: 2d6 more poison on a failure, the end of the spell on a success.")
Spell("Explosive Trap", 5, "DEX", { 8, 6 }, "An unseen trap on the ground: it explodes in a 20-foot sphere when a creature comes close. Fire damage on a failed save, none on a success, and a Huge or smaller creature that fails is thrown 20 feet.", CONC)

-- Druid
Spell("Wrath", 0, "ATTACK", { 1, 8 }, "A ball of energy: lightning damage, and the target's speed drops by 10 feet until the end of your next turn.")
Spell("Moonfire", 1, "DEX", { 2, 8 }, "Bonus action. A beam of moonlight: radiant damage, half on a successful save. A target that fails glows, can't hide, and takes 1d8 more at the end of its next turn.", { up = 1 })
Spell("Feral Prowl", 2, nil, nil, "Bonus action. You shape-shift without spending Wild Shape and are invisible until you attack or cast.")
Spell("Roar of Ursoc", 2, nil, nil, "Bonus action. You shape-shift without spending Wild Shape, and creatures that start their turn next to you have disadvantage on attacks against anyone but you until your next turn.")
Spell("Regrowth", 3, nil, { 3, 8 }, "A creature regains hit points now, and 1d8 more at the start of each of your turns while it lasts.", With(HEAL, CONC))
Spell("Starfall", 4, "DEX", { 7, 8 }, "Falling stars fill a 30-foot cylinder: radiant damage, half on a success.")
Spell("Innervate", 5, nil, nil, "A creature gains a 4th-level spell slot, which lasts until it is used or the creature finishes a long rest. You regain one use of Wild Shape.")
Spell("Tranquility", 6, nil, { 2, 8 }, "Bonus action each turn while it lasts. Within 60 feet of you, creatures you choose resist bludgeoning, piercing and slashing damage and are healed by the roll.", With(HEAL_MOD, CONC, { up = 1 }))
Spell("Tree of Life", 8, nil, nil, "Bonus action. You take the form of a great tree: slow but steadfast, with much stronger healing.")

-- Death Knight (from the Oath of the Ebon Blade)
Spell("Chains of Ice", 1, "DEX", { 1, 10 }, "Icy chains bind a creature: cold damage, half on a successful save. A failure also halves its speed.")
Spell("Death Grip", 1, "STR", nil, "Bonus action. A creature that fails the save is pulled to within 5 feet of you.")
Spell("Rune Strike", 1, nil, { 2, 8 }, "Bonus action after a melee hit: extra necrotic damage, one die more against a celestial.")
Spell("Scourge Strike", 1, "CON", { 2, 6 }, "Bonus action after a melee hit: extra necrotic damage, and the target is poisoned if it fails the save.")
Spell("Vampiric Blood", 1, nil, nil, "Your maximum hit points rise by 10, and you regain 1d6 more whenever you are healed.", CONC)
Spell("Death and Decay", 2, "WIS", { 2, 6 }, "Corruption spreads in a 20-foot sphere on the ground: necrotic damage, half on a successful save. A creature that fails is cursed until the end of your next turn: your attacks deal 1d6 more necrotic damage to it.")
Spell("Frostscythe", 2, "CON", { 3, 8 }, "A sweep of icy cold in a 20-foot cone: cold damage, half on a successful save. A failure also slows the creature by 10 feet for a minute.")
Spell("Leeching Strike", 3, nil, { 3, 8 }, "Bonus action after a melee hit: extra necrotic damage, and you regain 3d4 hit points.")
Spell("Remorseless Winter", 3, "CON", { 6, 6 }, "You drain the warmth within 30 feet of you: cold damage to creatures you choose, half on a success.")
Spell("Bonestorm", 5, "CON", { 4, 8 }, "A whirl of bone around you: creatures within 10 feet take necrotic damage, half on a successful save, and you regain 4d6 hit points; raise your bar by that roll by hand.")

-- Demon Hunter (from the Demon Hunter subclass)
Spell("Consume Soul", 1, "CON", { 4, 4 }, "You drain a creature's essence: force damage, half on a successful save, and you gain half of what it takes as temporary hit points.")
Spell("Fel Rush", 1, "DEX", { 2, 6 }, "Your speed rises by 30 feet for the turn without provoking opportunity attacks, and creatures you rush past take fire damage, half on a successful save.")
Spell("Infernal Strike", 1, "DEX", { 2, 6 }, "You leap up to 30 feet and land in fire: creatures within 10 feet take fire damage, half on a successful save.")
Spell("Throw Glaive", 1, "ATTACK", { 2, 8 }, "A demonic warglaive: slashing and fire damage on a hit, and it ricochets onward.")
Spell("Eye Beam", 2, "DEX", { 3, 6 }, "A burst of fel magic in a 15-foot cone, now and as an action on later turns: force damage, half on a successful save.", CONC)
Spell("Fiery Brand", 2, "WIS", { 3, 10 }, "A burning symbol on a creature: fire damage, half on a successful save. A failure also curses it, weakening what it does to you.")
Spell("Sigil of Flame", 2, "CON", { 2, 8 }, "A sigil appears on a creature: fire damage, half on a success.")
Spell("Demon Spikes", 3, nil, nil, "Bonus action. +2 AC, and a creature within 5 feet that hits you in melee takes 10 piercing damage.")
Spell("Metamorphosis", 3, nil, nil, "Bonus action. You take on demonic features and choose one benefit: your force damage dice that show a 1 or 2 count as a 3; your melee weapon hits deal 1d6 more fire damage; or +2 Armor Class and 5 more current and maximum hit points.")
Spell("Soul Reap", 3, "ATTACK", { 6, 6 }, "A bolt of cosmic matter that ignores cover: force damage on a hit.")
Spell("Chaos Nova", 4, "WIS", { 2, 6 }, "Chaos bursts within 20 feet of you: creatures you choose take the force damage, and those who fail the save are also stunned.")
Spell("Collapsing Star", 4, "CON", { 4, 12 }, "A blast of Void energy in a 20-foot sphere: force damage to creatures you choose, half on a successful save.")
Spell("Sigil of Chains", 5, "DEX", { 5, 6 }, "A sigil erupts in a 20-foot sphere: force damage, half on a successful save, and those who fail are dragged toward its centre.")

local function Add(list, names)
    for _, name in ipairs(names) do list[#list + 1] = name end
end
Add(R.SPELL_LISTS.Cleric, { "Shadow Word: Pain", "Prayer of Mending", "Holy Nova", "Psychic Horror", "Void Eruption", "Apotheosis" })
Add(R.SPELL_LISTS.Wizard, { "Arcane Pulse", "Frost Nova", "Flurry", "Combustion", "Mass Polymorph" })
Add(R.SPELL_LISTS.Sorcerer, {
    "Azure Strike", "Ebon Might", "Living Flame", "Dream Breath", "Eruption", "Blistering Scales", "Emerald Blossom",
    "Breath of Eons", "Emberstorm", "Time Dilation", "Upheaval", "Dream Flight", "Rescue", "Shattering Star", "Azure Sweep", "Lay Waste",
})
Add(R.SPELL_LISTS.Paladin, { "Consecration", "Guided Prayer", "Divine Shield" })
Add(R.SPELL_LISTS.Warlock, { "Entropic Embrace", "Curse of Agony", "Hand of Gul'dan", "Rain of Fire" })
Add(R.SPELL_LISTS.Ranger, { "Freezing Trap", "Serpent Sting", "Explosive Trap" })
Add(R.SPELL_LISTS.Druid, { "Wrath", "Moonfire", "Feral Prowl", "Roar of Ursoc", "Regrowth", "Starfall", "Innervate", "Tranquility", "Tree of Life" })

R.CLASS_SPELLS = {
    DEATHKNIGHT = {
        "Chains of Ice", "Death Grip", "Rune Strike", "Scourge Strike", "Vampiric Blood", "Death and Decay", "Frostscythe",
        "Leeching Strike", "Remorseless Winter", "Bonestorm",
    },
    DEMONHUNTER = {
        "Consume Soul", "Fel Rush", "Infernal Strike", "Throw Glaive", "Eye Beam", "Fiery Brand", "Sigil of Flame", "Demon Spikes",
        "Metamorphosis", "Soul Reap", "Chaos Nova", "Collapsing Star", "Sigil of Chains",
    },
}
