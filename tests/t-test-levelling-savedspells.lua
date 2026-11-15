-- Copies of listed spells saved on a character follow corrections to the spell data
-- (Sheet/SpellRefresh.lua, Data/SpellFormer.lua), and what the player changed stays:
--   * a copy from before changes were recorded, holding what the spell used to say in
--     any field, is brought up to date and not marked as edited;
--   * the same copy with a value of the player's in one field keeps that field, is
--     marked as edited, and its other former values are still corrected;
--   * a copy made now follows fully until a control of its Customize page is used;
--   * the mark survives export and import, and "Use the built-in spell" lifts it;
--   * a spell of the player's own grows by the dice set on it for higher slots.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local Util = ns.Util
local checks = 0
local function Check(ok, text)
    checks = checks + 1
    if not ok then Problem(text) end
end

local sheet = T.NewCharacter("PRIEST", 1)
local OWN, LISTED = R.SPELL_OWN_FIELDS, R.SPELL_LISTED_FIELDS

-- What the sheet's upkeep does, on the login path: entries get their shape first.
local function Upkeep()
    ns.NormalizeState(RPSheet:State())
    ns.ApplyGrants(sheet)
    ns.NormalizeState(RPSheet:State())
end
local function Saved(name)
    for _, spell in ipairs(sheet.spells) do
        if spell.name == name and (spell.auto or "") == "" then return spell end
    end
end
-- A copy as an older version saved it: no marks, and `fields` in place of today's.
local function Old(name, fields)
    local spell = CopyTable(R.SPELLS[name])
    spell.tracked, spell.edited = nil, nil
    for key, value in pairs(fields or {}) do spell[key] = value end
    spell.free = true -- beside the limits: this is about the copy, not the count
    sheet.spells[#sheet.spells + 1] = spell
    return spell
end
local function Differs(spell, fields)
    local known = R.SPELLS[spell.name]
    for _, field in ipairs(fields) do
        if spell[field] ~= known[field] then return field end
    end
end
local function Clear()
    for index = #sheet.spells, 1, -1 do
        if (sheet.spells[index].auto or "") == "" then table.remove(sheet.spells, index) end
    end
end

---------------------------------------------------------------------------
-- Every former value of every spell, one at a time and all together
---------------------------------------------------------------------------
local formers = 0
for name, fields in pairs(R.SPELL_FORMER) do
    local known = R.SPELLS[name]
    Check(known ~= nil, name .. ": Data/SpellFormer.lua names a spell that isn't listed")
    if known then
        local all = {}
        for field, values in pairs(fields) do
            Check(tContains(OWN, field) or tContains(LISTED, field), ("%s: former values for %s, which no copy keeps"):format(name, field))
            for _, value in ipairs(values) do
                formers = formers + 1
                Check(value ~= known[field], ("%s: the former %s is the value it has now"):format(name, field))
                Clear()
                Old(name, { [field] = value })
                Upkeep()
                local spell = Saved(name)
                local wrong = Differs(spell, OWN) or Differs(spell, LISTED)
                Check(not wrong, ("%s saved with the former %s (%s) still has another %s than the listed spell"):format(name, field, tostring(value), tostring(wrong)))
                Check(spell.edited == false and spell.tracked == true, name .. " saved with a former " .. field .. " is marked as edited")
            end
            all[field] = values[1]
        end
        Clear()
        Old(name, all)
        Upkeep()
        Check(not Differs(Saved(name), OWN) and not Saved(name).edited, name .. " saved with all its former values isn't brought up to date")
    end
end
-- The corrections of the last rules check, by name, so the list can't go quietly.
for name, field in pairs({
    ["Blade Ward"] = "concentration", ["Sanctuary"] = "kind", ["Searing Smite"] = "save", ["Thunderous Smite"] = "save",
    ["Wrathful Smite"] = "save", ["Banishing Smite"] = "save", ["Serpent Sting"] = "kind", ["Earthquake"] = "save",
    ["Conjure Fey"] = "kind", ["Flame Blade"] = "addMod", ["Mordenkainen's Sword"] = "addMod", ["Spiritual Weapon"] = "addMod",
    ["Emberstorm"] = "desc", ["Soul Reap"] = "desc", ["Call Lightning"] = "desc", ["Control Weather"] = "desc",
}) do
    Check(R.SPELL_FORMER[name] and R.SPELL_FORMER[name][field] ~= nil, ("%s: its corrected %s has no former value kept"):format(name, field))
end
-- A copy that carries the line of facts a core spell had before its summary was written.
for name, line in pairs(R.SPELL_FACT_LINES) do
    if line ~= R.SPELLS[name].desc then
        Clear()
        Old(name, { desc = line })
        Upkeep()
        Check(Saved(name).desc == R.SPELLS[name].desc and not Saved(name).edited, name .. " saved with its line of facts doesn't get the summary")
        break
    end
end

---------------------------------------------------------------------------
-- What the player set stays
---------------------------------------------------------------------------
Clear()
-- The save was corrected (none -> Constitution); this player had given it dice of their own.
local smite = Old("Searing Smite", { kind = "NONE", save = "DEX", count = 3 })
-- Corrected to a Dexterity save; this player had ruled Wisdom.
local quake = Old("Earthquake", { save = "WIS", desc = R.SPELL_FACT_LINES["Earthquake"] })
-- Nothing corrected, a description of the player's own.
local bolt = Old("Fire Bolt", { desc = "My own words." })
-- An untouched copy from a version that knew fewer fields.
local bless = Old("Bless", { up = nil, hits = nil, time = nil, ritual = nil })
Upkeep()
smite, quake, bolt, bless = Saved("Searing Smite"), Saved("Earthquake"), Saved("Fire Bolt"), Saved("Bless")
Check(smite.kind == "SAVE" and smite.save == "CON", "Searing Smite with dice of the player's own doesn't get its corrected save")
Check(smite.count == 3 and smite.edited == true, "Searing Smite loses the dice the player set, or isn't marked as edited")
Check(quake.save == "WIS" and quake.edited == true, "Earthquake loses the save the player set")
Check(quake.desc == R.SPELLS["Earthquake"].desc, "Earthquake with a save of the player's own keeps the old line of facts")
Check(bolt.desc == "My own words." and bolt.edited == true, "Fire Bolt loses the description the player wrote")
Check(not bless.edited and not Differs(bless, OWN) and not Differs(bless, LISTED), "an untouched Bless from an older version isn't completed")
-- A second pass changes nothing.
local before = Util.Copy and Util.Copy(sheet.spells) or CopyTable(sheet.spells)
Upkeep()
for index, spell in ipairs(sheet.spells) do
    for key, value in pairs(before[index]) do
        Check(spell[key] == value, ("%s: a second pass changes %s"):format(spell.name, key))
    end
end
-- Later corrections: an edited copy keeps the fields its page can change and follows
-- in the others; one that isn't edited follows in all.
smite.count, smite.save, smite.time, smite.material = 5, "INT", "LONG", 99
bless.kind, bless.save, bless.count, bless.concentration, bless.desc, bless.time = "SAVE", "STR", 2, false, "Stale.", "REACTION"
Upkeep()
smite, bless = Saved("Searing Smite"), Saved("Bless")
Check(smite.count == 5 and smite.save == "INT", "an edited spell loses what the player set on a later pass")
Check(smite.time == R.SPELLS["Searing Smite"].time and smite.material == R.SPELLS["Searing Smite"].material, "an edited spell doesn't follow in the fields its page can't change")
Check(not Differs(bless, OWN) and not Differs(bless, LISTED), "a spell that isn't edited doesn't follow the listed spell: " .. tostring(Differs(bless, OWN) or Differs(bless, LISTED)))
-- A spell whose level the player changed is their own altogether.
local raised = Old("Bane", { level = 3, count = 4 })
Upkeep()
Check(raised.count == 4 and raised.level == 3, "a spell moved to another level is overwritten")

---------------------------------------------------------------------------
-- The Customize page marks a spell, and can put the listed one back
---------------------------------------------------------------------------
Clear()
-- (Marked as not counting, so the prepared picks leave it alone.)
local function Add(name)
    local spell = CopyTable(R.SPELLS[name])
    spell.free = true
    sheet.spells[#sheet.spells + 1] = spell
end
Add("Guiding Bolt")
Upkeep()
local guiding = Saved("Guiding Bolt")
Check(guiding ~= nil and guiding.tracked == true and guiding.edited == false, "a spell added now isn't followed from the start")
local page = Opt.lists.spells.build(guiding)
for _, key in ipairs({ "name", "level", "concentration", "kind", "save", "count", "sides", "dice", "addMod", "scales", "up", "desc" }) do
    Check(page[key] ~= nil, "the spell page has no control for " .. key)
    if page[key] then
        guiding.edited = false
        local value = page[key].get({})
        Try("spell page " .. key, page[key].set, {}, value)
        Check(guiding.edited == true, "changing " .. key .. " on the spell's page doesn't mark it as edited")
    end
end
for _, key in ipairs({ "free", "class", "damage" }) do
    guiding.edited = false
    Try("spell page " .. key, page[key].set, {}, page[key].get({}))
    Check(guiding.edited == false, "changing " .. key .. " marks the spell as edited: that isn't a fact of the spell")
end
Try("count", page.count.set, {}, 9)
Upkeep()
guiding = Saved("Guiding Bolt")
Check(guiding.count == 9, "the dice set on the spell's page don't survive the upkeep")
-- Export and import keep the mark, so the import doesn't undo the player's change.
do
    local text = RPSheet:ExportSheet()
    local decoded = Try("decode", RPSheet.DecodeSheet, RPSheet, text)
    local found
    for _, spell in ipairs(decoded and decoded.spells or {}) do
        if spell.name == "Guiding Bolt" then found = spell end
    end
    Check(found and found.edited == true and found.tracked == true and found.count == 9, "an exported spell loses its edited mark or its dice")
end
page = Opt.lists.spells.build(guiding)
Check(not page.restore.hidden() and not page.own.hidden(), "an edited copy of a listed spell doesn't offer the listed spell back")
Try("restore", page.restore.func)
Check(guiding.count == R.SPELLS["Guiding Bolt"].count and guiding.edited == false, "\"Use the built-in spell\" doesn't put the listed spell back")
Check(page.restore.hidden() and page.own.hidden(), "the restore button stays after it was used")

---------------------------------------------------------------------------
-- Higher slots: a spell of the player's own, and a listed one they changed
---------------------------------------------------------------------------
do
    local own = CopyTable(R.TEMPLATES.spell)
    own.name, own.level, own.count, own.sides = "Sunder the Sky", 2, 3, 6
    sheet.spells[#sheet.spells + 1] = own
    page = Opt.lists.spells.build(own)
    Check(not page.up.hidden(), "a levelled spell with dice has no \"Dice per higher slot\"")
    Try("up", page.up.set, {}, 2)
    Check(RPSheet:SlotGrowth(own, 4).dice == 4, "a spell of the player's own with 2 dice per slot adds " .. RPSheet:SlotGrowth(own, 4).dice .. " dice two slots up")
    Check(table.concat(RPSheet:SlotGrowthHelp(own), " "):find("adds 2d6"), "its tooltip doesn't say what a higher slot adds")
    own.level = 0
    Check(page.up.hidden() and not page.scales.hidden(), "a cantrip shows dice per higher slot, or no growth by level")
    own.level, own.count = 2, 0
    Check(page.up.hidden(), "a spell without dice shows dice per higher slot")
    -- A listed spell follows its listed growth until the player sets another.
    Clear()
    Add("Guiding Bolt")
    local bolt2 = Saved("Guiding Bolt")
    local listed = R.SPELLS["Guiding Bolt"].up
    Check(RPSheet:SlotGrowth(bolt2, 3).dice == 2 * listed, "Guiding Bolt doesn't grow by its listed dice")
    page = Opt.lists.spells.build(bolt2)
    Try("up", page.up.set, {}, listed + 2)
    Check(RPSheet:SlotGrowth(bolt2, 3).dice == 2 * (listed + 2), "the dice per higher slot set on a listed spell aren't used")
    Check(not Opt.lists.spells.help:find("add those by hand"), "the Spells page still tells the player to add higher-slot dice by hand")
end

local problems = 0
for _ in pairs(PROBLEMS) do problems = problems + 1 end
print(("saved spells: %d former values of %d spells, %d checks, %d problems"):format(formers, (function() local n = 0 for _ in pairs(R.SPELL_FORMER) do n = n + 1 end return n end)(), checks, problems))
