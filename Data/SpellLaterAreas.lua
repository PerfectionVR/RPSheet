-- Spells that fill an area, a wall or an aura, and harm the creatures that enter it or
-- stay in it on later turns (how an entry is written: Data/SpellLater.lua).
local _, ns = ...
local R = ns.Rules
local L, Same, Dice = R.SPELL_LATER, R.LaterSame, R.LaterDice

-- quiet: nothing is harmed when it appears, only later.
local ENTERS = "a creature enters it or ends its turn there"

for _, name in ipairs({ "Cloudkill", "Insect Plague", "Incendiary Cloud", "Wall of Fire", "Blade Barrier",
    "Evard's Black Tentacles", "Jallarzi's Storm of Radiance" }) do
    L[name] = { hours = 0, rolls = { Same(ENTERS) } }
end
L["Wall of Thorns"] = { hours = 0, rolls = { Same(ENTERS .. " (slashing)") } }
L["Wall of Ice"] = { hours = 0, rolls = { Dice("a creature passes through the frigid air", 5, 6, "cold damage", { save = "CON", up = 1 }) } }
-- A higher slot strengthens the cold or the acid, as chosen when it is cast.
L["Hunger of Hadar"] = { hours = 0, quiet = true, rolls = {
    Dice("a creature starts its turn inside", 2, 6, "cold damage", { below = true }),
    Dice("a creature ends its turn inside", 2, 6, "acid damage", { save = "DEX", below = true }),
    Dice("a creature starts its turn inside (cold chosen)", 2, 6, "cold damage", { up = 1, above = true }),
    Dice("a creature starts its turn inside (acid chosen)", 2, 6, "cold damage", { above = true }),
    Dice("a creature ends its turn inside (acid chosen)", 2, 6, "acid damage", { save = "DEX", up = 1, above = true }),
    Dice("a creature ends its turn inside (cold chosen)", 2, 6, "acid damage", { save = "DEX", above = true }) } }
L["Consecration"] = { hours = 0, quiet = true, rolls = { Same("a creature you chose starts its turn there") } }
L["Conjure Animals"] = { hours = 0, rolls = { Same("the pack comes near a creature, or it enters or ends its turn near") } }
L["Conjure Woodland Beings"] = { hours = 0, rolls = { Same("the aura reaches a creature, or it enters or ends its turn there") } }
L["Conjure Elemental"] = { hours = 0, rolls = { Same("a creature enters its space or starts its turn beside it"),
    Dice("the restrained creature fails its save again", 4, 8, "damage of the spirit's kind", { save = "DEX", up = 1 }) } }
L["Yolande's Regal Presence"] = { hours = 0, rolls = { Same("the aura reaches a creature, or it enters or ends its turn there") } }
L["Mordenkainen's Faithful Hound"] = { hours = 8, quiet = true, rolls = { Same("the hound bites at the start of your turn") } }
L["Cordon of Arrows"] = { hours = 8, quiet = true, rolls = { Same("a piece flies at a creature") } }
L["Earthquake"] = { hours = 0, rolls = { Same("a structure collapses near a creature") } }
L["Spike Growth"] = { hours = 0, quiet = true, rolls = { Same("each 5 feet a creature moves there") } }
L["Hand of Gul'dan"] = { hours = 0, rolls = { Dice(ENTERS, 1, 8, "fire damage", { save = "DEX", also = { count = 1, sides = 8, word = "necrotic damage" } }) } }
L["Storm of Vengeance"] = { hours = 0, sequence = true, rolls = {
    Dice("your second turn: acid rain", 4, 6, "acid damage"),
    Dice("your third turn: lightning bolts", 10, 6, "lightning damage", { save = "DEX" }),
    Dice("your fourth turn: hail", 2, 6, "bludgeoning damage"),
    Dice("your fifth to tenth turn: freezing wind", 1, 6, "cold damage") } }
-- The wave weakens each round: one die fewer each time it moves.
L["Tsunami"] = { hours = 0, sequence = true, rolls = {
    Dice("the wall moves (first time)", 5, 10, "bludgeoning damage", { save = "STR" }),
    Dice("the wall moves (second time)", 4, 10, "bludgeoning damage", { save = "STR" }),
    Dice("the wall moves (third time)", 3, 10, "bludgeoning damage", { save = "STR" }),
    Dice("the wall moves (fourth time)", 2, 10, "bludgeoning damage", { save = "STR" }),
    Dice("the wall moves (fifth time)", 1, 10, "bludgeoning damage", { save = "STR" }) } }
