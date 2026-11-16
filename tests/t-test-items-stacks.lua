-- Carried items over time: which magic items share an entry, the mark the Customize
-- page leaves on an item it changed, and what the upkeep then refreshes from the
-- catalogue: everything of an unchanged item, nothing of a changed one, and the old
-- careful rule for items saved before changes were marked.
dofile(ARG3 .. "/t-test-items-lib.lua")

local sheet = NewChar("WARRIOR", 5)
local purse = RPSheet:Purse()
local function Gold(gp) purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, gp, 0, 0, 0 end
local function Clear()
    for index = #sheet.items, 1, -1 do table.remove(sheet.items, index) end
end
local function Entries(name)
    local count, total = 0, 0
    for _, item in ipairs(sheet.items) do
        if item.name == name then count, total = count + 1, total + item.qty end
    end
    return count, total
end
-- An entry as an older version saved it: no marks.
local function Old(name, fields)
    local item = ns.NewItem(name)
    item.tracked = false
    for key, value in pairs(fields or {}) do item[key] = value end
    sheet.items[#sheet.items + 1] = item
    return item
end
local REGISTRY = LibStub("AceConfigRegistry-3.0")
local function Page(item)
    ns.RebuildOptions()
    local options = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
    for index, other in ipairs(sheet.items) do
        if other == item then
            for key, page in pairs(options.args.customize.args.items.args) do
                if type(page) == "table" and page.type == "group" and page.order == index and page.args and page.args.qty then return page.args end
            end
        end
    end
    -- by name, when the pages are not ordered by index
    for _, page in pairs(options.args.customize.args.items.args) do
        if type(page) == "table" and page.type == "group" and page.args and page.args.name
            and page.args.name.get({ "name", option = page.args.name }) == item.name then return page.args end
    end
end
local function Set(option, value) Run("set", option.set, { "x", option = option }, value) end

---------------------------------------------------------------------------
-- What stacks
---------------------------------------------------------------------------
Check(ns.MagicStacks("Potion of Healing") and ns.MagicStacks("Dust of Disappearance") and ns.MagicStacks("+1 Ammunition"), "potions, dusts and magic ammunition stack")
Check(not ns.MagicStacks("Ring of Protection") and not ns.MagicStacks("Longsword") and not ns.MagicStacks("Nonsense"), "a lasting magic item, plain gear and an unknown thing don't")
-- Used up, but attuned to: an entry each.
local needsAttuning = 0
for name in pairs(R.CONSUMABLES) do
    if R.ITEMS[name] and R.ITEMS[name].attune then
        needsAttuning = needsAttuning + 1
        Check(not ns.MagicStacks(name), name .. " needs attunement and stacks")
    end
end
Check(needsAttuning > 0, "some used-up items need attunement (Candle of Invocation)")

Gold(1000)
Check(RPSheet:BuyItem("Potion of Healing") and RPSheet:BuyItem("Potion of Healing"), "two potions bought")
Eq(#sheet.items, 1, "two bought potions are one entry")
Eq(sheet.items[1].qty, 2, "of two")
local potion = sheet.items[1]
Check(RPSheet:AddItem("Potion of Healing", 3) == potion and potion.qty == 5, "adding three more makes five")
Eq(RPSheet:CarriedWeight() - RPSheet:Coins() / 5000, 5 * potion.weight, "and they weigh as five")
-- every stacking item, added twice
for _, name in ipairs(R.ITEM_NAMES["Magic items"]) do
    Clear()
    local first, second = RPSheet:AddItem(name), RPSheet:AddItem(name)
    if ns.MagicStacks(name) then
        Check(first == second and first.qty == 2 and #sheet.items == 1, name .. ": two are not one entry of two")
    else
        Check(first ~= second and first.qty == 1 and #sheet.items == 2, name .. ": two are not two entries")
    end
end
-- one the player attuned, edited or wrote stays apart
Clear()
local candleA = RPSheet:AddItem("Candle of Invocation")
Check(RPSheet:AddItem("Candle of Invocation") ~= candleA, "a used-up item that is attuned to is an entry each")
Clear()
potion = RPSheet:AddItem("Potion of Healing", 2)
potion.edited = true
local second = RPSheet:AddItem("Potion of Healing")
Check(second ~= potion and potion.qty == 2 and second.qty == 1, "an edited potion stays its own entry")
Check(RPSheet:AddItem("Potion of Healing") == second and second.qty == 2, "the next one joins the untouched entry")
potion.edited, potion.attuned = false, true
Check(RPSheet:AddItem("Potion of Healing") == second, "an attuned one is not joined either")
potion.attuned = false
-- using one up takes one off the stack
Clear()
potion = RPSheet:AddItem("Potion of Healing", 2)
RPSheet:UseItem(potion); FlushTimers()
Check(potion.qty == 1 and #sheet.items == 1, "drinking one leaves one")
RPSheet:UseItem(potion); FlushTimers()
Eq(#sheet.items, 0, "drinking the last takes the entry")
-- plain gear as before
Clear()
local torch = RPSheet:AddItem("Torch", 2)
torch.edited = true
Check(RPSheet:AddItem("Torch", 3) == torch and torch.qty == 5, "plain gear of one name always stacks")
-- crafting adds to the stack
Clear()
sheet.tools["Herbalism Kit"] = true
RPSheet:AddItem("Herbalism Kit")
Gold(1000)
local alchemy = R.PROFESSIONS.alchemy
local recipe = ns.FindRecipe(alchemy, "Potion of Healing")
Check(RPSheet:Craft(alchemy, recipe) and RPSheet:Craft(alchemy, recipe), "two potions brewed"); FlushTimers()
local entries, total = Entries("Potion of Healing")
Check(entries == 1 and total == 2, "brewed potions are one entry of two")

-- potions from before they stacked are put together when the character is loaded
Clear()
local a, b = Old("Potion of Healing"), Old("Potion of Healing", { qty = 3 })
local noted = Old("Potion of Healing", { desc = "From the hermit." })
local ringA, ringB = Old("Ring of Protection"), Old("Ring of Protection")
local arrowA, arrowB = ns.NewVariantItem("ammo1", "Arrow"), ns.NewVariantItem("ammo1", "Arrow")
sheet.items[#sheet.items + 1], sheet.items[#sheet.items + 2] = arrowA, arrowB
local unnamed = Old("", { magic = true })
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
entries, total = Entries("Potion of Healing")
Check(entries == 2 and total == 5 and a.qty == 4 and noted.qty == 1, ("old potions are put together, the one with a note of its own stays: %d entries, %d potions"):format(entries, total))
Eq((Entries("Ring of Protection")), 2, "two old rings stay two")
Check(Entries("Arrow +1") == 1 and arrowA.qty == 2, "two magic arrows become one entry of two")
Check(tContains(sheet.items, unnamed), "an unnamed item is left where it is")
Run("NormalizeInventory again", ns.NormalizeInventory, sheet)
Check(a.qty == 4 and select(2, Entries("Potion of Healing")) == 5, "running it again changes nothing")

---------------------------------------------------------------------------
-- The mark the Customize page leaves
---------------------------------------------------------------------------
Clear()
local ring = RPSheet:AddItem("Ring of Protection")
Check(ring.tracked and not ring.edited, "a new item is tracked and unedited")
local page = Page(ring)
if Check(page ~= nil and page.name and page.edited, "the ring's page") then
    -- what is not a change to the item
    Set(page.qty, 2); Set(page.equipped, true); Set(page.attuned, true)
    Check(ring.qty == 2 and ring.equipped and ring.attuned and not ring.edited, "how many, worn and attuned are not edits")
    Set(page.qty, 1); Set(page.equipped, false); Set(page.attuned, false)
    Check(page.edited.get() == false, "Keep my changes is unticked")
    -- every field that is the item itself
    local changes = {
        { "name", "Ring of Protection" }, { "weight", "2" }, { "cost", "5 gp" }, { "desc", "A gift." }, { "base", "" }, { "magic", true },
        { "rarity", "Rare" }, { "attune", true }, { "limit", "" },
    }
    for _, change in ipairs(changes) do
        ring.edited = false
        Set(page[change[1]], change[2])
        Check(ring.edited, "setting " .. change[1] .. " marks the item as edited")
    end
    Check(page.edited.get() == true, "and the tick shows it")
    -- effects
    ring.edited = false
    local had = #ring.effects
    Run("add effect", page.addEffect.func, { "addEffect", option = page.addEffect })
    Check(ring.edited and #ring.effects == had + 1, "adding an effect marks it")
    page = Page(ring)
    ring.edited = false
    local last = page["effect" .. (had + 1)]
    Set(last.args.flat, 3)
    Check(ring.edited and ring.effects[had + 1].flat == 3, "changing an effect marks it")
    ring.edited = false
    Run("remove effect", last.args.remove.func, { "remove", option = last.args.remove })
    Check(ring.edited and #ring.effects == had, "removing an effect marks it")
end
-- a bonus is only on something that is armor, a shield or a weapon
Clear()
local blade = RPSheet:AddItem("Flame Tongue")
page = Page(blade)
if Check(page ~= nil, "the blade's page") then
    Set(page.base, "Longsword")
    Check(blade.edited and blade.base == "Longsword", "saying what it counts as is an edit")
    blade.edited = false
    Set(page.bonus, 1)
    Check(blade.edited and blade.bonus == 1, "and so is its bonus")
end
-- a scroll's "written by you" is not
Clear()
local scroll = RPSheet:AddItem(R.SCROLL_PREFIX .. "Fireball")
page = Page(scroll)
if Check(page ~= nil and page.scribed, "the scroll's page") then
    Set(page.scribed, true)
    Check(scroll.scribed and not scroll.edited, "who wrote a scroll is not an edit")
    Check(page.edited.hidden() == true, "an item no list has can't follow one: no tick")
end

---------------------------------------------------------------------------
-- What the upkeep refreshes
---------------------------------------------------------------------------
local known = R.ITEMS["Ring of Protection"]
local function Stale(item)
    -- As if the catalogue had since changed everything about it.
    item.desc, item.cost, item.weight, item.rarity = "What the list said last year.", 7, 9, "Common"
    item.attune, item.limit, item.magic = false, "UNARMORED", false
    item.effects = { { target = "AC", flat = 5, stat = "", times = 1, mode = "" }, { target = "HP", flat = 9, stat = "", times = 1, mode = "" } }
end
local function IsListed(item, label)
    Check(item.desc == known.desc and item.cost == known.cost and item.weight == known.weight and item.rarity == "Rare" and item.magic
        and item.attune and item.limit == "", label .. ": note, price, weight, rarity, attunement")
    Check(#item.effects == #known.effects and item.effects[1].target == known.effects[1].target and item.effects[1].flat == known.effects[1].flat
        and item.effects[1] ~= known.effects[1], label .. ": effects, as copies")
end
Clear()
ring = RPSheet:AddItem("Ring of Protection")
ring.qty, ring.equipped, ring.attuned = 2, true, true
Stale(ring)
ring.attune = true
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
IsListed(ring, "an unedited item is refreshed fully")
Check(ring.qty == 2 and ring.equipped and ring.attuned and ring.tracked and not ring.edited, "how many, worn and attuned stay")
-- an edited one is left alone
Stale(ring)
ring.edited = true
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(ring.desc == "What the list said last year." and ring.cost == 7 and ring.weight == 9 and ring.rarity == "Common" and not ring.attune
    and ring.limit == "UNARMORED" and #ring.effects == 2 and ring.effects[1].flat == 5, "an edited item is left exactly as it is")
-- unticking Keep my changes sets it back at once
page = Page(ring)
if Check(page ~= nil, "the ring's page") then
    Set(page.edited, false)
    IsListed(ring, "unticking Keep my changes")
    Check(not ring.edited and ring.tracked, "and it follows the lists again")
end
-- an item that no longer asks for attunement lets go of it
local gauntlets = RPSheet:AddItem("Gauntlets of Ogre Power")
gauntlets.attuned = true
local wasAttune = R.ITEMS["Gauntlets of Ogre Power"].attune
R.ITEMS["Gauntlets of Ogre Power"].attune = nil
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(not gauntlets.attune and not gauntlets.attuned, "an item that stops asking for attunement is no longer attuned")
R.ITEMS["Gauntlets of Ogre Power"].attune = wasAttune
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(gauntlets.attune and not gauntlets.attuned, "and asks again when the list does")
-- plain gear follows its price and weight
Clear()
local rope = RPSheet:AddItem("Rope")
rope.cost, rope.weight = 1, 1
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(rope.cost == R.ITEMS.Rope.cost and rope.weight == R.ITEMS.Rope.weight, "unedited plain gear follows the list's price and weight")
rope.cost, rope.edited = 1, true
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Eq(rope.cost, 1, "edited plain gear keeps its price")
-- what no list has is never touched
local locket = RPSheet:AddItem("Grandmother's Locket")
locket.desc, locket.cost = "Silver.", 300
local written = RPSheet:AddItem(R.SCROLL_PREFIX .. "Fireball")
written.scribed, written.cost, written.desc = true, 123, "Mine."
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(locket.desc == "Silver." and locket.cost == 300, "an item of your own is left alone")
Check(written.scribed and written.cost == 123 and written.desc == "Mine.", "and so is a scroll")

-- every listed item: fresh, the upkeep changes nothing; stale, it comes back
local fields = { "desc", "cost", "weight", "rarity", "attune", "limit", "magic" }
local kinds = 0
for _, kind in ipairs(R.ITEM_KINDS) do
    kinds = kinds + 1
    for _, name in ipairs(R.ITEM_NAMES[kind]) do
        Clear()
        local item, fresh = RPSheet:AddItem(name), ns.NewItem(name)
        Run("upkeep " .. name, ns.NormalizeInventory, sheet)
        for _, field in ipairs(fields) do
            if item[field] ~= fresh[field] then Problem(("%s: the upkeep changed %s of a fresh item"):format(name, field)) end
        end
        Stale(item)
        Run("upkeep " .. name, ns.NormalizeInventory, sheet)
        for _, field in ipairs(fields) do
            if item[field] ~= fresh[field] then Problem(("%s: the upkeep didn't bring %s back"):format(name, field)) end
        end
        Eq(#item.effects, #fresh.effects, name .. ": effects")
        CHECKS = CHECKS + 1
    end
end
Check(kinds >= 8, "every kind of item was gone through")

---------------------------------------------------------------------------
-- Items from before the mark: the careful rule
---------------------------------------------------------------------------
Clear()
local bare = Old("Ring of Protection", { desc = "", cost = 0, weight = 0, rarity = "", magic = false, attune = false, effects = {} })
local own = Old("Ring of Protection", { desc = "My aunt's ring.", cost = 5 })
local tuned = Old("Ring of Protection", { effects = { { target = "AC", flat = 3, stat = "", times = 1, mode = "" } } })
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
IsListed(bare, "a bare old item is brought up to date")
Check(bare.tracked, "and, matching the list in everything, is tracked from now on")
Check(own.desc == "My aunt's ring." and own.cost == 5 and not own.tracked and not own.edited, "an old item with a note of its own is left alone, and stays under the careful rule")
Check(#tuned.effects == 1 and tuned.effects[1].flat == 3 and not tuned.tracked, "an old item with effects of its own keeps them")
-- once tracked, it follows the list like a new one
Stale(bare)
Stale(own)
own.desc = "My aunt's ring."
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
IsListed(bare, "the old item that matched now follows the list")
Check(own.cost == 7 and #own.effects == 2, "the other one still doesn't")
-- an old item that happens to match already
Clear()
local same = Old("Cloak of Protection")
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(same.tracked, "an old item that says what the list says is tracked")
-- old plain gear: only when it matches
Clear()
local oldRope, cheapRope = Old("Rope"), Old("Rope", { cost = 1 })
Run("NormalizeInventory", ns.NormalizeInventory, sheet)
Check(oldRope.tracked and not cheapRope.tracked and cheapRope.cost == 1, "old plain gear is tracked when it matches, and left alone when it doesn't")

---------------------------------------------------------------------------
-- The marks are saved, exported and imported
---------------------------------------------------------------------------
Clear()
ring = RPSheet:AddItem("Ring of Protection")
ring.edited, ring.desc = true, "Changed."
local fresh = RPSheet:AddItem("Cloak of Protection")
local legacy = Old("Amulet of Health", { desc = "Old and mine." })
Check(R.TEMPLATES.item.edited == false and R.TEMPLATES.item.tracked == false, "the item template has both marks, off")
local back = Run("DecodeSheet", RPSheet.DecodeSheet, RPSheet, RPSheet:ExportSheet())
if Check(type(back) == "table" and #back.items == 3, "the export decodes") then
    Check(back.items[1].edited == true and back.items[1].tracked == true and back.items[1].desc == "Changed.", "an edited item comes back edited")
    Check(back.items[2].edited == false and back.items[2].tracked == true, "an untouched one tracked")
    Check(back.items[3].edited == false and back.items[3].tracked == false and back.items[3].desc == "Old and mine.", "an old one as it was")
end
-- an export from before the marks: every item is an old one
for _, item in ipairs(sheet.items) do item.edited, item.tracked = nil, nil end
back = Run("DecodeSheet old", RPSheet.DecodeSheet, RPSheet, RPSheet:ExportSheet())
if Check(type(back) == "table" and #back.items == 3, "the old export decodes") then
    Check(back.items[1].desc == "Changed." and back.items[1].edited == false and back.items[1].tracked == false, "an item without marks is taken as an old one, and kept")
    Check(back.items[2].tracked == true, "one that matches the list is tracked")
end
for _, item in ipairs(sheet.items) do item.edited, item.tracked = item.edited == true, item.tracked == true end
-- a saved sheet goes through the same door
ns.NormalizeState(RPSheet:State())
Check(sheet.items[1].desc == "Changed." and sheet.items[1].edited == false, "NormalizeState fills the marks in")

-- A piece of magic ammunition is used up like a potion: an enchanter can't take it apart.
Clear()
sheet.level = 17
sheet.tools["Woodcarver's Tools"] = true
RPSheet:AddItem("Woodcarver's Tools")
local arrow, plusSword = RPSheet:AddVariantItem("ammo1", "Arrow"), RPSheet:AddVariantItem("weapon1", "Longsword")
local brew = RPSheet:AddItem("Potion of Healing")
local apart = RPSheet:Disenchantable()
Check(tContains(apart, plusSword) and not tContains(apart, arrow) and not tContains(apart, brew), "a magic sword can be disenchanted, a magic arrow and a potion can't")

Done("stacks")
