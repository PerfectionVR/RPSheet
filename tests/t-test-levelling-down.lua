-- Levelling down and back up, with the Character tab's own buttons: every class goes
-- to level 12, back down to 1 one level at a time and up to 12 again; two characters
-- of several classes go up, down by the class picked and up again. After each step
-- the sheet is checked; where going down left more picks than the level allows, the
-- choices button is used to put it right, as the red line on the tab says.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local TOP = tonumber(ARG4) or 12
local downs, fixes = 0, 0
redone = 0

-- What a level gave has to be gone: its record, its feat, its features.
local function AfterDown(label, level, lostSlot, lostFeatures)
    local sheet = RPSheet:Sheet()
    if sheet.level ~= level then Problem(("%s: level %d after going down to %d"):format(label, sheet.level, level)) return end
    downs = downs + 1
    if Levels.Record(sheet, lostSlot) then Problem(label .. ": the lost level's choice is still kept") end
    for _, passive in ipairs(sheet.passives) do
        if passive.auto == "level:" .. lostSlot then Problem(label .. ": the lost level's feat is still on the sheet: " .. passive.name) end
    end
    for _, name in ipairs(lostFeatures) do
        if T.HasEntry(sheet, name) then Problem(("%s: %s is still on the sheet"):format(label, name)) end
    end
    T.Check(label, { level = level, open = true })
    -- The tab says what is open; the choices button puts it right.
    if ns.OpenClassChoices(sheet) then
        fixes = fixes + 1
        local red = table.concat(T.RedLines(sheet), " ")
        if not red:find("choices to make") then Problem(label .. ": choices are open but the tab doesn't say so") end
        if not T.Tab("classChoices") then Problem(label .. ": the choices button can't be pressed") end
        FlushTimers()
        T.Finish(label .. " choices")
    end
    -- A feat of an earlier level may have lost what it asked for (a spellcasting class,
    -- a score): the tab asks for that level's choice again.
    for _, slot in ipairs(Levels.Pending(sheet)) do
        local record = Levels.Record(sheet, slot)
        print(("  %s: level choice %d asked again: %s"):format(label, slot, tostring(record and Levels.Problem(sheet, slot, record))))
        redone = redone + 1
        if not T.Tab("levelChoice" .. slot) then Problem(label .. ": no button for the open level choice") end
        FlushTimers()
        T.Finish(label .. " level choice")
    end
    T.Check(label .. " settled", { level = level })
end

-- The features only this level of the class gave (by name), for the check above.
local function GainedOnly(sheet, key, classLevel)
    local names, earlier = {}, {}
    local subclass = ns.ClassSubclass(sheet, key)
    for level = 1, classLevel - 1 do
        for _, feature in ipairs(ns.FeaturesGainedAt(key, subclass, level)) do earlier[feature.name] = true end
    end
    for _, feature in ipairs(ns.FeaturesGainedAt(key, subclass, classLevel)) do
        if not earlier[feature.name] and not feature.when and not feature.option and not feature.spec then names[#names + 1] = feature.name end
    end
    return names
end

for index, key in ipairs(R.CLASS_ORDER) do
    local sheet = T.NewCharacter(key, index)
    if sheet then
        T.Tab("levelClass", key) -- the dropdown may still name a class of the character before
        for level = 2, TOP do
            T.label = ("%s up %d"):format(key, level)
            if not T.Tab("levelUp") then Problem(T.label .. ": the level button can't be pressed") break end
            FlushTimers()
            if L.draft and L.draft.class ~= key then Problem(T.label .. ": the dialog is for " .. tostring(L.draft.class)) end
            if not T.Finish(T.label) then break end
        end
        T.Check(key .. " at the top", { level = TOP })
        local hurt = RPSheet:State()
        for level = TOP - 1, 1, -1 do
            local label = ("%s down %d"):format(key, level)
            local lost = GainedOnly(sheet, key, level + 1)
            if not T.Tab("levelDown") then Problem(label .. ": the button can't be pressed") break end
            FlushTimers()
            AfterDown(label, level, level + 1, lost)
        end
        if T.Tab("levelDown") then Problem(key .. ": can go below level 1") end
        if ns.ClassSubclass(sheet, key) ~= "" and not R.CLASSES[key].hero then Problem(key .. ": still has subclass " .. sheet.subclass .. " at level 1") end
        for level = 2, TOP do
            local label = ("%s again %d"):format(key, level)
            if not T.TakeLevel(nil, {}, label) then break end
            T.Check(label, { level = level })
        end
    end
end

-- Several classes: up in turn, then down class by class as picked on the tab.
for n, keys in ipairs({ { "WARRIOR", "MAGE" }, { "PRIEST", "WARLOCK", "ROGUE" }, { "PALADIN", "EVOKER" } }) do
    local label = table.concat(keys, "+")
    local sheet = T.NewCharacter(keys[1], 30 + n, true)
    if sheet then
        local order = {}
        for level = 2, TOP do
            local key = keys[(level - 1) % #keys + 1]
            if level < R.HERO_START_LEVEL and R.CLASSES[key].hero then key = keys[1] end
            T.Tab("levelClass", key)
            T.label = ("%s up %d (%s)"):format(label, level, key)
            if not T.Tab("levelUp") then Problem(T.label .. ": the level button can't be pressed") break end
            FlushTimers()
            if not L.draft or L.draft.class ~= key then Problem(T.label .. ": the dialog is for " .. tostring(L.draft and L.draft.class)) end
            if not T.Finish(T.label) then break end
            order[#order + 1] = key
        end
        T.Check(label .. " at the top", { level = TOP })
        -- Straight back: without a class picked, the last level taken goes first.
        T.Tab("levelClass", keys[1])
        local last = order[#order]
        local before = ns.ClassLevel(sheet, last)
        T.Tab("levelDown"); FlushTimers()
        if ns.ClassLevel(sheet, last) ~= before - 1 then Problem(("%s: going back took the level from another class than the last one taken (%s)"):format(label, last)) end
        AfterDown(label .. " back one", TOP - 1, ns.LevelSlot(sheet, last, before), {})
        -- Then by the class picked, down to the first class alone at level 1.
        for index = #keys, 1, -1 do
            local key = keys[index]
            T.Tab("levelClass", key)
            while ns.ClassLevel(sheet, key) > (index == 1 and 1 or 0) do
                local classLevel = ns.ClassLevel(sheet, key)
                local slot, lost = ns.LevelSlot(sheet, key, classLevel), GainedOnly(sheet, key, classLevel)
                local step = ("%s down %s %d"):format(label, key, classLevel - 1)
                local level = sheet.level
                if not T.Tab("levelDown") then Problem(step .. ": the button can't be pressed") break end
                FlushTimers()
                if ns.ClassLevel(sheet, key) ~= classLevel - 1 then Problem(step .. ": the level went from another class") break end
                AfterDown(step, level - 1, slot, lost)
            end
        end
        if ns.IsMulticlass(sheet) or sheet.level ~= 1 then Problem(label .. ": not back to one class at level 1") end
        for level = 2, TOP do
            local key = keys[(level - 1) % #keys + 1]
            if level < R.HERO_START_LEVEL and R.CLASSES[key].hero then key = keys[1] end
            local step = ("%s again %d (%s)"):format(label, level, key)
            if not T.TakeLevel(key, {}, step) then break end
            T.Check(step, { level = level })
        end
    end
end
T.Tab("levelClass", RPSheet:Sheet().class)
print(("levels gone down: %d, choices put right after going down: %d"):format(downs, fixes))
T.Summary("levelling down and up")
