-- The item leftovers before 0.7.0: the Enspelled Staff as a make of the quarterstaff,
-- the reason an unmade item gives on its block, hoverable item terms, using items
-- while incapacitated, the right-click on an item that needs no attunement, and the
-- gathering checks with the "Next roll" bonus and their "Not now" line.
dofile(ARG3 .. "/t-test-items-lib.lua")
local UI = ns.UI

-- Text as it reads: hover links keep their words, colours go.
local function Plain(text)
    return (text:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
local function Linked(text, term)
    return text:find("|Hrpsheet:" .. term .. "|h", 1, true) ~= nil
end
-- The browser sources are local to their files: catch them as they are shown.
local RealShow = RPSheet.ShowItemBrowser
local caught
RPSheet.ShowItemBrowser = function(_, wanted) caught = wanted end
local function Source(open, ...)
    caught = nil
    Run("open a browser", open, ...)
    return caught
end

local sheet = NewChar("MAGE", 5)
local SHEET = Source(RPSheet.ToggleItemBrowser, RPSheet)

---------------------------------------------------------------------------
-- B1: an Enspelled Staff is a make of the quarterstaff
---------------------------------------------------------------------------
for _, rarity in ipairs({ "Uncommon", "Rare", "Very rare", "Legendary" }) do
    local key = ("Enspelled Staff (%s)"):format(rarity)
    local variant = R.ITEM_VARIANT[key]
    if Check(variant ~= nil, key .. " is a make") then
        Eq(table.concat(ns.VariantBases(variant), ","), "Quarterstaff", key .. ": made of the quarterstaff alone")
        Check(variant.rarity == rarity and variant.attune == true, key .. ": rarity and attunement from the listed staff")
        local item = ns.NewVariantItem(key, "Quarterstaff")
        if Check(item ~= nil, key .. ": made") then
            Eq(item.name, ("Enspelled Staff (Quarterstaff, %s)"):format(rarity:lower()), key .. ": its name")
            Check(R.ITEMS[item.name] == nil, key .. ": the name is not a listed item's")
            Eq(item.weight, 4, key .. ": weighs what the staff does")
        end
        Eq(R.RECIPE_BASE[key], "Quarterstaff", key .. ": made from a quarterstaff")
    end
end
Check(ns.NewVariantItem("Enspelled Staff (Rare)", "Longsword") == nil, "an Enspelled Staff isn't made of a longsword")
-- Carried and equipped it is a quarterstaff in hand.
local staff = RPSheet:AddVariantItem("Enspelled Staff (Rare)", "Quarterstaff")
RPSheet:SetEquipped(staff, true)
Eq(ns.ItemSlot(staff), "weapon", "the staff is wielded")
local readied = false
for _, weapon in ipairs(RPSheet:Sheet().weapons or {}) do
    if weapon.name == staff.name and weapon.base == "Quarterstaff" then readied = true end
end
Check(readied, "it is readied as a quarterstaff")
-- The Makes tab lists it.
local listed = false
for _, entry in ipairs(UI.ItemMakes.entries(RPSheet)) do
    if entry.name == "Enspelled Staff (Quarterstaff, legendary)" then listed = true end
end
Check(listed, "the Makes tab lists the legendary staff")
-- Crafting the listed staff costs its rarity plus the quarterstaff.
Eq((ns.CraftCost("Enspelled Staff (Uncommon)")), R.MAGIC_CRAFT.Uncommon.cost + R.ITEMS.Quarterstaff.cost, "making one pays for the quarterstaff")

---------------------------------------------------------------------------
-- B2: an item nobody makes says why on its block
---------------------------------------------------------------------------
local said = 0
for name, why in pairs(R.NOT_MADE) do
    local notes = Plain(table.concat(Run(name .. " notes", SHEET.notes, RPSheet, { name = name }), "\n"))
    if Check(notes:find("No profession makes it: " .. why, 1, true), name .. ": says why it isn't made: " .. notes) then said = said + 1 end
end
Check(said >= 3, "the unmade items say why: " .. said)
Eq(#SHEET.notes(RPSheet, { name = "Longsword" }), 0, "a made item has no such line")
Eq(#SHEET.notes(RPSheet, { name = "Potion of Greater Healing" }), 0, "nor a magic one with a recipe")

---------------------------------------------------------------------------
-- B3: item terms can be hovered
---------------------------------------------------------------------------
for _, term in ipairs({ "Attunement", "Consumable", "Harness", "Make" }) do
    Check(type(ns.Glossary[term]) == "string" and #ns.Glossary[term] > 40, term .. " is in the glossary")
end
local lines = table.concat(UI.ItemLines(RPSheet, "Ring of Protection"), "\n")
Check(Linked(lines, "Attunement") and Plain(lines):find("requires attunement", 1, true), "attunement is a term: " .. lines)
lines = table.concat(UI.ItemLines(RPSheet, "Potion of Greater Healing"), "\n")
Check(Linked(lines, "Consumable"), "a potion's block says it is used up: " .. lines)
lines = table.concat(UI.ItemLines(RPSheet, "Longsword"), "\n")
Check(not Linked(lines, "Consumable") and not Linked(lines, "Make"), "a longsword is neither")
local tongue = ns.NewVariantItem("Flame Tongue", "Longsword")
lines = table.concat(UI.ItemLines(RPSheet, tongue.name, tongue), "\n")
Check(Linked(lines, "Make") and Plain(lines):find("A magic make, counts as: Longsword.", 1, true), "a make is a term: " .. lines)
local arrow = ns.NewVariantItem("ammo1", "Arrow")
Check(Linked(table.concat(UI.ItemLines(RPSheet, arrow.name, arrow), "\n"), "Consumable"), "a magic arrow is used up")
-- the stable
local horse, cart = RPSheet:AddMount("Draft Horse"), RPSheet:AddMount("Cart")
Check(Linked(table.concat(UI.MountLines(RPSheet, "Draft Horse"), "\n"), "Harness"), "a horse's block links harness")
Check(Linked(table.concat(UI.MountLines(RPSheet, "Cart"), "\n"), "Harness"), "a cart's block links harness")
horse.hitched, cart.hitched = true, true
lines = Plain(table.concat(UI.MountLines(RPSheet, "Cart", cart), "\n"))
Check(lines:find("In harness: your harnessed animals pull it.", 1, true), "a cart in harness says so: " .. lines)
-- the crafting window's note on consumables
local CRAFT = Source(RPSheet.ShowCrafting, RPSheet)
if Check(CRAFT and CRAFT.notes, "the crafting window's source") then
    local recipe = ns.FindRecipe(R.PROFESSIONS.alchemy, "Potion of Greater Healing")
    local notes = table.concat(CRAFT.notes(RPSheet, { name = recipe.name, recipe = recipe, profession = R.PROFESSIONS.alchemy }), "\n")
    Check(Linked(notes, "Consumable") and Plain(notes):find("As a consumable, it takes half the usual time and cost.", 1, true), "consumable in the crafting notes: " .. notes)
end
-- the search reads the words of a link, not its code
local Search = UI.ItemSearch
local ring = { name = "Ring of Protection" }
Check(Search.Matches(RPSheet, { marks = function() return {} end, lines = function() return UI.ItemLines(RPSheet, "Ring of Protection") end }, ring, "requires attunement"),
    "the search finds linked words")
Check(not Search.Matches(RPSheet, { marks = function() return {} end, lines = function() return UI.ItemLines(RPSheet, "Ring of Protection") end }, ring, "rpsheet:"),
    "the search doesn't find the link's code")
-- the blocks of the browsers switch hover links on
Check(type(ns.EnableTermLinks) == "function", "ns.EnableTermLinks")

---------------------------------------------------------------------------
-- B4: nothing is used while incapacitated
---------------------------------------------------------------------------
local potion = RPSheet:AddItem("Potion of Greater Healing", 2)
local torch = RPSheet:AddItem("Torch", 2)
for _, condition in ipairs({ "Unconscious", "Incapacitated", "Stunned", "Paralyzed", "Petrified" }) do
    RPSheet:State().conditions[condition] = true
    local sent, mark = #SENT, #PRINTED
    RPSheet:UseItem(potion); RPSheet:UseItem(torch); FlushTimers()
    Check(potion.qty == 2 and torch.qty == 2 and #SENT == sent, condition .. ": nothing is used")
    local printed = PrintedSince(mark)
    Check(printed:find(("You can't drink Potion of Greater Healing while %s"):format(condition:lower()), 1, true)
        and printed:find("You can't use Torch while " .. condition:lower(), 1, true), condition .. ": says why: " .. printed)
    Check(printed:find("Someone else can give it to you with a bonus action", 1, true), condition .. ": says who can still give a potion")
    RPSheet:State().conditions[condition] = nil
end
local sent = #SENT
RPSheet:UseItem(potion); FlushTimers()
Check(potion.qty == 1 and SentSince(sent):find("uses [Potion of Greater Healing]", 1, true), "awake, the potion is drunk")
RPSheet:State().conditions.Prone = true
RPSheet:UseItem(torch); FlushTimers()
Eq(torch.qty, 1, "prone, a torch can still be lit")
RPSheet:State().conditions.Prone = nil

---------------------------------------------------------------------------
-- B5: a right-click on an item that needs no attunement says what it is for
---------------------------------------------------------------------------
local mark = #PRINTED
RPSheet:ToggleAttuned(torch)
Check(PrintedSince(mark):find("Torch needs no attunement. A right-click attunes to a magic item that asks for it", 1, true), "says what right-click is for: " .. PrintedSince(mark))
Check(not torch.attuned, "and nothing changes")

---------------------------------------------------------------------------
-- B6: gathering and archaeology take the "Next roll" bonus; "Not now" in red
---------------------------------------------------------------------------
sheet = NewChar("HUNTER", 5, { scores = { STR = 10, DEX = 14, CON = 12, INT = 10, WIS = 14, CHA = 8 } })
sheet.skills.Survival, sheet.skills.History, sheet.tools["Herbalism Kit"] = 1, 1, true
local region = RPSheet:GatherRegion()
local mod = RPSheet:GatherMod(R.PROFESSIONS.herbalism)
local function Roll(fn, dice)
    for _, value in ipairs(dice) do DICE[#DICE + 1] = value end
    local at = #SENT
    Run("roll", fn)
    FlushTimers(); RPSheet.busy = false
    DICE = {}
    return SentSince(at)
end
RPSheet:AddItem("Herbalism Kit", 1)
-- a d20 just short of the DC, which the bonus lifts over it
local short = region.dc - mod - 1
RPSheet:SetRollBonusDie(1)
local line = Roll(function() RPSheet:Gather(R.PROFESSIONS.herbalism) end, { short, 3 })
Check(line:find(("%d + %d + 3 [1d4] = %d"):format(short, mod, short + mod + 3), 1, true) and line:find("finds something", 1, true),
    "herbalism adds the d4 and finds: " .. line)
Eq(RPSheet.rollBonusDie, nil, "the d4 is used up")
RPSheet:ChangeRollBonusFlat(-2)
line = Roll(function() RPSheet:Gather(R.PROFESSIONS.herbalism) end, { short + 1 })
Check(line:find("- 2 [next roll -2]", 1, true) and line:find("nothing found", 1, true), "a penalty can make it fail: " .. line)
local history = 0
for _, skill in ipairs(R.SKILLS) do if skill.name == "History" then history = RPSheet:SkillMod(skill) end end
RPSheet:ChangeRollBonusFlat(5)
line = Roll(function() RPSheet:Dig() end, { region.dc - history - 5, 1 })
Check(line:find("+ 5 [next roll +5]", 1, true) and line:find("unearths 1 fragment", 1, true), "archaeology takes the bonus: " .. line)
-- the gathering row's tooltip says what stands in the way, like the making rows
local tips = {}
local RealAdd, RealHeading = UI.AddLabel, UI.AddHeading
UI.AddLabel = function(_, _, text, _, title, body) tips[#tips + 1] = { text = text, title = title, body = body } end
UI.AddHeading = function() end
local function GatherTip()
    tips = {}
    Run("profession section", UI.ProfessionSection, RPSheet, {})
    for _, tip in ipairs(tips) do
        if tip.title == "Herbalism" then return type(tip.body) == "function" and tip.body() or tip.body end
    end
    return ""
end
Check(not GatherTip():find("Not now", 1, true), "with the kit in hand nothing stands in the way")
RPSheet:DropItem(RPSheet:CarriedItem("Herbalism Kit"))
local tip = GatherTip()
Check(tip:find("|cffff5555Not now: you don't carry your Herbalism Kit", 1, true), "without it the tooltip says so in red: " .. tip)
UI.AddLabel, UI.AddHeading = RealAdd, RealHeading
RPSheet.ShowItemBrowser = RealShow

Done("leftovers")
