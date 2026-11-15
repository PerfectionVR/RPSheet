-- The material components that have a price: which spell needs what, and the items
-- themselves, so they can be added or bought (the "Reagents" tab of the item browser).
-- The check and the taking are in Sheet/SpellComponents.lua.
--
-- R.SPELL_COMPONENTS[<spell name>] = a list of parts, each
--   item      the listed item that does the job, e.g. "Diamond (300 gp)"
--   cost      what it must be worth at least, in copper
--   consumed  true when the casting uses it up
--   qty       how many are needed (1 unless stated)
--   each      "target", "corpse": one is needed for each; the sheet counts one
--   accept    [base name] = true: the things that will do, when worth enough
--
-- Left out: components that are a weapon (it is on the weapon list, not carried here),
-- a couple of coins, or a class resource.
local _, ns = ...
local R = ns.Rules

local KIND = "Spell components"
R.SPELL_COMPONENTS = {}

-- Spell=part+part. A part is  Name:gold  then, in this order and each optional:
--   !        the casting uses it up
--   xN       N of them are needed
--   *word    one for each such thing
--   ~A/B     other things that will do as well
-- Gold 0 means a thing already on the gear list, at its own price.
local LIST = {
    "Arcane Lock=Gold dust:25!", "Astral Projection=Jacinth:1000!*target+Silver bar:100!*target",
    "Augury=Divining tokens:25", "Awaken=Agate:1000!", "Bless=Amulet:0~Emblem/Reliquary",
    "Chromatic Orb=Diamond:50", "Circle of Death=Black pearl powder:500",
    "Clairvoyance=Glass eye:100~Jeweled horn", "Clone=Diamond:1000!+Sealable vessel:2000",
    "Contingency=Statuette of yourself:1500", "Continual Flame=Ruby dust:50!",
    "Create Undead=Black onyx:150*corpse", "Divination=Incense:25!",
    "Drawmij's Instant Summons=Sapphire:1000", "Find Familiar=Incense:10!",
    "Find the Path=Divining tokens:100", "Forbiddance=Ruby dust:1000", "Forcecage=Ruby dust:1500!",
    "Gate=Diamond:5000", "Glyph of Warding=Diamond dust:200!", "Greater Restoration=Diamond dust:100!",
    "Guards and Wards=Silver rod:10", "Hallow=Incense:1000!", "Heroes' Feast=Jeweled bowl:1000!",
    "Holy Aura=Reliquary:1000", "Identify=Pearl:100", "Illusory Script=Ink:0!",
    "Imprisonment=Statuette of the target:5000", "Legend Lore=Incense:250!+Ivory strip:50x4",
    "Leomund's Secret Chest=Rare chest:5000+Chest replica:50", "Magic Circle=Salt and silver powder:100!",
    "Magic Jar=Gem:500~Crystal/Reliquary/Jewel/Diamond/Sapphire/Agate/Jacinth", "Magic Mouth=Jade dust:10!",
    "Mordenkainen's Magnificent Mansion=Miniature door:15", "Mordenkainen's Sword=Miniature sword:250",
    "Nondetection=Diamond dust:25!", "Planar Binding=Jewel:1000!~Gem/Diamond/Sapphire/Agate/Jacinth",
    "Plane Shift=Forked metal rod:250", "Programmed Illusion=Jade dust:25", "Project Image=Statuette of yourself:5",
    "Protection from Evil and Good=Holy Water:0!", "Raise Dead=Diamond:500!", "Reincarnate=Rare oils:1000!",
    "Resurrection=Diamond:1000!", "Revivify=Diamond:300!", "Scrying=Scrying focus:1000",
    "Sequester=Gem dust:5000!~Diamond dust/Ruby dust/Jade dust", "Shapechange=Jade circlet:1500",
    "Simulacrum=Ruby dust:1500!", "Stoneskin=Diamond dust:100!", "Summon Aberration=Platinum-inlaid vial:400",
    "Summon Beast=Gilded acorn:200", "Summon Celestial=Reliquary:500", "Summon Construct=Lockbox:400",
    "Summon Dragon=Dragon-engraved token:500", "Summon Elemental=Gold-inlaid vial:400",
    "Summon Fey=Gilded flower:300", "Summon Fiend=Bloody vial:600", "Summon Undead=Gilded skull:300",
    "Swift Quiver=Quiver:0", "Symbol=Diamond dust:1000!", "Teleportation Circle=Rare inks:50!",
    "True Resurrection=Diamond:25000!", "True Seeing=Mushroom powder:25!", "Warding Bond=Platinum ring:50x2",
}

-- "Diamond (300 gp)" -> "Diamond", 30000. A plain name has no worth in it.
function R.ComponentWorth(name)
    local base, gold = name:match("^(.-) %((%d+) gp%)$")
    if base then return base, tonumber(gold) * 100 end
    return name
end

local uses = {} -- [item name] = the spells that need it

local function Part(spell, text)
    local base, gold, consumed, rest = text:match("^([^:]+):(%d+)(!?)(.*)$")
    if not base then return end
    gold = tonumber(gold)
    local item = gold > 0 and ("%s (%d gp)"):format(base, gold) or base
    if not R.ITEMS[item] then R.AddGear(KIND, ("%s|%d|0"):format(item, gold * 100)) end
    local part = {
        item = item, cost = R.ITEMS[item] and R.ITEMS[item].cost or gold * 100, consumed = consumed == "!",
        qty = tonumber(rest:match("^x(%d+)")) or 1, each = rest:match("%*(%a+)"), accept = { [base] = true },
    }
    for other in (rest:match("~(.+)$") or ""):gmatch("[^/]+") do part.accept[other] = true end
    uses[item] = uses[item] or {}
    table.insert(uses[item], spell)
    return part
end

for _, entry in ipairs(LIST) do
    local spell, parts = entry:match("^(.-)=(.+)$")
    local list = {}
    for text in parts:gmatch("[^+]+") do list[#list + 1] = Part(spell, text) end
    R.SPELL_COMPONENTS[spell] = list
end
R.AddGear(KIND, "Jeweled horn (100 gp)|10000|0") -- does for Clairvoyance what the glass eye does

-- The new items say what they are for; gear that was listed already keeps its own text.
for item, spells in pairs(uses) do
    if R.ITEMS[item].kind == KIND then
        R.ITEMS[item].desc = "A spell component, for " .. table.concat(spells, ", ") .. ". One worth more will do as well."
    end
end
R.ITEMS["Jeweled horn (100 gp)"].desc = "A spell component, for Clairvoyance."

-- By name, and the cheaper before the dearer of the same thing.
table.sort(R.ITEM_NAMES[KIND], function(a, b)
    local baseA, worthA = R.ComponentWorth(a)
    local baseB, worthB = R.ComponentWorth(b)
    if baseA ~= baseB then return baseA < baseB end
    return (worthA or 0) < (worthB or 0)
end)
