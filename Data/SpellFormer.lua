-- What the listed spells used to say, for the copies of them saved on characters.
-- A spell put on a sheet is a copy of its entry in R.SPELLS, and the player may change
-- that copy under Customize. When an entry here is corrected, a saved copy has to
-- follow, but not one the player changed on purpose. A copy made from now on records
-- its own changes (spell.edited). One saved before that doesn't, so for those every
-- value an entry ever had is kept here: a field that still holds one of them was
-- never touched, and takes the entry's value of today (Sheet/SpellRefresh.lua).
-- When you correct a spell, add what it said before: Was() for a field, Read() in
-- Data/SpellFormerText.lua for its summary.
local _, ns = ...
local R = ns.Rules

-- The fields of a saved spell that the Customize page can change, in the order they
-- are brought up to date (a field that hides another comes first)...
R.SPELL_OWN_FIELDS = { "kind", "save", "count", "sides", "dice", "addMod", "concentration", "scales", "up", "desc" }
-- ...and the ones it can't, which always follow the listed spell.
R.SPELL_LISTED_FIELDS = { "time", "material", "consumed", "hits", "hitsUp", "hitsScale", "ritual" }

R.SPELL_FORMER = {} -- [spell name] = { [field] = { former value, ... } }

function R.SpellWas(name, field, value)
    local spell = R.SPELL_FORMER[name] or {}
    R.SPELL_FORMER[name] = spell
    spell[field] = spell[field] or {}
    table.insert(spell[field], value)
end

-- field, the value it had, the spells that had it (names with | between them).
local function Was(field, value, names)
    for name in names:gmatch("[^|]+") do R.SpellWas(name, field, value) end
end

Was("addMod", false, "Conjure Fey|Flame Blade|Mordenkainen's Sword|Spiritual Weapon|Tranquility")
Was("concentration", false, "Blade Ward")
Was("count", 0, "False Life")
Was("count", 1, "Upheaval")
Was("count", 2, "Hand of Gul'dan")
Was("dice", "DAMAGE", "False Life")
Was("dice", "SELFHEAL", "Bonestorm")
Was("hitsUp", 0, "Flurry")
Was("kind", "NONE", "Banishing Smite|Conjure Fey|Sanctuary|Searing Smite|Serpent Sting|Thunderous Smite|Wrathful Smite")
Was("save", "CON", "Earthquake")
Was("save", "DEX", "Banishing Smite|Sanctuary|Searing Smite|Serpent Sting|Thunderous Smite|Wrathful Smite")
Was("scales", true, "Arcane Pulse")
Was("sides", 12, "Upheaval")
Was("sides", 6, "Bonestorm|Living Flame")
Was("sides", 8, "False Life")
Was("up", 0, "Azure Strike|Chains of Ice|Consume Soul|Dream Breath|Emberstorm|Eruption|Eye Beam|Fel Rush|Frost Nova|Frostscythe|Holy Nova|Infernal Strike|Leeching Strike|Magic Missile|Moonfire|Psychic Horror|Rain of Fire|Remorseless Winter|Rune Strike|Scourge Strike|Shadow Word: Pain|Shattering Star|Sigil of Flame|Soul Reap|Throw Glaive|Tranquility")

-- True if a listed spell once had this value in this field. A summary may also be
-- the line of facts it had before its summary was written (Data/SpellSummaries.lua).
function R.SpellHadValue(name, field, value)
    if field == "desc" and R.SPELL_FACT_LINES[name] == value then return true end
    local former = R.SPELL_FORMER[name]
    for _, was in ipairs(former and former[field] or {}) do
        if was == value then return true end
    end
    return false
end
