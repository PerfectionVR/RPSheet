-- The armoury: weapons kept for the whole account. Saving, adding a copy to a
-- character, renaming, deleting, the order, the one-line summary, a store from an
-- older version, and the share string out and in again.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
dofile(ARG3 .. "/sim.lua")
-- A store saved by an older version, in place before the addon first reads it.
local enable = RPSheet.OnEnable
RPSheet.OnEnable = function(self)
    self.db.global.weaponStore = { { name = "Old Blade", dice = 2, sides = 6 }, { name = "" }, "junk", [7] = { name = "Far Bow", base = "Longbow" } }
    return enable(self)
end
Start()
SKIP_SIM = true
dofile(ARG3 .. "/t-test-items-lib.lua")

-- The harness's serializer keeps one table and its encoder passes text through, so a
-- string can't be told from another. Real text in, real text out (candidates for env.lua).
local function Dump(value)
    local kind = type(value)
    if kind == "table" then
        local parts = {}
        for key, each in pairs(value) do parts[#parts + 1] = ("[%s]=%s"):format(Dump(key), Dump(each)) end
        table.sort(parts)
        return "{" .. table.concat(parts, ",") .. "}"
    elseif kind == "string" then return ("%q"):format(value)
    else return tostring(value) end
end
local serializer, deflate = LibStub("LibSerialize"), LibStub("LibDeflate")
function serializer:Serialize(...) return Dump({ ... }) end
function serializer:Deserialize(text)
    local chunk = loadstring("return " .. text)
    if not chunk then return false end
    setfenv(chunk, {})
    local ok, values = pcall(chunk)
    if not ok or type(values) ~= "table" then return false end
    return true, unpack(values)
end
function deflate:EncodeForPrint(text) return (text:gsub(".", function(char) return ("%02x"):format(char:byte()) end)) end
function deflate:DecodeForPrint(text)
    if #text % 2 ~= 0 or text:find("[^0-9a-f]") then return nil end
    return (text:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end))
end

local sheet = NewChar("WARRIOR", 5)
local TEMPLATE = R.TEMPLATES.weapon

---------------------------------------------------------------------------
-- A store from an older version
---------------------------------------------------------------------------
local store = RPSheet:StoredWeapons()
Eq(#store, 2, "an old store keeps its named weapons")
Check(store[1].name == "Old Blade" and store[2].name == "Far Bow", "in their order")
for index, weapon in ipairs(store) do
    for key, default in pairs(TEMPLATE) do
        Check(type(weapon[key]) == type(default), ("stored weapon %d: %s is %s"):format(index, key, type(weapon[key])))
    end
    Run("summary of an old weapon", ns.StoredWeaponSummary, weapon)
end
Check(store[1].dice == 2 and store[1].sides == 6 and store[1].stat == "STR" and store[1].proficient == true, "its own fields stay, the missing ones are filled in")
RPSheet:DeleteStoredWeapon(2); RPSheet:DeleteStoredWeapon(1)
Eq(#RPSheet:StoredWeapons(), 0, "emptied")

---------------------------------------------------------------------------
-- Saving and finding
---------------------------------------------------------------------------
local function Weapon(name, fields)
    local weapon = CopyTable(TEMPLATE)
    weapon.name = name
    for key, value in pairs(fields or {}) do weapon[key] = value end
    return weapon
end
local gorehowl = Weapon("Gorehowl", { dice = 2, sides = 6, magic = 2, mastery = "Cleave", cost = 50000 })
Eq(RPSheet:StoreWeapon(gorehowl), 1, "the first stored weapon")
Check(store[1] ~= gorehowl and store[1].name == "Gorehowl" and store[1].magic == 2, "a copy is stored")
gorehowl.magic = 3
Eq(store[1].magic, 2, "changing the weapon afterwards leaves the copy")
Eq(RPSheet:StoreWeapon(Weapon("Ashbringer", { base = "Longsword", sides = 8, mastery = "Sap" })), 2, "a second")
Eq(RPSheet:StoreWeapon(Weapon("gorehowl", { dice = 1, sides = 12 })), 1, "the same name in other capitals replaces")
Check(#store == 2 and store[1].sides == 12 and store[1].name == "gorehowl", "replaced in place")
Eq(RPSheet:FindStoredWeapon("ASHBRINGER"), 2, "found whatever the capitals")
Check(RPSheet:FindStoredWeapon("Nothing") == nil and RPSheet:FindStoredWeapon(nil) == nil and RPSheet:FindStoredWeapon("") == nil, "not found")
-- a weapon lacking fields is stored whole
local partial = { name = "Stick" }
RPSheet:StoreWeapon(partial)
for key, default in pairs(TEMPLATE) do Check(type(store[3][key]) == type(default), "a partial weapon gets " .. key) end
Check(partial.stat == nil, "the weapon handed in is not touched")

---------------------------------------------------------------------------
-- Adding a copy to a character
---------------------------------------------------------------------------
local before = #sheet.weapons
Check(RPSheet:AddStoredWeapon(2) == true and #sheet.weapons == before + 1, "a copy goes on the sheet")
local copy = sheet.weapons[#sheet.weapons]
Check(copy ~= store[2] and copy.name == "Ashbringer" and copy.base == "Longsword" and copy.mastery == "Sap", "it is a copy of the stored weapon")
copy.name = "Changed"
Eq(store[2].name, "Ashbringer", "changing the copy leaves the stored weapon")
Check(RPSheet:AddStoredWeapon(99) == false and #sheet.weapons == before + 1, "a stored weapon that is gone adds nothing")
Check(RPSheet:CopyStoredWeapon(99) == nil and RPSheet:CopyStoredWeapon(1) ~= store[1], "CopyStoredWeapon")
Run("the copy on the sheet works", function()
    RPSheet:WeaponText(copy); RPSheet:ExplainWeapon(copy)
    RPSheet:State().weapon = #ns.ReadyWeapons(sheet)
    RPSheet:Attack(); FlushTimers(); RPSheet.busy = false
end)

---------------------------------------------------------------------------
-- Renaming, order, deleting
---------------------------------------------------------------------------
Check(RPSheet:RenameStoredWeapon(1, "Gorehowl") == true and store[1].name == "Gorehowl", "renamed to its own name in other capitals")
Check(RPSheet:RenameStoredWeapon(1, "") == false and store[1].name == "Gorehowl", "an empty name is refused")
Check(RPSheet:RenameStoredWeapon(1, "ashbringer") == false and store[1].name == "Gorehowl", "another weapon's name is refused")
Check(RPSheet:RenameStoredWeapon(99, "Whatever") == false, "a weapon that isn't there")
Check(RPSheet:RenameStoredWeapon(3, "zweihander") == true, "renamed")
RPSheet:StoreWeapon(Weapon("apple corer"))
local order = RPSheet:StoredWeaponOrder()
local sorted = {}
for _, index in ipairs(order) do sorted[#sorted + 1] = store[index].name end
Eq(table.concat(sorted, ", "), "apple corer, Ashbringer, Gorehowl, zweihander", "sorted by name, whatever the capitals")
RPSheet:DeleteStoredWeapon(RPSheet:FindStoredWeapon("zweihander"))
RPSheet:DeleteStoredWeapon(RPSheet:FindStoredWeapon("apple corer"))
Check(#store == 2 and RPSheet:FindStoredWeapon("zweihander") == nil and RPSheet:FindStoredWeapon("Ashbringer") == 2, "deleted")
Eq(sheet.weapons[#sheet.weapons].name, "Changed", "the character's copy stays when the store changes")

---------------------------------------------------------------------------
-- The one-line summary
---------------------------------------------------------------------------
Eq(ns.StoredWeaponSummary(Weapon("Longsword", { base = "Longsword", mastery = "Sap" })), R.WeaponSummary("Longsword") .. ", mastery: Sap", "a basic weapon")
Eq(ns.StoredWeaponSummary(Weapon("Ashbringer", { base = "Longsword" })), "Longsword: " .. R.WeaponSummary("Longsword"), "a named basic weapon says what it is")
Eq(ns.StoredWeaponSummary(Weapon("Gorehowl", { dice = 2, sides = 6, stat = "STR" })), "2d6 damage, Strength", "a weapon of your own")
Eq(ns.StoredWeaponSummary(Weapon("Healing Touch", { dice = 1, sides = 4, stat = "WIS", heal = true, proficient = false })), "1d4 healing, Wisdom, not proficient", "a healing one, not proficient")
Eq(ns.StoredWeaponSummary(Weapon("Odd", { stat = "LUCK", mastery = "Nonsense" })), "1d8 damage, LUCK", "an unknown ability and mastery don't break it")
for _, name in ipairs(R.WEAPON_ORDER) do
    local words = Run("summary of " .. name, ns.StoredWeaponSummary, Weapon(name, { base = name, mastery = R.WEAPONS[name].mastery }))
    Check(type(words) == "string" and words:find("mastery: " .. R.WEAPONS[name].mastery, 1, true), name .. ": summary " .. tostring(words))
end

---------------------------------------------------------------------------
-- The share string, out and in
---------------------------------------------------------------------------
Eq(RPSheet:ExportStoredWeapon(99), "", "nothing to export")
local text = RPSheet:ExportStoredWeapon(1)
Check(text:sub(1, 6) == "!RPW1!" and #text > 20 and not text:find("%s"), "a string with the weapon mark and no spaces")
local back, problem = RPSheet:DecodeWeapon(text)
if Check(back ~= nil, "the string reads back: " .. tostring(problem)) then
    for key in pairs(TEMPLATE) do Eq(back[key], store[1][key], "round trip: " .. key) end
    Check(back ~= store[1], "what comes back is a new weapon")
end
-- every basic weapon and one of each oddity goes round
local function Round(weapon, label)
    local index = RPSheet:StoreWeapon(weapon)
    local got, why = RPSheet:DecodeWeapon(RPSheet:ExportStoredWeapon(index))
    if Check(got ~= nil, label .. ": " .. tostring(why)) then
        for key in pairs(TEMPLATE) do Eq(got[key], store[index][key], label .. ": " .. key) end
    end
    RPSheet:DeleteStoredWeapon(index)
    return got
end
for _, name in ipairs(R.WEAPON_ORDER) do
    local data = R.WEAPONS[name]
    Round(Weapon(name, { base = name, dice = data.dice[1], sides = data.dice[2], mastery = data.mastery, twoHands = data.versatile ~= nil, magic = 1 }), name)
end
Round(Weapon("Staff of Mending, the Long-Named One", { heal = true, stat = "WIS", dice = 3, sides = 4, proficient = false, style = false, ranged = true, cost = 123456, stowed = true }), "an own weapon")
-- pasted with line breaks and spaces
local broken = "  " .. text:sub(1, 20) .. "\n" .. text:sub(21, 40) .. " \t" .. text:sub(41) .. "\n"
Check(RPSheet:DecodeWeapon(broken) ~= nil, "a string pasted with line breaks still reads")
-- what is wrong with a string
local function Refused(input, wanted, label)
    local got, why = RPSheet:DecodeWeapon(input)
    Check(got == nil and type(why) == "string" and why:find(wanted, 1, true), ("%s: got %s / %s"):format(label, tostring(got), tostring(why)))
end
Refused("", "Paste a weapon string first", "nothing pasted")
Refused(nil, "Paste a weapon string first", "nil")
Refused("   \n ", "Paste a weapon string first", "only spaces")
Refused("hello", "not an RP Sheet weapon string", "any text")
Refused("!RPS1!" .. text:sub(7), "not an RP Sheet weapon string", "a character string")
Refused("!RPW1!", "damaged or incomplete", "the mark alone")
Refused("!RPW1!zzzz", "damaged or incomplete", "rubbish after the mark")
Refused(text:sub(1, #text - 7), "damaged or incomplete", "a string cut short")
local Codec = ns.Codec
local function Packed(payload) return "!RPW1!" .. Codec.Pack("print", payload) end
Refused(Packed({ format = 2, weapon = { name = "Future" } }), "newer version", "a newer format")
Refused(Packed({ format = 1 }), "damaged or incomplete", "no weapon in it")
Refused(Packed({ format = 1, weapon = "sword" }), "damaged or incomplete", "a weapon that is not a table")
Refused(Packed("just text"), "damaged or incomplete", "a payload that is not a table")
Refused(Packed({ format = 1, weapon = { name = "   " } }), "has no name", "a weapon without a name")
Refused(Packed({ format = 1, weapon = { dice = 2 } }), "has no name", "a weapon with no name field")
-- untrusted contents are cleaned
local dirty = RPSheet:DecodeWeapon(Packed({ format = 1, weapon = {
    name = "  |cffff0000Red|r Blade\n ", stat = "LUCK", mastery = "Winning", dice = 500, sides = -3, magic = 99, cost = -5,
    proficient = "yes", heal = 1, base = "Lightsaber", twoHands = true, evil = "yes", effects = { 1, 2 }, stowed = true,
} }))
if Check(dirty ~= nil, "a dirty weapon is still read") then
    Eq(dirty.name, "cffff0000Redr Blade", "colour codes and line breaks are stripped from the name")
    Check(dirty.stat == "STR" and dirty.mastery == "", "an unknown ability and mastery are reset")
    Check(dirty.dice == 20 and dirty.sides == 1 and dirty.magic == 3 and dirty.cost == 0, ("numbers are held to their limits: %s %s %s %s"):format(dirty.dice, dirty.sides, dirty.magic, dirty.cost))
    Check(dirty.proficient == false and dirty.heal == false, "only true is true")
    Check(dirty.base == "" and dirty.twoHands == false, "an unknown basic weapon is none, and not held in two hands")
    Check(dirty.evil == nil and dirty.effects == nil, "unknown fields are dropped")
    for key, default in pairs(TEMPLATE) do Check(type(dirty[key]) == type(default), "dirty weapon: " .. key .. " is " .. type(dirty[key])) end
    Run("summary of the dirty weapon", ns.StoredWeaponSummary, dirty)
end
-- a basic weapon's dice are the rules' own
local cheat = RPSheet:DecodeWeapon(Packed({ format = 1, weapon = { name = "Dagger of Doom", base = "Dagger", dice = 10, sides = 12 } }))
Check(cheat and cheat.dice == 1 and cheat.sides == 4 and cheat.base == "Dagger", "a basic weapon's dice can't be forged")
-- in through the string, onto the store, onto the character
local got = RPSheet:DecodeWeapon(text)
RPSheet:DeleteStoredWeapon(1)
Eq(RPSheet:FindStoredWeapon("Gorehowl"), nil, "gone from the store")
Eq(RPSheet:StoreWeapon(got), 2, "the decoded weapon is stored")
Check(RPSheet:AddStoredWeapon(2) and sheet.weapons[#sheet.weapons].name == "Gorehowl", "and added to the character")

---------------------------------------------------------------------------
-- The Armoury page and the buttons on the Weapons page
---------------------------------------------------------------------------
ns.RebuildOptions()
local options = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
local page = options.args.customize.args.armoury
if Check(page ~= nil, "the Armoury page exists") then
    Run("feed the Armoury page", Feed, page, "armoury")
    local count = 0
    for key in pairs(page.args) do
        if key:find("^stored") then count = count + 1 end
    end
    Eq(count, #RPSheet:StoredWeapons(), "a page per stored weapon")
    local import = page.args.import
    Run("paste a string", import.set, { "import", option = import }, RPSheet:ExportStoredWeapon(1))
    Check(page.args.status.name():find("Ready to add: Ashbringer", 1, true), "the page reads the string: " .. page.args.status.name())
    RPSheet:DeleteStoredWeapon(1)
    Run("add to armoury", page.args.apply.func, { "apply", option = page.args.apply })
    Check(RPSheet:FindStoredWeapon("Ashbringer") ~= nil, "Add to armoury stores it")
    Run("paste rubbish", import.set, { "import", option = import }, "rubbish")
    Check(page.args.status.name():find("not an RP Sheet weapon string", 1, true) and page.args.apply.disabled() == true, "rubbish is refused on the page")
end
FlushTimers()
Done("armoury")
