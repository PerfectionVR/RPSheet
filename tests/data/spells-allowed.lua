-- Differences between the addon's spell facts and the rules site's that are meant.
-- ["<spell or list>|<field>"] = why, as tests/t-conform-spells.lua names them. An
-- entry that no longer matches a difference is reported, so the list stays true.
local A = {}
local function Allow(reason, keys)
    for key in keys:gmatch("[^;]+") do A[strtrim(key)] = reason end
end

-- Dice ---------------------------------------------------------------------------
Allow("the site's dice belong to something that happens later or to one option of the spell, not to the casting: the sheet rolls nothing and the summary names them",
    "Alter Self|dice; Blistering Scales|dice; Breath of Eons|dice; Combustion|dice; Dimension Door|dice; Ebon Might|dice; "
    .. "Enlarge/Reduce|dice; Entropic Embrace|dice; Meld into Stone|dice; Metamorphosis|dice; Teleport|dice; Web|dice; Wish|dice")
Allow("the die is the weapon's, which the sheet rolls with the weapon: the cantrip has no dice of its own", "Shillelagh|dice; Shillelagh|cantrip; True Strike|cantrip")
Allow("two damage parts of one hit are rolled together as one set of dice (Data/SpellsAzeroth.lua)", "Hand of Gul'dan|dice; Throw Glaive|dice")
Allow("three darts of 1d4 + 1 are rolled together as 3d4 + 3, and a higher slot adds a dart, held as one die and 1 more (Data/SlotGrowth.lua)", "Magic Missile|dice; Magic Missile|up")
Allow("the bonus grows in steps at 5th and 7th-level slots, held as upAt in Data/SlotGrowth.lua, not as dice per slot level", "Elemental Weapon|up")
Allow("the d12s against a wounded target are in the summary: the sheet rolls the d8s", "Toll the Dead|cantrip")
Allow("the modifier belongs to a part the sheet states and doesn't roll (the grasping hand, the healing light, the bolt on later turns)",
    "Bigby's Hand|modifier; Conjure Celestial|modifier; Void Eruption|modifier")

Allow("the other dice come on a later turn, or only against some targets or in some conditions: the casting rolls the first damage and the summary names the rest",
    "Call Lightning|other damage; Conjure Elemental|other damage; Death and Decay|other damage; Delayed Blast Fireball|other damage; "
    .. "Divine Smite|other damage; Emberstorm|other damage; Melf's Acid Arrow|other damage; Moonfire|other damage; Rain of Fire|other damage; "
    .. "Rune Strike|other damage; Serpent Sting|other damage; Sigil of Flame|other damage; Storm of Vengeance|other damage; "
    .. "Toll the Dead|other damage; Tsunami|other damage; Vitriolic Sphere|other damage; Void Eruption|other damage; Wall of Ice|other damage; "
    .. "Weird|other damage; Witch Bolt|other damage")
Allow("the other dice are another use of the spell (the grasping hand), stated with the higher slots in Data/SlotGrowth.lua", "Bigby's Hand|other damage")
Allow("a die that shows its highest number adds another die, which the player rolls by hand: the summary says so", "Sorcerous Burst|other damage; Soul Reap|other damage")

-- Attack or save -----------------------------------------------------------------
Allow("the sheet holds one roll for a spell: the one its first effect asks for; the others are in the summary",
    "Bigby's Hand|one roll; Ice Knife|one roll; Prismatic Spray|one roll; Prismatic Wall|one roll; "
    .. "Storm of Vengeance|one roll; Symbol|one roll; Synaptic Static|one roll; Void Eruption|one roll; Wall of Ice|one roll")

-- Components -----------------------------------------------------------------------
Allow("a holy symbol is an Amulet, Emblem or Reliquary on the gear list", "Bless|component name")
Allow("the site's divination tools are the sheet's divining tokens, the same thing Augury uses at a lower worth", "Find the Path|component name")
Allow("the component is a number of arrows or a coin, which the site gives no price for: the sheet still counts them", "Cordon of Arrows|component; Detect Thoughts|component")

-- Wards ----------------------------------------------------------------------------
Allow("the casting is instantaneous, the feast's benefits last 24 hours", "Heroes' Feast|ward hours")

-- Class lists ------------------------------------------------------------------------
Allow("OPEN, outside the spell data: a Death Knight shares the Paladin's list in the addon and so can pick the three spells the setting adds for Paladins; the site's Death Knight list leaves them out",
    "Death Knight list|Consecration; Death Knight list|Guided Prayer; Death Knight list|Divine Shield")
Allow("OPEN, outside the spell data: a Demon Hunter shares the Ranger's list in the addon and so can pick the three spells the setting adds for Hunters; the site's Demon Hunter list leaves them out",
    "Demon Hunter list|Freezing Trap; Demon Hunter list|Serpent Sting; Demon Hunter list|Explosive Trap")

-- Always prepared ----------------------------------------------------------------------
Allow("the spell is a class feature of its own on the sheet (an ability that casts it), not an entry of the spell list",
    "Druid prepared|Find Familiar")

return A
