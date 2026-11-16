-- Changing a levelled character under Customize, and the sheet staying consistent:
-- another subclass, another class, classes added, resized and removed on the More
-- classes page, class options ticked beyond their number. These pages refuse nothing;
-- what goes against the rules has to be said in red, and the Character tab's buttons
-- have to be able to put it right. Also a few smaller points found by reading.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local identity = T.Group("customize", "identity").args
local changes = 0

-- Uses the Character tab until nothing is red: level choices, then class choices.
local function Settle(label)
    local sheet = RPSheet:Sheet()
    for guard = 1, 8 do
        local pending = Levels.Pending(sheet)
        if #pending > 0 then
            ns.RebuildOptions()
            if not T.Tab("levelChoice" .. pending[1]) then Problem(label .. ": no button for level choice " .. pending[1]) break end
            FlushTimers(); T.Finish(label .. " level choice")
        elseif ns.OpenClassChoices(sheet) then
            if not T.Tab("classChoices") then Problem(label .. ": no choices button") break end
            FlushTimers(); T.Finish(label .. " choices")
        else
            break
        end
    end
    -- A Fighting Style is chosen where the red line says: on the class's own page.
    for _, slot in ipairs(ns.StyleSlots(sheet)) do
        if not R.FIGHTING_STYLES[slot.name] then
            if not table.concat(T.RedLines(sheet), " "):find("Fighting Style to choose") then Problem(label .. ": an empty Fighting Style isn't called out") end
            local taken = {}
            for _, other in ipairs(ns.StyleSlots(sheet)) do taken[other.name] = true end
            local pick
            for _, name in ipairs(ns.StyleChoices(ns.ClassView(sheet, slot.class), slot.slot)) do
                if not taken[name] then pick = pick or name end
            end
            if slot.class == sheet.class then
                Try(label .. " style", identity[slot.slot == 1 and "fightingStyle" or "fightingStyle2"].set, {}, pick)
            else
                ns.RebuildOptions()
                local group = T.Group("customize", "multiclass", "later" .. slot.class)
                Try(label .. " style", group.args[slot.slot == 1 and "style" or "style2"].set, {}, pick)
            end
        end
    end
    -- Customize doesn't heal: a larger maximum is filled by a rest.
    RPSheet:ClampState(true)
end
-- Everything the sheet shows is read once: an error in any page is a problem.
local function ReadAll(label)
    ns.RebuildOptions()
    Try(label .. " options", Feed, mainRoot, "options")
    Try(label .. " trackers", function() RPSheet:GetTrackers(); RPSheet:GetStatData(); RPSheet:Summary() end)
end
local function HasAuto(sheet, pattern)
    for _, list in ipairs({ sheet.abilities, sheet.passives, sheet.spells }) do
        for _, entry in ipairs(list) do
            if (entry.auto or ""):find(pattern) then return entry end
        end
    end
end

---------------------------------------------------------------------------
-- Another subclass
---------------------------------------------------------------------------
for index, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    if #class.subclasses > 1 then
        local sheet = T.NewCharacter(key, index + 100)
        for level = 2, 11 do T.TakeLevel(nil, { subclass = class.subclasses[1] }, key .. " " .. level) end
        for turn = 2, #class.subclasses + 1 do
            local subclass = class.subclasses[(turn - 1) % #class.subclasses + 1]
            local label = ("%s to %s"):format(key, subclass)
            local old = sheet.subclass
            local oldNames = {}
            for level = 1, 11 do
                for _, feature in ipairs(ns.FeaturesGainedAt(key, old, level)) do oldNames[feature.name] = true end
                for _, feature in ipairs(ns.FeaturesGainedAt(key, subclass, level)) do oldNames[feature.name] = nil end
            end
            Try(label, identity.subclass.set, {}, subclass); FlushTimers()
            changes = changes + 1
            if sheet.subclass ~= subclass then Problem(label .. ": subclass is " .. tostring(sheet.subclass)) end
            for name in pairs(oldNames) do
                if T.HasEntry(sheet, name) then Problem(("%s: %s of %s is still on the sheet"):format(label, name, old)) end
            end
            ReadAll(label)
            T.Check(label .. " before settling", { level = 11, open = true, hurt = true })
            Settle(label)
            T.Check(label, { level = 11 })
        end
    end
end

---------------------------------------------------------------------------
-- Another class
---------------------------------------------------------------------------
for index, key in ipairs(R.CLASS_ORDER) do
    local other = R.CLASS_ORDER[index % #R.CLASS_ORDER + 1]
    local sheet = T.NewCharacter(key, index + 120)
    for level = 2, 9 do T.TakeLevel(nil, {}, key .. " " .. level) end
    local label = ("%s becomes %s"):format(key, other)
    Try(label, identity.class.set, {}, other); FlushTimers()
    changes = changes + 1
    if sheet.class ~= other or sheet.level ~= 9 then Problem(label .. ": class " .. tostring(sheet.class) .. " level " .. sheet.level) end
    if sheet.subclass ~= "" and not R.CLASSES[other].hero then Problem(label .. ": keeps subclass " .. sheet.subclass) end
    -- nothing of the old class's features, picks or spells stays
    local left = HasAuto(sheet, "^class:") and nil
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for _, entry in ipairs(list) do
            local auto = entry.auto or ""
            if auto:find("^subclass:") and not R.CLASSES[other].hero then Problem(label .. ": a subclass feature stays: " .. entry.name) end
        end
    end
    for _, listKey in ipairs(R.PICK_LIST_ORDER) do
        if ns.SheetPickLimit(sheet, listKey) == 0 then
            for _, list in ipairs({ sheet.abilities, sheet.passives }) do
                for _, entry in ipairs(list) do
                    if (entry.auto or ""):find("^pick:" .. listKey .. ":") then Problem(label .. ": a pick of the old class stays on the sheet: " .. entry.name) end
                end
            end
        end
    end
    if ns.SheetManeuverLimit(sheet) == 0 and HasAuto(sheet, "^maneuver:") then Problem(label .. ": a maneuver stays on the sheet") end
    ReadAll(label)
    T.Check(label .. " before settling", { level = 9, open = true, hurt = true })
    -- the subclass is chosen on the same page, then the tab's buttons do the rest
    local red = table.concat(T.RedLines(sheet), " ")
    if not R.CLASSES[other].hero then
        if not red:find("subclass") then Problem(label .. ": the tab doesn't say a subclass is to be chosen") end
        Try(label .. " subclass", identity.subclass.set, {}, R.CLASSES[other].subclasses[1])
    elseif sheet.subclass == "" then
        -- a hero class is its subclass
        if not red:find("subclass") then Problem(label .. ": a hero class got no subclass and the tab doesn't say so") end
        Try(label .. " subclass", identity.subclass.set, {}, R.CLASSES[other].subclasses[1])
    end
    Settle(label)
    T.Check(label, { level = 9 })
    -- and it can go on levelling
    T.TakeLevel(nil, {}, label .. " 10")
    T.Check(label .. " 10", { level = 10 })
end

---------------------------------------------------------------------------
-- The More classes page
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 140, true)
    for level = 2, 6 do T.TakeLevel(nil, {}, "more " .. level) end
    local page = T.Group("customize", "multiclass").args
    local function Later(key) ns.RebuildOptions(); return page["later" .. key] and page["later" .. key].args end
    Try("add Mage", page.add.set, {}, "MAGE"); FlushTimers()
    if ns.ClassLevel(sheet, "MAGE") ~= 1 or sheet.level ~= 7 then Problem("more: adding a Mage gives Mage " .. ns.ClassLevel(sheet, "MAGE") .. ", level " .. sheet.level) end
    ReadAll("more: Mage added")
    Settle("more: Mage added")
    T.Check("more: Mage added", { level = 7 })
    local mage = Later("MAGE")
    if not mage then Problem("more: no group for the Mage")
    else
        Try("Mage to 5", mage.levels.set, {}, 5); FlushTimers()
        if ns.ClassLevel(sheet, "MAGE") ~= 5 or sheet.level ~= 11 then Problem("more: Mage 5 gives level " .. sheet.level) end
        local red = table.concat(T.RedLines(sheet), " ")
        if not red:find("subclass") then Problem("more: a Mage of level 5 has no subclass and the tab doesn't say so") end
        Try("Mage subclass", mage.subclass.set, {}, "Evoker")
        ReadAll("more: Mage 5")
        Settle("more: Mage 5")
        T.Check("more: Mage 5", { level = 11 })
        -- the slider's room: the character can't pass level 20
        mage.levels.hidden()
        if mage.levels.max ~= 5 + R.MAX_LEVEL - 11 then Problem("more: the Mage's slider goes to " .. tostring(mage.levels.max)) end
        Try("Mage to 2", Later("MAGE").levels.set, {}, 2); FlushTimers()
        if ns.ClassLevel(sheet, "MAGE") ~= 2 or sheet.level ~= 8 then Problem("more: Mage 2 gives level " .. sheet.level) end
        T.Check("more: Mage 2 before settling", { level = 8, open = true, hurt = true })
        Settle("more: Mage 2")
        -- below level 3 the subclass set by hand is against the rules: said in red, not removed
        T.CheckNumbers("more: Mage 2", sheet, { open = true })
    end
    -- the first class's own levels
    page.first.hidden()
    Try("Warrior to 10", page.first.set, {}, 10); FlushTimers()
    if ns.ClassLevel(sheet, "WARRIOR") ~= 10 or sheet.level ~= 12 then Problem("more: Warrior 10 gives level " .. sheet.level) end
    Settle("more: Warrior 10")
    -- a second later class, a hero class, and a class on the same core class: allowed here, said in red
    Try("add Death Knight", page.add.set, {}, "DEATHKNIGHT"); FlushTimers()
    Try("add Paladin", page.add.set, {}, "PALADIN"); FlushTimers()
    local text = page.summary.name()
    if not text:find("both the Paladin class") then Problem("more: Paladin and Death Knight together aren't called out in red") end
    ReadAll("more: three later classes")
    Settle("more: three later classes")
    T.CheckNumbers("more: three later classes", sheet, { open = true })
    for _, key in ipairs({ "PALADIN", "DEATHKNIGHT", "MAGE" }) do
        local group = Later(key)
        local level = sheet.level
        local own = ns.ClassLevel(sheet, key)
        Try("remove " .. key, group.remove.func, {}); FlushTimers()
        if ns.ClassLevel(sheet, key) ~= 0 or sheet.level ~= level - own then Problem("more: removing " .. key .. " leaves it at " .. ns.ClassLevel(sheet, key)) end
        for _, slot in ipairs(ns.AllLevelSlots()) do
            if sheet.levels[slot] and not ns.HasSlot(sheet, slot) then Problem("more: a level choice of the removed " .. key .. " is kept (" .. slot .. ")") end
        end
        ReadAll("more: " .. key .. " removed")
    end
    if ns.IsMulticlass(sheet) then Problem("more: still several classes") end
    Settle("more: one class again")
    T.Check("more: one class again", { level = 10 })
    changes = changes + 9
end

---------------------------------------------------------------------------
-- Class options set by hand
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARLOCK", 150)
    for level = 2, 6 do T.TakeLevel(nil, {}, "options " .. level) end
    local group = T.Group("customize", "classPicks", "listinvocations")
    local ticked = 0
    for key, option in pairs(group.args) do
        if option.type == "toggle" and not option.get() and ticked < 3 then option.set({}, true); ticked = ticked + 1 end
    end
    if ns.PicksKnown(sheet, "invocations") ~= 8 then Problem("options: " .. ns.PicksKnown(sheet, "invocations") .. " invocations after ticking three more") end
    if not group.args.warning.name():find("you know 5 at this level, and 8 are chosen") then Problem("options: the page doesn't say that too many are ticked: " .. group.args.warning.name()) end
    if not table.concat(T.RedLines(sheet), " "):find("choices to make") then Problem("options: the Character tab says nothing about three invocations too many") end
    ReadAll("options: too many")
    -- every ticked one is on the sheet
    for name in pairs(sheet.picks.invocations) do
        if not T.HasEntry(sheet, name) then Problem("options: " .. name .. " is ticked but not on the sheet") end
    end
    Settle("options")
    T.Check("options settled", { level = 6 })
    changes = changes + 1
end

---------------------------------------------------------------------------
-- Smaller points
---------------------------------------------------------------------------
-- The class picked for the next level belongs to the character it was picked for.
do
    local sheet = T.NewCharacter("WARRIOR", 160, true)
    T.Tab("levelClass", "MAGE")
    T.NewCharacter("ROGUE", 161)
    local _, byKey = T.Rows(mainRoot.args.character, "tab")
    if byKey.levelClass.option.get() ~= "ROGUE" then
        Problem("a new character's next level is offered in " .. tostring(byKey.levelClass.option.get()) .. ", the class picked for the character before")
    end
    T.Tab("levelClass", "ROGUE")
end
-- A hero class below level 3 has its subclass by right: no warning about it.
do
    local sheet = T.NewCharacter("DEATHKNIGHT", 162)
    if sheet.level < 3 and sheet.subclass ~= "" and not identity.subclassLater.hidden() then
        Problem("a level " .. sheet.level .. " Death Knight is told its subclass comes at level 3")
    end
    local other = T.NewCharacter("ROGUE", 163)
    identity.subclass.set({}, "Assassin")
    if identity.subclassLater.hidden() then Problem("a level 1 Rogue with a subclass set by hand isn't told it comes at level 3") end
end
-- A Battle Master's open feat choice names the button as it is labelled for it.
do
    local sheet = T.NewCharacter("WARRIOR", 164)
    for level = 2, 3 do T.TakeLevel(nil, { subclass = "Battle Master" }) end
    table.insert(sheet.passives, { name = "Crafter", desc = "", enabled = true, effects = {} })
    Opt.Regrant()
    local button = mainRoot.args.character.args.classChoices.name()
    local found
    for _, passive in ipairs(sheet.passives) do
        if passive.name == "Crafter" and passive.desc:find("Still to choose") then
            found = true
            local named = passive.desc:match('Use "([^"]+)"')
            if not named or button:sub(1, #named) ~= named then Problem(("a Battle Master's feat says to use \"%s\"; the button is \"%s\""):format(tostring(named), button)) end
        end
    end
    if not found then Problem("Crafter added by hand has no open choice named in its text") end
    Settle("crafter")
end
-- Weapon Mastery deleted: its picks don't count any more.
do
    local sheet = T.NewCharacter("WARRIOR", 165, true)
    T.TakeLevel("ROGUE", {})
    local both = RPSheet:MasteryLimit()
    if both ~= 5 then Problem("Warrior 1 / Rogue 1 has " .. both .. " weapon masteries, expected 3 + 2") end
    for index, passive in ipairs(sheet.passives) do
        if passive.name == "Weapon Mastery" then ns.DismissAuto(sheet, passive); table.remove(sheet.passives, index) break end
    end
    Opt.Regrant()
    if T.HasEntry(sheet, "Weapon Mastery") then Problem("Weapon Mastery came back after being deleted") end
    if RPSheet:MasteryLimit() ~= 0 then Problem("Weapon Mastery deleted, but " .. RPSheet:MasteryLimit() .. " masteries still count") end
end
print("changes made under Customize: " .. changes)
T.Summary("changing the character under Customize")
