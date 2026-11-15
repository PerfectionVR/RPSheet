-- Magic items that set an ability score or change how you move. A score or a walking
-- speed that is simply set is an effect the sheet counts (Data/EffectModes.lua); a
-- speed that has to be switched on, and swimming, climbing and flying speeds, which the
-- sheet doesn't keep, are told in the description. Descriptions are in our own words.
local _, ns = ...
local R = ns.Rules
local Magic = R.AddMagicItem

local ATTUNE = { attune = true }

-- "Your <ability> score is <score> while worn, unless it is that high already."
local function Sets(stat, score)
    return { { target = "SCORE:" .. stat, flat = score, stat = "", times = 1, mode = "MIN" } }
end

local function ScoreItem(name, rarity, stat, score, how, extra)
    Magic(name, rarity,
        ("%s, your %s score is %d. It does nothing for you if your own score is that high already."):format(how, R.STAT_NAMES[stat], score),
        Sets(stat, score), extra or ATTUNE)
end

ScoreItem("Amulet of Health", "Rare", "CON", 19, "While you wear it", { attune = true, weight = 1 })
ScoreItem("Gauntlets of Ogre Power", "Uncommon", "STR", 19, "While you wear them")
ScoreItem("Headband of Intellect", "Uncommon", "INT", 19, "While you wear it")

-- The belts, and the potions that do the same for a while: giant, rarity of the belt,
-- Strength score, rarity of the potion.
local GIANTS = {
    { "Hill", "Rare", 21, "Uncommon" }, { "Frost", "Very rare", 23, "Rare" }, { "Stone", "Very rare", 23, "Rare" },
    { "Fire", "Very rare", 25, "Rare" }, { "Cloud", "Legendary", 27, "Very rare" }, { "Storm", "Legendary", 29, "Legendary" },
}
for _, giant in ipairs(GIANTS) do
    local kind, rarity, score, potion = giant[1], giant[2], giant[3], giant[4]
    ScoreItem(("Belt of %s Giant Strength"):format(kind), rarity, "STR", score, "While you wear it")
    -- A potion is drunk, not worn, so the sheet can't count it: a passive of your own can.
    Magic(("Potion of %s Giant Strength"):format(kind), potion,
        ("Drinking it sets your Strength score to %d for a while, if your own is lower. The sheet doesn't count this by itself: add a passive that sets your Strength score and switch it on while the potion lasts."):format(score),
        nil, { weight = 0.5 })
end

-- Walking speed.
Magic("Boots of Striding and Springing", "Uncommon",
    "While you wear them your speed is 30 feet if it would be lower. Not counted: a heavy load or heavy armor no longer slows you, and once a turn you can jump up to 30 feet for 10 feet of movement.",
    { { target = "SPEED", flat = 30, stat = "", times = 1, mode = "MIN" } }, ATTUNE)
Magic("Boots of Speed", "Rare",
    "As a bonus action you click the heels to double your speed, and opportunity attacks against you have disadvantage, until you click them again; ten minutes of use in all between long rests. Not counted by itself: add a passive that multiplies your speed by 2 and switch it on while the boots are running.",
    nil, ATTUNE)

-- Other ways of moving: the sheet keeps one speed, so these only say what they give.
Magic("Ring of Swimming", "Uncommon", "While you wear it you have a swimming speed of 40 feet.")
Magic("Cloak of the Manta Ray", "Uncommon", "While you wear it you breathe underwater and have a swimming speed of 60 feet.", nil, ATTUNE)
Magic("Slippers of Spider Climbing", "Uncommon",
    "While you wear them you can walk up walls and across ceilings with your hands free, climbing as fast as you walk. They don't grip slippery surfaces such as ice or oil.",
    nil, ATTUNE)
Magic("Cloak of Arachnida", "Very rare",
    "While you wear it you resist poison damage, climb walls and ceilings as fast as you walk with your hands free, and webs can't catch you. It also holds a web spell.",
    nil, ATTUNE)
Magic("Winged Boots", "Uncommon",
    "Four charges, of which 1d4 come back each dawn. A Magic action and one charge give you a flying speed of 30 feet for an hour; when it runs out in the air you sink 30 feet a round.",
    nil, ATTUNE)
Magic("Wings of Flying", "Rare",
    "A Magic action turns this cloak into wings for an hour: a flying speed of 60 feet. When they vanish in the air you fall, and they can't be used again for 1d12 hours.",
    nil, ATTUNE)
Magic("Broom of Flying", "Uncommon",
    "Stand astride it and take a Magic action to ride it through the air at 50 feet, or 30 feet when it carries more than 200 pounds; 400 pounds is all it lifts.",
    nil, ATTUNE)
Magic("Cloak of the Bat", "Rare",
    "While you wear it you have advantage on Stealth checks. In dim light or darkness, holding its edges gives you a flying speed of 40 feet, and you can turn into a bat.",
    nil, ATTUNE)

-- From Azeroth.
Magic("Aviana's Feather", "Legendary",
    "A Magic action sprouts golden wings: a flying speed of 80 feet, and opportunity attacks against you have disadvantage when you fly out of reach. If you fall with the wings out you descend 60 feet a round.",
    nil, ATTUNE)
Magic("Experimental Goblin Jetpack", "Rare",
    "A Magic action fires its jets for an hour: a flying speed of 60 feet. When they stop in the air you fall, and they can't be used again for 1d12 hours.",
    nil, ATTUNE)
Magic("Life-Staff of the Web Lair", "Legendary",
    "A staff with 8 charges. While attuned you climb walls and ceilings as fast as you walk with your hands free, and webs don't hinder you; a charge casts a web from it (save DC 18).",
    nil, { attune = true, weight = 4 })
