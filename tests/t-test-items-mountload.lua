-- What a mount carries and a team pulls: a ridden mount with more on its back than
-- it can carry moves 5 feet at most, as the character does on foot; animals in
-- harness move five times what they carry, the vehicle included, and no more.
dofile(ARG3 .. "/t-test-items-lib.lua")
local UI = ns.UI

local function Explained(fn, ...)
    local mark = #PRINTED
    Run("explain", fn, RPSheet, ...)
    local text = PrintedSince(mark)
    return tonumber(text:match("|cffffd100(%-?%d+)")), text
end
local LABELS = {}
local RealAddLabel = UI.AddLabel
UI.AddLabel = function(parent, width, text, onClick, tipTitle, tipBody, explain)
    LABELS[#LABELS + 1] = { text = text, tipTitle = tipTitle, tipBody = type(tipBody) == "function" and tipBody() or tipBody }
    return RealAddLabel(parent, width, text, onClick, tipTitle, tipBody, explain)
end
local function Section()
    LABELS = {}
    Run("MountSection", UI.MountSection, RPSheet, STUB("body"))
    return LABELS
end
local function Row(start)
    for _, label in ipairs(Section()) do
        if label.text:find("^" .. start) then return label end
    end
end

-- Strength 20: the character itself carries 300 lb., so only the mount is in question.
local sheet = NewChar("WARRIOR", 5, { scores = { STR = 20, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
local function Carry(pounds)
    for index = #sheet.items, 1, -1 do table.remove(sheet.items, index) end
    local purse = RPSheet:Purse()
    purse.pp, purse.gp, purse.ep, purse.sp, purse.cp = 0, 0, 0, 0, 0
    if pounds > 0 then
        local lump = RPSheet:AddItem("Lump of lead")
        lump.weight = pounds
    end
end

---------------------------------------------------------------------------
-- A ridden mount and what is on its back
---------------------------------------------------------------------------
local pony, horse = RPSheet:AddMount("Pony"), RPSheet:AddMount("Riding Horse")
sheet.size = "S"
Eq(pony.capacity, 225, "a pony carries 225 lb.")
RPSheet:ToggleRiding(pony); FlushTimers()
Carry(100)
Eq(RPSheet:RiderLoad(), 100, "with no weight said, only the gear counts")
Check(RPSheet:MountHeld(pony) == nil and RPSheet:Speed() == 40, "100 lb. on a pony: its own 40 feet")
Carry(225)
Check(RPSheet:MountHeld(pony) == nil and RPSheet:Speed() == 40, "exactly what it carries is fine")
Carry(226)
local limit, why = RPSheet:MountHeld(pony)
Check(limit == 5 and why:find("carries 226.0 lb., more than the 225 lb. it can", 1, true), "a pound more holds it to 5 feet: " .. tostring(why))
Eq(RPSheet:Speed(), 5, "and that is the Speed in the saddle")
Eq(RPSheet:MountSpeed(pony), 5, "MountSpeed")
Check(not RPSheet:Overloaded() and RPSheet:Speed(true) == 30, "the character itself is not overloaded: 30 on foot")
local feet, text = Explained(RPSheet.ExplainSpeed)
Check(feet == 5 and text:find("riding Pony", 1, true) and text:find("holds it to 5 feet", 1, true) and text:find("On foot your speed is 30 ft", 1, true), "explained: " .. text)
Check(not text:find("don't slow it", 1, true), "the explanation doesn't say the load doesn't matter")
Check(UI.SpeedTip(RPSheet):find("holds it to 5 feet", 1, true), "the Speed row's tip says so: " .. UI.SpeedTip(RPSheet))
local row = Row("Riding ")
if Check(row ~= nil, "the Riding row") then
    Check(row.text:find("|cffff5555", 1, true) and row.text:find("5 ft", 1, true), "the Riding row shows 5 ft in red: " .. row.text)
    Check(row.tipBody:find("more than the 225 lb. it can", 1, true) and row.tipBody:find("Say what you weigh", 1, true), "its tip: " .. row.tipBody)
end
-- the rider's own weight, once said
Carry(190)
Check(RPSheet:Speed() == 40, "190 lb. of gear alone is fine")
sheet.bodyWeight = 40
Eq(RPSheet:RiderLoad(), 230, "a 40 lb. rider with 190 lb. of gear weighs 230")
Eq(RPSheet:Speed(), 5, "which is more than the pony carries")
row = Row("Riding ")
Check(row and row.tipBody:find("You weigh 40 lb. and your gear 190.0 lb.: 230.0 lb. on its back", 1, true), "the tip adds them up: " .. tostring(row and row.tipBody))
sheet.bodyWeight = 35
Check(RPSheet:Speed() == 40, "five pounds lighter, and it moves freely")
feet, text = Explained(RPSheet.ExplainSpeed)
Check(feet == 40 and text:find("don't slow it", 1, true), "explained without a hold: " .. text)
-- the weight is carried by the mount only: on foot it is not gear
RPSheet:ToggleRiding(pony); FlushTimers()
Check(RPSheet:CarriedWeight() == 190 and RPSheet:Speed() == 30, "on foot the character's own weight is not a load")
-- a flyer is held on the ground and in the air alike
sheet.size, sheet.bodyWeight = "M", 180
RPSheet:AddItem("Exotic Saddle")
local gryphon = RPSheet:AddMount("Gryphon")
RPSheet:ToggleRiding(gryphon); FlushTimers()
Carry(40); RPSheet:AddItem("Exotic Saddle")
Check(gryphon.riding and RPSheet:Speed() == 80 and UI.RidingMark(RPSheet) == " fly", "a gryphon flies 80 feet")
Carry(400); RPSheet:AddItem("Exotic Saddle")
Check(RPSheet:RiderLoad() == 620 and RPSheet:Speed() == 5, "620 lb. on a gryphon that carries 540: 5 feet")
-- a mount that swims and climbs: every speed is held
RPSheet:ToggleRiding(gryphon); FlushTimers()
local elekk = RPSheet:AddMount("Elekk")
RPSheet:ToggleRiding(elekk); FlushTimers()
Check(elekk.riding and RPSheet:MoveSpeed("climb") == 5 and RPSheet:Speed() == 5, "an overloaded elekk climbs 5 feet too")
feet, text = Explained(RPSheet.ExplainMoveSpeed, "climb")
Check(feet == 5 and text:find("holds it to 5 feet", 1, true), "the climbing speed explained: " .. text)
Carry(100)
Check(RPSheet:MoveSpeed("climb") == 30 and RPSheet:Speed() == 40, "lightened, it climbs 30 and walks 40")
-- a mount whose capacity is not set is not judged
local beast = RPSheet:AddMount("Something of my own")
beast.speed, beast.capacity, beast.size = 50, 0, "L"
RPSheet:ToggleRiding(beast); FlushTimers()
Carry(5000)
Check(beast.riding and RPSheet:MountHeld(beast) == nil and RPSheet:Speed() == 50, "a mount without a capacity is not held")
RPSheet:ToggleRiding(beast); FlushTimers()
-- every listed mount: at its capacity free, a pound over held to 5
sheet.bodyWeight = 0
for _, name in ipairs(R.MOUNT_NAMES.Mounts) do
    local entry = ns.NewMount(name)
    local pace = ns.MountPace(entry)
    Carry(entry.capacity)
    Check(RPSheet:MountHeld(entry) == nil and RPSheet:MountSpeed(entry) == pace, name .. ": held at its capacity")
    Carry(entry.capacity + 1)
    Check(RPSheet:MountHeld(entry) == 5 and RPSheet:MountSpeed(entry) == math.min(5, pace), name .. ": not held a pound over")
end

---------------------------------------------------------------------------
-- A team and what it pulls
---------------------------------------------------------------------------
sheet = NewChar("WARRIOR", 5, { scores = { STR = 20, DEX = 14, CON = 13, INT = 10, WIS = 10, CHA = 12 } })
Carry(50)
local draft, second, wagon, cart = RPSheet:AddMount("Draft Horse"), RPSheet:AddMount("Draft Horse"), RPSheet:AddMount("Wagon"), RPSheet:AddMount("Cart")
local cat, ship, carpet = RPSheet:AddMount("Beast companion"), RPSheet:AddMount("Keelboat"), RPSheet:AddMount("Carpet of Flying, 3 ft. x 5 ft.")
Check(ns.CanPull(draft) and not ns.CanPull(wagon) and not ns.CanPull(cat) and not ns.CanPull(ship), "animals pull")
Check(ns.IsDrawn(wagon) and ns.IsDrawn(cart) and not ns.IsDrawn(ship) and not ns.IsDrawn(draft), "drawn vehicles are pulled")
if carpet and R.MOUNTS[carpet.name] then Check(not ns.CanPull(carpet), "a flying carpet pulls nothing") end
Check(RPSheet:Team() == nil, "nothing in harness yet")
RPSheet:SetHitched(draft, true)
Check(draft.hitched and RPSheet:Team() == nil, "an animal alone is no team")
RPSheet:SetHitched(wagon, true)
local vehicle, animals = RPSheet:Team()
Check(vehicle == wagon and #animals == 1 and animals[1] == draft, "a draft horse before a wagon")
local pulled, most = RPSheet:TeamLoad()
Check(pulled == 400 and most == 540 * 5, ("the empty wagon weighs 400 of the 2700 lb. it can pull: %d of %d"):format(pulled, most))
RPSheet:SetHitched(cart, true)
Check(cart.hitched and not wagon.hitched and RPSheet:Team() == cart, "one vehicle in harness at a time")
RPSheet:SetHitched(wagon, true)
RPSheet:SetHitched(cat, true); RPSheet:SetHitched(ship, true)
Check(not cat.hitched and not ship.hitched, "a companion and a ship don't go in harness")
-- riding the harnessed horse
RPSheet:ToggleRiding(draft); FlushTimers()
wagon.load = 2300
Check(select(1, RPSheet:TeamLoad()) == 2700 and RPSheet:MountHeld(draft) == nil and RPSheet:Speed() == 40, "exactly five times what it carries moves")
Check(RPSheet:VehicleLoadProblem(wagon) == nil, "and nothing is wrong with the wagon")
wagon.load = 2301
limit, why = RPSheet:MountHeld(draft)
Check(limit == 0 and why:find("harnessed to the Wagon, which with its load weighs 2701 lb.: more than the 2700 lb. its team can move", 1, true), "a pound more and it stands: " .. tostring(why))
Eq(RPSheet:Speed(), 0, "the rider of a harnessed horse stands still with it")
feet, text = Explained(RPSheet.ExplainSpeed)
Check(feet == 0 and text:find("holds it to 0 feet", 1, true), "explained: " .. text)
Check((RPSheet:VehicleLoadProblem(wagon) or ""):find("more than the 2700 lb. its team can move", 1, true), "the wagon says so")
Check(RPSheet:VehicleLoadProblem(cart) == nil, "the cart that is not in harness doesn't")
row = Row("In harness ")
if Check(row ~= nil, "the In harness row") then
    Check(row.text:find("Wagon", 1, true) and row.text:find("|cffff5555", 1, true) and row.text:find("2701 of 2700 lb.", 1, true), "it shows the load in red: " .. row.text)
    Check(row.tipBody:find("Pulled by Draft Horse", 1, true) and row.tipBody:find("more than the team can move", 1, true), "its tip: " .. row.tipBody)
end
local lines = table.concat(UI.MountLines(RPSheet, wagon.name, wagon), "\n")
Check(lines:find("Loaded with 2301 lb.", 1, true) and lines:find("In harness", 1, true) and lines:find("its team can move", 1, true), "the wagon's block: " .. lines)
-- a second horse
RPSheet:SetHitched(second, true)
pulled, most = RPSheet:TeamLoad()
Check(most == 5400 and RPSheet:MountHeld(draft) == nil and RPSheet:Speed() == 40, "two horses pull twice as much")
row = Row("In harness ")
Check(row and not row.text:find("|cffff5555", 1, true) and row.tipBody:find("Pulled by Draft Horse, Draft Horse", 1, true), "the row names the team")
-- out of harness, the load is not the horse's
wagon.load = 99999
Eq(RPSheet:Speed(), 0, "far too much even for two")
RPSheet:SetHitched(draft, false)
Check(not draft.hitched and RPSheet:Speed() == 40, "taken out of harness, the horse moves freely")
RPSheet:SetHitched(draft, true)
RPSheet:SetHitched(wagon, false)
Check(RPSheet:Team() == nil and RPSheet:Speed() == 40, "with no vehicle in harness there is nothing to pull")
-- the rider's own load still counts on a harnessed horse
RPSheet:SetHitched(wagon, true)
wagon.load = 0
Carry(541)
Check(RPSheet:MountHeld(draft) == 5 and RPSheet:Speed() == 5, "an overloaded rider on a harnessed horse: 5 feet")
Carry(50)
-- cargo of a powered vehicle and a ship
ship.load = 1000
Check(RPSheet:VehicleLoadProblem(ship) == nil, "a keelboat takes half a ton")
ship.load = 1001
Check((RPSheet:VehicleLoadProblem(ship) or ""):find("more than the 1000 lb. of cargo it takes", 1, true), "and no more: " .. tostring(RPSheet:VehicleLoadProblem(ship)))
lines = table.concat(UI.MountLines(RPSheet, ship.name, ship), "\n")
Check(lines:find("Loaded with 1001 lb.", 1, true) and lines:find("of cargo it takes", 1, true), "the ship's block: " .. lines)
Check(RPSheet:VehicleLoadProblem(draft) == nil, "an animal has no cargo")

---------------------------------------------------------------------------
-- The Customize page
---------------------------------------------------------------------------
ns.RebuildOptions()
local options = LibStub("AceConfigRegistry-3.0"):GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
local pages = options.args.customize.args.mounts.args
local function Set(option, value) Run("set", option.set, { "x", option = option }, value) end
if Check(pages.bodyWeight ~= nil, "Your weight is on the Mounts page") then
    Set(pages.bodyWeight, "172")
    Eq(sheet.bodyWeight, 172, "set")
    Set(pages.bodyWeight, "-5"); Eq(sheet.bodyWeight, 0, "not below 0")
    Set(pages.bodyWeight, "5000"); Eq(sheet.bodyWeight, 999, "nor above 999")
    Set(pages.bodyWeight, "nonsense"); Eq(sheet.bodyWeight, 0, "nonsense is 0")
    Eq(pages.bodyWeight.get(), "0", "shown")
end
local function PageOf(entry)
    for _, page in pairs(pages) do
        if type(page) == "table" and page.type == "group" and page.args and page.args.load
            and page.args.name.get({ "name", option = page.args.name }) == entry.name and page.args.load.get() == tostring(entry.load) then return page.args end
    end
end
wagon.load = 123
local page = PageOf(wagon)
if Check(page ~= nil, "the wagon's page") then
    Check(page.load.hidden() == false and page.hitched.hidden() == false, "a drawn vehicle has a load and a harness")
    Set(page.load, "6000")
    Eq(wagon.load, 6000, "the load is set")
    Check(page.status.name():find("its team can move", 1, true), "the page says in red what is wrong: " .. page.status.name())
    Set(page.hitched, false)
    Check(not wagon.hitched and not page.status.name():find("its team can move", 1, true), "out of harness its load is nobody's trouble")
    Set(page.hitched, true)
end
ship.load = 77
page = PageOf(ship)
if Check(page ~= nil, "the ship's page") then
    Check(page.load.hidden() == false and page.hitched.hidden() == true, "a ship has a load and no harness")
end
second.load = 0
page = PageOf(second)
if Check(page ~= nil, "a horse's page") then
    Check(page.load.hidden() == true and page.hitched.hidden() == false, "an animal has a harness and no load")
end

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
cat.hitched, ship.hitched, cart.hitched, wagon.hitched = true, true, true, true
draft.load, wagon.load, sheet.bodyWeight = 50, 1e9, 12345.6
Run("NormalizeMounts", ns.NormalizeMounts, sheet)
Check(not cat.hitched and not ship.hitched, "a companion and a ship are taken out of harness")
Check(wagon.hitched ~= cart.hitched, "one drawn vehicle stays in harness")
Check(draft.load == 0 and wagon.load == 999999 and sheet.bodyWeight == 999, "loads and the rider's weight are held to their limits")
-- an older character has neither field
sheet.bodyWeight = nil
for _, entry in ipairs(sheet.mounts) do entry.hitched, entry.load = nil, nil end
ns.NormalizeState(RPSheet:State())
Check(sheet.bodyWeight == 0 and RPSheet:RiderLoad() == RPSheet:CarriedWeight(), "an old sheet: no weight said")
for _, entry in ipairs(sheet.mounts) do
    if not Check(entry.hitched == false and entry.load == 0, entry.name .. ": an old entry is out of harness and empty") then break end
end
Check(RPSheet:Team() == nil, "and nothing is in harness")
-- export and import
sheet.bodyWeight = 150
RPSheet:SetHitched(draft, true); RPSheet:SetHitched(wagon, true)
wagon.load = 1234
local back = Run("DecodeSheet", RPSheet.DecodeSheet, RPSheet, RPSheet:ExportSheet())
if Check(type(back) == "table", "the export decodes") then
    local horseBack, wagonBack
    for _, entry in ipairs(back.mounts) do
        if entry.name == "Draft Horse" and entry.hitched then horseBack = entry end
        if entry.name == "Wagon" then wagonBack = entry end
    end
    Check(back.bodyWeight == 150 and horseBack ~= nil and wagonBack and wagonBack.hitched and wagonBack.load == 1234, "weight, harness and load survive an export")
end

Done("mountload")
