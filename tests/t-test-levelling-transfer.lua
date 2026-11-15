-- Export and import: characters levelled through the dialog are exported, imported and
-- exported again at several levels (the two strings must be equal), and levelling goes
-- on with the imported sheet. Also: deleted features stay deleted through an import,
-- and the example character loads complete and can be levelled.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
dofile(ARG3 .. "/exercise_body.lua")
dofile(ARG3 .. "/t-test-levelling-codec.lua")

-- Where two tables first differ, as text.
local function Diff(a, b, path)
    if type(a) ~= type(b) then return ("%s: %s / %s"):format(path, tostring(a), tostring(b)) end
    if type(a) ~= "table" then return a ~= b and ("%s: %s / %s"):format(path, tostring(a), tostring(b)) or nil end
    for key, value in pairs(a) do
        local found = Diff(value, b[key], path .. "." .. tostring(key))
        if found then return found end
    end
    for key in pairs(b) do
        if a[key] == nil then return ("%s.%s: nil / %s"):format(path, tostring(key), tostring(b[key])) end
    end
end

rounds = 0
-- Export, import, export again.
function RoundTrip(label)
    rounds = rounds + 1
    local first = RPSheet:ExportSheet()
    local before = CopyTable(RPSheet:Sheet())
    local sheet, name = RPSheet:DecodeSheet(first)
    if not sheet then Problem(label .. ": the export can't be read back: " .. tostring(name)) return RPSheet:Sheet() end
    Try(label .. " import", function() RPSheet:ReplaceSheet(sheet) end)
    local second = RPSheet:ExportSheet()
    if first ~= second then
        Problem(("%s: export, import, export gives another string: %s"):format(label, tostring(Diff(before, RPSheet:Sheet(), "sheet"))))
    end
    return RPSheet:Sheet()
end

local AT = { [2] = true, [5] = true, [11] = true, [17] = true, [20] = true }
local function Run(keys, n)
    local label = table.concat(keys, "+")
    local sheet = T.NewCharacter(keys[1], n, #keys > 1)
    if not sheet then return end
    RoundTrip(label .. " 1")
    for level = 2, R.MAX_LEVEL do
        local key = keys[(level - 1) % #keys + 1]
        if level < R.HERO_START_LEVEL and R.CLASSES[key].hero then key = keys[1] end
        local step = ("%s %d"):format(label, level)
        if not T.TakeLevel(key, {}, step) then return end
        if AT[level] then
            RoundTrip(step)
            T.Check(step .. " imported", { level = level })
        end
    end
    Exercise(label .. " imported at 20")
    -- back down on the imported sheet, and up again
    local lost = ns.LevelDownClass(RPSheet:Sheet())
    Try(label .. " down", function() RPSheet:LevelDown() end)
    if RPSheet:Sheet().level ~= R.MAX_LEVEL - 1 then Problem(label .. ": level down on the imported sheet gives level " .. RPSheet:Sheet().level) end
    if ns.OpenClassChoices(RPSheet:Sheet()) then T.Reopen(nil, {}, label .. " choices after down") end
    T.TakeLevel(lost, {}, label .. " up again")
    T.Check(label .. " up again", { level = R.MAX_LEVEL })
end
local order = R.CLASS_ORDER
for index, key in ipairs(order) do Run({ key }, index) end
Run({ "WARRIOR", "MAGE" }, 20)
Run({ "PRIEST", "WARLOCK", "ROGUE" }, 21)
Run({ "DRUID", "EVOKER", "MONK" }, 22)

-- Features the player deleted stay deleted through an import.
do
    local sheet = T.NewCharacter("WARRIOR", 3)
    for level = 2, 5 do T.TakeLevel(nil, { subclass = "Champion" }) end
    sheet = RPSheet:Sheet()
    local gone
    for index, entry in ipairs(sheet.abilities) do
        if (entry.auto or ""):find("^class:") then gone = entry; ns.DismissAuto(sheet, entry); table.remove(sheet.abilities, index) break end
    end
    Opt.Regrant()
    if not gone then Problem("dismissed: no class ability to delete")
    elseif T.HasEntry(sheet, gone.name) then Problem("dismissed: " .. gone.name .. " came back at once")
    else
        sheet = RoundTrip("dismissed")
        if T.HasEntry(sheet, gone.name) then Problem("a deleted feature (" .. gone.name .. ") comes back after export and import") end
        Opt.Regrant()
        if T.HasEntry(RPSheet:Sheet(), gone.name) then Problem("a deleted feature (" .. gone.name .. ") comes back after import and the next change") end
        -- junk in the list of deleted features doesn't get through
        local dirty = CopyTable(RPSheet:Sheet())
        dirty.dismissed[gone.auto] = true
        dirty.dismissed[42], dirty.dismissed["x|cffff0000y"], dirty.dismissed[("z"):rep(300)], dirty.dismissed["class:Fake"] = true, true, true, "yes"
        local prefix = RPSheet:ExportSheet():match("^(.-)%x+$")
        local clean = RPSheet:DecodeSheet(prefix .. ns.Codec.Pack("print", { format = 1, name = "x", sheet = dirty }))
        if not clean then Problem("dismissed: a sheet with junk in dismissed isn't read")
        else
            for key, value in pairs(clean.dismissed) do
                if type(key) ~= "string" or value ~= true or #key > 120 or key:find("|") then Problem("dismissed: junk got through: " .. tostring(key):sub(1, 40)) end
            end
            if not clean.dismissed[gone.auto] then Problem("dismissed: the real entry was lost beside the junk") end
        end
    end
end

-- The example character.
do
    local general = mainRoot.args.general
    local button = general and general.args.example
    if not button then Problem("no example button")
    else
        Try("load example", button.func, { "example", option = button }); FlushTimers()
        local sheet = RPSheet:Sheet()
        if sheet.class ~= "ROGUE" or sheet.level ~= 3 then Problem("example: not loaded") end
        -- every field a new sheet has, with its type
        for key, default in pairs(ns.NewSheet()) do
            if type(sheet[key]) ~= type(default) then Problem(("example: sheet.%s is %s, a new sheet has %s"):format(key, type(sheet[key]), type(default))) end
            if type(default) == "table" and type(sheet[key]) == "table" then
                for inner, value in pairs(default) do
                    if type(value) ~= "table" and type(sheet[key][inner]) ~= type(value) then Problem(("example: sheet.%s.%s is %s"):format(key, inner, type(sheet[key][inner]))) end
                end
            end
        end
        if ns.ExampleCharacter.coins or ns.ExampleCharacter.dismissed then Problem("example: loading wrote into the example itself") end
        Exercise("example")
        RoundTrip("example")
        for level = 4, 6 do
            if T.TakeLevel(nil, {}, "example " .. level) then
                for _, line in ipairs(T.RedLines(RPSheet:Sheet())) do Problem("example " .. level .. ": red: " .. line) end
            end
        end
        if RPSheet:Sheet().level ~= 6 then Problem("example: level " .. RPSheet:Sheet().level .. " after three levels") end
        RoundTrip("example 6")
        Exercise("example 6")
    end
end
print("round trips: " .. rounds)
T.Summary("export, import, example")
