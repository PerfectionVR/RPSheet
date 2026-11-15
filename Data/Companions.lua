-- Companion creatures: small creatures bound to a character that follow it around.
-- They don't fight or carry; a loyal one gives its owner a small gift while it is out.
-- (A Beast Master's animal companion is something else: Data/Pets.lua.)
local _, ns = ...
local R = ns.Rules

R.LOYALTY_GIFT = 10    -- Loyalty Score from which a companion gives its gift
R.LOYALTY_TREAT = 4    -- die rolled when it is treated particularly well
R.LOYALTY_MAX = 30     -- the highest Charisma score there is

R.COMPANION_HELP = "Calling or dismissing a companion takes a Magic action, and only one can be out at a time. It stays within 5 feet of you, can't act and can't be attacked. If it takes any damage it is gone until you call it again, and loses 1 loyalty."
R.LOYALTY_HELP = ("Loyalty starts at your Charisma modifier (at least 1) and can't go above your Charisma score. It goes up by 1d%d when the companion is treated particularly well, which the DM decides. At %d or more the companion gives its gift while it is out."):format(R.LOYALTY_TREAT, R.LOYALTY_GIFT)

-- R.COMPANIONS[family] = { desc, gift, and what the sheet counts of the gift:
--   skills   skills the gift makes you an expert in
--   speed    feet it adds to your own speed
--   moves    { swim = true }: a speed of that kind equal to your walking speed
--   advantage  rolls it gives advantage on, by their label (Sheet/RollModes.lua)
--   ward     { type = "psychic", sides = 4 }: a die rolled and taken off damage of
--            that type whenever you take it (Actions/Damage.lua)
-- A gift that depends on what a save is against is in Data/SaveAdvantages.lua.
R.COMPANIONS = {
    Aquatic = { desc = "Fish, crabs, frogs, turtles, otters and other water creatures, sometimes floating along in a bubble of water.",
        gift = "You have a swim speed equal to your speed.", moves = { swim = true } },
    Beast = { desc = "Small natural animals that neither fly nor swim, and the young of larger ones. They don't age while kept.",
        gift = "You have proficiency and expertise in Animal Handling and Survival.", skills = { "Animal Handling", "Survival" } },
    Dragonkin = { desc = "Tiny dragon whelplings and the draconic animals of the Dragon Isles.",
        gift = "You have advantage on saving throws to avoid or end being Frightened. The sheet asks what a save is against when you roll one." },
    Elemental = { desc = "Living motes of elemental energy, animate plants, and leftovers of older powers.",
        gift = "You have advantage on saving throws to avoid or end Exhaustion. The sheet asks what a save is against when you roll one." },
    Flying = { desc = "Birds, bats, moths, bees, flying snakes and magical versions of them.",
        gift = "Your speed is 5 feet higher.", speed = 5 },
    Humanoid = { desc = "Imps, kobolds, baby murlocs and other small folk that help in ways that aren't fighting. The DM may play one as a character of its own.",
        gift = "You have proficiency and expertise in Persuasion.", skills = { "Persuasion" } },
    Magic = { desc = "Beings of magic through and through: oozes, stray eyes and tentacles, Void creatures, ghostly spirits, animated tomes.",
        gift = "You have proficiency and expertise in Arcana.", skills = { "Arcana" } },
    Mechanical = { desc = "Clockwork and engineered creatures, from mechanical chickens to toy war machines. They are switched off and stowed, not sent away.",
        gift = "Whenever you take psychic damage, roll 1d4 and take that much less.", ward = { type = "psychic", sides = 4 } },
    Undead = { desc = "Skeletal or ghostly animals and the like.",
        gift = "You have advantage on death saving throws.", advantage = { "death save roll" } },
}
R.COMPANION_ORDER = { "Aquatic", "Beast", "Dragonkin", "Elemental", "Flying", "Humanoid", "Magic", "Mechanical", "Undead" }

-- The stable lists one of each family to take; where it comes from and what it costs
-- is up to the DM (a few gold from a merchant, a reward, a find).
for _, family in ipairs(R.COMPANION_ORDER) do
    R.AddMount("Companions", family .. " companion", { family = family, desc = R.COMPANIONS[family].desc })
end
