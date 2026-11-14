-- The core rules' spells of levels 1 to 9 as bare facts, so they can be added to a
-- sheet with the right level, save or attack, and dice. A spell that Spells.lua
-- already describes by hand keeps that entry. The summary of each is put together
-- from the facts below.
--
-- One spell per line:
--   name | level | school | save ability or ATTACK | dice | damage type, "heal" or
--   "heal+" (adds the spellcasting modifier) | range | c = concentration, r = ritual
--   | dice added per slot level above its own | classes
-- Classes: C Cleric, D Druid, P Paladin, R Ranger, S Sorcerer, K Warlock, W Wizard.
local _, ns = ...
local R = ns.Rules

local SCHOOLS = {
    A = "Abjuration", C = "Conjuration", D = "Divination", E = "Enchantment",
    V = "Evocation", I = "Illusion", N = "Necromancy", T = "Transmutation",
}
local CLASSES = { C = "Cleric", D = "Druid", P = "Paladin", R = "Ranger", S = "Sorcerer", K = "Warlock", W = "Wizard" }

local DATA = [[
Alarm|1|A||||30 ft|r||RW
Animal Friendship|1|E|WIS|||30 ft|||DR
Armor of Agathys|1|A||||Self|||K
Arms of Hadar|1|C|STR|2d6|necrotic|Self, 10-ft emanation||1d6|K
Bane|1|E|CHA|||30 ft|c||CK
Bless|1|E||||30 ft|c||CP
Burning Hands|1|V|DEX|3d6|fire|Self, 15-ft cone||1d6|SW
Charm Person|1|E|WIS|||30 ft|||DSKW
Chromatic Orb|1|V|ATTACK|3d8||90 ft||1d8|SW
Color Spray|1|I|CON|||Self, 15-ft cone|||SW
Command|1|E|WIS|||60 ft|||CP
Compelled Duel|1|E|WIS|||30 ft|c||P
Comprehend Languages|1|D||||Self|r||SKW
Create or Destroy Water|1|T||||30 ft|||CD
Cure Wounds|1|A||2d8|heal+|Touch||2d8|CDRP
Detect Evil and Good|1|D||||Self, 30-ft sphere|c||CP
Detect Magic|1|D||||Self, 30-ft sphere|cr||CDRSKWP
Detect Poison and Disease|1|D||||Self, 30-ft sphere|cr||CDRP
Disguise Self|1|I||||Self|||SW
Dissonant Whispers|1|E|WIS|3d6|psychic|60 ft||1d6|
Divine Favor|1|T||1d4|radiant|Self|||P
Divine Smite|1|V||2d8|radiant|Self||1d8|P
Ensnaring Strike|1|C|STR|1d6|piercing|Self|c|1d6|R
Entangle|1|C|STR|||90 ft|c||DR
Expeditious Retreat|1|T||||Self|c||SKW
Faerie Fire|1|V|DEX|||60 ft|c||D
False Life|1|N||||Self|||SW
Feather Fall|1|T||||60 ft|||SW
Find Familiar|1|C||||10 ft|r||W
Fog Cloud|1|C||||120 ft|c||DRSW
Goodberry|1|C||||Touch|||DR
Grease|1|C|DEX|||60 ft|||SW
Guiding Bolt|1|V|ATTACK|4d6|radiant|120 ft||1d6|C
Hail of Thorns|1|C|DEX|1d10|piercing|Self||1d10|R
Healing Word|1|A||2d4|heal+|60 ft||2d4|CD
Hellish Rebuke|1|V|DEX|2d10|fire|60 ft||1d10|K
Heroism|1|E||||Touch|c||P
Hex|1|E||1d6|necrotic|90 ft|c||K
Hunter's Mark|1|D||1d6|force|90 ft|c||R
Ice Knife|1|C|ATTACK|1d10||60 ft||1d6|DSW
Identify|1|D||||Touch|r||W
Illusory Script|1|I||||Touch|r||KW
Inflict Wounds|1|N|CON|2d10|necrotic|Touch||1d10|C
Jump|1|T||||Touch|||DRSW
Longstrider|1|T||||Touch|||DRW
Mage Armor|1|A||||Touch|||SW
Magic Missile|1|V||1d4|force|120 ft|||SW
Protection from Evil and Good|1|A||||Touch|c||CDKWP
Purify Food and Drink|1|T||||10 ft|r||CDP
Ray of Sickness|1|N|ATTACK|2d8|poison|60 ft||1d8|SW
Sanctuary|1|A|WIS|||30 ft|||C
Searing Smite|1|V|CON|1d6|fire|Self||1d6|P
Shield|1|A||||Self|||SW
Shield of Faith|1|A||||60 ft|c||CP
Silent Image|1|I||||60 ft|c||SW
Sleep|1|E|WIS|||60 ft|c||SW
Speak with Animals|1|D||||Self|r||DRK
Tasha's Hideous Laughter|1|E|WIS|||30 ft|c||KW
Tenser's Floating Disk|1|C||||30 ft|r||W
Thunderous Smite|1|V|STR|2d6|thunder|Self||1d6|P
Thunderwave|1|V|CON|2d8|thunder|Self, 15-ft cube||1d8|DSW
Unseen Servant|1|C||||60 ft|r||KW
Witch Bolt|1|V|ATTACK|2d12|lightning|60 ft|c|1d12|SKW
Wrathful Smite|1|N|WIS|1d6|necrotic|Self||1d6|P
Aid|2|A||||30 ft|||CDRP
Alter Self|2|T||||Self|c||SW
Animal Messenger|2|E|CHA|||30 ft|r||DR
Arcane Lock|2|A||||Touch|||W
Arcane Vigor|2|A||||Self|||SW
Augury|2|D||||Self|r||CDW
Barkskin|2|T||||Touch|||DR
Beast Sense|2|D||||Touch|cr||DR
Blindness/Deafness|2|T|CON|||120 ft|||CSW
Blur|2|I||||Self|c||SW
Calm Emotions|2|E|CHA|||60 ft|c||C
Cloud of Daggers|2|C||4d4|slashing|60 ft|c|2d4|SKW
Continual Flame|2|V||||Touch|||CDW
Cordon of Arrows|2|T|DEX|2d4|piercing|Touch|||R
Crown of Madness|2|E|WIS|||120 ft|c||SKW
Darkness|2|V||||60 ft|c||SKW
Darkvision|2|T||||Touch|||DRSW
Detect Thoughts|2|D|WIS|||Self|c||SW
Dragon's Breath|2|T|DEX|3d6||Touch|c|1d6|SW
Enhance Ability|2|T||||Touch|c||CDRSW
Enlarge/Reduce|2|T|CON|||30 ft|c||DSW
Enthrall|2|E|WIS|||60 ft|c||K
Find Steed|2|C||||30 ft|||P
Find Traps|2|D||||120 ft|||CDR
Flame Blade|2|V|ATTACK|3d6|fire|Self|c|1d6|DS
Flaming Sphere|2|V|DEX|2d6|fire|60 ft|c|1d6|DSW
Gentle Repose|2|N||||Touch|r||CWP
Gust of Wind|2|V|STR|||Self, 60-ft line|c||DRSW
Heat Metal|2|T|CON|2d8|fire|60 ft|c|1d8|D
Hold Person|2|E|WIS|||60 ft|c||CDSKW
Invisibility|2|I||||Touch|c||SKW
Knock|2|T||||60 ft|||SW
Lesser Restoration|2|A||||Touch|||CDRP
Levitate|2|T|CON|||60 ft|c||SW
Locate Animals or Plants|2|D||||Self|r||DR
Locate Object|2|D||||Self|c||CDRWP
Magic Mouth|2|I||||30 ft|r||W
Magic Weapon|2|T||||Touch|||RSWP
Melf's Acid Arrow|2|V|ATTACK|4d4|acid|90 ft||1d4|W
Mind Spike|2|D|WIS|3d8|psychic|120 ft|c|1d8|SKW
Mirror Image|2|I||||Self|||SKW
Misty Step|2|C||||Self|||SKW
Moonbeam|2|V|CON|2d10|radiant|120 ft|c|1d10|D
Nystul's Magic Aura|2|I||||Touch|||W
Pass without Trace|2|A||||Self, 30-ft emanation|c||DR
Phantasmal Force|2|I|INT|2d8|psychic|60 ft|c||SW
Prayer of Healing|2|A||2d8|heal|30 ft||1d8|CP
Protection from Poison|2|A||||Touch|||CDRP
Ray of Enfeeblement|2|N|CON|||60 ft|c||KW
Rope Trick|2|T||||Touch|||W
Scorching Ray|2|V|ATTACK|2d6|fire|120 ft|||SW
See Invisibility|2|D||||Self|||SW
Shatter|2|V|CON|3d8|thunder|60 ft||1d8|SW
Shining Smite|2|T||2d6|radiant|Self|c|1d6|P
Silence|2|I||||120 ft|cr||CR
Spider Climb|2|T||||Touch|c||SKW
Spike Growth|2|T||2d4|piercing|150 ft|c||DR
Spiritual Weapon|2|V|ATTACK|1d8|force|60 ft|c|1d8|C
Suggestion|2|E|WIS|||30 ft|c||SKW
Summon Beast|2|C||||90 ft|c||DR
Warding Bond|2|A||||Touch|||CP
Web|2|C|DEX|||60 ft|c||SW
Zone of Truth|2|E|CHA|||60 ft|||CP
Animate Dead|3|N||||10 ft|||CW
Aura of Vitality|3|A||2d6|heal|Self, 30-ft emanation|c||CDP
Beacon of Hope|3|A||||30 ft|c||C
Bestow Curse|3|N|WIS|1d8|necrotic|Touch|c||CW
Blinding Smite|3|V|CON|3d8|radiant|Self||1d8|P
Blink|3|T||||Self|||SW
Call Lightning|3|C|DEX|3d10|lightning|120 ft|c|1d10|D
Clairvoyance|3|D||||1 mi|c||CSW
Conjure Animals|3|C|DEX|3d10|slashing|60 ft|c|1d10|DR
Conjure Barrage|3|C|DEX|5d8|force|Self, 60-ft cone||1d8|R
Counterspell|3|A|CON|||60 ft|||SKW
Create Food and Water|3|C||||30 ft|||CP
Crusader's Mantle|3|V||1d4|radiant|Self, 30-ft emanation|c||P
Daylight|3|V||||60 ft|||CDRSP
Dispel Magic|3|A||||120 ft|||CDRSKWP
Elemental Weapon|3|T||1d4||Touch|c||DRP
Fear|3|I|WIS|||Self, 30-ft cone|c||SKW
Feign Death|3|N||||Touch|r||CDW
Fireball|3|V|DEX|8d6|fire|150 ft||1d6|SW
Fly|3|T||||Touch|c||SKW
Gaseous Form|3|T||||Touch|c||SKW
Glyph of Warding|3|A|DEX|5d8||Touch||1d8|CW
Haste|3|T||||30 ft|c||SW
Hunger of Hadar|3|C|DEX|2d6||150 ft|c|1d6|K
Hypnotic Pattern|3|I|WIS|||120 ft|c||SKW
Leomund's Tiny Hut|3|V||||Self, 10-ft emanation|r||W
Lightning Arrow|3|T|DEX|4d8|lightning|Self||1d8|R
Lightning Bolt|3|V|DEX|8d6|lightning|Self, 100-ft line||1d6|SW
Magic Circle|3|A|CHA|||10 ft|||CKWP
Major Image|3|I||||120 ft|c||SKW
Mass Healing Word|3|A||2d4|heal+|60 ft||1d4|C
Meld into Stone|3|T||||Touch|r||CDR
Nondetection|3|A||||Touch|||RW
Phantom Steed|3|I||||30 ft|r||W
Plant Growth|3|T||||150 ft|||DR
Protection from Energy|3|A||||Touch|c||CDRSW
Remove Curse|3|A||||Touch|||CKWP
Revivify|3|N||||Touch|||CDRP
Sending|3|D||||Unlimited|||CW
Sleet Storm|3|C|DEX|||150 ft|c||DSW
Slow|3|T|WIS|||120 ft|c||SW
Speak with Dead|3|N||||10 ft|||CW
Speak with Plants|3|T||||Self, 30-ft emanation|||DR
Spirit Guardians|3|C|WIS|3d8||Self, 15-ft emanation|c|1d8|C
Stinking Cloud|3|C|CON|||90 ft|c||SW
Summon Fey|3|C||||90 ft|c||DRKW
Summon Undead|3|N||||90 ft|c||KW
Tongues|3|D||||Touch|||CSKW
Vampiric Touch|3|N|ATTACK|3d6|necrotic|Self|c|1d6|SKW
Water Breathing|3|T||||30 ft|r||DRSW
Water Walk|3|T||||30 ft|r||CDRS
Wind Wall|3|V|STR|4d8|bludgeoning|120 ft|c||DR
Arcane Eye|4|D||||30 ft|c||W
Aura of Life|4|A||||Self, 30-ft emanation|c||CP
Aura of Purity|4|A||||Self, 30-ft emanation|c||CP
Banishment|4|A|CHA|||30 ft|c||CSKWP
Blight|4|N|CON|8d8|necrotic|30 ft||1d8|DSKW
Charm Monster|4|E|WIS|||30 ft|||DSKW
Compulsion|4|E|WIS|||30 ft|c||
Confusion|4|E|WIS|||90 ft|c||DSW
Conjure Minor Elementals|4|C||2d8||Self, 15-ft emanation|c|1d8|DW
Conjure Woodland Beings|4|C|WIS|5d8|force|Self, 10-ft emanation|c|1d8|DR
Control Water|4|T|STR|2d8|bludgeoning|300 ft|c||CDW
Death Ward|4|A||||Touch|||CP
Dimension Door|4|C||||500 ft|||SKW
Divination|4|D||||Self|r||CDW
Dominate Beast|4|E|WIS|||60 ft|c||DRS
Evard's Black Tentacles|4|C|STR|3d6|bludgeoning|90 ft|c||W
Fabricate|4|T||||120 ft|||W
Fire Shield|4|V||2d8||Self|||DSW
Fount of Moonlight|4|V|CON|2d6|radiant|Self|c||D
Freedom of Movement|4|A||||Touch|||CDR
Giant Insect|4|C||||60 ft|c||D
Grasping Vine|4|C|ATTACK|4d8|bludgeoning|60 ft|c||DR
Greater Invisibility|4|I||||Touch|c||SW
Guardian of Faith|4|C|DEX|||30 ft|||C
Hallucinatory Terrain|4|I||||300 ft|||DKW
Ice Storm|4|V|DEX|2d10||300 ft||1d10|DSW
Leomund's Secret Chest|4|C||||Touch|||W
Locate Creature|4|D||||Self|c||CDRWP
Mordenkainen's Faithful Hound|4|C|DEX|4d8|force|30 ft|||W
Mordenkainen's Private Sanctum|4|A||||120 ft|||W
Otiluke's Resilient Sphere|4|A|DEX|||30 ft|c||W
Phantasmal Killer|4|I|WIS|4d10|psychic|120 ft|c|1d10|W
Polymorph|4|T|WIS|||60 ft|c||DSW
Staggering Smite|4|E|WIS|4d6|psychic|Self||1d6|P
Stone Shape|4|T||||Touch|||CDW
Stoneskin|4|T||||Touch|c||DRSW
Summon Aberration|4|C||||90 ft|c||KW
Summon Construct|4|C||||90 ft|c||W
Summon Elemental|4|C||||90 ft|c||DRW
Vitriolic Sphere|4|V|DEX|10d4|acid|150 ft||2d4|SW
Wall of Fire|4|V|DEX|5d8|fire|120 ft|c|1d8|DSW
Animate Objects|5|T||||120 ft|c||SW
Antilife Shell|5|A||||Self, 10-ft emanation|c||D
Awaken|5|T||||Touch|||D
Banishing Smite|5|C||5d10|force|Self|c||P
Bigby's Hand|5|V|ATTACK|5d8||120 ft|c|2d8|SW
Circle of Power|5|A||||Self, 30-ft emanation|c||CWP
Cloudkill|5|C|CON|5d8|poison|120 ft|c|1d8|SW
Commune|5|D||||Self|r||C
Commune with Nature|5|D||||Self|r||DR
Cone of Cold|5|V|CON|8d8|cold|Self, 60-ft cone||1d8|DSW
Conjure Elemental|5|C|DEX|8d8||60 ft|c|1d8|DW
Conjure Volley|5|C|DEX|8d8|force|150 ft|||R
Contact Other Plane|5|D|INT|6d6|psychic|Self|r||KW
Contagion|5|N|CON|11d8|necrotic|Touch|||CD
Creation|5|I||||30 ft|||SW
Destructive Wave|5|V|CON|5d6||Self, 30-ft emanation|||P
Dispel Evil and Good|5|A|CHA|||Self|c||CP
Dominate Person|5|E|WIS|||60 ft|c||SW
Dream|5|I|WIS|3d6|psychic|Self|||KW
Flame Strike|5|V|DEX|5d6||60 ft||1d6|C
Geas|5|E|WIS|5d10|psychic|60 ft|||CDWP
Greater Restoration|5|A||||Touch|||CDRP
Hallow|5|A||||Touch|||C
Hold Monster|5|E|WIS|||90 ft|c||SKW
Insect Plague|5|C|CON|4d10|piercing|300 ft|c|1d10|CDS
Jallarzi's Storm of Radiance|5|V|CON|2d10||120 ft|c|1d10|KW
Legend Lore|5|D||||Self|||CW
Mass Cure Wounds|5|A||5d8|heal+|60 ft||1d8|CD
Mislead|5|I||||Self|c||KW
Modify Memory|5|E|WIS|||30 ft|c||W
Passwall|5|T||||30 ft|||W
Planar Binding|5|A|CHA|||60 ft|||CDKW
Raise Dead|5|N||||Touch|||CP
Rary's Telepathic Bond|5|D||||30 ft|r||W
Reincarnate|5|N||||Touch|||D
Scrying|5|D|WIS|||Self|c||CDKW
Seeming|5|I|CHA|||30 ft|||SW
Steel Wind Strike|5|C|ATTACK|6d10|force|30 ft|||RW
Summon Celestial|5|C||||90 ft|c||CP
Summon Dragon|5|C||||60 ft|c||W
Swift Quiver|5|T||||Self|c||R
Synaptic Static|5|E|INT|8d6|psychic|120 ft|||SKW
Telekinesis|5|T|STR|||60 ft|c||SW
Teleportation Circle|5|C||||10 ft|||SKW
Tree Stride|5|C||||Self|c||DR
Wall of Force|5|V||||120 ft|c||W
Wall of Stone|5|V|DEX|||120 ft|c||DSW
Yolande's Regal Presence|5|E|WIS|4d6|psychic|Self, 10-ft emanation|c||W
Arcane Gate|6|C||||500 ft|c||SKW
Blade Barrier|6|V|DEX|6d10|force|90 ft|c||C
Chain Lightning|6|V|DEX|10d8|lightning|150 ft|||SW
Circle of Death|6|N|CON|8d8|necrotic|150 ft||2d8|SKW
Conjure Fey|6|C||3d12|psychic|60 ft|c|1d12|D
Contingency|6|A||||Self|||W
Create Undead|6|N||||10 ft|||CKW
Disintegrate|6|T|DEX|10d6|force|60 ft||3d6|SW
Drawmij's Instant Summons|6|C||||Touch|r||W
Eyebite|6|N|WIS|||Self|c||SKW
Find the Path|6|D||||Self|c||CD
Flesh to Stone|6|T|CON|||60 ft|c||DSW
Forbiddance|6|A||5d10||Touch|r||C
Globe of Invulnerability|6|A||||Self, 10-ft emanation|c||SW
Guards and Wards|6|A||||Touch|||W
Harm|6|N|CON|14d6|necrotic|60 ft|||C
Heal|6|A||||60 ft|||CD
Heroes' Feast|6|C||||Self, 10-ft cube|||CD
Magic Jar|6|N|CHA|||Self|||W
Mass Suggestion|6|E|WIS|||60 ft|||SW
Move Earth|6|T||||120 ft|c||DSW
Otiluke's Freezing Sphere|6|V|CON|10d6|cold|300 ft||1d6|SW
Otto's Irresistible Dance|6|E|WIS|||30 ft|c||W
Planar Ally|6|C||||60 ft|||C
Programmed Illusion|6|I||||120 ft|||W
Summon Fiend|6|C||||90 ft|c||KW
Sunbeam|6|V|CON|6d8|radiant|Self, 60-ft line|c||CDSW
Tasha's Bubbling Cauldron|6|C||||5 ft|||KW
Transport via Plants|6|C||||10 ft|||D
True Seeing|6|D||||Touch|||CSKW
Wall of Ice|6|V|DEX|10d6|cold|120 ft|c|2d6|W
Wall of Thorns|6|C|DEX|7d8||120 ft|c|1d8|D
Wind Walk|6|T||||30 ft|||D
Word of Recall|6|C||||5 ft|||C
Conjure Celestial|7|C|DEX|6d12|radiant|90 ft|c|1d12|C
Delayed Blast Fireball|7|V|DEX|12d6|fire|150 ft|c|1d6|SW
Divine Word|7|V|CHA|||30 ft|||C
Etherealness|7|C||||Self|||CSKW
Finger of Death|7|N|CON|7d8|necrotic|60 ft|||SKW
Fire Storm|7|V|DEX|7d10|fire|150 ft|||CDS
Forcecage|7|V|CHA|||100 ft|c||KW
Mirage Arcane|7|I||||Sight|||DW
Mordenkainen's Magnificent Mansion|7|C||||300 ft|||W
Mordenkainen's Sword|7|V|ATTACK|4d12|force|90 ft|c||W
Plane Shift|7|C||||Touch|||CDSKW
Power Word Fortify|7|E||||60 ft|||C
Prismatic Spray|7|V|DEX|12d6||Self, 60-ft cone|||SW
Project Image|7|I||||500 mi|c||W
Regenerate|7|T||4d8|heal|Touch|||CD
Resurrection|7|N||||Touch|||C
Reverse Gravity|7|T|DEX|||100 ft|c||DSW
Sequester|7|T||||Touch|||W
Simulacrum|7|I||||Touch|||W
Symbol|7|A|CON|10d10||Touch|||CDW
Teleport|7|C||||10 ft|||SW
Animal Shapes|8|T||||30 ft|||D
Antimagic Field|8|A||||Self, 10-ft emanation|c||CW
Antipathy/Sympathy|8|E|WIS|||60 ft|||DW
Befuddlement|8|E|INT|10d12|psychic|150 ft|||DKW
Clone|8|N||||Touch|||W
Control Weather|8|T||||Self, 5-ft sphere|c||CDW
Demiplane|8|C||||60 ft|||SKW
Dominate Monster|8|E|WIS|||60 ft|c||SKW
Earthquake|8|T|CON|12d6|bludgeoning|500 ft|c||CDS
Glibness|8|E||||Self|||K
Holy Aura|8|A|CON|||Self, 30-ft emanation|c||C
Incendiary Cloud|8|C|DEX|10d8|fire|150 ft|c||DSW
Maze|8|C||||60 ft|c||W
Mind Blank|8|A||||Touch|||W
Power Word Stun|8|E|CON|||60 ft|||SKW
Sunburst|8|V|CON|12d6|radiant|150 ft|||CDSW
Telepathy|8|D||||Unlimited|||W
Tsunami|8|C|STR|6d10|bludgeoning|1 mi|c||D
Astral Projection|9|N||||10 ft|||CKW
Foresight|9|D||||Touch|||DKW
Gate|9|C||||60 ft|c||CSKW
Imprisonment|9|A|WIS|||30 ft|||KW
Mass Heal|9|A||||60 ft|||C
Meteor Swarm|9|V|DEX|20d6||1 mi|||SW
Power Word Heal|9|E||||60 ft|||C
Power Word Kill|9|E||12d12|psychic|60 ft|||SKW
Prismatic Wall|9|A|CON|12d6||60 ft|||W
Shapechange|9|T||||Self|c||DW
Storm of Vengeance|9|C|CON|2d6||1 mi|c||D
Time Stop|9|T||||Self|||SW
True Polymorph|9|T|WIS|||30 ft|c||KW
True Resurrection|9|N||||Touch|||CD
Weird|9|I|WIS|10d10|psychic|120 ft|c||KW
Wish|9|C||||Self|||SW
]]

-- The summary shown for a spell, put together from its facts.
local function Summary(school, how, dice, kind, range, flags, up, level)
    local parts = { SCHOOLS[school] or "Spell", "Range " .. range:gsub(" ft", " feet"):gsub("-ft", "-foot"):gsub(" mi$", " miles"):gsub("^1 miles", "1 mile") }
    if how == "ATTACK" then
        parts[#parts + 1] = "Spell attack"
    elseif how ~= "" then
        parts[#parts + 1] = (R.STAT_NAMES[how] or how) .. " save"
    end
    if dice ~= "" then
        if kind == "heal" or kind == "heal+" then
            parts[#parts + 1] = ("Restores %s hit points%s"):format(dice, kind == "heal+" and " plus your spellcasting modifier" or "")
        else
            parts[#parts + 1] = ("%s %sdamage"):format(dice, kind ~= "" and (kind .. " ") or "")
        end
        if up ~= "" then parts[#parts + 1] = ("%s more for each slot level above %s"):format(up, R.ORDINALS[level]) end
    end
    if flags:find("c") then parts[#parts + 1] = "Concentration" end
    if flags:find("r") then parts[#parts + 1] = "Can be cast as a ritual" end
    return table.concat(parts, ". ") .. "."
end

local listed = {}
for class, names in pairs(R.SPELL_LISTS) do
    listed[class] = {}
    for _, name in ipairs(names) do listed[class][name] = true end
end

for line in DATA:gmatch("[^\n]+") do
    local name, level, school, how, dice, kind, range, flags, up, classes = strsplit("|", line)
    level = tonumber(level)
    local count, sides = dice:match("^(%d+)d(%d+)$")
    -- Dice a higher slot adds, where they are the same kind of die.
    local upCount, upSides = up:match("^(%d+)d(%d+)$")
    local more = (upSides and upSides == sides) and tonumber(upCount) or 0
    if R.SPELLS[name] then
        local known = R.SPELLS[name]
        if known.level == level and known.sides == tonumber(sides) and known.count > 0 then known.up = more end
    else
        local extra = { concentration = flags:find("c") ~= nil }
        if kind == "heal" or kind == "heal+" then extra.dice, extra.addMod = "HEALING", kind == "heal+" end
        extra.up = more
        R.DefineSpell(name, level, how ~= "" and how or nil, count and { tonumber(count), tonumber(sides) } or nil,
            Summary(school, how, dice, kind, range, flags, up, level), extra)
    end
    for letter in classes:gmatch(".") do
        local class = CLASSES[letter]
        if class and listed[class] and not listed[class][name] then
            listed[class][name] = true
            table.insert(R.SPELL_LISTS[class], name)
        end
    end
end
