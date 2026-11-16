-- Spells two classes share, and the Weapon Master feat:
--   * a spell one class always has prepared and another class picked is on the list
--     once for each class, and Customize > Spells names each page with its class;
--   * Weapon Master's pick is for its own kind of weapon, also beside the class's
--     Weapon Mastery; it changes once per long rest; and the kinds it offers are the
--     ones the character is proficient with from any source.
dofile(ARG3 .. "/t-test-play-lib.lua")

local CLERIC = R.PREPARED_LISTS.Cleric
local function Entries(name)
    local found = {}
    for _, spell in ipairs(RPSheet:Sheet().spells) do
        if spell.name == name then found[#found + 1] = spell end
    end
    return found
end

Section("an always-prepared spell and another class's pick", function()
    -- (either class first)
    for _, order in ipairs({ { "PALADIN", "PRIEST" }, { "PRIEST", "PALADIN" } }) do
        local subclass = { PALADIN = "Oath of the Holy", PRIEST = R.CLASSES.PRIEST.subclasses[1] }
        local label = order[1] .. " first"
        Build(order[1], subclass[order[1]], 10, {
            extras = { { class = order[2], level = order[2] == "PALADIN" and 3 or 5, subclass = subclass[order[2]] } },
            setup = function(sheet) sheet.picks[CLERIC] = { ["Healing Word"] = true, ["Bless"] = true } end })
        local sheet = RPSheet:Sheet()
        Check(sheet.picks[CLERIC]["Healing Word"], label .. ": the Priest's pick of Healing Word stays")
        local classes = {}
        for _, spell in ipairs(Entries("Healing Word")) do classes[spell.class or ""] = spell end
        Check(classes.PRIEST and not classes.PRIEST.free, label .. ": the Priest has Healing Word as a prepared spell that counts")
        Check(classes.PALADIN and classes.PALADIN.free, label .. ": the Paladin has Healing Word always prepared")
        Eq(#Entries("Healing Word"), 2, label .. ": one entry for each class")
        -- Customize > Spells names the two pages apart
        ns.RebuildOptions()
        local names = {}
        for key, page in pairs(ns.options.args.customize.args.spells.args) do
            if key:find("^item%d+$") then
                local name = type(page.name) == "function" and page.name() or page.name
                names[name] = (names[name] or 0) + 1
            end
        end
        Check(names["Healing Word (Priest)"] == 1 and names["Healing Word (Paladin)"] == 1, label .. ": the pages are named with their class")
        Check(names["Bless"] == 1, label .. ": a spell on the list once keeps its plain name")
        -- a level of the Priest's checks again changes nothing
        ns.ApplyClassFeatures(sheet)
        Eq(#Entries("Healing Word"), 2, label .. ": the upkeep keeps both")
    end
    -- one class: an always-prepared spell is still listed once
    Build("PALADIN", "Oath of the Holy", 5)
    Eq(#Entries("Healing Word"), 1, "a Paladin alone has Healing Word once")
end)

-- The feat on the sheet, with its kind of weapon.
local function WeaponMaster(kind)
    local sheet = RPSheet:Sheet()
    table.insert(sheet.passives, { name = "Weapon Master", desc = "", auto = "", enabled = true, effects = {} })
    sheet.featChoices["own:Weapon Master"] = { feat = "Weapon Master", picks = { weapon = { kind } } }
    ns.ApplyFeatChoices(sheet)
    ns.Util.NormalizeList(sheet.passives, R.TEMPLATES.passive)
end
local function AddWeapon(name)
    local sheet = RPSheet:Sheet()
    local weapon = ns.NewBasicWeapon(name, function(stat) return RPSheet:Mod(stat) end, true, RPSheet:MasteryRoom(name))
    sheet.weapons[#sheet.weapons + 1] = weapon
    return weapon
end

Section("Weapon Master beside Weapon Mastery", function()
    -- A level 1 Warrior picks the mastery of 3 kinds of weapon (Data/Combat.lua).
    Build("WARRIOR", "", 4)
    local sheet = RPSheet:Sheet()
    wipe(sheet.weapons)
    local picks = RPSheet:MasteryLimit()
    WeaponMaster("Longsword")
    Eq(RPSheet:MasteryLimit(), picks + 1, "the feat adds one pick")
    local others = { "Greataxe", "Handaxe", "Javelin", "Spear", "Mace" }
    for index = 1, picks do Check(AddWeapon(others[index]).mastery ~= "", "the class's picks go to weapons of any kind") end
    local extra = AddWeapon(others[picks + 1])
    Eq(extra.mastery, "", "with the class's picks used, a weapon of another kind gets no mastery: the feat's pick is for its own kind")
    extra.mastery = R.WEAPONS[extra.base].mastery
    Check(RPSheet:MasteryOver(), "a mastery set by hand on that weapon is more than the class allows")
    Eq(RPSheet:MasteriesUsed(), RPSheet:MasteryLimit(), "though the count alone looks full")
    extra.mastery = ""
    Check(not RPSheet:MasteryOver(), "taken off again, nothing is over")
    local sword = AddWeapon("Longsword")
    Check(sword.mastery ~= "", "a weapon of the feat's kind gets its mastery")
    Check(RPSheet:WeaponMastery(sword) ~= nil, "and uses it")
    Check(not RPSheet:MasteryOver(), "without going over the class's picks")
    Eq(RPSheet:MasteriesUsed(), RPSheet:MasteryLimit(), "every pick is used")
end)

Section("Weapon Master changes once per long rest", function()
    Build("WARRIOR", "", 4)
    WeaponMaster("Longsword")
    local sheet = RPSheet:Sheet()
    RPSheet:LongRest()
    local instances = {}
    for _, instance in ipairs(ns.FeatInstances(sheet)) do
        if instance.name == "Weapon Master" then instances[1] = instance end -- (not the background's feat)
    end
    local function Draft(kind)
        local store = CopyTable(sheet.featChoices)
        store["own:Weapon Master"].picks.weapon = { kind }
        return store
    end
    Eq(ns.RestPickProblem(Draft("Longsword"), instances), nil, "keeping the pick is no change")
    Eq(ns.RestPickProblem(Draft("Greataxe"), instances), nil, "after a long rest it can be changed")
    sheet.featChoices = Draft("Greataxe") -- (as the level dialog saves it)
    ns.ApplyFeatChoices(sheet)
    local problem = ns.RestPickProblem(Draft("Spear"), instances)
    Check(problem and problem:find("since your last long rest", 1, true), "a second change before the next long rest is refused: " .. tostring(problem))
    local open = select(3, ns.FeatChoiceProgress(Draft("Spear"), instances, sheet.level))
    Check(open == problem, "the level dialog says so: " .. tostring(open))
    Eq(ns.RestPickProblem(Draft("Greataxe"), instances), nil, "keeping the changed pick is fine")
    RPSheet:LongRest()
    Eq(ns.RestPickProblem(Draft("Spear"), instances), nil, "the next long rest allows a change again")
end)

Section("Weapon Master offers the kinds the character is proficient with", function()
    local function Offers(kind)
        local sheet = RPSheet:Sheet()
        local instances = ns.FeatInstances(sheet)
        local store = CopyTable(sheet.featChoices)
        ns.NormalizeFeatChoices(store, instances, sheet.level)
        for _, slot in ipairs(ns.FeatChoiceSlots(store, instances, sheet.level)) do
            if slot.choice.key == "weapon" then return tContains(ns.FeatChoiceValues(sheet, store, instances, slot), kind) end
        end
    end
    -- A Mage trains with simple weapons only.
    Build("MAGE", "", 4)
    WeaponMaster("Dagger")
    Check(not Offers("Longsword"), "a Mage isn't offered a longsword")
    Check(not ns.SheetWeaponProficient(RPSheet:Sheet(), "Longsword"), "a Mage isn't proficient with a longsword")
    -- the feat Martial Weapon Training
    table.insert(RPSheet:Sheet().passives, { name = "Martial Weapon Training", desc = "", auto = "", enabled = true, effects = {} })
    Check(ns.SheetWeaponProficient(RPSheet:Sheet(), "Longsword") and Offers("Longsword"), "Martial Weapon Training makes a longsword one to offer")
    -- a Priest's Protector order
    Build("PRIEST", R.CLASSES.PRIEST.subclasses[1], 4, { setup = function(sheet) sheet.featureOptions["Divine Order"] = "Protector" end })
    WeaponMaster("Mace")
    Check(ns.SheetWeaponProficient(RPSheet:Sheet(), "Longsword") and Offers("Longsword"), "a Protector priest is offered a longsword")
    Build("PRIEST", R.CLASSES.PRIEST.subclasses[1], 4, { setup = function(sheet) sheet.featureOptions["Divine Order"] = "Thaumaturge" end })
    WeaponMaster("Mace")
    Check(not Offers("Longsword"), "a Thaumaturge priest is not")
end)

Summary("t-test-play-classpicks")
