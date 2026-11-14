-- What a higher spell slot changes about a spell, besides more dice of its own kind
-- (`up` on the spell) and more separate attacks (`hitsUp`). Kept by spell name, so it
-- also holds for spells already saved on a character (see Actions/SlotGrowth.lua).
--
-- R.SLOT_GROWTH[<spell name>] = {
--   up, hitsUp   set on the listed spell: dice or attacks added per slot level
--   flat         a fixed number added to the dice at any slot; flatUp: more of it per slot level
--   upAt         { [slot level] = dice added from that slot level on } for steps
--   also         a second roll one casting makes: { count, sides, up, kind, word }
--   at           { [slot level] = what holds from that slot level on }, not rolled
--   noConc       the slot level from which it needs no concentration
--   refresh      saved copies take the listed dice and summary (it rolls more than it did)
--   1, 2, ...    amounts that are stated, not rolled: { base, per, text, every }; the
--                text gets  base + per x slot levels above the spell's own  (counted
--                in steps of `every` levels). No base means the spell's own level.
-- }
local _, ns = ...
local R = ns.Rules

local G = {}
R.SLOT_GROWTH = G

local function Amount(base, per, text, every)
    return { base = base, per = per, text = text, every = every }
end
local function Each(names, make)
    for name in names:gmatch("[^|]+") do G[name] = make() end
end

-- More targets -------------------------------------------------------------
Each("Animal Friendship|Banishment|Blindness/Deafness|Charm Monster|Charm Person|Command|Enhance Ability|Fly|Freedom of Movement|Gaseous Form|Heroism|Hold Monster|Hold Person|Invisibility|Jump|Longstrider|Spider Climb|Tasha's Hideous Laughter",
    function() return { Amount(1, 1, "targets: %d") } end)
Each("Bane|Bless", function() return { Amount(3, 1, "targets: %d") } end)
G["Living Flame"] = { Amount(1, 1, "targets: %d", 2) }
G["Etherealness"] = { Amount(0, 3, "willing creatures it can take, you included: %d") }
G["Animate Dead"] = { Amount(1, 2, "undead raised or kept: %d") }
G["Chain Lightning"] = { Amount(3, 1, "leaping bolts: %d") }
G["Grasping Vine"] = { Amount(1, 1, "creatures it can hold: %d") }
G["Cordon of Arrows"] = { Amount(4, 2, "arrows or bolts: %d") }
G["Blistering Scales"] = { Amount(5, 1, "scales: %d") }
G["Prayer of Mending"] = { Amount(5, 1, "times it can heal: %d") }

-- A fixed number per slot level -------------------------------------------
G["Aid"] = { Amount(5, 5, "hit points each target gains: %d") }
G["Armor of Agathys"] = { Amount(5, 5, "temporary hit points, and cold damage to those who hit you: %d") }
G["Heal"] = { Amount(70, 10, "hit points restored: %d") }
G["Emerald Blossom"] = { Amount(20, 5, "hit points it can restore in all: %d") }
G["Arcane Vigor"] = { Amount(2, 1, "hit dice you may roll: %d") }
G["False Life"] = { flat = 4, flatUp = 5, refresh = true }
G["Magic Missile"] = { flat = 3, flatUp = 1, refresh = true } -- 1 for each dart
G["Disintegrate"] = { flat = 40 }

-- A longer duration or a larger area --------------------------------------
G["Animal Messenger"] = { Amount(24, 48, "hours it lasts: %d") }
G["Magic Circle"] = { Amount(1, 1, "hours it lasts: %d") }
G["Fog Cloud"] = { Amount(20, 20, "radius in feet: %d") }
G["Confusion"] = { Amount(10, 5, "radius in feet: %d") }
G["Creation"] = { Amount(5, 5, "largest cube, feet on a side: %d") }
G["Mordenkainen's Private Sanctum"] = { Amount(100, 100, "largest cube, feet on a side: %d") }
G["Create or Destroy Water"] = { Amount(10, 10, "gallons: %d"), Amount(30, 5, "or a cube, feet on a side: %d") }
G["Globe of Invulnerability"] = { Amount(5, 1, "blocks spells up to level %d") }

-- What follows the slot's level -------------------------------------------
Each("Summon Aberration|Summon Beast|Summon Celestial|Summon Construct|Summon Dragon|Summon Elemental|Summon Fey|Summon Fiend|Summon Undead|Find Steed|Giant Insect",
    function() return { Amount(nil, 1, "the creature's numbers use spell level %d") } end)
G["Dispel Magic"] = { Amount(nil, 1, "ends spells up to level %d outright") }
G["Glyph of Warding"] = { Amount(nil, 1, "a spell glyph can hold a spell up to level %d") }
G["Chromatic Orb"] = { Amount(nil, 1, "most leaps: %d") }
G["Throw Glaive"] = { up = 1, Amount(nil, 1, "most ricochets: %d") }

-- Steps at certain slot levels --------------------------------------------
G["Hex"] = { at = { [2] = "concentration can last 4 hours", [3] = "concentration can last 8 hours", [5] = "concentration can last 24 hours" } }
G["Hunter's Mark"] = { at = { [3] = "concentration can last 8 hours", [5] = "concentration can last 24 hours" } }
G["Bestow Curse"] = { noConc = 5, at = {
    [4] = "concentration can last 10 minutes", [5] = "lasts 8 hours without concentration",
    [7] = "lasts 24 hours without concentration", [9] = "lasts until dispelled, without concentration",
} }
G["Major Image"] = { noConc = 4, at = { [4] = "lasts until dispelled, without concentration" } }
G["Dominate Beast"] = { at = { [5] = "concentration can last 10 minutes", [6] = "concentration can last 1 hour", [7] = "concentration can last 8 hours" } }
G["Dominate Person"] = { at = { [6] = "concentration can last 10 minutes", [7] = "concentration can last 1 hour", [8] = "concentration can last 8 hours" } }
G["Dominate Monster"] = { at = { [9] = "concentration can last 8 hours" } }
G["Geas"] = { at = { [7] = "lasts a year", [9] = "lasts until another spell ends it" } }
G["Mass Suggestion"] = { at = { [7] = "lasts 10 days", [8] = "lasts 30 days", [9] = "lasts a year and a day" } }
G["Planar Binding"] = { at = { [6] = "lasts 10 days", [7] = "lasts 30 days", [8] = "lasts 180 days", [9] = "lasts a year and a day" } }
G["Modify Memory"] = { at = {
    [6] = "reaches memories up to 7 days old", [7] = "reaches memories up to 30 days old",
    [8] = "reaches memories up to a year old", [9] = "reaches any memory",
} }
G["Magic Weapon"] = { at = { [3] = "the bonus is +2", [6] = "the bonus is +3" } }
G["Elemental Weapon"] = { upAt = { [5] = 1, [7] = 2 }, at = {
    [5] = "+2 to attack rolls, 2d4 extra damage", [7] = "+3 to attack rolls, 3d4 extra damage",
} }
G["Create Undead"] = { at = {
    [7] = "four ghouls", [8] = "five ghouls, or two ghasts or wights",
    [9] = "six ghouls, three ghasts or wights, or two mummies",
} }

-- A second part with its own dice -----------------------------------------
-- Rolled along with the spell:
G["Ice Knife"] = { also = { count = 2, sides = 6, up = 1, kind = "DAMAGE", word = "cold damage in the burst" } }
G["Flame Strike"] = { also = { count = 5, sides = 6, up = 1, kind = "DAMAGE", word = "radiant damage" } }
G["Jallarzi's Storm of Radiance"] = { also = { count = 2, sides = 10, up = 1, kind = "DAMAGE", word = "thunder damage" } }
G["Lightning Arrow"] = { also = { count = 2, sides = 8, up = 1, kind = "DAMAGE", word = "lightning damage to those nearby" } }
G["Upheaval"] = { also = { count = 1, sides = 12, up = 1, kind = "DAMAGE", word = "bludgeoning damage" } }
G["Holy Nova"] = { also = { count = 3, sides = 6, up = 1, kind = "HEALING", word = "healing for the others" } }
G["Leeching Strike"] = { up = 1, also = { count = 3, sides = 4, up = 1, kind = "SELFHEAL", word = "healing" } }
-- Stated only: it comes on a later turn or is one of several choices.
G["Melf's Acid Arrow"] = { Amount(2, 1, "the later damage is %dd4") }
G["Searing Smite"] = { Amount(1, 1, "the burning each turn is %dd6") }
G["Moonfire"] = { Amount(1, 1, "the later damage is %dd8") }
G["Sigil of Flame"] = { up = 1, Amount(1, 1, "the later damage is %dd8") }
G["Bigby's Hand"] = { Amount(4, 2, "the grasping hand crushes for %dd6") }
G["Wall of Ice"] = { Amount(5, 1, "passing through the cold air deals %dd6") }
G["Animate Objects"] = { Amount(0, 1, "slam damage dice added (d4, d6 or d12 by size): %d") }
G["Entropic Embrace"] = { Amount(1, 1, "the extra damage or healing is %dd4") }
G["Vampiric Blood"] = { Amount(1, 1, "the extra healing is %dd6") }

-- Azeroth's spells that add dice of their own kind, or attacks --------------
Each("Azure Strike|Chains of Ice|Consume Soul|Emberstorm|Eruption|Eye Beam|Fel Rush|Frost Nova|Frostscythe|Infernal Strike|Psychic Horror|Rain of Fire|Remorseless Winter|Rune Strike|Scourge Strike|Shattering Star|Soul Reap",
    function() return { up = 1 } end)
G["Dream Breath"] = { up = 2 }
G["Flurry"] = { hitsUp = 1 }

-- The dice and attacks go onto the listed spells, where the rest of the sheet reads them.
for name, facts in pairs(G) do
    local spell = R.SPELLS[name]
    if spell then
        if facts.up then spell.up = facts.up end
        if facts.hitsUp then spell.hitsUp = facts.hitsUp end
    end
end
