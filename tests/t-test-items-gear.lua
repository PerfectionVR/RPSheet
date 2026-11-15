-- Starting gear in the creation wizard: every class's set (both of a Warrior's) with
-- every choice it leaves, every background's set with every choice, taking none,
-- putting everything back, and the inventory, armor, coins and tool proficiency the
-- new character ends up with after W.Finish.
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
dofile(ARG3 .. "/wiz2.lua") -- loads the addon and gives Make, Set, Press, Shown
SKIP_SIM = true
dofile(ARG3 .. "/t-test-items-lib.lua")

-- A set's items read from the data's text, without the addon's own reader.
local function Parse(set)
    local list = {}
    for entry in set.items:gmatch("[^;]+") do
        local name, count = entry:match("^%s*(.-)%s*%*(%d+)%s*$")
        if not name then name, count = entry:match("^%s*(.-)%s*$"), 1 end
        list[#list + 1] = { name = name, count = tonumber(count) }
    end
    return list
end
local function ChoiceNames(kind)
    local choice, names = R.GEAR_CHOICES[kind], {}
    for _, name in ipairs(choice.items or {}) do names[#names + 1] = name end
    for _, name in ipairs(choice.tools and R.TOOL_ORDER or {}) do
        if choice.tools[R.TOOLS[name].kind] then names[#names + 1] = name end
    end
    return names
end

---------------------------------------------------------------------------
-- The data holds together
---------------------------------------------------------------------------
local function CheckSet(label, set)
    Check(type(set.gold) == "number" and set.gold >= 0, label .. ": gold")
    for _, entry in ipairs(Parse(set)) do
        Check(R.ITEMS[entry.name] ~= nil, ("%s: %q is not in the item lists, so the set silently lacks it"):format(label, entry.name))
        Check(entry.count >= 1, label .. ": count of " .. entry.name)
    end
    Eq(#R.GearList(set), #Parse(set), label .. ": items the addon reads")
    Check(#(set.choices or {}) <= 2, label .. ": more choices than the page has dropdowns")
    for _, choice in ipairs(set.choices or {}) do
        if Check(R.GEAR_CHOICES[choice.kind] ~= nil, label .. ": choice " .. tostring(choice.kind)) then
            local names = ChoiceNames(choice.kind)
            Check(#names > 0, label .. ": nothing to choose for " .. choice.kind)
            for _, name in ipairs(names) do
                Check(R.ITEMS[name] ~= nil, ("%s: %s can be chosen but is not in the item lists"):format(label, name))
                if choice.trained then Check(R.TOOLS[name] ~= nil, ("%s: %s is trained but is not a tool"):format(label, name)) end
            end
            Eq(#R.GearChoiceNames(choice.kind), #names, label .. ": names offered for " .. choice.kind)
        end
    end
end
for _, key in ipairs(R.CLASS_ORDER) do
    local base = R.CLASSES[key].base
    Check(R.START_GOLD[base] ~= nil, key .. ": no starting gold for " .. base)
    if Check(R.CLASS_GEAR[base] ~= nil and #R.CLASS_GEAR[base] > 0, key .. ": no starting gear for " .. base) then
        for index, set in ipairs(R.CLASS_GEAR[base]) do
            CheckSet(base .. " set " .. index, set)
            if #R.CLASS_GEAR[base] > 1 then Check(type(set.label) == "string", base .. " set " .. index .. ": no label") end
        end
    end
end
for _, key in ipairs(R.BACKGROUND_ORDER) do
    if Check(R.BACKGROUND_GEAR[key] ~= nil, key .. ": no starting gear") then CheckSet(key, R.BACKGROUND_GEAR[key]) end
end
for key in pairs(R.BACKGROUND_GEAR) do Check(R.BACKGROUNDS[key] ~= nil, "gear for a background that doesn't exist: " .. key) end

---------------------------------------------------------------------------
-- One character through the wizard, the gear done as `plan` says just before Create
---------------------------------------------------------------------------
local RealFinish = W.Finish
local plan, expect
local function Pick(half, set, wanted, label)
    local choice = set.choices and set.choices[1]
    local key = "gearChoice" .. half .. "1"
    local shown = Shown(label .. " after taking")
    if not choice then
        Check(shown[key] == nil, label .. ": a dropdown though the set leaves nothing to choose")
        return
    end
    local row = shown[key]
    if not Check(row ~= nil, label .. ": no dropdown for " .. choice.kind) then return end
    local names = ChoiceNames(choice.kind)
    for _, name in ipairs(names) do Check(row.values[name] ~= nil, label .. ": " .. name .. " is not offered") end
    local offered = 0
    for _ in pairs(row.values) do offered = offered + 1 end
    Eq(offered, #names + 1, label .. ": how many are offered")
    Eq(row.current, "", label .. ": nothing chosen yet")
    Check(row.name:find(R.GEAR_CHOICES[choice.kind].name, 1, true) and row.name:find(half, 1, true), label .. ": dropdown name " .. tostring(row.name))
    Check(shown.gearNote and shown.gearNote.name:find("Still to choose below", 1, true), label .. ": the note doesn't say something is still to choose")
    if not wanted then return end
    -- another one first, then the wanted one: the first goes back
    local other = names[1] ~= wanted and names[1] or names[2]
    Set(key, other); FlushTimers()
    Eq(W.draft.closet[other], (expect.items[other] or 0) + 1, label .. ": the first pick is in the closet")
    Set(key, wanted); FlushTimers()
    Eq(W.draft.closet[other], expect.items[other], label .. ": the first pick went back")
    shown = Shown(label .. " after choosing")
    Eq(shown[key].current, wanted, label .. ": the dropdown shows the pick")
    Check(not shown.gearNote.name:find("Still to choose below", 1, true) or (plan.class and plan.background and half == "class"), label .. ": still says something is to choose")
    expect.items[wanted] = (expect.items[wanted] or 0) + 1
    if choice.trained then expect.tools[#expect.tools + 1] = wanted end
end
local function Take(half, set, wanted, label)
    local button = half == "class" and "takeClassGear" or "takeBackgroundGear"
    local shown = Shown(label .. " before taking")
    Check(shown[button] and shown[button].disabled == false and shown[button].name:find("^Take my"), label .. ": the button is ready")
    Check(type(shown[button].option.desc()) == "string", label .. ": the button's tooltip")
    Press(button)
    for _, entry in ipairs(Parse(set)) do
        expect.items[entry.name] = (expect.items[entry.name] or 0) + entry.count
        if R.ARMOR_ITEMS[entry.name] then expect.armor = R.ARMOR_ITEMS[entry.name] end
        if entry.name == "Shield" then expect.shield = true end
    end
    shown = Shown(label .. " taken")
    Check(shown[button].disabled == true and shown[button].name:find("^Took my"), label .. ": the button says it was taken")
    Check(shown.gearNote and shown.gearNote.name:find("Added from your " .. half, 1, true), label .. ": the note")
    if set.note then Check(shown.gearNote.name:find(set.note, 1, true), label .. ": the set's own note") end
    -- taking it again doesn't pile up
    local before = CopyTable(W.draft.closet)
    Run(label .. " take again", W.TakeGear, half); FlushTimers()
    for name, count in pairs(W.draft.closet) do Eq(count, before[name], label .. ": " .. name .. " after taking the set twice") end
    Pick(half, set, wanted, label)
end
W.Finish = function()
    local draft, label = W.draft, plan.label
    local class = R.CLASSES[draft.class]
    local full = R.START_GOLD[class.base] + R.BACKGROUND_GOLD
    expect = { items = {}, tools = {}, armor = "NONE", shield = false }
    -- Start clean: Make took both sets already.
    Press("empty")
    Check(next(draft.closet) == nil and next(draft.worn) == nil and next(draft.gear) == nil, label .. ": Put everything back leaves something")
    Eq(draft.gold, full, label .. ": gold after putting everything back")
    local shown = Shown(label .. " emptied")
    Check(shown.empty.disabled == true, label .. ": Put everything back is off when nothing is taken")
    Check(shown.taken.name == "Nothing taken yet.\n", label .. ": summary of an empty closet")
    Eq(shown.gearSet ~= nil, #R.CLASS_GEAR[class.base] > 1, label .. ": the set dropdown shows")
    local classGold, backgroundGold = R.START_GOLD[class.base], R.BACKGROUND_GOLD
    if plan.class then
        local sets = R.CLASS_GEAR[class.base]
        if #sets > 1 then
            -- the other set first, then the wanted one: it is swapped, not piled up
            local other = plan.set % #sets + 1
            Set("gearSet", other); Press("takeClassGear")
            Check(next(draft.closet) ~= nil and draft.gold == sets[other].gold + R.BACKGROUND_GOLD, label .. ": the other set was taken")
            Set("gearSet", plan.set); FlushTimers()
            Check(next(draft.closet) == nil and next(draft.worn) == nil, label .. ": choosing another set puts the taken one back")
            Eq(draft.gold, full, label .. ": and the gold is the class's own again")
            shown = Shown(label .. " other set")
            Check(shown.takeClassGear.disabled == false, label .. ": after choosing another set the button is ready again")
            Check(shown.gearNote and shown.gearNote.name:find("went back", 1, true), label .. ": the note says the set went back")
        end
        Take("class", sets[plan.set], plan.classPick, label .. " class")
        classGold = sets[plan.set].gold
    end
    if plan.background then
        Take("background", R.BACKGROUND_GEAR[draft.background], plan.backgroundPick, label .. " background")
        backgroundGold = R.BACKGROUND_GEAR[draft.background].gold
    end
    if not plan.class and not plan.background then Press("goldAll") end
    Eq(draft.gold, classGold + backgroundGold, label .. ": starting gold")
    expect.gold = classGold + backgroundGold
    for name, count in pairs(expect.items) do Eq(draft.closet[name], count, label .. ": closet has " .. name) end
    for name, count in pairs(draft.closet) do Check(expect.items[name] == count, label .. ": closet has " .. count .. " " .. name .. " too many") end
    if plan.extra then plan.extra(draft, expect) end
    shown = Shown(label .. " ready")
    Check(next(expect.items) == nil or shown.taken.name:find("Worth ", 1, true), label .. ": the summary of what was taken")
    Check(W.StepProblem() == nil, label .. ": the last step is stuck: " .. tostring((W.StepProblem())))
    RealFinish()
end

local runs = 0
local function Character(spec)
    runs = runs + 1
    plan = spec
    plan.label = spec.label or ("%s %s set %s pick %s / %s pick %s"):format(spec.classKey, spec.class and "takes" or "skips", tostring(spec.set), tostring(spec.classPick),
        (spec.background and "takes " or "skips ") .. spec.backgroundKey, tostring(spec.backgroundPick))
    local class = R.CLASSES[spec.classKey]
    local sheet = Make({ label = plan.label, class = spec.classKey, level = class.hero and R.HERO_START_LEVEL or 1,
        species = R.SPECIES_ORDER[runs % #R.SPECIES_ORDER + 1], background = spec.backgroundKey, n = runs })
    FlushTimers()
    local label = plan.label
    if not sheet or not expect then Problem(label .. ": no character") return end
    -- the inventory is exactly what was taken
    local seen = {}
    for _, item in ipairs(sheet.items) do
        Check(not seen[item.name], label .. ": two entries of " .. item.name)
        seen[item.name] = item
        Eq(item.qty, expect.items[item.name], label .. ": carries " .. item.name)
        local known = R.ITEMS[item.name]
        Check(known and item.cost == known.cost and item.weight == known.weight, label .. ": " .. item.name .. " is not the catalogue's")
        local worn = R.ARMOR_ITEMS[item.name] == expect.armor or (item.name == "Shield" and expect.shield) or (expect.ready and expect.ready[item.name]) or false
        Eq(item.equipped, worn, label .. ": " .. item.name .. " equipped")
    end
    for name in pairs(expect.items) do Check(seen[name], label .. ": " .. name .. " is missing from the inventory") end
    Eq(sheet.armor, expect.armor, label .. ": armor")
    Eq(sheet.shield, expect.shield, label .. ": shield")
    local purse = sheet.coins
    Check(purse.gp == expect.gold and purse.sp == (expect.silver or 0) and purse.pp + purse.ep + purse.cp == 0, label .. ": coins " .. ns.PurseText(purse))
    for _, tool in ipairs(expect.tools) do
        -- (a Monk's is taken over as the class's pick: Sheet/ToolPicks.lua)
        Check((sheet.tools[tool] == true or ns.ToolPicked(sheet, tool)) and RPSheet:ToolSource(tool) ~= nil, label .. ": not proficient with the chosen " .. tool)
    end
    local ready = {}
    for _, weapon in ipairs(ns.ReadyWeapons(sheet)) do ready[#ready + 1] = weapon.name end
    table.sort(ready)
    local wanted = {}
    for name in pairs(expect.ready or {}) do wanted[#wanted + 1] = name end
    table.sort(wanted)
    Eq(table.concat(ready, ", "), table.concat(wanted, ", "), label .. ": weapons at hand")
    -- the armor counts
    local armor = R.ARMOR[expect.armor]
    if expect.armor ~= "NONE" then
        local dex = RPSheet:Mod("DEX")
        Eq(RPSheet:AC(), armor.ac + math.min(dex, armor.dexCap or dex) + (expect.shield and 2 or 0) + RPSheet:Bonus("AC") + RPSheet:StyleAC(), label .. ": Armor Class")
    end
    Run(label .. " numbers", function() RPSheet:CarriedWeight(); RPSheet:Speed(); RPSheet:ExplainAC(); RPSheet:ExplainSpeed() end)
    expect = nil
    return sheet
end

-- Every class's every set with every choice, the background's set taken with it
local at = 0
for _, classKey in ipairs(R.CLASS_ORDER) do
    for setIndex, set in ipairs(R.CLASS_GEAR[R.CLASSES[classKey].base]) do
        local picks = set.choices and ChoiceNames(set.choices[1].kind) or { false }
        for _, pick in ipairs(picks) do
            at = at + 1
            local backgroundKey = R.BACKGROUND_ORDER[at % #R.BACKGROUND_ORDER + 1]
            local backgroundSet = R.BACKGROUND_GEAR[backgroundKey]
            local backgroundPicks = backgroundSet.choices and ChoiceNames(backgroundSet.choices[1].kind) or { false }
            Character({ classKey = classKey, class = true, set = setIndex, classPick = pick,
                backgroundKey = backgroundKey, background = true, backgroundPick = backgroundPicks[at % #backgroundPicks + 1] })
        end
    end
end
-- Every background's set with every choice, the class giving gold in place of gear
for _, backgroundKey in ipairs(R.BACKGROUND_ORDER) do
    local set = R.BACKGROUND_GEAR[backgroundKey]
    local picks = set.choices and ChoiceNames(set.choices[1].kind) or { false }
    for _, pick in ipairs(picks) do
        at = at + 1
        Character({ classKey = R.CLASS_ORDER[at % #R.CLASS_ORDER + 1], class = false, set = 1,
            backgroundKey = backgroundKey, background = true, backgroundPick = pick })
    end
end
-- The class's set alone, and nothing at all
for index, classKey in ipairs(R.CLASS_ORDER) do
    Character({ classKey = classKey, class = true, set = 1, backgroundKey = R.BACKGROUND_ORDER[index], background = false })
    Character({ classKey = classKey, class = false, set = 1, backgroundKey = R.BACKGROUND_ORDER[index + 2], background = false })
end
-- A choice left open: the set comes without it
Character({ label = "choice left open", classKey = "PRIEST", class = true, set = 1, classPick = false, backgroundKey = "NOBLE", background = true, backgroundPick = false })
-- Things taken by hand next to a set, a weapon readied in the closet
local sheet = Character({ label = "by hand", classKey = "WARRIOR", class = true, set = 1, backgroundKey = "SOLDIER", background = false,
    extra = function(draft, want)
        W.TakeItem("Longsword", 1); W.WearItem("Longsword", true)
        W.TakeItem("Javelin", 2) -- on top of the set's eight
        W.TakeItem("Torch", 5)
        W.TakeItem("Leather Armor", 1) -- taken, not worn: the set's chain mail stays on
        want.items.Longsword, want.items.Javelin, want.items.Torch, want.items["Leather Armor"] = 1, 10, 5, 1
        want.ready = { Longsword = true }
    end })
if sheet then
    local sword = sheet.weapons[1]
    Check(sword and sword.name == "Longsword" and sword.proficient and sword.mastery == "Sap", "the readied longsword has its mastery")
end
-- Leather worn in place of the set's chain mail
Character({ label = "other armor", classKey = "WARRIOR", class = true, set = 1, backgroundKey = "SOLDIER", background = false,
    extra = function(draft, want)
        W.TakeItem("Leather Armor", 1); W.WearItem("Leather Armor", true)
        Check(draft.worn["Chain Mail"] == nil, "wearing leather takes the chain mail off in the closet")
        want.items["Leather Armor"], want.armor = 1, "LEATHER"
    end })
-- Putting the set's pick back by hand, then putting back the set: nothing goes below zero
Character({ label = "pick put back by hand", classKey = "PRIEST", class = true, set = 1, classPick = "Amulet", backgroundKey = "SAGE", background = false,
    extra = function(draft, want)
        W.TakeItem("Amulet", -1)
        Run("take the set again", W.TakeGear, "class"); FlushTimers()
        for name, count in pairs(draft.closet) do Check(count > 0, name .. " is at " .. count) end
        want.items.Amulet = nil
    end })

-- A set taken for a class that was changed since: it goes back when the other half's
-- set is taken, so the old class's gear never stands next to the new class's full gold.
Character({ label = "class changed after its set was taken", classKey = "MAGE", class = false, set = 1, backgroundKey = "SAILOR", background = true,
    extra = function(draft, want)
        Press("empty")
        local mage = draft.class
        draft.class = "WARRIOR"
        W.TakeGear("class"); FlushTimers()
        Check(draft.closet["Chain Mail"] == 1 and draft.worn["Chain Mail"], "the Warrior's set is in the closet")
        draft.class = mage
        Check(W.GearTaken("class") == nil, "the set no longer counts as taken for a Mage")
        W.TakeGear("background"); FlushTimers()
        Check(draft.closet["Chain Mail"] == nil and draft.worn["Chain Mail"] == nil, "taking the background's set puts the old class's set back")
        Eq(draft.gold, R.START_GOLD.Wizard + R.BACKGROUND_GEAR.SAILOR.gold, "gold: the Mage's own and the Sailor's left over")
        Check(W.DropStaleGear() == false, "nothing more to put back")
    end })

-- Carrying over what the last character gathered: its items and coins stay, its
-- armor is not on the new character, and the set's things are added to them.
local last = RPSheet:Sheet()
for index = #last.items, 1, -1 do table.remove(last.items, index) end
RPSheet:AddItem("Dagger", 1)
RPSheet:SetEquipped(RPSheet:AddItem("Plate Armor", 1), true)
last.coins = { pp = 0, gp = 7, ep = 0, sp = 3, cp = 0 }
last.weapons[#last.weapons + 1] = ns.NewBasicWeapon("Club", function() return 0 end, true, false) -- so there is something to carry over
Character({ label = "carried over", classKey = "ROGUE", class = true, set = 1, backgroundKey = "SAILOR", background = false,
    extra = function(draft, want)
        draft.keepLists = true
        want.items.Dagger = want.items.Dagger + 1
        want.items["Plate Armor"] = 1
        want.gold, want.silver = want.gold + 7, 3
        want.ready = { Club = true }
    end })

print("characters made", runs)
Done("gear")
