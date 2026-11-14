-- Two more facts about spells, set on the entries the other spell files made:
--   time      what casting takes: "ACTION" (the default), "BONUS", "REACTION", or
--             "LONG" for a minute or more
--   material  the price in gold of a component the spell needs, when it has one with
--             a price; consumed = true when the casting uses it up
local _, ns = ...
local R = ns.Rules

R.SPELL_TIMES = { ACTION = "Action", BONUS = "Bonus action", REACTION = "Reaction", LONG = "A minute or longer" }

local TIMES = {
    BONUS = "Arcane Vigor|Armor of Agathys|Banishing Smite|Barkskin|Blinding Smite|Compelled Duel|Divine Favor|Divine Smite|Divine Word|Dragon's Breath|Ensnaring Strike|Expeditious Retreat|Flame Blade|Grasping Vine|Hail of Thorns|Healing Word|Hex|Hunter's Mark|Jump|Lesser Restoration|Lightning Arrow|Magic Weapon|Mass Healing Word|Misty Step|Produce Flame|Sanctuary|Searing Smite|Shield of Faith|Shillelagh|Shining Smite|Spiritual Weapon|Staggering Smite|Swift Quiver|Thunderous Smite|Wrathful Smite|Apotheosis|Blistering Scales|Death Grip|Demon Spikes|Emerald Blossom|Feral Prowl|Leeching Strike|Metamorphosis|Moonfire|Rescue|Roar of Ursoc|Rune Strike|Scourge Strike|Serpent Sting|Tree of Life|Void Eruption",
    REACTION = "Counterspell|Feather Fall|Hellish Rebuke|Shield|Divine Shield|Entropic Embrace|Guided Prayer|Time Dilation",
    LONG = "Alarm|Animate Dead|Antipathy/Sympathy|Astral Projection|Augury|Awaken|Clairvoyance|Clone|Commune|Commune with Nature|Contact Other Plane|Contingency|Control Weather|Create Undead|Creation|Drawmij's Instant Summons|Dream|Fabricate|Find Familiar|Find the Path|Forbiddance|Foresight|Geas|Glyph of Warding|Guards and Wards|Hallow|Hallucinatory Terrain|Heroes' Feast|Identify|Illusory Script|Imprisonment|Legend Lore|Leomund's Tiny Hut|Magic Circle|Magic Jar|Magic Mouth|Mending|Mirage Arcane|Mordenkainen's Magnificent Mansion|Mordenkainen's Private Sanctum|Phantom Steed|Planar Ally|Planar Binding|Prayer of Healing|Raise Dead|Regenerate|Reincarnate|Resurrection|Scrying|Simulacrum|Symbol|Teleportation Circle|True Resurrection|Tsunami|Wind Walk",
}

-- name=price in gold; an exclamation mark when the casting uses the component up.
-- Components that cost less than a gold piece are left out.
local MATERIALS = "Arcane Lock=25!|Astral Projection=1000!|Augury=25|Awaken=1000!|Bless=5|Chromatic Orb=50|Circle of Death=500|Clairvoyance=100|Clone=1000!|Contingency=1500|Continual Flame=50!|Create Undead=150|Divination=25!|Drawmij's Instant Summons=1000|Find Familiar=10!|Find the Path=100|Forbiddance=1000|Forcecage=1500!|Gate=5000|Glyph of Warding=200!|Greater Restoration=100!|Guards and Wards=10|Hallow=1000!|Heroes' Feast=1000!|Holy Aura=1000|Identify=100|Illusory Script=10!|Imprisonment=5000|Legend Lore=250!|Leomund's Secret Chest=5000|Magic Circle=100!|Magic Jar=500|Magic Mouth=10!|Mordenkainen's Magnificent Mansion=15|Mordenkainen's Sword=250|Nondetection=25!|Planar Binding=1000!|Plane Shift=250|Programmed Illusion=25|Project Image=5|Protection from Evil and Good=25!|Raise Dead=500!|Reincarnate=1000!|Resurrection=1000!|Revivify=300!|Scrying=1000|Sequester=5000!|Shapechange=1500|Simulacrum=1500!|Stoneskin=100!|Summon Aberration=400|Summon Beast=200|Summon Celestial=500|Summon Construct=400|Summon Dragon=500|Summon Elemental=400|Summon Fey=300|Summon Fiend=600|Summon Undead=300|Swift Quiver=1|Symbol=1000!|Teleportation Circle=50!|True Resurrection=25000!|True Seeing=25!|Warding Bond=50"

for time, names in pairs(TIMES) do
    for name in names:gmatch("[^|]+") do
        if R.SPELLS[name] then R.SPELLS[name].time = time end
    end
end
for entry in MATERIALS:gmatch("[^|]+") do
    local name, price, consumed = entry:match("^(.-)=(%d+)(!?)$")
    if name and R.SPELLS[name] then
        R.SPELLS[name].material, R.SPELLS[name].consumed = tonumber(price), consumed == "!"
    end
end

-- What a spell's tooltip says about casting it, or nil when there is nothing to add.
function R.SpellCastingNote(spell)
    local parts = {}
    if spell.time and spell.time ~= "ACTION" then parts[#parts + 1] = R.SPELL_TIMES[spell.time] .. "." end
    if (spell.material or 0) > 0 then
        parts[#parts + 1] = ("Needs a component worth %d gold%s."):format(spell.material, spell.consumed and ", which the casting uses up" or "")
    end
    return #parts > 0 and table.concat(parts, " ") or nil
end
